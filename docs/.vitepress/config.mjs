import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "CachyOS Workstation",
  description: "Enterprise-grade, modular, aesthetic developer environment.",
  base: '/CachyOS-Workstation-Setup/',
  themeConfig: {
    logo: 'https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/logos/exports/1544x1544_circle.png',
    nav: [
      { text: 'Home', link: '/' },
      { text: 'Guide', link: '/guide/' },
      { text: 'Release Notes', link: 'https://github.com/anantaarthasejahtera/CachyOS-Workstation-Setup/releases' }
    ],
    sidebar: [
      {
        text: 'Getting Started',
        items: [
          { text: 'Introduction', link: '/guide/' },
          { text: 'Installation', link: '/guide/installation' }
        ]
      },
      {
        text: 'Living Ecosystem',
        items: [
          { text: 'Nexus Command Center', link: '/guide/nexus' },
          { text: 'Tools & Utilities', link: '/guide/tools' }
        ]
      }
    ],
    socialLinks: [
      { icon: 'github', link: 'https://github.com/anantaarthasejahtera/CachyOS-Workstation-Setup' }
    ],
    search: {
      provider: 'local'
    },
    footer: {
      message: 'Released under the GPL-3.0 License.',
      copyright: 'Copyright © 2026 PT Ananta Artha Sejahtera'
    }
  }
})
