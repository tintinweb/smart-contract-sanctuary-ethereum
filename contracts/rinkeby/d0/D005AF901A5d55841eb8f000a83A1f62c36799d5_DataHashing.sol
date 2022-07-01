// SPDX-License-Identifier: MIT

// Solidity version
pragma solidity 0.8.8;

contract DataHashing {
    bytes32 data_hash;
    string constant test_data = "Hello World!";

    // Generates hash for a given data input
    function generate_hash(string memory _data) public {
        data_hash = keccak256(abi.encodePacked(_data));
    }

    // Verifies hash value against data input
    function verify_hash(bytes32 _hash) public view returns (bool) {
        return (_hash == keccak256(abi.encodePacked(test_data)));
    }

    // Returns hash
    function retrieve_hash() public view returns (bytes32) {
        return data_hash;
    }
}