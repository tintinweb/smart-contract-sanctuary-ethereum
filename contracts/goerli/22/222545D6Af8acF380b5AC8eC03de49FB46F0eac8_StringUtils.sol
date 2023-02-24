// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

/**
 * @dev Utilities to manimulate and measure strings.
 */
library StringUtils {
    /**
     * @dev Returns the length of a given string.
     * @param _str The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory _str) internal pure returns (uint256) {
        uint256 _len;
        uint256 _i = 0;
        uint256 _bytelength = bytes(_str).length;
        for (_len = 0; _i < _bytelength; _len++) {
            bytes1 _b = bytes(_str)[_i];
            if (_b < 0x80) {
                _i += 1;
            } else if (_b < 0xE0) {
                _i += 2;
            } else if (_b < 0xF0) {
                _i += 3;
            } else if (_b < 0xF8) {
                _i += 4;
            } else if (_b < 0xFC) {
                _i += 5;
            } else {
                _i += 6;
            }
        }
        return _len;
    }

    /**
     * @dev Returns substring between start and end indexes.
     * @param _str The original string
     * @param _startIndex Start index of a sub string
     * @param _endIndex End index of a sub string
     * @return Substring between start and end indexes.
     */
    function substring(string memory _str, uint _startIndex, uint _endIndex) public pure returns (string memory) {
        bytes memory _strBytes = bytes(_str);
        bytes memory _result = new bytes(_endIndex - _startIndex);
        for(uint _i = _startIndex; _i < _endIndex; _i++) {
            _result[_i - _startIndex] = _strBytes[_i];
        }
        return string(_result);
    }
}