pragma solidity ^0.8.1;
// SPDX-License-Identifier: MIT
library SeapadHelper {
    function toAsciiString(address x) public pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) public pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function uint2str(uint256 _i)
        public
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

    function stringToBytes32(string memory source)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function getPathToTokenFromTokenThroughEth(
        address inputToken,
        address wethAddress,
        address outputToken
    ) public pure returns (address[] memory) {
        address[] memory path = new address[](3);
        path[0] = inputToken;
        path[1] = wethAddress;
        path[2] = outputToken;
        return path;
    }

    function getPathToTokenFromToken(address inputToken, address outputToken)
        public
        pure
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = outputToken;
        return path;
    }

    function getPathToEth(address token, address wethAddress)
        public
        pure
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = wethAddress;
        return path;
    }

    function getPathForToken(address token, address wethAddress)
        public
        pure
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = wethAddress;
        path[1] = address(token);
        return path;
    }
}