// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


contract Testooor {
    uint public price = 0.001 ether;
    bytes32 public data;
    mapping(address => uint256) public balance;

    function smolmintooor() external payable {
        require(msg.value == price);
        balance[msg.sender] = balance[msg.sender]++;
    }

    function mintooor(uint _amount) external payable {
        require(msg.value * _amount == price);
        balance[msg.sender] = _amount;
    }

    function maxMintooor(uint _amount, bytes32[] calldata _proof) external payable {
        require(msg.value * _amount == price);
        balance[msg.sender] = _amount;
        data = _proof[0];
    }
} //0x3a4826c800000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000374739cf897bd446ed1aa6e0b900b4414fe6e3c81fb806fa2334c56922f0fce9074739cf897bd446ed1aa6e0b900b4414fe6e3c81fb806fa2334c56922f0fce9074739cf897bd446ed1aa6e0b900b4414fe6e3c81fb806fa2334c56922f0fce90