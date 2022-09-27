//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract
{
	address public owner;
	bytes32 public role;

	struct Pradeep{
		uint256 id;
		uint256 age;
	}
	
	Pradeep public data;

	constructor(address _owner, bytes32 _role, Pradeep memory x)
	{
		owner = _owner;
		role = _role;
		data = x;
	}
	
	

}