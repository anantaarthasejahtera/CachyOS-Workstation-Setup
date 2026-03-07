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
                text: 'Architecture',
                items: [
                    { text: 'The 15 Modules', link: '/guide/modules' }
                ]
            },
            {
                text: 'Ecosystem & Interface',
                items: [
                    { text: 'Nexus Command Center', link: '/guide/nexus' },
                    { text: 'Living Ecosystem', link: '/guide/living-ecosystem' },
                    { text: 'AI Developer Tools', link: '/guide/ai-tools' }
                ]
            },
            {
                text: 'Advanced Usage',
                items: [
                    { text: 'Configuration & Customization', link: '/guide/configuration' },
                    { text: 'Master Cheat Sheet (Keybinds)', link: '/guide/keybinds' }
                ]
            },
            {
                text: 'Deep Dive',
                items: [
                    { text: 'Architecture & Design', link: '/guide/architecture' },
                    { text: 'Troubleshooting & FAQ', link: '/guide/troubleshooting' }
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
