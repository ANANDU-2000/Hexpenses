import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

export type ApiErrorBody = {
  success: false;
  message: string;
  error?: unknown;
};

function normalizeHttpExceptionResponse(
  status: number,
  response: string | object,
): ApiErrorBody {
  if (typeof response === 'string') {
    return { success: false, message: response };
  }

  const r = response as Record<string, unknown>;
  const msg = r['message'];

  if (Array.isArray(msg)) {
    const lines = msg.map((x) => String(x)).filter(Boolean);
    return {
      success: false,
      message: lines.length ? lines[0] : 'Bad Request',
      ...(lines.length > 0 ? { error: lines } : {}),
    };
  }

  if (typeof msg === 'string') {
    const err = r['error'];
    return {
      success: false,
      message: msg,
      ...(err !== undefined ? { error: err } : {}),
    };
  }

  const fallback =
    status === HttpStatus.UNAUTHORIZED
      ? 'Unauthorized'
      : status === HttpStatus.FORBIDDEN
        ? 'Forbidden'
        : status === HttpStatus.NOT_FOUND
          ? 'Not Found'
          : 'Request failed';

  const { message: _m, statusCode: _s, error: _e, ...rest } = r;
  const extra = Object.keys(rest).length ? rest : undefined;

  return {
    success: false,
    message: fallback,
    ...(extra ? { error: extra } : {}),
  };
}

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException ? exception.getStatus() : HttpStatus.INTERNAL_SERVER_ERROR;

    let body: ApiErrorBody;

    if (exception instanceof HttpException) {
      body = normalizeHttpExceptionResponse(status, exception.getResponse());
    } else {
      const isProd = process.env.NODE_ENV === 'production';
      const errMsg = exception instanceof Error ? exception.message : 'Internal server error';
      body = {
        success: false,
        message: isProd ? 'Internal server error' : errMsg,
        ...(!isProd && exception instanceof Error
          ? {
              error: {
                name: exception.name,
                message: exception.message,
              },
            }
          : {}),
      };
    }

    if (status >= 500) {
      this.logger.error(
        `${req.method} ${req.url} ${status}`,
        exception instanceof Error ? exception.stack : String(exception),
      );
    }

    res.status(status).json(body);
  }
}
