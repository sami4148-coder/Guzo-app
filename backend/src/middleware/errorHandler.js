import { AppError } from '../utils/errors.js';

export const notFoundHandler = (req, res) => {
  res.status(404).json({
    success: false,
    error: { message: `Route ${req.method} ${req.path} not found`, code: 'NOT_FOUND' },
  });
};

export const errorHandler = (err, _req, res, _next) => {
  if (err instanceof AppError) {
    return res.status(err.status).json({
      success: false,
      error: { message: err.message, code: err.code },
    });
  }
  if (err.name === 'ZodError') {
    return res.status(400).json({
      success: false,
      error: { message: 'Validation failed', code: 'VALIDATION_ERROR', details: err.issues },
    });
  }
  console.error('[Unhandled]', err);
  res.status(500).json({
    success: false,
    error: { message: 'Internal server error', code: 'INTERNAL_ERROR' },
  });
};