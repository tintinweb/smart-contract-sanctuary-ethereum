// SPDX-Licence-Identifier: MIT

pragma solidity 0.8.20;

contract SimpleStorage {
    uint public number;

    constructor(uint _number) {
        number = _number;
    }

    function getNumber() external view returns (uint) {
        return number;
    }

    function setNumber(uint _number) external {
        number = _number;
    }
}