// generated by codegen, do not edit
/**
 * This module provides the generated definition of `SelfParam`.
 * INTERNAL: Do not import directly.
 */

private import codeql.rust.elements.internal.generated.Synth
private import codeql.rust.elements.internal.generated.Raw
import codeql.rust.elements.internal.AstNodeImpl::Impl as AstNodeImpl
import codeql.rust.elements.Attr
import codeql.rust.elements.Lifetime
import codeql.rust.elements.Name
import codeql.rust.elements.TypeRef

/**
 * INTERNAL: This module contains the fully generated definition of `SelfParam` and should not
 * be referenced directly.
 */
module Generated {
  /**
   * A SelfParam. For example:
   * ```rust
   * todo!()
   * ```
   * INTERNAL: Do not reference the `Generated::SelfParam` class directly.
   * Use the subclass `SelfParam`, where the following predicates are available.
   */
  class SelfParam extends Synth::TSelfParam, AstNodeImpl::AstNode {
    override string getAPrimaryQlClass() { result = "SelfParam" }

    /**
     * Gets the `index`th attr of this self parameter (0-based).
     */
    Attr getAttr(int index) {
      result =
        Synth::convertAttrFromRaw(Synth::convertSelfParamToRaw(this).(Raw::SelfParam).getAttr(index))
    }

    /**
     * Gets any of the attrs of this self parameter.
     */
    final Attr getAnAttr() { result = this.getAttr(_) }

    /**
     * Gets the number of attrs of this self parameter.
     */
    final int getNumberOfAttrs() { result = count(int i | exists(this.getAttr(i))) }

    /**
     * Gets the lifetime of this self parameter, if it exists.
     */
    Lifetime getLifetime() {
      result =
        Synth::convertLifetimeFromRaw(Synth::convertSelfParamToRaw(this)
              .(Raw::SelfParam)
              .getLifetime())
    }

    /**
     * Holds if `getLifetime()` exists.
     */
    final predicate hasLifetime() { exists(this.getLifetime()) }

    /**
     * Gets the name of this self parameter, if it exists.
     */
    Name getName() {
      result =
        Synth::convertNameFromRaw(Synth::convertSelfParamToRaw(this).(Raw::SelfParam).getName())
    }

    /**
     * Holds if `getName()` exists.
     */
    final predicate hasName() { exists(this.getName()) }

    /**
     * Gets the ty of this self parameter, if it exists.
     */
    TypeRef getTy() {
      result =
        Synth::convertTypeRefFromRaw(Synth::convertSelfParamToRaw(this).(Raw::SelfParam).getTy())
    }

    /**
     * Holds if `getTy()` exists.
     */
    final predicate hasTy() { exists(this.getTy()) }
  }
}
