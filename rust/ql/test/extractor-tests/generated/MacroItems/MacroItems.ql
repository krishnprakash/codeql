// generated by codegen, do not edit
import codeql.rust.elements
import TestUtils

query predicate instances(MacroItems x) { toBeTested(x) and not x.isUnknown() }

query predicate getItem(MacroItems x, int index, Item getItem) {
  toBeTested(x) and not x.isUnknown() and getItem = x.getItem(index)
}
