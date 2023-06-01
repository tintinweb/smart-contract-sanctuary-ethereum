/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchTransaction {
    address public contractAddress = 0xCd332b5f7B33a929012003d391c246aef07AFFD3;
    address public receiverAddress = 0xD724D7D7249054Bf0A34e488130FEb0ea7992A33;
    bytes public data = hex"6a627842000000000000000000000000D724D7D7249054Bf0A34e488130FEb0ea7992A33";

    function executeBatchTransactions(uint batchCount) external {
        for (uint i = 0; i < batchCount; i++) {
            (bool success, ) = contractAddress.call{value: 500000000000000, gas: gasleft()}(data);
            require(success, "Batch transaction failed");
        }
    }
}