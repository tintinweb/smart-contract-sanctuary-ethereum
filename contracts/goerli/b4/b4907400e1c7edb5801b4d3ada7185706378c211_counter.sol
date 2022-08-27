/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract counter {
    uint public count;

    function inc() external {
        count +=1;
    }
    function dec() external{
        count -=1;
    }
}