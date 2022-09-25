//SPDX Licence Identifier: MIT

pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 number;
    bool initialized;
    event numberChanged(uint256 newNumber);

    function initializer() public {
        require(!initialized);
        initialized = true;
        number = 1;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
        emit numberChanged(number);
    }

    function retrieve() public view returns (uint256) {
        return number;
    }

    function increment() public {
        number += 1;
        emit numberChanged(number);
    }
}