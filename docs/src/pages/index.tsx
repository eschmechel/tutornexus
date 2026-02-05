import type { ReactNode } from 'react';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

// ============================================
// Hero Section
// ============================================

function HeroSection(): ReactNode {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={styles.hero}>
      <div className={styles.heroBackground}>
        <div className={styles.heroGrid} />
      </div>
      <div className={styles.heroContent}>
        <span className={styles.heroLabel}>AI-Powered Learning Platform</span>
        <Heading as="h1" className={styles.heroTitle}>
          Tutor Nexus
        </Heading>
        <p className={styles.heroTagline}>
          Where students cultivate knowledge, discover courses, and navigate transfers with AI-powered guidance.
        </p>
        <div className={styles.heroButtons}>
          <Link className={styles.buttonPrimary} to="/docs/guides/quickstart">
            Get Started
          </Link>
          <Link className={styles.buttonSecondary} to="/docs/reference/api">
            View API
          </Link>
        </div>
        <div className={styles.heroCode}>
          <code>git clone https://github.com/eschmechel/tutornexus.git</code>
        </div>
      </div>
    </header>
  );
}

// ============================================
// Features Section
// ============================================

type FeatureItem = {
  icon: string;
  title: string;
  description: string;
  link?: string;
  featured?: boolean;
};

const features: FeatureItem[] = [
  {
    icon: '🎓',
    title: 'Adaptive Tutoring',
    description: 'Voice-enabled AI sessions that understand your courses. Ask questions, work through problems, get explanations that click.',
    link: '/docs/reference/features',
    featured: true,
  },
  {
    icon: '📚',
    title: 'Course Intelligence',
    description: 'Deep access to SFU course outlines, instructor profiles, and curriculum data across institutions.',
  },
  {
    icon: '🔀',
    title: 'Transfer Planning',
    description: 'BC Transfer Guide integration. Know what credits transfer before you commit.',
  },
];

function FeatureCard({ icon, title, description, link, featured }: FeatureItem): ReactNode {
  return (
    <article className={`${styles.featureCard} ${featured ? styles.featureCardFeatured : ''}`}>
      <span className={styles.featureIcon}>{icon}</span>
      <h3 className={styles.featureTitle}>{title}</h3>
      <p className={styles.featureDescription}>{description}</p>
      {link && (
        <Link to={link} className={styles.featureLink}>
          Explore features →
        </Link>
      )}
    </article>
  );
}

function FeaturesSection(): ReactNode {
  return (
    <section className={styles.section}>
      <div className={styles.container}>
        <div className={styles.sectionHeader}>
          <span className={styles.sectionLabel}>Platform</span>
          <h2 className={styles.sectionTitle}>Three tools. One ecosystem.</h2>
          <p className={styles.sectionSubtitle}>Everything BC students need to learn, explore, and plan.</p>
        </div>
        <div className={styles.featureGrid}>
          {features.map((feature, idx) => (
            <FeatureCard key={idx} {...feature} />
          ))}
        </div>
      </div>
    </section>
  );
}

// ============================================
// Access Methods Section
// ============================================

type AccessItem = {
  icon: string;
  title: string;
  description: string;
};

const accessMethods: AccessItem[] = [
  { icon: '🌐', title: 'Web App', description: 'Full functionality in your browser' },
  { icon: '⌨️', title: 'CLI', description: 'Rust-powered terminal tool' },
  { icon: '🔌', title: 'MCP Server', description: 'IDE integration via Go server' },
  { icon: '🔗', title: 'REST API', description: 'OpenAPI-documented endpoints' },
];

function AccessSection(): ReactNode {
  return (
    <section className={`${styles.section} ${styles.sectionAlt}`}>
      <div className={styles.container}>
        <div className={styles.sectionHeader}>
          <span className={styles.sectionLabel}>Access</span>
          <h2 className={styles.sectionTitle}>Your workflow. Your way.</h2>
        </div>
        <div className={styles.accessGrid}>
          {accessMethods.map((item, idx) => (
            <div key={idx} className={styles.accessCard}>
              <span className={styles.accessIcon}>{item.icon}</span>
              <h4 className={styles.accessTitle}>{item.title}</h4>
              <p className={styles.accessDescription}>{item.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ============================================
// Docs Section
// ============================================

type DocLink = {
  title: string;
  description: string;
  href: string;
  primary?: boolean;
};

const docLinks: DocLink[] = [
  { title: 'Quick Start', description: 'Five minutes to your first local build', href: '/docs/guides/quickstart', primary: true },
  { title: 'API Reference', description: 'Complete REST documentation', href: '/docs/reference/api' },
  { title: 'Architecture', description: '19 decision records', href: '/docs/adrs' },
  { title: 'Deployment', description: 'Cloudflare Workers setup', href: '/docs/guides/deployment' },
];

function DocsSection(): ReactNode {
  return (
    <section className={styles.section}>
      <div className={styles.container}>
        <div className={styles.sectionHeader}>
          <span className={styles.sectionLabel}>Docs</span>
          <h2 className={styles.sectionTitle}>Start here</h2>
        </div>
        <div className={styles.docsGrid}>
          {docLinks.map((doc, idx) => (
            <Link key={idx} to={doc.href} className={`${styles.docCard} ${doc.primary ? styles.docCardPrimary : ''}`}>
              <div className={styles.docCardContent}>
                <h3 className={styles.docCardTitle}>{doc.title}</h3>
                <p className={styles.docCardDescription}>{doc.description}</p>
              </div>
              <span className={styles.docCardArrow}>→</span>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}

// ============================================
// Tech Stack Section
// ============================================

type StackItem = {
  label: string;
  value: string;
};

const stackItems: StackItem[] = [
  { label: 'Frontend', value: 'React + Vite + Tailwind' },
  { label: 'Backend', value: 'Cloudflare Workers + Hono' },
  { label: 'Database', value: 'D1 + Vectorize' },
  { label: 'MCP', value: 'Go 1.25' },
  { label: 'CLI', value: 'Rust + Clap' },
  { label: 'Voice', value: 'Deepgram + ElevenLabs' },
];

function StackSection(): ReactNode {
  return (
    <section className={`${styles.section} ${styles.sectionDark}`}>
      <div className={styles.container}>
        <div className={styles.sectionHeader}>
          <span className={styles.sectionLabel}>Stack</span>
          <h2 className={styles.sectionTitleLight}>Built on solid ground</h2>
        </div>
        <div className={styles.stackGrid}>
          {stackItems.map((item, idx) => (
            <div key={idx} className={styles.stackItem}>
              <span className={styles.stackLabel}>{item.label}</span>
              <span className={styles.stackValue}>{item.value}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// ============================================
// CTA Section
// ============================================

function CTASection(): ReactNode {
  return (
    <section className={styles.section}>
      <div className={styles.container}>
        <div className={styles.ctaBox}>
          <h2 className={styles.ctaTitle}>Ready to begin?</h2>
          <p className={styles.ctaDescription}>Clone the repo and start building in minutes.</p>
          <div className={styles.ctaCode}>
            <code>git clone https://github.com/eschmechel/tutornexus.git</code>
          </div>
          <Link to="/docs/guides/quickstart" className={styles.buttonPrimary}>
            Read the Quick Start →
          </Link>
        </div>
      </div>
    </section>
  );
}

// ============================================
// Main Component
// ============================================

export default function Home(): ReactNode {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title="AI Tutoring for BC Students"
      description="AI tutoring and course transfer planning for British Columbia students. Voice-enabled learning, course intelligence, and transfer planning.">
      <HeroSection />
      <main>
        <FeaturesSection />
        <AccessSection />
        <DocsSection />
        <StackSection />
        <CTASection />
      </main>
    </Layout>
  );
}
