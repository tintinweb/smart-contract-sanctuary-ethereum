pragma solidity >=0.5.0 <0.6.0;

contract Zozo {
	uint public testNumber;

	constructor(uint _testNumber) public {
        testNumber = _testNumber;
	}

	function addUpdateAndGet(uint _addNumber) public returns (uint) {
		testNumber = _addNumber;

		return testNumber + _addNumber;
	}
}