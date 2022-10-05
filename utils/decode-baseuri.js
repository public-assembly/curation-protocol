const fs = require("fs");

function extractURI(input) {
  console.log({input})
  return input.substring(input.indexOf(","));
}

const b64 = process.argv[2];
const json = Buffer.from(extractURI(b64), "base64").toString("utf-8");
try {
  const jsonData = JSON.parse(json);
  console.log(jsonData);
  const image = Buffer.from(extractURI(jsonData.image), "base64").toString("utf-8");

  if (process.argv.length == 4) {
    fs.writeFileSync(process.argv[3], image);
  }
} catch (err) {
  console.error(err);
  console.log("cannot decode json", json);
}
