// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Number {
    event NumberUpdate(address indexed userAddress, uint256 number);

    mapping(address => uint256) public numbers;

    function update(uint256 number) public {
        numbers[msg.sender] = number;
        emit NumberUpdate(msg.sender, number);
    }
}