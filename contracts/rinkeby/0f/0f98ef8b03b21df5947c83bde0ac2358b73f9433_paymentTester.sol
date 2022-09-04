/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract paymentTester{
    mapping (address => uint) public getDeposit;

    function deposit() public payable{
        getDeposit[msg.sender] += msg.value;
    }
    
    function withdraw(uint256 amount) public{
        address payable _to = payable(msg.sender);
        require((getDeposit[msg.sender] - amount) >= 0);
        _to.transfer(amount);
        getDeposit[msg.sender] -= amount;
    }

    function gift(uint256 amount, address receiver) public{
        require((getDeposit[msg.sender] - amount) >= 0);
        getDeposit[msg.sender] -= amount;
        getDeposit[receiver] += amount;
    }
}