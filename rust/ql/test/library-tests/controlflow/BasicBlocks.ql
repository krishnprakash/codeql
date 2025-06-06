import rust
import codeql.rust.controlflow.ControlFlowGraph
import codeql.rust.controlflow.BasicBlocks
import TestUtils

query predicate dominates(BasicBlock bb1, BasicBlock bb2) {
  toBeTested(bb1.getScope()) and bb1.dominates(bb2)
}

query predicate postDominance(BasicBlock bb1, BasicBlock bb2) {
  toBeTested(bb1.getScope()) and bb1.postDominates(bb2)
}

query predicate immediateDominator(BasicBlock bb1, BasicBlock bb2) {
  toBeTested(bb1.getScope()) and bb1.getImmediateDominator() = bb2
}

query predicate controls(ConditionBasicBlock bb1, BasicBlock bb2, SuccessorType t) {
  toBeTested(bb1.getScope()) and bb1.edgeDominates(bb2, t)
}

query predicate successor(ConditionBasicBlock bb1, BasicBlock bb2, SuccessorType t) {
  toBeTested(bb1.getScope()) and bb1.getASuccessor(t) = bb2
}

query predicate joinBlockPredecessor(JoinBasicBlock bb1, BasicBlock bb2, int i) {
  toBeTested(bb1.getScope()) and bb1.getJoinBlockPredecessor(i) = bb2
}
