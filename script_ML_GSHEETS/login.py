from playwright.sync_api import sync_playwright

def gerar_sessao():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False)
        context = browser.new_context()
        page = context.new_page()

        page.goto("https://xtools.adminml.com/tools/home/mercadoenvios")

        print("➡️ Faça login manualmente no navegador aberto...")
        page.wait_for_timeout(90000)  # 1m30s para login

        context.storage_state(path="session.json")
        browser.close()

if __name__ == "__main__":
    gerar_sessao()
