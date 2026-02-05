import { themes as prismThemes } from 'prism-react-renderer';
import type { Config } from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

const config: Config = {
  title: 'Tutor Nexus',
  tagline: 'AI tutoring and course transfer planning for BC students',
  favicon: 'img/favicon.svg',

  future: {
    v4: true,
  },

  url: 'https://tutornexus.dev',
  baseUrl: '/',

  organizationName: 'eschmechel',
  projectName: 'tutornexus',

  onBrokenLinks: 'throw',
  onBrokenAnchors: 'throw',

  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'throw',
    },
  },

  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          editUrl: 'https://github.com/eschmechel/tutornexus/tree/main/docs/',
          // Disable until files are tracked in git
          showLastUpdateTime: false,
        },
        blog: false, // Disable blog
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    image: 'img/social-card.png',
    
    colorMode: {
      defaultMode: 'dark',
      disableSwitch: false,
      respectPrefersColorScheme: true,
    },

    navbar: {
      title: 'Tutor Nexus',
      logo: {
        alt: 'Tutor Nexus Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'guidesSidebar',
          position: 'left',
          label: 'Guides',
        },
        {
          type: 'docSidebar',
          sidebarId: 'referenceSidebar',
          position: 'left',
          label: 'Reference',
        },
        {
          type: 'docSidebar',
          sidebarId: 'adrsSidebar',
          position: 'left',
          label: 'Architecture',
        },
        {
          href: 'https://github.com/eschmechel/tutornexus',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },

    footer: {
      style: 'dark',
      links: [
        {
          title: 'Documentation',
          items: [
            {
              label: 'Quick Start',
              to: '/docs/guides/quickstart',
            },
            {
              label: 'API Reference',
              to: '/docs/reference/api',
            },
            {
              label: 'Architecture',
              to: '/docs/adrs',
            },
          ],
        },
        {
          title: 'Guides',
          items: [
            {
              label: 'Development',
              to: '/docs/guides/development',
            },
            {
              label: 'Deployment',
              to: '/docs/guides/deployment',
            },
            {
              label: 'Security',
              to: '/docs/guides/security',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'GitHub',
              href: 'https://github.com/eschmechel/tutornexus',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Tutor Nexus. Built with Docusaurus.`,
    },

    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['bash', 'rust', 'go', 'toml', 'yaml', 'json'],
    },

    // Algolia search can be configured later
    // algolia: {
    //   appId: 'YOUR_APP_ID',
    //   apiKey: 'YOUR_SEARCH_API_KEY',
    //   indexName: 'tutornexus',
    // },
  } satisfies Preset.ThemeConfig,
};

export default config;
