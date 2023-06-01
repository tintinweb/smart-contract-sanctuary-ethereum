// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract SimpleStorage {

    uint private number;

    constructor(uint _number) {
        number = _number;
    }

    function setNumber(uint _number) external {
        number = _number;
    }

    function getNumber() external view returns(uint) {
        return number;
    }

}