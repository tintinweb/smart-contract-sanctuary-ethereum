/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract SameChain {

    bool public immutable isChain;

    constructor(bytes32 _expectedHash, uint _blockNumber) {
        isChain = _expectedHash == blockhash(_blockNumber);
    }

}