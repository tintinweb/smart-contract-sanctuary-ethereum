// SPDX-License-Identifier: MIT

// Solidity version
pragma solidity 0.8.16;

contract HashStorage {
    // State variables
    bytes32 file_hash;
    uint256 no_of_hashes;
    mapping(bytes32 => bool) hash_record; 

    // Stores hash of a file
    function store_hash(bytes32 new_file_hash) public {
        file_hash = new_file_hash;
        hash_record[file_hash] = true;
        no_of_hashes++;
    }

    // Checks whether an input hash is valid
    function verify_hash(bytes32 hash_to_verify) public view returns (bool) {
        return hash_record[hash_to_verify];
    }

    // Returns most recent file hash
    function retrieve_hash() public view returns (bytes32) {
        return file_hash;
    }

    // Returns total number of hashes
    function check_hash_number() public view returns (uint256) {
        return no_of_hashes;
    }
 
}