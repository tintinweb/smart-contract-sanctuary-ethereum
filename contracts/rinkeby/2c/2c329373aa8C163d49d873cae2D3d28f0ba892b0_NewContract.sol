// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract NewContract {
    string public name;
    uint256 public age;

    constructor(string memory _daughtersName, uint256 _daughtersAge) public {
        name = _daughtersName;
        age = _daughtersAge;
    }

    function retrieve_name() public view returns (string memory) {
        return name;
    }

    function retrieve_age() public view returns (uint256) {
        return age;
    }
}