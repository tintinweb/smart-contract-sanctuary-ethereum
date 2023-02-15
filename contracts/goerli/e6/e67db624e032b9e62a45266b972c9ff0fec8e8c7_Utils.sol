pragma solidity 0.8.14;

contract Create2Deployer {
    function mergeBytes(bytes memory param1, bytes memory param2)
        public
        pure
        returns (bytes memory)
    {
        bytes memory merged = new bytes(param1.length + param2.length);

        uint256 k = 0;
        for (uint256 i = 0; i < param1.length; i++) {
            merged[k] = param1[i];
            k++;
        }

        for (uint256 i = 0; i < param2.length; i++) {
            merged[k] = param2[i];
            k++;
        }
        return merged;
    }
}

library Utils {
    function stringToUint(string memory s) internal pure returns (uint256 result) {
        bytes memory b = bytes(s);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function stringToUint16(string memory s) public pure returns (uint16) {
        return uint16(stringToUint(s));
    }
}