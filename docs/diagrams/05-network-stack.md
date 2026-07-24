# 05 · Network stack & error model

**Type:** sequence — request → interceptor chain → PostgREST → typed error back.
**Source:** [technical-summary §7](../technical-summary.md) · [dio_client.dart](../../lib/core/network/dio_client.dart)

Dio runs interceptors in **FIFO (list) order for every hook** — requests *and*
errors (verified in dio 5.9.2 source, `dio_mixin.dart`). List order here:
`TalkerDioLogger → ErrorMappingInterceptor → AuthInterceptor`.

```mermaid
sequenceDiagram
    autonumber
    participant Caller as caller · SupabaseCommandSender (04)
    participant Log as TalkerDioLogger
    participant Map as ErrorMappingInterceptor
    participant Auth as AuthInterceptor
    participant API as Supabase PostgREST

    Note over Caller,API: — request path · FIFO —
    Caller->>Log: dio.post('/rest/v1/…', data)
    Log->>Map: onRequest · logs the request
    Map->>Auth: pass-through (no onRequest)
    Auth->>API: attach Authorization: Bearer token → HTTPS POST
    Note right of API: TLS enforced · no cert pinning (ADR-004) ·<br/>NSC bans plain HTTP · timeouts 10s

    alt 2xx
        API-->>Caller: Response
    else error path · FIFO again: Log → Map → Auth
        API--)Log: DioException
        Log->>Map: onError · logs it raw
        Map->>Auth: err.copyWith(error: AppError) · typed before auth sees it
        Note right of Map: DioException → sealed AppError:<br/>timeout/no-conn → NetworkError · 401 → AuthError ·<br/>4xx → ValidationError · 5xx/rest → UnknownError ·<br/>backend errorCode overrides via mapCustomErrorCode

        alt 401 · not yet retried — built, never faced live (NoAuthTokenProvider)
            Auth->>Auth: refresh lock — first 401 calls refreshToken(),<br/>the rest await one shared Completer (QueuedInterceptorsWrapper)
            opt refresh succeeded
                Auth->>API: _dio.fetch(retryOptions) · extra['retried'] = true → full chain re-runs
                API-->>Caller: retry response resolves the original call
            end
            Auth--)Caller: refresh failed → original error flows out
        else not a 401 · or already retried once (the loop guard)
            Auth--)Caller: handler.next → DioException with AppError inside
        end
    end

    Note over Caller: two consumers, two error families:<br/>repos → safeApiCall → Result: Success | Failure(AppError) — exceptions never leak ·<br/>the sync sender ignores AppError and classifies raw status → SendFailure (04)
```

**Reading it**

- **FIFO is the subtle fact.** The mapper decorates the error *before* the auth
  interceptor handles it — auth reads the raw `statusCode`, so the dance still
  works, but the order is mapper-then-auth, not the reverse.
- **The 401 dance has two guards:** the refresh *lock* (ten 401s → one refresh, the
  rest wait) and the retry *marker* (`extra['retried']` — a second 401 means the
  token isn't the problem, give up). Unit-tested, but auth isn't wired yet.
- **Two error families by consumer:** the repo path wants "which `AppError` is it?"
  (`Result`, exhaustive `switch`); the sync path wants "does this count toward the
  retry ceiling?" (`SendFailure`) — same client, different questions.

**Seams:** the caller and what it does with `SendFailure` → `04-sync-outbox` ·
"online" is a hint, not a promise the server answers → `06-connectivity`.
