// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

library KassUtils {
    function strToUint256(string memory text) public pure returns (uint256 res) {
        bytes32 stringInBytes32 = bytes32(bytes(text));
        uint256 strLen = bytes(text).length; // TODO: cannot be above 32
        require(strLen <= 32, "String cannot be longer than 32");

        uint256 shift = 256 - 8 * strLen;

        uint256 stringInUint256;
        assembly {
            stringInUint256 := shr(shift, stringInBytes32)
        }
        return stringInUint256;
    }

    function concat(string[] calldata words) public pure returns (string memory) {
        string memory output;

        for (uint256 i = 0; i < words.length; i++) {
            output = string.concat(output, words[i]);
        }

        return output;
    }
}