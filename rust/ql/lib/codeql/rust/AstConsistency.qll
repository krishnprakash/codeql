/**
 * Provides classes for recognizing control flow graph inconsistencies.
 */

private import rust
private import codeql.rust.elements.internal.generated.ParentChild

private predicate multipleToStrings(Element e) { strictcount(e.toString()) > 1 }

/**
 * Holds if `e` has more than one `toString()` result.
 */
query predicate multipleToStrings(Element e, string cls, string s) {
  multipleToStrings(e) and
  cls = e.getPrimaryQlClasses() and
  s = strictconcat(e.toString(), ", ")
}

/**
 * Holds if `e` has more than one `Location`.
 */
query predicate multipleLocations(Locatable e) { strictcount(e.getLocation()) > 1 }

/**
 * Holds if `e` does not have a `Location`.
 */
query predicate noLocation(Locatable e) { not exists(e.getLocation()) }

private predicate multiplePrimaryQlClasses(Element e) {
  strictcount(string cls | cls = e.getAPrimaryQlClass() and cls != "VariableAccess") > 1
}

/**
 * Holds if `e` has more than one `getPrimaryQlClasses()` result.
 */
query predicate multiplePrimaryQlClasses(Element e, string s) {
  multiplePrimaryQlClasses(e) and
  s = strictconcat(e.getPrimaryQlClasses(), ", ")
}

private Element getParent(Element child) { child = getChildAndAccessor(result, _, _) }

private predicate multipleParents(Element child) { strictcount(getParent(child)) > 1 }

/**
 * Holds if `child` has more than one AST parent.
 */
query predicate multipleParents(Element child, string childClass, Element parent, string parentClass) {
  multipleParents(child) and
  childClass = child.getPrimaryQlClasses() and
  parent = getParent(child) and
  parentClass = parent.getPrimaryQlClasses()
}

/**
 * Gets counts of abstract syntax tree inconsistencies of each type.
 */
int getAstInconsistencyCounts(string type) {
  // total results from all the AST consistency query predicates.
  type = "Multiple toStrings" and
  result = count(Element e | multipleToStrings(e) | e)
  or
  type = "Multiple locations" and
  result = count(Element e | multipleLocations(e) | e)
  or
  type = "No location" and
  result = count(Element e | noLocation(e) | e)
  or
  type = "Multiple primary QL classes" and
  result = count(Element e | multiplePrimaryQlClasses(e) | e)
  or
  type = "Multiple parents" and
  result = count(Element e | multipleParents(e) | e)
}
