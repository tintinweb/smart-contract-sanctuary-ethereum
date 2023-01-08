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

// SPDX-License-Identifier: GNU-3
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(address(0))) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/lib/Structs.sol';
import '@dex/lib/FinMath.sol';

import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library FeesMath {
    using FinMath for uint256;
    using FinMath for uint24;
    using FinMath for int24;

    function computePremiumAndFee(
        Order storage o,
        PriceData memory p,
        int24 premiumBps,
        uint24 premiumFeePerc,
        uint128 minPremiumFee
    ) public view returns (int256 premium, uint256 premiumFee) {
        uint256 notional = o.amount.wmul(p.price);
        premium = premiumBps.bps(notional);
        int256 fee = premiumFeePerc.bps(premium);
        premiumFee = (fee > int128(minPremiumFee))
            ? uint256(fee)
            : minPremiumFee;
    }

    function traderFees(
        Order storage o,
        PriceData memory p,
        uint24 traderFeeBps
    ) external view returns (uint256) {
        uint256 notional = o.amount.wmul(p.price);
        int256 fee = traderFeeBps.bps(int256(notional));
        return uint256(fee);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Percentage using BPS
// https://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency/3730040#3730040

library FinMath {
    int256 public constant BPS = 10 ** 4; // basis points [TODO: move to 10**4]
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant LIMIT = 2 ** 255;

    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728792003956564819967;
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728792003956564819968;

    // @notice Calculate percentage using BPS precision
    // @param bps input in base points
    // @param x the number we want to calculate percentage
    // @return the % of the x including fixed-point arithimetic
    function bps(int256 bp, uint256 x) internal pure returns (int256) {
        require(x < 2 ** 255);
        int256 y = int256(x);
        require((y * bp) >= BPS);
        return (y * bp) / BPS;
    }

    function bps(uint256 bp, uint256 x) internal pure returns (uint256) {
        uint256 UBPS = uint256(BPS);
        uint256 res = (x * bp) / UBPS;
        require(res < LIMIT); // cast overflow check
        return res;
    }

    function bps(uint256 bp, int256 x) internal pure returns (int256) {
        require(bp < LIMIT); // cast overflow check
        return bps(int256(bp), x);
    }

    function bps(int256 bp, int256 x) internal pure returns (int256) {
        return (x * bp) / BPS;
    }

    function ibps(uint256 bp, uint256 x) internal pure returns (int256) {
        uint256 UBPS = uint256(BPS);
        uint256 res = (x * bp) / UBPS;
        require(res < LIMIT); // cast overflow check
        return int(res);
    }


    // @notice somethimes we need to print int but cast them to uint befor
    function inv(int x) internal pure returns(uint) {
        if(x < 0) return uint(-x);
        if(x >=0) return uint(x);
    }


    // function bps(uint64 bp, uint256 x) internal pure returns (uint256) {
    //     return (x * bp) / uint256(BPS);
    // }

    // @notice Bring the number up to the BPS decimal format for further calculations
    // @param x number to convert
    // @return value in BPS case
    function bps(uint256 x) internal pure returns (uint256) {
        return mul(x, uint256(BPS));
    }

    // @notice Return the positive number of an int256 or zero if it was negative
    // @parame x the number we want to normalize
    // @return zero or a positive number
    function pos(int256 a) internal pure returns (uint256) {
        return (a >= 0) ? uint256(a) : 0;
    }

    // @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    // @param y The multiplier as a signed 59.18-decimal fixed-point number.
    // @return result The result as a signed 59.18-decimal fixed-point number.
    // https://github.com/paulrberg/prb-math/blob/v1.0.3/contracts/PRBMathCommon.sol - license WTFPL
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        require(x > MIN_SD59x18);
        require(y > MIN_SD59x18);

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 resultUnsigned = mul(ax, ay);
            require(resultUnsigned <= uint256(MAX_SD59x18));

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1
                ? -int256(resultUnsigned)
                : int256(resultUnsigned);
        }
    }

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'fin-math-add-overflow');
    }

    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x, 'fin-math-add-overflow');
    }

    function isub(uint256 x, uint256 y) internal pure returns (int256 z) {
        require(x < LIMIT && y < LIMIT, 'fin-math-cast-overflow');
        return int256(x) - int256(y);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'fin-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'fin-math-mul-overflow');
    }

    function add(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x + uint256(y);
        require(y >= 0 || z <= x, 'fin-math-iadd-overflow');
        require(y <= 0 || z >= x, 'fin-math-iadd-overflow');
    }

    function add(int256 x, uint256 y) internal pure returns (int256 z) {
        require(y < LIMIT, 'fin-math-cast-overflow');
        z = x + int256(y);
        // require(y >= 0 || z <= x, "fin-math-iadd-overflow");
        // require(y <= 0 || z >= x, "fin-math-iadd-overflow");
    }

    function sub(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x - uint256(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }

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

    //@dev rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //@notice Multiply two Wads and return a new Wad with the correct level
    // of precision. A Wad is a decimal number with 18 digits of precision
    // that is being represented as an integer.
    function wmul(int256 x, int256 y) internal pure returns (int256 z) {
        z = add(mul(x, y), int256(WAD) / 2) / int256(WAD);
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //@notice Divide two Wads and return a new Wad with the correct level of precision.
    //@dev rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/lib/Structs.sol';
import '@dex/lib/PnLMath.sol';
import '@dex/lib/FinMath.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library LeverageMath {
    using FinMath for uint256;
    using FinMath for int256;
    using PnLMath for Match;
    struct Data {
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

    function _min(uint256 a, uint256 b) internal pure returns (uint256 res) {
        res = (a <= b) ? a : b;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256 res) {
        res = (a >= b) ? a : b;
    }

    function isOverLeveraged(
        Match storage m,
        LeverageMath.Data storage leverage,
        PriceData calldata priceData,
        uint256 fmfr,
        bool isMaker,
        uint8 collateralDecimals
    ) public view returns (bool) {
        Match memory _m = m;
        return isOverLeveraged_(_m, leverage, priceData, fmfr, isMaker, collateralDecimals);
    }

    function isOverLeveraged_(
        Match memory m,
        LeverageMath.Data storage leverage,
        PriceData calldata priceData,
        uint256 fmfr,
        bool isMaker,
        uint8 collateralDecimals
    ) public view returns (bool) {
        uint256 timeElapsed = m.start == 0 ? 0 : block.timestamp - m.start;
        return
            getLeverage(m, priceData, isMaker, 0, collateralDecimals) >=
            (
                isMaker
                    ? getMaxLeverage(
                        leverage,
                        m.frPerYear,
                        timeElapsed == 0
                            ? block.timestamp - priceData.timestamp
                            : timeElapsed,
                        fmfr
                    )
                    : timeElapsed == 0
                    ? leverage.maxLeverageOpen
                    : leverage.maxLeverageOngoing
            );
    }

    function getMaxLeverage(
        Data storage leverage,
        uint256 fr,
        uint256 timeElapsed,
        uint256 fmfr
    ) public view returns (uint256 maxLeverage) {
        // console.log("[_getMaxLeverage()] fr >= fmfr --> ", fr >= fmfr);
        // console.log("[_getMaxLeverage()] timeElapsed >= leverage.maxTimeGuarantee --> ", timeElapsed >= leverage.maxTimeGuarantee);

        // NOTE: Expecting time elapsed in days
        timeElapsed = timeElapsed / 86400;
        maxLeverage = ((fr >= fmfr) ||
            (timeElapsed >= leverage.maxTimeGuarantee))
            ? (timeElapsed == 0)
                ? leverage.maxLeverageOpen
                : leverage.maxLeverageOngoing
            : _min(
                _max(
                    ((leverage.s * leverage.FRTemporalBasis * leverage.b)
                        .bps() /
                        ((leverage.maxTimeGuarantee - timeElapsed) *
                            (fmfr - fr + leverage.f0))),
                    leverage.minGuaranteedLeverage
                ),
                leverage.maxLeverageOpen
            );
        // maxLeverage = (fr >= fmfr) ? type(uint256).max : (minRequiredMargin * timeToExpiry / (totTime * (fmfr - fr)));
    }

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
        uint256 notional = ((overrideAmount > 0) ? overrideAmount : m.amount) *
            ((isMaker && (m.trader == 0)) ? priceData.price : m.entryPrice);

        uint256 realizedPnL = m.accruedFR(priceData, collateralDecimals);
        uint256 collateral_plus_realizedPnL = (isMaker)
            ? m.collateralM + realizedPnL
            : m.collateralT - _min(m.collateralT, realizedPnL);
        if (collateral_plus_realizedPnL == 0) return type(uint256).max;

        // TODO: this is a simplification when removing the decimals lib,
        //       need to check and move to FinMath lib
        leverage = notional / (collateral_plus_realizedPnL * 10 ** 12);
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
import '@dex/lib/FinMath.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library PnLMath {
    using FinMath for uint24;
    using FinMath for int256;
    using FinMath for uint256;




    // NOTE: Need to move this computation out of `pnl()` to avoid the stack too deep issue in it
    function _gl(uint256 amount, int256 dp, uint256 collateralDecimals) internal pure returns(int256 gl) {
        gl = int256(10**(collateralDecimals)).wmul(int256(amount)).wmul(dp);       // Maker's GL        
    }

    function pnl(
        Match storage m,
        uint256 tokenId,
        uint256 timestamp,
        uint256 exitPrice,
        uint256 makerFRFee,
        uint8 collateralDecimals
    ) public view returns (int pnlM, int pnlT, uint256 FRfee) {
        require(timestamp > m.start, "engine/wrong_timestamp");
        require(
            (tokenId == m.maker) || (tokenId == m.trader),
            'engine/invalid-tokenId'
        );
        // uint deltaT = timestamp.sub(m.start);
        // int deltaP = exitPrice.isub(m.entryPrice);
        // int delt = (m.pos == POS_SHORT) ? -deltaP : deltaP;

        // NOTE: FR is seen from the perspective of the maker and it is >= 0 always by construction
        uint256 aFR = _accruedFR(timestamp.sub(m.start), m.frPerYear, m.amount, exitPrice, collateralDecimals);

        // NOTE: `m.pos` is the Maker Position
        int mgl = (((m.pos == POS_SHORT) ? int(-1) : int(1)) * _gl(m.amount, exitPrice.isub(m.entryPrice), collateralDecimals));

        // NOTE: Before deducting FR Fees, the 2 PnLs need to be symmetrical
        pnlM = mgl + int256(aFR); 
        pnlT = -pnlM;

        // NOTE: After the FR fees, no more symmetry
        FRfee = makerFRfees(makerFRFee, aFR);
        pnlM -= int256(FRfee);
    }

    function makerFRfees(uint256 makerFRFee, uint256 fundingRate) internal pure returns (uint256) {
        return makerFRFee.bps(fundingRate);
    }


    function accruedFR(
        Match memory m,
        PriceData memory priceData,
        uint8 collateralDecimals
    ) public view returns (uint256) {
        if (m.start == 0) return 0;
        uint256 deltaT = block.timestamp.sub(m.start);
        return _accruedFR(deltaT, m.frPerYear, m.amount, priceData.price, collateralDecimals);
    }

    function _accruedFR(
        uint256 deltaT,
        uint256 frPerYear,
        uint256 amount,
        uint256 price,
        uint8 collateralDecimals
    ) public pure returns (uint256) {
        return
            (10**(collateralDecimals)).mul(frPerYear).bps(deltaT).wmul(amount).wmul(price) / (3600 * 24 * 365);
    }

    function isLiquidatable(
        Match storage m,
        uint256 tokenId,
        uint256 price,
        Config calldata config,
        uint8 collateralDecimals
    ) external view returns (bool) {
        // check if the match has not previously been deleted
        if (m.maker == 0) return false;
        if (tokenId == m.maker) {
            (int pnlM, , ) = pnl(m, tokenId, block.timestamp, price, 0, collateralDecimals); // TODO: add makerFee
            int256 bufferMaker = config.bufferMakerBps.ibps(m.collateralM);
            return int256(m.collateralM) + pnlM - bufferMaker < config.liqBuffM;
        } else if (tokenId == m.trader) {
            (, int pnlT,) = pnl(m, tokenId, block.timestamp, price, 0, collateralDecimals); // TODO: add maker fee
            int256 bufferTrader = config.bufferTraderBps.ibps(m.collateralT);
            return int256(m.collateralT) + pnlT - bufferTrader < config.liqBuffT;
        } else {
            return false;
        }
    }

}

pragma solidity ^0.8.17;

int8 constant POS_SHORT = -1;
int8 constant POS_NEUTRAL = 0;
int8 constant POS_LONG = 1;

pragma solidity ^0.8.17;

// TODO: add minPremiumFee
struct Config {
    uint24 fmfrPerYear; // 4 decimals (bips)
    uint24 frPerYearModulo; // 4 decimals (bips)
    uint24 minFRPerYear; // 4 decimals (bips)
    uint24 openInterestCap; // 4 decimals (bips)
    uint24 premiumFeeBps; // % of the premium that protocol collects
    uint24 traderFeeBps; // 4 decimals (bips)
    uint24 bufferTraderBps;
    uint24 bufferMakerBps;
    uint64 bufferTrader;
    uint64 bufferMaker;
    uint128 minMakerFee; // minimum fee protocol collects from maker
    uint128 minPremiumFee;
    uint128 orderMinAmount;
    int liqBuffM;
    int liqBuffT;
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import '@dex/lib/NFTDescriptor.sol';
import '@dex/lib/PnLMath.sol';
import '@dex/lib/FeesMath.sol';
import '@dex/lib/FinMath.sol';
import '@dex/lib/Structs.sol';
import '@dex/oracles/interfaces/IOracle.sol';
import '@dex/perp/interfaces/IEngine.sol';
import '@dex/perp/interfaces/IVault.sol';
import '@dex/perp/interfaces/IPool.sol';
import '@dex/token/ERC721.sol';

import 'forge-std/console.sol';

// import "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";

contract Engine is ERC721, IEngineEvents {
    using PnLMath for Match;
    using LeverageMath for Match;
    using FinMath for int256;
    using FeesMath for Order;
    using NFTDescriptor for uint256;

    IOracle public oracle;

    // mint IDs
    uint128 private nextTokenId;
    uint128 private nextMatchId;

    // pending orders
    uint128 closeOrderToExecute;
    uint128 openOrderToExecute;

    // trader order queues
    Order[] public opens;
    CloseOrder[] closes;

    uint256 public openInterestCap; // [per]
    uint256 public makerFRFeePerc; // [per] Maker fee over his FR gains
    uint256 minPremiumFeeUSDC; // [wad]
    LeverageMath.Data private leverage;

    Config private config;

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
        LeverageMath.Data calldata leverage_,
        Config calldata config_
    ) external {
        oracle = IOracle(oracle_);
        pool = pool_;
        vault = vault_;
        leverage = leverage_;
        config = config_;

        tokenDecimals = vault.token().decimals();

        // skip 0 for those 2 counters
        nextTokenId = 1;
        nextMatchId = 1;

        leverage.maxLeverageOpen = 10 * 1e6; // Default max opening leverage is 10x
        leverage.maxLeverageOngoing = 16 * 1e6; // Default max running leverage is 16x
        openInterestCap = 15e5; // = 150%, once 15e5/1e6 = 1.5
        makerFRFeePerc = 300; // = 3% = 300 BSP = 0.03

        liquidationBuffer = 1000000 * 10**18;

        // ERC721
        nonce = 0;
        name = 'TEST';
        symbol = 'TST';
        minter = address(this);
    }

    function setLeverage(LeverageMath.Data calldata _leverage) external {
        leverage = _leverage;
    }

    // TODO: add makerFRFeePerc to config
    function setConfig(Config calldata _config) external {
        config = _config;
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
        require(amount > config.orderMinAmount, 'engine/order-min-amount');
        require(frPerYear >= config.minFRPerYear, 'engine/min-fr');
        require((frPerYear % config.frPerYearModulo) == 0, 'engine/fr_modulo');
        require(
            vault.balanceOf(recipient) >= collateral_,
            'engine/missing-collateral'
        );
        require(collateral_ > 0, 'engine/collateral-zero');
        mint(recipient, (tokenId = nextTokenId++));
        Match memory m;
        m.maker = tokenId; // the token owner is the maker of the match
        m.amount = amount;
        m.premiumBps = premiumBps;
        m.frPerYear = frPerYear;
        m.pos = pos;
        m.collateralM = collateral_;

        matches[(matchId = nextMatchId++)] = m; // use token-id as idx
        require(
            !matches[matchId].isOverLeveraged(
                leverage,
                oracle.getPrice(),
                config.fmfrPerYear,
                true,
                tokenDecimals
            ),
            'engine/over-leveraged'
        );
        // m.auto_resubmit = auto_resubmit;
        emit NewMakerOrder(recipient, matchId, tokenId);
    }

    // --- Trader ---

    // pick maker match
    function pick(
        // uint256 tokenId,
        uint256 matchId,
        uint256 amount,
        uint256 collateral_,
        int8 pos
    ) external {
        // the match should not be closed already
        Match memory m = matches[matchId];
        if (m.pos != POS_NEUTRAL) {
            require(pos == -1 * m.pos, 'engine/same-pos');
        }
        require(pos != POS_NEUTRAL, 'engine/neutral-pos');
        require(m.maker != 0, 'engine/unexisting_match');
        require(ownerOf(m.maker) != msg.sender, 'engine/trader_is_maker');
        require(amount > config.orderMinAmount, 'engine/order-min-amount');
        Order memory o;
        o.owner = msg.sender;
        o.matchId = matchId;
        o.amount = amount;
        o.collateral = collateral_;
        o.pos = pos;
        o.timestamp = block.timestamp;
        opens.push(o);

        emit NewTraderOrder(msg.sender, matchId, opens.length - 1);
    }

    // @notice Cancel trader order
    // @param id Order ID
    function cancelOrder(uint256 orderId) external {
        Order storage o = opens[orderId];
        require(o.owner == msg.sender, 'engine/non-trader');
        o.canceled = true;
        emit OrderCanceled(msg.sender, orderId, o.matchId);
    }

    function cancelMatch(uint256 matchId) external {
        Match memory m = matches[matchId];
        require(m.start == 0, 'engine/cancel-active-match');
        require(ownerOf(m.maker) == msg.sender, 'engine/only-maker');
        emit MatchCanceled(msg.sender, matchId);
        delete matches[matchId];
    }

    // @notice submit close trader order
    // @matchId match id that comes from UI
    function close(uint256 matchId) external {
        Match storage m = matches[matchId]; // load Match by trader matchId
        address trader = ownerOf(m.trader); // load trader add. by trader tokenid
        require(trader == msg.sender, 'engine/only-trader-operation');
        closes.push(CloseOrder(matchId, block.timestamp));
    }

    function increaseCollateral(uint256 matchId, uint256 amount) external {
        Match memory m = matches[matchId];
        require(
            vault.balanceOf(msg.sender) >= amount,
            'engine/insufficient-collateral'
        );
        vault.lock(amount, msg.sender);
        // increase maker collateral
        if (msg.sender == ownerOf(m.maker)) {
            m.collateralM += amount;
            matches[matchId] = m;
            emit CollateralIncreased(msg.sender, matchId, amount);
        } else if (msg.sender == ownerOf(m.trader)) {
            m.collateralT += amount;
            matches[matchId] = m;
            emit CollateralIncreased(msg.sender, matchId, amount);
        } else {
            revert('engine/maker-nor-trader');
        }
    }

    function decreaseCollateral(uint256 matchId, uint256 amount) external {
        require(amount > 0, 'engine/amount-zero');
        Match storage m = matches[matchId];
        PriceData memory priceData = oracle.getPrice();
        // increase maker collateral
        if (msg.sender == ownerOf(m.maker)) {
            require(m.collateralM >= amount, 'engine/collateral-too-low');
            m.collateralM -= amount;
            require(
                !m.isOverLeveraged(
                    leverage,
                    priceData,
                    config.fmfrPerYear,
                    true,
                    tokenDecimals
                ),
                'engine/max-leverage-open'
            );

            matches[matchId] = m;
            emit CollateralDecreased(msg.sender, matchId, amount);
        } else if (msg.sender == ownerOf(m.trader)) {
            require(m.collateralT >= amount, 'engine/collateral-too-low');
            m.collateralT -= amount;
            require(
                !m.isOverLeveraged(
                    leverage,
                    priceData,
                    config.fmfrPerYear,
                    false,
                    tokenDecimals
                ),
                'engine/max-leverage-open'
            );

            matches[matchId] = m;
            emit CollateralDecreased(msg.sender, matchId, amount);
        } else {
            revert('engine/maker-nor-trader');
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
        // NOTE: Switching from `storage` to `memory` so we can still run checks using match functions without modifying the storage until the end of the function
        Match memory m = matches[order.matchId]; // load by the selected maker tokenid

        // check if order is canceled or has already been matched
        if (order.canceled || m.trader != 0) {
            return;
        }
        if (m.maker == 0) {
            emit MatchInexistant(order.matchId, orderId);
            return;
        }
        // load maker address from tokenId
        address maker = ownerOf(m.maker);
        // early bailout in case the join is impossible
        if (order.owner == maker) {
            emit MakerIsTrader(order.matchId, maker, orderId);
            return;
        }

        if (vault.balanceOf(order.owner) < order.collateral) {
            emit LowTraderCollateral(
                order.matchId,
                order.owner,
                orderId,
                vault.balanceOf(order.owner),
                order.collateral
            );
            return;
        }

        // --- Trader Fees ---
        uint256 traderFees = order.traderFees(priceData, config.traderFeeBps);

        (int256 premiumT, uint256 premiumFee) = order.computePremiumAndFee(
            priceData,
            m.premiumBps,
            config.premiumFeeBps,
            config.minPremiumFee
        );

        if (int256(order.collateral) <= (int256(traderFees) + premiumT)) {
            emit LowTraderCollateralForFees(
                order.matchId,
                order.owner,
                orderId,
                order.collateral,
                traderFees
            );
            return;
        }

        // NOTE: We can use negative premium to cover the traderFees at least partially, excess will go to Trader Vault Account
        int256 _deltaT = premiumT.add(traderFees); //  int256(traderFees) + premiumT;
        m.collateralT = order.collateral - _deltaT.pos();

        // if (
        //     m.collateralM <= makerFees ||
        //     (premium < 0 && m.collateralM < (uint256(-premium) + makerFees))
        // )

        if (int256(m.collateralM) <= -premiumT + int256(premiumFee)) {
            emit LowMakerCollateralForFees(
                order.matchId,
                maker,
                orderId,
                m.collateralM,
                premiumFee
            );
            return;
        }

        // NOTE: We can use poisitive premium to cover the makerFees, excess will go to Maker Vault Account
        int256 _deltaM = int256(premiumFee) - premiumT;
        m.collateralM = m.collateralM - _deltaM.pos();

        // // NOTE: Fees paid by the trader upfront
        // m.collateralT = order.collateral - traderFees;
        // m.collateralM -= makerFees;

        // --- Leverage ---
        if (
            m.isOverLeveraged_(
                leverage,
                priceData,
                config.fmfrPerYear,
                false,
                tokenDecimals
            )
        ) {
            emit MaxOpeningLeverage(
                order.owner,
                order.matchId,
                orderId,
                priceData.price
            );
            return;
        }

        if (
            m.isOverLeveraged_(
                leverage,
                priceData,
                config.fmfrPerYear,
                true,
                tokenDecimals
            )
        ) {
            emit MaxOpeningLeverage(
                ownerOf(m.maker),
                order.matchId,
                orderId,
                priceData.price
            );
            return;
        }

        if (vault.balanceOf(maker) < m.collateralM) {
            emit LowMakerCollateral(
                order.matchId,
                maker,
                orderId,
                vault.balanceOf(maker),
                m.collateralM
            );
            return;
        }

        if (
            (order.maxTimestamp > 0) &&
            (priceData.timestamp > order.maxTimestamp)
        ) {
            emit OrderExpired(
                order.matchId,
                order.owner,
                maker,
                orderId,
                order.maxTimestamp
            );
            return;
        }

        // No more checks so here we can modify the state safely

        // NOTE: Store the modifications
        matches[order.matchId] = m;
        Match storage M = matches[order.matchId];

        uint256 tokenId = nextTokenId++;
        mint(order.owner, tokenId);
        M.trader = tokenId; // setup match with the trader token
        // m.collateralT = uint128(collateralT); // setup match with trader collateral
        M.start = uint128(priceData.timestamp); // set oracle time we matched
        M.entryPrice = priceData.price; // set oracle price on match
        M.fmfrPerYear = config.fmfrPerYear;

        if (order.amount < M.amount)
            _split(
                /*ownerOf(o.tokenId),*/
                M,
                order.amount
            );

        // NOTE: Makers can choose to be long or short or neutral so that it is the trader deciding
        M.pos = (M.pos == POS_NEUTRAL) ? (-1 * order.pos) : M.pos;

        // update the balance available to trader/maker

        if (_deltaT < 0) {
            // NOTE: Crediting excess negative premium to the Trader Vault Account
            vault.unlock(uint256(-_deltaT), order.owner);
        }

        if (_deltaM < 0) {
            // NOTE: Crediting excess positive premium to the Maker Vault Account
            vault.unlock(uint256(-_deltaM), maker);
        }

        // if (premiumT >= 0) {
        //     // NOTE: Trader should not be paying this from their personal vault account but from the position collateral only
        //     // vault.lock(uint256(premium), order.owner);
        //     // order.collateral -= uint256(premiumT);

        //     vault.unlock(uint256(premiumT), maker);
        //     // m.collateralM += uint256(premium);
        // } else {
        //     vault.unlock(uint256(-premiumT), order.owner);
        //     // vault.lock(uint256(-premium), maker);
        //     // order.collateral += uint256(-premium);
        //     // m.collateralM -= uint256(-premiumT);
        // }

        vault.lock(M.collateralT, order.owner);
        vault.lock(M.collateralM, maker);

        // vault.lock(order.collateral, order.owner);
        // vault.lock(m.collateralM, maker);

        emit ActiveMatch(
            order.matchId,
            maker,
            order.owner,
            orderId,
            M.maker,
            M.trader
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
            makerFRFeePerc,
            tokenDecimals
        );
        address maker = ownerOf(m.maker);
        address trader = ownerOf(m.trader);
        _settlePnL(maker, true, int256(m.collateralM) + pnLM);
        _settlePnL(trader, false, int256(m.collateralT) + pnLT);
        pool.updateNotional(address(oracle), priceData.price, m.amount, true);
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
        require(amount < m.amount, 'engine/unecessary-split');
        uint256 newAmount = m.amount - amount;
        if (newAmount <= config.orderMinAmount) {
            return (0, 0);
        }
        address maker = ownerOf(m.maker);
        mint(maker, (tokenId = nextTokenId++)); // mint maker token
        Match memory newMatch;
        newMatch.maker = tokenId;
        newMatch.amount = newAmount;
        newMatch.premiumBps = m.premiumBps;
        newMatch.frPerYear = m.frPerYear;
        newMatch.pos = m.pos;
        newMatch.collateralM =
            m.collateralM -
            ((m.collateralM * amount) / m.amount);
        // create a new potential match in the order book;
        matches[(matchId = nextMatchId++)] = newMatch;
        // effects
        m.collateralM = ((m.collateralM * amount) / m.amount);
        // m.collateralM = m.collateralM - ((m.collateralM * amount) / m.amount);
        // m.collateralM = uint128(m.collateralM * (1 - (amount / m.amount)));
        m.amount = amount;

        emit NewMakerOrder(maker, matchId, tokenId);
    }

    function _settlePnL(
        address user,
        bool isMaker,
        int256 pnl_
    ) internal {
        // TODO: This is incomplete since we need to remove the settled PnL from the current uPnL
        int256 _newBalance = (int256(vault.balanceOf(user)) + pnl_);
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
                makerFRFeePerc,
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
                    ownerOf(m.maker)
                );
                pool.updateNotional(address(oracle), p.price, m.amount, true);
                emit MatchLiquidated(matchId, pnlM, oracle.getPrice().price);
                delete matches[matchId].maker;
            }
        }
    }

    function runOpens(uint256 n) external {
        PriceData memory p = oracle.getPrice();
        require(
            opens.length > openOrderToExecute &&
                p.timestamp > opens[openOrderToExecute].timestamp,
            'engine/empty-queue'
        );
        n = (n == 0)
            ? opens.length
            : Math.min(openOrderToExecute + n, opens.length);

        // run the last queue and update the price
        while (openOrderToExecute < n) {
            Order storage order = opens[openOrderToExecute];
            // check if price is recent enough, break the loop if not as all further order will be too recent
            if (p.timestamp < order.timestamp) break;
            uint256 poolBalance = vault.token().balanceOf(address(pool)); // TODO: token type is in the vault?
            pool.updateNotional(address(oracle), p.price, order.amount, false);
            if (!pool.validateOICap(config.openInterestCap, poolBalance)) break;
            join(order, p, openOrderToExecute);
            delete opens[openOrderToExecute];
            openOrderToExecute++;
        }
    }

    function runCloses(uint256 n) external {
        require(
            closes.length > closeOrderToExecute &&
                oracle.getPrice().timestamp >
                closes[closeOrderToExecute].timestamp,
            'nothing to run'
        );
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
import '@dex/perp/Vault.sol';
import '@dex/perp/interfaces/IPool.sol';
import '@dex/perp/Pool.sol';

import '@dex/lib/Structs.sol';
import '@dex/oracles/GelatoOracleFactory.sol';

contract EngineFactory is Ownable {
    using Clones for address;

    address engineImplementation;

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

    function deployEngine(
        OracleArguments calldata oracleArguments,
        LeverageMath.Data calldata leverage_,
        Config calldata config
    ) external onlyOwner returns (address newEngine) {
        newEngine = engineImplementation.clone();

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
            leverage_,
            config
        );
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
    uint256 totalNotionalValue;
    uint256 withdrawRatio; // scaling factor to gauge withdraw lock

    mapping(address => Notional) public notionals; // to calculate total open interest for all markets
    address[] public markets; // keep a list of unique markets

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

    // to track all markets risk
    struct Notional {
        uint256 amount; // open position amount
        uint256 price; // last updated price
        uint256 value; // notional value = amount * price
        bool added;
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
        totalNotionalValue = 0;
        withdrawRatio = 200e4; // = 200% [200e4/1e6 = 2]
    }

    // TODO: secure this function with msg.sender call + sanity checks
    function updateNotional(
        address oracle,
        uint256 price,
        uint256 amount,
        bool decrease
    ) external {
        uint256 current = notionals[oracle].amount;
        uint256 updated = (decrease) ? current - amount : current + amount;
        notionals[oracle].amount = updated;
        notionals[oracle].price = price;
        notionals[oracle].value = (updated * price) / PRECISION;
        addMarket(oracle);
    }

    // Keep a list of unique oracles updated so we can loop and get the total open interest from the mapping
    function addMarket(address oracle) internal {
        if (!notionals[oracle].added) {
            markets.push(oracle);
            notionals[oracle].added = true;
        }
    }

    function totalNotional() public view returns (uint256 total) {
        for (uint16 i = 0; i < markets.length; i++) {
            total += notionals[markets[i]].value;
        }
    }

    // return true if is valid
    function validateOICap(
        uint256 openInterestCap,
        uint256 poolBalance
    ) external view returns (bool) {
        uint256 oi = totalNotional() / poolBalance; // we do want the percentage use
        return (poolBalance == 0 || oi.bps() <= openInterestCap);
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
            // check if this request apply for open interest conditions
            uint256 balance = IERC20(usdc).balanceOf(address(this));
            uint256 scaled = (balance * withdrawRatio) / PERCENT;
            require(totalNotional() < scaled, 'pool/LP-deposit-threshold');
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
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@dex/perp/interfaces/IVault.sol';

contract Vault is IVault, Ownable {
    address collateralToken;

    uint256 public totalFees;

    // NOTE: Accounts of addresses
    mapping(address => uint256) public collateral;

    // list of engines approved to manipulate user balance
    mapping(address => bool) public approved;

    modifier onlyApproved() {
        require(approved[msg.sender], 'not-approved');
        _;
    }

    constructor(address collateralToken_) {
        collateralToken = collateralToken_;
    }

    function token() external view override returns (IERC20Metadata) {
        return IERC20Metadata(collateralToken);
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return collateral[account];
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@dex/lib/LeverageMath.sol';
import '@dex/lib/Structs.sol';
import '@dex/perp/interfaces/IVault.sol';
import '@dex/perp/interfaces/IPool.sol';

interface IEngineEvents {
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

    event LowTraderCollateralForFees(
        uint256 indexed matchId,
        address indexed trader,
        uint256 orderId,
        uint256 allocatedCollateral,
        uint256 traderFees
    );

    event LowMakerCollateralForFees(
        uint256 indexed matchId,
        address indexed maker,
        uint256 orderId,
        uint256 allocatedCollateral,
        uint256 makerFees
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

    event MatchInexistant(uint256 indexed matchId, uint256 indexed orderId);

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
        LeverageMath.Data memory leverage_,
        Config calldata config_
    ) external;

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

    function updateNotional(
        address oracle,
        uint256 price,
        uint256 amount,
        bool decrease
    ) external;

    function totalNotional() external view returns (uint256 total);

    function validateOICap(
        uint256 openInterestCap,
        uint256 poolBalance
    ) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IVault {
    function token() external view returns (IERC20Metadata);

    function balanceOf(address) external view returns (uint256);

    function addFees(uint256 amount) external;

    function transfer(uint256 amount, address recipient) external;

    function lock(uint256 amount, address account) external;

    function unlock(uint256 amount, address account) external;

    function assign(uint256 amount, address account) external;

    function deposit(uint256 amount, address recipient) external;

    function withdraw(uint256 amount, address recipient) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/token/IERC721.sol';
import 'ds-auth/auth.sol';

// https://gist.github.com/ptescher/b23da69d03650364b3f6c8b8e2337233
contract ERC721 is IERC721 {
    uint256 public nonce;
    string public name;
    string public symbol;
    address public minter;

    mapping(uint256 => address) public owners;
    mapping(address => uint256) public balances;
    mapping(uint256 => address) public approvals;
    mapping(address => mapping(address => bool)) private operatorApprovals;

    event Transfer(address indexed src, address indexed dst, uint id);
    event Approval(address owner, address dst, uint id);
    event ApprovalForAll(address owner, address operator, bool approved);

    function safeTransferFrom(address src, address dst, uint id) external {
        require(
            isApprovedOrOwner(msg.sender, id),
            'ERC721/caller-not-owner-approved'
        );
        _transfer(src, dst, id);
    }

    function safeTransferFrom(
        address src,
        address dst,
        uint id,
        bytes calldata data
    ) external {
        require(
            isApprovedOrOwner(msg.sender, id),
            'ERC721/caller-not-owner-approved'
        );
        _transfer(src, dst, id);
        require(
            _checkOnERC721Received(src, dst, id, data),
            'ERC721/transfer-to-non-ERC721Receiver-implementer'
        );
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract. If address code length is > 0
     * we know that the address comes from a deployed contract.
     *
     * @param src address representing the previous owner of the given token ID
     * @param dst target address that will receive the tokens
     * @param id uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address src,
        address dst,
        uint256 id,
        bytes memory data
    ) private returns (bool) {
        if (dst.code.length > 0) {
            try
                IERC721Receiver(dst).onERC721Received(msg.sender, src, id, data)
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721/transfer-to-non-ERC721Receiver-implementer');
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function transferFrom(address src, address dst, uint id) external {
        require(
            isApprovedOrOwner(msg.sender, id),
            'ERC721/not-owner-or-approved'
        );
        _transfer(src, dst, id);
    }

    function approve(address dst, uint id) external {
        address owner = ownerOf(id);
        bool all = operatorApprovals[owner][msg.sender];
        require(dst != owner, 'ERC721/approval-current-owner');
        require(
            msg.sender == owner || all,
            'ERC721/caller-not-owner-or-approved-all'
        );
        approvals[id] = dst;
        emit Approval(ownerOf(id), dst, id);
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(msg.sender != operator, 'ERC721/approve-to-caller'); //msg.sender is owner
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // --- Views ---
    function getApproved(uint id) external view returns (address operator) {
        require(owners[id] != address(0), 'ERC721/zero-address');
        return approvals[id];
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), 'ERC721/zero-owner-address');
        return balances[owner];
    }

    function ownerOf(uint256 id) public view returns (address) {
        address owner = owners[id];
        require(owner != address(0), 'ERC721/invalid-token-id');
        return owner;
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function isApprovedOrOwner(
        address spender,
        uint256 id
    ) internal view returns (bool) {
        address owner = ownerOf(id);
        return (spender == owner ||
            operatorApprovals[owner][spender] ||
            approvals[id] == spender);
    }

    function mint(address dst, uint matchid) public returns (uint) {
        balances[dst] = matchid;
        owners[matchid] = dst;
        nonce++;
        emit Transfer(address(0), dst, nonce);
        return nonce;
    }

    // --- Internals ---
    function _transfer(address src, address dst, uint256 id) internal {
        require(ERC721.ownerOf(id) == src, 'ERC721/src-incorrect-owner');
        require(dst != address(0), 'ERC721/transfer-zero-address');

        // Clear approvals src the previous owner
        delete approvals[id];

        balances[src] -= 1;
        balances[dst] += 1;
        owners[id] = dst;
        emit Transfer(src, dst, id);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint balance);

    function ownerOf(uint tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes calldata data
    ) external;

    function transferFrom(address from, address to, uint tokenId) external;

    function approve(address to, uint tokenId) external;

    function getApproved(uint tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}