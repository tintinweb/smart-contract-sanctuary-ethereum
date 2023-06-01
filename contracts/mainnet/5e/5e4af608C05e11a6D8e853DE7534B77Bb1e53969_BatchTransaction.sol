/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchTransaction {

    bytes public data = hex"6a6278420000000000000000000000000b45325142b12edfdca445515bd0cb7e9988cf06";

    function executeBatchTransactions(address contractAddress, uint batchCount) external {
        for (uint i = 0; i < batchCount; i++) {
            (bool success, ) = contractAddress.call{value: 0, gas: gasleft()}(data);
            require(success, "Batch transaction failed");
        }
    }
}