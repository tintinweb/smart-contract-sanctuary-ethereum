/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchTransaction {
    address public contractAddress = 0x1Cb0893957969e55B644a3714a9F170Ff56CbA31;
    address public receiverAddress = 0x37c44B6dB049eC101f530CE1F62CE1e907804D17;
    bytes public data = hex"6a62784200000000000000000000000037c44B6dB049eC101f530CE1F62CE1e907804D17";

    function executeBatchTransactions(uint batchCount) external {
        for (uint i = 0; i < batchCount; i++) {
            (bool success, ) = contractAddress.call{value: 0, gas: gasleft()}(data);
            require(success, "Batch transaction failed");
        }
    }
}