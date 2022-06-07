// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


contract Testooor {
    uint public price = 0.001 ether;
    bytes32 public data;
    mapping(address => uint256) public balance;

    function mintooor(uint _amount) external payable {
        require(msg.value * _amount == price);
        balance[msg.sender] = _amount;
    }

    function maxMintooor(uint _amount, bytes32[] calldata _proof) external payable {
        require(msg.value * _amount == price);
        balance[msg.sender] = _amount;
        data = _proof[0];
    }
}