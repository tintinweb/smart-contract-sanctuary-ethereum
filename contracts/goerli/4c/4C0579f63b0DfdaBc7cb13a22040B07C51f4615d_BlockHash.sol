/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
 

contract BlockHash { 
 
    function blockHash(uint256 diff)
        external
        view
        returns (bytes32)
    {
        return blockhash(block.number - diff);
    }
}