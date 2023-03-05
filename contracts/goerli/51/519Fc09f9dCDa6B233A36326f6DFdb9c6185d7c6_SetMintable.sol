// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
struct MintableData {
    mapping(address => mapping(uint256 => bool)) claimed;    
}

error OnlyOwnerCanClaim();
library SetMintable {
    function isClaimed(MintableData storage self, address addressed, uint256 tokenId) public view returns (bool) {
        return self.claimed[addressed][tokenId];
    }
    function claim(MintableData storage self, address addressed, uint256 tokenId) public {
        self.claimed[addressed][tokenId] = true;
    }
}