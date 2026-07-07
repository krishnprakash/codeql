---
category: minorAnalysis
---
* The `uri` method of Spring's reactive `WebClient` is now considered a request forgery sink. Previously only the `create` and `baseUrl` methods were considered. This may lead to more alerts for the query `java/ssrf` (Server-side request forgery).
