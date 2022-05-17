// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IPropertyValidator} from "./interfaces/IPropertyValidator.sol";

// Credits: https://github.com/mzhu25/0x-property-validators
contract BitVectorValidator is IPropertyValidator {
    function validateProperty(
        address, // tokenAddress
        uint256 tokenId,
        bytes calldata propertyData
    ) external pure {
        // tokenId < propertyData.length * 8
        require(
            tokenId < propertyData.length << 3,
            "Bit vector length exceeded"
        );

        // Bit corresponding to tokenId must be set
        require(
            uint8(propertyData[tokenId >> 3]) & (0x80 >> (tokenId & 7)) != 0,
            "Token id not in bit vector"
        );
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