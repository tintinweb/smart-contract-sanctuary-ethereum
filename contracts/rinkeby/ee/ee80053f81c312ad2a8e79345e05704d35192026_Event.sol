/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

contract Event {

 event BridgeAdded(
        string indexed tokenTicker,
        string tokenName,
        string imageUrl
    );

    function test() public{
        emit BridgeAdded("test1", "test2", "test3");
    }
}