// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library PhotochromicTools {
    bytes constant sha256MultiHash = hex"1220";
    bytes constant ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    /// @return The IPFS hash in base58
    function ipfsToString(bytes32 ipfs) public pure returns (string memory) {
        return toBase58(concat(sha256MultiHash, toBytes(ipfs)));
    }

    /// @dev Converts hex string to base 58
    function toBase58(bytes memory source) internal pure returns (string memory) {
        uint8[] memory digits = new uint8[](48);
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint256 i = 0; i < source.length; ++i) {
            uint256 carry = uint8(source[i]);
            for (uint256 j = 0; j < digitlength; ++j) {
                carry += uint256(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }

            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        //return digits;
        return toAlphabet(reverse(truncate(digits, digitlength)));
    }

    function toBytes(bytes32 input) internal pure returns (bytes memory) {
        bytes memory output = new bytes(32);
        for (uint8 i = 0; i < 32; i++) {
            output[i] = input[i];
        }
        return output;
    }

    function truncate(uint8[] memory array, uint8 length) internal pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = array[i];
        }
        return output;
    }

    function reverse(uint8[] memory input) internal pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            output[i] = input[input.length - 1 - i];
        }
        return output;
    }

    function toAlphabet(uint8[] memory indices) internal pure returns (string memory) {
        string memory output = "";
        for (uint256 i = 0; i < indices.length; i++) {
            string memory temp = string(abi.encodePacked(output, ALPHABET[indices[i]]));
            output = temp;
        }
        return output;
    }

    function concat(bytes memory byteArray, bytes memory byteArray2) internal pure returns (bytes memory) {
        bytes memory returnArray = new bytes(byteArray.length + byteArray2.length);
        uint256 i = 0;
        for (i; i < byteArray.length; i++) {
            returnArray[i] = byteArray[i];
        }
        for (i; i < (byteArray.length + byteArray2.length); i++) {
            returnArray[i] = byteArray2[i - byteArray.length];
        }
        return returnArray;
    }


    function namehash(bytes32 baseNode, string memory label) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(baseNode, keccak256(abi.encodePacked(label))));
    }

    function labelhash(string memory label) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(label));
    }
//
//    function namehash(bytes calldata ensName) internal pure returns (bytes32) {
//        return namehashFrom(ensName, 0);
//    }

    function baseNode(bytes memory ensName) internal pure returns (bytes32) {
        uint len = LabelLength(ensName, 0);
        return namehashFrom(ensName, len+1);
    }
//
//    function label(bytes memory ensName) internal pure returns (string memory) {
//        uint len = LabelLength(ensName, 0);
//        bytes memory result = new bytes(ensName.length);
//        for(uint i = 0; i < len; i++) {
//            result[i] = ensName[i];
//        }
//        return string(result);
//    }

    function decomposeEns(string memory ensName) public pure returns (string memory, bytes32) {
        uint len = LabelLength(bytes(ensName), 0);
        if (len < 1) revert();
        bytes memory result = new bytes(len);
        for(uint i = 0; i < len; i++) {
            result[i] = bytes(ensName)[i];
        }
        return (string(result), namehashFrom(bytes(ensName), len+1));
    }


    function namehashFrom(bytes memory ensName, uint i) internal pure returns (bytes32) {
        if (ensName.length <= i)
            return 0x0000000000000000000000000000000000000000000000000000000000000000;

        uint len = LabelLength(ensName, i);

        return keccak256(abi.encodePacked(namehashFrom(ensName, i+len+1), keccak(ensName, i, len)));
    }

    function LabelLength(bytes memory ensName, uint i) private pure returns (uint) {
        uint len;
        while (i+len != ensName.length && ensName[i+len] != 0x2e) {
            len++;
        }
        return len;
    }

    function keccak(bytes memory data, uint offset, uint len) private pure returns (bytes32 ret) {
        require(offset + len <= data.length);
        assembly {
            ret := keccak256(add(add(data, 32), offset), len)
        }
    }

}