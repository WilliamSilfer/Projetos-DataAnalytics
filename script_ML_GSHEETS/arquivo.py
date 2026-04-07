import gspread
from google.oauth2.service_account import Credentials
from playwright.async_api import async_playwright
import asyncio
import requests
import folium
import webbrowser

# Gerar mapa para visualização das rotas pontuadas
def gerar_mapa_rota(coordenadas):

    coords = ";".join([f"{lon},{lat}" for lon, lat in coordenadas])

    url = f"http://localhost:5000/route/v1/driving/{coords}?overview=full&geometries=geojson"

    response = requests.get(url)

    data = response.json()

    geometry = data["routes"][0]["geometry"]["coordinates"]

    # inverter para lat,lon (folium usa assim)
    rota = [(lat, lon) for lon, lat in geometry]

    # centro do mapa
    mapa = folium.Map(location=rota[0], zoom_start=12)

    # desenhar rota
    folium.PolyLine(rota,weight=5).add_to(mapa)

    # marcar paradas
    for i, (lon, lat) in enumerate(coordenadas):

        folium.Marker(
            location=[lat, lon],
            popup=f"Stop {i}",
            icon=folium.Icon(icon="truck")).add_to(mapa)

    arquivo = "rota_mapa.html"

    mapa.save(arquivo)

    print("Mapa salvo:", arquivo)

    webbrowser.open(arquivo)

# Acesso ao drive e planilhas
scope = ["https://www.googleapis.com/auth/spreadsheets","https://www.googleapis.com/auth/drive"]

# Buscar credenciais do JSON

creds = Credentials.from_service_account_file("credentials.json",scopes=scope)
client = gspread.authorize(creds)

# Nome da planilha/ABA
# Automatizar aqui

nome_planilha = "PAGAMENTOS EMN5 TESTES"
nome_aba = "EMN5"

# Buscar a planilha
planilha = client.open(nome_planilha).worksheet(nome_aba)

CHROME_PROFILE = r"C:\Users\William Silva\AppData\Local\Google\Chrome\User Data\Profile 4"
# Automatizar o processo de coluna
def converter_coluna(coluna):
    coluna = coluna.upper()
    indice = 0
    for letra in coluna:
        indice = indice * 26 + ord(letra) - ord('A') + 1
    return indice

# Coluna
coluna = converter_coluna('r')
# Retornar valores
id = planilha.col_values(coluna)

# Dicionário para receber as rotas
rotas = {}

# Pegar os IDS
pedido = id[1]

url = f"https://envios.adminml.com/logistics/api/monitoring-route/route-detail?routeId={pedido}&siteId=MLB&isRouteTypeFlex=false"

print(pedido)
# Sessão de login OKTA
# Realizar o login

# Otimização de cálculo de rota

def calcular_rota_otimizada_osrm(coordenadas):

    coords = ";".join([f"{lon},{lat}" for lon, lat in coordenadas])

    url = f"http://localhost:5000/trip/v1/driving/{coords}?source=first&roundtrip=false"

    response = requests.get(url)

    if response.status_code != 200:
        raise Exception(response.text)

    data = response.json()

    distancia_metros = data["trips"][0]["distance"]
    duracao_segundos = data["trips"][0]["duration"]

    return distancia_metros, duracao_segundos

# Acesso a uma request JSON contendo todos dados da rota, pedidos e usuários
# Código abaixo irá acessar a request passando o ID da rota, buscará mapear e coletar dados somente de entregas efetuadas

async def main():
    print("Loop 1")
    async with async_playwright() as p:
        print("loop 2")
        # Preenchimento e utilização de cookies
        brower = await p.chromium.launch_persistent_context(user_data_dir = CHROME_PROFILE, headless=False)

        #context = brower.new_context()
        page = await brower.new_page()
        print("loop3")
        async def fazer_requisicao():
            return await page.request.get(url)
        # primeira tentativa
        response = await fazer_requisicao()

        # sessão expirada, pedir login
        if response.status == 401:
            print("🔐 Sessão expirada. Faça login manualmente...")
            
            await page.goto("https://envios.adminml.com/logistics/monitoring-distribution/")
            
            # Espera até sair do domínio do login (OKTA)
            while "okta" in page.url.lower():
                await page.wait_for_timeout(2000)

            print("✅ Login detectado. Tentando novamente...")
            response = await fazer_requisicao()
            # Falha número 3
        if response.status != 200:
            print(await response.text())
            raise Exception(f"Erro definitivo: {await response.text()}")
        # Recebimentos dos dados json
        data = await response.json()
        print("✅ Dados recebidos com sucesso")

        await page.goto("https://envios.adminml.com/logistics/monitoring-distribution/")
        await page.wait_for_timeout(5000)

        response = await page.request.get(url)

        if response.status != 200:
            print(await response.text())
            raise Exception(f"Erro: {await response.text()}")
        print("✅ Processo finalizado. Fechando navegador...")
        print("Autenticado")
        
        print("loop4")
        # Coleta do SVC para ponto de partida
        data = await response.json()
        def extrair_primeiro_ponto(data):
            resultados2 = []
            # laço para pegar as coordenadas do SVC
            destino = data.get("destinationFacility", {})
            if destino:
                        resultados2.append({
                            "lat": destino.get("latitude"),
                            "long": destino.get("longitude"),
                            "Nome Rua": destino.get("name")
                        })

            return resultados2
        # Acesso aos dados da rota
        def extrair_shipments(data):
            resultados = []

            for stop in data.get("stops", []):
                for order in stop.get("orders", []):
                    for unit in order.get("transportUnits", []):
                        related = unit.get("relatedEntity", {})
                        if related.get("type") == "shipment":
                            receiver = related.get("receiverInfo", {})
                            shipment_id = related.get("id")
                            latitude = receiver.get("latitude")
                            longitude = receiver.get("longitude")
                            street_name = receiver.get("street_name")
                            zip_code = receiver.get("zip_code")
                            resultados.append({
                                "shipment_id": shipment_id,
                                "latitude": latitude,
                                "longitude": longitude,
                                "street_name": street_name,
                                "zip_code": zip_code
                            })
            print("loop5")
            return resultados
        print("loop6")
        # Fim da coleta dos dados

        # Verificar o número de Paradas de acordo com as coordenadas latitude e longitude
        resultados = extrair_shipments(data)
        ponto_inicial = extrair_primeiro_ponto(data)

        coordenadas = []
        svc = ponto_inicial[0]
        svc_coord = (svc["long"], svc["lat"])
        
        coordenadas.append(svc_coord)
        vistos = set()
        print("Primeiro Ponto", coordenadas)
        for x in resultados:
            lat = x["latitude"]
            lon = x["longitude"]

            if lat is not None and lon is not None:
                coord = (round(lon,6), round(lat,6))

                if coord not in vistos:
                    coordenadas.append(coord)
                    vistos.add(coord)
        coordenadas.append(svc_coord)
        # entregas
        #coordenadas = []

        # depois as paradas
       # for x in resultados:
        #    lat = x["latitude"]
       #     lon = x["longitude"]

        #    if lat and lon:
       #         coordenadas.append((lon, lat))
       # Visualização do último e último ponto para cruzar dados coletados com os dados visualizados do JSON

        print("Quase último Ponto", coordenadas[-2])
        print("Último Ponto", coordenadas[-1])
        
        # Coletando somente a distancia em metros
        distancia_metros, duracao_segundos = calcular_rota_otimizada_osrm(coordenadas)

        distancia_km = distancia_metros / 1000

        print(f"Distância total da rota: {distancia_km:.2f} km")
        print("Total de pontos:", len(coordenadas))
        await brower.close()
        print("loop7")
        gerar_mapa_rota(coordenadas)
if __name__ == "__main__":
    asyncio.run(main())