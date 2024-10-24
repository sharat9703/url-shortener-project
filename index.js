const express = require("express");
const app = express();
const path = require("path");

app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, "public")));

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});
var shortUrl = "";
var longUrl = "";
app.post("/api/shorturl", (req, res) => {
  longUrl = req.body.url;
  const urlRegex = /^(https?:\/\/)[\w.-]+\.(com)$/;
  if (!urlRegex.test(longUrl)) {
    res.send({ error: "Invalid URL" });
  }
  shortUrl = Math.floor(Math.random() * 10000);
  res.json({ original_url: longUrl, short_url: shortUrl });
});
app.get(`/api/shorturl/${shortUrl}`,(req,res)=>{
    res.redirect(`${longUrl}`);
});
app.listen(3000, () => {
  console.log("listening on port 3000");
});

module.exports = app;
