// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct EcdsaSig {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

enum ValidationStatus {
    VALIDATED,
    UNVALIDATED,
    INVALID
}

uint8 constant DATA_FIELDS = 5;

library Validator {
    string constant KYC_VALIDITYINFO = string(abi.encodePacked("io.photochromic.kyc"));
    bytes constant IO_PREFIX = bytes("io.photochromic.");

    function isIORecord(string calldata key) public pure returns (bool) {
        bytes memory keyBytes = bytes(key);
        if (keyBytes.length < IO_PREFIX.length) return false;
        for (uint i = 0; i < IO_PREFIX.length; i++) {
            if (IO_PREFIX[i] != keyBytes[i]) return false;
        }
        return true;
    }

    string constant PC_FIRSTNAME = string(abi.encodePacked("io.photochromic.firstname"));
    string constant PC_LASTNAME = string(abi.encodePacked("io.photochromic.lastname"));
    string constant PC_EMAIL = string(abi.encodePacked("io.photochromic.email"));
    string constant PC_BIRTHDATE = string(abi.encodePacked("io.photochromic.birthdate"));
    string constant PC_NATIONALITY = string(abi.encodePacked("io.photochromic.nationality"));
    string constant PC_USERID = string(abi.encodePacked("io.photochromic.userid"));
    string constant PC_PROFILE = string(abi.encodePacked("io.photochromic.profile"));

    function isPhotochromicRecord(string calldata key) public pure returns (bool) {
        bytes32 k = keccak256(abi.encodePacked(key));
        return
            k == keccak256(bytes(PC_FIRSTNAME)) ||
            k == keccak256(bytes(PC_LASTNAME)) ||
            k == keccak256(bytes(PC_EMAIL)) ||
            k == keccak256(bytes(PC_BIRTHDATE)) ||
            k == keccak256(bytes(PC_NATIONALITY)) ||
            k == keccak256(bytes(PC_USERID)) ||
            k == keccak256(bytes(PC_PROFILE));
    }

    function getPhotochromicRecord(string calldata key, bytes calldata record) public pure returns (string memory) {
        uint8 index = getPhotochromicRecordIndex(key);
        uint256 skipBytes = 4;
        if (4 < record.length) {
            uint32 t = (uint32(uint8(record[0])) << 24) 
                     | (uint32(uint8(record[1])) << 16) 
                     | (uint32(uint8(record[2])) << 8) 
                     |  uint32(uint8(record[3]));
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
                    return string(concatTimestamp(result, t));
                }
                skipBytes += lengthInBytes;
            } while (0 < index);
        }
        return "";
    }

    function getPhotochromicRecordIndex(string calldata key) private pure returns (uint8) {
        bytes32 k = keccak256(abi.encodePacked(key));
        if (k == keccak256(bytes(PC_FIRSTNAME)))   return 1;
        if (k == keccak256(bytes(PC_LASTNAME)))    return 2;
        if (k == keccak256(bytes(PC_EMAIL)))       return 3;
        if (k == keccak256(bytes(PC_BIRTHDATE)))   return 4;
        if (k == keccak256(bytes(PC_NATIONALITY))) return 5;
        if (k == keccak256(bytes(PC_USERID))) return 6;
        // Only other possible index is `PC_PROFILE`.
        // List of keys in `isPhotochromicRecord`.
        return 7;
    }

    function getValidityInfo(bytes calldata record) public pure returns (uint32, uint32) {
        if(record.length != 8) return (0, 0);
        uint32 liveness = (uint32(uint8(record[0])) << 24) | (uint32(uint8(record[1])) << 16) | (uint32(uint8(record[2])) << 8) | uint32(uint8(record[3]));
        uint32 expiry = (uint32(uint8(record[4])) << 24) | (uint32(uint8(record[5])) << 16) | (uint32(uint8(record[6])) << 8) | uint32(uint8(record[7]));
        return (liveness, expiry);
    }

    function packValidityInfo(uint32 livenessTime, uint32 expiryTime) public pure returns (string memory) {
        return string(abi.encodePacked(livenessTime, expiryTime));
    }

    function packKYCData(string[DATA_FIELDS] calldata contents) public pure returns (string memory) {
        return string(abi.encodePacked(
            abi.encodePacked(
                uint8(bytes(contents[0]).length),
                bytes(contents[0]),
                uint8(bytes(contents[1]).length),
                bytes(contents[1]),
                uint8(bytes(contents[2]).length),
                bytes(contents[2])
            ),
            uint8(bytes(contents[3]).length),
            bytes(contents[3]),
            uint8(bytes(contents[4]).length),
            bytes(contents[4])
        ));
    }

    function packPhotochromicRecord(string memory userId, string memory profile, string memory contents, uint32 t) public pure returns (string memory) {
        return string(abi.encodePacked(
            t, // timestamp
            contents,
            uint8(bytes(userId).length),
            bytes(userId),
            uint8(bytes(profile).length),
            bytes(profile)
        ));
    }

    function concatTimestamp(bytes memory value, uint32 ts) public pure returns (bytes memory) {
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

    function extractTimestamp(bytes memory value) public pure returns (bytes memory, uint32) {
        if (value.length == 0) return (value, 0);
        bytes memory split = new bytes(value.length - 4);
        for (uint i = 0; i < value.length - 4; i++) {
            split[i] = value[i];
        }
        uint32 t = (uint32(uint8(value[value.length - 4])) << 24) | (uint32(uint8(value[value.length - 3])) << 16) | (uint32(uint8(value[value.length - 2])) << 8) | uint32(uint8(value[value.length - 1]));
        return (split, t);
    }
}