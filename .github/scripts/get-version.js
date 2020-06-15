const fs = require('fs');
const path = require('path');
const fetch = require('node-fetch');

(async () => {
  const pkg = fs.readFileSync(path.join(__dirname, "../../package.json"), { encoding: 'utf8' });
  const pkgJson = JSON.parse(pkg);
  const version = pkgJson.version;

  const url = `https://github.com/ValoIntranet/valo-community-samples/releases/tag/${version}`;

  const data = await fetch(url);
  if (data && data.ok) {
    console.log(pkgJson.version);
  }
})();