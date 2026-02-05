module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',
        'fix',
        'docs',
        'style',
        'refactor',
        'perf',
        'test',
        'chore',
        'revert',
      ],
    ],
    'scope-enum': [
      2,
      'always',
      ['api', 'mcp', 'cli', 'web', 'adapter', 'docs', 'infra', 'db'],
    ],
    'header-min-length': [2, 'always', 10],
    'header-max-length': [2, 'always', 100],
  },
};
