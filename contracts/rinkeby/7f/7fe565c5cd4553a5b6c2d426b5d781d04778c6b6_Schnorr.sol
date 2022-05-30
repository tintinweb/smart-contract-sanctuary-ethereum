/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity  >=0.7.0 <0.9.0;

contract Schnorr {
    function encodeMessage(uint256 chainID, bytes32 uniqueID, uint tokenPairID, uint value, address tokenAccount, address userAccount) public pure returns (bytes32 message) {
        message = sha256(abi.encode(chainID, uniqueID, tokenPairID, value, tokenAccount, userAccount));
    }

    /// @notice       convert bytes to bytes32
    /// @param b      bytes array
    /// @param offset offset of array to begin convert
    function bytesToBytes32(bytes memory b, uint offset) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(add(b, offset), 32))
        }
    }

    function parseBytes64(bytes memory dataBytes64) public pure returns (bytes32 x, bytes32 y) {
        x = bytesToBytes32(dataBytes64, 0);
        y = bytesToBytes32(dataBytes64, 32);
    }

    function parseData(uint256 chainID, bytes32 uniqueID, uint tokenPairID, uint value, address tokenAccount, address userAccount, bytes memory PK, bytes memory R, bytes32 inputS) public pure returns (bytes32 s, bytes32 PKx, bytes32 PKy, bytes32 Rx, bytes32 Ry, bytes32 message) {
        s = inputS;
        (PKx, PKy) = parseBytes64(PK);
        (Rx, Ry) = parseBytes64(R);
        message = encodeMessage(chainID, uniqueID, tokenPairID, value, tokenAccount, userAccount);
    }
}