/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract NFT {
    uint256 id;
    string name;
    string uri;

    constructor(uint256 _id, string memory _name, string memory _uri) public {
        id = _id;
        name = _name;
        uri = _uri;
    }

    function getId() public view returns (uint256) {
        return id;
    }

    function getName() public view returns (string memory) {
        return name;
    }

    function getUri() public view returns (string memory) {
        return uri;
    }
}