// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library Utility {
    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        bytes memory s = new bytes(64);

        for (uint8 i = 0; i < 32; i++) {
            bytes1 b = bytes1(_bytes32[i]);
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));

            if (hi < 0x0A) {
                s[i * 2] = bytes1(uint8(hi) + 0x30);
            } else {
                s[i * 2] = bytes1(uint8(hi) + 0x57);
            }

            if (lo < 0x0A) {
                s[i * 2 + 1] = bytes1(uint8(lo) + 0x30);
            } else {
                s[i * 2 + 1] = bytes1(uint8(lo) + 0x57);
            }
        }

        return string(s);
    }

    function strToUint(string memory _str) public pure returns (uint256 res) {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if (
                (uint8(bytes(_str)[i]) - 48) < 0 ||
                (uint8(bytes(_str)[i]) - 48) > 9
            ) {
                return 0;
            }
            res +=
                (uint8(bytes(_str)[i]) - 48) *
                10**(bytes(_str).length - i - 1);
        }

        return res;
    }

    function uintToStr(uint256 _i)
        public
        pure
        returns (string memory _uintAsString)
    {
        uint256 number = _i;
        if (number == 0) {
            return "0";
        }
        uint256 j = number;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (number >= 10) {
            bstr[k--] = bytes1(uint8(48 + (number % 10)));
            number /= 10;
        }
        bstr[k] = bytes1(uint8(48 + (number % 10)));
        return string(bstr);
    }

    function addressToStr(address _address)
        public
        pure
        returns (string memory)
    {
        bytes32 _bytes = bytes32((uint256(uint160(_address))));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);

        _string[0] = "0";
        _string[1] = "x";

        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_string);
    }

    function compareSeed(string memory seedHash, string memory seed)
        public
        pure
        returns (bool)
    {
        string memory hash = bytes32ToString(sha256(abi.encodePacked(seed)));

        if (
            keccak256(abi.encodePacked(hash)) ==
            keccak256(abi.encodePacked(seedHash))
        ) {
            return true;
        } else {
            return false;
        }
    }
}