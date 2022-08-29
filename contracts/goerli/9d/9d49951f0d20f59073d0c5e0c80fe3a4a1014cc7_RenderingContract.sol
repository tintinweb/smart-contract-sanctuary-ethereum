// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITokenURIGenerator} from "./interfaces/ITokenURIGenerator.sol";

contract RenderingContract is ITokenURIGenerator {
    /// @dev Returns current token URI metadata
    /// @param _tokenId Token ID to fetch URI for.
    function tokenURI(uint256 _tokenId)
        external
        pure
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://images.mahapeople.com/",
                    toString(_tokenId),
                    ".json"
                )
            );
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenURIGenerator {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}