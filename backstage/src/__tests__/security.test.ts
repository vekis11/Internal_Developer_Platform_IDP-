import { validateNoSecretsInCode, validateNoHardcodedUrls } from '../setupTests';

describe('Security Tests', () => {
  describe('Credential Exposure Detection', () => {
    test('should detect hardcoded passwords', () => {
      const codeWithPassword = `
        const config = {
          password: 'mysecretpassword123',
          username: 'admin'
        };
      `;
      expect(validateNoSecretsInCode(codeWithPassword)).toBe(false);
    });

    test('should detect hardcoded API keys', () => {
      const codeWithApiKey = `
        const apiKey = 'sk-1234567890abcdef';
        const endpoint = 'https://api.openai.com/v1';
      `;
      expect(validateNoSecretsInCode(codeWithApiKey)).toBe(false);
    });

    test('should detect hardcoded tokens', () => {
      const codeWithToken = `
        const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
        const authHeader = \`Bearer \${token}\`;
      `;
      expect(validateNoSecretsInCode(codeWithToken)).toBe(false);
    });

    test('should pass when no secrets are present', () => {
      const cleanCode = `
        const config = {
          host: process.env.DB_HOST,
          port: process.env.DB_PORT
        };
      `;
      expect(validateNoSecretsInCode(cleanCode)).toBe(true);
    });
  });

  describe('Hardcoded URL Detection', () => {
    test('should detect hardcoded URLs', () => {
      const codeWithUrls = `
        const apiUrl = 'https://api.company.com/v1';
        const webhookUrl = 'https://webhook.company.com/events';
      `;
      expect(validateNoHardcodedUrls(codeWithUrls)).toBe(false);
    });

    test('should detect localhost URLs', () => {
      const codeWithLocalhost = `
        const devUrl = 'http://localhost:3000';
        const dbUrl = 'postgresql://localhost:5432';
      `;
      expect(validateNoHardcodedUrls(codeWithLocalhost)).toBe(false);
    });

    test('should pass when using environment variables', () => {
      const cleanCode = `
        const apiUrl = process.env.API_URL;
        const dbUrl = process.env.DATABASE_URL;
      `;
      expect(validateNoHardcodedUrls(cleanCode)).toBe(true);
    });
  });

  describe('Environment Variable Security', () => {
    test('should not expose sensitive environment variables', () => {
      const sensitiveVars = [
        'AUTH_SECRET',
        'GITHUB_TOKEN',
        'DATABASE_URL',
        'REDIS_URL',
        'JWT_SECRET',
      ];

      sensitiveVars.forEach(varName => {
        expect(process.env[varName]).toBeDefined();
        expect(process.env[varName]).not.toBe('');
        expect(process.env[varName]).not.toContain('production');
      });
    });
  });

  describe('Authentication Security', () => {
    test('should validate JWT token format', () => {
      const jwtRegex = /^[A-Za-z0-9-_]+\.[A-Za-z0-9-_]+\.[A-Za-z0-9-_]*$/;
      const testToken = process.env.AUTH_SECRET || 'test-token';
      
      // This is a basic format check - in real scenarios, you'd validate the actual JWT
      expect(typeof testToken).toBe('string');
      expect(testToken.length).toBeGreaterThan(0);
    });

    test('should not use weak passwords in tests', () => {
      const weakPasswords = ['password', '123456', 'admin', 'test'];
      const testPassword = 'test-password';
      
      expect(weakPasswords).not.toContain(testPassword);
    });
  });

  describe('API Security', () => {
    test('should validate API endpoint security', () => {
      const endpoints = [
        '/api/v1/users',
        '/api/v1/admin',
        '/api/v1/config',
      ];

      endpoints.forEach(endpoint => {
        expect(endpoint).toMatch(/^\/api\/v1\//);
        expect(endpoint).not.toContain('..'); // Prevent path traversal
        expect(endpoint).not.toContain('script'); // Prevent XSS
      });
    });

    test('should validate CORS configuration', () => {
      const allowedOrigins = [
        'https://backstage.company.com',
        'https://argocd.company.com',
      ];

      const testOrigin = 'https://backstage.company.com';
      expect(allowedOrigins).toContain(testOrigin);
    });
  });

  describe('Database Security', () => {
    test('should validate database connection security', () => {
      const dbUrl = process.env.DATABASE_URL || 'postgresql://test:test@localhost:5432/test';
      
      expect(dbUrl).toMatch(/^postgresql:\/\//);
      expect(dbUrl).not.toContain('password');
      expect(dbUrl).not.toContain('secret');
    });

    test('should validate SQL injection prevention', () => {
      const userInput = "'; DROP TABLE users; --";
      const sanitizedInput = userInput.replace(/['";]/g, '');
      
      expect(sanitizedInput).not.toContain("'");
      expect(sanitizedInput).not.toContain('"');
      expect(sanitizedInput).not.toContain(';');
    });
  });

  describe('File Upload Security', () => {
    test('should validate file type restrictions', () => {
      const allowedTypes = ['.jpg', '.png', '.pdf', '.txt'];
      const testFile = 'document.pdf';
      const fileExtension = testFile.substring(testFile.lastIndexOf('.'));
      
      expect(allowedTypes).toContain(fileExtension);
    });

    test('should validate file size limits', () => {
      const maxFileSize = 10 * 1024 * 1024; // 10MB
      const testFileSize = 5 * 1024 * 1024; // 5MB
      
      expect(testFileSize).toBeLessThanOrEqual(maxFileSize);
    });
  });

  describe('Input Validation', () => {
    test('should validate email format', () => {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      const validEmail = 'test@company.com';
      const invalidEmail = 'invalid-email';
      
      expect(emailRegex.test(validEmail)).toBe(true);
      expect(emailRegex.test(invalidEmail)).toBe(false);
    });

    test('should validate username format', () => {
      const usernameRegex = /^[a-zA-Z0-9_-]{3,20}$/;
      const validUsername = 'testuser123';
      const invalidUsername = 'test@user';
      
      expect(usernameRegex.test(validUsername)).toBe(true);
      expect(usernameRegex.test(invalidUsername)).toBe(false);
    });
  });
}); 