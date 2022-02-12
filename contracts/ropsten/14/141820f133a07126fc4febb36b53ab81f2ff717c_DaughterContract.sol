// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract DaughterContract {
    string public name;
    uint public age;
    constructor(
        string memory _daughtersName,
        uint _daughtersAge
    )
    {
    name = _daughtersName;
    age = _daughtersAge;
    }
}