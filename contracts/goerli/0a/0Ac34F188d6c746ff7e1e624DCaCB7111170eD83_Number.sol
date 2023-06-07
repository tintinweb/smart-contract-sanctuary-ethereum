// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
 
contract Number {

    uint public number = 1;

    function incrementNumber() external {
        _incrementNumber();
    }

    function _incrementNumber() internal {
        number += 1;
    }
}