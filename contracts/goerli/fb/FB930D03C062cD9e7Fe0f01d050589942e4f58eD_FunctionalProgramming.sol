// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AsyncFunction {
	function then(uint self, function (uint) returns (uint) f)
		internal
		returns (uint)
	{
		return f(self);
	}
	
	function then(bool self, function (bool) returns (bool) f)
		internal
		returns (bool)
	{
		return f(self);
	}
	
}

contract FunctionalProgramming {

	using AsyncFunction for *;

	uint public v;
	bool public b1;
	bool public b2;
	
	function call() public {
		v = AsyncFunction
			.then(1, incUint) // 2
			.then(doubleUint) // 4
			.then(incUint) // 5
			.then(doubleUint) // 10
			.then(decUint) // 9
			.then(doubleUint); // 18

		b1 = AsyncFunction
			.then(true, invBool); // false

		b2 = AsyncFunction
			.then(false, invBool); // true
	}
	
	function invBool(bool from) internal pure returns (bool result) {
		result = !from;
	}
	
	function incUint(uint from) internal pure returns (uint result) {
		result = from + 1;
	}
	function decUint(uint from) internal pure returns (uint result) {
		result = from - 1;
	}
	function doubleUint(uint from) internal pure returns (uint result) {
		result = from * 2;
	}
}