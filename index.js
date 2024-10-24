const express = require("express");
const mongoose = require("mongoose");
const dotenv = require("dotenv");
const path = require("path");
const dns = require("dns");

dotenv.config();
const app = express();
const connectString = process.env.URL;

app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, "public")));

const urlSchema = new mongoose.Schema({
  shortUrl: String,
  longUrl: String,
});
const Url = mongoose.model("Url", urlSchema);

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.post("/api/shorturl", async (req, res) => {
  const longUrl = req.body.url;

  const urlRegex = /^(https?:\/\/)/;
  if (!urlRegex.test(longUrl)) {
    console.log("Invalid URL format:", longUrl);
    return res.json({ error: "Invalid URL" });
  }

  const hostname = new URL(longUrl).hostname;

  dns.lookup(hostname, async (err) => {
    if (err) {
      console.log("DNS Lookup failed:", err);
      return res.json({ error: "Invalid URL" });
    }

    const shortUrl = Math.floor(Math.random() * 10000).toString();
    
    const urlData = new Url({ longUrl, shortUrl });
    await urlData.save();

    res.json({ original_url: longUrl, short_url: Number(shortUrl) });
  });
});

app.get("/api/shorturl/:shortUrl", async (req, res) => {
  const shortUrl = req.params.shortUrl;

  const urlData = await Url.findOne({ shortUrl: ""+shortUrl });
  
  if (urlData) {
    return res.redirect(urlData.longUrl);
  } else {
    console.log("No URL found for:", shortUrl);
    return res.json({ error: "No short URL found" });
  }
});

mongoose.connect(connectString, { useNewUrlParser: true, useUnifiedTopology: true })
  .then(() => {
    app.listen(3000, () => {
      console.log("Connected to MongoDB and listening on port 3000");
    });
  })
  .catch(err => {
    console.error("MongoDB connection error:", err);
  });

module.exports = app;
