import cpp
import codeql.util.ReportStats

module CallTargetStats implements StatsSig {
  private class RelevantCall extends Call {
    RelevantCall() { this.getFile() = any(File f | f.fromSource() and exists(f.getRelativePath())) }
  }

  // We assume that calls with an implicit target are calls that could not be
  // resolved. This is accurate in the vast majority of cases, but is inaccurate
  // for calls that deliberately rely on implicitly declared functions.
  private predicate hasImplicitTarget(RelevantCall call) {
    call.getTarget().getADeclarationEntry().isImplicit()
  }

  int getNumberOfOk() { result = count(RelevantCall call | not hasImplicitTarget(call)) }

  int getNumberOfNotOk() { result = count(RelevantCall call | hasImplicitTarget(call)) }

  string getOkText() { result = "calls with call target" }

  string getNotOkText() { result = "calls with missing call target" }
}

module CallTargetStatsReport = ReportStats<CallTargetStats>;
