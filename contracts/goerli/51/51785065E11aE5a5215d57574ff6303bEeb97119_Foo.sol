// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Foo {
    string public _name;
    uint256 public counter;

    event CountUp(address indexed sender);

    constructor(string memory name_) {
        _name = name_;
    }

    function countUp() public {
        counter += 1;

        emit CountUp(msg.sender);
    }
}