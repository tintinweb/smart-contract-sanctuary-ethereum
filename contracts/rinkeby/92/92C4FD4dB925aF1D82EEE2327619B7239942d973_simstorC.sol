//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract simstorC{

	uint256 count;

	function store(uint256 _num) public {
		count = _num;
	}

	function retrieve() public view returns(uint256){
		return count;
	}

}