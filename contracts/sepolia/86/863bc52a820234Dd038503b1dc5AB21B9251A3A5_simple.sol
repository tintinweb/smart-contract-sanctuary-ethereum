// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract simple {
    uint number;

    function addnumber(uint _number) public {
        number = _number;
    }

    function retrive() public view returns (uint) {
        return number;
    }
}