/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.6.0 <0.9.0;

contract SafePayable
{
	address payable public owner;

	constructor() payable
	{
		owner = payable(msg.sender); //senders address who initiates contract will be payable
	}

	function deposit() public payable {} //anyone can pay to here

	function withdraw() public
	{
		require(msg.sender == owner, "Caller is not sender/contract owner");
		uint amount = address(this).balance; //withdraws the ENTIRE amount from the current contract balance
		(bool success, ) = owner.call{value: amount}("");
		require(success, "Failed to withdraw, caller is not sender/contract owner!");
	}

	function ownerOnlyTransfer(address payable reciever, uint amount) public //can only be called by contract owner! 
	{
		require(msg.sender == owner, "Caller is not sender/contract owner"); 
		(bool success, ) = reciever.call{value: amount}("");
                require(success, "Failed to Send!");
	}
}