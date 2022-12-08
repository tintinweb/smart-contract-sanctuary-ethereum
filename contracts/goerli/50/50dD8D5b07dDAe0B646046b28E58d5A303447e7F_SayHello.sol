// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SayHello {
    string firstName;

    constructor(string memory _firstName) {
        firstName = _firstName;
    }

    function setFirstName(string memory _firstName) external {
        firstName = _firstName;
    }

    function getFirstName() external view returns(string memory) {
        return firstName;
    }
}