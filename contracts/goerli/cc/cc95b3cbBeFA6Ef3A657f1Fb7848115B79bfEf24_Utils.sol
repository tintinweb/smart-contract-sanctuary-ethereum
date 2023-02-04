//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Utils {
    /// @dev Create a pseudo random number
    function seed(uint256 nonce) public view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(msg.sender, block.coinbase, nonce))
        );
    }

    /// @dev Pseudorandom number based on input max bound
    function random(uint256 input, uint256 max) public pure returns (uint256) {
        return max - (uint256(keccak256(abi.encodePacked(input))) % max);
    }

    /// @dev Convert an integer to a string
    function uint2str(uint256 _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            ++len;
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

    /// @dev Get the smallest non zero number
    function minGt0(uint8 one, uint8 two) public pure returns (uint8) {
        return one > two
            ? two > 0
                ? two
                : one
            : two;
    }

    /// @dev Get the smallest number
    function min(uint8 one, uint8 two) public pure returns (uint8) {
        return one < two ? one : two;
    }

    /// @dev Get the average between two numbers
    function avg(uint8 one, uint8 two) public pure returns (uint8) {
        return (one & two) + (one ^ two) / 2;
    }

    /// @dev Get the days since another date (input is seconds)
    function day(uint256 from, uint256 to) public pure returns (uint16) {
        return uint16((to - from) / 86400 + 1);
    }
}