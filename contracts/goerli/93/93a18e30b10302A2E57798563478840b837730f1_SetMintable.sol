// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
struct MintableData {
    mapping(address => mapping(uint256 => bool)) claimed;    
}
interface SevenTwoOne {
   function ownerOf(uint256 tokenId) external view returns (address);
}
error OnlyOwnerCanClaim();
library SetMintable {
    function isClaimed(MintableData storage self, address addressed, uint256 tokenId) public view returns (bool) {
        return self.claimed[addressed][tokenId];
    }
    function claim(MintableData storage self, address addressed, uint256 tokenId) public {
        address owner = SevenTwoOne(addressed).ownerOf(tokenId);
        if (owner != msg.sender) {
            revert OnlyOwnerCanClaim();
        }
        self.claimed[addressed][tokenId] = true;
    }
}