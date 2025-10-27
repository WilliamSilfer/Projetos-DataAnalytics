--SELECT * FROM sales.customers where (city in ('SÃO PAULO', 'RIO DE JANEIRO')) AND birth_date > '2000-01-01';
--SELECT * FROM sales.customers where (city LIKE 'A%') AND birth_date > '2000-01-01';
--select DISTINCT(state) FROM sales.customers limit 10;

SELECT distinct(city) , count(*) FROM sales.customers
group by distinct(city) 
order by count(*) desc;

SELECT first_name, EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) AS "idade", birth_date FROM sales.customers
WHERE EXTRACT(YEAR FROM AGE(current_date, birth_date)) >= 30
ORDER BY "idade" asc
limit 10;

SELECT (first_name || ' ' || last_name) as nome_cliente, 
		(current_date - birth_date)/365 as idade,
		professional_status, (professional_status = 'clt') as client_clt
from sales.customers
where (current_date - birth_date)/365 BETWEEN 30 and 40
order by idade desc;

SELECT brand, price as preco_cheio, (SUM(price) * .15) as desconto, SUM(price) - (SUM(price) * .15) as valor_descontado, model_year
from sales.products
where price > 400000 and model_year NOT IN ('2010', '2016')
GROUP BY brand, model_year,price
order by brand, model_year;

SELECT C.first_name, F.customer_id, F.store_id, F.product_id, P.brand, P.price
FROM sales.funnel as F LEFT JOIN sales.products as P
ON f.product_id = P.product_id
LEFT JOIN sales.customers as C
ON F.customer_id = C.customer_id
WHERE P.price > 600000
ORDER BY p.price desc;

SELECT city as Cidades,COUNT(*), 100.0 * COUNT(*)/((select count(*) from sales.customers)) as Percentual
from sales.customers
GROUP BY cidades
order by COUNT(*) DESC;

-- Número de vendas primeiro trimestre de 2021
select COUNT(*) from sales.funnel
where (EXTRACT(YEAR FROM (paid_date))) = 2021 and (EXTRACT(MONTH FROM (paid_date))) IN (1,2,3);

-- Marcas compradas no primeiro Semestre
select P.brand, count(*), P.price, DATE_TRUNC('month',F.paid_date) as Mes from sales.funnel as F 
LEFT JOIN sales.products as P
ON F.product_id = P.product_id
where (EXTRACT(YEAR FROM (paid_date))) = 2021 and (EXTRACT(MONTH FROM (paid_date))) BETWEEN 1 AND 6
group by DATE_TRUNC('month',F.paid_date),P.brand,P.price
order by P.brand asc;

-- Subquerys para filtrar Where
-- Subquery Scalar Frequencia (frequencia de clientes por cidade e %)

select count(*), city, 100.0*count(*)/(SELECT COUNT(*) FROM sales.customers)
from sales.customers as C
group by C.city
order by count(*) desc;

-- Subquery encontrar o cliente mais velho
with idade as (SELECT customer_id, first_name, MAX(AGE(CURRENT_DATE,birth_date)) as idade
from sales.customers
group by 2,1
order by idade desc
limit 01
)
SELECT * from idade
;
-- Outra forma
SELECT customer_id, first_name, extract(year from (AGE(CURRENT_DATE, birth_date))) as idade FROM sales.customers
order by 3 desc;
-- Frequencia da Idade
SELECT extract(year from (AGE(CURRENT_DATE, birth_date))) as idade, 
100.0*count(*)/(SELECT count(*) from sales.customers)
FROM sales.customers
group by 1
order by 2 desc

-- Calculando a faixa etária e o % utilizando Subquery 

WITH base as(
	select customer_id, extract(year from (AGE(CURRENT_DATE, birth_date))) as idade from sales.customers
)
SELECT 
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
group by 1
order by 1 asc;

-- Subquery no from
SELECT * from (SELECT customer_id, first_name, MAX(AGE(CURRENT_DATE,birth_date)) as idade
from sales.customers
group by 2,1
order by idade desc
limit 1)
;
-- Subquery no WHERE
select C.first_Name, P.product_id, P.brand, P.price, F.customer_id from sales.funnel as F JOIN sales.products as P
	ON F.product_id = P.product_id
	LEFT JOIN sales.customers as C ON F.customer_id = C.customer_id
where P.price > (SELECT avg(price) FROM sales.products)
order by 4
;

-- Subquery no COM JOIN
SELECT C.first_name, C.customer_id, C.professional_status, J.brand, J.price, J.customer_id, J.product_id
FROM sales.customers as C
RIGHT JOIN ( 
select P.product_id, P.brand, P.price, F.customer_id from sales.funnel as F JOIN sales.products as P
	ON F.product_id = P.product_id
	where P.price > (SELECT avg(price) FROM sales.products)) as J
	ON C.customer_id = J.customer_id
	;

select C.first_name, COUNT(*),'SP', C.state FROM sales.funnel AS F
LEFT JOIN sales.customers as C
ON F.customer_id = C.customer_id
WHERE STATE = 'SP' and F.customer_id = '7BF0759A5E7D'
group by 1,4

UNION ALL

select C.first_name, COUNT(*),'SP', C.state FROM sales.funnel AS F
LEFT JOIN sales.customers as C
ON F.customer_id = C.customer_id
WHERE STATE = 'SP' and F.customer_id = '7A1FCEE6BBD1'
group by 1,4
;

SELECT customer_id, count(*) FROM sales.funnel
group by customer_id
order by 2 desc;

-- Utilizando WINDOWS FUNCTION para rankear por idade e cidade
SELECT first_name, city, extract(YEAR FROM AGE(current_date, birth_date)) AS idade,
-- Calculando a idade
			ROW_NUMBER() OVER (PARTITION BY city ORDER BY AGE(CURRENT_DATE, birth_date) DESC) as ranking_idade
FROM sales.customers
ORDER BY city, ranking_idade;

SELECT first_name, professional_status, EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) AS idade,
ROW_NUMBER() OVER (PARTITION BY professional_status ORDER BY AGE(CURRENT_DATE, birth_date) DESC) as ranking_idade
FROM sales.customers
where professional_status NOT IN ('businessman', 'civil_servant', 'clt', 'freelancer', 'other') 
order by professional_status, ranking_idade;

-- Calculando Percentual de Clientes por Cidade sem subquery e utilizando OVER ()
SELECT city, count(*), 100.0*COUNT(*)/SUM(COUNT(*)) OVER() AS percentual 
FROM sales.customers
GROUP BY city
order by percentual desc;

-- Crie uma query que liste todos os produtos (sales.products), com:
-- Colunas: brand, model_year, price, e um ranking (RANK) do preço dentro de cada marca, ordenado por preço descendente.
-- Filtre apenas produtos com model_year > 2018.

SELECT brand, model_year, price,
ROW_NUMBER() OVER (PARTITION BY brand ORDER BY price desc) as ranking_precos
FROM sales.products
WHERE model_year > '2018'
ORDER BY 1
;

-- SOMA CUMULATIVA POR MES DE 2021
SELECT DATE_TRUNC('month', paid_date) as mes, count(*) as vendas_mes,
	SUM(COUNT(*)) OVER(ORDER BY DATE_TRUNC('month', paid_date)) as venda_acumulada
FROM sales.funnel
WHERE EXTRACT(YEAR FROM paid_date) = 2021
group by mes
order BY mes;

SELECT date_trunc('month', paid_date) as vendas_ano, count(*), 100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS percentual
FROM sales.funnel
where paid_date is not null
GROUP by 1
order by 1;


SELECT date_trunc('month', paid_date) as vendas_ano, count(*)
FROM sales.funnel
where paid_date is not null
GROUP by 1
order by 1;

1️⃣ CTE + Filtro de Agregação

📌 Objetivo: listar apenas os produtos mais vendidos em 2024.

Exercício:
Crie uma query que mostre brand, product_id e quantidade_vendida,
mas apenas para os produtos que venderam mais que a média de vendas de todos os produtos em 2024.

		
SELECT F.product_id, P.brand, COUNT(*) AS Qtd_itens FROM sales.funnel as F
LEFT JOIN sales.products as P 
	ON F.product_id = P.product_id
WHERE EXTRACT(YEAR FROM (F.paid_date)) = 2021
group by 1,2
having COUNT(*) > 
(SELECT AVG(Quantidade_Vendida) AS media FROM
			(SELECT product_id, count(*) as Quantidade_Vendida from sales.funnel 
				WHERE EXTRACT(YEAR FROM (paid_date)) = 2021
				GROUP BY product_id))
order by 3 asc;

WITH media_vendas_2021 as (
			SELECT COUNT(*) AS Quantidade, product_id
				FROM sales.funnel
				WHERE EXTRACT(YEAR FROM (paid_date)) = 2021
			GROUP BY product_id
)
SELECT m.product_id, P.brand, m.Quantidade AS Qtd_itens 
	FROM media_vendas_2021 as m	
		LEFT JOIN sales.products as p
		ON m.product_id = P.product_id
	WHERE m.Quantidade > (SELECT AVG(Quantidade) FROM media_vendas_2021)
	order by m.Quantidade desc;
	
	
2️⃣ Percentual de Participação por Cidade

📌 Objetivo: calcular a contribuição de cada cidade no total de clientes.

Exercício:
Liste city, quantidade_de_clientes, e %_do_total.
Ordene da maior para a menor cidade em clientes.
	

WITH total_clientes as (
	SELECT city, COUNT(*), 100.0*COUNT(*)/SUM(COUNT(*)) OVER() as percentual from sales.customers
	GROUP BY city
	order by percentual desc
)
SELECT *
FROM total_clientes
;

3️⃣ Clientes mais novos e mais velhos

📌 Objetivo: usar subquery no WHERE.

Exercício:
Liste os clientes que têm a menor idade e os que têm a maior idade.
Mostre customer_id, first_name, idade.


SELECT customer_id, nome, idade
FROM (
    SELECT 
        customer_id,
        first_name AS nome,
        EXTRACT(YEAR FROM AGE(birth_date)) AS idade,
        MIN(EXTRACT(YEAR FROM AGE(birth_date))) OVER () AS idade_min,
        MAX(EXTRACT(YEAR FROM AGE(birth_date))) OVER () AS idade_max
    FROM sales.customers
) AS base
WHERE idade = idade_min OR idade = idade_max
ORDER BY idade DESC;

4️⃣ TOP N por Grupo (Window Function)

📌 Objetivo: praticar ROW_NUMBER().

Exercício:
Liste os 3 produtos mais vendidos por marca.
Mostre brand, product_id, qtd_vendida, ranking.


SELECT * FROM (
SELECT P.brand, P.product_id, COUNT(F.customer_id) AS Qtd_Vendas,
ROW_NUMBER() OVER(PARTITION BY P.brand ORDER BY COUNT(F.customer_id) DESC) as Rank_Vendas
	FROM sales.funnel AS F
		LEFT JOIN sales.products as P
		ON F.product_id = P.product_id
GROUP BY P.brand, P.product_id
) as vendas_por_produto
WHERE Rank_vendas <=3
ORDER BY brand ASC, rank_vendas ASC;

5️⃣ Faturamento Acumulado (Running Total)

📌 Objetivo: praticar SUM() OVER.

Exercício:
Liste paid_date, faturamento_no_dia e faturamento_acumulado.
Ordene por paid_date crescente.


SELECT  produto, preco_original, datas, count(produto) as qtd_itens, preco_original * count(produto) as Faturamento_Dia,
			(SUM(preco_original * count(produto)) OVER(ORDER BY datas ASC)) as Faturamento_Acumulado
	FROM (
		select F.product_id as produto, DATE_TRUNC('day', F.paid_date) as datas, P.price as preco_original
			from sales.funnel as F
				left join sales.products as P
					on F.product_id = P.product_id
		where F.paid_date NOTNULL
		)
group by produto, preco_original, datas
HAVING count(produto) > 2
order by datas asc;

6️⃣ Comparação de Tabelas com UNION ALL

📌 Objetivo: identificar duplicatas.

Exercício:
Una os dados de products e products_2,
e liste apenas os produtos que aparecem nas duas tabelas (mesmo nome).

WITH uniao_dados AS (
		SELECT * FROM temp_tables.products_2 AS P2
			UNION all
		SELECT * FROM sales.products  AS P1
) 
select * from uniao_dados as UN
GROUP BY UN.product_id, UN.brand, UN.model, UN.model_year, UN.price
HAVING COUNT(*) > 1
;
7️⃣ Clientes Ativos vs. Inativos

📌 Objetivo: usar subquery com NOT IN.

Exercício:
Liste os clientes que nunca compraram nada.
Mostre customer_id, first_name, city.

SELECT F.customer_id, C.first_name, C.city, F.paid_date
	FROM sales.funnel AS F
		LEFT JOIN sales.customers as C
			ON F.customer_id = C.customer_id
	WHERE NOT F.customer_id IN (select customer_id from sales.funnel
WHERE paid_date ISNULL)
;


8️⃣ Agrupamento por Faixa de Preço

📌 Objetivo: usar CASE.

Exercício:
Agrupe os produtos em faixas:

até 100,

101–500,

501–1000,

acima de 1000.

Conte quantos produtos há em cada faixa.

WITH contagem_produto AS(
	SELECT product_id as produtos, COUNT(*) AS Qtd_produtos 
		FROM sales.funnel
		GROUP BY product_id
		ORDER BY Qtd_produtos DESC
)
SELECT produtos, 
CASE 
	WHEN qtd_produtos <=100 THEN 'Até 100'
	WHEN qtd_produtos between 101 AND 500 THEN '101 - 500'
	WHEN qtd_produtos between 501 AND 1000 THEN '501 - 1000'
	ELSE 'Acima de 1000'
	END AS produtos_faixa, Qtd_produtos
FROM contagem_produto
;

9️⃣ CTE Aninhada + Ranking

📌 Objetivo: usar múltiplas CTEs.

Exercício:

Na primeira CTE, calcule as vendas por store_id.

Na segunda CTE, calcule o percentual de participação de cada loja no total.

Na query final, mostre apenas as lojas que representam mais de 10% das vendas totais.


WITH lojas AS (
	select store_id as id_loja, count(*) as qtd
		from sales.funnel
	group by 1
	order by 2 desc
),
percentual AS (
	SELECT l.id_loja, l.qtd, round(100.0*l.qtd/SUM(l.qtd) OVER(),1) as percentual
	FROM lojas as l
	group by 1,2
	order by 3 desc
)
select * from percentual as p
where p.percentual > 1.0

🔟 Join com Dimensão de Região

📌 Objetivo: usar JOINs múltiplos.

Exercício:
Liste region_name, qtd_clientes, qtd_vendas, ticket_medio.
(Junte customers, regions e funnel.)

SELECT COUNT(F.product_id) as qtd_vendas, 
       COUNT(DISTINCT(F.product_id)) AS Qtd_Clientes, 
       C.state, 
       (SUM(P.price) / COUNT(F.product_id)) as ticket_medio
FROM sales.funnel as F
LEFT JOIN sales.customers as C 
    ON F.customer_id = C.customer_id
LEFT JOIN sales.products as P
    ON F.product_id = P.product_id
GROUP BY C.state
ORDER BY ticket_medio DESC;

# Extra
WITH base AS
		(
			SELECT customer_id, EXTRACT(YEAR FROM(AGE(CURRENT_DATE, birth_date))) AS idade
		FROM sales.customers
)
SELECT 
	CASE 
		WHEN idade BETWEEN 1 AND 29 THEN '29 ou menos'
		WHEN idade BETWEEN 30 AND 40 THEN '30-40 Anos'
		WHEN idade BETWEEN 41 AND 50 THEN '41-50 Anos'
		WHEN idade BETWEEN 51 AND 60 THEN '51-60 Anos'
		WHEN idade BETWEEN 61 AND 70 THEN '61-70 Anos'
		ELSE '71+'
	END AS Faixa_Etaria,
ROUND(100.0*COUNT(*)/(SELECT COUNT(*) FROM sales.customers),2)||'%' AS percentual
	FROM base
	GROUP BY Faixa_Etaria
	ORDER BY Faixa_Etaria ASC;



SELECT D.name as Department, E.name as Employee, E.salary as Salary
FROM employee AS E
LEFT JOIN Department as D
ON E.departmentID = D.id
where E.salary = (SELECT MAX(salary) FROM Employee
                        where departmentID = e.departmentID
                        );


select brand, count(brand), sum(count(*)) OVER(order by brand asc) as quantidade_acumulada from sales.products
group by brand
order by quantidade_acumulada asc;









