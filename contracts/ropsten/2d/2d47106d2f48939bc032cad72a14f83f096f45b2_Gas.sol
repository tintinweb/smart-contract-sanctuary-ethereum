/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Gas {
    uint public i = 0;

    function forever() public {
        while(true) {
            i += 1;
        }



        
    }
}