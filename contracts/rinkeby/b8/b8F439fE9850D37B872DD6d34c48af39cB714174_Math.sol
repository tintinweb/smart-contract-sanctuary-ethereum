// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Math {
	uint constant _perc = 100;

	function extractPercentage(uint value, uint perc) public pure returns (uint) {
		return value - ((value * perc) / _perc);
	}

	function extractPart(
		uint value,
		uint values,
		uint amount
	) public pure returns (uint) {
		return (values > 0) ? (amount * value) / values : 0;
	}

	function calcValues(uint[] memory values) public pure returns (uint) {
		uint s = 0;
		for (uint i = 0; i < values.length; i++) s += values[i];
		return s;
	}
}