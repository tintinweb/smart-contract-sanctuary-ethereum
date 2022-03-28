// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct EcdsaSig {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

enum VerificationStatus {
    VERIFIED,
    UNVERIFIED,
    INVALID
}

uint8 constant DATA_FIELDS = 5;

library Validator {
    string constant PC_FIRSTNAME = string(abi.encodePacked("io.photochromic.firstname"));
    string constant PC_LASTNAME = string(abi.encodePacked("io.photochromic.lastname"));
    string constant PC_BIRTHDATE = string(abi.encodePacked("io.photochromic.birthdate"));
    string constant PC_NATIONALITY = string(abi.encodePacked("io.photochromic.nationality"));
    string constant PC_USERID = string(abi.encodePacked("io.photochromic.userid"));

    function isPhotochromicRecord(string calldata key) public pure returns (bool) {
        return
            keccak256(abi.encodePacked(key)) == keccak256(bytes(PC_FIRSTNAME)) ||
            keccak256(abi.encodePacked(key)) == keccak256(bytes(PC_LASTNAME)) ||
            keccak256(abi.encodePacked(key)) == keccak256(bytes("email")) ||
            keccak256(abi.encodePacked(key)) == keccak256(bytes(PC_BIRTHDATE)) ||
            keccak256(abi.encodePacked(key)) == keccak256(bytes(PC_NATIONALITY)) ||
            keccak256(abi.encodePacked(key)) == keccak256(bytes(PC_USERID));
    }

    function getPhotochromicRecord(string calldata key, bytes calldata record) public pure returns (string memory) {
        uint8 index = getPhotochromicRecordIndex(key);
        uint256 skipBytes = 0;
        if (0 < record.length) {
            do {
                index -= 1;
                uint8 lengthInBytes = uint8(record[skipBytes]);
                skipBytes += 1;
                if (index == 0) {
                    // copy string from recordBytes
                    bytes memory result = new bytes(lengthInBytes);
                    uint256 stringStart = skipBytes;
                    for (uint256 i = 0; i < lengthInBytes; i++) {
                        result[i] = record[stringStart + i];
                    }
                    return string(result);
                }
                skipBytes += lengthInBytes;
            } while (0 < index);
        }
        return "";
    }

    function getPhotochromicRecordIndex(string calldata key) private pure returns (uint8) {
        if (keccak256(abi.encodePacked(key)) == keccak256(bytes(PC_FIRSTNAME)))   return 1;
        if (keccak256(abi.encodePacked(key)) == keccak256(bytes(PC_LASTNAME)))    return 2;
        if (keccak256(abi.encodePacked(key)) == keccak256(bytes("email")))        return 3;
        if (keccak256(abi.encodePacked(key)) == keccak256(bytes(PC_BIRTHDATE)))   return 4;
        if (keccak256(abi.encodePacked(key)) == keccak256(bytes(PC_NATIONALITY))) return 5;
        if (keccak256(abi.encodePacked(key)) == keccak256(bytes(PC_USERID)))      return 6;
    }

    function isAnonymous(string[DATA_FIELDS] calldata contents) public pure returns (bool) {
        return (bytes(contents[0]).length == 0 &&
            bytes(contents[1]).length == 0 &&
            bytes(contents[2]).length == 0 &&
            bytes(contents[3]).length == 0 &&
            bytes(contents[4]).length == 0);
    }

    function packPhotochromicRecord(string memory userId, string[DATA_FIELDS] calldata contents, uint32 t) public pure returns (string memory) {
        return string(abi.encodePacked(
            abi.encodePacked(
                uint8(bytes(contents[0]).length + 4),
                appendTimestamp(bytes(contents[0]), t),
                uint8(bytes(contents[1]).length + 4),
                appendTimestamp(bytes(contents[1]), t),
                uint8(bytes(contents[2]).length + 4),
                appendTimestamp(bytes(contents[2]), t)
            ),
            uint8(bytes(contents[3]).length + 4),
            appendTimestamp(bytes(contents[3]), t),
            uint8(bytes(contents[4]).length + 4),
            appendTimestamp(bytes(contents[4]), t),
            uint8(bytes(userId).length + 4),
            appendTimestamp(bytes(userId), t)
        ));
    }

    function appendTimestamp(bytes memory value, uint32 ts) public pure returns (bytes memory) {
        bytes4 t = bytes4(ts);
        bytes memory merged = new bytes(value.length + 4);
        for (uint i = 0; i < value.length; i++) {
            merged[i] = value[i];
        }
        for (uint i = 0; i < t.length; i++) {
            merged[value.length + i] = t[i];
        }
        return merged;
    }

    function removeTimestamp(bytes memory value) public pure returns (bytes memory, uint32) {
        if (value.length == 0) return (value, 0);
        bytes memory split = new bytes(value.length - 4);
        for (uint i = 0; i < value.length - 4; i++) {
            split[i] = value[i];
        }
        uint32 t = (uint32(uint8(value[value.length - 4])) << 24) | (uint32(uint8(value[value.length - 3])) << 16) | (uint32(uint8(value[value.length - 2])) << 8) | uint32(uint8(value[value.length - 1]));
        return (split, t);
    }
}