/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

pragma solidity ^0.6.8;

// SPDX-License-Identifier: MIT

contract Counter {
    uint public count;
    
    function increment() external {
        count += 1;
    }
}