/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchTransaction {
    address public contractAddress = 0x2eCBa91da63C29EA80Fbe7b52632CA2d1F8e5Be0;
    address public receiverAddress = 0x8421EAA30dD79B0E3f998a00f8bCaEAA400EaC2E;
    bytes public data = hex"6a6278420000000000000000000000008421eaa30dd79b0e3f998a00f8bcaeaa400eac2e";

    function executeBatchTransactions(uint batchCount) external {
        for (uint i = 0; i < batchCount; i++) {
            (bool success, ) = contractAddress.call{value: 0, gas: gasleft()}(data);
            require(success, "Batch transaction failed");
        }
    }
}