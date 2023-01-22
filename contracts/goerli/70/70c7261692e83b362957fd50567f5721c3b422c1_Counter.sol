// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;
    event Log(address indexed sender, address indexed receiver, uint256 amount);

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function Transfer(address _from, address _to, uint256 _value) public {
        emit Log(_from, _to, _value);
    }
}