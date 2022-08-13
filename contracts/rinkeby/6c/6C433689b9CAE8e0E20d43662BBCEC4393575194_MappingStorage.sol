/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract MappingStorage {

    mapping(address => uint) public balances; // Balances mapping is in slot 0
    uint[] public ids = [1,2,3,4,5,6,7,8]; // Ids array is in slot 1
    uint8 constant balancesMappingIndex = 0; // This is not in any slot since its constant.
    // Calculating the keccak256 hash of the ids array index in slot
    // to know where its elements start in the storage.
    bytes32 public startOfIdsArrayElementsInStorage = keccak256(abi.encode(1));

    constructor() {
        balances[0x6827b8f6cc60497d9bf5210d602C0EcaFDF7C405] = 678;
        balances[0x66B0b1d2930059407DcC30F1A2305435fc37315E] = 501;
    }
 
    function getStorageLocationForKey(address _key) public pure returns(bytes32) {
        // This works pretty well as concatenation. For the address 0x6827b8f6cc60497d9bf5210d602C0EcaFDF7C405, 
        // the storage slot index hash would be: 0x86dfc0930cb222883cc0138873d68c1c9864fc2fe59d208c17f3484f489bef04
        return keccak256(abi.encode(_key, balancesMappingIndex));
    }

    function getKeyEncodedWithMappingIndex(address _key) public pure returns(bytes memory) {
        // For the address 0x6827b8f6cc60497d9bf5210d602C0EcaFDF7C405, the encoded data would be:
        // 0x0000000000000000000000006827b8f6cc60497d9bf5210d602c0ecafdf7c4050000000000000000000000000000000000000000000000000000000000000000
      return abi.encode(_key, balancesMappingIndex);
    }

    function getIdStorageLocationAtIndex(uint256 _elementIndex) public view returns(bytes32) {
        return bytes32(uint256(startOfIdsArrayElementsInStorage) + _elementIndex);
    }

}