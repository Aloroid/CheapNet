import { defineConfig } from "vitepress"

// https://vitepress.dev/reference/site-config
export default defineConfig({
    lang: 'en-US',
    title: "CheapNet",
    titleTemplate: ":title - A Roblox networking library",

    description: "A Roblox networking library.",
    base: "/main/",
    head: [["link", { rel: "icon", href: "/ecr/favicon.svg" }]],
    ignoreDeadLinks: true,

    themeConfig: {
        logo: "/logo.svg",
        siteTitle: "CheapNet",

        // https://vitepress.dev/reference/default-theme-config
        nav: [
            { text: "Home", link: "/" },
            { text: "Tutorials", link: "/tut/crashcourse" },
            { text: "API", link: "/api/cheapnet"},
        ],

        outline: "deep",

        sidebar: {
            "/api/": [
                {
                    text: "API",
                    items: [
                        { text: "cheapnet", link: "/api/cheapnet" },
                        { text: "Event", link: "/api/event" },
                        { text: "Signal", link: "/api/signal" },
                        { text: "Filterable", link: "/api/filterable" },
                    ]
                }
            ],

            "/tut/": [
                {
                    text: "Tutorials",
                    items: [
                        { text: "Crash Course", link: "/tut/crashcourse" },
                    ]
                }
            ],
        },

        socialLinks: [
             { icon: "github", link: "https://github.com/aloroid/cheapnet" }
        ],

        footer: {
            message: "Released under 0BSD"
        }
    },

})