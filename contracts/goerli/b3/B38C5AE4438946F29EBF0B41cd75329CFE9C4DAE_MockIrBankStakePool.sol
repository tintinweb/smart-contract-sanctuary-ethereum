/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MockIrBankStakePool {

    bool public paused;

    function setPaused (bool _paused) external  {
        paused = _paused;
    }
}