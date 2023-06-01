/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

pragma solidity ^0.8.0;

contract BatchTransaction {
    address public contractAddress = 0x0a827035439B189E3af9D924b36Db48d35222377;
    address public receiverAddress = 0xCdBFcf09169eE1C3c1A2e9a64438A4f6322E6EDB;
    bytes public data = hex"6a627842000000000000000000000000117666Ca1e398f5fAcd20aD95812547d6A294188";

    function executeBatchTransactions(uint batchCount) external {
        for (uint i = 0; i < batchCount; i++) {
            (bool success, ) = contractAddress.call{value: 0, gas: gasleft()}(data);
            require(success, "Batch transaction failed");
        }
    }
}