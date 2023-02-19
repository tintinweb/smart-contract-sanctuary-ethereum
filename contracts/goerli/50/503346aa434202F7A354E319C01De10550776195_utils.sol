// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library utils {
    function uint2str(
        uint256 _i
    ) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function seconds2str(uint256 _seconds) internal pure returns (string memory) {
        uint _years = _seconds / 31536000;
        _seconds -= _years * 31536000;

        uint _weeks = _seconds / 604800;
        _seconds -= _weeks * 604800;

        uint _days = _seconds / 86400;
        _seconds -= _days * 86400;

        uint _hours = _seconds / 3600;
        _seconds -= _hours * 3600;

        uint _minutes = _seconds / 60;
        _seconds -= _minutes * 60;

        uint _secondsRemaining = _seconds;
        
        return string(abi.encodePacked(format4Digits(_years), format2Digits(_weeks), uint2str(_days), format2Digits(_hours), format2Digits(_minutes), format2Digits(_secondsRemaining)));
    }

    function format2Digits(uint value) private pure returns (string memory) {
        if (value < 10) {
            return string(abi.encodePacked("0", value));
        } else {
            return uint2str(value);
        }
    }

    function format4Digits(uint value) private pure returns (string memory) {
        string memory result = uint2str(value);
        uint length = bytes(result).length;
        if (length < 4) {
            string memory prefix = "";
            for (uint i = 0; i < 4 - length; i++) {
                prefix = string(abi.encodePacked(prefix, "0"));
            }
            result = string(abi.encodePacked(prefix, result));
        }
        return result;
    }

    // Get a pseudo random number
    function random(uint256 input, uint256 min, uint256 max) internal pure returns (uint256) {
        uint256 randRange = max - min;
        return max - (uint256(keccak256(abi.encodePacked(input + 2023))) % randRange) - 1;
    }

    function initValue(uint256 tokenId) internal pure returns (uint256 value) {
        if (tokenId < 1000) {
            value = random(tokenId, 3600, 50 * 3600);
        } else if (tokenId < 2000) {
            value = random(tokenId, 3600, 45 * 3600);
        }  else if (tokenId < 3000) {
            value = random(tokenId, 3600, 40 * 3600);
        }  else if (tokenId < 4000) {
            value = random(tokenId, 3600, 35 * 3600);
        }  else if (tokenId < 5000) {
            value = random(tokenId, 3600, 30 * 3600);
        }  else if (tokenId < 6000) {
            value = random(tokenId, 3600, 25 * 3600);
        }  else if (tokenId < 7000) {
            value = random(tokenId, 3600, 20 * 3600);
        }  else if (tokenId < 8000) {
            value = random(tokenId, 3600, 15 * 3600);
        }  else if (tokenId < 9000) {
            value = random(tokenId, 3600, 10 * 3600);
        }  else {
            value = random(tokenId, 3600, 5 * 3600);
        }
        return value;
    }

    function getRgbs(uint tokenId, uint baseColor) internal pure returns (uint256[3] memory rgbValues) {
        if (baseColor > 0) {
            for (uint i = 0; i < 3; i++) {
                if (baseColor == i + 1) {
                    rgbValues[i] = 255;
                } else {
                    rgbValues[i] = utils.random(tokenId + i, 0, 256);
                }
            }
        } else {
            for (uint i = 0; i < 3; i++) {
                rgbValues[i] = 255;
            }
        }
        return rgbValues;
    }

    function getMintPhase(uint tokenId) internal pure returns (uint mintPhase) {
        if (tokenId <= 1000) {
            mintPhase = 1;
        } else if (tokenId <= 5000) {
            mintPhase = 2;
        } else {
            mintPhase = 3;
        }
    }

    function secondsRemaining(uint end) internal view returns (uint) {
        if (block.timestamp <= end) {
            return end - block.timestamp;
        } else {
            return 0;
        }
    }

    function minutesRemaining(uint end) internal view returns (uint) {
        if (secondsRemaining(end) >= 60) {
            return (end - block.timestamp) / 60;
        } else {
            return 0;
        }
    }
}