const express = require("express");
const { default: mongoose } = require("mongoose");
const app = express();
const dotenv = require("dotenv");
dotenv.config();
const path = require("path");
const connectString = process.env.URL;
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, "public")));

const urlSchema = new mongoose.Schema({
    shortUrl: String,
    longUrl: String
  });
  
const Url = mongoose.model("Url", urlSchema);

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.post("/api/shorturl", async(req, res) => {
  const longUrl = req.body.url;
  const urlRegex = /^(https?:\/\/)[\w.-]+\.(com)$/;
  if (!urlRegex.test(longUrl)) {
    res.send({ error: "Invalid URL" });
  }
  const shortUrl = Math.floor(Math.random() * 10000).toString();
  const urlData = new Url({
    longUrl : longUrl,
    shortUrl : shortUrl
  });
  
  await urlData.save();

  res.json({ original_url: longUrl, short_url: shortUrl });
});
app.get(`/api/shorturl/:shortUrl`,async(req,res)=>{
    const shorturl = req.params.shortUrl;
    const urlData = await Url.findOne({ shortUrl : shorturl });
    if(urlData){
      return res.redirect(urlData.longUrl);
    }else res.json({error : "post a url please"});    
});

mongoose.connect(connectString).then(()=>{
    app.listen(3000, () => {
        console.log("Connected to MongoDB and listening on port 3000");
    });
});


module.exports = app;
