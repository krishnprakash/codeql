import go
import semmle.go.security.OpenUrlRedirectCustomizations
import utils.test.InlineExpectationsTest

module FasthttpTest implements TestSig {
  string getARelevantTag() { result = "OpenRedirect" }

  predicate hasActualResult(Location location, string element, string tag, string value) {
    exists(OpenUrlRedirect::Sink s |
      s.getLocation() = location and
      element = s.toString() and
      value = s.toString() and
      tag = "OpenRedirect"
    )
  }
}

import MakeTest<FasthttpTest>
