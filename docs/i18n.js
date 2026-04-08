/* ============================================================
   oh-my-clawd — i18n Translation System
   Supports Korean (ko) and English (en)
   ============================================================ */

const translations = {
  en: {
    // Navbar
    'nav.home': 'Home',
    'nav.docs': 'Docs',
    'nav.features': 'Features',
    'nav.collection': 'Collection',

    // Hero
    'hero.title': 'oh-my-clawd',
    'hero.tagline': 'clawd has infiltrated my computer',
    'hero.subtitle': 'A lightweight status line + menu bar Clawd for Claude Code',
    'hero.description': 'Rate Limit, Session Time, Context Usage, Tool Calls, Agents, Model Info \u2014 all at a glance. Plus a Tamagotchi-style pixel art Clawd that reacts to your coding activity.',
    'hero.cta.download': 'Download DMG',
    'hero.cta.docs': 'Read Docs',
    'hero.stat.accessories': '9+ Accessories',
    'hero.stat.states': '8 States',
    'hero.stat.effects': '3 Effects',
    'hero.stat.hud': 'HUD',

    // Features section
    'features.title': 'Features',
    'features.hud.title': 'HUD Status Line',
    'features.hud.desc': 'Real-time rate limits, session duration, context usage, tool calls, and active model info displayed in your terminal.',
    'features.pet.title': 'Clawd System',
    'features.pet.desc': 'One Clawd character with 8 states, 3 activity levels, and 9 collectible accessories. Each accessory has unique unlock conditions based on your Claude Code usage.',
    'features.update.title': 'Auto Updates',
    'features.update.desc': 'Check for updates directly from the app. Download the latest DMG from GitHub Releases with one click.',

    // Collection
    'collection.title': 'Accessory Collection',

    // Install
    'install.title': 'Get Started',
    'install.step1.title': 'Download',
    'install.step1.desc': 'Get the latest DMG from GitHub Releases',
    'install.step2.title': 'Install',
    'install.step2.desc': 'Drag OhMyClawd.app to Applications',
    'install.step3.title': 'Launch',
    'install.step3.desc': 'Open the app and check your menu bar',

    // Footer
    'footer.license': 'MIT License',
    'footer.github': 'GitHub',
    'footer.disclaimer': 'The Clawd character design is copyrighted by Anthropic. This is a non-commercial fan project. We will remove it immediately if any copyright issues arise.',

    // Docs page — sidebar
    'docs.sidebar.getting-started': 'Getting Started',
    'docs.sidebar.installation': 'Installation',
    'docs.sidebar.quick-start': 'Quick Start',
    'docs.sidebar.features': 'Features',
    'docs.sidebar.pet-system': 'Clawd System',
    'docs.sidebar.activity-levels': 'Activity Levels',
    'docs.sidebar.hud': 'HUD Status Line',
    'docs.sidebar.collection': 'Accessory Collection',
    'docs.sidebar.config': 'Configuration',
    'docs.sidebar.update': 'Update',

    // Docs content sections
    'docs.install.title': 'Installation',
    'docs.install.dmg': 'Download DMG (Recommended)',
    'docs.install.dmg.desc': 'Download the latest DMG from GitHub Releases, open it, and drag OhMyClawd.app to your Applications folder.',
    'docs.install.manual': 'Manual Install',
    'docs.quickstart.title': 'Quick Start',
    'docs.pet.title': 'Clawd System',
    'docs.pet.desc': 'Clawd lives in the macOS menu bar and reacts to Claude Code activity across all sessions.',
    'docs.pet.states.title': 'Clawd States',
    'docs.effect.title': 'Activity Levels',
    'docs.effect.desc': 'Clawd\'s activity level changes based on concurrent agent count.',
    'docs.hud.title': 'HUD Status Line',
    'docs.hud.desc': 'A real-time status line showing Claude Code metrics.',
    'docs.collection.title': 'Accessory Collection',
    'docs.collection.desc': '9 collectible accessories, each with unique unlock conditions.',
    'docs.config.title': 'Configuration',
    'docs.update.title': 'Update',
    'docs.update.desc': 'Check for updates directly from the app popover, or download the latest DMG from GitHub Releases.',

    // Accessory names — hats
    'accessory.cap': 'Cap',
    'accessory.partyHat': 'Party Hat',
    'accessory.santaHat': 'Santa Hat',
    'accessory.silkHat': 'Silk Hat',
    'accessory.cowboyHat': 'Cowboy Hat',

    // Accessory names — glasses
    'accessory.hornRimmed': 'Horn-rimmed',
    'accessory.sunglasses': 'Sunglasses',
    'accessory.roundGlasses': 'Round Glasses',
    'accessory.starGlasses': 'Star Glasses',

    // Unlock conditions
    'unlock.cap': '10 sessions',
    'unlock.partyHat': '5 hours total usage',
    'unlock.santaHat': '500K tokens used',
    'unlock.silkHat': '50 agent runs',
    'unlock.cowboyHat': '30 hours total usage',
    'unlock.hornRimmed': '3+ concurrent sessions',
    'unlock.sunglasses': '10 rate limit hits',
    'unlock.roundGlasses': '20 long sessions (45m+)',
    'unlock.starGlasses': '10 hours on Opus',

    // States
    'state.idle': 'Sleeping...',
    'state.wakeUp': 'Waking up!',
    'state.normal': 'Walking happily',
    'state.busy': 'Working hard!',
    'state.bloated': 'Context is full...',
    'state.stressed': 'Rate limit warning!',
    'state.tired': 'Getting tired...',
    'state.collab': 'Working together!',
    'state.idle.trigger': 'No active sessions',
    'state.wakeUp.trigger': 'Transition from idle',
    'state.normal.trigger': 'Default active state',
    'state.busy.trigger': '50+ tool calls',
    'state.bloated.trigger': 'Context >= 70%',
    'state.stressed.trigger': 'Rate limit >= 80%',
    'state.tired.trigger': 'Session >= 45 min',
    'state.collab.trigger': '2+ agents',

    // Activity levels (replaces muscles)
    'effect.normal': 'Normal',
    'effect.glowing': 'Glowing',
    'effect.supercharged': 'Supercharged!',
    'effect.normal.cond': '0-1 agents',
    'effect.glowing.cond': '2-3 agents',
    'effect.supercharged.cond': '4+ agents',
  },

  ko: {
    // Navbar
    'nav.home': '\uD648',
    'nav.docs': '\uBB38\uC11C',
    'nav.features': '\uAE30\uB2A5',
    'nav.collection': '\uCEEC\uB809\uC158',

    // Hero
    'hero.title': 'oh-my-clawd',
    'hero.tagline': '\uB0B4 \uCEF4\uD4E8\uD130\uC5D0 \uCE68\uD22C\uD55C clawd',
    'hero.subtitle': 'Claude Code\uB97C \uC704\uD55C \uC0C1\uD0DC \uD45C\uC2DC\uC904 + \uBA54\uB274\uBC14 Clawd',
    'hero.description': 'Rate Limit, \uC138\uC158 \uC2DC\uAC04, \uCEE8\uD14D\uC2A4\uD2B8 \uC0AC\uC6A9\uB7C9, \uB3C4\uAD6C \uD638\uCD9C, \uC5D0\uC774\uC804\uD2B8, \uBAA8\uB378 \uC815\uBCF4\uB97C \uD55C\uB208\uC5D0. \uCF54\uB529 \uD65C\uB3D9\uC5D0 \uBC18\uC751\uD558\uB294 \uD0C0\uB9C8\uACE0\uCE58 \uC2A4\uD0C0\uC77C \uD53D\uC140\uC544\uD2B8 Clawd\uB3C4 \uD568\uAED8.',
    'hero.cta.download': 'DMG \uB2E4\uC6B4\uB85C\uB4DC',
    'hero.cta.docs': '\uBB38\uC11C \uBCF4\uAE30',
    'hero.stat.accessories': '9\uC885+ \uC561\uC138\uC11C\uB9AC',
    'hero.stat.states': '8\uAC00\uC9C0 \uC0C1\uD0DC',
    'hero.stat.effects': '3\uB2E8\uACC4 \uD6A8\uACFC',
    'hero.stat.hud': 'HUD',

    // Features section
    'features.title': '\uAE30\uB2A5',
    'features.hud.title': 'HUD \uC0C1\uD0DC \uD45C\uC2DC\uC904',
    'features.hud.desc': 'Rate Limit, \uC138\uC158 \uC9C0\uC18D\uC2DC\uAC04, \uCEE8\uD14D\uC2A4\uD2B8 \uC0AC\uC6A9\uB7C9, \uB3C4\uAD6C \uD638\uCD9C, \uD65C\uC131 \uBAA8\uB378 \uC815\uBCF4\uB97C \uD130\uBBF8\uB110\uC5D0 \uC2E4\uC2DC\uAC04 \uD45C\uC2DC\uD569\uB2C8\uB2E4.',
    'features.pet.title': 'Clawd \uC2DC\uC2A4\uD15C',
    'features.pet.desc': '8\uAC00\uC9C0 \uC0C1\uD0DC\uC640 3\uB2E8\uACC4 \uD65C\uB3D9 \uB808\uBCA8\uC744 \uAC00\uC9C4 Clawd \uCE90\uB9AD\uD130\uC5D0 9\uC885\uC758 \uC561\uC138\uC11C\uB9AC\uB97C \uC218\uC9D1\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4. \uAC01 \uC561\uC138\uC11C\uB9AC\uB294 Claude Code \uC0AC\uC6A9\uB7C9\uC5D0 \uB530\uB978 \uACE0\uC720\uD55C \uC5B8\uB77D \uC870\uAC74\uC774 \uC788\uC2B5\uB2C8\uB2E4.',
    'features.update.title': '\uC790\uB3D9 \uC5C5\uB370\uC774\uD2B8',
    'features.update.desc': '\uC571\uC5D0\uC11C \uC9C1\uC811 \uC5C5\uB370\uC774\uD2B8\uB97C \uD655\uC778\uD558\uC138\uC694. \uD074\uB9AD \uD55C \uBC88\uC73C\uB85C GitHub Releases\uC5D0\uC11C \uCD5C\uC2E0 DMG\uB97C \uB2E4\uC6B4\uB85C\uB4DC\uD569\uB2C8\uB2E4.',

    // Collection
    'collection.title': '\uC561\uC138\uC11C\uB9AC \uCEEC\uB809\uC158',

    // Install
    'install.title': '\uC2DC\uC791\uD558\uAE30',
    'install.step1.title': '\uB2E4\uC6B4\uB85C\uB4DC',
    'install.step1.desc': 'GitHub Releases\uC5D0\uC11C \uCD5C\uC2E0 DMG \uB2E4\uC6B4\uB85C\uB4DC',
    'install.step2.title': '\uC124\uCE58',
    'install.step2.desc': 'OhMyClawd.app\uC744 Applications\uB85C \uB4DC\uB798\uADF8',
    'install.step3.title': '\uC2E4\uD589',
    'install.step3.desc': '\uC571\uC744 \uC5F4\uACE0 \uBA54\uB274\uBC14\uB97C \uD655\uC778\uD558\uC138\uC694',

    // Footer
    'footer.license': 'MIT \uB77C\uC774\uC120\uC2A4',
    'footer.github': 'GitHub',
    'footer.disclaimer': 'Clawd \uCE90\uB9AD\uD130 \uB514\uC790\uC778\uC758 \uC800\uC791\uAD8C\uC740 Anthropic\uC5D0 \uC788\uC2B5\uB2C8\uB2E4. \uBE44\uC0C1\uC5C5\uC801 \uD32C \uD504\uB85C\uC81D\uD2B8\uC785\uB2C8\uB2E4. \uC800\uC791\uAD8C \uBB38\uC81C \uBC1C\uC0DD \uC2DC \uC989\uC2DC \uC0AD\uC81C\uD558\uACA0\uC2B5\uB2C8\uB2E4.',

    // Docs page — sidebar
    'docs.sidebar.getting-started': '\uC2DC\uC791\uD558\uAE30',
    'docs.sidebar.installation': '\uC124\uCE58',
    'docs.sidebar.quick-start': '\uBE60\uB978 \uC2DC\uC791',
    'docs.sidebar.features': '\uAE30\uB2A5',
    'docs.sidebar.pet-system': 'Clawd \uC2DC\uC2A4\uD15C',
    'docs.sidebar.activity-levels': '\uD65C\uB3D9 \uB808\uBCA8',
    'docs.sidebar.hud': 'HUD \uC0C1\uD0DC \uD45C\uC2DC\uC904',
    'docs.sidebar.collection': '\uC561\uC138\uC11C\uB9AC \uCEEC\uB809\uC158',
    'docs.sidebar.config': '\uC124\uC815',
    'docs.sidebar.update': '\uC5C5\uB370\uC774\uD2B8',

    // Docs content sections
    'docs.install.title': '\uC124\uCE58',
    'docs.install.dmg': 'DMG \uB2E4\uC6B4\uB85C\uB4DC (\uAD8C\uC7A5)',
    'docs.install.dmg.desc': 'GitHub Releases\uC5D0\uC11C \uCD5C\uC2E0 DMG\uB97C \uB2E4\uC6B4\uB85C\uB4DC\uD558\uACE0, \uC5F4\uC5B4\uC11C OhMyClawd.app\uC744 Applications \uD3F4\uB354\uB85C \uB4DC\uB798\uADF8\uD558\uC138\uC694.',
    'docs.install.manual': '\uC218\uB3D9 \uC124\uCE58',
    'docs.quickstart.title': '\uBE60\uB978 \uC2DC\uC791',
    'docs.pet.title': 'Clawd \uC2DC\uC2A4\uD15C',
    'docs.pet.desc': 'Clawd\uB294 macOS \uBA54\uB274\uBC14\uC5D0 \uC0B4\uBA70 \uBAA8\uB4E0 \uC138\uC158\uC758 Claude Code \uD65C\uB3D9\uC5D0 \uBC18\uC751\uD569\uB2C8\uB2E4.',
    'docs.pet.states.title': 'Clawd \uC0C1\uD0DC',
    'docs.effect.title': '\uD65C\uB3D9 \uB808\uBCA8',
    'docs.effect.desc': '\uB3D9\uC2DC \uC5D0\uC774\uC804\uD2B8 \uC218\uC5D0 \uB530\uB77C Clawd\uC758 \uD65C\uB3D9 \uB808\uBCA8\uC774 \uBCC0\uD569\uB2C8\uB2E4.',
    'docs.hud.title': 'HUD \uC0C1\uD0DC \uD45C\uC2DC\uC904',
    'docs.hud.desc': 'Claude Code \uBA54\uD2B8\uB9AD\uC744 \uC2E4\uC2DC\uAC04\uC73C\uB85C \uBCF4\uC5EC\uC8FC\uB294 \uC0C1\uD0DC \uD45C\uC2DC\uC904\uC785\uB2C8\uB2E4.',
    'docs.collection.title': '\uC561\uC138\uC11C\uB9AC \uCEEC\uB809\uC158',
    'docs.collection.desc': '\uAC01\uAC01 \uACE0\uC720\uD55C \uC5B8\uB77D \uC870\uAC74\uC744 \uAC00\uC9C4 9\uC885\uC758 \uC561\uC138\uC11C\uB9AC.',
    'docs.config.title': '\uC124\uC815',
    'docs.update.title': '\uC5C5\uB370\uC774\uD2B8',
    'docs.update.desc': '\uC571 \uD31D\uC624\uBC84\uC5D0\uC11C \uC9C1\uC811 \uC5C5\uB370\uC774\uD2B8\uB97C \uD655\uC778\uD558\uAC70\uB098, GitHub Releases\uC5D0\uC11C \uCD5C\uC2E0 DMG\uB97C \uB2E4\uC6B4\uB85C\uB4DC\uD558\uC138\uC694.',

    // Accessory names — hats
    'accessory.cap': '\uCE98\uBAA8\uC790',
    'accessory.partyHat': '\uAF34\uAE54\uBAA8\uC790',
    'accessory.santaHat': '\uC0B0\uD0C0\uBAA8\uC790',
    'accessory.silkHat': '\uC2E4\uD06C\uD587',
    'accessory.cowboyHat': '\uCE74\uC6B0\uBCF4\uC774\uBAA8\uC790',

    // Accessory names — glasses
    'accessory.hornRimmed': '\uBFFC\uD14C\uC548\uACBD',
    'accessory.sunglasses': '\uC120\uAE00\uB77C\uC2A4',
    'accessory.roundGlasses': '\uB465\uADFC\uC548\uACBD',
    'accessory.starGlasses': '\uBCC4\uC548\uACBD',

    // Unlock conditions
    'unlock.cap': '\uC138\uC158 10\uD68C',
    'unlock.partyHat': '\uCD1D 5\uC2DC\uAC04 \uC0AC\uC6A9',
    'unlock.santaHat': '500K \uD1A0\uD070 \uC0AC\uC6A9',
    'unlock.silkHat': '\uC5D0\uC774\uC804\uD2B8 50\uD68C \uC2E4\uD589',
    'unlock.cowboyHat': '\uCD1D 30\uC2DC\uAC04 \uC0AC\uC6A9',
    'unlock.hornRimmed': '\uB3D9\uC2DC 3\uAC1C \uC774\uC0C1 \uC138\uC158',
    'unlock.sunglasses': 'Rate Limit 10\uD68C \uB3C4\uB2EC',
    'unlock.roundGlasses': '\uAE34 \uC138\uC158(45\uBD84+) 20\uD68C',
    'unlock.starGlasses': 'Opus \uBAA8\uB378 10\uC2DC\uAC04',

    // States
    'state.idle': '\uC790\uACE0 \uC788\uC5B4\uC694...',
    'state.wakeUp': '\uAE68\uC5B4\uB098\uB294 \uC911!',
    'state.normal': '\uC2E0\uB098\uAC8C \uAC77\uB294 \uC911',
    'state.busy': '\uC5F4\uC2EC\uD788 \uC77C\uD558\uB294 \uC911!',
    'state.bloated': '\uCEE8\uD14D\uC2A4\uD2B8\uAC00 \uAC00\uB4DD...',
    'state.stressed': '\uB808\uC774\uD2B8 \uB9AC\uBC0B \uACBD\uACE0!',
    'state.tired': '\uD53C\uACE4\uD574\uC694...',
    'state.collab': '\uD568\uAED8 \uC77C\uD558\uB294 \uC911!',
    'state.idle.trigger': '\uD65C\uC131 \uC138\uC158 \uC5C6\uC74C',
    'state.wakeUp.trigger': '\uC218\uBA74\uC5D0\uC11C \uC804\uD658 \uC2DC',
    'state.normal.trigger': '\uAE30\uBCF8 \uD65C\uC131 \uC0C1\uD0DC',
    'state.busy.trigger': '\uB3C4\uAD6C 50\uD68C \uC774\uC0C1',
    'state.bloated.trigger': '\uCEE8\uD14D\uC2A4\uD2B8 >= 70%',
    'state.stressed.trigger': 'Rate Limit >= 80%',
    'state.tired.trigger': '\uC138\uC158 >= 45\uBD84',
    'state.collab.trigger': '\uC5D0\uC774\uC804\uD2B8 2\uAC1C \uC774\uC0C1',

    // Activity levels
    'effect.normal': '\uBCF4\uD1B5',
    'effect.glowing': '\uBE5B\uB098\uB294 \uC911',
    'effect.supercharged': '\uC288\uD37C\uCC28\uC9C0!',
    'effect.normal.cond': '\uC5D0\uC774\uC804\uD2B8 0-1',
    'effect.glowing.cond': '\uC5D0\uC774\uC804\uD2B8 2-3',
    'effect.supercharged.cond': '\uC5D0\uC774\uC804\uD2B8 4+',
  },
};


/* ============================================================
   Language Detection & Management
   ============================================================ */

const STORAGE_KEY = 'oh-my-clawd-lang';
const SUPPORTED_LANGS = ['en', 'ko'];
const DEFAULT_LANG = 'en';

/**
 * Detect the preferred language.
 * Priority: localStorage > browser language > default (en)
 */
function detectLang() {
  // Check localStorage first
  var stored = localStorage.getItem(STORAGE_KEY);
  if (stored && SUPPORTED_LANGS.indexOf(stored) !== -1) {
    return stored;
  }

  // Check browser language
  var browserLang = (navigator.language || navigator.userLanguage || '').slice(0, 2).toLowerCase();
  if (SUPPORTED_LANGS.indexOf(browserLang) !== -1) {
    return browserLang;
  }

  return DEFAULT_LANG;
}

/** Current language */
var currentLang = detectLang();


/* ============================================================
   Translation Application
   ============================================================ */

/**
 * Get a translated string by key.
 * Falls back to English, then to the key itself.
 */
function t(key) {
  var lang = translations[currentLang];
  if (lang && lang[key] !== undefined) {
    return lang[key];
  }
  // Fallback to English
  var en = translations[DEFAULT_LANG];
  if (en && en[key] !== undefined) {
    return en[key];
  }
  return key;
}

/**
 * Apply translations to all elements with [data-i18n] attribute.
 * The attribute value is the translation key.
 *
 * Supported modes:
 *   data-i18n="key"             -> sets textContent
 *   data-i18n-placeholder="key" -> sets placeholder attribute
 *   data-i18n-title="key"       -> sets title attribute
 *   data-i18n-html="key"        -> sets innerHTML
 */
function applyTranslations() {
  // Text content
  var elements = document.querySelectorAll('[data-i18n]');
  for (var i = 0; i < elements.length; i++) {
    var key = elements[i].getAttribute('data-i18n');
    if (key) {
      elements[i].textContent = t(key);
    }
  }

  // Placeholder
  var placeholders = document.querySelectorAll('[data-i18n-placeholder]');
  for (var i = 0; i < placeholders.length; i++) {
    var key = placeholders[i].getAttribute('data-i18n-placeholder');
    if (key) {
      placeholders[i].setAttribute('placeholder', t(key));
    }
  }

  // Title attribute
  var titles = document.querySelectorAll('[data-i18n-title]');
  for (var i = 0; i < titles.length; i++) {
    var key = titles[i].getAttribute('data-i18n-title');
    if (key) {
      titles[i].setAttribute('title', t(key));
    }
  }

  // innerHTML (for content with markup)
  var htmlElements = document.querySelectorAll('[data-i18n-html]');
  for (var i = 0; i < htmlElements.length; i++) {
    var key = htmlElements[i].getAttribute('data-i18n-html');
    if (key) {
      htmlElements[i].innerHTML = t(key);
    }
  }

  // Update html lang attribute
  document.documentElement.lang = currentLang;

  // Update active state on language dropdown links
  var langLinks = document.querySelectorAll('.lang-dropdown a');
  for (var i = 0; i < langLinks.length; i++) {
    var linkLang = langLinks[i].getAttribute('data-lang');
    if (linkLang === currentLang) {
      langLinks[i].classList.add('active');
    } else {
      langLinks[i].classList.remove('active');
    }
  }

  // Update the language switcher button text
  var langBtn = document.querySelector('.lang-switcher button');
  if (langBtn) {
    langBtn.textContent = currentLang === 'ko' ? 'KO' : 'EN';
  }
}


/* ============================================================
   Language Switching
   ============================================================ */

/**
 * Set the active language and re-apply all translations.
 * @param {string} lang - Language code ('en' or 'ko')
 */
function setLang(lang) {
  if (SUPPORTED_LANGS.indexOf(lang) === -1) {
    return;
  }
  currentLang = lang;
  localStorage.setItem(STORAGE_KEY, lang);
  applyTranslations();
}


/* ============================================================
   Initialization
   ============================================================ */

document.addEventListener('DOMContentLoaded', function () {
  // Apply translations on page load
  applyTranslations();

  // Set up language dropdown toggle
  var langSwitcher = document.querySelector('.lang-switcher button');
  var langDropdown = document.querySelector('.lang-dropdown');

  if (langSwitcher && langDropdown) {
    langSwitcher.addEventListener('click', function (e) {
      e.stopPropagation();
      langDropdown.classList.toggle('open');
    });

    // Close dropdown when clicking outside
    document.addEventListener('click', function () {
      langDropdown.classList.remove('open');
    });

    // Prevent dropdown clicks from closing it
    langDropdown.addEventListener('click', function (e) {
      e.stopPropagation();
    });
  }

  // Set up language selection links
  var langLinks = document.querySelectorAll('.lang-dropdown a[data-lang]');
  for (var i = 0; i < langLinks.length; i++) {
    langLinks[i].addEventListener('click', function (e) {
      e.preventDefault();
      var lang = this.getAttribute('data-lang');
      setLang(lang);
      if (langDropdown) {
        langDropdown.classList.remove('open');
      }
    });
  }
});
