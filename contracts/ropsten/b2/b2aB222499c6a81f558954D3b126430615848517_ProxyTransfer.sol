/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract ProxyTransfer {

   function proxyTransfer(address payable _to) public payable {
        (bool success, ) = _to.call{value: msg.value}("");
        require(success, "Failed to send Ether");
    }

    // TODO: Proxy NFTs - ERC-17 
}