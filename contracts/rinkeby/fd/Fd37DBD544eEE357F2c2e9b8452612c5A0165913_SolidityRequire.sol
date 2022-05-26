/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


contract SolidityRequire {
    address owner;
    bool result;

    constructor() {
        result = false;
        owner = msg.sender;
    }

    function throwACoin(uint256 tokenId, uint256 blockTimestamp) public view returns(uint256) {
        require(owner == msg.sender, "Caller is not the owner");
        bytes32 rand = keccak256(abi.encodePacked(tokenId, blockTimestamp));

        return uint256(rand)%2;           
    }
}