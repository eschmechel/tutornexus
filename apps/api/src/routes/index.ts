import { OpenAPIHono, createRoute, z } from '@hono/zod-openapi';

import type { AppBindings } from './types';

export const api = new OpenAPIHono<AppBindings>();

// Health check route
api.openapi(
  createRoute({
    method: 'get',
    path: '/health',
    responses: {
      200: {
        description: 'Service is healthy',
        content: {
          'application/json': {
            schema: z.object({
              status: z.literal('ok'),
              timestamp: z.string().datetime(),
            }),
          },
        },
      },
    },
  }),
  (c) => {
    return c.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
    });
  }
);

// Root route
api.openapi(
  createRoute({
    method: 'get',
    path: '/',
    responses: {
      200: {
        description: 'API information',
        content: {
          'application/json': {
            schema: z.object({
              name: z.literal('Tutor Nexus API'),
              version: z.literal('0.0.0'),
              description: z.literal('Tutoring + Transfer Assistant API'),
            }),
          },
        },
      },
    },
  }),
  (c) => {
    return c.json({
      name: 'Tutor Nexus API',
      version: '0.0.0',
      description: 'Tutoring + Transfer Assistant API',
    });
  }
);
