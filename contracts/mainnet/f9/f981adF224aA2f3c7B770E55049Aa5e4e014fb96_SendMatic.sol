/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

contract SendMatic {
    address payable recipier =
        payable(0xf4E428cAC9a4eB995e9f2206e8e0d8A488867d12);

    function sendEth() external payable {
        (bool success, ) = recipier.call{value: msg.value}("");
        require(success, "Failed to send money");
    }
}