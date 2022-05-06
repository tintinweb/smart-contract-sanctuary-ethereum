// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TokenRangeValidator {
    function validateProperty(
        address, // tokenAddress
        uint256 tokenId,
        bytes calldata propertyData
    ) external pure {
        (uint256 startTokenId, uint256 endTokenId) = abi.decode(
            propertyData,
            (uint256, uint256)
        );
        require(
            startTokenId <= tokenId && tokenId <= endTokenId,
            "Token id out of range"
        );
    }
}