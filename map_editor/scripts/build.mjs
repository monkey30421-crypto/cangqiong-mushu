import {mkdir,cp,writeFile} from 'node:fs/promises';
import {join} from 'node:path';
import {build} from 'esbuild';
import {editorRoot} from './store.mjs';
export async function buildEditor(){
 await mkdir(join(editorRoot,'dist/vendor'),{recursive:true});
 await cp(join(editorRoot,'public'),join(editorRoot,'dist'),{recursive:true});
 await build({stdin:{contents:"export * from '@esotericsoftware/spine-webgl';",resolveDir:editorRoot,sourcefile:'spine-runtime.js'},bundle:true,format:'esm',target:'es2022',outfile:join(editorRoot,'dist/vendor/spine.js'),minify:true});
 await writeFile(join(editorRoot,'dist/build-info.json'),JSON.stringify({builtAt:new Date().toISOString()}));
 console.log('EDITOR_BUILD_OK');
}
if(process.argv[1]?.endsWith('/build.mjs'))await buildEditor();
