import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'CachyOS Workstation',
  description: 'Modular, aesthetic, bilingual developer environment built on CachyOS',
  lang: 'en-US',
  base: '/CachyOS-Workstation-Setup/',

  head: [
    ['meta', { name: 'theme-color', content: '#cba6f7' }],
    ['meta', { name: 'og:type', content: 'website' }],
    ['meta', { name: 'og:title', content: 'CachyOS Workstation Setup' }],
    ['meta', { name: 'og:description', content: 'Transform a fresh CachyOS install into a fully-configured developer workstation in under 30 minutes.' }],
    ['meta', { name: 'og:url', content: 'https://anantaarthasejahtera.github.io/CachyOS-Workstation-Setup/' }],
  ],

  themeConfig: {
    logo: 'https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/logos/exports/1544x1544_circle.png',

    nav: [
      { text: 'Guide', link: '/guide/' },
      { text: 'GitHub', link: 'https://github.com/anantaarthasejahtera/CachyOS-Workstation-Setup' },
    ],

    sidebar: [
      {
        text: '📖 Guide',
        items: [
          { text: '🌟 Introduction', link: '/guide/' },
          { text: '📦 Installation', link: '/guide/installation' },
          { text: '🏗️ Architecture', link: '/guide/architecture' },
          { text: '🧩 Modules', link: '/guide/modules' },
          { text: '🔧 Configuration', link: '/guide/configuration' },
          { text: '⌨️ Keybinds', link: '/guide/keybinds' },
          { text: '🎮 Nexus', link: '/guide/nexus' },
          { text: '🌍 Living Ecosystem', link: '/guide/living-ecosystem' },
          { text: '🤖 AI Tools', link: '/guide/ai-tools' },
          { text: '🆘 Troubleshooting', link: '/guide/troubleshooting' },
        ],
      },
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/anantaarthasejahtera/CachyOS-Workstation-Setup' },
    ],

    footer: {
      message: 'Released under the GPL-3.0 License.',
      copyright: 'Copyright © 2024-present PT Ananta Artha Sejahtera',
    },

    editLink: {
      pattern: 'https://github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/edit/main/docs/:path',
      text: 'Edit this page on GitHub',
    },

    search: {
      provider: 'local',
    },
  },
})
