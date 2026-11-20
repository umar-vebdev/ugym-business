// Shared drawing definitions for the Figma import and the offline preview.
const palette = {
  white: ['FFFFFF', 'FFFFFF'],
  ink: ['151D2B', '151D2B'],
  canvas: ['EEEFF2', 'EEEFF2'],
  board: ['FFFFFF', 'FFFFFF'],
  boardSubtle: ['F3F5F8', 'F3F5F8'],
  boardText: ['526078', '526078'],
  background: ['F5F7FA', '151C29'],
  surface: ['FFFFFF', '202A39'],
  secondary: ['ECF1F8', '293548'],
  tile: ['F0F4FE', '293548'],
  hero: ['E4EBF7', '293B58'],
  foreground: ['151D2B', 'E5EAF2'],
  secondaryText: ['526078', 'A8B4C5'],
  muted: ['526078', '94A3B8'],
  line: ['DFE5EF', '344156'],
  inputBorder: ['7989A4', '71819A'],
  primary: ['315FCB', '7C9CD8'],
  primaryText: ['315FCB', 'A0B5DE'],
  pressed: ['244CAA', '6D88BD'],
  onPrimary: ['FFFFFF', '151C29'],
  progressTrack: ['C9D4E6', '344156'],
  disabled: ['E3EAF7', '293548'],
  onDisabled: ['4E608D', 'A8B4C5'],
  success: ['116443', '9BC6AD'],
  successBg: ['E0F6EC', '2B413A'],
  warning: ['835219', 'CFB487'],
  warningBg: ['FFF0D8', '443A32'],
  error: ['A82B3B', 'D7A2AA'],
  errorBg: ['FFEBEF', '44323D'],
  overlay: ['151D2B', '151C29'],
};

const typography = {
  display: [32, 40, 'Semi Bold'],
  headline: [24, 32, 'Semi Bold'],
  title: [20, 28, 'Medium'],
  section: [18, 26, 'Semi Bold'],
  large: [16, 24, 'Regular'],
  body: [14, 21, 'Regular'],
  medium: [14, 21, 'Medium'],
  label: [13, 18, 'Medium'],
  caption: [12, 17, 'Regular'],
  small: [11, 16, 'Medium'],
  metric: [28, 36, 'Semi Bold'],
  moneyLabel: [12, 17, 'Medium'],
  monoSample: [28, 36, 'Medium', 'Geist Mono'],
  number: [16, 24, 'Medium', 'Geist Mono'],
  time: [12, 17, 'Medium', 'Geist Mono'],
};

const moneyStyles = new Set(['metric', 'moneyLabel']);

// The prototypes use Russian labels. Format their integer TJS amounts without
// depending on Intl, which is unavailable in the Figma plugin sandbox.
function somoni(minor) {
  const sign = minor < 0 ? '−' : '';
  const digits = String(Math.abs(minor)).padStart(3, '0');
  const whole = digits.slice(0, -2).replace(/\B(?=(\d{3})+(?!\d))/g, '\u00a0');
  return sign + whole + ',' + digits.slice(-2) + '\u00a0TJS';
}

const paths = {
  home: 'M3 10l9-7 9 7v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z M9 21v-8h6v8',
  pin: 'M20 10c0 5-8 11-8 11s-8-6-8-11a8 8 0 1 1 16 0z M15 10a3 3 0 1 1-6 0 3 3 0 0 1 6 0z',
  qr: 'M3 3h6v6H3z M15 3h6v6h-6z M3 15h6v6H3z M15 15h2v2h-2z M21 15v2 M15 21h2 M21 21v-2h-2',
  scan: 'M8 3H5a2 2 0 0 0-2 2v3 M16 3h3a2 2 0 0 1 2 2v3 M21 16v3a2 2 0 0 1-2 2h-3 M8 21H5a2 2 0 0 1-2-2v-3 M7 12h10',
  dumbbell: 'M6.5 6.5l11 11 M21 21l-1-1 M3 3l1 1 M18 14l-4 4 M10 6l-4 4 M20 16l-4 4 M8 4L4 8',
  user: 'M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2 M16 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0z',
  users: 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2 M13 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0z M22 21v-2a4 4 0 0 0-3-3.9 M16 3a4 4 0 0 1 0 8',
  wallet: 'M20 8V6a2 2 0 0 0-2-2H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H5a2 2 0 0 1-2-2V6 M21 12h-5a2 2 0 0 0 0 4h5',
  calendar: 'M3 5h18v16H3z M16 3v4 M8 3v4 M3 10h18',
  grid: 'M3 3h7v7H3z M14 3h7v7h-7z M3 14h7v7H3z M14 14h7v7h-7z',
  arrow: 'M19 12H5 M12 19l-7-7 7-7',
  next: 'M9 18l6-6-6-6',
  down: 'M6 9l6 6 6-6',
  check: 'M20 6L9 17l-5-5',
  plus: 'M12 5v14 M5 12h14',
  x: 'M18 6L6 18 M6 6l12 12',
  search: 'M17 10a7 7 0 1 1-14 0 7 7 0 0 1 14 0z M21 21l-6-6',
  sliders: 'M4 7h8 M16 7h4 M4 17h4 M12 17h8 M12 4v6 M8 14v6',
  ticket: 'M4 5h16a1 1 0 0 1 1 1v3a3 3 0 0 0 0 6v3a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-3a3 3 0 0 0 0-6V6a1 1 0 0 1 1-1z M14 8v1 M14 12v1 M14 16v1',
  clock: 'M22 12a10 10 0 1 1-20 0 10 10 0 0 1 20 0z M12 6v6l4 2',
  bell: 'M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9 M10 21h4',
  mail: 'M3 5h18v14H3z M3 7l9 6 9-6',
  eye: 'M2 12s4-7 10-7 10 7 10 7-4 7-10 7-10-7-10-7z M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0z',
  lock: 'M5 10h14v11H5z M8 10V7a4 4 0 0 1 8 0v3 M12 14v3',
  alert: 'M10.3 4.5L2.5 18a2 2 0 0 0 1.7 3h15.6a2 2 0 0 0 1.7-3L13.7 4.5a2 2 0 0 0-3.4 0z M12 9v4 M12 17h.01',
  chart: 'M3 3v18h18 M8 16v-3 M13 16V9 M18 16V6',
  bag: 'M5 8h14l2 13H3z M8 10V6a4 4 0 0 1 8 0v4',
  bolt: 'M13 2L3 14h8l-1 8 10-12h-8z',
  wifi: 'M2 8a16 16 0 0 1 20 0 M5 12a11 11 0 0 1 14 0 M8 16a6 6 0 0 1 8 0 M12 20h.01',
  signal: 'M4 20v-3 M9 20v-6 M14 20V10 M19 20V6',
  battery: 'M2 7h17v10H2z M22 10v4 M5 10h11v4H5z',
  refresh: 'M20 7v5h-5 M4 17v-5h5 M6 7a7 7 0 0 1 12-1l2 3 M4 15l2 3a7 7 0 0 0 12-1',
  backspace: 'M9 5h13v14H9l-7-7z M13 9l6 6 M19 9l-6 6',
  receipt: 'M5 3l3 2 4-2 4 2 3-2v18l-3-2-4 2-4-2-3 2z M9 9h6 M9 13h6',
  filters: 'M3 5h18l-7 8v5l-4 2v-7z',
};

const W = 390;
const H = 844;
const pageWidth = 1800;
const appSections = [
  { key: 'auth', title: 'Вход и подтверждение почты', y: 122 },
  { key: 'main', title: 'Главная и повседневные действия', y: 1090 },
  { key: 'states', title: 'Темы и состояния', y: 2058 },
];

function node(parent, type, name, x, y, width, height, attributes = {}) {
  const item = { type, name, x, y, width, height, children: [], ...attributes };
  if (parent) parent.children.push(item);
  return item;
}

function box(p, name, x, y, w, h, fill, radius = 0, stroke, target) {
  return node(p, 'frame', name, x, y, w, h, { fill, radius, stroke, target });
}

function shape(p, name, x, y, w, h, fill, radius = 0) {
  return node(p, 'rect', name, x, y, w, h, { fill, radius });
}

function text(p, value, x, y, w, style = 'body', color = 'foreground', align = 'left', name) {
  const lines = value.split('\n').length;
  return node(p, 'text', name || value, x, y, w, typography[style][1] * lines, {
    value, style, color, align,
  });
}

function icon(p, key, x, y, size = 24, color = 'primary') {
  if (!paths[key]) throw new Error('Unknown icon: ' + key);
  return node(p, 'icon', key, x, y, size, size, { path: paths[key], color });
}

function logo(p, x, y, size, lockup = 'avatar') {
  return node(p, 'logo', lockup === 'primary' ? 'uCraft / Логотип' : 'uCraft / Компактный знак',
    x, y, size, lockup === 'primary' ? size * 0.3 : size, { lockup });
}

function component(p, group, variant, name, x, y, w, h, label, target) {
  return node(p, 'instance', name, x, y, w, h, { group, variant, label, target });
}

const buttonStates = ['Default', 'Pressed', 'Focused', 'Disabled', 'Loading'];
const fieldStates = ['Default', 'Focused', 'Filled', 'Error', 'Disabled'];
const families = {
  'Button / Primary': buttonStates.map((state) => ({ state, width: 350, height: 48 })),
  'Button / Secondary': buttonStates.map((state) => ({ state, width: 350, height: 48 })),
  'Field / Text': fieldStates.map((state) => ({ state, width: 350, height: 52 })),
};

function componentVisual(p, group, variant, label) {
  const primary = group === 'Button / Primary';
  const isField = group === 'Field / Text';
  const disabled = variant === 'Disabled';
  const focused = variant === 'Focused';
  const isError = variant === 'Error';
  const fill = disabled ? 'disabled' : primary ? (variant === 'Pressed' ? 'pressed' : 'primary')
    : variant === 'Pressed' ? 'secondary' : 'surface';
  const ink = disabled ? 'onDisabled' : primary ? 'onPrimary'
    : isField && variant !== 'Filled' && !isError ? 'muted' : 'foreground';
  const stroke = focused ? 'primary' : isError ? 'error' : disabled || primary ? undefined : 'inputBorder';
  p.fill = fill;
  p.stroke = stroke;
  p.strokeWeight = focused ? 2 : 1;
  p.radius = 8;
  if (variant === 'Loading') {
    icon(p, 'refresh', 94, 15, 18, ink);
  }
  text(p, label, isField ? 14 : 8, isField ? 14 : 15, isField ? 282 : 334,
    isField ? 'large' : 'label', ink, isField ? 'left' : 'center', 'Label');
  if (focused && primary) shape(p, 'Фокус', 16, 40, 318, 2, 'onPrimary', 1);
}

function button(p, label, y, target, kind = 'Primary', state = 'Default', x = 20) {
  return component(p, 'Button / ' + kind, state, label, x, y, 350, 48, label,
    state === 'Disabled' || state === 'Loading' ? undefined : target);
}

function field(p, label, value, y, state = 'Default', glyph) {
  text(p, label, 20, y, 350, 'label');
  component(p, 'Field / Text', state, label, 20, y + 24, 350, 52, value);
  if (glyph) icon(p, glyph, 332, y + 40, 20, 'muted');
}

function segment(p, items, selected, x, y, width) {
  const frame = box(p, 'Переключатель', x, y, width, 48, 'secondary', 12);
  const cell = (width - 8) / items.length;
  items.forEach(([label, target], index) => {
    const active = index === selected;
    const tab = box(frame, label, 4 + index * cell, 4, cell, 40,
      active ? 'surface' : undefined, 8, active ? 'inputBorder' : undefined, target);
    text(tab, label, 4, 11, cell - 8, 'label', active ? 'primaryText' : 'muted', 'center');
  });
}

function pill(p, label, x, y, w, kind = 'success', glyph = 'check') {
  const badge = box(p, label, x, y, w, 28, kind + 'Bg', 14);
  icon(badge, glyph, 8, 6, 16, kind);
  text(badge, label, 28, 6, w - 34, 'small', kind);
}

function section(p, title, y, action, target) {
  text(p, title, 20, y, action ? 230 : 350, 'section');
  if (action) {
    const link = box(p, action, 254, y - 10, 116, 48, undefined, 0, undefined, target);
    text(link, action, 0, 15, 116, 'label', 'primaryText', 'right');
  }
}

function progress(p, x, y, w, fraction) {
  shape(p, 'Шкала', x, y, w, 8, 'progressTrack', 4);
  shape(p, 'Значение', x, y, w * fraction, 8, 'primary', 4);
}

function glyphTile(p, glyph, x, y, size = 40, fill = 'tile') {
  const tile = box(p, glyph, x, y, size, size, fill, 12);
  icon(tile, glyph, (size - 20) / 2, (size - 20) / 2, 20);
  return tile;
}

function row(p, y, title, detail, options = {}) {
  const { glyph, time, tail, tailStyle = 'caption', tone = 'muted', target, last = false } = options;
  const r = box(p, title, 20, y, 350, 64, undefined, 0, undefined, target);
  if (glyph) glyphTile(r, glyph, 0, 12);
  if (time) text(r, time, 0, 23, 48, 'time', 'muted');
  const start = glyph || time ? 52 : 0;
  text(r, title, start, 11, tail ? 210 - start : 275 - start, 'medium');
  text(r, detail, start, 34, 276 - start, 'caption', 'secondaryText');
  if (tail) text(r, tail, 234, 13, 116, tailStyle, tone, 'right');
  else if (target) icon(r, 'next', 328, 22, 20, 'muted');
  if (!last) shape(r, 'Разделитель', 0, 63, 350, 1, 'line');
}

function actionTiles(p, list, y) {
  list.forEach(([label, glyph, target], i) => {
    const w = 110;
    const tile = box(p, label.replace('\n', ' '), 20 + 120 * i, y, w, 80, 'tile', 12, undefined, target);
    glyphTile(tile, glyph, 41, 8, 28, 'surface');
    text(tile, label, 4, 42, w - 8, 'small', 'foreground', 'center');
  });
}

function status(p, width = W) {
  text(p, '9:41', 24, 13, 55, 'label');
  ['signal', 'wifi', 'battery'].forEach((glyph, i) => icon(p, glyph, width - 78 + 19 * i, 15, 16, 'foreground'));
}

function homeIndicator(p, width = W, height = H) {
  shape(p, 'Системная полоска', (width - 134) / 2, height - 10, 134, 4, 'foreground', 2);
}

const memberNav = [
  ['Главная', 'home', 'member-home'], ['Залы', 'pin', 'member-clubs'], ['Чекин', 'qr', 'member-qr'],
  ['Тренировки', 'dumbbell', 'member-workouts'], ['Профиль', 'user', 'member-profile'],
];
const businessNav = [
  ['Ресепшн', 'home', 'biz-home'], ['Клиенты', 'users', 'biz-clients'], ['Касса', 'wallet', 'biz-pos'],
  ['Расписание', 'calendar', 'biz-schedule'], ['Управление', 'grid', 'biz-manage'],
];

function nav(p, entries, selected) {
  const bar = box(p, 'Нижняя навигация', 0, H - 80, W, 80, 'surface');
  shape(bar, 'Разделитель', 0, 0, W, 1, 'line');
  const width = W / entries.length;
  entries.forEach(([label, glyph, target], i) => {
    const active = i === selected;
    const item = box(bar, label, i * width, 1, width, 63, undefined, 0, undefined, target);
    if (active) shape(item, 'Активная вкладка', (width - 44) / 2, 6, 44, 32, 'hero', 12);
    icon(item, glyph, (width - 24) / 2, 10, 24, active ? 'primary' : 'muted');
    text(item, label, 0, 41, width, 'small', active ? 'primaryText' : 'muted', 'center');
  });
  homeIndicator(p);
}

function phone(page, name, id, sectionKey, col, options = {}) {
  const { dark = false, system = true } = options;
  const fill = options.fill || (dark ? 'background' : 'surface');
  const y = appSections.find(({ key }) => key === sectionKey).y + 70;
  const x = 32 + col * 434;
  text(page, name, x, y - 28, W, 'label', 'boardText');
  const p = box(page, name, x, y, W, H, fill, 24);
  Object.assign(p, { id, mode: dark ? 'Dark' : 'Light', clip: true, stroke: 'line' });
  if (system) status(p);
  return p;
}

function header(p, title, back, action) {
  if (back) {
    const hit = box(p, 'Назад', 12, 48, 48, 48, undefined, 0, undefined, back);
    icon(hit, 'arrow', 12, 12, 24, 'foreground');
  }
  text(p, title, back ? 68 : 20, 57, back ? 270 : 305, 'headline');
  if (action) {
    const hit = box(p, action[0], 322, 48, 48, 48, 'tile', 12, undefined, action[2]);
    icon(hit, action[1], 12, 12, 24);
  }
}

function description(p, title, detail, top, glyph, tone) {
  const tile = box(p, glyph, 167, top, 56, 56, tone ? tone + 'Bg' : 'tile', 16);
  icon(tile, glyph, 14, 14, 28, tone || 'primary');
  text(p, title, 24, top + 72, 342, 'title', 'foreground', 'center');
  text(p, detail, 24, top + 108, 342, 'body', 'secondaryText', 'center');
}

function boardHeader(page, label, detail, styleguide = false) {
  const b = box(page, 'Шапка страницы', 32, 24, pageWidth - 64, 72, 'board', 24);
  if (styleguide) {
    logo(b, 24, 14.4, 144, 'primary');
    text(b, label, 184, 19, 440, 'headline', 'ink');
  } else {
    logo(b, 24, 20, 32);
    text(b, label, 74, 19, 550, 'headline', 'ink');
  }
  text(b, detail, 632, 27, pageWidth - 732, 'body', 'boardText', 'right');
}

function keyboard(p, y) {
  const base = box(p, 'Системная цифровая клавиатура', 0, y, W, H - y, 'secondary');
  const letters = ['', 'ABC', 'DEF', 'GHI', 'JKL', 'MNO', 'PQRS', 'TUV', 'WXYZ'];
  for (let i = 0; i < 10; i++) {
    const col = i === 9 ? 1 : i % 3;
    const row = Math.floor(i / 3);
    const key = box(base, 'Клавиша ' + ((i + 1) % 10), 8 + col * 126, 8 + row * 49, 122, 45, 'surface', 8);
    text(key, String((i + 1) % 10), 0, i === 9 ? 10 : 3, 122, 'title', 'foreground', 'center');
    if (letters[i]) text(key, letters[i], 0, 27, 122, 'small', 'muted', 'center');
  }
  icon(base, 'backspace', 306, 163, 22, 'foreground');
}

function brand(p, name, y) {
  const tile = box(p, 'Знак uCraft', 173, y, 44, 44, 'tile', 12);
  logo(tile, 8, 8, 28);
  text(p, name, 20, y + 52, 350, 'headline', 'foreground', 'center');
}

function auth(page, prefix, product, main) {
  const client = prefix === 'member';
  let p = phone(page, '01 · Запуск', prefix + '-splash', 'auth', 0, { fill: 'background' });
  shape(p, 'Фоновая форма верхняя', -98, 78, 232, 232, 'hero', 116);
  shape(p, 'Фоновая форма нижняя', 236, 576, 260, 260, 'hero', 130);
  brand(p, product, 308);
  text(p, client ? 'Абонементы и тренировки' : 'Ресепшн и управление залом',
    20, 410, 350, 'body', 'secondaryText', 'center');
  button(p, 'Войти в аккаунт', 684, prefix + '-login');
  if (client) button(p, 'Посмотреть залы', 744, 'member-clubs', 'Secondary');
  homeIndicator(p);

  p = phone(page, '02 · Вход по email', prefix + '-login', 'auth', 1);
  brand(p, product, 84);
  text(p, 'Вход в аккаунт', 20, 178, 350, 'title', 'foreground', 'center');
  text(p, 'Введите email или телефон и пароль.', 20, 214, 350, 'body', 'secondaryText', 'center');
  segment(p, [['Email'], ['Телефон', prefix + '-phone']], 0, 20, 268, 350);
  field(p, 'Email', 'name@example.com', 338, 'Default', 'mail');
  field(p, 'Пароль', 'Введите пароль', 434, 'Default', 'eye');
  text(p, 'Забыли пароль?', 20, 530, 350, 'label', 'primaryText', 'right');
  button(p, 'Войти', 732, undefined, 'Primary', 'Disabled');
  homeIndicator(p);

  p = phone(page, '03 · Вход по телефону', prefix + '-phone', 'auth', 2);
  brand(p, product, 84);
  text(p, 'Вход в аккаунт', 20, 178, 350, 'title', 'foreground', 'center');
  text(p, 'Введите номер, указанный при регистрации.', 20, 214, 350, 'body', 'secondaryText', 'center');
  segment(p, [['Email', prefix + '-login'], ['Телефон']], 1, 20, 268, 350);
  field(p, 'Номер телефона', '+992 900 00 00 00', 338, 'Focused');
  field(p, 'Пароль', '••••••••', 434, 'Filled', 'eye');
  text(p, 'Забыли пароль?', 20, 530, 350, 'label', 'primaryText', 'right');
  button(p, 'Войти', 732, main);
  homeIndicator(p);

  p = phone(page, '04 · Код из письма', prefix + '-verify', 'auth', 3, { fill: 'background' });
  header(p, 'Подтверждение', prefix + '-login');
  const panel = box(p, 'Подтверждение email', 20, 136, 350, 398, 'surface', 20);
  glyphTile(panel, 'mail', 151, 28, 48);
  text(panel, 'Введите код', 16, 90, 318, 'headline', 'foreground', 'center');
  text(panel, 'Отправили письмо на\nname@example.com', 16, 134, 318, 'body', 'secondaryText', 'center');
  for (let i = 0; i < 6; i++) {
    const active = i === 2;
    const input = box(panel, 'Цифра ' + (i + 1), 16 + i * 54, 196, 48, 54, 'surface', 8, active ? 'primary' : 'inputBorder');
    if (active) input.strokeWeight = 2;
    if (i < 2) text(input, i === 0 ? '5' : '4', 0, 15, 48, 'number', 'foreground', 'center');
    if (active) shape(input, 'Курсор', 23, 17, 2, 20, 'primary');
  }
  text(panel, 'Повторная отправка через 0:42', 16, 272, 318, 'caption', 'secondaryText', 'center');
  const later = box(panel, 'Подтвердить позже', 16, 300, 318, 48, undefined, 0, undefined, client ? main : undefined);
  if (client) text(later, 'Подтвердить позже', 0, 14, 318, 'label', 'primaryText', 'center');
  keyboard(p, 612);
  homeIndicator(p);
}

function qr(p, x, y, size) {
  // Deliberately decorative matrix. It carries no check-in token.
  const plate = box(p, 'Демонстрационный QR', x, y, size, size, 'white', 16);
  const margin = 18;
  const cell = (size - margin * 2) / 25;
  const markers = [[0, 0], [18, 0], [0, 18]];
  const insideMarker = (col, row) => markers.some(([a, b]) =>
    col >= a - 1 && col <= a + 7 && row >= b - 1 && row <= b + 7);
  let pattern = '';
  for (let row = 0; row < 25; row++) {
    for (let col = 0; col < 25; col++) {
      if (!insideMarker(col, row) && ((col * 17 + row * 11 + col * row * 7) % 13) < 6) {
        pattern += 'M' + col + ' ' + row + 'h1v1h-1z ';
      }
    }
  }
  for (const [col, row] of markers) {
    pattern += 'M' + col + ' ' + row + 'h7v7h-7z m1 1v5h5v-5z m1 1h3v3h-3z ';
  }
  node(plate, 'vector', 'Матрица QR (демо)', margin, margin, cell * 25, cell * 25,
    { path: pattern.trim(), color: 'ink', view: 25 });
}

function memberHome(p, empty = false) {
  const dark = p.mode === 'Dark';
  const notifications = dark ? undefined : 'member-profile';
  text(p, 'Доброе утро', 20, 57, 174, 'caption', 'muted');
  text(p, 'Салом, Мадина!', 20, 75, 280, 'headline');
  const profile = box(p, 'Профиль', 322, 55, 48, 48, 'tile', 24, undefined, notifications);
  text(profile, 'М', 0, 12, 48, 'large', 'primaryText', 'center');

  const hero = box(p, 'Мой абонемент', 20, 128, 350, 188, 'hero', 20);
  text(hero, 'МОЙ АБОНЕМЕНТ', 20, 20, 176, 'small', 'secondaryText');
  text(hero, empty ? 'Первый абонемент' : 'Фитнес · 12 визитов', 20, 58, 310, 'title');
  text(hero, empty ? 'Выберите тариф в каталоге залов.' : 'Atlas Fitness · Душанбе', 20, 92, 310, 'body', 'secondaryText');
  if (empty) {
    glyphTile(hero, 'ticket', 278, 16, 48, 'surface');
  } else {
    pill(hero, 'Активен', 230, 16, 100);
    progress(hero, 20, 130, 310, 8 / 12);
    text(hero, '8 из 12 визитов', 20, 149, 153, 'time');
    text(hero, 'До 28 ноября', 178, 149, 152, 'caption', 'secondaryText', 'right');
  }

  button(p, empty ? 'Выбрать зал' : 'Показать мой QR', 332, empty ? 'member-clubs' : dark ? 'member-qr-dark' : 'member-qr');
  section(p, 'Быстрые действия', 408);
  actionTiles(p, [
    ['Сканировать\nQR зала', 'scan', 'member-scan'],
    ['Мои\nабонементы', 'ticket', 'member-memberships'],
    ['История\nвизитов', 'clock', 'member-visits'],
  ], 446);

  section(p, 'Сегодня в зале', 550, 'Расписание', 'member-schedule');
  row(p, 587, 'Функциональная', 'Зал 2 · Фарид Саидов', { time: '10:30', tail: '4 места', tone: 'success' });
  row(p, 651, 'Пилатес', 'Студия · Лейла Юсуфова', { time: '18:00', tail: '2 места', last: true });
  nav(p, memberNav, 0);
}

function memberQr(p) {
  const dark = p.mode === 'Dark';
  header(p, 'Чекин');
  segment(p, [['Сканировать зал', 'member-scan'], ['Мой QR-код', dark ? undefined : 'member-qr']], 1, 20, 114, 350);
  const panel = box(p, 'Личный QR-код', 20, 184, 350, 436, 'hero', 20);
  text(panel, 'Мой QR-код', 16, 16, 318, 'title', 'foreground', 'center');
  text(panel, 'Покажите код администратору у входа.', 16, 51, 318, 'body', 'secondaryText', 'center');
  qr(panel, 57, 95, 236);
  progress(panel, 40, 357, 270, 42 / 60);
  text(panel, 'Обновление через 42 сек', 16, 377, 318, 'time', 'secondaryText', 'center');
  button(p, 'Открыть историю визитов', 652, 'member-visits', 'Secondary');
  nav(p, memberNav, 2);
}

function search(p, value, y, hint = 'Фильтры') {
  const input = box(p, value, 20, y, 292, 48, 'surface', 8, 'inputBorder');
  icon(input, 'search', 12, 14, 20, 'muted');
  text(input, value, 42, 13, 240, 'body', 'secondaryText');
  const filter = box(p, hint, 322, y, 48, 48, 'secondary', 8);
  icon(filter, 'sliders', 14, 14, 20);
}

function state(p, title, message, glyph, action, target, tone) {
  description(p, title, message, 244, glyph, tone);
  button(p, action, 478, target);
}

function memberPage() {
  const page = node(null, 'page', '02 · uGym', 0, 0, pageWidth, 4216, { fill: 'canvas' });
  boardHeader(page, 'uGym', 'Мобильное приложение для посетителей');
  for (const s of appSections) text(page, s.title, 32, s.y, 850, 'section', 'ink');
  auth(page, 'member', 'uGym', 'member-home');

  memberHome(phone(page, '05 · Главная', 'member-home', 'main', 0));
  memberQr(phone(page, '06 · Личный QR', 'member-qr', 'main', 1));

  let p = phone(page, '07 · Каталог залов', 'member-clubs', 'main', 2);
  header(p, 'Залы');
  segment(p, [['Список'], ['Карта']], 0, 20, 112, 350);
  search(p, 'Найти зал', 176);
  const location = box(p, 'Город', 20, 240, 350, 56, 'hero', 12);
  icon(location, 'pin', 16, 16);
  text(location, 'Душанбе', 54, 17, 240, 'medium');
  icon(location, 'down', 310, 17, 20, 'muted');
  section(p, 'Залы рядом', 324);
  row(p, 366, 'Atlas Fitness', 'Сино · ул. Н. Карабаева', { glyph: 'pin', tail: 'Открыт', tone: 'success', target: 'member-schedule' });
  row(p, 430, 'Navo Sport', 'Шохмансур · пр. Рудаки', { glyph: 'pin', tail: 'Открыт', tone: 'success' });
  row(p, 494, 'Sado Studio', 'Исмоили Сомони · ул. Айни', { glyph: 'pin', last: true });
  nav(p, memberNav, 1);

  p = phone(page, '08 · Расписание зала', 'member-schedule', 'main', 3);
  header(p, 'Расписание', 'member-home');
  text(p, 'Atlas Fitness · 19 ноября', 20, 107, 350, 'body', 'secondaryText');
  const weekdays = ['Пн\n16', 'Вт\n17', 'Ср\n18', 'Чт\n19', 'Пт\n20', 'Сб\n21', 'Вс\n22'];
  weekdays.forEach((day, i) => {
    const pick = box(p, day.replace('\n', ' '), 20 + i * 51, 151, 44, 62, i === 3 ? 'primary' : 'tile', 8);
    text(pick, day, 0, 12, 44, 'label', i === 3 ? 'onPrimary' : 'foreground', 'center');
  });
  section(p, 'Занятия в четверг', 247);
  row(p, 287, 'Функциональная', 'Зал 2 · Фарид Саидов', { time: '10:30', tail: '4 места', tone: 'success' });
  row(p, 351, 'Растяжка', 'Студия · Мадина Саидова', { time: '12:00', tail: '8 мест', tone: 'success' });
  row(p, 415, 'Пилатес', 'Студия · Лейла Юсуфова', { time: '18:00', tail: '2 места', tone: 'success', last: true });
  homeIndicator(p);

  memberHome(phone(page, '09 · Главная / Dark', 'member-home-dark', 'states', 0, { dark: true }));
  memberQr(phone(page, '10 · Личный QR / Dark', 'member-qr-dark', 'states', 1, { dark: true }));
  memberHome(phone(page, '11 · Без абонемента', 'member-empty', 'states', 2), true);

  p = phone(page, '12 · Доступ к камере', 'member-scan', 'states', 3);
  header(p, 'Чекин');
  segment(p, [['Сканировать зал'], ['Мой QR-код', 'member-qr']], 0, 20, 114, 350);
  state(p, 'Разрешите доступ к камере', 'Откройте настройки, чтобы сканировать\nQR у входа в зал.', 'scan', 'Открыть настройки');
  button(p, 'Показать мой QR', 542, 'member-qr', 'Secondary');
  nav(p, memberNav, 2);

  text(page, 'Личный кабинет и тренировки', 32, 3026, 900, 'section', 'ink');

  p = extraPhone(page, '13 · Абонементы', 'member-memberships', 0);
  header(p, 'Мои абонементы', 'member-home');
  segment(p, [['Активные'], ['Прошедшие']], 0, 20, 114, 350);
  const membership = box(p, 'Фитнес · 12 визитов', 20, 188, 350, 166, 'hero', 20);
  pill(membership, 'Активен', 226, 16, 104);
  text(membership, 'Atlas Fitness', 20, 19, 178, 'caption', 'secondaryText');
  text(membership, 'Фитнес · 12 визитов', 20, 58, 310, 'title');
  progress(membership, 20, 104, 310, 8 / 12);
  text(membership, '8 из 12 визитов', 20, 126, 310, 'time');
  button(p, 'Показать мой QR', 374, 'member-qr');
  homeIndicator(p);

  p = extraPhone(page, '14 · История визитов', 'member-visits', 1);
  header(p, 'История визитов', 'member-qr');
  section(p, 'Ноябрь', 128);
  row(p, 170, 'Atlas Fitness', '19 ноября · 08:42 · Личный QR', { glyph: 'qr', tail: 'Завершён', tone: 'success' });
  row(p, 234, 'Atlas Fitness', '17 ноября · 18:06 · QR зала', { glyph: 'qr', tail: 'Завершён', tone: 'success' });
  row(p, 298, 'Atlas Fitness', '14 ноября · 09:12 · Вручную', { glyph: 'clock', tail: 'Отменён', tone: 'error', last: true });
  homeIndicator(p);

  p = extraPhone(page, '15 · Тренировки', 'member-workouts', 2);
  header(p, 'Тренировки');
  const banner = box(p, 'Свободная тренировка', 20, 112, 350, 134, 'hero', 20);
  glyphTile(banner, 'dumbbell', 20, 18);
  text(banner, 'Свободная тренировка', 20, 69, 310, 'title');
  text(banner, 'Записывайте упражнения и подходы.', 20, 103, 310, 'caption', 'secondaryText');
  button(p, 'Начать тренировку', 266);
  section(p, 'Дневник', 338);
  row(p, 376, 'Мои планы', 'Ваши программы', { glyph: 'calendar' });
  row(p, 440, 'Библиотека', 'Упражнения и готовые планы', { glyph: 'grid' });
  row(p, 504, 'История и прогресс', 'Сессии и результаты', { glyph: 'chart', last: true });
  nav(p, memberNav, 3);

  p = extraPhone(page, '16 · Профиль', 'member-profile', 3);
  header(p, 'Профиль');
  const profile = box(p, 'Аккаунт', 20, 111, 350, 133, 'hero', 20);
  const avatar = box(profile, 'М', 18, 22, 48, 48, 'surface', 24);
  text(avatar, 'М', 0, 12, 48, 'large', 'primaryText', 'center');
  text(profile, 'Мадина Каримова', 80, 19, 251, 'title');
  text(profile, 'name@example.com', 80, 50, 250, 'caption', 'secondaryText');
  pill(profile, 'Email не подтверждён', 80, 81, 172, 'warning', 'mail');
  section(p, 'Мои данные', 271);
  row(p, 311, 'Мои абонементы', 'Активные и прошедшие', { glyph: 'ticket', target: 'member-memberships' });
  row(p, 375, 'История визитов', 'Записи о посещениях залов', { glyph: 'clock', target: 'member-visits' });
  row(p, 439, 'Подтверждение email', 'Подтвердите почту кодом из письма', { glyph: 'mail', target: 'member-verify', last: true });
  nav(p, memberNav, 4);
  return page;
}

function extraPhone(page, name, id, col, options = {}) {
  const x = 32 + col * 434;
  const y = 3096;
  text(page, name, x, y - 28, W, 'label', 'boardText');
  const p = box(page, name, x, y, W, H, 'surface', 24);
  Object.assign(p, { id, mode: options.dark ? 'Dark' : 'Light', clip: true, stroke: 'line' });
  status(p);
  return p;
}

function businessHome(p, readOnly = false) {
  const dark = p.mode === 'Dark';
  const heading = box(p, 'Текущий филиал', 20, 48, 281, 52, undefined);
  text(heading, 'Atlas Fitness', 0, 2, 193, 'headline');
  icon(heading, 'down', 167, 9, 20, 'muted');
  text(heading, 'Душанбе · Владелец', 0, 32, 250, 'caption', 'muted');
  const quick = box(p, 'Быстрые действия', 322, 50, 48, 48, 'tile', 12, undefined,
    readOnly ? undefined : 'biz-quick');
  icon(quick, 'bolt', 12, 12);
  let shift = 0;
  if (readOnly) {
    const alert = box(p, 'Режим просмотра', 20, 112, 350, 56, 'warningBg', 8);
    icon(alert, 'lock', 12, 17, 20, 'warning');
    text(alert, 'Подписка истекла', 44, 8, 294, 'label', 'warning');
    text(alert, 'Доступен только просмотр.', 44, 29, 294, 'caption', 'warning');
    shift = 60;
  }
  const hero = box(p, 'Сводка зала', 20, 120 + shift, 350, 178, 'hero', 20);
  text(hero, 'Сегодня · 19 ноября', 16, 13, 242, 'caption', 'secondaryText');
  text(hero, somoni(1147682), 16, 32, 312, 'metric');
  text(hero, 'Выручка зала', 16, 71, 312, 'caption', 'secondaryText');
  const strip = box(hero, 'Показатели дня', 12, 102, 326, 62, 'secondary', 12);
  [['Визиты', '48'], ['Заявки', '6'], ['Истекают', '9']].forEach(([label, value], i) => {
    if (i > 0) shape(strip, 'Разделитель', i * 109, 12, 1, 38, 'line');
    text(strip, value, i * 109, 8, 108, 'number', 'foreground', 'center');
    text(strip, label, i * 109, 34, 108, 'caption', 'secondaryText', 'center');
  });
  button(p, 'Сканировать QR клиента', 314 + shift, dark ? 'biz-allowed' : 'biz-scan',
    'Primary', readOnly ? 'Disabled' : 'Default');
  section(p, 'Операции', 386 + shift, readOnly ? undefined : 'Все операции', 'biz-menu');
  actionTiles(p, readOnly
    ? [['Клиенты', 'users'], ['История\nпродаж', 'receipt'], ['Расписание', 'calendar']]
    : [['QR-табло\nзала', 'qr', 'biz-kiosk'], ['Новая\nпродажа', 'wallet', 'biz-pos'], ['Новый\nклиент', 'users', 'biz-new']], 424 + shift);

  section(p, readOnly ? 'Доступно для просмотра' : 'Последние визиты', 527 + shift);
  row(p, 565 + shift, 'Далер Юсуфов', '09:38 · Личный QR', { glyph: 'user', tail: 'Отмечен', tone: 'success' });
  row(p, 629 + shift, 'Ситора Мирзоева', '09:31 · Вручную', { glyph: 'user', tail: 'Отмечен', tone: 'success', last: true });
  const entries = readOnly ? businessNav.map(([label, glyph]) => [label, glyph]) : businessNav;
  nav(p, entries, 0);
}

function businessPage() {
  const page = node(null, 'page', '03 · uGym Business', 0, 0, pageWidth, 5018, { fill: 'canvas' });
  boardHeader(page, 'uGym Business', 'Мобильное приложение для владельцев и сотрудников');
  for (const s of appSections) text(page, s.title, 32, s.y, 850, 'section', 'ink');
  auth(page, 'biz', 'uGym Business', 'biz-home');

  businessHome(phone(page, '05 · Ресепшн владельца', 'biz-home', 'main', 0));

  let p = phone(page, '06 · Все операции', 'biz-menu', 'main', 1);
  header(p, 'Все операции', 'biz-home');
  search(p, 'Найти операцию', 119);
  const actions = [
    ['Сканировать QR клиента', 'Отметка посещения', 'scan', 'biz-scan'],
    ['Показать QR зала', 'Табло для входа', 'qr', 'biz-kiosk'],
    ['Новая продажа', 'Абонементы и товары', 'wallet', 'biz-pos'],
    ['Ручной визит', 'Отметка через карточку клиента', 'clock', 'biz-clients'],
    ['Клиенты', 'Список и поиск', 'users', 'biz-clients'],
    ['Расписание', 'Занятия и группы', 'calendar', 'biz-schedule'],
  ];
  actions.forEach(([title, detail, glyph, target], i) => {
    const op = box(p, title, 20, 190 + i * 72, 350, 64, 'tile', 12, undefined, target);
    glyphTile(op, glyph, 12, 12, 40, 'surface');
    text(op, title, 64, 10, 247, 'medium');
    text(op, detail, 64, 34, 247, 'caption', 'muted');
    icon(op, 'next', 314, 22, 20);
  });
  homeIndicator(p);

  p = phone(page, '07 · Быстрые действия', 'biz-quick', 'main', 2);
  businessHome(p);
  const scrim = box(p, 'Закрыть быстрые действия', 0, 0, W, H, 'overlay', 0, undefined, 'biz-home');
  scrim.opacity = 0.48;
  const sheet = box(p, 'Панель быстрых действий', 0, 448, W, 396, 'surface', 20);
  shape(sheet, 'Ручка', 175, 10, 40, 4, 'line', 2);
  text(sheet, 'Быстрые действия', 20, 33, 350, 'title');
  row(sheet, 78, 'Сканировать QR', 'Отметить посещение', { glyph: 'scan', target: 'biz-scan' });
  row(sheet, 142, 'Новая продажа', 'Оформить через кассу', { glyph: 'wallet', target: 'biz-pos' });
  row(sheet, 206, 'Новый клиент', 'Создать карточку', { glyph: 'users', target: 'biz-new', last: true });
  button(sheet, 'Закрыть', 300, 'biz-home', 'Secondary');
  homeIndicator(sheet, W, 396);

  p = phone(page, '08 · Новый клиент', 'biz-new', 'main', 3);
  businessHome(p);
  const formScrim = box(p, 'Закрыть форму', 0, 0, W, H, 'overlay', 0, undefined, 'biz-clients');
  formScrim.opacity = 0.48;
  const form = box(p, 'Форма нового клиента', 0, 278, W, 566, 'surface', 20);
  shape(form, 'Ручка', 175, 10, 40, 4, 'line', 2);
  text(form, 'Новый клиент', 20, 36, 350, 'headline');
  text(form, 'Заполните имя и номер телефона.', 20, 74, 350, 'body', 'secondaryText');
  field(form, 'Имя', 'Например, Мадина Каримова', 123);
  field(form, 'Телефон', '+992 900 00 00 00', 219);
  field(form, 'Email · необязательно', 'name@example.com', 315, 'Default', 'mail');
  text(form, 'После подтверждения почты абонементы\nпоявятся в приложении uGym.', 20, 406, 350, 'caption', 'muted');
  button(form, 'Сохранить клиента', 473, undefined, 'Primary', 'Disabled');
  homeIndicator(form, W, 566);

  businessHome(phone(page, '09 · Ресепшн / Dark', 'biz-home-dark', 'states', 0, { dark: true }));
  businessHome(phone(page, '10 · Подписка истекла', 'biz-readonly', 'states', 1), true);

  p = phone(page, '11 · Ошибка / журнал визитов', 'biz-error', 'states', 2);
  header(p, 'Журнал визитов', 'biz-home');
  state(p, 'Журнал не загрузился', 'Проверьте подключение и попробуйте ещё раз.', 'alert', 'Повторить', 'biz-home', 'error');
  homeIndicator(p);

  p = phone(page, '12 · Недостаточно прав', 'biz-forbidden', 'states', 3);
  header(p, 'Аналитика', 'biz-schedule');
  state(p, 'Доступ ограничен', 'Аналитика доступна владельцу зала.', 'lock', 'Вернуться к расписанию', 'biz-schedule', 'warning');
  homeIndicator(p);

  text(page, 'Клиенты, касса и расписание', 32, 3026, 900, 'section', 'ink');

  p = extraPhone(page, '13 · Клиенты', 'biz-clients', 0);
  header(p, 'Клиенты', undefined, ['Новый клиент', 'plus', 'biz-new']);
  search(p, 'Имя, телефон или email', 116);
  row(p, 197, 'Далер Юсуфов', 'Абонемент · 8 визитов', { glyph: 'user', tail: 'В uGym', tone: 'success' });
  row(p, 261, 'Ситора Мирзоева', 'Абонемент · до 28 ноября', { glyph: 'user', tail: 'В uGym', tone: 'success' });
  row(p, 325, 'Фарид Саидов', 'Карточка клиента', { glyph: 'user', tail: 'Офлайн', last: true });
  nav(p, businessNav, 1);

  p = extraPhone(page, '14 · Касса', 'biz-pos', 1);
  header(p, 'Касса', undefined, ['Быстрые действия', 'bolt', 'biz-quick']);
  segment(p, [['Продажи'], ['Заявки'], ['Товары']], 0, 20, 114, 350);
  const turnover = box(p, 'Продажи сегодня', 20, 185, 350, 124, 'hero', 20);
  text(turnover, 'Продажи сегодня', 20, 19, 310, 'caption', 'secondaryText');
  text(turnover, somoni(1147682), 20, 43, 310, 'metric');
  text(turnover, '12 чеков', 20, 89, 310, 'caption', 'secondaryText');
  section(p, 'Последние продажи', 342);
  row(p, 380, 'Фитнес · 12 визитов', '09:20 · Терминал', { glyph: 'ticket', tail: somoni(55000), tailStyle: 'moneyLabel' });
  row(p, 444, 'Вода 0,5 л', '09:04 · Наличные', { glyph: 'bag', tail: somoni(500), tailStyle: 'moneyLabel', last: true });
  nav(p, businessNav, 2);

  p = extraPhone(page, '15 · Расписание и группы', 'biz-schedule', 2);
  header(p, 'Расписание');
  text(p, 'Atlas Fitness · 19 ноября', 20, 107, 350, 'body', 'secondaryText');
  segment(p, [['Занятия'], ['Тренеры']], 0, 20, 147, 350);
  section(p, 'Занятия сегодня', 228);
  row(p, 266, 'Функциональная', 'Зал 2 · Фарид Саидов', { time: '10:30', tail: '8 из 12' });
  row(p, 330, 'Растяжка', 'Студия · Мадина Саидова', { time: '12:00', tail: '4 из 12' });
  row(p, 394, 'Пилатес', 'Студия · Лейла Юсуфова', { time: '18:00', tail: '10 из 12', last: true });
  nav(p, businessNav, 3);

  p = extraPhone(page, '16 · Управление', 'biz-manage', 3);
  header(p, 'Управление');
  row(p, 124, 'Аналитика', 'Выручка и посещаемость', { glyph: 'chart' });
  row(p, 188, 'Витрина зала', 'Профиль, фотографии и публикация', { glyph: 'pin' });
  row(p, 252, 'Сотрудники', 'Штат и роли', { glyph: 'users' });
  row(p, 316, 'Настройки подписки', 'Тариф, статус и лимиты', { glyph: 'receipt', last: true });
  nav(p, businessNav, 4);

  text(page, 'Отметка визита на ресепшне', 32, 4024, 900, 'section', 'ink');
  p = lowerPhone(page, '17 · Сканер клиента', 'biz-scan', 32);
  header(p, 'Сканер QR', 'biz-home');
  const camera = box(p, 'Область камеры', 20, 130, 350, 420, 'ink', 20);
  icon(camera, 'scan', 104, 133, 142, 'white');
  text(camera, 'Наведите камеру на QR клиента', 14, 332, 322, 'body', 'white', 'center');
  button(p, 'Отметить вручную', 594, 'biz-clients', 'Secondary');
  homeIndicator(p);

  p = lowerPhone(page, '18 · Визит отмечен', 'biz-allowed', 466, true);
  header(p, 'Результат', 'biz-home-dark');
  state(p, 'Визит отмечен', 'Далер Юсуфов · 09:38\nПо абонементу осталось 8 посещений.', 'check', 'Сканировать следующего', 'biz-scan', 'success');
  homeIndicator(p);

  text(page, '19 · QR-табло / планшет', 900, 4066, 840, 'label', 'boardText');
  const tablet = box(page, '19 · QR-табло / планшет', 900, 4094, 840, 650, 'background', 24, 'line');
  Object.assign(tablet, { id: 'biz-kiosk', mode: 'Light', clip: true });
  status(tablet, 840);
  const back = box(tablet, 'Выйти из табло', 20, 52, 48, 48, 'tile', 12, undefined, 'biz-home');
  icon(back, 'arrow', 12, 12, 24);
  logo(tablet, 52, 232, 40);
  text(tablet, 'Atlas Fitness', 52, 290, 323, 'display');
  text(tablet, 'Отметьте посещение', 52, 348, 320, 'title');
  text(tablet, 'Откройте uGym и наведите\nкамеру на QR-код зала.', 52, 390, 320, 'large', 'secondaryText');
  qr(tablet, 442, 150, 324);
  progress(tablet, 469, 508, 270, 42 / 60);
  text(tablet, 'Обновление через 42 сек', 442, 536, 324, 'time', 'muted', 'center');
  homeIndicator(tablet, 840, 650);
  return page;
}

function lowerPhone(page, name, id, x, dark = false) {
  text(page, name, x, 4066, W, 'label', 'boardText');
  const p = box(page, name, x, 4094, W, H, dark ? 'background' : 'surface', 24, 'line');
  Object.assign(p, { id, mode: dark ? 'Dark' : 'Light', clip: true });
  status(p);
  return p;
}

function guideCard(page, name, subtitle, x, y, w, h) {
  const card = box(page, name, x, y, w, h, 'board', 12);
  shape(card, 'Верхняя линия', 0, 0, w, 4, 'ink', 2);
  text(card, name, 32, 30, w - 64, 'headline', 'ink');
  text(card, subtitle, 32, 69, w - 64, 'body', 'boardText');
  return card;
}

const samples = [
  ['display', 'Заголовок экрана'], ['headline', 'Вход в аккаунт'], ['title', 'Мой абонемент'],
  ['section', 'Сегодня в зале'], ['large', 'Данные посетителя'], ['medium', 'Показать мой QR'],
  ['body', 'Посмотрите расписание занятий.'], ['label', 'Номер телефона'],
  ['caption', 'Обновлено сегодня'], ['metric', somoni(1147682)], ['time', '09:38 · 00:42'],
];

function swatches(p, title, colors, y) {
  text(p, title, 32, y, 784, 'section', 'ink');
  colors.forEach(([label, token], i) => {
    const x = 32 + i * 158;
    text(p, label, x, y + 40, 145, 'label', 'ink');
    const swatch = box(p, label, x, y + 65, 142, 66, token, 8, token === 'surface' ? 'line' : undefined);
    swatch.clip = true;
    const dark = box(swatch, label + ' · Dark', 71, 0, 71, 66, token);
    dark.mode = 'Dark';
    text(p, palette[token].map((value) => '#' + value).join(' · '), x, y + 141, 142, 'time', 'boardText');
  });
}

function libraryPage() {
  const page = node(null, 'page', '01 · uCraft', 0, 0, pageWidth, 2760, { fill: 'canvas' });
  boardHeader(page, 'Styleguide', 'Дизайн-система для uGym и uGym Business', true);

  const colors = guideCard(page, 'Палитра', 'Акцент и семантические цвета · Light / Midnight — Soft', 32, 132, 848, 784);
  swatches(colors, 'Основные', [
    ['Кобальт', 'primary'], ['Нажатие', 'pressed'], ['Акцентная панель', 'hero'],
    ['Приглушённый текст', 'muted'], ['Основной текст', 'foreground'],
  ], 122);
  swatches(colors, 'Нейтральные', [
    ['Фон', 'background'], ['Поверхность', 'surface'], ['Вторичный фон', 'secondary'],
    ['Разделитель', 'line'], ['Вторичный текст', 'secondaryText'],
  ], 326);
  swatches(colors, 'Состояния', [
    ['Успех', 'successBg'], ['Внимание', 'warningBg'], ['Ошибка', 'errorBg'],
    ['Недоступно', 'disabled'],
  ], 530);
  text(colors, 'Режимы Light и Dark привязаны к переменным макетов.', 32, 730, 784, 'caption', 'boardText');

  const type = guideCard(page, 'Типографика', 'Inter для интерфейса и сумм, Geist Mono для времени и кодов', 912, 132, 856, 784);
  const family = box(type, 'Шрифты', 32, 119, 792, 68, 'boardSubtle', 12);
  text(family, 'Аа  Inter', 16, 17, 330, 'headline', 'ink');
  text(family, 'Aa  Geist Mono', 405, 17, 350, 'monoSample', 'ink');
  samples.forEach(([style, value], i) => {
    const y = 219 + i * 46;
    text(type, value, 32, y, 552, style, 'ink');
    text(type, style + ' · ' + typography[style][0] + '/' + typography[style][1], 590, y + 6, 234, 'time', 'boardText');
    if (i < samples.length - 1) shape(type, 'Разделитель', 32, y + 41, 792, 1, 'boardSubtle');
  });

  const components = guideCard(page, 'Компоненты и варианты', 'Кнопки, поля и типовые состояния формы', 32, 948, 848, 1100);
  const suite = [
    ['Основная кнопка', 'Button / Primary', 124, 'Продолжить'],
    ['Вторичная кнопка', 'Button / Secondary', 417, 'Посмотреть залы'],
    ['Поле ввода', 'Field / Text', 710, 'name@example.com'],
  ];
  suite.forEach(([heading, group, y, label]) => {
    text(components, heading, 32, y, 750, 'section', 'ink');
    const set = node(components, 'componentSet', group, 274, y + 37, 360, 242, { group });
    const translations = {
      Default: 'Обычное', Pressed: 'Нажатие', Focused: 'Фокус',
      Disabled: 'Недоступно', Loading: 'Загрузка', Filled: 'Заполнено', Error: 'Ошибка',
    };
    const height = families[group][0].height;
    set.height = (height + 8) * 5 - 8;
    families[group].forEach(({ state, width, height }, i) => {
      const rowY = (height + 8) * i;
      text(components, translations[state], 32, y + 50 + rowY, 222, 'label', 'boardText');
      const item = node(set, 'component', 'State=' + state, 0, rowY, width, height, { variant: state });
      const example = state === 'Loading' ? 'Подождите' : state === 'Error' ? 'name@example' : label;
      componentVisual(item, group, state, example);
      if (state === 'Error') text(components, 'Проверьте email.', 646, y + 50 + rowY, 170, 'caption', 'error');
    });
  });

  const icons = guideCard(page, 'Иконки', 'Контурные иконки для навигации, действий и статусов', 912, 948, 856, 594);
  const keys = ['home', 'pin', 'qr', 'scan', 'dumbbell', 'user', 'users', 'wallet',
    'calendar', 'grid', 'check', 'plus', 'search', 'sliders', 'ticket', 'clock',
    'bell', 'mail', 'eye', 'lock', 'alert', 'chart', 'bag', 'receipt'];
  keys.forEach((key, i) => {
    const tile = box(icons, key, 32 + (i % 6) * 132, 120 + Math.floor(i / 6) * 106,
      116, 90, 'boardSubtle', 12);
    icon(tile, key, 46, 16, 24, 'ink');
    text(tile, key, 4, 54, 108, 'caption', 'boardText', 'center');
  });

  const patterns = guideCard(page, 'Навигация и данные', 'Статусы, список, переключатель и таблица', 912, 1574, 856, 474);
  const list = box(patterns, 'Списки и статусы', 12, 118, 392, 319, 'surface', 12);
  text(list, 'Абонементы', 20, 0, 350, 'section');
  segment(list, [['Активные'], ['Прошедшие']], 0, 20, 38, 350);
  pill(list, 'Активен', 20, 106, 102);
  pill(list, 'Истекает', 132, 106, 108, 'warning', 'clock');
  pill(list, 'Ошибка', 250, 106, 96, 'error', 'alert');
  row(list, 152, 'Фитнес · 12 визитов', 'Atlas Fitness', { glyph: 'ticket', tail: '8 визитов' });
  row(list, 216, 'Утренний тариф', 'Navo Sport', { glyph: 'ticket', tail: 'До 28.11', last: true });

  const data = box(patterns, 'Таблица визитов', 424, 118, 400, 300, 'surface', 12);
  text(data, 'Журнал визитов', 0, 0, 390, 'section');
  shape(data, 'Шапка таблицы', 0, 38, 400, 44, 'secondary', 8);
  const table = [
    ['Время', 'Посетитель', 'Статус'],
    ['09:38', 'Далер Юсуфов', 'Отмечен'],
    ['09:31', 'Ситора Мирзоева', 'Отмечен'],
    ['09:20', 'Фарид Саидов', 'Отменён'],
  ];
  table.forEach(([time, name, state], i) => {
    const y = 51 + i * 48;
    text(data, time, 12, y, 80, i === 0 ? 'label' : 'time');
    text(data, name, 88, y, 172, i === 0 ? 'label' : 'body');
    text(data, state, 280, y, 108, i === 0 ? 'label' : 'caption',
      ['foreground', 'success', 'success', 'error'][i]);
    if (i > 0) shape(data, 'Разделитель', 0, y + 32, 400, 1, 'line');
  });

  const feedback = guideCard(page, 'Обратная связь', 'Сообщения, индикаторы и состояния загрузки', 32, 2080, 848, 540);
  const loading = box(feedback, 'Загрузка списка', 32, 122, 350, 294, 'background', 16);
  text(loading, 'Загрузка списка', 20, 16, 300, 'section');
  for (let i = 0; i < 3; i++) {
    const y = 67 + i * 68;
    shape(loading, 'Заглушка аватара', 20, y, 40, 40, 'line', 20);
    shape(loading, 'Заглушка текста', 74, y + 4, 152 - i * 8, 10, 'line', 4);
    shape(loading, 'Заглушка деталей', 74, y + 23, 104 - i * 8, 8, 'line', 4);
  }
  const notices = box(feedback, 'Состояния', 406, 122, 410, 294);
  [['Камера недоступна', 'warning', 'lock'], ['Визит отмечен', 'success', 'check'],
    ['Не удалось обновить данные', 'error', 'alert']].forEach(([label, tone, glyph], i) => {
    const note = box(notices, label, 0, i * 72, 410, 56, tone + 'Bg', 8);
    icon(note, glyph, 16, 16, 24, tone);
    text(note, label, 52, 16, 342, 'large', tone);
  });
  text(notices, '8 из 12 визитов', 0, 229, 410, 'time');
  progress(notices, 0, 258, 410, 8 / 12);

  const system = guideCard(page, 'Системные элементы', 'Строка состояния, нижняя панель и базовые контролы', 912, 2080, 856, 540);
  ['Light', 'Dark'].forEach((mode, i) => {
    const bar = box(system, 'Системные элементы · ' + mode, 32 + i * 407, 119, 382, 222, 'surface', 16, 'line');
    bar.mode = mode;
    status(bar, 382);
    shape(bar, 'Разделитель', 0, 45, 382, 1, 'line');
    text(bar, 'Уведомления', 20, 68, 213, 'label');
    const toggle = box(bar, 'Переключатель включён', 310, 60, 52, 32, 'primary', 16);
    shape(toggle, 'Бегунок', 24, 4, 24, 24, 'onPrimary', 12);
    text(bar, 'Запомнить выбор', 20, 121, 240, 'label');
    const tick = box(bar, 'Выбрано', 331, 112, 31, 31, 'primary', 8);
    icon(tick, 'check', 6, 6, 19, 'onPrimary');
    homeIndicator(bar, 382, 222);
  });
  return page;
}

function design() {
  const pages = [libraryPage(), memberPage(), businessPage()];
  function removeSelfLinks(item, screen) {
    const current = item.id || screen;
    if (item.target === current) delete item.target;
    for (const child of item.children) removeSelfLinks(child, current);
  }
  for (const page of pages) removeSelfLinks(page);
  return pages;
}

function color(key, mode) {
  if (!palette[key]) throw new Error('Unknown color: ' + key);
  return '#' + palette[key][mode === 'Dark' ? 1 : 0];
}

function rgb(key, mode) {
  const hex = color(key, mode).slice(1);
  const channel = (start) => parseInt(hex.slice(start, start + 2), 16) / 255;
  return { r: channel(0), g: channel(2), b: channel(4) };
}

function iconSvg(item, mode) {
  const view = item.view || 24;
  const ink = color(item.color, mode);
  const style = item.type === 'vector' ? 'fill="' + ink + '" fill-rule="evenodd"'
    : 'fill="none" stroke="' + ink + '" stroke-width="' + (item.weight || 1.8) +
      '" stroke-linecap="round" stroke-linejoin="round"';
  return '<svg xmlns="http://www.w3.org/2000/svg" width="' + item.width + '" height="' + item.height +
    '" viewBox="0 0 ' + view + ' ' + view + '"><path ' + style + ' d="' + item.path + '"/></svg>';
}

// Inter glyph outlines from the supplied 04, 07 and 08 SVGs. The adjacent
// logos/ directory keeps the original text-based sources byte for byte.
const logoOutlines = {
  primary: [
    ["59.999999", "188.695305", "M 47.441406 1.460938 C 39.988281 1.460938 33.480469 0.390625 27.910156 -1.746094 C 22.34375 -3.886719 18.039062 -7.003906 14.992188 -11.101562 C 11.949219 -15.195312 10.425781 -20.167969 10.425781 -26.011719 L 10.425781 -69.609375 L 39.800781 -69.609375 L 39.800781 -29.578125 C 39.800781 -24.933594 41.503906 -21.394531 44.910156 -18.957031 C 48.3125 -16.519531 53.082031 -15.300781 59.210938 -15.300781 C 63.257812 -15.300781 66.839844 -15.851562 69.953125 -16.953125 C 73.070312 -18.054688 75.507812 -19.761719 77.265625 -22.078125 C 79.023438 -24.394531 79.90625 -27.347656 79.90625 -30.9375 L 79.90625 -69.609375 L 109.285156 -69.609375 L 109.285156 0 L 80.359375 0 L 80.359375 -18.121094 L 85.367188 -18.121094 C 82.015625 -11.976562 77.257812 -7.175781 71.101562 -3.722656 C 64.945312 -0.265625 57.058594 1.460938 47.441406 1.460938 Z M 47.441406 1.460938"],
    ["177.450439", "188.695305", "M 76.976562 1.582031 C 63.371094 1.582031 51.238281 -0.46875 40.578125 -4.570312 C 29.917969 -8.675781 21.539062 -14.515625 15.441406 -22.09375 C 9.339844 -29.671875 6.289062 -38.652344 6.289062 -49.042969 C 6.289062 -59.519531 9.332031 -68.554688 15.417969 -76.140625 C 21.5 -83.730469 29.878906 -89.570312 40.554688 -93.664062 C 51.230469 -97.753906 63.371094 -99.800781 76.976562 -99.800781 C 85.699219 -99.800781 93.785156 -98.949219 101.238281 -97.242188 C 108.691406 -95.539062 115.292969 -93.101562 121.039062 -89.929688 C 126.789062 -86.757812 131.507812 -82.949219 135.191406 -78.507812 C 138.875 -74.066406 141.308594 -69.09375 142.492188 -63.597656 L 111.445312 -63.597656 C 110.570312 -66.492188 109.132812 -69.074219 107.128906 -71.34375 C 105.125 -73.617188 102.65625 -75.535156 99.71875 -77.101562 C 96.78125 -78.667969 93.433594 -79.859375 89.675781 -80.671875 C 85.917969 -81.484375 81.828125 -81.890625 77.40625 -81.890625 C 68.96875 -81.890625 61.757812 -80.546875 55.765625 -77.863281 C 49.777344 -75.175781 45.1875 -71.378906 41.992188 -66.46875 C 38.800781 -61.558594 37.207031 -55.75 37.207031 -49.042969 C 37.207031 -42.378906 38.792969 -36.605469 41.96875 -31.714844 C 45.140625 -26.828125 49.734375 -23.039062 55.738281 -20.355469 C 61.746094 -17.667969 68.96875 -16.328125 77.40625 -16.328125 C 81.828125 -16.328125 85.902344 -16.726562 89.625 -17.527344 C 93.351562 -18.328125 96.683594 -19.511719 99.621094 -21.082031 C 102.558594 -22.652344 105.035156 -24.5625 107.050781 -26.808594 C 109.070312 -29.058594 110.550781 -31.617188 111.492188 -34.488281 L 142.492188 -34.488281 C 141.304688 -29.011719 138.871094 -24.058594 135.1875 -19.625 C 131.503906 -15.195312 126.78125 -11.398438 121.011719 -8.238281 C 115.246094 -5.074219 108.644531 -2.648438 101.210938 -0.957031 C 93.777344 0.734375 85.699219 1.582031 76.976562 1.582031 Z M 76.976562 1.582031"],
    ["323.658276", "188.695305", "M 10.425781 0 L 10.425781 -69.609375 L 38.789062 -69.609375 L 38.789062 -57.742188 L 39.078125 -57.742188 C 41.011719 -61.9375 44.035156 -65.046875 48.15625 -67.066406 C 52.277344 -69.085938 57.816406 -70.09375 64.765625 -70.09375 C 66.511719 -70.09375 68.105469 -70.074219 69.546875 -70.035156 C 70.988281 -69.992188 72.296875 -69.953125 73.464844 -69.914062 L 73.464844 -53.367188 C 72.402344 -53.425781 70.652344 -53.503906 68.21875 -53.59375 C 65.78125 -53.683594 63.3125 -53.730469 60.816406 -53.730469 C 56.808594 -53.730469 53.214844 -53.125 50.03125 -51.914062 C 46.84375 -50.703125 44.34375 -48.914062 42.527344 -46.539062 C 40.710938 -44.164062 39.800781 -41.222656 39.800781 -37.71875 L 39.800781 0 Z M 10.425781 0"],
    ["396.203161", "188.695305", "M 42.683594 1.160156 C 35.660156 1.160156 29.417969 0.394531 23.964844 -1.140625 C 18.511719 -2.675781 14.214844 -4.984375 11.078125 -8.066406 C 7.9375 -11.148438 6.371094 -14.996094 6.371094 -19.613281 C 6.371094 -23.5625 7.46875 -26.84375 9.671875 -29.457031 C 11.875 -32.066406 14.882812 -34.171875 18.699219 -35.765625 C 22.519531 -37.359375 26.914062 -38.574219 31.882812 -39.402344 C 36.855469 -40.234375 42.078125 -40.820312 47.554688 -41.164062 C 53.988281 -41.589844 59.109375 -41.996094 62.917969 -42.386719 C 66.722656 -42.777344 69.453125 -43.351562 71.101562 -44.101562 C 72.75 -44.851562 73.574219 -45.972656 73.574219 -47.472656 L 73.574219 -47.917969 C 73.574219 -49.636719 72.882812 -51.144531 71.503906 -52.449219 C 70.121094 -53.75 68.152344 -54.773438 65.589844 -55.515625 C 63.03125 -56.253906 59.953125 -56.625 56.355469 -56.625 C 52.71875 -56.625 49.523438 -56.246094 46.769531 -55.492188 C 44.015625 -54.734375 41.835938 -53.675781 40.234375 -52.316406 C 38.636719 -50.960938 37.703125 -49.375 37.433594 -47.570312 L 9.753906 -47.570312 C 10.230469 -52.378906 12.390625 -56.535156 16.230469 -60.042969 C 20.070312 -63.550781 25.449219 -66.265625 32.367188 -68.1875 C 39.285156 -70.109375 47.570312 -71.070312 57.21875 -71.070312 C 64.421875 -71.070312 70.84375 -70.527344 76.488281 -69.4375 C 82.128906 -68.351562 86.894531 -66.777344 90.785156 -64.707031 C 94.675781 -62.636719 97.625 -60.132812 99.632812 -57.1875 C 101.640625 -54.246094 102.644531 -50.917969 102.644531 -47.207031 L 102.644531 0 L 73.898438 0 L 73.898438 -9.816406 L 73.5 -9.816406 C 71.660156 -7.554688 69.363281 -5.597656 66.613281 -3.953125 C 63.863281 -2.3125 60.53125 -1.046875 56.625 -0.164062 C 52.714844 0.71875 48.070312 1.160156 42.683594 1.160156 Z M 50.796875 -12.3125 C 55.527344 -12.3125 59.617188 -12.886719 63.0625 -14.035156 C 66.507812 -15.183594 69.15625 -16.746094 71.011719 -18.71875 C 72.863281 -20.691406 73.789062 -22.929688 73.789062 -25.441406 L 73.789062 -32.433594 C 72.945312 -32.132812 71.820312 -31.84375 70.414062 -31.5625 C 69.011719 -31.28125 67.378906 -31.011719 65.515625 -30.753906 C 63.652344 -30.496094 61.628906 -30.242188 59.4375 -29.992188 C 57.25 -29.746094 54.960938 -29.503906 52.578125 -29.261719 C 49.238281 -28.933594 46.199219 -28.40625 43.472656 -27.679688 C 40.742188 -26.953125 38.570312 -25.984375 36.953125 -24.769531 C 35.335938 -23.550781 34.53125 -22.015625 34.53125 -20.164062 C 34.53125 -18.53125 35.207031 -17.125 36.554688 -15.945312 C 37.90625 -14.765625 39.800781 -13.863281 42.234375 -13.242188 C 44.667969 -12.621094 47.523438 -12.3125 50.796875 -12.3125 Z M 50.796875 -12.3125"],
    ["506.963514", "188.695305", "M 71.824219 -69.609375 L 71.824219 -54.359375 L 1.769531 -54.359375 L 1.769531 -69.609375 Z M 20.863281 0 L 20.863281 -78.65625 C 20.863281 -82.992188 22.136719 -86.605469 24.6875 -89.5 C 27.238281 -92.390625 31.054688 -94.566406 36.128906 -96.027344 C 41.207031 -97.488281 47.53125 -98.21875 55.09375 -98.21875 C 58.609375 -98.21875 61.964844 -98.21875 65.160156 -98.21875 C 68.359375 -98.21875 70.578125 -98.21875 71.824219 -98.21875 L 71.824219 -82.96875 C 70.972656 -82.96875 69.464844 -82.96875 67.296875 -82.96875 C 65.125 -82.96875 63.28125 -82.96875 61.761719 -82.96875 C 57.585938 -82.96875 54.625 -82.390625 52.871094 -81.234375 C 51.117188 -80.078125 50.242188 -78.125 50.242188 -75.375 L 50.242188 0 Z M 20.863281 0"],
    ["571.871867", "188.695305", "M 70.960938 -69.609375 L 70.960938 -54.359375 L 1.769531 -54.359375 L 1.769531 -69.609375 Z M 20 -88.59375 L 49.378906 -88.59375 L 49.378906 -21.503906 C 49.378906 -19.15625 50.101562 -17.523438 51.546875 -16.613281 C 52.992188 -15.703125 55.699219 -15.25 59.667969 -15.25 C 61.339844 -15.25 63.328125 -15.25 65.632812 -15.25 C 67.9375 -15.25 69.710938 -15.25 70.960938 -15.25 L 70.960938 0 C 69.195312 0 66.714844 0 63.515625 0 C 60.320312 0 57.101562 0 53.863281 0 C 42.222656 0 33.667969 -1.496094 28.199219 -4.492188 C 22.734375 -7.484375 20 -12.144531 20 -18.464844 Z M 20 -88.59375"],
  ],
  avatar: [
    ["119.999996", "279.105461", "M 84.585938 1.703125 C 71.300781 1.703125 59.691406 0.457031 49.765625 -2.039062 C 39.835938 -4.53125 32.160156 -8.167969 26.730469 -12.949219 C 21.300781 -17.730469 18.585938 -23.527344 18.585938 -30.347656 L 18.585938 -81.210938 L 70.964844 -81.210938 L 70.964844 -34.507812 C 70.964844 -29.089844 74 -24.960938 80.070312 -22.117188 C 86.140625 -19.273438 94.640625 -17.851562 105.570312 -17.851562 C 112.785156 -17.851562 119.167969 -18.492188 124.722656 -19.777344 C 130.277344 -21.0625 134.621094 -23.058594 137.757812 -25.757812 C 140.894531 -28.460938 142.464844 -31.90625 142.464844 -36.09375 L 142.464844 -81.210938 L 194.84375 -81.210938 L 194.84375 0 L 143.273438 0 L 143.273438 -21.140625 L 152.203125 -21.140625 C 146.226562 -13.972656 137.746094 -8.371094 126.769531 -4.339844 C 115.789062 -0.3125 101.730469 1.703125 84.585938 1.703125 Z M 84.585938 1.703125"],
  ],
};

function logoSvg(item, mode) {
  const primary = item.lockup === 'primary';
  const dark = !primary && mode === 'Dark';
  const width = primary ? 1200 : 600;
  const height = primary ? 360 : 600;
  const letterColor = dark ? '#F9FAFB' : '#111827';
  const background = dark ? '#111827' : '#F9FAFB';
  const [cx, cy, radius] = primary ? [835, 225, 19] : [405, 381, 21];
  const glyphs = logoOutlines[item.lockup].map(([x, y, path]) =>
    '<path transform="translate(' + x + ' ' + y + ')" d="' + path + '"/>').join('');
  return '<svg xmlns="http://www.w3.org/2000/svg" role="img" aria-label="uCraft" width="' +
    item.width + '" height="' + item.height + '" viewBox="0 0 ' + width + ' ' + height + '">' +
    '<rect width="' + width + '" height="' + height + '" fill="' + background + '"/>' +
    '<g transform="scale(1.3333333333333333)" fill="' + letterColor + '">' + glyphs + '</g>' +
    '<circle cx="' + cx + '" cy="' + cy + '" r="' + radius + '" fill="#507DE8"/></svg>';
}

function keepScreenColors(key) {
  return ['white', 'ink', 'canvas', 'board', 'boardSubtle', 'boardText'].includes(key);
}

async function loadFigmaFonts(api) {
  const available = (await api.listAvailableFontsAsync()).map((font) => font.fontName);
  const normalize = (s) => s.toLowerCase().replace(/[ -]/g, '');
  const fonts = {};
  for (const [key, [, , weight, family = 'Inter']] of Object.entries(typography)) {
    const candidates = family === 'Inter' ? ['Inter', 'Roboto', 'Arial'] : ['Geist Mono', 'Roboto Mono', 'Inter'];
    let match;
    for (const name of candidates) {
      const variants = available.filter((f) => f.family === name);
      match = variants.find((f) => normalize(f.style) === normalize(weight))
        || variants.find((f) => f.style === 'Regular');
      if (match) break;
    }
    if (!match) throw new Error('Не найден шрифт ' + family);
    await api.loadFontAsync(match);
    fonts[key] = match;
  }
  return fonts;
}

async function importFigma(api) {
  if (api.root.children.some((page) => page.getPluginData('ucraft-boards') === '1')) {
    api.closePlugin('Макеты уже есть в этом файле. Для нового импорта откройте отдельный файл.');
    return;
  }

  const specs = design();
  const fonts = await loadFigmaFonts(api);
  const original = api.currentPage;
  await original.loadAsync();
  const reuseOriginal = api.root.children.length === 1 && original.children.length === 0;
  const originalName = original.name;
  const originalBackgrounds = original.backgrounds;
  const createdPages = [];
  const textStyles = {};
  let collection;
  let darkMode;
  const variables = {};
  const components = new Map();
  const targets = new Map();
  const links = [];

  function paint(key, mode) {
    const solid = { type: 'SOLID', color: rgb(key, mode) };
    return variables[key] && (mode === 'Light' || darkMode)
      ? api.variables.setBoundVariableForPaint(solid, 'color', variables[key]) : solid;
  }

  function applySurface(layer, item, mode) {
    layer.fills = item.fill ? [paint(item.fill, mode)] : [];
    if (item.radius) layer.cornerRadius = item.radius;
    if (item.stroke) {
      layer.strokes = [paint(item.stroke, mode)];
      layer.strokeWeight = item.strokeWeight || 1;
      layer.strokeAlign = 'INSIDE';
    }
  }

  async function create(item, parent, inheritedMode = 'Light') {
    const mode = item.mode || inheritedMode;
    let layer;
    if (item.type === 'componentSet') {
      const variants = [];
      for (const variant of item.children) {
        const componentNode = await create(variant, parent, mode);
        componentNode.x = item.x + variant.x;
        componentNode.y = item.y + variant.y;
        components.set(item.group + '|' + variant.variant, componentNode);
        variants.push(componentNode);
      }
      layer = api.combineAsVariants(variants, parent);
      layer.name = item.name;
      layer.x = item.x;
      layer.y = item.y;
      layer.fills = [];
      layer.strokes = [];
      return layer;
    }
    if (item.type === 'text') {
      layer = api.createText();
      layer.fontName = fonts[item.style];
      await layer.setTextStyleIdAsync(textStyles[item.style].id);
      layer.characters = item.value;
      layer.textAlignHorizontal = item.align.toUpperCase();
      layer.textAutoResize = 'NONE';
      layer.resize(item.width, item.height);
      layer.fills = [paint(item.color, mode)];
    } else if (item.type === 'logo') {
      layer = api.createNodeFromSvg(logoSvg(item, mode));
    } else if (item.type === 'icon' || item.type === 'vector') {
      layer = api.createNodeFromSvg(iconSvg(item, mode));
      layer.resize(item.width, item.height);
      for (const vector of layer.findAll((child) => child.type === 'VECTOR')) {
        if (vector.strokes.length) vector.strokes = [paint(item.color, mode)];
        if (vector.fills.length) vector.fills = [paint(item.color, mode)];
      }
    } else if (item.type === 'instance' && (mode === 'Light' || darkMode)) {
      layer = components.get(item.group + '|' + item.variant).createInstance();
      const label = layer.findOne((child) => child.type === 'TEXT' && child.name === 'Label');
      label.characters = item.label;
    } else {
      layer = item.type === 'component' ? api.createComponent()
        : item.type === 'rect' ? api.createRectangle() : api.createFrame();
      layer.resize(item.width, item.height);
      if (item.type === 'instance') componentVisual(item, item.group, item.variant, item.label);
      applySurface(layer, item, mode);
      if (layer.type === 'FRAME' || layer.type === 'COMPONENT') layer.clipsContent = Boolean(item.clip);
      for (const child of item.children) await create(child, layer, mode);
    }
    parent.appendChild(layer);
    layer.name = item.name;
    layer.x = item.x;
    layer.y = item.y;
    if (item.opacity !== undefined) layer.opacity = item.opacity;
    if (item.mode && collection && darkMode) {
      layer.setExplicitVariableModeForCollection(collection,
        item.mode === 'Dark' ? darkMode : collection.defaultModeId);
    }
    if (item.id) targets.set(item.id, layer);
    if (item.target) links.push([layer, item.target]);
    return layer;
  }

  try {
    collection = api.variables.createVariableCollection('uCraft · Концепт');
    collection.renameMode(collection.defaultModeId, 'Light');
    try {
      darkMode = collection.addMode('Dark');
    } catch {
      // A workspace may only permit one variable mode. Dark frames keep their own colors.
    }
    for (const key of Object.keys(palette).filter((name) => !keepScreenColors(name))) {
      const variable = api.variables.createVariable('Color/' + key, collection, 'COLOR');
      variable.setValueForMode(collection.defaultModeId, rgb(key, 'Light'));
      if (darkMode) variable.setValueForMode(darkMode, rgb(key, 'Dark'));
      variables[key] = variable;
    }

    for (const [key, [size, height]] of Object.entries(typography)) {
      const style = api.createTextStyle();
      textStyles[key] = style;
      style.name = 'uCraft/' + key;
      style.fontName = fonts[key];
      style.fontSize = size;
      style.lineHeight = { value: height, unit: 'PIXELS' };
      style.letterSpacing = { value: 0, unit: 'PIXELS' };
      if (moneyStyles.has(key)) style.description = 'Inter · табличные цифры (tnum)';
    }

    for (const [index, spec] of specs.entries()) {
      const page = index === 0 && reuseOriginal ? original : api.createPage();
      if (page !== original) createdPages.push(page);
      await api.setCurrentPageAsync(page);
      page.name = spec.name;
      page.backgrounds = [paint(spec.fill, 'Light')];
      for (const child of spec.children) await create(child, page);
      page.setPluginData('ucraft-boards', '1');
    }

    for (const [layer, key] of links) {
      const destination = targets.get(key);
      await layer.setReactionsAsync([{
        trigger: { type: 'ON_CLICK' },
        actions: [{ type: 'NODE', destinationId: destination.id, navigation: 'NAVIGATE', transition: null, preserveScrollPosition: false }],
      }]);
    }
  } catch (error) {
    await api.setCurrentPageAsync(original);
    for (const page of createdPages) page.remove();
    if (reuseOriginal) {
      for (const layer of [...original.children]) layer.remove();
      original.name = originalName;
      original.backgrounds = originalBackgrounds;
      original.setPluginData('ucraft-boards', '');
    }
    for (const style of Object.values(textStyles)) style.remove();
    if (collection) collection.remove();
    throw error;
  }

  const cover = reuseOriginal ? original : createdPages[0];
  await api.setCurrentPageAsync(cover);
  api.viewport.scrollAndZoomIntoView(cover.children.slice(0, 3));
  const fallbacks = [];
  if (!darkMode) fallbacks.push('Тёмная тема добавлена отдельными цветами.');
  if (fonts.time.family !== 'Geist Mono') fallbacks.push('Коды используют ' + fonts.time.family + '.');
  if (fonts.body.family !== 'Inter') fallbacks.push('Текст использует ' + fonts.body.family + '.');
  api.closePlugin(['Готово. Созданы страницы uCraft, uGym и uGym Business.', ...fallbacks].join(' '));
}

if (typeof figma !== 'undefined') {
  importFigma(figma).catch((error) => {
    console.error(error);
    figma.closePlugin('Импорт не завершён. ' + error.message);
  });
}
if (typeof module !== 'undefined') {
  module.exports = { design, color, iconSvg, logoSvg, componentVisual, typography, moneyStyles, importFigma };
}
