const fs = require('fs');
const path = require('path');

const pkg = fs.readFileSync(path.join(__dirname, "../../package.json"), { encoding: 'utf8' });
const pkgJson = JSON.parse(pkg)
console.log(pkgJson.version);