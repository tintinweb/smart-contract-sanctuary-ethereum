/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Gelato {
    uint public counter = 0;

    function increase() external {
        counter += 1;
    }
}