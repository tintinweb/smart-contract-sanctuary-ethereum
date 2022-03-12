/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.22;

contract owned {

    address owner;

    constructor (){
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require (msg.sender == owner,"Only owner can call this function");
        _;
    }
}

contract mortal is owned {
    function destroy () public onlyOwner {
        selfdestruct(owner);
    }
}

contract faucet is mortal{
    event Withdrawal(address indexed to,uint amount);
    event Deposit(address indexed from,uint amount);
    function withdraw(uint withdraw_amount) public{
        require(withdraw_amount <= 1 ether);
        require(this.balance>=withdraw_amount,"banlace is no enough");
        msg.sender.transfer(withdraw_amount);
        emit Withdrawal(msg.sender,withdraw_amount);
    }

    function () public payable {
        emit Deposit(msg.sender,msg.value);
    }
    function getContactBanlance() public view returns (uint){
        return address(this).balance;
    }
   
}