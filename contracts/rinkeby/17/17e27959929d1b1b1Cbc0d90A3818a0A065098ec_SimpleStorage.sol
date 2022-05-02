/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// File: SimpleStorage.sol

contract SimpleStorage {
    // Contents of our contract simple storage.

    address public owner;
    int256 public storage_count;

    constructor() public {
        storage_count = 0;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function update_count(int256 count) public payable onlyOwner {
        storage_count = storage_count + count;
    }
}