// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Test {
	uint[] intArray;

	function getLength() public view returns(uint) {
		return intArray.length;
	}

	function setArray(uint[] memory newIntArray) public {
		intArray = newIntArray;
	}

	function max(uint lhs, uint rhs) public pure returns(uint) {
		return lhs > rhs ? lhs : rhs;
	}
}