/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

contract Property {

    int public value;

    function setValue(int _value) public {
        value = _value;
    }
}