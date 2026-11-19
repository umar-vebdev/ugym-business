const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { design, color, iconSvg, componentVisual, typography } = require('./code');

function escape(value) {
  return String(value).replace(/[&<>"']/g, (char) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[char]);
}

function validate(pages) {
  const variantKeys = new Set();
  let links = 0;
  for (const page of pages) {
    const frames = new Set();
    const targets = [];
    walk(page, null);
    for (const target of targets) {
      assert.ok(frames.has(target), page.name + ': missing prototype frame ' + target);
    }
    links += targets.length;
    function walk(item, parent) {
      if (item.id) {
        assert.equal(parent.type, 'page');
        assert.ok(!frames.has(item.id), 'Duplicate frame ' + item.id);
        frames.add(item.id);
      }
      if (item.target) targets.push(item.target);
      if (parent && !parent.clip) {
        assert.ok(item.x >= 0 && item.y >= 0 &&
          item.x + item.width <= parent.width && item.y + item.height <= parent.height,
        page.name + ': ' + item.name + ' exceeds ' + parent.name);
      }
      for (const key of [item.fill, item.stroke, item.color].filter(Boolean)) {
        color(key, 'Light');
        color(key, 'Dark');
      }
      if (item.type === 'componentSet') {
        for (const child of item.children) variantKeys.add(item.group + '|' + child.variant);
      }
      if (item.type === 'instance') assert.ok(variantKeys.has(item.group + '|' + item.variant));
      for (const child of item.children) walk(child, item);
    }
    console.error(page.name + ' · ' + frames.size + ' экранов');
  }
  console.error(variantKeys.size + ' вариантов компонентов · ' + links + ' связей');
}

let clipCount = 0;
function render(item, inheritedMode) {
  const mode = item.mode || inheritedMode;
  let body = '';
  const children = item.children;
  if (item.type === 'instance') {
    item = { ...item, children: [] };
    componentVisual(item, item.group, item.variant, item.label);
  }
  const fill = item.fill ? color(item.fill, mode) : 'none';
  const edge = item.stroke ? ' stroke="' + color(item.stroke, mode) + '" stroke-width="' +
    (item.strokeWeight || 1) + '"' : '';
  const rect = '<rect width="' + item.width + '" height="' + item.height + '" rx="' +
    (item.radius || 0) + '"';
  let clip = '';
  if (item.clip) {
    const id = 'mask-' + (++clipCount);
    body += '<clipPath id="' + id + '">' + rect + '/></clipPath>';
    clip = ' clip-path="url(#' + id + ')"';
  }
  const id = item.id ? ' id="' + item.id + '"' : '';
  const opacity = item.opacity === undefined ? '' : ' opacity="' + item.opacity + '"';
  const start = '<g' + id + opacity + ' transform="translate(' + item.x + ' ' + item.y + ')">';
  if (item.type === 'text') {
    const [size, lineHeight, style, family = 'Inter'] = typography[item.style];
    const weights = { Regular: 400, Medium: 500, 'Semi Bold': 600, SemiBold: 600, Bold: 700 };
    const anchors = { left: [0, 'start'], center: [item.width / 2, 'middle'], right: [item.width, 'end'] };
    const [x, anchor] = anchors[item.align];
    for (const [i, line] of item.value.split('\n').entries()) {
      const baseline = lineHeight * i + (lineHeight + size * 0.73) / 2;
      body += '<text data-fit-width="' + item.width + '" x="' + x + '" y="' + baseline + '" text-anchor="' + anchor +
        '" fill="' + color(item.color, mode) + '" font-family="' + family + '" font-size="' + size +
        '" font-weight="' + weights[style] + '">' + escape(line) + '</text>';
    }
  } else if (item.type === 'vector' || item.type === 'icon') {
    body += iconSvg(item, mode);
  } else {
    if (item.fill || item.stroke || item.target) {
      body += rect + ' fill="' + (item.target && fill === 'none' ? 'transparent' : fill) + '"' + edge + '/>';
    }
    const contents = item.children.map((child) => render(child, mode)).join('\n');
    body += clip ? '<g' + clip + '>' + contents + '</g>' : contents;
  }
  const group = start + body + '</g>';
  return item.target
    ? '<a href="#' + item.target + '" aria-label="' + escape(item.name) + '"><title>' +
      escape(item.name) + '</title>' + group + '</a>' : group;
}

const pages = design();
validate(pages);
if (process.argv.includes('--check')) process.exit(0);

const boardNames = ['uCraft', 'uGym', 'uGym Business'];
const boards = pages.map((page, i) => '<section id="board-' + i + '" aria-label="' +
  boardNames[i] + '"' + (i === 0 ? '' : ' hidden') + '><svg xmlns="http://www.w3.org/2000/svg" ' +
  'width="' + page.width + '" height="' + page.height + '" viewBox="0 0 ' + page.width + ' ' +
  page.height + '">' + render(page, 'Light') + '</svg></section>');

const html = `<!doctype html>
<html lang="ru">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>uCraft · Макеты uGym и uGym Business</title>
<style>
@font-face{font-family:Inter;src:url(../../../assets/fonts/Inter-Variable.ttf);font-weight:100 900}
@font-face{font-family:"Geist Mono";src:url(../../../assets/fonts/GeistMono-Variable.ttf);font-weight:100 900}
:root{font-family:Inter,system-ui,sans-serif;color:#151d2b;background:#eeeff2}
*{box-sizing:border-box}body{margin:0}
header{position:sticky;top:0;z-index:1;display:flex;align-items:center;justify-content:space-between;gap:16px;flex-wrap:wrap;min-height:64px;padding:12px clamp(16px,4vw,64px);background:#fff;border-bottom:1px solid #dfe5ef}
header strong{font-size:15px}nav,.controls{display:flex;align-items:center;gap:6px;flex-wrap:wrap}
button{font:600 13px Inter,system-ui,sans-serif;border:1px solid transparent;background:#fff;color:#526078;min-height:36px;padding:6px 12px;border-radius:8px;cursor:pointer}
button[aria-pressed=true]{background:#edf1ff;color:#1734c0}
button:hover{border-color:#a2b8ff}button:focus-visible,a:focus-visible{outline:2px solid #2248f5;outline-offset:3px}
main{overflow-x:auto}main section{width:var(--board-width,100%);min-width:640px;max-width:2700px;margin:0 auto}
section>svg{width:100%;height:auto;display:block}svg a{cursor:pointer}
.controls{font-size:13px;color:#526078}output{min-width:42px;font-variant-numeric:tabular-nums}
[id]{scroll-margin-top:94px}
@media(max-width:640px){header{padding:8px 12px;gap:4px}header strong{display:none}.controls{gap:0}button{padding-inline:8px}}
</style>
<header>
  <strong>uCraft · Макеты</strong>
  <nav aria-label="Листы макета">${boardNames.map((name, i) =>
    '<button type="button" data-board="' + i + '" aria-controls="board-' + i +
    '" aria-pressed="' + (i === 0) + '">' + name + '</button>').join('')}</nav>
  <div class="controls" aria-label="Просмотр и экспорт">
    <button type="button" id="export">Скачать SVG</button>
    <button type="button" data-zoom="-25" aria-label="Уменьшить">−</button>
    <output aria-live="polite">100%</output>
    <button type="button" data-zoom="25" aria-label="Увеличить">+</button>
  </div>
</header>
<main>${boards.join('\n')}</main>
<script>
const boardButtons = [...document.querySelectorAll('[data-board]')];
let zoom = 100;
function selectBoard(value, top = true) {
  for (const button of boardButtons) {
    const current = button.dataset.board === String(value);
    button.setAttribute('aria-pressed', current);
    document.getElementById(button.getAttribute('aria-controls')).hidden = !current;
  }
  if (top) window.scrollTo(0, 0);
}
for (const button of boardButtons) {
  button.addEventListener('click', () => {
    history.replaceState(null, '', '#board-' + button.dataset.board);
    selectBoard(button.dataset.board);
  });
}
for (const button of document.querySelectorAll('[data-zoom]')) {
  button.addEventListener('click', () => {
    zoom = Math.min(250, Math.max(75, zoom + Number(button.dataset.zoom)));
    document.documentElement.style.setProperty('--board-width', zoom + '%');
    document.querySelector('output').textContent = zoom + '%';
  });
}
document.getElementById('export').addEventListener('click', () => {
  const active = document.querySelector('main section:not([hidden])');
  const svg = active.querySelector('svg').cloneNode(true);
  for (const link of svg.querySelectorAll('a')) {
    link.querySelector('title')?.remove();
    link.replaceWith(...link.childNodes);
  }
  const content = new XMLSerializer().serializeToString(svg);
  const url = URL.createObjectURL(new Blob([content], { type: 'image/svg+xml;charset=utf-8' }));
  const download = document.createElement('a');
  download.href = url;
  download.download = active.getAttribute('aria-label').replaceAll(' ', '-') + '.svg';
  download.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
});
function goToHash() {
  const item = document.getElementById(location.hash.slice(1));
  const section = item?.closest('section');
  if (!section) return;
  selectBoard(section.id.slice(-1), item === section);
  if (item !== section) item.scrollIntoView({ block: 'start', inline: 'nearest' });
}
window.addEventListener('hashchange', goToHash);
goToHash();
</script>
</html>
`;

const output = process.argv[2] || path.join(__dirname, 'preview.html');
fs.writeFileSync(output, html);
