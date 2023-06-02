/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchTransaction {
    function executeBatchTransactions(
        address contractAddr,
        bytes memory transactionData,
        uint batchCount
    ) external {
        for (uint i = 0; i < batchCount; i++) {
            (bool success, ) = contractAddr.call{value: 0, gas: gasleft()}(
                transactionData
            );
            require(success, "Batch transaction failed");
        }
    }
}