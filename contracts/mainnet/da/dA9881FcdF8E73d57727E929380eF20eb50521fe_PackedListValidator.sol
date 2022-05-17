// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IPropertyValidator} from "./interfaces/IPropertyValidator.sol";

// Credits: https://github.com/mzhu25/0x-property-validators
contract PackedListValidator is IPropertyValidator {
    function validateProperty(
        address, // tokenAddress
        uint256 tokenId,
        bytes calldata propertyData
    )
        external
        pure
    {
        (uint256 bytesPerTokenId, bytes memory packedList) = abi.decode(
            propertyData,
            (uint256, bytes)
        );

        require(
            bytesPerTokenId != 0 && bytesPerTokenId <= 32,
            "Invalid number of bytes per token id"
        );

        // Masks the lower `bytesPerTokenId` bytes of a word
        // So if `bytesPerTokenId` == 1, then bitmask = 0xff
        //    if `bytesPerTokenId` == 2, then bitmask = 0xffff, etc.
        uint256 bitMask = ~(type(uint256).max << (bytesPerTokenId << 3));
        assembly {
            // Binary search for given token id

            let left := 1
            // right = number of tokenIds in the list
            let right := div(mload(packedList), bytesPerTokenId)

            // while(left < right)
            for {} lt(left, right) {} {
                // mid = (left + right) / 2
                let mid := shr(1, add(left, right))
                // more or less equivalent to:
                // value = list[index]
                let offset := add(packedList, mul(mid, bytesPerTokenId))
                let value := and(mload(offset), bitMask)
                // if (value < tokenId) {
                //     left = mid + 1;
                //     continue;
                // }
                if lt(value, tokenId) {
                    left := add(mid, 1)
                    continue
                }
                // if (value > tokenId) {
                //     right = mid;
                //     continue;
                // }
                if gt(value, tokenId) {
                    right := mid
                    continue
                }
                // if (value == tokenId) { return; }
                stop()
            }
            // At this point left == right; check if list[left] == tokenId
            let offset := add(packedList, mul(left, bytesPerTokenId))
            let value := and(mload(offset), bitMask)
            if eq(value, tokenId) {
                stop()
            }
        }
        revert("Token id not in packed list");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPropertyValidator {
    function validateProperty(
        address tokenAddress,
        uint256 tokenId,
        bytes calldata propertyData
    ) external view;
}