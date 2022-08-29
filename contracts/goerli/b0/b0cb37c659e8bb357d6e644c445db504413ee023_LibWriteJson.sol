// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

// solhint-disable quotes

library LibWriteJson {
    function createObject(string memory object) public pure returns (string memory) {
        return string.concat("{", object, "}");
    }

    function keyObject(string memory key, string memory value) public pure returns (string memory) {
        return string.concat('"', key, '": ', "{", value, "}");
    }

    function keyValue(string memory key, string memory value) public pure returns (string memory) {
        return string.concat('"', key, '": ', '"', value, '"');
    }
}