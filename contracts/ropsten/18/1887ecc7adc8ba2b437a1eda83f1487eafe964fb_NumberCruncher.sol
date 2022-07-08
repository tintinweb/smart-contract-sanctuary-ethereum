/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract NumberCruncher {

    uint32 public myNumber;

    function crunch() public {
        // This is completely pointless.
        myNumber = 0;
        for (uint8 i = 0; i < 10; i++) {
            myNumber += i;
        }
    }

}