/**
 * Provides classes for reasoning about lexically scoped variables and references to these.
 */

private import unified
private import unified as U
private import codeql.namebinding.LocalNameBinding

private module LocalNameBindingInput implements LocalNameBindingInputSig<Location> {
  class AstNode = U::AstNode;

  private class LogicalAndRoot extends LogicalAndExpr {
    LogicalAndRoot() { not this = any(LogicalAndExpr e).getAnOperand() }

    private Expr getDescendent(string path) {
      path = "" and result = this
      or
      exists(LogicalAndExpr mid, string midPath | mid = this.getDescendent(midPath) |
        result = mid.getLeft() and path = midPath + "A"
        or
        result = mid.getRight() and path = midPath + "B"
      )
    }

    Expr getNthLeaf(int n) {
      result =
        rank[n](Expr e, string path |
          e = this.getDescendent(path) and not e instanceof LogicalAndExpr
        |
          e order by path
        )
    }

    Expr getLastLeaf() { result = max(int n | | this.getNthLeaf(n) order by n) }
  }

  private AstNode getChild1(AstNode n, int index) {
    result = n.(Block).getStmt(index)
    or
    result = n.(LogicalAndRoot).getNthLeaf(index)
    or
    exists(PatternGuardExpr guard | n = guard |
      index = 0 and result = guard.getPattern()
      or
      index = 1 and result = guard.getValue()
    )
    or
    exists(IfExpr expr | n = expr |
      index = 0 and result = expr.getCondition()
      or
      index = 1 and result = expr.getThen()
      or
      index = 2 and result = expr.getElse()
    )
    or
    exists(VariableDeclaration decl | n = decl |
      index = 0 and result = decl.getPattern()
      or
      index = 1 and result = decl.getType()
      or
      index = 2 and result = decl.getValue()
    )
  }

  AstNode getChild(AstNode n, int index) {
    result = getChild1(n, index)
    or
    not exists(getChild1(n, _)) and
    not n instanceof LogicalAndExpr and // also ignore intermediate nodes within a 'logical and' tree
    index = 0 and
    result = n.getAFieldOrChild()
  }

  abstract class Conditional extends AstNode {
    /** Gets the condition of this conditional. */
    abstract AstNode getCondition();

    /** Gets the then-branch of this conditional. */
    abstract AstNode getThen();

    /** Gets the else-branch of this conditional. */
    abstract AstNode getElse();
  }

  private class IfExprConditional extends Conditional instanceof IfExpr {
    override AstNode getCondition() { result = IfExpr.super.getCondition() }

    override AstNode getThen() { result = IfExpr.super.getThen() }

    override AstNode getElse() { result = IfExpr.super.getElse() }
  }

  abstract class SiblingShadowingDecl extends AstNode {
    /** Gets the left-hand side of this declaration. */
    abstract AstNode getLhs();

    /**
     * Gets the right-hand side of this declaration.
     *
     * Any local declared in the left-hand side of this declaration is _not_ in scope
     * in the right-hand side.
     */
    abstract AstNode getRhs();

    /**
     * Gets the else-branch of this declaration, if any.
     *
     * Any local declared in the left-hand side of this declaration is _not_ in scope
     * in the else-branch.
     */
    abstract AstNode getElse();
  }

  private class LocalVariableDeclarationSiblingShadowingDecl extends SiblingShadowingDecl instanceof LocalVariableDeclaration
  {
    override AstNode getLhs() { result = LocalVariableDeclaration.super.getPattern() }

    override AstNode getRhs() { result = LocalVariableDeclaration.super.getValue() }

    override AstNode getElse() { none() }
  }

  private class PatternGuardExprSiblingShadowingDecl extends SiblingShadowingDecl instanceof PatternGuardExpr
  {
    override AstNode getLhs() { result = PatternGuardExpr.super.getPattern() }

    override AstNode getRhs() { result = PatternGuardExpr.super.getValue() }

    override AstNode getElse() { none() }
  }

  private class GuardIfStmtSiblingShadowingDecl extends SiblingShadowingDecl instanceof GuardIfStmt {
    override AstNode getLhs() { result = GuardIfStmt.super.getCondition() }

    override AstNode getRhs() { none() }

    override AstNode getElse() { result = GuardIfStmt.super.getElse() }
  }

  private predicate bindingContext(AstNode pattern, AstNode scope) {
    exists(LocalVariableDeclaration decl |
      scope = decl and // LocalVariableDeclaration is a ShadowingSiblingDecl, it must use itself as the scope
      pattern = decl.getPattern()
    )
    or
    exists(LocalFunctionDeclaration func |
      scope = func.getDeclaringBlock() and
      pattern = func.getName()
    )
    or
    exists(Parameter param |
      scope = param.getParent() and // TODO: add SourceCallable and use .getParameter() instead
      pattern = param.getPattern()
    )
    or
    exists(CatchClause catch |
      scope = catch and // ensure both 'body' and 'guard' clause are in scope
      pattern = catch.getPattern()
    )
    or
    exists(SwitchCase case |
      scope = case and // ensure both 'body' and 'guard' clause are in scope (TODO: merge CatchClause and SwitchCase?)
      pattern = case.getPattern()
    )
    or
    exists(ForEachStmt stmt |
      scope = stmt and // ensure both 'body' and 'guard' are in scope
      pattern = stmt.getPattern()
    )
    or
    exists(TuplePattern pat |
      bindingContext(pat, scope) and
      pattern = pat.getElement(_).getPattern()
    )
    or
    exists(ConstructorPattern pat |
      bindingContext(pat, scope) and
      pattern = pat.getElement(_).getPattern()
    )
    or
    exists(OrPattern pat |
      bindingContext(pat, scope) and
      pattern = pat.getPattern(_)
    )
    or
    exists(PatternGuardExpr expr |
      pattern = expr.getPattern() and
      scope = expr
    )
  }

  predicate declInScope(AstNode definingNode, string name, AstNode scope) {
    bindingContext(definingNode, scope) and
    (
      definingNode.(NamePattern).getIdentifier().getValue() = name
      or
      definingNode.(Identifier).getValue() = name
    )
  }

  predicate implicitDeclInScope(string name, AstNode scope) {
    none()
    // TODO: self
  }

  predicate accessCand(AstNode n, string name) {
    n.(NameExpr).getIdentifier().getValue() = name
    or
    n.(NamePattern).getIdentifier().getValue() = name
    or
    n = any(LocalFunctionDeclaration f).getName() and
    n.(Identifier).getValue() = name
  }

  predicate lookupStartsAt(AstNode n, AstNode scope) { none() }
}

module LocalNameBindingOutput = LocalNameBinding<Location, LocalNameBindingInput>;

module Public {
  /**
   * A local variable.
   */
  class Variable extends LocalNameBindingOutput::Local {
    VariableAccess getAnAccess() { result.getVariable() = this }
  }

  /**
   * An AST node that is a reference to a local variable.
   */
  class VariableAccess extends AstNode instanceof LocalNameBindingOutput::LocalAccess {
    Variable getVariable() { result = super.getLocal() }

    Identifier getIdentifier() {
      result = this.(NameExpr).getIdentifier()
      or
      result = this.(NamePattern).getIdentifier()
      or
      result = this
    }

    string getName() { result = this.getIdentifier().getValue() }
  }
}
