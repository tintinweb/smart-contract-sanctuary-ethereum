/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.4;

contract VerifyPoC {
    function verifySerialized(bytes memory message, bytes memory signature) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // Singature need to be 65 in length
            // if (signature.length !== 65) revert();
            if iszero(eq(mload(signature), 65)) {
                revert(0, 0)
            }
            // r = signature[:32]
            // s = signature[32:64]
            // v = signature[64]
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
            // Invalid v value, for Ethereum it's only possible to be 27, 28 and 0, 1 in legacy code
            if lt(v, 27) {
                v := add(v, 27)
            }
            if iszero(or(eq(v, 27), eq(v, 28))) {
                revert(0, 0)
            }
        }

        // Get hashes of message with Ethereum proof prefix
        bytes32 hashes = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", uintToStr(message.length), message));

        return ecrecover(hashes, v, r, s);
    }

    function verify(bytes memory message, bytes32 r, bytes32 s, uint8 v) public pure returns (address) {
        if(v < 27) {
            v += 27;
        }
        // V must be 27 or 28
        require(v == 27 || v == 28, "Invalid v value");
        // Get hashes of message with Ethereum proof prefix
        bytes32 hashes = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", uintToStr(message.length), message));

        return ecrecover(hashes, v, r, s);
    }

    function uintToStr(uint256 value) public pure returns (bytes memory result) {
        assembly {
            switch value
                case 0 {
                    // In case of 0, we just return "0"
                    result := mload(0x20)
                    // result.length = 1
                    mstore(result, 0x01)
                    // result = "0"
                    mstore(add(result, 0x20), 0x30)
                }
                default {
                    let length := 0x0
                    // let result = new bytes(32)
                    result := mload(0x20)

                    // Get length of render number
                    // for (let v := value; v > 0; v = v / 10)
                    for { let v := value } gt(v, 0x00) { v := div(v, 0x0a) } {
                        length := add(length, 0x01)
                    }

                    // We're only support number with 32 digits
                    // if (length > 32) revert();
                    if gt(length, 0x20) {
                        revert(0, 0)
                    }

                    // Set length of result
                    mstore(result, length)

                    // Start render result
                    // for (let v := value; length > 0; v = v / 10)
                    for { let v := value } gt(length, 0x00) { v := div(v, 0x0a) } {
                        // result[--length] = 48 + (v % 10)
                        length := sub(length, 0x01)
                        mstore8(add(add(result, 0x20), length), add(0x30, mod(v, 0x0a)))
                    }
                }
        }
    }
}