/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

/*

  Copyright 2018 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.5.0;


library LibBytes {

    using LibBytes for bytes;

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return address from byte array.
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        require(
            b.length >= index + 20,  // 20 is length of address
            "GREATER_OR_EQUAL_TO_20_LENGTH_REQUIRED"
        );

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /// @dev Reads a bytes32 value from a position in a byte array.
    /// @param b Byte array containing a bytes32 value.
    /// @param index Index in byte array of bytes32 value.
    /// @return bytes32 value from byte array.
    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        require(
            b.length >= index + 32,
            "GREATER_OR_EQUAL_TO_32_LENGTH_REQUIRED"
        );

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    function readBytes2(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes2 result)
    {
        require(
            b.length >= index + 2,
            "GREATER_OR_EQUAL_TO_2_LENGTH_REQUIRED"
        );

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFF000000000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }
}

contract LibDecoder {
    using LibBytes for bytes;

    function decodeMmSignatureWithoutSign(bytes memory signature) internal pure returns(address user, uint16 feeFactor) {
        require(
            signature.length == 87 || signature.length == 88,
            "LENGTH_87_REQUIRED"
        );

        user = signature.readAddress(65);
        feeFactor = uint16(signature.readBytes2(85));
        
        require(
            feeFactor < 10000,
            "FEE_FACTOR_MORE_THEN_10000"
        );

        return (user, feeFactor);
    }

    function decodeMmSignature(bytes memory signature) internal pure returns(uint8 v, bytes32 r, bytes32 s, address user, uint16 feeFactor) {
        (user, feeFactor) = decodeMmSignatureWithoutSign(signature);

        v = uint8(signature[0]);
        r = signature.readBytes32(1);
        s = signature.readBytes32(33);

        return (v, r, s, user, feeFactor);
    }
}

contract MarketMakerProxy is LibDecoder {
    string public version = "0.0.6";

    uint256 constant MAX_UINT = 2**256 - 1;
    address public SIGNER;

    // Manage
    function setSigner(address _signer) public {
        SIGNER = _signer;
    }

    function isValidSignature(bytes32 orderHash, bytes memory signature) public view returns (bytes32) {
        require(
            SIGNER == ecrecoverAddress(orderHash, signature),
            "INVALID_SIGNATURE"
        );
        return keccak256("isValidWalletSignature(bytes32,address,bytes)");
    }

    function ecrecoverAddress(bytes32 orderHash, bytes memory signature) public pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s, address user, uint16 feeFactor) = decodeMmSignature(signature);
        
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n54",
                    orderHash,
                    user,
                    feeFactor
                )),
            v, r, s
        );
    }
}