import {chromium} from '/Users/junjiehou/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright/index.mjs';
import {mkdir,mkdtemp,cp,symlink,readFile,rm} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {editorServer} from './dev.mjs';
import {gameRoot,userRoot} from './store.mjs';
if(process.argv.includes('--preview-aspect')){await import('./preview-qa.mjs');process.exit(0);}
if(process.argv.includes('--live-resources')){await import('./live-preview-qa.mjs');process.exit(0);}
const folder=fileURLToPath(new URL('../qa/',import.meta.url));
await mkdir(folder,{recursive:true});
const temporary=await mkdtemp(join(tmpdir(),'mother-tree-browser-')),root=join(temporary,'game'),runtime=join(temporary,'user');await mkdir(root);await mkdir(runtime);await cp(join(gameRoot,'config'),join(root,'config'),{recursive:true});await symlink(join(gameRoot,'assets'),join(root,'assets'),'dir');for(const f of ['city_walkable_area.json','city_spawn_area.json','dungeon_area_editor.json']){try{await cp(join(userRoot,f),join(runtime,f));}catch(e){if(e.code!=='ENOENT')throw e;}}
const fixture=editorServer({root,runtime});await new Promise(r=>fixture.listen(0,'127.0.0.1',r));const fixtureBase='http://127.0.0.1:'+fixture.address().port;
const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true,args:['--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
try{
const page=await browser.newPage({viewport:{width:1440,height:1000}}),errors=[];
page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
page.on('response',r=>{if(r.status()>=400)console.log('HTTP_ERROR',r.status(),r.url());});
const base=process.env.EDITOR_URL||fixtureBase;
for(const route of ['/','/characters','/actions','/monster-actions','/items']){
 await page.goto(base+route);await page.waitForSelector(route==='/'?'.map-canvas':'tbody tr');
 if(route!=='/'&&route!=='/items')await page.waitForSelector('canvas[data-ready="true"]',{timeout:20000});
 if(route==='/')await page.waitForFunction(()=>[...document.images].every(i=>i.complete));
 await page.screenshot({path:folder+(route==='/'?'map':route.slice(1))+'.png',fullPage:true});
 const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth);if(overflow)errors.push(route+' horizontal overflow');
 console.log(route,'rows',await page.locator('tbody tr').count(),'overflow',overflow);
 if(route==='/'){
  await page.locator('[data-map="1"]').click();await page.waitForSelector('.map-spine[data-ready="true"]');await page.screenshot({path:folder+'dungeon.png'});
  const old=await page.locator('[data-key="walkable.0.0"]').inputValue();await page.locator('[data-key="walkable.0.0"]').fill(String(Number(old)+1));await page.locator('[data-key="walkable.0.0"]').press('Tab');await page.getByRole('button',{name:'↶',exact:true}).click();if(await page.locator('[data-key="walkable.0.0"]').inputValue()!==old)errors.push('map undo did not restore');
 }
 if(route==='/actions'){
  await page.locator('[data-select="15"]').click();await page.waitForSelector('canvas[data-ready="true"]');await page.waitForTimeout(1600);console.log('effects',await page.locator('#preview-stage canvas').evaluate(c=>({...c.dataset})));
  const starts=Number(await page.locator('#preview-stage canvas').getAttribute('data-effect-starts'));if(starts<2)errors.push('repeated hero effects failed');await page.screenshot({path:folder+'attack-preview.png'});
 }
}
// Save through the real browser forms against isolated configuration copies.
page.on('dialog',dialog=>dialog.accept());
await page.goto(fixtureBase+'/');await page.waitForSelector('.map-canvas');await page.locator('[data-map="1"]').click();await page.locator('[data-object="altar"]').click();const oldX=Number(await page.locator('[data-key="altar.0"]').inputValue());await page.locator('[data-key="altar.0"]').fill(String(oldX+9));await page.locator('[data-key="altar.0"]').press('Tab');await page.getByRole('button',{name:'保存到游戏',exact:true}).click();await page.waitForFunction(()=>document.querySelector('#toast').textContent.includes('地图已保存'));const savedMap=JSON.parse(await readFile(join(root,'config/dungeon_area_editor.json'),'utf8'));if(Math.abs(savedMap.altar_tree_positions_by_foreground.start[0]-oldX-9)>.11)errors.push('browser map save failed');
await page.reload();await page.waitForSelector('.map-canvas');await page.locator('[data-map="1"]').click();await page.locator('[data-object="altar"]').click();if(Math.abs(Number(await page.locator('[data-key="altar.0"]').inputValue())-oldX-9)>.11)errors.push('browser map persisted reload failed');
for(const [route,file,field,value] of [['/characters','characters.json','name','浏览器保存测试'],['/items','inventory.json','name','浏览器道具测试']]){await page.goto(fixtureBase+route);await page.waitForSelector('tbody tr');const input=page.locator(`[data-row="0"][data-field="${field}"]`);await input.fill(value);await input.press('Tab');await page.getByRole('button',{name:'保存到游戏',exact:true}).click();await page.waitForFunction(()=>document.querySelector('#toast').textContent.includes('配置已保存'));const saved=JSON.parse(await readFile(join(root,'config',file),'utf8'));const actual=route==='/items'?saved.items[Object.keys(saved.items)[0]].name:saved.rows[0].name;if(actual!==value)errors.push(route+' browser save failed');}
for(const route of ['/actions','/monster-actions']){
 await page.goto(fixtureBase+route);await page.waitForSelector('tbody tr');
 if(route==='/actions'){
  const fields=['attackDistancePx','longitudinalRangePx','heightRangePx','advanceDistancePx','advanceDurationMs','hitStopMs'];
  const values=[210,42,99,33,80,175];
  if(await page.locator('[data-skill-field]').count()!==30)errors.push('all five skills need six inline parameters');
  for(const width of [1440,1024]){
   await page.setViewportSize({width,height:1000});
   const gaps=await page.locator('[data-skill-parameters="2001"] input').evaluateAll(inputs=>inputs.slice(1).map((input,i)=>{const previous=inputs[i].getBoundingClientRect(),current=input.getBoundingClientRect();return {gap:current.left-previous.right,dy:current.top-previous.top};}));
   console.log('PARAMETER_GAPS',width,gaps);
   const widths=await page.locator('[data-select="15"] select').evaluateAll(selects=>selects.map(select=>select.getBoundingClientRect().width));
   console.log('SELECT_WIDTHS',width,widths);
   if(widths.some(value=>Math.abs(value-200)>.1))errors.push('animation and effect selects must be 200px at '+width);
   if(gaps.some(p=>Math.abs(p.gap-20)>.1||Math.abs(p.dy)>.1))errors.push('parameters require a single row and 20px input gaps at '+width);
  }
  await page.setViewportSize({width:1440,height:1000});
  for(let i=0;i<fields.length;i++){const input=page.locator(`[data-skill-parameters="2001"] [data-skill-field="${fields[i]}"]`);await input.fill(String(values[i]));await input.press('Tab');}
  const other=page.locator('[data-skill-parameters="2005"] [data-skill-field="advanceDurationMs"]');await other.fill('110');await other.press('Tab');
  await page.waitForSelector('#preview-stage canvas[data-ready="true"]');await page.screenshot({path:folder+'inline-skill-parameters.png',fullPage:true});
 }
 await page.getByRole('button',{name:'保存到游戏',exact:true}).click();await page.waitForFunction(()=>document.querySelector('#toast').textContent.includes('配置已保存'));
 if(route==='/actions'){
  const saved=JSON.parse(await readFile(join(root,'config/character_actions.json'),'utf8'));
  const row=saved.rows.find(r=>r.id===2001),expected={attackDistancePx:210,longitudinalRangePx:42,heightRangePx:99,advanceDistancePx:33,advanceDurationMs:80,hitStopMs:175};
  for(const [key,value] of Object.entries(expected))if(row[key]!==value)errors.push('inline skill save failed '+key);
  if(saved.rows.find(r=>r.id===2005).advanceDurationMs!==110)errors.push('second inline skill save failed');
  await page.reload();await page.waitForSelector('[data-skill-field]');
  if(await page.locator('[data-skill-parameters="2001"] [data-skill-field="hitStopMs"]').inputValue()!=='175')errors.push('inline skill reload failed');
  if(await page.locator('[data-skill-parameters="2005"] [data-skill-field="advanceDurationMs"]').inputValue()!=='110')errors.push('second inline skill reload failed');
 }
}
await page.setViewportSize({width:1024,height:768});for(const route of ['/','/characters','/actions','/monster-actions','/items']){await page.goto(fixtureBase+route);await page.waitForSelector(route==='/'?'.map-canvas':'tbody tr');if(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth))errors.push(route+' overflow at 1024');}
console.log('BROWSER_SAVE_AND_RELOAD_OK');
console.log('BROWSER_ERRORS',JSON.stringify(errors));if(errors.length)process.exitCode=1;
}finally{await browser.close();await new Promise(r=>fixture.close(r));await rm(temporary,{recursive:true,force:true});}
