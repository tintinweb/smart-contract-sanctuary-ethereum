/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

contract transferTest {
    
	mapping (address => uint256) public BalanceOf;

	function receiveMoney() payable public {BalanceOf[msg.sender]+=msg.value;}
	
	function getBalance(address addr) public view returns(uint) {
        return BalanceOf[addr];
    }
	
	function getBalanceOfMe() public view returns(uint) {
        return BalanceOf[msg.sender];
    }

	function withdrawMoney(uint amount) public {
		require(amount<=BalanceOf[msg.sender]);
        address payable to = payable(msg.sender);
        BalanceOf[to]-=amount;
        to.transfer(amount);
    }

	function withdrawMoneyTo(address payable _to,uint amount) public {
        require(amount<=BalanceOf[msg.sender]);
		_to.transfer(amount);
		BalanceOf[msg.sender]-=amount;
		BalanceOf[_to]+=amount;
    }
}