/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract paymentTester{
    mapping (address => uint) public payments;

    function getBalance(address addy) public view returns(uint){
        return addy.balance;
    }
    function send() public payable{
        payments[msg.sender] += msg.value;
    }
    
    function sendBack(address target, uint256 amount) public{
        address payable _to = payable(target);
        require(payments[target] - amount*10**18 >= 0 && msg.sender == target);
        _to.transfer(amount*10**18);
        payments[msg.sender] -= amount*10**18;
    }
}