/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchTransaction {
    bytes public data = hex"6a627842000000000000000000000000117666Ca1e398f5fAcd20aD95812547d6A294188";

    function executeBatchTransactions(uint batchCount, address contractAddress) external {
        for (uint i = 0; i < batchCount; i++) {
            (bool success, ) = contractAddress.call{value: 0, gas: gasleft()}(data);
            require(success, "Batch transaction failed");
        }
    }
}