import {chromium} from '/Users/junjiehou/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright/index.mjs';
import assert from 'node:assert/strict';
import {mkdtemp,mkdir,cp,readFile,writeFile,utimes,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {editorServer} from './dev.mjs';
import {gameRoot} from './store.mjs';
import {previewResource} from './preview-resources.mjs';

const temporary=await mkdtemp(join(tmpdir(),'live-spine-preview-')),root=join(temporary,'game'),runtime=join(temporary,'user');
await mkdir(root);await mkdir(runtime);await cp(join(gameRoot,'config'),join(root,'config'),{recursive:true});
for(const relative of ['assets/character/art/player_animations','assets/character/art/monsters','assets/character/art/common_shadow.png','assets/skill_effects','assets/scene/effects/teleport']){await mkdir(join(root,relative,'..'),{recursive:true});await cp(join(gameRoot,relative),join(root,relative),{recursive:true});}
const server=editorServer({root,runtime});await new Promise(r=>server.listen(0,'127.0.0.1',r));const base='http://127.0.0.1:'+server.address().port;
const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true,args:['--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
try{
 const page=await browser.newPage({viewport:{width:1440,height:1000}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
 const wait=()=>page.waitForSelector('#preview-stage canvas[data-ready="true"]',{timeout:20000});
 const revision=()=>page.locator('#preview-stage canvas').getAttribute('data-resource-revision');
 const changed=async old=>{await page.waitForFunction(old=>{const c=document.querySelector('#preview-stage canvas');return c?.dataset.ready==='true'&&c.dataset.resourceRevision!==old;},old,{timeout:15000});};
 const hero=join(root,'assets/character/art/player_animations/source_spine/Character');
 await page.goto(base+'/characters');await wait();let before=await revision();
 let source=JSON.parse(await readFile(hero+'.json','utf8'));source.skeleton.hash='live-preview-character';await writeFile(hero+'.json',JSON.stringify(source));const later=new Date(Date.now()+1000);await utimes(hero+'.json',later,later);await changed(before);
 assert.equal(await page.locator('#preview-stage canvas').getAttribute('data-source-hash'),'live-preview-character');assert.equal(JSON.parse(await readFile(hero+'.spine-json','utf8')).skeleton.hash,'live-preview-character');
 console.log('CHARACTER_JSON_EXPORT_RELOADED');
 await page.goto(base+'/actions');await wait();await page.locator('[data-select="15"]').click();await wait();before=await revision();
 const input=page.locator('[data-skill-parameters="2001"] [data-skill-field="advanceDistancePx"]');await input.fill('12345');
 const effect=await previewResource('res://assets/skill_effects/skilleffect_jd_dg1-data.tres',root),image=join(root,effect.textures[0].path.slice(6));await writeFile(image,Buffer.concat([await readFile(image),Buffer.from('\npreview-update')]));await changed(before);assert.equal(await input.inputValue(),'12345');console.log('EFFECT_TEXTURE_RELOADED_WITH_UNSAVED_INPUT');
 before=await revision();source=JSON.parse(await readFile(hero+'.json','utf8'));source.animations.live_new_animation=structuredClone(source.animations.idle_SingleWeapon);source.skeleton.hash='live-preview-actions';await writeFile(hero+'.json',JSON.stringify(source));await utimes(hero+'.json',new Date(),new Date(Date.now()+1000));await changed(before);
 assert.equal(await page.locator('[data-row="15"][data-animation] option[value="live_new_animation"]').count(),1);assert.equal(await input.inputValue(),'12345');console.log('ACTION_NAMES_RELOADED_WITHOUT_RESET');
 before=await revision();const atlas=join(root,effect.info.atlas.slice(6));await writeFile(atlas,(await readFile(atlas,'utf8'))+'\n');await changed(before);assert.equal(await input.inputValue(),'12345');console.log('EFFECT_ATLAS_RELOADED');
 page.on('dialog',dialog=>dialog.accept());await page.goto(base+'/monster-actions');await wait();before=await revision();
 const native=join(root,'assets/character/art/monsters/101-wind-slime/monster_101.spine-json');source=JSON.parse(await readFile(native,'utf8'));source.skeleton.hash='live-preview-monster';await writeFile(native,JSON.stringify(source));await changed(before);assert.equal(await page.locator('#preview-stage canvas').getAttribute('data-source-hash'),'live-preview-monster');console.log('MONSTER_NATIVE_SOURCE_RELOADED');
 assert.deepEqual(errors,[]);console.log('LIVE_PREVIEW_QA_OK');
}finally{await browser.close();await new Promise(r=>server.close(r));await rm(temporary,{recursive:true,force:true});}
