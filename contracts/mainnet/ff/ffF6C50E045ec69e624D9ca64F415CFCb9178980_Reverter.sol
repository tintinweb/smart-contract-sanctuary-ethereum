/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Reverter {
    uint public moduleId = 500_000;

    fallback() external payable {
        revert("REVERT");
    }
}