//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

library Utils {
    /// @dev Pseudorandom number based on input max bound
    function random(uint256 input, uint256 max) public pure returns (uint256) {
        return max - (uint256(keccak256(abi.encodePacked(input))) % max);
    }

    /// @dev Pseudorandom number based on input max bound and random number mixer
    function random(
        uint256 input,
        uint256 max,
        uint256 randomNum
    ) public pure returns (uint256) {
        return (uint256(
            keccak256(
                abi.encodePacked((input * randomNum) + (input * max) + input)
            )
        ) % max);
    }

    /// @dev Convert an integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
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

    /// @dev Compares two strings, returns true if different
    function strDiff(string memory str1, string memory str2)
        public
        pure
        returns (bool)
    {
        if (bytes(str1).length != bytes(str2).length) {
            return true;
        } else return false;
        // return
        //     keccak256(abi.encodePacked(str1)) !=
        //     keccak256(abi.encodePacked(str2));
    }

    /// @dev Get the smallest non zero number
    function minGt0(uint8 one, uint8 two) public pure returns (uint8) {
        return one > two ? two > 0 ? two : one : two;
    }

    /// @dev Get the smallest number
    function min(uint8 one, uint8 two) public pure returns (uint8) {
        return one < two ? one : two;
    }

    /// @dev Get the average between two numbers
    function avg(uint8 one, uint8 two) public pure returns (uint8) {
        return (one & two) + (one ^ two) / 2;
    }
}