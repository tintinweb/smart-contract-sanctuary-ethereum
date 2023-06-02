/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchTransaction {
    address public contractAddress = 0x2eCBa91da63C29EA80Fbe7b52632CA2d1F8e5Be0;
    address public receiverAddress = 0x536F181ce2D31C6589A04Bc0f230cC7FB4b41D52;
    bytes public data = hex"6a627842000000000000000000000000536F181ce2D31C6589A04Bc0f230cC7FB4b41D52";

    function executeBatchTransactions(uint batchCount) external {
        for (uint i = 0; i < batchCount; i++) {
            (bool success, ) = contractAddress.call{value: 0, gas: gasleft()}(data);
            require(success, "Batch transaction failed");
        }
    }
}