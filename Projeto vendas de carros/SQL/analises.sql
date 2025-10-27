-- 1 - View Faturamento Mensal
CREATE VIEW sales.faturamento_mensal AS (
SELECT EXTRACT(MONTH FROM paid_date) AS mes, SUM(p.price)::MONEY AS faturamento_mensal
	FROM sales.funnel AS f
		LEFT JOIN sales.products AS p
		ON f.product_id = p.product_id
		WHERE f.paid_date IS NOT NULL
GROUP BY 1
ORDER BY mes);

-- 2 - Top 5 marcas mais vendidas
CREATE VIEW sales.top5_produtos_vendidos AS (
WITH Qtd as (
		SELECT  DISTINCT(P.brand) AS Marca, COUNT(F.product_id) AS quantidade
		FROM sales.funnel AS F
		LEFT JOIN sales.products as P
		ON F.product_id = P.product_id
		GROUP BY P.brand
)
SELECT *
FROM Qtd
LIMIT 5
);

-- 3 - Receita por estado/loja puxando as top 3 lojas por estado & criando um segundo ranking para maiores receitas
CREATE VIEW sales.rank_receita_estado_loja AS(
WITH maiores_receitas_regiao_loja AS(
	SELECT C.state AS Regiao, S.store_name as Loja_nome, SUM(P.price)::MONEY AS receita
			FROM sales.stores AS S
		LEFT JOIN sales.funnel AS F
			ON F.store_id = S.store_id
		LEFT JOIN sales.products AS P
			ON F.product_id = P.product_id
		LEFT JOIN sales.customers AS C
			ON F.customer_id = C.customer_id
	GROUP BY C.state,S.store_name
		ORDER BY receita DESC
	) 
,rankear_lojas AS (
	SELECT regiao, loja_nome, receita, DENSE_RANK() OVER(PARTITION BY regiao ORDER BY receita DESC) as ranking_regiao,
		ROW_NUMBER() OVER(ORDER BY m.receita DESC) as ranking_receita
	FROM maiores_receitas_regiao_loja as m
)
SELECT * FROM rankear_lojas 
WHERE ranking_regiao <=3
ORDER BY ranking_receita);

-- Faixa Etária dos Clientes
CREATE VIEW sales.faixa_etaria_clientes AS(
WITH base as(
	select customer_id, extract(year from (AGE(CURRENT_DATE, birth_date))) as idade from sales.customers
)
SELECT COUNT(*) as qtd_clientes,
	CASE 
	WHEN idade BETWEEN 1 AND 29 THEN '29 ou menos'
	WHEN idade BETWEEN 30 AND 40 THEN '30-40 Anos'
	WHEN idade BETWEEN 41 AND 50 THEN '41-50 Anos'
	WHEN idade BETWEEN 51 AND 60 THEN '51-60 Anos'
	WHEN idade BETWEEN 61 AND 70 THEN '61-70 Anos'
	else '71+'
	end as Faixa_Etaria,
round(100.0*count(*)/(SELECT count(*) from sales.customers),2)||'%' as percentual
FROM base
group by 2
order by 1 asc);

-- Taxa de Crescimento de vendas Mês a Mês (Faturamento Acumulado)
CREATE VIEW sales.faturamento_acumulado AS (
WITH faturamento_acumulado AS (
	SELECT DATE_TRUNC('month', f.paid_date) as Mes,
	SUM(P.price) as Venda_mensal FROM sales.funnel AS F
	LEFT JOIN sales.products AS P
	ON F.product_id = P.product_id
	GROUP BY mes
	ORDER BY mes ASC
)
SELECT mes, Venda_mensal, SUM(Venda_mensal) OVER(ORDER BY mes ASC) as Venda_Acumulada
FROM faturamento_acumulado as F
group by mes, venda_mensal);

select mes, venda_mensal, venda_acumulada::money from sales.faturamento_acumulado;