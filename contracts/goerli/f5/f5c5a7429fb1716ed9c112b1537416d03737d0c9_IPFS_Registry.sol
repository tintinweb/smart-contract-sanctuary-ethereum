/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

contract IPFS_Registry {

    // Mapping from content id to content struct
    mapping(address => string) public contents;

    function setFilePublic(string memory file) public {
        contents[msg.sender] = file;
    }

    function setFileExternal(string memory file) external {
        contents[msg.sender] = file;
    }

}