const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });
const puppeteer = require("puppeteer-core");

// Inicializa o Firebase Admin SDK
const serviceAccount = require("./bracefaucet-firebase-adminsdk-ngeww-ecc8d5fa87.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

exports.getResultLens = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    let browser = null;
    try {
      const imageUrl = req.query.image;
      if (!imageUrl) {
        return res.status(400).send("Missing 'image' query parameter.");
      }

      console.log("Launching Puppeteer...");
      browser = await puppeteer.launch({
        headless: true,
        executablePath: "/usr/bin/google-chrome", // Caminho do navegador no Firebase
        args: [
          "--no-sandbox",
          "--disable-setuid-sandbox",
          "--disable-dev-shm-usage",
          "--disable-accelerated-2d-canvas",
          "--disable-gpu",
        ],
      });
      const page = await browser.newPage();

      // Abre o Google Lens com a URL da imagem fornecida
      console.log(`Opening Google Lens for image: ${imageUrl}`);
      await page.goto(`https://lens.google.com/uploadbyurl?url=${encodeURIComponent(imageUrl)}`, {
        waitUntil: "networkidle2",
      });

      console.log("Waiting for search results...");
      await page.waitForSelector("a[href^='http']", { timeout: 30000 });

      // Extrai os links da página
      let links = await page.$$eval("a[href^='http']", (elements) =>
        elements.map((el) => el.href)
      );

      if (links.length > 4) {
        let o = []
        for (let index = 0; index < links.length; index++) {
          if(index >3 && index < links.length-1){
            o.push(links[index])
          }          
        }
        links = o
        .map((o) => `<a href="${o}" target="_blank">${o}</a>`)
        .join("<br>");
      } else {
        links = []; // Caso tenha 4 ou menos, retorna nada
      }


      const formattedLinks = links
        .map((link) => `<a href="${link}" target="_blank">${link}</a>`)
        .join("<br>");

      await browser.close();

      console.log("Search completed.");
      res.status(200).send(formattedLinks);
    } catch (error) {
      console.error("Error in getResultsLens:", error);

      if (browser) {
        await browser.close();
      }

      res.status(500).json({
        details: "An error occurred while processing the request.",
        error: error.message,
        stack: error.stack,
      });
    }
  });
});
