import type { ReactNode } from 'react';
import Link from '@docusaurus/Link';
import styles from './styles.module.css';

type FeatureItem = {
  icon: string;
  title: string;
  description: string;
  link?: string;
};

const FeatureList: FeatureItem[] = [
  {
    icon: '🎓',
    title: 'Adaptive Tutoring',
    description: 'Voice-enabled AI sessions that understand your courses. Ask questions, work through problems, get explanations that click.',
    link: '/docs/reference/features',
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

function Feature({ icon, title, description, link }: FeatureItem): ReactNode {
  return (
    <article className={styles.featureCard}>
      <span className={styles.featureIcon}>{icon}</span>
      <h3 className={styles.featureTitle}>{title}</h3>
      <p className={styles.featureDescription}>{description}</p>
      {link && (
        <Link to={link} className={styles.featureLink}>
          Learn more →
        </Link>
      )}
    </article>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className={styles.container}>
        <div className={styles.header}>
          <span className={styles.label}>Platform</span>
          <h2 className={styles.title}>Three tools. One ecosystem.</h2>
          <p className={styles.subtitle}>Everything BC students need to learn, explore, and plan.</p>
        </div>
        <div className={styles.grid}>
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
