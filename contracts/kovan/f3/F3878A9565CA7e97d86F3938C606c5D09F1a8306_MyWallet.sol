/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyWallet{
    address public owner=address(0x59355190440FEFFB17ee4bB9CDB682Ea8E5aD1F5);
    address public walletAddress;
    
    constructor(){
        walletAddress = address(this);
    }

    function getBalance() public view returns(uint){
        return walletAddress.balance;
    }

    function sendMoneyTo() public payable{

    }

    function sendMoneyFrom(uint _val) public{
        require(owner == msg.sender, "You're not an owner!");
        require(_val <= walletAddress.balance, "This wallet doesn't have enough money");
        address payable receiver = payable(owner);
        receiver.transfer(_val);
    }

}