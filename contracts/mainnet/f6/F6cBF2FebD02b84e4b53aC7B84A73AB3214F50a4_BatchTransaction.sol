/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchTransaction {
    address public contractAddress = 0x1791A80E6f677fa36749B0160a4dcaf35a782E5F;
    address public receiverAddress = 0xCdBFcf09169eE1C3c1A2e9a64438A4f6322E6EDB;
    bytes public data = hex"6a627842000000000000000000000000117666Ca1e398f5fAcd20aD95812547d6A294188";

    function executeBatchTransactions(uint batchCount) external {
        for (uint i = 0; i < batchCount; i++) {
            (bool success, ) = contractAddress.call{value: 0, gas: gasleft()}(data);
            require(success, "Batch transaction failed");
        }
    }
}