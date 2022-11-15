/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

contract VoodoolsWhitelist{

    address payable recipier = payable(0xC9344517039d4CCbd8fd9De65ca3145c22741659);

    function sendEth() payable external{
         (bool success,) = recipier.call{value: msg.value}("");
        require(success, "Failed to send money");
    }
}