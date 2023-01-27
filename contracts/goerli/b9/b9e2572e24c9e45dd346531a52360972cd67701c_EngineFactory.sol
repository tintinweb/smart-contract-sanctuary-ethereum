// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any (single) token transfer. This includes minting and burning.
     * See {_beforeConsecutiveTokenTransfer}.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any (single) transfer of tokens. This includes minting and burning.
     * See {_afterConsecutiveTokenTransfer}.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called before consecutive token transfers.
     * Calling conditions are similar to {_beforeTokenTransfer}.
     *
     * The default implementation include balances updates that extensions such as {ERC721Consecutive} cannot perform
     * directly.
     */
    function _beforeConsecutiveTokenTransfer(
        address from,
        address to,
        uint256, /*first*/
        uint96 size
    ) internal virtual {
        if (from != address(0)) {
            _balances[from] -= size;
        }
        if (to != address(0)) {
            _balances[to] += size;
        }
    }

    /**
     * @dev Hook that is called after consecutive token transfers.
     * Calling conditions are similar to {_afterTokenTransfer}.
     */
    function _afterConsecutiveTokenTransfer(
        address, /*from*/
        address, /*to*/
        uint256, /*first*/
        uint96 /*size*/
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/lib/Structs.sol';
import '@dex/lib/FinMath.sol';

import '@dex/perp/interfaces/IConfig.sol';

import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library FeesMath {
    using FinMath for uint256;
    using FinMath for uint24;
    using FinMath for int24;

    // @dev External function used in engine
    function computePremiumAndFee(
        Order storage o,
        PriceData memory p,
        int24 premiumBps,
        IConfig config,
        uint8 minPremiumFeeDiscountPerc
    ) public view returns (int256 premium, uint256 premiumFee) {
        uint256 notional = o.amount.wmul(p.price);
        premium = premiumBps.bps(notional);
        int256 fee = config.premiumFeeBps().bps(premium);
        int256 _minPremiumFee = int256(
            (config.getAmounts().minPremiumFee *
                uint256((minPremiumFeeDiscountPerc))) / 100
        );
        premiumFee = uint256((fee > _minPremiumFee) ? fee : _minPremiumFee);
    }

    // @dev External function used in engine.
    function traderFees(
        Order storage o,
        PriceData memory p,
        IConfig config
    ) external view returns (uint256) {
        uint256 notional = o.amount.wmul(p.price);
        int256 fee = config.traderFeeBps().bps(int256(notional));
        return uint256(fee);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/lib/SafeCast.sol';
// Percentage using BPS
// https://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency/3730040#3730040
// Ranges:
// int(x): -2^(x-1) to [2^(x-1)]-1
// uint(x): 0 to [2^(x)]-1

// @notice Simple multiplication with native overflow protection for uint when
// using solidity above 0.8.17.
library FinMath {
    using SafeCast for uint256;
    using SafeCast for int256;

    // Bps
    int256 public constant iBPS = 10**4; // basis points [TODO: move to 10**4]
    uint256 public constant uBPS = 10**4; // basis points [TODO: move to 10**4]

    // Fixed Point arithimetic
    uint256 constant WAD = 10**18;
    int256 constant iWAD = 10**18;
    uint256 constant LIMIT = 2**255;

    int256 internal constant iMAX_128 = 0x100000000000000000000000000000000; // 2^128
    int256 internal constant iMIN_128 = -0x100000000000000000000000000000000; // 2^128
    uint256 internal constant uMAX_128 = 0x100000000000000000000000000000000; // 2^128

    // --- SIGNED CAST FREE

    function mul(int256 x, int256 y) internal pure returns (int256 z) {
        z =  x * y;
    }
    function div(int256 a, int256 b) internal pure returns (int256 z) {
        z =  a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256 z) {
        z =  a - b;
    }
    function add(int256 a, int256 b) internal pure returns (int256 z) {
        z =  a + b;
    }

    // --- UNSIGNED CAST FREE

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 z) {
        z =  a / b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 z) {
        z =  a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 z) {
        z =  a - b;
    }

    // --- MIXED TYPES SAFE CAST

    function add(uint256 x, int256 y) internal pure returns (uint256 z) {
        bool flip = y < 0 ? true : false;
        z = flip ? x - (-y).u256() : x + y.u256();
    }
    function add(int256 x, uint256 y) internal pure returns (int256 z) {
        z = x + y.i256();
    }
    function sub(uint256 x, int256 y) internal pure returns (uint256 z) {
        bool flip = y < 0 ? true : false;
        z = flip ? x + (-y).u256() : x - y.u256();
    }
    function isub(uint256 x, uint256 y) internal pure returns (int256 z) {
        int256 x1 = x.i256();
        int256 y1 = y.i256();
        z = x1 - y1;
    }

    // --- FIXED POINT [1e18 precision]

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function wmul(int256 x, int256 y) internal pure returns (int256 z) {
        z = add(mul(x, y), int256(WAD) / 2) / iWAD;
    }
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }


    // --- FIXED POINT BPS [1e4 precision]

    // @notice Calculate percentage using BPS precision
    // @param bps input in base points
    // @param x the number we want to calculate percentage
    // @return the % of the x including fixed-point arithimetic
    function bps(int256 bp, uint256 x) internal pure returns (int256 z) {
        require(bp < iMAX_128, 'bps-x-overflow');
        z = (mul(x.i256(), bp)) / iBPS;
    }

    function bps(uint256 bp, uint256 x) internal pure returns (uint256 z) {
        require(bp < uMAX_128, 'bps-x-overflow');
        z = mul(x, bp) / uBPS;
    }

    function bps(uint256 bp, int256 x) internal pure returns (int256 z) {
        require(bp < uMAX_128, 'bps-x-overflow');
        z = mul(x, bp.i256()) / iBPS;
    }

    function bps(int256 bp, int256 x) internal pure returns (int256 z) {
        require(bp < iMAX_128, 'bps-x-overflow');
        z = mul(x, bp) / iBPS;
    }

    function ibps(uint256 bp, uint256 x) internal pure returns (int256 z) {
        require(bp < uMAX_128, 'bps-x-overflow');
        z = (mul(x, bp) / uBPS).i256();
    }

    // @dev Transform to BPS precision
    function bps(uint256 x) internal pure returns (uint256) {
        return mul(x, uBPS);
    }

    // @notice Return the positive number of an int256 or zero if it was negative
    // @parame x the number we want to normalize
    // @return zero or a positive number
    function pos(int256 a) internal pure returns (uint256) {
        return (a >= 0) ? uint256(a) : 0;
    }

    // @notice somethimes we need to print int but cast them to uint befor
    function inv(int256 x) internal pure returns (uint256 z) {
        z = x < 0 ? uint256(-x) : uint256(x);
    }


    // --- MINIMUM and MAXIMUM

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './Positions.sol';
import '@dex/lib/LeverageMath.sol';
import '@dex/lib/Structs.sol';
import '@dex/lib/FinMath.sol';
import '@dex/perp/interfaces/IVault.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

error Inexistent(uint256);

library JoinLib {
    using FinMath for uint24;
    using FinMath for int256;
    using FinMath for uint256;

    using LeverageMath for Match;

    event MatchInexistant(uint256 indexed matchId, uint256 indexed orderId);
    event MakerIsTrader(
        uint256 indexed matchId,
        address indexed maker,
        uint256 orderId
    );
    event LowTraderCollateral(
        uint256 indexed matchId,
        address indexed trader,
        uint256 orderId,
        uint256 traderCollateral,
        uint256 collateralNeeded
    );

    event LowMakerCollateralForFees(
        uint256 indexed matchId,
        address indexed maker,
        uint256 orderId,
        uint256 allocatedCollateral,
        uint256 makerFees
    );

    event LowTraderCollateralForFees(
        uint256 indexed matchId,
        address indexed trader,
        uint256 orderId,
        uint256 allocatedCollateral,
        uint256 traderFees
    );

    event MaxOpeningLeverage(
        address indexed user,
        uint256 matchId,
        uint256 orderId,
        uint256 price
    );

    event LowMakerCollateral(
        uint256 indexed matchId,
        address indexed maker,
        uint256 orderId,
        uint256 makerCollateral,
        uint256 collateralNeeded
    );

    event OrderExpired(
        uint256 indexed matchId,
        address indexed trader,
        address indexed maker,
        uint256 orderId,
        uint256 orderTimestamp
    );

    // @notice Sometimes the trader choose a position size smaller than the picked
    // maker position, so we have to ajust the collateral and amount accordingly.
    function normalize(Match memory m, uint256 amount)
        public
        pure
        returns (Match memory)
    {
        if (amount < m.amount) {
            m.collateralM = ((m.collateralM.mul(amount)) / m.amount);
            m.amount = amount;
        }
        return m;
    }

    function beforeChecks(
        Match memory m,
        Order memory o,
        uint256 orderId,
        address maker,
        uint256 balance,
        int256 feesM,
        int256 feesT
    ) public returns (bool) {
        // check if order is canceled or has already been matched
        if (o.canceled) return false;
        if (m.trader != 0) return false;

        if (o.owner == maker) {
            emit MakerIsTrader(o.matchId, maker, orderId);
            return false;
        }

        if (balance < o.collateral) {
            emit LowTraderCollateral(
                o.matchId,
                o.owner,
                orderId,
                balance,
                o.collateral
            );
            return false;
        }

        if (int256(o.collateral) <= feesT) {
            emit LowTraderCollateralForFees(
                o.matchId,
                o.owner,
                orderId,
                o.collateral,
                uint256(feesT)
            );
            return false;
        }

        if (int256(m.collateralM) <= feesM) {
            emit LowMakerCollateralForFees(
                o.matchId,
                maker,
                orderId,
                m.collateralM,
                uint256(feesM)
            );
            return false;
        }

        return true;
    }

    struct AfterCheck {
        PriceData priceData;
        IConfig config;
        IVault vault;
        address maker;
        address trader;
        uint256 matchId;
        uint256 orderId;
        uint256 maxTimestamp;
        uint8 tokenDecimals;
    }

    function afterChecks(Match memory m, AfterCheck calldata params)
        public
        returns (bool)
    {
        if (
            m.isOverLeveraged_(
                params.priceData,
                params.config,
                false,
                params.tokenDecimals
            )
        ) {
            emit MaxOpeningLeverage(
                params.trader,
                params.matchId,
                params.orderId,
                params.priceData.price
            );
            return false;
        }

        if (
            m.isOverLeveraged_(
                params.priceData,
                params.config,
                true,
                params.tokenDecimals
            )
        ) {
            emit MaxOpeningLeverage(
                params.maker,
                params.matchId,
                params.orderId,
                params.priceData.price
            );
            return false;
        }

        if (params.vault.collateral(params.maker) < m.collateralM) {
            emit LowMakerCollateral(
                params.matchId,
                params.maker,
                params.orderId,
                params.vault.collateral(params.maker),
                m.collateralM
            );
            return false;
        }

        if (
            params.maxTimestamp != 0 &&
            params.priceData.timestamp > params.maxTimestamp
        ) {
            emit OrderExpired(
                params.matchId,
                params.trader,
                params.maker,
                params.orderId,
                params.maxTimestamp
            );
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/lib/Structs.sol';
import '@dex/lib/PnLMath.sol';
import '@dex/lib/FinMath.sol';

import '@dex/perp/interfaces/IConfig.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library LeverageMath {
    using FinMath for uint256;
    using FinMath for int256;
    using PnLMath for Match;

    // TODO: move min/max to be used from FinMath
    function _min(uint256 a, uint256 b) internal pure returns (uint256 res) {
        res = (a <= b) ? a : b;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256 res) {
        res = (a >= b) ? a : b;
    }

    // @dev External function.
    function isOverLeveraged(
        Match storage m,
        PriceData calldata priceData,
        IConfig config,
        bool isMaker,
        uint8 collateralDecimals
    ) public view returns (bool) {
        return
            isOverLeveraged_(m, priceData, config, isMaker, collateralDecimals);
    }

    function isOverLeveraged_(
        Match memory m,
        PriceData calldata priceData,
        IConfig config,
        bool isMaker,
        uint8 collateralDecimals
    ) public view returns (bool) {
        Leverage memory leverage = config.getLeverage();
        uint256 timeElapsed = m.start == 0 ? 0 : block.timestamp - m.start;
        return
            getLeverage(m, priceData, isMaker, 0, collateralDecimals) >
            (
                isMaker
                    ? getMaxLeverage(
                        config,
                        m.frPerYear,
                        timeElapsed == 0
                            ? block.timestamp - priceData.timestamp
                            : timeElapsed
                    )
                    : timeElapsed == 0
                    ? leverage.maxLeverageOpen
                    : leverage.maxLeverageOngoing
            );
    }

    // @dev Internal function
    function getMaxLeverage(
        IConfig config,
        uint256 fr,
        uint256 timeElapsed
    ) public view returns (uint256 maxLeverage) {
        // console.log("[_getMaxLeverage()] fr >= fmfr --> ", fr >= fmfr);
        // console.log("[_getMaxLeverage()] timeElapsed >= leverage.maxTimeGuarantee --> ", timeElapsed >= leverage.maxTimeGuarantee);
        Leverage memory leverage = config.getLeverage();
        // NOTE: Expecting time elapsed in days
        timeElapsed = timeElapsed / 86400;
        maxLeverage = ((fr >= config.fmfrPerYear()) ||
            (timeElapsed >= leverage.maxTimeGuarantee))
            ? (timeElapsed == 0)
                ? leverage.maxLeverageOpen
                : leverage.maxLeverageOngoing
            : _min(
                _max(
                    ((leverage.s * leverage.FRTemporalBasis * leverage.b)
                        .bps() /
                        ((leverage.maxTimeGuarantee - timeElapsed) *
                            (config.fmfrPerYear() - fr + leverage.f0))),
                    leverage.minGuaranteedLeverage
                ),
                leverage.maxLeverageOpen
            );
        // maxLeverage = (fr >= fmfr) ? type(uint256).max : (minRequiredMargin * timeToExpiry / (totTime * (fmfr - fr)));
    }

    // @dev Internal function
    // NOTE: For leverage, notional depends on entryPrice while accruedFR is transformed into collateral using currentPrice
    // Reasons
    // LP Pool risk is connected to Makers' Leverage
    // (even though we have a separate check for liquidation, we use leverage to control collateral withdrawal)
    // so higher leverage --> LP Pool risk increases
    // Makers' are implicitly always long market for the accruedFR component
    // NOTE: The `overrideAmount` is used in `join()` since we split after having done a bunch of checks so the `m.amount` is not the correct one in that case
    function getLeverage(
        Match memory m,
        PriceData calldata priceData,
        bool isMaker,
        uint256 overrideAmount,
        uint8 collateralDecimals
    ) public view returns (uint256 leverage) {
        // NOTE: This is correct almost always with the exception of the levarge computation
        // for the maker when they submit an order which is not picked yet and
        // as a consquence we to do not have an entryPrice yet so we use currentPrice
        uint256 notional = (10**(collateralDecimals))
            .wmul((overrideAmount > 0) ? overrideAmount : m.amount)
            .wmul(
                (isMaker && (m.trader == 0)) ? priceData.price : m.entryPrice
            );
        uint256 realizedPnL = m.accruedFR(priceData, collateralDecimals);
        uint256 collateral_plus_realizedPnL = (isMaker)
            ? m.collateralM + realizedPnL
            : m.collateralT - _min(m.collateralT, realizedPnL);
        if (collateral_plus_realizedPnL == 0) return type(uint256).max;

        // TODO: this is a simplification when removing the decimals lib,
        //       need to check and move to FinMath lib
        leverage = notional.bps() / collateral_plus_realizedPnL;
    }
}

pragma solidity ^0.8.17;

import '@base64/base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

library NFTDescriptor {
    function constructTokenURI(
        uint256 tokenId
    ) public pure returns (string memory) {
        string memory name = string.concat(
            'test name: ',
            Strings.toString(tokenId)
        );
        string memory descriptionPartOne = 'test description part 1';
        string memory descriptionPartTwo = 'test description part 2';
        string memory image = Base64.encode(bytes(generateSVGImage()));

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                descriptionPartOne,
                                descriptionPartTwo,
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateSVGImage() internal pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    '<?xml version="1.0" encoding="UTF-8"?>',
                    '<svg version="1.1" viewBox="50 20 600 600" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    '<g>',
                    '<path d="m589.12 253.12h-82.883c-7.8398 0-15.121 3.3594-20.16 8.9609l-13.441 15.68-24.641-56c-6.1602-13.441-21.84-19.602-35.281-14-13.441 6.1602-19.602 21.84-14 35.281l41.441 94.641c3.9219 8.3984 11.199 14.559 20.719 15.68 1.1211 0 2.8008 0.55859 3.9219 0.55859 7.8398 0 15.121-3.3594 20.16-8.9609l33.039-38.078h70.559c14.559 0 26.879-11.762 26.879-26.879 0.56641-14.562-11.195-26.883-26.312-26.883z"/>',
                    '<path d="m353.92 221.76c-6.1602-13.441-21.84-19.602-35.281-14-13.441 6.1602-19.602 21.84-14 35.281l41.441 94.641c4.4805 10.078 14.559 16.238 24.641 16.238 3.3594 0 7.2812-0.55859 10.641-2.2383 13.441-6.1602 19.602-21.84 14-35.281z"/>',
                    '<path d="m259.28 221.76c-3.9219-8.3984-11.199-14.559-20.719-15.68-8.9609-1.6797-18.48 1.6797-24.078 8.9609l-33.039 38.078h-70.566c-14.559 0-26.879 11.762-26.879 26.879 0 14.559 11.762 26.879 26.879 26.879h82.879c7.8398 0 15.121-3.3594 20.16-8.9609l13.441-15.68 24.641 56c4.4805 10.078 14.559 16.238 24.641 16.238 3.3594 0 7.2812-0.55859 10.641-2.2383 13.441-6.1602 19.602-21.84 14-35.281z"/>',
                    '</g>',
                    '</svg>'
                )
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './Positions.sol';
import '@dex/lib/LeverageMath.sol';
import '@dex/lib/Structs.sol';
import '@dex/perp/interfaces/IConfig.sol';
import '@dex/lib/FinMath.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library PnLMath {
    using FinMath for uint24;
    using FinMath for int256;
    using FinMath for uint256;

    // NOTE: Need to move this computation out of `pnl()` to avoid the stack too deep issue in it
    function _gl(
        uint256 amount,
        int256 dp,
        uint256 collateralDecimals
    ) internal pure returns (int256 gl) {
        gl = int256(10**(collateralDecimals)).wmul(int256(amount)).wmul(dp); // Maker's GL
    }

    function pnl(
        Match memory m,
        uint256 tokenId,
        uint256 timestamp,
        uint256 exitPrice,
        uint256 makerFRFee,
        uint8 collateralDecimals
    )
        public
        pure
        returns (
            int256 pnlM,
            int256 pnlT,
            uint256 FRfee
        )
    {
        require(timestamp > m.start, 'engine/wrong_timestamp');
        require(
            (tokenId == m.maker) || (tokenId == m.trader),
            'engine/invalid-tokenId'
        );
        // uint deltaT = timestamp.sub(m.start);
        // int deltaP = exitPrice.isub(m.entryPrice);
        // int delt = (m.pos == POS_SHORT) ? -deltaP : deltaP;

        // NOTE: FR is seen from the perspective of the maker and it is >= 0 always by construction
        uint256 aFR = _accruedFR(
            timestamp.sub(m.start),
            m.frPerYear,
            m.amount,
            exitPrice,
            collateralDecimals
        );

        // NOTE: `m.pos` is the Maker Position
        int256 mgl = (((m.pos == POS_SHORT) ? int256(-1) : int256(1)) *
            _gl(m.amount, exitPrice.isub(m.entryPrice), collateralDecimals));

        // NOTE: Before deducting FR Fees, the 2 PnLs need to be symmetrical
        pnlM = mgl + int256(aFR);
        pnlT = -pnlM;

        // NOTE: After the FR fees, no more symmetry
        FRfee = makerFRfees(makerFRFee, aFR);
        pnlM -= int256(FRfee);
    }

    function makerFRfees(uint256 makerFRFee, uint256 fundingRate)
        internal
        pure
        returns (uint256)
    {
        return makerFRFee.bps(fundingRate);
    }

    function accruedFR(
        Match memory m,
        PriceData memory priceData,
        uint8 collateralDecimals
    ) public view returns (uint256) {
        if (m.start == 0) return 0;
        uint256 deltaT = block.timestamp.sub(m.start);
        return
            _accruedFR(
                deltaT,
                m.frPerYear,
                m.amount,
                priceData.price,
                collateralDecimals
            );
    }

    function _accruedFR(
        uint256 deltaT,
        uint256 frPerYear,
        uint256 amount,
        uint256 price,
        uint8 collateralDecimals
    ) public pure returns (uint256) {
        return
            (10**(collateralDecimals))
                .mul(frPerYear)
                .bps(deltaT)
                .wmul(amount)
                .wmul(price) / (3600 * 24 * 365);
    }

    // TODO: move return value to a threshold numerical one and add the threshold on config
    function isLiquidatable(
        Match storage m,
        uint256 tokenId,
        uint256 price,
        IConfig config,
        uint8 collateralDecimals
    ) external view returns (bool) {
        // check if the match has not previously been deleted
        if (m.maker == 0) return false;
        if (tokenId == m.maker) {
            (int256 pnlM, , ) = pnl(
                m,
                tokenId,
                block.timestamp,
                price,
                0,
                collateralDecimals
            ); // TODO: add makerFee
            int256 bufferMaker = config.bufferMakerBps().ibps(m.collateralM);
            return
                int256(m.collateralM) + pnlM - bufferMaker <
                int256(config.bufferMaker());
        } else if (tokenId == m.trader) {
            (, int256 pnlT, ) = pnl(
                m,
                tokenId,
                block.timestamp,
                price,
                0,
                collateralDecimals
            ); // TODO: add maker fee
            int256 bufferTrader = config.bufferTraderBps().ibps(m.collateralT);
            return
                int256(m.collateralT) + pnlT - bufferTrader <
                int256(config.bufferTrader());
        } else {
            return false;
        }
    }
}

pragma solidity ^0.8.17;

int8 constant POS_SHORT = -1;
int8 constant POS_NEUTRAL = 0;
int8 constant POS_LONG = 1;

// SPDX-License-Identifier: GPL-2.0-or-later
// Uniswap lib
pragma solidity 0.8.17;

// @title Safe casting methods
// @notice Contains methods for safely casting between types
library SafeCast {
    // @notice Cast a uint256 to a uint160, revert on overflow
    // @param y The uint256 to be downcasted
    // @return z The downcasted integer, now type uint160
    function u160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y, 'cast-u160');
    }

    // @notice Cast a int256 to a int128, revert on overflow or underflow
    // @param y The int256 to be downcasted
    // @return z The downcasted integer, now type int128
    function i128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y, 'cast-i128');
    }

    // @notice Cast a uint256 to a int256, revert on overflow
    // @param y The uint256 to be casted
    // @return z The casted integer, now type int256
    function i256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255, 'cast-i256');
        z = int256(y);
    }

    // @notice Cast an int256, check if it's not negative
    // @param y The uint256 to be downcasted
    // @return z The downcasted integer, now type uint160
    function u256(int256 y) internal pure returns (uint256 z) {
        require(y >= 0, 'cast-u256');
        z = uint256(y);
    }

}

pragma solidity ^0.8.17;

struct Match {
    int8 pos; // If maker is short = true
    int24 premiumBps; // In percent of the amount
    uint24 frPerYear;
    uint24 fmfrPerYear; // The fair market funding rate when the match was done
    uint256 maker; // maker vault token-id
    uint256 trader; // trader vault token-id
    uint256 amount;
    uint256 start; // timestamp of the match starting
    uint256 entryPrice;
    uint256 collateralM; // Maker  collateral
    uint256 collateralT; // Trader collateral
    uint8 minPremiumFeeDiscountPerc;    // To track what perc of minPreomiumFee to pay, used when the order is split
    bool close;  // A close request for this match is pending
}

struct Order {
    bool canceled;
    int8 pos;
    address owner; // trader address
    uint256 tokenId;
    uint256 matchId; // trader selected matchid
    uint256 amount;
    uint256 collateral;
    uint256 collateralAdd;
    // NOTE: Used to apply the check for the Oracle Latency Protection
    uint256 timestamp;
    // NOTE: In this case, we give trader the max full control on the price for matching: no assumption it is symmetric and we do not compute any percentage so introducing some approximations, the trader writes the desired prices
    uint256 slippageMinPrice;
    uint256 slippageMaxPrice;
    uint256 maxTimestamp;
}

struct CloseOrder {
    uint256 matchId;
    uint256 timestamp;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IOracle.sol';

contract GelatoOracle is IOracle, Ownable {
    PriceData lastPrice;
    /// @notice min price deviation to accept a price update
    uint256 public deviation;
    address public dataProvider;
    uint8 _decimals;
    /// @notice heartbeat duration in seconds
    uint40 public heartBeat;

    modifier ensurePriceDeviation(uint256 newValue) {
        if (_computeDeviation(newValue) > deviation) {
            _;
        }
    }

    function _computeDeviation(
        uint256 newValue
    ) internal view returns (uint256) {
        if (lastPrice.price == 0) {
            return deviation + 1; // return the deviation amount if price is 0, so that the update will happen
        } else if (newValue > lastPrice.price) {
            return ((newValue - lastPrice.price) * 1e20) / lastPrice.price;
        } else {
            return ((lastPrice.price - newValue) * 1e20) / lastPrice.price;
        }
    }

    constructor() {}

    function initialize(
        uint256 deviation_,
        uint8 decimals_,
        uint40 heartBeat_,
        address dataProvider_
    ) external {
        _decimals = decimals_;
        deviation = deviation_;
        heartBeat = heartBeat_;
        dataProvider = dataProvider_;
        _transferOwnership(msg.sender);
    }

    // to be called by gelato bot to know if a price update is needed
    function isPriceUpdateNeeded(
        uint256 newValue
    ) external view returns (bool) {
        if ((lastPrice.timestamp + heartBeat) < block.timestamp) {
            return true;
        } else if (_computeDeviation(newValue) > deviation) {
            return true;
        }
        return false;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function setPrice(uint256 _value) external onlyOwner {
        lastPrice.price = uint128(_value);
        lastPrice.timestamp = uint128(block.timestamp);

        emit NewValue(lastPrice.price, lastPrice.timestamp);
    }

    function getPrice() external view override returns (PriceData memory) {
        return lastPrice;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/proxy/Clones.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './GelatoOracle.sol';
import './interfaces/IOracleFactory.sol';

import 'forge-std/console.sol';

/// @title GelatoOracleFactory
/// @notice
/// @dev
contract GelatoOracleFactory is Ownable, IOracleFactory {
    using Clones for address;

    modifier onlyDataProvider() {
        console.log(msg.sender);
        require(msg.sender == dataProvider, 'onlyDataProvider');
        _;
    }

    address oracleImplementation;

    address public dataProvider;

    mapping(bytes32 => address) oracles;

    /// @notice
    /// @dev
    /// @param dataProvider_ (address)
    constructor(address dataProvider_) {
        dataProvider = dataProvider_;
        oracleImplementation = address(new GelatoOracle());
    }

    /// @notice
    /// @dev
    /// @param endpoints (accept up to 4 endpoints for one oracle)
    function deployOracle(
        uint256 deviation,
        uint8 decimals,
        uint40 heartBeat,
        string[4] memory endpoints
    ) external onlyOwner returns (address newOracle) {
        bytes32 key = keccak256(
            abi.encodePacked(
                deviation,
                decimals,
                heartBeat,
                endpoints[0],
                endpoints[1],
                endpoints[2],
                endpoints[3]
            )
        );
        // if that oracle does not exist yet, create it
        if (oracles[key] == address(0)) {
            newOracle = oracleImplementation.clone();
            GelatoOracle(newOracle).initialize(
                deviation,
                decimals,
                heartBeat,
                address(this)
            );
            oracles[key] = newOracle;
            emit OracleDeployed(newOracle, key);
        } else {
            newOracle = oracles[key];
        }
    }

    function getOracle(bytes32 key) public view returns (GelatoOracle) {
        return GelatoOracle(oracles[key]);
    }

    function setPrice(bytes32 key, uint256 _value) external onlyDataProvider {
        GelatoOracle gelatoOracle = GelatoOracle(oracles[key]);
        require(oracles[key] != address(0), 'no_oracle');
        gelatoOracle.setPrice(_value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct PriceData {
    // wad
    uint256 price;
    uint256 timestamp;
}

interface IOracle {
    event NewValue(uint256 value, uint256 timestamp);

    function setPrice(uint256 _value) external;

    function decimals() external view returns (uint8);

    function getPrice() external view returns (PriceData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IOracleFactory {
    event OracleDeployed(address indexed oracle, bytes32 indexed key);
}

pragma solidity ^0.8.17;

import '@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol';

import './interfaces/IConfig.sol';

contract Config is IConfig, OwnableUpgradeable {
    uint24 public bufferTraderBps;
    uint24 public bufferMakerBps;
    uint256 public bufferTrader;
    uint256 public bufferMaker;
    uint24 public openInterestCap; // 4 decimals (bips)
    uint24 public fmfrPerYear; // 4 decimals (bips)
    uint24 public frPerYearModulo; // 4 decimals (bips)
    uint24 public makerFRFeeBps; // [bips] Maker fee over his FR gains
    uint128 public minPremiumFee;
    uint24 public premiumFeeBps; // % of the premium that protocol collects
    uint24 public minFRPerYear; // 4 decimals (bips)
    uint128 public orderMinAmount;
    uint24 public traderFeeBps; // 4 decimals (bips)
    int256 public liqBuffM;
    int256 public liqBuffT;

    // leverage config
    uint24 public maxLeverageOpen;
    uint24 public maxLeverageOngoing;
    uint24 public minGuaranteedLeverage;
    uint256 public s;
    uint256 public b;
    uint256 public f0;
    // NOTE: Example 180 days
    uint256 public maxTimeGuarantee;
    // NOTE: In case the above is measured in days then it is 365 days
    uint256 public FRTemporalBasis;

    function initialize(address sender) public initializer {
        _transferOwnership(sender);

        bufferTraderBps = 100; // 1%
        bufferMakerBps = 100; // 1%
        bufferTrader = 10 * 1e18;
        bufferMaker = 10 * 1e18;
        openInterestCap = 80 * 1e2; // 80%
        fmfrPerYear = 10 * 1e2; // 10%
        frPerYearModulo = 1; // 0.01%
        minPremiumFee = 1 * 1e18; // 1 USDC
        premiumFeeBps = 20 * 1e2; // 20%
        minFRPerYear = 1 * 1e2; // 1%
        orderMinAmount = 0.1 * 1e18; // 0.1 units
        traderFeeBps = 5; // 0.05%
        makerFRFeeBps = 300; // 3%;

        // leverage config
        maxLeverageOpen = 10 * 1e4; // 1000% (10x)
        maxLeverageOngoing = 16 * 1e4; // 1600% (16x)
        minGuaranteedLeverage = 1 * 1e4; // 100% (1x)
        s = 1;
        b = 1;
        f0 = 0;
        maxTimeGuarantee = 180 days;
        FRTemporalBasis = 365 days;
    }

    function getLeverage() external view override returns (Leverage memory) {
        return
            Leverage(
                maxLeverageOpen,
                maxLeverageOngoing,
                minGuaranteedLeverage,
                s,
                b,
                f0,
                maxTimeGuarantee,
                FRTemporalBasis
            );
    }

    function getBips() external view override returns (Bips memory) {
        return
            Bips(
                bufferTraderBps,
                bufferMakerBps,
                openInterestCap,
                fmfrPerYear,
                frPerYearModulo,
                premiumFeeBps,
                minFRPerYear,
                traderFeeBps,
                makerFRFeeBps
            );
    }

    function getAmounts() external view override returns (Amounts memory) {
        return
            Amounts(bufferTrader, bufferMaker, minPremiumFee, orderMinAmount);
    }

    function setLeverage(Leverage calldata l) external override onlyOwner {
        maxLeverageOpen = l.maxLeverageOpen;
        maxLeverageOngoing = l.maxLeverageOngoing;
        minGuaranteedLeverage = l.minGuaranteedLeverage;
        s = l.s;
        b = l.b;
        f0 = l.f0;
        maxTimeGuarantee = l.maxTimeGuarantee;
        FRTemporalBasis = l.FRTemporalBasis;
    }

    function setBips(Bips calldata bp) external override onlyOwner {
        bufferTraderBps = bp.bufferTraderBps;
        bufferMakerBps = bp.bufferMakerBps;
        openInterestCap = bp.openInterestCap;
        fmfrPerYear = bp.fmfrPerYear;
        frPerYearModulo = bp.frPerYearModulo;
        premiumFeeBps = bp.premiumFeeBps;
        minFRPerYear = bp.minFRPerYear;
        traderFeeBps = bp.traderFeeBps;
    }

    function setAmounts(Amounts calldata a) external override onlyOwner {
        bufferTrader = a.bufferTrader;
        bufferMaker = a.bufferMaker;
        minPremiumFee = a.minPremiumFee;
        orderMinAmount = a.orderMinAmount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import '@dex/lib/NFTDescriptor.sol';
import '@dex/lib/PnLMath.sol';
import '@dex/lib/FeesMath.sol';
import '@dex/lib/FinMath.sol';
import '@dex/lib/Structs.sol';
import '@dex/lib/JoinLib.sol';
import '@dex/oracles/interfaces/IOracle.sol';
import '@dex/perp/interfaces/IEngine.sol';
import '@dex/perp/interfaces/IVault.sol';
import '@dex/perp/interfaces/IPool.sol';
import '@dex/perp/interfaces/IConfig.sol';

import 'forge-std/console.sol';

// import "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
error OrderMinAmount();
error MinFundingRate();
error FundingRateModulo();
error MissingCollateral();
error ZeroCollateral();
error OverLeveraged(uint256 matchId);
error SamePos();
error NeutralPos();
error UnexistingMatch();
error TraderIsMaker();
error NonTrader();
error CancelActiveMatch();
error OnlyMaker();
error OnlyTraderOperation();
error InsufficientCollateral();
error MakerNorTrader();
error ZeroAmount();
error CollateralTooLow();
error MaxLeverageOpen();
error UnecessarySplit();
error EmptyQueue();
error NothingToRun();
error PendingClose();

uint256 constant DEFAULT_ORDERS_DELTA_MAX_TIMESTAMP = 7200;

contract Engine is IEngineEvents {
    using PnLMath for Match;
    using LeverageMath for Match;
    using FinMath for int256;
    using FinMath for uint256;
    using FeesMath for Order;
    using NFTDescriptor for uint256;
    using JoinLib for Match;

    IOracle public oracle;

    // skip 0
    uint128 private nextMatchId;

    // pending orders
    uint128 closeOrderToExecute;
    uint128 openOrderToExecute;

    uint256 public totalTradedAmount;

    // trader order queues
    Order[] public opens;
    CloseOrder[] closes;

    IConfig public config;

    IPool public pool;
    IVault public vault;

    uint8 private tokenDecimals;

    mapping(uint256 => Match) public matches;

    uint256 lpPoolMakeUpMaker;
    uint256 lpPoolMakeUpTrader;
    uint256 liquidationBuffer;

    //@notice Instead of using constructor, this contract is cloned using the Clone lib
    //@dev https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones
    function initialize(
        address oracle_,
        IVault vault_,
        IPool pool_,
        IConfig config_
    ) external {
        oracle = IOracle(oracle_);
        pool = pool_;
        vault = vault_;
        config = config_;

        tokenDecimals = vault.token().decimals();

        // skip 0
        nextMatchId = 1;

        liquidationBuffer = 1000000 * 10**18;
    }

    function pnl(
        uint256 matchId,
        uint256 tokenId,
        uint256 timestamp,
        uint256 exitPrice
    )
        external
        view
        returns (
            int256 pnLM,
            int256 pnlT,
            uint256 FRfee
        )
    {
        return
            matches[matchId].pnl(
                tokenId,
                timestamp,
                exitPrice,
                config.makerFRFeeBps(),
                tokenDecimals
            );
    }

    function accruedFR(uint256 matchId) external view returns (uint256) {
        Match memory m = matches[matchId];
        return m.accruedFR(oracle.getPrice(), tokenDecimals);
    }

    // @dev Temporary 'deep stack' fix, to be used on tests, used 0.25 kb margin, once
    // using the automatic generated viewer has to many args, after adding the `close`.
    function getMatch(uint256 matchId) external view returns (Match memory) {
        return matches[matchId];
    }

    function getMaxLeverageOpen(uint256 fr) external view returns (uint256) {
        return
            LeverageMath.getMaxLeverage(
                config,
                fr,
                block.timestamp - oracle.getPrice().timestamp
            );
    }

    // @notice Here there is no check on the order min amount since it can be
    // created as a result of a split
    function open(
        uint256 amount,
        int24 premiumBps,
        // NOTE: We do not allow negative FRs in v1
        uint24 frPerYear,
        int8 pos,
        uint256 collateral_,
        address recipient
    ) external returns (uint256 matchId, uint256 tokenId) {
        if (amount <= config.getAmounts().orderMinAmount)
            revert OrderMinAmount();
        if (frPerYear < config.minFRPerYear()) revert MinFundingRate();
        if ((frPerYear % config.frPerYearModulo()) != 0)
            revert FundingRateModulo();
        if (vault.collateral(recipient) < collateral_)
            revert MissingCollateral();
        if (collateral_ == 0) revert ZeroCollateral();

        tokenId = vault.mint(recipient);
        Match memory m;
        m.maker = tokenId; // the token owner is the maker of the match
        m.amount = amount;
        m.premiumBps = premiumBps;
        m.frPerYear = frPerYear;
        m.pos = pos;
        m.collateralM = collateral_;
        m.minPremiumFeeDiscountPerc = 100; // Initialize at 100%

        matches[(matchId = nextMatchId++)] = m; // use match-id as idx
        if (
            matches[matchId].isOverLeveraged(
                oracle.getPrice(),
                config,
                true,
                tokenDecimals
            )
        ) revert OverLeveraged(matchId);
        // m.auto_resubmit = auto_resubmit;
        emit NewMakerOrder(recipient, matchId, tokenId);
    }

    // --- Trader ---

    // pick maker match
    // clean memory load gave us 0.121 kb
    function pick(
        // uint256 tokenId,
        uint256 matchId,
        uint256 amount,
        uint256 collateral_,
        int8 pos
    ) external {
        if (
            matches[matchId].pos != POS_NEUTRAL &&
            pos != -1 * matches[matchId].pos
        ) revert SamePos();
        if (pos == POS_NEUTRAL) revert NeutralPos();
        if (matches[matchId].maker == 0) revert UnexistingMatch();
        if (vault.ownerOf(matches[matchId].maker) == msg.sender)
            revert TraderIsMaker();
        if (amount <= config.getAmounts().orderMinAmount)
            revert OrderMinAmount();

        Order memory o;
        o.owner = msg.sender;
        o.matchId = matchId;
        o.amount = amount;
        o.collateral = collateral_;
        o.pos = pos;
        o.timestamp = block.timestamp;
        o.maxTimestamp = o.timestamp + DEFAULT_ORDERS_DELTA_MAX_TIMESTAMP;
        opens.push(o);

        emit NewTraderOrder(msg.sender, matchId, opens.length - 1);
    }

    // @notice Cancel trader order
    // @param id Order ID
    function cancelOrder(uint256 orderId) external {
        Order storage o = opens[orderId];
        if (o.owner != msg.sender) revert NonTrader();
        o.canceled = true;
        emit OrderCanceled(msg.sender, orderId, o.matchId);
    }

    function cancelMatch(uint256 matchId) external {
        Match memory m = matches[matchId];
        if (m.start != 0) revert CancelActiveMatch();
        if (vault.ownerOf(m.maker) != msg.sender) revert OnlyMaker();
        emit MatchCanceled(msg.sender, matchId);
        delete matches[matchId];
    }

    // @notice submit close trader order
    // @matchId match id that comes from UI
    function close(uint256 matchId) external {
        address trader = vault.ownerOf(matches[matchId].trader); // load trader
        if (trader != msg.sender) revert OnlyTraderOperation();
        if (matches[matchId].close) revert PendingClose();
        matches[matchId].close = true; // flag true for the close request
        closes.push(CloseOrder(matchId, block.timestamp));
    }

    // @dev removing memory struct load here gave us 0.34 kb
    function increaseCollateral(uint256 matchId, uint256 amount) external {
        if (vault.collateral(msg.sender) < amount)
            revert InsufficientCollateral();
        vault.lock(amount, msg.sender);
        // increase maker collateral
        if (msg.sender == vault.ownerOf(matches[matchId].maker)) {
            matches[matchId].collateralM += amount;
            emit CollateralIncreased(msg.sender, matchId, amount);
        } else if (msg.sender == vault.ownerOf(matches[matchId].trader)) {
            matches[matchId].collateralT += amount;
            emit CollateralIncreased(msg.sender, matchId, amount);
        } else {
            revert MakerNorTrader();
        }
    }

    // @dev cleaning storage load on Match gave us 0.163 kb and reduced
    // average gas use from 15k to 13.5k
    function decreaseCollateral(uint256 matchId, uint256 amount) external {
        if (amount <= 0) revert ZeroAmount();
        // Match storage m = matches[matchId];
        PriceData memory priceData = oracle.getPrice();
        // increase maker collateral
        if (msg.sender == vault.ownerOf(matches[matchId].maker)) {
            if (matches[matchId].collateralM < amount)
                revert CollateralTooLow();
            matches[matchId].collateralM -= amount;
            if (
                matches[matchId].isOverLeveraged(
                    priceData,
                    config,
                    true,
                    tokenDecimals
                )
            ) revert MaxLeverageOpen();

            emit CollateralDecreased(msg.sender, matchId, amount);
        } else if (msg.sender == vault.ownerOf(matches[matchId].trader)) {
            if (matches[matchId].collateralT < amount)
                revert CollateralTooLow();
            matches[matchId].collateralT -= amount;
            if (
                matches[matchId].isOverLeveraged(
                    priceData,
                    config,
                    true,
                    tokenDecimals
                )
            ) revert MaxLeverageOpen();

            emit CollateralDecreased(msg.sender, matchId, amount);
        } else {
            revert MakerNorTrader();
        }
        vault.unlock(amount, msg.sender);
    }

    // --- Keeper ---

    // associate trader order to maker match
    function join(
        Order storage order,
        PriceData memory priceData,
        uint256 orderId
    ) internal {
        Match memory m = matches[order.matchId].normalize(order.amount); // load by the selected maker tokenid
        if (m.maker == 0) {
            emit MatchInexistant(order.matchId, orderId);
            return;
        }
        address maker = vault.ownerOf(m.maker);
        uint256 balance = vault.collateral(order.owner);

        // --- Trader Fees ---
        uint256 traderFees = order.traderFees(priceData, config);

        (int256 premiumT, uint256 premiumFee) = order.computePremiumAndFee(
            priceData,
            m.premiumBps,
            config,
            m.minPremiumFeeDiscountPerc
        );

        //
        if (
            !m.beforeChecks(
                order,
                orderId,
                maker,
                balance,
                int256(traderFees) + premiumT,
                -premiumT + int256(premiumFee)
            )
        ) return;

        // NOTE: We can use negative premium to cover the traderFees at least partially, excess will go to Trader Vault Account
        int256 _deltaT = premiumT.add(traderFees); //  int256(traderFees) + premiumT;
        m.collateralT = order.collateral - _deltaT.pos();

        // NOTE: We can use poisitive premium to cover the makerFees, excess will go to Maker Vault Account
        int256 _deltaM = int256(premiumFee) - premiumT;
        m.collateralM = m.collateralM - _deltaM.pos();

        if (
            !m.afterChecks(
                JoinLib.AfterCheck(
                    priceData,
                    config,
                    vault,
                    maker,
                    order.owner,
                    order.matchId,
                    orderId,
                    order.maxTimestamp,
                    tokenDecimals
                )
            )
        ) return;
        // No more checks so here we can modify the state safely

        uint256 tokenId = vault.mint(order.owner);
        m.trader = tokenId; // setup match with the trader token
        m.start = uint128(priceData.timestamp); // set oracle time we matched
        m.entryPrice = priceData.price; // set oracle price on match
        m.fmfrPerYear = config.fmfrPerYear();

        if (order.amount < matches[order.matchId].amount)
            // create another match with the remaining amount from the original match
            _split(matches[order.matchId], order.amount);

        m.collateralT = order.collateral - _deltaT.pos();
        m.collateralM = m.collateralM - _deltaM.pos();

        // NOTE: Makers can choose to be long or short or neutral so that it is the trader deciding
        m.pos = (m.pos == POS_NEUTRAL) ? (-1 * order.pos) : m.pos;

        // update the balance available to trader/maker
        if (_deltaT < 0) {
            // NOTE: Crediting excess negative premium to the Trader Vault Account
            vault.unlock(uint256(-_deltaT), order.owner);
        }

        if (_deltaM < 0) {
            // NOTE: Crediting excess positive premium to the Maker Vault Account
            vault.unlock(uint256(-_deltaM), maker);
        }

        matches[order.matchId] = m;
        vault.lock(m.collateralT, order.owner);
        vault.lock(m.collateralM, maker);

        totalTradedAmount += order.amount;

        emit ActiveMatch(
            order.matchId,
            maker,
            order.owner,
            orderId,
            m.maker,
            m.trader
        );
    }

    // desassociate trader from match based on trader tokenid
    function unjoin(uint256 matchId, PriceData memory priceData) internal {
        Match storage m = matches[matchId]; // load Match by trader matchid
        // // early bailout in case the match is already closed
        if (m.maker == 0) return;
        (int256 pnLM, int256 pnLT, ) = m.pnl(
            m.maker,
            priceData.timestamp,
            priceData.price,
            config.makerFRFeeBps(),
            tokenDecimals
        );
        address maker = vault.ownerOf(m.maker);
        address trader = vault.ownerOf(m.trader);

        totalTradedAmount -= m.amount;

        _settlePnL(maker, true, int256(m.collateralM) + pnLM);
        _settlePnL(trader, false, int256(m.collateralT) + pnLT);

        emit CloseMatch(
            matchId,
            m.maker,
            m.trader,
            pnLM,
            pnLT,
            priceData.price
        );
        delete matches[matchId].maker;
    }

    function _split(Match storage m, uint256 amount)
        internal
        returns (uint256 matchId, uint256 tokenId)
    {
        if (amount >= m.amount) revert UnecessarySplit();
        uint256 newAmount = m.amount - amount;
        if (newAmount <= config.getAmounts().orderMinAmount) {
            return (0, 0);
        }
        address maker = vault.ownerOf(m.maker);
        tokenId = vault.mint(maker); // mint maker token
        Match memory newMatch;
        newMatch.maker = tokenId;
        newMatch.amount = newAmount;
        newMatch.premiumBps = m.premiumBps;
        newMatch.frPerYear = m.frPerYear;
        newMatch.pos = m.pos;
        newMatch.collateralM =
            m.collateralM -
            ((m.collateralM * amount) / m.amount);
        newMatch.minPremiumFeeDiscountPerc =
            m.minPremiumFeeDiscountPerc -
            uint8((uint256(m.minPremiumFeeDiscountPerc) * amount) / m.amount);
        // create a new potential match in the order book;
        matches[(matchId = nextMatchId++)] = newMatch;

        emit NewMakerOrder(maker, matchId, tokenId);
    }

    function _settlePnL(
        address user,
        bool isMaker,
        int256 pnl_
    ) internal {
        // TODO: This is incomplete since we need to remove the settled PnL from the current uPnL
        int256 _newBalance = (int256(vault.collateral(user)) + pnl_);
        vault.assign(_newBalance > 0 ? uint256(_newBalance) : 0, user);

        // NOTE: Track losses that have to be made up by the LP Pool
        if (isMaker && _newBalance < 0) {
            lpPoolMakeUpMaker += uint256(-_newBalance);
        }
        if (!isMaker && _newBalance < 0) {
            lpPoolMakeUpTrader += uint256(-_newBalance);
        }
    }

    function liquidate(
        uint256[] calldata matchIds,
        uint256[] calldata tokenIds,
        address recipient
    ) external {
        PriceData memory p = oracle.getPrice(); // TODO: do we need to get price in the loop?
        for (uint256 i = 0; i < matchIds.length; i++) {
            uint256 matchId = matchIds[i];
            uint256 tokenId = tokenIds[i];

            bool _isLiquidatable = matches[matchId].isLiquidatable(
                tokenId,
                p.price,
                config,
                tokenDecimals
            );
            if (!_isLiquidatable) continue; // TODO: what is this ? [tests are insensible]
            Match storage m = matches[matchId];
            (int256 pnlM, int256 pnlT, ) = m.pnl(
                tokenId,
                p.timestamp,
                p.price,
                config.makerFRFeeBps(),
                tokenDecimals
            );
            if (!_isLiquidatable) continue; // TODO: what is this ? [tests are insensible]
            if (tokenId == m.maker) {
                // TODO: Implement Maker Liquidation --> it means
                // 1) Decapitating current owner
                // 2) Recapitilizing through LP Pool
                // 3) Minting ownership to pool --> Take care about auction start
            } else {
                // a fix fee of 1$ is always paid off to the liquidator
                uint256 fee = 1 * 10**18; // collateral with 18 decimal precision
                // take 0.01% of the collateral as fee
                fee += m.collateralT / 10000; // TODO: use our FinMath lib
                int256 remainingCollateral = int256(m.collateralT) + pnlT;
                if (int256(fee) < remainingCollateral) {
                    // TODO: if remainingCollateral goes below 0 here, we have a problem
                    remainingCollateral -= int256(fee);
                    vault.transfer(
                        fee + uint256(remainingCollateral) / 2,
                        recipient
                    );
                    vault.addFees(uint256(remainingCollateral) / 2);
                } else {
                    // fees are above remaining collateral,
                    // the pool pay the liquidator fees and the missing collateral
                    lpPoolMakeUpTrader += uint256(
                        int256(fee) - remainingCollateral
                    );
                    vault.transfer(fee, recipient);
                }
                // settle profitable pnl for the maker on the vault, if the trader
                // was liquidated, maker is profitable on the other side of the trade
                vault.unlock(
                    uint256(int256(m.collateralM) + pnlM),
                    vault.ownerOf(m.maker)
                );

                totalTradedAmount -= m.amount;

                emit MatchLiquidated(matchId, pnlM, oracle.getPrice().price);
                delete matches[matchId].maker;
            }
        }
    }

    ///@notice returns the current market usage vs the insurance pool
    function poolUsage(uint256 price, uint256 orderAmount)
        public
        view
        returns (uint256)
    {
        return
            totalTradedAmount.add(orderAmount).wmul(price).bps().div(
                pool.capLimit()
            );
    }

    function _validateOICap(uint256 price, uint256 orderAmount)
        internal
        view
        returns (bool)
    {
        if (pool.capLimit() == 0) return false;
        return poolUsage(price, orderAmount) < config.openInterestCap();
    }

    function runOpens(uint256 n) external {
        PriceData memory p = oracle.getPrice();
        if (
            (opens.length <= openOrderToExecute &&
                p.timestamp <= opens[openOrderToExecute].timestamp) ||
            !_validateOICap(p.price, 0)
        ) revert EmptyQueue();
        n = (n == 0)
            ? opens.length
            : Math.min(openOrderToExecute + n, opens.length);

        // run the last queue and update the price
        while (openOrderToExecute < n) {
            Order storage order = opens[openOrderToExecute];
            // check if price is recent enough, break the loop if not as all further order will be too recent
            if (p.timestamp < order.timestamp) break;
            if (!_validateOICap(p.price, order.amount)) break;
            join(order, p, openOrderToExecute);
            delete opens[openOrderToExecute];
            openOrderToExecute++;
        }
    }

    function runCloses(uint256 n) external {
        if (
            closes.length <= closeOrderToExecute ||
            oracle.getPrice().timestamp <= closes[closeOrderToExecute].timestamp
        ) revert NothingToRun();
        n = (n == 0)
            ? closes.length
            : Math.min(closeOrderToExecute + n, closes.length);

        PriceData memory priceData = oracle.getPrice();
        while (closeOrderToExecute < n) {
            CloseOrder memory order = closes[closeOrderToExecute];
            // check if price is recent enough, break the loop if not as all further order will be too recent as well
            if (priceData.timestamp < order.timestamp) break;
            unjoin(order.matchId, priceData);
            delete closes[closeOrderToExecute];
            closeOrderToExecute++;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/proxy/Clones.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@dex/perp/Engine.sol';
import '@dex/perp/Config.sol';
import '@dex/perp/Vault.sol';
import '@dex/perp/interfaces/IPool.sol';
import '@dex/perp/Pool.sol';

import '@dex/lib/Structs.sol';
import '@dex/oracles/GelatoOracleFactory.sol';

contract EngineFactory is Ownable {
    using Clones for address;

    address engineImplementation;
    address configImplementation;

    GelatoOracleFactory public oracleFactory;
    Vault public vault;
    Pool public pool;

    event EngineDeployed(
        address indexed engine,
        address indexed vault,
        address indexed oracle,
        address pool
    );

    struct OracleArguments {
        uint256 deviation;
        uint8 decimals;
        uint40 heartBeat;
        string[4] endpoints;
    }

    constructor(address dataProvider, address collateralToken) {
        oracleFactory = new GelatoOracleFactory(dataProvider);
        vault = new Vault(collateralToken);
        pool = new Pool(
            msg.sender,
            IERC20(collateralToken),
            1 * 1e16,
            240,
            240,
            1000000 * 10e18
        );
        engineImplementation = address(new Engine());
        configImplementation = address(new Config());
    }

    function liquidates(
        uint256[][] calldata matchIds,
        uint256[][] calldata tokenIds,
        address[] calldata engines,
        address recipient
    ) external {
        for (uint256 i = 0; i < engines.length; i++) {
            IEngine(engines[i]).liquidate(matchIds[i], tokenIds[i], recipient);
        }
    }

    function deployEngine(OracleArguments calldata oracleArguments)
        external
        onlyOwner
        returns (address newEngine)
    {
        newEngine = engineImplementation.clone();
        address newConfig = configImplementation.clone();
        IConfig(newConfig).initialize(msg.sender);

        address newOracle = oracleFactory.deployOracle(
            oracleArguments.deviation,
            oracleArguments.decimals,
            oracleArguments.heartBeat,
            oracleArguments.endpoints
        );

        vault.approve(newEngine);

        IEngine(newEngine).initialize(
            newOracle,
            vault,
            pool,
            IConfig(newConfig)
        );
        // totalEngine, used to calculate the OI cap
        pool.addMarket();
        emit EngineDeployed(
            newEngine,
            address(vault),
            newOracle,
            address(pool)
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@dex/perp/interfaces/IPool.sol';
import '@dex/lib/FinMath.sol';

// TODO: rename bond to shares or similar name
contract Pool is Ownable, IPool {
    uint128 markets; // Markets count, used to calculate the cap limit per market

    using FinMath for uint256;
    using SafeERC20 for IERC20;
    uint256 constant PRECISION = 1e18;
    uint256 constant PERCENT = 1e6; // TODO: move this to global config
    uint256 public door; // Cooldown permited withdraw period
    uint256 public wfee; // Withdraw fee [wad]
    uint256 public cap; // Max deposit cap [wad]
    uint256 public immutable hold; // Cooldown waiting period
    address public immutable treasury; // gov to receive withdraw fees
    IERC20 public immutable usdc; // USDC address
    mapping(address => UserInfo) public users;
    uint256 public totalShares;
    int256 public accRewardsPerShares; // rewards are not guaranteed and can potentially turns negative
    uint256 public totalFees;
    uint256 withdrawRatio; // scaling factor to gauge withdraw lock

    enum Status {
        NONE,
        PREMATURE,
        ACTIVE,
        EXPIRED
    }

    // --- Events ---
    event Deposited(address indexed user, address indexed usdc, uint256 pay);

    event Withdrew(
        address indexed user,
        address indexed usdc,
        uint256 pay,
        uint256 per,
        uint256 fee
    );

    event Profit(address indexed user, address indexed usdc, uint256 pay);

    event Loss(address indexed user, address indexed usdc, uint256 pay);

    struct UserInfo {
        uint256 withdrawRequest; // timestamp the last time a user attempted a withdraw
        uint256 shares;
        uint256 withdrawAmount; // Promised withdraw amount on hold during the door period
        int256 accRewardsSnapshotAtLock; // used to avoid rewards aggregating while a withdraw is pending
        int256 accRewardsSnapshot;
    }

    // --- Init ---
    constructor(
        address treasury_,
        IERC20 usdc_,
        uint256 wfee_,
        uint256 door_,
        uint256 hold_,
        uint256 cap_
    ) {
        require(treasury_ != address(0), 'address0');
        require(address(usdc_) != address(0), 'address0');

        treasury = treasury_;
        usdc = usdc_;
        wfee = wfee_;
        door = door_;
        hold = hold_;
        cap = cap_;
        withdrawRatio = 200e4; // = 200% [200e4/1e6 = 2]
    }

    function capLimit() external view returns (uint256) {
        // will revert if markets is 0 and that's fine, because that function is supposedly called by a market
        return IERC20(usdc).balanceOf(address(this)) / markets;
    }

    function addMarket() external onlyOwner {
        markets++;
    }

    // --- Fungibility ---
    function deposit(uint256 amount) external {
        require(amount != 0, 'pool/zero-amount');
        uint256 balance = IERC20(usdc).balanceOf(address(this));
        require(amount + balance <= cap, 'pool/total-cap-exceeded');

        IERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);

        UserInfo storage u = users[msg.sender];

        totalShares += amount;
        u.shares += amount;
        u.accRewardsSnapshot = accRewardsPerShares;

        // users[msg.sender] = u;

        emit Deposited(msg.sender, address(usdc), amount);
    }

    function cancelWithdraw() external {
        UserInfo storage u = users[msg.sender];
        require(u.withdrawRequest != 0, 'pool/no-withdraw-ongoing');
        u.withdrawRequest = 0;
        // modify the old snapshot, take the pnl of the withdrawal process into account
        u.accRewardsSnapshot =
            ((int256(u.shares - u.withdrawAmount) *
                (accRewardsPerShares - u.accRewardsSnapshotAtLock)) +
                (int256(u.shares) *
                    (u.accRewardsSnapshotAtLock - u.accRewardsSnapshot))) /
            int256(u.shares);
    }

    // only escrow is authorized to call
    function withdraw(uint256 amount, address recipient) external {
        UserInfo storage u = users[recipient];
        require(amount != 0, 'pool/zero-amount');
        require(amount <= u.shares, 'pool/amount-too-high');
        if (u.withdrawRequest == 0) {
            // clean state
            u.withdrawRequest = block.timestamp;
            u.withdrawAmount = amount;
            // take a snapshot of the current accRewardsPerShare
            u.accRewardsSnapshotAtLock = accRewardsPerShares;
        } else if ((block.timestamp - u.withdrawRequest) > (door + hold)) {
            totalShares = totalShares + u.withdrawAmount - amount;
            // there was a previous request but is now expired
            // modify the old snapshot, take the pnl of the withdrawal process into account
            u.accRewardsSnapshot =
                ((int256(u.shares - u.withdrawAmount) *
                    (accRewardsPerShares - u.accRewardsSnapshotAtLock)) +
                    (int256(u.shares) *
                        (u.accRewardsSnapshotAtLock - u.accRewardsSnapshot))) /
                int256(u.shares);
            u.withdrawRequest = block.timestamp;
            u.withdrawAmount = amount;
            // take a snapshot of the current accRewardsPerShare
            u.accRewardsSnapshotAtLock = accRewardsPerShares;
        } else if ((block.timestamp - u.withdrawRequest) > door) {
            require(u.withdrawAmount >= amount, 'locked-amount-too-low');
            int256 pnlSinceLock = (int256(u.shares - u.withdrawAmount) *
                (accRewardsPerShares - u.accRewardsSnapshotAtLock)) /
                int256(PRECISION);
            int256 pnlAtLock = (int256(u.shares) *
                (u.accRewardsSnapshotAtLock - u.accRewardsSnapshot)) /
                int256(PRECISION);
            int256 pnl = pnlSinceLock + pnlAtLock;
            // do we take fees if pnl is negative?
            uint256 fees = (amount * wfee) / PRECISION;
            totalFees += fees;

            // Effects
            totalShares = totalShares + u.withdrawAmount - amount; // if a difference exist, add to the totalShares
            u.shares -= amount;
            u.accRewardsSnapshot = accRewardsPerShares;
            u.withdrawRequest = 0;

            // @todo this is a naïve way to do it, should be done differently
            require(int256(amount) > (-pnl + int256(fees)), 'pnl>amount');

            usdc.safeTransfer(
                recipient,
                uint256(int256(amount) + pnl - int256(fees))
            );
        } else {
            // if we are below door period, we do a refresh
            // update the totalshare if a delta exist between previous withdraw amount and the current
            // modify the old snapshot, take the pnl of the uncanceled withdrawal process into account
            u.accRewardsSnapshot =
                ((int256(u.shares - u.withdrawAmount) *
                    (accRewardsPerShares - u.accRewardsSnapshotAtLock)) +
                    (int256(u.shares) *
                        (u.accRewardsSnapshotAtLock - u.accRewardsSnapshot))) /
                int256(u.shares);
            totalShares = totalShares + u.withdrawAmount - amount;
            u.withdrawRequest = block.timestamp;
            u.withdrawAmount = amount;
            // refresh rewards accumulation to an older date
            u.accRewardsSnapshotAtLock = accRewardsPerShares;
        }
        // // store
        // users[recipient] = u;
    }

    function setWithdrawRatio(uint256 ratio) external onlyOwner {
        withdrawRatio = ratio;
    }

    function setCoolDown(uint256 period) external onlyOwner {
        door = period;
    }

    function setWithdrawFee(uint256 fee) external onlyOwner {
        wfee = fee;
    }

    function setCap(uint256 cap_) external onlyOwner {
        cap = cap_;
    }

    function profit(uint256 amount) external onlyOwner {
        require(totalShares != 0, 'no-shares');
        IERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);
        accRewardsPerShares += int256(amount * PRECISION) / int256(totalShares);
        emit Profit(msg.sender, address(usdc), amount);
    }

    function loss(uint256 amount) external onlyOwner {
        require(totalShares != 0, 'no-shares');
        IERC20(usdc).safeTransferFrom(address(this), msg.sender, amount);
        accRewardsPerShares -= int256(amount * PRECISION) / int256(totalShares);
        emit Loss(msg.sender, address(usdc), amount);
    }

    function status() public view returns (Status) {
        UserInfo memory u = users[msg.sender];
        if (u.withdrawRequest == 0) {
            // no withdrawal request pending
            return Status.NONE;
        } else if ((block.timestamp - u.withdrawRequest) > (door + hold)) {
            // there was a previous request but is now expired
            return Status.EXPIRED;
        } else if ((block.timestamp - u.withdrawRequest) > door) {
            return Status.ACTIVE;
        } else {
            return Status.PREMATURE;
        }
    }

    function withdrawFees() public onlyOwner {
        // reset totalFees accumulated
        totalFees = 0;

        usdc.safeTransfer(treasury, totalFees);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import './interfaces/IVault.sol';

contract Vault is IVault, ERC721, Ownable {
    // mint IDs
    address collateralToken;

    uint256 public totalFees;

    uint256 private _nextTokenId = 1;

    // NOTE: Accounts of addresses
    mapping(address => uint256) public collateral;

    // list of engines approved to manipulate user balance
    mapping(address => bool) public approved;

    modifier onlyApproved() {
        require(approved[msg.sender], 'not-approved');
        _;
    }

    constructor(address collateralToken_) ERC721('TEST', 'TST') {
        collateralToken = collateralToken_;
        // ERC721
    }

    function mint(address to) external onlyApproved returns (uint256 tokenId) {
        _safeMint(to, (tokenId = _nextTokenId++));
    }

    function token() external view override returns (IERC20Metadata) {
        return IERC20Metadata(collateralToken);
    }

    function approve(address engine) external onlyOwner {
        approved[engine] = true;
    }

    function addFees(uint256 amount) external onlyApproved {
        totalFees += amount;
    }

    ///@notice Engine can send liquidation fees to any recipient
    function transfer(uint256 amount, address recipient) external onlyApproved {
        IERC20(collateralToken).transferFrom(address(this), recipient, amount);
    }

    function withdrawFees(address recipient) external onlyOwner {
        IERC20(collateralToken).transferFrom(
            address(this),
            recipient,
            totalFees
        );
        totalFees = 0;
    }

    /// @dev this expressly do not check if collateral > amount, it will revert anyway
    function lock(uint256 amount, address account) external onlyApproved {
        collateral[account] -= amount;
    }

    function unlock(uint256 amount, address account) external onlyApproved {
        collateral[account] += amount;
    }

    function assign(uint256 amount, address account) external onlyApproved {
        collateral[account] = amount;
    }

    function deposit(uint256 amount, address recipient) external override {
        require(amount > 0, 'account/zero-deposit');
        IERC20(collateralToken).transferFrom(msg.sender, address(this), amount);
        collateral[recipient] += amount;
    }

    // withdraw free collateral
    function withdraw(uint256 amount, address recipient) external override {
        require(amount > 0, 'vault/zero-withdrawl');
        require(collateral[msg.sender] >= amount, 'vault/not-enough-balance');

        collateral[msg.sender] -= amount;
        IERC20(collateralToken).transferFrom(address(this), recipient, amount);
    }
}

pragma solidity ^0.8.17;

struct Bips {
    uint24 bufferTraderBps;
    uint24 bufferMakerBps;
    uint24 openInterestCap; // 4 decimals (bips)
    uint24 fmfrPerYear; // 4 decimals (bips)
    uint24 frPerYearModulo; // 4 decimals (bips)
    uint24 premiumFeeBps; // % of the premium that protocol collects
    uint24 minFRPerYear; // 4 decimals (bips)
    uint24 traderFeeBps; // 4 decimals (bips)
    uint24 makerFRFeeBps; // 4 decimals (bips)
}

struct Amounts {
    uint256 bufferTrader;
    uint256 bufferMaker;
    uint128 minPremiumFee;
    uint128 orderMinAmount;
}

struct Leverage {
    // NOTE: Like in PerpV2, we have 2 max leverages: one for when the position is opened and the other for the position ongoing
    uint24 maxLeverageOpen;
    uint24 maxLeverageOngoing;
    uint24 minGuaranteedLeverage;
    uint256 s;
    uint256 b;
    uint256 f0;
    // NOTE: Example 180 days
    uint256 maxTimeGuarantee;
    // NOTE: In case the above is measured in days then it is 365 days
    uint256 FRTemporalBasis;
    // NOTE: Fair Market FR
    // NOTE: Atm we do not support negative FR
}

interface IConfig {
    function fmfrPerYear() external view returns (uint24);

    function premiumFeeBps() external view returns (uint24);

    function openInterestCap() external view returns (uint24);

    function frPerYearModulo() external view returns (uint24);

    function minFRPerYear() external view returns (uint24);

    function traderFeeBps() external view returns (uint24);

    function bufferTraderBps() external view returns (uint24);

    function bufferMakerBps() external view returns (uint24);

    function makerFRFeeBps() external view returns (uint24);

    function bufferTrader() external view returns (uint256);

    function bufferMaker() external view returns (uint256);

    function getLeverage() external view returns (Leverage memory);

    function getBips() external view returns (Bips memory);

    function getAmounts() external view returns (Amounts memory);

    function setLeverage(Leverage calldata leverage) external;

    function setBips(Bips calldata) external;

    function setAmounts(Amounts calldata) external;

    function initialize(address owner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@dex/lib/LeverageMath.sol';
import '@dex/perp/interfaces/IVault.sol';
import '@dex/perp/interfaces/IPool.sol';
import '@dex/perp/interfaces/IConfig.sol';

interface IEngineEvents {
    // TODO: move out [leave only on test]
    event MatchInexistant(uint256 indexed matchId, uint256 indexed orderId);
    event MakerIsTrader(
        uint256 indexed matchId,
        address indexed maker,
        uint256 orderId
    );
    event LowMakerCollateralForFees(
        uint256 indexed matchId,
        address indexed maker,
        uint256 orderId,
        uint256 allocatedCollateral,
        uint256 makerFees
    );

    event LowTraderCollateral(
        uint256 indexed matchId,
        address indexed trader,
        uint256 orderId,
        uint256 traderCollateral,
        uint256 collateralNeeded
    );
    event LowTraderCollateralForFees(
        uint256 indexed matchId,
        address indexed trader,
        uint256 orderId,
        uint256 allocatedCollateral,
        uint256 traderFees
    );
    event NewMakerOrder(
        address indexed recipient,
        uint256 indexed matchId,
        uint256 tokenId
    );

    event NewTraderOrder(
        address indexed recipient,
        uint256 indexed matchId,
        uint256 orderId
    );

    event ActiveMatch(
        uint256 indexed matchId,
        address indexed maker,
        address indexed trader,
        uint256 orderId,
        uint256 makerToken,
        uint256 traderToken
    );

    event CloseMatch(
        uint256 indexed matchId,
        uint256 indexed makerToken,
        uint256 indexed traderToken,
        int256 PnLM,
        int256 PnLT,
        uint256 price
    );

    event MatchLiquidated(uint256 indexed matchId, int256 pnl, uint256 price);

    event LowMakerCollateral(
        uint256 indexed matchId,
        address indexed maker,
        uint256 orderId,
        uint256 makerCollateral,
        uint256 collateralNeeded
    );

    event OrderExpired(
        uint256 indexed matchId,
        address indexed trader,
        address indexed maker,
        uint256 orderId,
        uint256 orderTimestamp
    );

    event OrderCanceled(
        address indexed trader,
        uint256 indexed orderId,
        uint256 indexed matchId
    );

    event MatchCanceled(address indexed maker, uint256 indexed matchId);

    event CollateralIncreased(
        address indexed sender,
        uint256 matchId,
        uint256 amount
    );

    event CollateralDecreased(
        address indexed sender,
        uint256 matchId,
        uint256 amount
    );

    event MaxOpeningLeverage(
        address indexed user,
        uint256 matchId,
        uint256 orderId,
        uint256 price
    );
}

interface IEngine {
    function initialize(
        address oracle_,
        IVault vault_,
        IPool pool_,
        IConfig config_
    ) external;

    function getMatch(uint256 matchId) external view returns (Match memory);

    function liquidate(
        uint256[] calldata matchIds,
        uint256[] calldata tokenIds,
        address recipient
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IPool {
    function totalShares() external view returns (uint256);

    function deposit(uint256 amount) external;

    function cancelWithdraw() external;

    function withdraw(uint256 amount, address recipient) external;

    function capLimit() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IVault is IERC721 {
    function token() external view returns (IERC20Metadata);

    function collateral(address) external view returns (uint256);

    function mint(address to) external returns (uint256);

    function addFees(uint256 amount) external;

    function transfer(uint256 amount, address recipient) external;

    function lock(uint256 amount, address account) external;

    function unlock(uint256 amount, address account) external;

    function assign(uint256 amount, address account) external;

    function deposit(uint256 amount, address recipient) external;

    function withdraw(uint256 amount, address recipient) external;
}