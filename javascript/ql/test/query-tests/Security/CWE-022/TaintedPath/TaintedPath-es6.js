import { readFileSync } from 'fs';
import { createServer } from 'http';
import { parse } from 'url';
import { join } from 'path';

var server = createServer(function(req, res) {
  let path = parse(req.url, true).query.path; // $ Source

  res.write(readFileSync(join("public", path))); // $ Alert - This could read any file on the file system
});
