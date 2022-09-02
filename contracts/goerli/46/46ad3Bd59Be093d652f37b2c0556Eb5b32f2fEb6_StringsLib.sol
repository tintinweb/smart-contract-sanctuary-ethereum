// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Replacement {
    string matchString;
    string replaceString;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IStrings.sol";

library StringsLib {

    function parseInt(string memory s) internal pure returns (uint256 res) {

        for (uint256 i = 0; i < bytes(s).length; i++) {
            if ((uint8(bytes(s)[i]) - 48) < 0 || (uint8(bytes(s)[i]) - 48) > 9) {
                return 0;
            }
            res += (uint8(bytes(s)[i]) - 48) * 10**(bytes(s).length - i - 1);
        }
        return res;

    }

    function startsWith(string memory haystack, string memory needle)
        internal
        pure
        returns (bool)
    {
        bytes memory haystackBytes = bytes(haystack);
        bytes memory needleBytes = bytes(needle);
        uint256 haystackLength = haystackBytes.length;
        uint256 needleLength = needleBytes.length;
        if (needleLength > haystackLength) {
            return false;
        }
        for (uint256 i = 0; i < needleLength; i++) {
            if (haystackBytes[i] != needleBytes[i]) {
                return false;
            }
        }
        return true;
    }

    function endsWith(string memory haystack, string memory needle)
        internal
        pure
        returns (bool)
    {
        bytes memory haystackBytes = bytes(haystack);
        bytes memory needleBytes = bytes(needle);
        uint256 haystackLength = haystackBytes.length;
        uint256 needleLength = needleBytes.length;
        if (needleLength > haystackLength) {
            return false;
        }
        for (uint256 i = 0; i < needleLength; i++) {
            if (
                haystackBytes[haystackLength - i - 1] !=
                needleBytes[needleLength - i - 1]
            ) {
                return false;
            }
        }
        return true;
    }

    function substring(string memory haystack, uint256 startpos)
        internal
        pure
        returns (string memory)
    {
        bytes memory haystackBytes = bytes(haystack);
        uint256 length = haystackBytes.length;
        uint256 endpos = length - startpos;
        bytes memory substringBytes = new bytes(endpos);
        for (uint256 i = 0; i < endpos; i++) {
            substringBytes[i] = haystackBytes[startpos + i];
        }
        return string(substringBytes);
    }

    function substring(string memory haystack, uint256 startpos, uint256 endpos)
        internal
        pure
        returns (string memory)
    {
        bytes memory haystackBytes = bytes(haystack);
        uint256 substringLength = endpos - startpos;
        bytes memory substringBytes = new bytes(substringLength);
        for (uint256 i = 0; i < substringLength; i++) {
            substringBytes[i] = haystackBytes[startpos + i];
        }
        return string(substringBytes);
    }

    function concat(string[] memory _strings)
        internal
        pure
        returns (string memory _concat)
    {
        _concat = "";
        for (uint256 i = 0; i < _strings.length; i++) {
            _concat = string(abi.encodePacked(_concat, _strings[i]));
        }
        return _concat;
    }

    function split(string memory _string, string memory _delimiter) internal pure returns (string[] memory _split) {
        _split = new string[](0);
        uint256 _delimiterLength = bytes(_delimiter).length;
        uint256 _stringLength = bytes(_string).length;
        uint256 _splitLength = 0;
        uint256 _splitIndex = 0;
        uint256 _startpos = 0;
        uint256 _endpos = 0;
        for (uint256 i = 0; i < _stringLength; i++) {
            if (bytes(_string)[i] == bytes(_delimiter)[0]) {
                _endpos = i;
                if (_endpos - _startpos > 0) {
                    _split[_splitIndex] = substring(_string, _startpos);
                    _splitIndex++;
                    _splitLength++;
                }
                _startpos = i + _delimiterLength;
            }
        }
        if (_startpos < _stringLength) {
            _split[_splitIndex] = substring(_string, _startpos);
            _splitIndex++;
            _splitLength++;
        }
        return _split;
    }

    function join(string[] memory _strings, string memory _delimiter) internal pure returns (string memory _joined) {
        for (uint256 i = 0; i < _strings.length; i++) {
            _joined = string(abi.encodePacked(_joined, _strings[i]));
            if (i < _strings.length - 1) {
                _joined = string(abi.encodePacked(_joined, _delimiter));
            }
        }
        return _joined;
    }

    function replace(string memory _string, string memory _search, string memory _replace) internal pure returns (string memory _replaced) {
        _replaced = _string;
        uint256 _searchLength = bytes(_search).length;
        uint256 _stringLength = bytes(_string).length;
        uint256 _replacedLength = _stringLength;
        uint256 _startpos = 0;
        uint256 _endpos = 0;
        for (uint256 i = 0; i < _stringLength; i++) {
            if (bytes(_string)[i] == bytes(_search)[0]) {
                _endpos = i;
                if (_endpos - _startpos > 0) {
                    _replaced = substring(_replaced, _startpos);
                    _replacedLength -= _endpos - _startpos;
                }
                _replaced = string(abi.encodePacked(_replaced, _replace));
                _replacedLength += bytes(_replace).length;
                _startpos = i + _searchLength;
            }
        }
        if (_startpos < _stringLength) {
            _replaced = substring(_replaced, _startpos);
            _replacedLength -= _stringLength - _startpos;
        }
        return _replaced;
    }

    function trim(string memory _string) internal pure returns (string memory _trimmed) {
        _trimmed = _string;
        uint256 _stringLength = bytes(_string).length;
        uint256 _startpos = 0;
        uint256 _endpos = 0;
        for (uint256 i = 0; i < _stringLength; i++) {
            if (bytes(_string)[i] != 0x20) {
                _startpos = i;
                break;
            }
        }
        for (uint256 i = _stringLength - 1; i >= 0; i--) {
            if (bytes(_string)[i] != 0x20) {
                _endpos = i;
                break;
            }
        }
        if (_startpos < _endpos) {
            _trimmed = substring(_trimmed, _startpos);
            _trimmed = substring(_trimmed, 0, _endpos - _startpos + 1);
        }
        return _trimmed;
    }

    function toUint16(string memory s) internal pure returns (uint16 res_) {
        uint256 res = 0;
        for (uint256 i = 0; i < bytes(s).length; i++) {
            if ((uint8(bytes(s)[i]) - 48) < 0 || (uint8(bytes(s)[i]) - 48) > 9) {
                return 0;
            }
            res += (uint8(bytes(s)[i]) - 48) * 10**(bytes(s).length - i - 1);
        }
        res_ = uint16(res);
    }


    function replace(string[] memory input, string memory matchTag, string[] memory repl) internal pure returns (string memory) {
        string memory svgBody;
        for(uint256 i = 0; i < input.length; i++) {
            string memory svgString = input[i];
            string memory outValue;
            if(StringsLib.startsWith(svgString, matchTag)) {
                string memory restOfLine = StringsLib.substring(svgString, bytes(matchTag).length);
                uint256 replIndex = StringsLib.parseInt(restOfLine);
                outValue = repl[replIndex];
            } else {
                outValue = svgString;
            }
            svgBody = string(abi.encodePacked(svgBody, outValue));
        }
        return svgBody;
    }

    function replace(bytes[] memory sourceBytes, Replacement[] memory replacements_) public pure returns (string memory) {
        //bytes[] memory sourceBytes = _getSourceBytes();
        string memory outputFile = "";
        for (uint256 i = 0; i < sourceBytes.length; i++) {
            bytes memory sourceByte = sourceBytes[i];
            string memory outputLine  = string(sourceBytes[i]);
            for (uint256 j = 0; j < replacements_.length; j++) {
                Replacement memory replacement = replacements_[j];
                if (keccak256(sourceByte) == keccak256(bytes(replacement.matchString))) {
                    outputLine = replacement.replaceString;
                }
            }
            outputFile = string(abi.encodePacked(outputFile, outputLine));
        }
        return outputFile;
    }    
}