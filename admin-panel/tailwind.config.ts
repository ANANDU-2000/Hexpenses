import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./app/**/*.{js,ts,jsx,tsx,mdx}', './components/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        mf: {
          bg: '#0B1220',
          card: '#121A2B',
          lime: '#E6FF4D',
          purple: '#8B9CFF',
          muted: '#8D93A1',
        },
      },
      borderRadius: {
        card: '16px',
      },
    },
  },
  plugins: [],
};

export default config;
