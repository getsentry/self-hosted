import * as Sentry from "@sentry/node";

Sentry.captureFeedback({
    message: "I love your startup!",
    name: "John Doe",
    email: "john@example.com",
    url: "https://example.com",
});


Sentry.flush(5000);
