/* ============================================================
   Claude HUD — i18n Translation System
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
    'hero.title': 'Claude HUD',
    'hero.subtitle': 'A lightweight status line + menu bar pet for Claude Code',
    'hero.description': 'Rate Limit, Session Time, Context Usage, Tool Calls, Agents, Model Info \u2014 all at a glance. Plus a Tamagotchi-style pixel art pet that reacts to your coding activity.',
    'hero.cta.download': 'Download DMG',
    'hero.cta.docs': 'Read Docs',
    'hero.stat.pets': '12 Pets',
    'hero.stat.states': '7 States',
    'hero.stat.muscles': '3 Muscles',
    'hero.stat.hud': 'HUD',

    // Features section
    'features.title': 'Features',
    'features.hud.title': 'HUD Status Line',
    'features.hud.desc': 'Real-time rate limits, session duration, context usage, tool calls, and active model info displayed in your terminal.',
    'features.pet.title': 'Pet System',
    'features.pet.desc': '12 collectible pets with 7 emotional states and 3 muscle stages. Each pet has unique unlock conditions based on your Claude Code usage.',
    'features.update.title': 'Auto Updates',
    'features.update.desc': 'Check for updates directly from the app. Download the latest DMG from GitHub Releases with one click.',

    // Collection
    'collection.title': 'Pet Collection',

    // Install
    'install.title': 'Get Started',
    'install.step1.title': 'Download',
    'install.step1.desc': 'Get the latest DMG from GitHub Releases',
    'install.step2.title': 'Install',
    'install.step2.desc': 'Drag ClaudePet.app to Applications',
    'install.step3.title': 'Launch',
    'install.step3.desc': 'Open the app and check your menu bar',

    // Footer
    'footer.license': 'MIT License',
    'footer.github': 'GitHub',

    // Docs page — sidebar
    'docs.sidebar.getting-started': 'Getting Started',
    'docs.sidebar.installation': 'Installation',
    'docs.sidebar.quick-start': 'Quick Start',
    'docs.sidebar.features': 'Features',
    'docs.sidebar.pet-system': 'Pet System',
    'docs.sidebar.muscle-stages': 'Muscle Stages',
    'docs.sidebar.hud': 'HUD Status Line',
    'docs.sidebar.collection': 'Pet Collection',
    'docs.sidebar.config': 'Configuration',
    'docs.sidebar.update': 'Update',

    // Docs content sections
    'docs.install.title': 'Installation',
    'docs.install.dmg': 'Download DMG (Recommended)',
    'docs.install.dmg.desc': 'Download the latest DMG from GitHub Releases, open it, and drag ClaudePet.app to your Applications folder.',
    'docs.install.manual': 'Manual Install',
    'docs.quickstart.title': 'Quick Start',
    'docs.pet.title': 'Pet System',
    'docs.pet.desc': 'Your pet lives in the macOS menu bar and reacts to Claude Code activity across all sessions.',
    'docs.pet.states.title': 'Pet States',
    'docs.muscle.title': 'Muscle Stages',
    'docs.muscle.desc': 'Your pet grows based on concurrent agent count.',
    'docs.hud.title': 'HUD Status Line',
    'docs.hud.desc': 'A real-time status line showing Claude Code metrics.',
    'docs.collection.title': 'Pet Collection',
    'docs.collection.desc': '12 collectible pets, each with unique unlock conditions.',
    'docs.config.title': 'Configuration',
    'docs.update.title': 'Update',
    'docs.update.desc': 'Check for updates directly from the app popover, or download the latest DMG from GitHub Releases.',

    // Pet names
    'pet.cat': 'Cat',
    'pet.hamster': 'Hamster',
    'pet.chick': 'Chick',
    'pet.penguin': 'Penguin',
    'pet.fox': 'Fox',
    'pet.rabbit': 'Rabbit',
    'pet.goose': 'Goose',
    'pet.capybara': 'Capybara',
    'pet.sloth': 'Sloth',
    'pet.owl': 'Owl',
    'pet.dragon': 'Dragon',
    'pet.unicorn': 'Unicorn',

    // Unlock conditions
    'unlock.cat': 'Default pet',
    'unlock.hamster': 'Total 10 sessions',
    'unlock.chick': '5 hours total usage',
    'unlock.penguin': '500K tokens used',
    'unlock.fox': '50 agent runs',
    'unlock.rabbit': '3+ concurrent sessions',
    'unlock.goose': '30 hours total usage',
    'unlock.capybara': '10 rate limit hits',
    'unlock.sloth': '20 long sessions (45m+)',
    'unlock.owl': '10 hours on Opus',
    'unlock.dragon': '5+ concurrent agents',
    'unlock.unicorn': 'Unlock all other pets',

    // States
    'state.sleeping': 'Sleeping',
    'state.walking': 'Walking',
    'state.running': 'Running',
    'state.bloated': 'Bloated',
    'state.stressed': 'Stressed',
    'state.tired': 'Tired',
    'state.collab': 'Collab',
    'state.sleeping.trigger': 'No active sessions',
    'state.walking.trigger': 'Normal usage',
    'state.running.trigger': '50+ tool calls',
    'state.bloated.trigger': 'Context >= 70%',
    'state.stressed.trigger': 'Rate limit >= 80%',
    'state.tired.trigger': 'Session > 45 min',
    'state.collab.trigger': '2+ agents',

    // Muscles
    'muscle.normal': 'Normal',
    'muscle.buff': 'Buff',
    'muscle.macho': 'Macho',
    'muscle.normal.cond': '0-1 agents',
    'muscle.buff.cond': '2-3 agents',
    'muscle.macho.cond': '4+ agents',
  },

  ko: {
    // Navbar
    'nav.home': '\uD648',
    'nav.docs': '\uBB38\uC11C',
    'nav.features': '\uAE30\uB2A5',
    'nav.collection': '\uCEEC\uB809\uC158',

    // Hero
    'hero.title': 'Claude HUD',
    'hero.subtitle': 'Claude Code\uB97C \uC704\uD55C \uC0C1\uD0DC \uD45C\uC2DC\uC904 + \uBA54\uB274\uBC14 \uD3AB',
    'hero.description': 'Rate Limit, \uC138\uC158 \uC2DC\uAC04, \uCEE8\uD14D\uC2A4\uD2B8 \uC0AC\uC6A9\uB7C9, \uB3C4\uAD6C \uD638\uCD9C, \uC5D0\uC774\uC804\uD2B8, \uBAA8\uB378 \uC815\uBCF4\uB97C \uD55C\uB208\uC5D0. \uCF54\uB529 \uD65C\uB3D9\uC5D0 \uBC18\uC751\uD558\uB294 \uD0C0\uB9C8\uACE0\uCE58 \uC2A4\uD0C0\uC77C \uD53D\uC140\uC544\uD2B8 \uD3AB\uB3C4 \uD568\uAED8.',
    'hero.cta.download': 'DMG \uB2E4\uC6B4\uB85C\uB4DC',
    'hero.cta.docs': '\uBB38\uC11C \uBCF4\uAE30',
    'hero.stat.pets': '12\uC885 \uD3AB',
    'hero.stat.states': '7\uAC00\uC9C0 \uC0C1\uD0DC',
    'hero.stat.muscles': '3\uB2E8\uACC4 \uADFC\uC721',
    'hero.stat.hud': 'HUD',

    // Features section
    'features.title': '\uAE30\uB2A5',
    'features.hud.title': 'HUD \uC0C1\uD0DC \uD45C\uC2DC\uC904',
    'features.hud.desc': 'Rate Limit, \uC138\uC158 \uC9C0\uC18D\uC2DC\uAC04, \uCEE8\uD14D\uC2A4\uD2B8 \uC0AC\uC6A9\uB7C9, \uB3C4\uAD6C \uD638\uCD9C, \uD65C\uC131 \uBAA8\uB378 \uC815\uBCF4\uB97C \uD130\uBBF8\uB110\uC5D0 \uC2E4\uC2DC\uAC04 \uD45C\uC2DC\uD569\uB2C8\uB2E4.',
    'features.pet.title': '\uD3AB \uC2DC\uC2A4\uD15C',
    'features.pet.desc': '7\uAC00\uC9C0 \uAC10\uC815 \uC0C1\uD0DC\uC640 3\uB2E8\uACC4 \uADFC\uC721\uC744 \uAC00\uC9C4 12\uC885\uC758 \uC218\uC9D1 \uAC00\uB2A5\uD55C \uD3AB. \uAC01 \uD3AB\uC740 Claude Code \uC0AC\uC6A9\uB7C9\uC5D0 \uB530\uB978 \uACE0\uC720\uD55C \uC5B8\uB77D \uC870\uAC74\uC774 \uC788\uC2B5\uB2C8\uB2E4.',
    'features.update.title': '\uC790\uB3D9 \uC5C5\uB370\uC774\uD2B8',
    'features.update.desc': '\uC571\uC5D0\uC11C \uC9C1\uC811 \uC5C5\uB370\uC774\uD2B8\uB97C \uD655\uC778\uD558\uC138\uC694. \uD074\uB9AD \uD55C \uBC88\uC73C\uB85C GitHub Releases\uC5D0\uC11C \uCD5C\uC2E0 DMG\uB97C \uB2E4\uC6B4\uB85C\uB4DC\uD569\uB2C8\uB2E4.',

    // Collection
    'collection.title': '\uD3AB \uCEEC\uB809\uC158',

    // Install
    'install.title': '\uC2DC\uC791\uD558\uAE30',
    'install.step1.title': '\uB2E4\uC6B4\uB85C\uB4DC',
    'install.step1.desc': 'GitHub Releases\uC5D0\uC11C \uCD5C\uC2E0 DMG \uB2E4\uC6B4\uB85C\uB4DC',
    'install.step2.title': '\uC124\uCE58',
    'install.step2.desc': 'ClaudePet.app\uC744 Applications\uB85C \uB4DC\uB798\uADF8',
    'install.step3.title': '\uC2E4\uD589',
    'install.step3.desc': '\uC571\uC744 \uC5F4\uACE0 \uBA54\uB274\uBC14\uB97C \uD655\uC778\uD558\uC138\uC694',

    // Footer
    'footer.license': 'MIT \uB77C\uC774\uC120\uC2A4',
    'footer.github': 'GitHub',

    // Docs page — sidebar
    'docs.sidebar.getting-started': '\uC2DC\uC791\uD558\uAE30',
    'docs.sidebar.installation': '\uC124\uCE58',
    'docs.sidebar.quick-start': '\uBE60\uB978 \uC2DC\uC791',
    'docs.sidebar.features': '\uAE30\uB2A5',
    'docs.sidebar.pet-system': '\uD3AB \uC2DC\uC2A4\uD15C',
    'docs.sidebar.muscle-stages': '\uADFC\uC721 \uB2E8\uACC4',
    'docs.sidebar.hud': 'HUD \uC0C1\uD0DC \uD45C\uC2DC\uC904',
    'docs.sidebar.collection': '\uD3AB \uCEEC\uB809\uC158',
    'docs.sidebar.config': '\uC124\uC815',
    'docs.sidebar.update': '\uC5C5\uB370\uC774\uD2B8',

    // Docs content sections
    'docs.install.title': '\uC124\uCE58',
    'docs.install.dmg': 'DMG \uB2E4\uC6B4\uB85C\uB4DC (\uAD8C\uC7A5)',
    'docs.install.dmg.desc': 'GitHub Releases\uC5D0\uC11C \uCD5C\uC2E0 DMG\uB97C \uB2E4\uC6B4\uB85C\uB4DC\uD558\uACE0, \uC5F4\uC5B4\uC11C ClaudePet.app\uC744 Applications \uD3F4\uB354\uB85C \uB4DC\uB798\uADF8\uD558\uC138\uC694.',
    'docs.install.manual': '\uC218\uB3D9 \uC124\uCE58',
    'docs.quickstart.title': '\uBE60\uB978 \uC2DC\uC791',
    'docs.pet.title': '\uD3AB \uC2DC\uC2A4\uD15C',
    'docs.pet.desc': '\uD3AB\uC740 macOS \uBA54\uB274\uBC14\uC5D0 \uC0B4\uBA70 \uBAA8\uB4E0 \uC138\uC158\uC758 Claude Code \uD65C\uB3D9\uC5D0 \uBC18\uC751\uD569\uB2C8\uB2E4.',
    'docs.pet.states.title': '\uD3AB \uC0C1\uD0DC',
    'docs.muscle.title': '\uADFC\uC721 \uB2E8\uACC4',
    'docs.muscle.desc': '\uB3D9\uC2DC \uC5D0\uC774\uC804\uD2B8 \uC218\uC5D0 \uB530\uB77C \uD3AB\uC774 \uC131\uC7A5\uD569\uB2C8\uB2E4.',
    'docs.hud.title': 'HUD \uC0C1\uD0DC \uD45C\uC2DC\uC904',
    'docs.hud.desc': 'Claude Code \uBA54\uD2B8\uB9AD\uC744 \uC2E4\uC2DC\uAC04\uC73C\uB85C \uBCF4\uC5EC\uC8FC\uB294 \uC0C1\uD0DC \uD45C\uC2DC\uC904\uC785\uB2C8\uB2E4.',
    'docs.collection.title': '\uD3AB \uCEEC\uB809\uC158',
    'docs.collection.desc': '\uAC01\uAC01 \uACE0\uC720\uD55C \uC5B8\uB77D \uC870\uAC74\uC744 \uAC00\uC9C4 12\uC885\uC758 \uC218\uC9D1 \uAC00\uB2A5\uD55C \uD3AB.',
    'docs.config.title': '\uC124\uC815',
    'docs.update.title': '\uC5C5\uB370\uC774\uD2B8',
    'docs.update.desc': '\uC571 \uD31D\uC624\uBC84\uC5D0\uC11C \uC9C1\uC811 \uC5C5\uB370\uC774\uD2B8\uB97C \uD655\uC778\uD558\uAC70\uB098, GitHub Releases\uC5D0\uC11C \uCD5C\uC2E0 DMG\uB97C \uB2E4\uC6B4\uB85C\uB4DC\uD558\uC138\uC694.',

    // Pet names
    'pet.cat': '\uACE0\uC591\uC774',
    'pet.hamster': '\uD584\uC2A4\uD130',
    'pet.chick': '\uBCD1\uC544\uB9AC',
    'pet.penguin': '\uD3AD\uADC4',
    'pet.fox': '\uC5EC\uC6B0',
    'pet.rabbit': '\uD1A0\uB07C',
    'pet.goose': '\uAC70\uC704',
    'pet.capybara': '\uCE74\uD53C\uBC14\uB77C',
    'pet.sloth': '\uB098\uBB34\uB298\uBCF4',
    'pet.owl': '\uC62C\uBE7C\uBBF8',
    'pet.dragon': '\uB4DC\uB798\uACE4',
    'pet.unicorn': '\uC720\uB2C8\uCF58',

    // Unlock conditions
    'unlock.cat': '\uAE30\uBCF8 \uD3AB',
    'unlock.hamster': '\uCD1D 10\uD68C \uC138\uC158',
    'unlock.chick': '\uCD1D 5\uC2DC\uAC04 \uC0AC\uC6A9',
    'unlock.penguin': '500K \uD1A0\uD070 \uC0AC\uC6A9',
    'unlock.fox': '\uC5D0\uC774\uC804\uD2B8 50\uD68C \uC2E4\uD589',
    'unlock.rabbit': '\uB3D9\uC2DC 3\uAC1C \uC774\uC0C1 \uC138\uC158',
    'unlock.goose': '\uCD1D 30\uC2DC\uAC04 \uC0AC\uC6A9',
    'unlock.capybara': 'Rate Limit 10\uD68C \uB3C4\uB2EC',
    'unlock.sloth': '\uAE34 \uC138\uC158(45\uBD84+) 20\uD68C',
    'unlock.owl': 'Opus \uBAA8\uB378 10\uC2DC\uAC04',
    'unlock.dragon': '\uB3D9\uC2DC 5\uAC1C \uC774\uC0C1 \uC5D0\uC774\uC804\uD2B8',
    'unlock.unicorn': '\uBAA8\uB4E0 \uD3AB \uC5B8\uB77D',

    // States
    'state.sleeping': '\uC218\uBA74',
    'state.walking': '\uAC77\uAE30',
    'state.running': '\uB2EC\uB9AC\uAE30',
    'state.bloated': '\uB5A1\uB5A1',
    'state.stressed': '\uC2A4\uD2B8\uB808\uC2A4',
    'state.tired': '\uD53C\uACE4',
    'state.collab': '\uD611\uC5C5',
    'state.sleeping.trigger': '\uD65C\uC131 \uC138\uC158 \uC5C6\uC74C',
    'state.walking.trigger': '\uC77C\uBC18 \uC0AC\uC6A9',
    'state.running.trigger': '\uB3C4\uAD6C 50\uD68C \uC774\uC0C1',
    'state.bloated.trigger': '\uCEE8\uD14D\uC2A4\uD2B8 >= 70%',
    'state.stressed.trigger': 'Rate Limit >= 80%',
    'state.tired.trigger': '\uC138\uC158 > 45\uBD84',
    'state.collab.trigger': '\uC5D0\uC774\uC804\uD2B8 2\uAC1C \uC774\uC0C1',

    // Muscles
    'muscle.normal': '\uC77C\uBC18',
    'muscle.buff': '\uBC84\uD504',
    'muscle.macho': '\uB9C8\uCD08',
    'muscle.normal.cond': '\uC5D0\uC774\uC804\uD2B8 0-1',
    'muscle.buff.cond': '\uC5D0\uC774\uC804\uD2B8 2-3',
    'muscle.macho.cond': '\uC5D0\uC774\uC804\uD2B8 4+',
  },
};


/* ============================================================
   Language Detection & Management
   ============================================================ */

const STORAGE_KEY = 'claude-pet-lang';
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
