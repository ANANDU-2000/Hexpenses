import axios from 'axios';

const baseUrl = process.env.CANARY_BASE_URL || 'http://localhost:4000/api';

async function run() {
  const checks = ['/reports/monthly-summary', '/reports/category-breakdown', '/notifications'];
  for (const path of checks) {
    try {
      const response = await axios.get(`${baseUrl}${path}`);
      console.log(`${path}: ${response.status}`);
    } catch (error: any) {
      console.log(`${path}: failed (${error.response?.status ?? 'network'})`);
    }
  }
}

run();
