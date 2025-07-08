import '@testing-library/jest-dom';
import { configure } from '@testing-library/react';

// Configure testing library
configure({ testIdAttribute: 'data-testid' });

// Mock environment variables for security testing
const mockEnvVars = {
  NODE_ENV: 'test',
  AUTH_SECRET: 'test-secret',
  GITHUB_TOKEN: 'test-token',
  DATABASE_URL: 'postgresql://test:test@localhost:5432/test',
  REDIS_URL: 'redis://localhost:6379',
};

// Set up environment variables for testing
Object.entries(mockEnvVars).forEach(([key, value]) => {
  process.env[key] = value;
});

// Mock fetch for API testing
global.fetch = jest.fn();

// Mock console methods to avoid noise in tests
const originalConsoleError = console.error;
const originalConsoleWarn = console.warn;

beforeAll(() => {
  console.error = (...args: any[]) => {
    if (
      typeof args[0] === 'string' &&
      args[0].includes('Warning: ReactDOM.render is deprecated')
    ) {
      return;
    }
    originalConsoleError.call(console, ...args);
  };

  console.warn = (...args: any[]) => {
    if (
      typeof args[0] === 'string' &&
      args[0].includes('Warning: componentWillReceiveProps')
    ) {
      return;
    }
    originalConsoleWarn.call(console, ...args);
  };
});

afterAll(() => {
  console.error = originalConsoleError;
  console.warn = originalConsoleWarn;
});

// Security testing utilities
export const createMockCredentials = () => ({
  username: 'test-user',
  password: 'test-password',
  token: 'test-token',
  apiKey: 'test-api-key',
});

export const createMockSecrets = () => ({
  databaseUrl: 'postgresql://user:pass@localhost:5432/db',
  redisUrl: 'redis://localhost:6379',
  jwtSecret: 'jwt-secret',
  encryptionKey: 'encryption-key',
});

// Mock for security scanning
export const mockSecurityScan = jest.fn().mockResolvedValue({
  vulnerabilities: [],
  severity: 'low',
  score: 0,
});

// Mock for credential detection
export const mockCredentialScan = jest.fn().mockResolvedValue({
  found: false,
  secrets: [],
  score: 0,
});

// Test utilities for security validation
export const validateNoSecretsInCode = (code: string): boolean => {
  const secretPatterns = [
    /password\s*=\s*['"][^'"]+['"]/gi,
    /token\s*=\s*['"][^'"]+['"]/gi,
    /secret\s*=\s*['"][^'"]+['"]/gi,
    /api[_-]?key\s*=\s*['"][^'"]+['"]/gi,
    /private[_-]?key\s*=\s*['"][^'"]+['"]/gi,
  ];

  return !secretPatterns.some(pattern => pattern.test(code));
};

export const validateNoHardcodedUrls = (code: string): boolean => {
  const urlPatterns = [
    /https?:\/\/[^\s'"]+\.(com|org|net|io|dev)/gi,
    /localhost:\d+/gi,
    /127\.0\.0\.1:\d+/gi,
  ];

  return !urlPatterns.some(pattern => pattern.test(code));
};

// Mock for Kubernetes API
export const mockKubernetesAPI = {
  listPods: jest.fn().mockResolvedValue([]),
  getPod: jest.fn().mockResolvedValue({}),
  createPod: jest.fn().mockResolvedValue({}),
  deletePod: jest.fn().mockResolvedValue({}),
};

// Mock for ArgoCD API
export const mockArgoCDAPI = {
  listApplications: jest.fn().mockResolvedValue([]),
  getApplication: jest.fn().mockResolvedValue({}),
  syncApplication: jest.fn().mockResolvedValue({}),
  createApplication: jest.fn().mockResolvedValue({}),
};

// Mock for GitHub API
export const mockGitHubAPI = {
  listRepositories: jest.fn().mockResolvedValue([]),
  getRepository: jest.fn().mockResolvedValue({}),
  createRepository: jest.fn().mockResolvedValue({}),
  listWorkflows: jest.fn().mockResolvedValue([]),
};

// Cleanup after each test
afterEach(() => {
  jest.clearAllMocks();
  jest.resetModules();
});

// Global test timeout
jest.setTimeout(30000); 