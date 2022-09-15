/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract Contract {

    uint256 public counter;

    function increase() public {
        counter++;
    }

    function decrease() public {
        counter--;
    }
    
}