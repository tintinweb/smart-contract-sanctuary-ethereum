// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract MYICO {

    uint256 public price = 100;

    mapping(address => uint256) public balanceOf;

    function buyTokens(uint256 amount) public payable {
        require(msg.value == amount * price);
        balanceOf[msg.sender] += amount;
    }

    function sellTokens(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        payable(msg.sender).transfer(amount * price);
    }
}