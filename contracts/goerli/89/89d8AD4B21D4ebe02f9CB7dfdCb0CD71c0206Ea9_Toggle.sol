/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Toggle {
    bool private isOn;

    constructor() {
        isOn = true;
    }

    function toggleSwitch() public {
        isOn = !isOn;
    }
}