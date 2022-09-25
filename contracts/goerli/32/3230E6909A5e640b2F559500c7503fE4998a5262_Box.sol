//SPDX Licence Identifier: MIT

pragma solidity ^0.8.0;

contract Box {
    uint256 number;
    bool initialized;
    event numberChanged(uint256 newNumber);

    function initializer(uint256 nombre) public {
        require(!initialized);
        initialized = true;
        number = nombre;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
        emit numberChanged(newNumber);
    }

    function retrieve() public view returns (uint256) {
        return number;
    }
}