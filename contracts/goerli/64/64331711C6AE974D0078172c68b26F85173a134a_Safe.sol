// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Safe{
    mapping(address => uint256) public balances;

    function deposit() public payable{
        balances[msg.sender] = msg.value;
    }

    function withdraw() public {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}