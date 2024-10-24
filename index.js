const { error } = require("console");
const express = require("express");
const app = express();
const path = require("path");

app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, "public")));

const urlDatabase = {};

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.post("/api/shorturl", (req, res) => {
  const longUrl = req.body.url;
  const urlRegex = /^(https?:\/\/)[\w.-]+\.(com)$/;
  if (!urlRegex.test(longUrl)) {
    res.send({ error: "Invalid URL" });
  }
  shortUrl = Math.floor(Math.random() * 10000);
  urlDatabase[shortUrl] = longUrl;
  res.json({ original_url: longUrl, short_url: shortUrl });
});
app.get(`/api/shorturl/:shortUrl`,(req,res)=>{
    const shorturl = req.params.shortUrl;
    if(urlDatabase[shorturl]){
      return res.redirect(urlDatabase[shorturl]);
    }
    res.json({error : "post a url please"});    
});
app.listen(3000, () => {
  console.log("listening on port 3000");
});

module.exports = app;
