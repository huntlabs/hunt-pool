import std.stdio;

import hunt.util.UnitTest;

import test.PoolTest;

import test.impl.TestLinkedBlockingDeque;

void main() {
	// testUnits!(PoolTest);
	testUnits!(TestLinkedBlockingDeque);
}
