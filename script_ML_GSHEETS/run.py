import time
import logging
import gspread
from playwright.sync_api import sync_playwright
from oauth2client.service_account import ServiceAccountCredentials
from playwright.async_api import async_playwright

# Log
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

# Google Sheets
SCOPE = ["https://spreadsheets.google.com/feeds","https://www.googleapis.com/auth/drive"]
# Credenciais Json
CREDENTIALS = ServiceAccountCredentials.from_json_keyfile_name("credentials.json",SCOPE)


nome_planilha = "PAGAMENTOS EMN5 TESTES"
nome_da_aba = "EMN5"


gc = gspread.authorize(CREDENTIALS)
sheet = gc.open(nome_planilha).worksheet(nome_da_aba) # Nome da Planilha e sua Aba
data = sheet.get_all_values()[1:] # Ignorar cabeçalho
# Inserir Caminho para google chrome
# ========================
CHROME_PROFILE = r"C:\Users\William Silva\AppData\Local\Google\Chrome\User Data\Profile 4" # Caminho do perfil do chrome


def coluna_para_indice(coluna):
    coluna = coluna.upper()
    indice = 0
    for letra in coluna:
        indice = indice * 26 + (ord(letra) - ord('A') + 1)
    return indice

coluna_letra = input("Digite a letra da coluna dos IDs: ")
coluna = coluna_para_indice(coluna_letra)

ids = sheet.col_values(coluna)

# Função para Login AKTA
with sync_playwright() as p:
    browser = p.chromium.launch_persistent_context(
        user_data_dir=CHROME_PROFILE,
        headless=False
    )

    page = browser.new_page()

    for idx, pedido_id in enumerate(ids, start=2):
        
        if not pedido_id:
            continue

        logging.info(f"Processando ID {pedido_id}")

        url = f"https://envios.adminml.com/logistics/api/monitoring-route/route-detail?routeId={pedido_id}&siteId=MLB&isRouteTypeFlex=false"
        page.goto(url, timeout=30000)
        time.sleep(3)

        try:
            data = response.json()
            #buscar o json
            print("\n==== JSON RETORNADO ====\n")
            print(json.dumps(data, indent=2, ensure_ascii=False))

        except Exception as e:
            logging.error(f"Erro ao capturar status do {pedido_id}: {e}")
            status = "STATUS NÃO IDENTIFICADO"

        # Irá reescrever o conteúdo
        
       # status = status.upper()
        #sheet.update_cell(idx, 4, status)
        #logging.info(f"{pedido_id} → {status}")

        time.sleep(1)

    browser.close()
