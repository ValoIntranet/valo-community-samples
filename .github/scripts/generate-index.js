const fg = require('fast-glob');
const matter = require('gray-matter');
const fs = require('fs');
const path = require('path');

const repo_url = `https://github.com/ValoIntranet/valo-community-samples`;

(async () => {
  const entries = await fg('samples/**/*.md');
  let samples = [];
  for (const entry of entries) {
    console.log(path.join(__dirname, "../../", entry));
    const folder = entry.toLowerCase().replace("/readme.md", "");
    const content = fs.readFileSync(path.join(__dirname, "../../", entry), { encoding: 'utf8' });
    if (content) {
      const frontMatter = matter(content);
      let sample = {};
      if (frontMatter && frontMatter.data) {
        const metadata = frontMatter.data;
        sample["title"] = metadata["title"];
        sample["author"] = metadata["author"];
        sample["createdByValo"] = metadata["createdByValo"];
        sample["source"] = `${repo_url}/${entry}`;
        
        if (metadata["htmlTemplate"]) {
          sample["htmlTemplate"] = [];
          for (const tmp of metadata["htmlTemplate"]) {
            sample["htmlTemplate"].push(`${repo_url}/${folder}/${tmp}`);
          }
        }
        if (metadata["pnpTemplate"]) {
          sample["pnpTemplate"] = [];
          for (const tmp of metadata["pnpTemplate"]) {
            sample["pnpTemplate"].push(`${repo_url}/${folder}/${tmp}`);
          }
        }
        if (metadata["script"]) {
          sample["script"] = `${repo_url}/${folder}/`;
        }
        if (metadata["sppkg"]) {
          sample["sppkg"] = `${repo_url}/${folder}/`;
        }

        samples.push(sample);
      }
    }
  }

  if (samples) {
    fs.writeFileSync('release.json', JSON.stringify(samples, null, 2), { encoding: "utf8" });
  }
})();