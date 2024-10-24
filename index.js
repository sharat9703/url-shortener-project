const express = require("express");
const app = express();
const path = require("path");

app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, "public")));

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});
app.post("/api/shorturl", (req, res) => {
  const longUrl = req.body.url;
  const urlRegex = /^(https?:\/\/)[\w.-]+\.(com)$/;
  if (!urlRegex.test(longUrl)) {
    res.send({ error: "Invalid URL" });
  }
  const shortUrl = Math.floor(Math.random() * 10000);
  res.json({ original_url: longUrl, short_url: shortUrl });
});

app.listen(3000, () => {
  console.log("listening on port 3000");
});

module.exports = app;
