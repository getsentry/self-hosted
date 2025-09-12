import * as Sentry from "@sentry/node";

Sentry.init({
    dsn: process.env.SENTRY_DSN,
    sampleRate: 1.0,
    tracesSampleRate: 1.0,
    enableLogs: true,
    profileLifecycle: "manual",
    sendClientReports: true,
    sendDefaultPii: true,
    debug: true,
});
