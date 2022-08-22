/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/*
VERSION DATE: 22/08/2022
*/

contract Access 
{
	address public owner;

	mapping(address => uint) public admins;
	
	event AddAdmin(address user, uint amount);
	event RemoveAdmin(address user);
	
	modifier onlyOwner
	{
        require(msg.sender == owner, "wrong owner");
        _;
    }

	constructor() 
	{
		owner = msg.sender;
    }
	
    function changeOwner(address newOwner) public onlyOwner
	{
		require(newOwner != address(0), "wrong address");
		require(newOwner != owner, "wrong address");

        owner = newOwner;
    }
	
    function addAdmin(address addr, uint amount) public onlyOwner
	{
		require(addr != address(0));

		admins[addr] = admins[addr] + amount;

		emit AddAdmin(addr, amount);
    }

    function removeAdmin(address addr) public onlyOwner
	{
		require(admins[addr] > 0, "admin does not exists");
		
		delete admins[addr];
		
		emit RemoveAdmin(addr);
    }
	
	function isAdmin(address addr) public view returns (uint)
	{
		return( admins[addr] );
    }
}

contract SysWallet is Access
{
	event Payin(address user, uint amount);
	event Withdraw(address user, uint amount);
	
	function payin() public payable
	{
		require(msg.value > 0, "wrong value" );

        emit Payin(msg.sender, msg.value);
	}

	function withdraw(uint amount) public
	{
		require( amount > 0 && amount <= address(this).balance, "wrong amount" );

		require( admins[msg.sender] >= amount, "wrong admin" );
		admins[msg.sender] = admins[msg.sender] - amount;
		
		payable(msg.sender).transfer(amount);
		
		emit Withdraw(msg.sender, amount);
	}
	
	function getBalance() public view returns (uint)
	{
		return( address(this).balance );
	}

}