/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// File: homework.sol


pragma solidity ^0.8.10;

contract Homework{
	uint x;
	function setX(uint Sx) public{
		x = Sx;
	}
	function get() public view returns (uint)
	{
		return x;
	}
}