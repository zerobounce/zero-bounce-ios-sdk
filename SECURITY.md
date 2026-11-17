# Security Policy

## Reporting a Vulnerability

If you think you've found a security issue, please report it privately instead of opening a public issue.

**Email:** integrations@zerobounce.net (use a subject like `[zero-bounce-ios-sdk] Security`).

We'll look into reports as we can. If the issue is in the Zero Bounce API or service rather than this SDK, we may forward it to the right team.

## Supported Versions

We focus on the current release line for fixes. Using the latest release is recommended.

## Tips for Using This SDK

* Don't commit API keys or `.env` files—use environment variables or a secrets manager.
* Keep dependencies up to date and upgrade when new versions are released.
* The client uses HTTPS by default and refuses a base URL that is not `https://` (an `http://` URL to a loopback host, for local test stubs, is the only exception); a refused call fails before anything is sent.

Thanks for helping keep things secure.
