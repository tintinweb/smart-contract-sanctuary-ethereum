/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Guzzler {
    uint state;

    function use_gas(uint input) public {
        while (input > 0) {
            state++;
            state++;
            state--;
            state--;
            input--;
            }
    }
}