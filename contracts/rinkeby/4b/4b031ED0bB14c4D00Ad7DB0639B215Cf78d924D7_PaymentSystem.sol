/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// File: contracts/payment.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract PaymentSystem {
	struct User{
		string nickname;
		uint regTime;
		uint256 subscription;
	}
	mapping(address => User) public users;
	uint expiraion = 300;
	uint price = 10000000000000000;

	address public  Owner;
	address public  contractAdrr ;
	constructor() {
		Owner = msg.sender;
		contractAdrr = address(this);
	}

	function balanceOf() public view returns(uint){
		return address(this).balance ;
	}
	function isActive() public view returns(bool) {
		if (users[msg.sender].subscription > block.timestamp){
			return true;
		}
		return false;
	}
	function subEnd() public view returns(uint256) {
		require(isActive(),"inactive");

		return users[msg.sender].subscription;
	}
	function createUser(string memory _nickname) public {
		require(users[msg.sender].subscription == 0 ,"User exist");
		users[msg.sender].regTime = block.timestamp;
		users[msg.sender].nickname = _nickname;

	}
	function getUser( ) public view  returns( string memory){
		return users[msg.sender].nickname;

	}
	function setSubTime(uint _expiraion) public  {
		require(msg.sender == Owner,"u are not avaible to set vars");
		expiraion = _expiraion;

	}
	function setSubPay(uint _price) public  {
		require(msg.sender == Owner,"u are not avaible to set vars");
		price = _price;
	}

	function paySub() public payable {
		require(msg.value == price ,"Uncorrect price");


		if (users[msg.sender].subscription > block.timestamp){
			users[msg.sender].subscription += expiraion;
		} else{
			users[msg.sender].subscription = block.timestamp + expiraion;
		}

	}

	function windraw() public payable {
		(bool sent, ) = Owner.call{value:address(this).balance }("");
		require(sent, "Failed to send Ether");
	}


}