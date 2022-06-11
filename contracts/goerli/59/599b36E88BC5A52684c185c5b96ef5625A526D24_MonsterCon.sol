// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MonsterCon {
    uint256 public totalFed = 0;
    mapping(address => uint256) public addressToAmountFed;

    function feed() external payable {
        require(msg.value > 0, "Monster hungry...need food..");
        totalFed += msg.value;
        addressToAmountFed[msg.sender] += msg.value;
    }
}