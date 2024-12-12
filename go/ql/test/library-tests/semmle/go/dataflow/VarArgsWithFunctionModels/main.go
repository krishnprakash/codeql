package main

import (
	"github.com/nonexistent/test"
)

func source() string {
	return "untrusted data"
}

func sink(any) {
}

func main() {
	s := source()
	sink(test.FunctionWithParameter(s)) // $ hasValueFlow="call to FunctionWithParameter"

	stringSlice := []string{source()}
	sink(stringSlice[0]) // $ hasValueFlow="index expression"

	s0 := ""
	s1 := source()
	sSlice := []string{s0, s1}
	sink(test.FunctionWithParameter(sSlice[1]))           // $ hasValueFlow="call to FunctionWithParameter"
	sink(test.FunctionWithSliceParameter(sSlice))         // $ hasTaintFlow="call to FunctionWithSliceParameter" MISSING: hasValueFlow="call to FunctionWithSliceParameter"
	sink(test.FunctionWithVarArgsParameter(sSlice...))    // $ hasTaintFlow="call to FunctionWithVarArgsParameter" MISSING: hasValueFlow="call to FunctionWithVarArgsParameter"
	randomFunctionWithMoreThanOneParameter(1, 2, 3, 4, 5) // This is needed to make the next line pass, because we need to have seen a call to a function with at least 2 parameters for ParameterInput to exist with index 1.
	sink(test.FunctionWithVarArgsParameter(s0, s1))       // $ hasValueFlow="call to FunctionWithVarArgsParameter"

	var out1 *string
	var out2 *string
	test.FunctionWithVarArgsOutParameter(source(), out1, out2)
	sink(out1) // $ hasValueFlow="out1"
	sink(out2) // $ hasValueFlow="out2"

	sliceOfStructs := []test.A{{Field: source()}}
	sink(sliceOfStructs[0].Field) // $ hasValueFlow="selection of Field"

	// The following tests all fail because FunctionModel doesn't interact with access paths
	a0 := test.A{Field: ""}
	a1 := test.A{Field: source()}
	aSlice := []test.A{a0, a1}
	sink(test.FunctionWithSliceOfStructsParameter(aSlice))      // $ MISSING: hasValueFlow="call to FunctionWithSliceOfStructsParameter"
	sink(test.FunctionWithVarArgsOfStructsParameter(aSlice...)) // $ MISSING: hasValueFlow="call to FunctionWithVarArgsOfStructsParameter"
	sink(test.FunctionWithVarArgsOfStructsParameter(a0, a1))    // $ MISSING: hasValueFlow="call to FunctionWithVarArgsOfStructsParameter"
}

func randomFunctionWithMoreThanOneParameter(i1, i2, i3, i4, i5 int) {
}
