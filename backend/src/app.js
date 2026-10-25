import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import { fileURLToPath } from 'node:url';
import { env } from './config/env.js';
import routes from './routes/index.js';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js';

const app = express();

app.use(helmet());
app.use(cors({
  origin: (origin, callback) => {
    if (!origin || env.corsOrigin.includes('*') || env.corsOrigin.includes(origin)) {
      callback(null, true);
      return;
    }

    const isLocalDevelopmentOrigin =
      env.nodeEnv !== 'production' &&
      /^https?:\/\/((localhost|127\.0\.0\.1|10\.0\.2\.2)|(?:192\.168|10\.|172\.(?:1[6-9]|2\d|3[01])|169\.254)(?:\.\d{1,3}){2})(:\d+)?$/.test(origin);
    callback(null, isLocalDevelopmentOrigin);
  },
  credentials: true,
}));
app.use(express.json({ limit: '1mb' }));
app.use(morgan('tiny'));
app.use(
  '/uploads',
  express.static(fileURLToPath(new URL('../uploads/', import.meta.url))),
);

app.use('/api', rateLimit({ windowMs: 60_000, max: 120, standardHeaders: true, legacyHeaders: false }));

app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'GUZO API' }));

app.use('/api', routes);

app.use(notFoundHandler);
app.use(errorHandler);

export default app;