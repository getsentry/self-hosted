## Testing

Validate changes to the setup by running the integration test:

```shell
./integration-test.sh
```

**What To Fix?**

Environment
self-hosted (https://develop.sentry.dev/self-hosted/)

What are you trying to accomplish?
I set up Sentry for our frontend app and our backend app recently. While reading some Sentry docs I realized that the docs suggest using the same DSN for both apps.

I have already created two separate Sentry projects and set them up individually.

This is still early enough that I can make the change. It would also make it easier to use Sentry rather than keep having to switch projects.

How are you getting stuck?
Should I change this so that both the Angular front end and the ASP.NET Core web api backend share the same DSN?

Are there any benefits to combining? Any benefits to separating them?

Does distributed tracing work even if the two projects are separate?

Where in the product are you?
Other

Link
No response

DSN
No response

Version
23.11.0.dev0

**Solution**
**Sentry Project Configuration Options**
**1. Single Sentry Project for Both Frontend and Backend Apps**

**Advantages:**
**Simplified Setup:** Configure both frontend and backend applications to use the same Sentry project and DSN for consolidated error tracking.
Unified Error Monitoring: Easily monitor and manage errors from both apps in one location.
**Ease of Correlation:** Simplified tracing of issues across the entire application stack.

**Considerations:**
**Limited Isolation:** Frontend and backend errors are mixed, potentially making it harder to isolate specific issues.
**Potential Clutter: **Managing a large volume of errors might complicate the differentiation between frontend and backend issues.

**2. Two Separate Sentry Projects for Frontend and Backend**

**Advantages:**
**Isolated Error Tracking:** Independent projects for frontend and backend provide clear insights into respective app issues.
**Granular Monitoring:** Focus on each app's errors independently for precise debugging.

**Considerations:**
**Complex Configuration:** Requires setting up and managing two separate projects, potentially increasing maintenance overhead.
**Correlation Challenges:** Manually correlating frontend and backend errors without a unified view might require additional effort.

**Distributed Tracing Consideration**
**In a Single Project:** Distributed tracing is more seamless within a single project, enabling easier correlation of traces with errors across the entire application.
**Across Separate Projects:** Distributed tracing functionalities might have limitations when working across separate projects, potentially hindering the correlation of traces with errors.

**Recommendation**
Consider the following when choosing Sentry project configuration:
**Simplicity and Consolidation:** Use a single Sentry project for easy correlation and centralized tracking if seamless integration and correlation between frontend and backend errors are crucial.
**Granularity and Isolation:** Opt for two separate Sentry projects for distinct tracking and clearer isolation of frontend and backend issues if independent monitoring is a priority.
