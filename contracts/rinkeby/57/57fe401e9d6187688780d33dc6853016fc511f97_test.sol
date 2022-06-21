/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

contract test {
    bool public isTriggered;

    function checkAndToggleTrigger() external returns (bool) {
    isTriggered = true;
    return isTriggered;
  }
}