// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Address.sol";

contract Mining is Address{ 
 

    mapping(address => uint) balanceGHs;

    function deposit() external payable {
        balanceGHs[msg.sender] += msg.value;
    }

    function withdraw(uint _amount, address payable _to) external {
        require(balanceGHs[msg.sender] >= _amount, "You don't have enough money!");

        balanceGHs[msg.sender] -= _amount;
        _to.transfer(_amount);
    }

    function getBalance() external view returns(uint){
        return balanceGHs[msg.sender];
    }

}