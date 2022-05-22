//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.14;

contract TestCalldata {

event status (uint _temp);

uint public temporary;

    function updatevalueoftemp() public returns (uint) {
        temporary += 100;
        emit status (temporary);
        return temporary;
    }

}

// call data 0xfd445e19 for updatevalueoftemp()