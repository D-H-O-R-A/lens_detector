const express = require("express");
const { Builder, By, until } = require("selenium-webdriver");
const chrome = require("selenium-webdriver/chrome");
const cors = require("cors");
const path = require("path");

// Configurações
const app = express();
const API_PORT = 5000; // Porta para o servidor API
const WEB_PORT = 4000; // Porta para o website

// Configuração do CORS
app.use(cors());

// Servir arquivos estáticos para o website
const webApp = express();
webApp.use(express.static(path.join(__dirname, "../webview/build")));

// Rota principal do website
webApp.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "../webview/build/index.html"));
});

// API principal
app.get("/", async (req, res) => {
  const publicImageUrl = req.query.image;
  if (!publicImageUrl) {
    return res.status(400).json({ error: "Missing 'image' query parameter." });
  }

  let driver = null;

  try {
    console.log("Launching Selenium...");
    const chromeOptions = new chrome.Options()
      .addArguments("--headless", "--no-sandbox", "--disable-dev-shm-usage");
    driver = await new Builder()
      .forBrowser("chrome")
      .setChromeOptions(chromeOptions)
      .build();

    console.log("Navigating to Google Lens...");
    await driver.get(`https://lens.google.com/uploadbyurl?url=${publicImageUrl}`);
    await driver.wait(until.elementLocated(By.css("a[href^='http']")), 30000);

    console.log("Extracting links...");
    const linkElements = await driver.findElements(By.css("a[href^='http']"));
    const links = [];
    for (const element of linkElements) {
      const href = await element.getAttribute("href");
      if (href) {
        links.push(href);
      }
    }

    console.log(`Found ${links.length} links.`);
    const result =
      links.length > 4
        ? links
            .slice(4)
            .filter(
              (link, index, arr) =>
                !(index === arr.length - 1 && link.includes("support.google.com"))
            )
        : [];
    res.status(200).json({ html: result });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: error.message });
  } finally {
    if (driver) {
      await driver.quit();
    }
  }
});

// Iniciar servidores
app.listen(API_PORT, () => {
  console.log(`API server running at http://localhost:${API_PORT}`);
});

webApp.listen(WEB_PORT, () => {
  console.log(`Website running at http://localhost:${WEB_PORT}`);
});
