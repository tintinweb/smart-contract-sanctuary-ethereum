// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

contract MockCryptoPunks {
    mapping(uint256 => address) ownerOf;

    function setTokenOwner(uint256 tokenId_, address owner_) external {
        ownerOf[tokenId_] = owner_;
    }

    function punkIndexToAddress(uint256 tokenId) external view returns (address) {
        return ownerOf[tokenId];
    }
}