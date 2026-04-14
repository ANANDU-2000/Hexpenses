import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { Request, Response } from 'express';

/** Maps Prisma errors to HTTP responses so clients do not only see "Internal server error". */
function mapPrismaToHttp(exception: unknown): {
  status: number;
  body: ApiErrorBody;
} | null {
  if (exception instanceof Prisma.PrismaClientKnownRequestError) {
    const code = exception.code;
    const dev = process.env.NODE_ENV !== 'production';

    if (code === 'P2002') {
      const target = (exception.meta?.target as string[] | undefined) ?? [];
      const msg =
        target.includes('email') || target.includes('phone')
          ? 'An account with this email or phone already exists.'
          : 'A record with this value already exists.';
      return {
        status: HttpStatus.CONFLICT,
        body: {
          success: false,
          message: msg,
          ...(dev ? { error: { prisma: code, target } } : {}),
        },
      };
    }

    if (code === 'P2021') {
      return {
        status: HttpStatus.SERVICE_UNAVAILABLE,
        body: {
          success: false,
          message: 'Database schema is missing. Redeploy the API or run migrations.',
          ...(dev ? { error: { prisma: code, meta: exception.meta } } : {}),
        },
      };
    }

    return {
      status: HttpStatus.BAD_REQUEST,
      body: {
        success: false,
        message: 'Request could not be completed.',
        ...(dev
          ? { error: { prisma: code, meta: exception.meta, message: exception.message } }
          : {}),
      },
    };
  }

  if (exception instanceof Prisma.PrismaClientInitializationError) {
    return {
      status: HttpStatus.SERVICE_UNAVAILABLE,
      body: {
        success: false,
        message: 'Database is unavailable. Check DATABASE_URL and server status.',
        ...(process.env.NODE_ENV !== 'production' && exception instanceof Error
          ? { error: { name: exception.name, message: exception.message } }
          : {}),
      },
    };
  }

  if (exception instanceof Prisma.PrismaClientRustPanicError) {
    return {
      status: HttpStatus.SERVICE_UNAVAILABLE,
      body: { success: false, message: 'Database engine error. Try again later.' },
    };
  }

  return null;
}

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

    const prismaMapped = mapPrismaToHttp(exception);
    let status: number;
    let body: ApiErrorBody;

    if (prismaMapped) {
      status = prismaMapped.status;
      body = prismaMapped.body;
    } else if (exception instanceof HttpException) {
      status = exception.getStatus();
      body = normalizeHttpExceptionResponse(status, exception.getResponse());
    } else {
      status = HttpStatus.INTERNAL_SERVER_ERROR;
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
    } else if (prismaMapped && exception instanceof Prisma.PrismaClientKnownRequestError) {
      this.logger.warn(`${req.method} ${req.url} ${status} prisma ${exception.code}: ${exception.message}`);
    }

    res.status(status).json(body);
  }
}
