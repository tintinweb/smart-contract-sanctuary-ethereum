/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {BytesUtils} from "./utils/BytesUtils.sol";

contract ThreeHexSimpleRenderer {
    using BytesUtils for uint256;

    /// @param tokenId The tokenID to retrieve the URI of in
    /// format <baseURI>/<tokenId-as-hex-string>
    function render(uint256 tokenId, string calldata baseURI)
        public
        view
        virtual
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string.concat(baseURI, tokenId.toHexString3())
                : "";
    }
}

//SPDX-License-Identifier: MIT
// forked from https://github.com/ensdomains/ens-contracts/blob/master/contracts/wrapper/BytesUtil.sol
pragma solidity ^0.8.14;

library BytesUtils {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /*
    * @dev Returns the keccak-256 hash of a byte range.
    * @param self The byte string to hash.
    * @param offset The position to start hashing at.
    * @param len The number of bytes to hash.
    * @return The hash of the byte range.
    */
    function keccak(bytes memory self, uint offset, uint len) internal pure returns (bytes32 ret) {
        require(offset + len <= self.length);
        assembly {
            ret := keccak256(add(add(self, 32), offset), len)
        }
    }

    /**
     * @dev Converts a unit less than 4096  to its ASCII `string` hexadecimal with length 3.
     * @dev Adapted from OpenZepplin's toHexString.
     * @param value The integer to convert.
     * @return string The hex string representation of the integer.
     */
    function toHexString3(uint256 value) internal pure returns (string memory) {
        bytes memory buffer = new bytes(3);            
        for (uint256 i = 3; i > 0; --i) {
            buffer[i-1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "hex length insufficient");
        return string(buffer);
    }
}