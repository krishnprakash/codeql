overlay[local?]
module;

import default
import semmle.code.java.deadcode.DeadCode
import external.ExternalArtifact

/**
 * A method in a FIT fixture class, typically used in the fitnesse framework.
 */
class FitFixtureEntryPoint extends CallableEntryPoint {
  FitFixtureEntryPoint() {
    this.getDeclaringType().getAnAncestor().hasQualifiedName("fit", "Fixture")
  }
}

/**
 * FitNesse entry points externally defined.
 */
class FitNesseSlimEntryPointData extends ExternalData {
  FitNesseSlimEntryPointData() { this.getDataPath() = "fitnesse.csv" }

  /**
   * Gets the class name.
   *
   * This may be a fully qualified name, or just the name of the class. It may also be, or
   * include, a FitNesse symbol, in which case it can be ignored.
   */
  string getClassName() { result = this.getField(0) }

  /**
   * Gets a Class that either has `getClassName()` as the fully qualified name, or as the class name.
   */
  Class getACandidateClass() {
    result.getQualifiedName().matches(this.getClassName()) or
    result.getName() = this.getClassName()
  }

  /**
   * Gets the name of the callable that will be called.
   */
  string getCallableName() { result = this.getField(1) }

  /**
   * Gets the number of parameters for the callable that will be called.
   */
  int getNumParameters() { result = this.getField(2).toInt() }

  /**
   * Gets a callable on one of the candidate classes that matches the criteria for the method name
   * and number of arguments.
   */
  Callable getACandidateCallable() {
    result.getDeclaringType() = this.getACandidateClass() and
    result.getName() = this.getCallableName() and
    result.getNumberOfParameters() = this.getNumParameters()
  }
}

/**
 * A callable that is a candidate for being called by a processed Slim FitNesse test. This entry
 * point requires that the FitNesse tests are processed by the fitnesse-liveness-processor, and
 * the resulting CSV file is included in the snapshots external data.
 */
class FitNesseSlimEntryPoint extends EntryPoint {
  FitNesseSlimEntryPoint() {
    exists(FitNesseSlimEntryPointData entryPointData |
      this = entryPointData.getACandidateCallable() and
      this.(Callable).fromSource()
    )
  }

  override Callable getALiveCallable() { result = this }
}
