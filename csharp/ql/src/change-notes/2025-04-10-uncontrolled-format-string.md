---
category: minorAnalysis
---
* The precision of the query `cs/uncontrolled-format-string` has been improved (false negative reduction). Calls to `System.Text.CompositeFormat.Parse` are now considered a format like method call.
