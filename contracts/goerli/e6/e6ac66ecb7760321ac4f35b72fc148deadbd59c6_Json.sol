// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.10;

struct JsonAttribute {
    string key;
    string value;
}

library Json {
    function makeJsonString(JsonAttribute[] memory attributes) public pure returns (string memory ret) {
        ret = "{";
        for (uint i = 0; i < attributes.length; ++i) {
            ret = string.concat(ret, "\n    \"");
            ret = string.concat(ret, attributes[i].key);
            ret = string.concat(ret, "\": ");
            ret = string.concat(ret, attributes[i].value);
            if (i != attributes.length - 1) {
                ret = string.concat(ret, ",");
            }
        }
        ret = string.concat(ret, "\n}");
    }

    function quote(string memory s) public pure returns (string memory ret) {
        return string(abi.encodePacked("\"", s, "\""));
    }
}