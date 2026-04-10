import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { SKIP_RESPONSE_ENVELOPE_KEY } from '../decorators/skip-response-envelope.decorator';

@Injectable()
export class TransformResponseInterceptor implements NestInterceptor {
  constructor(private readonly reflector: Reflector) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const skip = this.reflector.getAllAndOverride<boolean>(SKIP_RESPONSE_ENVELOPE_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    return next.handle().pipe(
      map((data) => {
        if (skip) return data;
        if (data === null || data === undefined) {
          return { success: true, data: null };
        }
        if (typeof data === 'object' && data !== null && 'success' in data) {
          return data;
        }
        return { success: true, data };
      }),
    );
  }
}
