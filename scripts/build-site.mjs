import {cp,copyFile,mkdir,readFile,rm,stat} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {galleries} from '../site/gallery.js';

const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const output=resolve(root,'dist');
// Validate inputs before replacing generated output.
for(const [id] of Object.values(galleries).flat()) {
  await stat(resolve(root,'site/assets/screens',`${id}.webp`));
}
await stat(resolve(root,'site/assets/icon.png'));
await stat(resolve(root,'site/assets/social-preview.jpg'));
await rm(output,{recursive:true,force:true});
await mkdir(output,{recursive:true});
await cp(resolve(root,'site'),output,{recursive:true});
await copyFile(resolve(root,'web/history.js'),resolve(output,'history.js'));
const page=await readFile(resolve(output,'index.html'),'utf8');
if(!page.includes('Threefold')) throw new Error('Unexpected site entry point');
console.log('Built Threefold website → dist/');
