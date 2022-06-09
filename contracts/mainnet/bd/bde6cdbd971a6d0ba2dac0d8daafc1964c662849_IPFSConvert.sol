// contracts/IPFSConvert.sol
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;


library IPFSConvert {

    bytes constant private CODE_STRING = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
    bytes constant private CIDV0HEAD = "\x00\x04\x28\x0b\x12\x17\x09\x28\x31\x00\x12\x04\x28\x20\x25\x25\x22\x31\x1b\x1d\x39\x29\x09\x26\x1b\x29\x0b\x02\x0a\x18\x25\x22\x24\x1b\x39\x2c\x1d\x39\x07\x06\x29\x25\x13\x15\x2c\x17";

    /**
     * @dev This function converts an 256 bits hash value into IPFS CIDv0 hash string.
     * @param _cidv0 256 bits hash value (not including the 0x12 0x20 signature)
     * @return IPFS CIDv0 hash string (Qm...)
     */
    function cidv0FromBytes32(bytes32 _cidv0) public pure returns (string memory) {
        unchecked {
            // convert to base58
            bytes memory result = new bytes(46);        // 46 is the longest possible base58 result from CIDv0
            uint256 resultLen = 45;
            uint256 number = uint256(_cidv0);
            while(number > 0) {
                uint256 rem = number % 58;
                result[resultLen] = bytes1(uint8(rem));
                resultLen--;
                number = number / 58;
            }

            // add 0x1220 in front of _cidv0
            uint256 i;
            for (i = 0; i < 46; i++) {
                uint8 r = uint8(result[45 - i]) + uint8(CIDV0HEAD[i]);
                if (r >= 58) {
                    result[45 - i] = bytes1(r - 58);
                    result[45 - i - 1] = bytes1(uint8(result[45 - i - 1]) + 1);
                }
                else {
                    result[45 - i] = bytes1(r);
                }
            }

            // convert to characters
            for (i = 0; i < 46; i++) {
                result[i] = CODE_STRING[uint8(result[i])];
            }

            return string(result);
        }
    }
}