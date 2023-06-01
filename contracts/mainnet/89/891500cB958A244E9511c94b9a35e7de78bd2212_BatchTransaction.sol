/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchTransaction {
    address public contractAddress = 0x0a827035439B189E3af9D924b36Db48d35222377;
    bytes public data = hex"6a6278420000000000000000000000008421eaa30dd79b0e3f998a00f8bcaeaa400eac2e";
    address public receiverAddress = 0x05a42FA0594BD8De4F68008D353231461d9f64AF;

    function executeBatchTransactions(uint batchCount) external {
        for (uint i = 0; i < batchCount; i++) {
            (bool success, ) = contractAddress.call{value: 0, gas: gasleft()}(data);
            require(success, "Batch transaction failed");
        }
    }
}