---
category: minorAnalysis
---
* The query `cs/useless-tostring-call` has been updated to avoid false
  positive results in calls to `StringBuilder.AppendLine` and calls of
  the form `base.ToString()`. Moreover, the alert message has been
  made more precise.
