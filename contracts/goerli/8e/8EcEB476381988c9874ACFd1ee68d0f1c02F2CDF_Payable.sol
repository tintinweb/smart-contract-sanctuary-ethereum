/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0 <0.9.0;

contract Payable
{
	address payable public owner;

	constructor() payable
	{
		owner = payable(msg.sender); //senders address who initiates contract will be payable
	}

	function deposit() public payable {}

	function withdraw() public
	{
		require(msg.sender == owner, "Caller is not sender/contract owner");
		uint amount = address(this).balance; //withdraws the ENTIRE amount from the current contract
		(bool success, ) = owner.call{value: amount}("");
		require(success, "Failed to withdraw, caller is not sender/contract owner!");
	}

	function transfer(address payable reciever, uint amount) public //can be called by ANYONE!!
	{
		(bool success, ) = reciever.call{value: amount}("");
		require(success, "Failed to Send!");
	}

	function ownerOnlyTransfer(address payable reciever, uint amount) public
	{
		require(msg.sender == owner, "Caller is not sender/contract owner"); 
		(bool success, ) = reciever.call{value: amount}("");
                require(success, "Failed to Send!");
	}
	
}