import json, os, glob
os.chdir(os.path.dirname(os.path.abspath(__file__)))
heros = open('src/heros.json', encoding='utf-8').read()
css = open('src/core.css', encoding='utf-8').read() + '\n' + '\n'.join(open(f, encoding='utf-8').read() for f in sorted(glob.glob('src/[cdmns]*_*.css')))
core = open('src/core.js', encoding='utf-8').read()
assert core.count('/*HEROS*/[]') == 1
core = core.replace('/*HEROS*/[]', heros)
js = core + '\n' + '\n'.join(open(f, encoding='utf-8').read() for f in sorted(glob.glob('src/[cdmns]*_*.js')))
page = open('src/page.html', encoding='utf-8').read().replace('/*CSS*/', css).replace('/*JS*/', js)
open('arene.html.tmp', 'w', encoding='utf-8').write(page)
os.replace('arene.html.tmp', 'arene.html')
open('chk.js', 'w', encoding='utf-8').write(js + '\nmontrerMenu;')
print('arene.html', len(page)//1024, 'Ko ;', len(glob.glob('src/[cdns]*_*.js')), 'démos')
