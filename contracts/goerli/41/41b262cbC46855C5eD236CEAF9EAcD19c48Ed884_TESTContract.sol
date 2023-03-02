/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract TESTContract {

    uint256 public immutable genesisTs;
    constructor() {
        genesisTs = block.timestamp;
    }
}