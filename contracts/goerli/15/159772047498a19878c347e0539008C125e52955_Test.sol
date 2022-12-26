// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Test {
	uint[] intArray;

	function getLength() public view returns(uint) {
		return intArray.length;
	}

	function push(uint number) public {
		intArray.push(number);
	}

	//2개의 input 값을 받아 더 큰 함수를 반환시키는 함수(크기 비교 함수)
	function max(uint lhs, uint rhs) public pure returns(uint) {
		return lhs > rhs ? lhs : rhs;
	}
}