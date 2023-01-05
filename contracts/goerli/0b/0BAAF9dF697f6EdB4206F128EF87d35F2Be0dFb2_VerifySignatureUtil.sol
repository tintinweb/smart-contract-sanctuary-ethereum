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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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
            uint256 length = 1;

            // compute log10(value), and add it to length
            uint256 valueCopy = value;
            if (valueCopy >= 10**64) {
                valueCopy /= 10**64;
                length += 64;
            }
            if (valueCopy >= 10**32) {
                valueCopy /= 10**32;
                length += 32;
            }
            if (valueCopy >= 10**16) {
                valueCopy /= 10**16;
                length += 16;
            }
            if (valueCopy >= 10**8) {
                valueCopy /= 10**8;
                length += 8;
            }
            if (valueCopy >= 10**4) {
                valueCopy /= 10**4;
                length += 4;
            }
            if (valueCopy >= 10**2) {
                valueCopy /= 10**2;
                length += 2;
            }
            if (valueCopy >= 10**1) {
                length += 1;
            }
            // now, length is log10(value) + 1

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
            uint256 length = 1;

            // compute log256(value), and add it to length
            uint256 valueCopy = value;
            if (valueCopy >= 1 << 128) {
                valueCopy >>= 128;
                length += 16;
            }
            if (valueCopy >= 1 << 64) {
                valueCopy >>= 64;
                length += 8;
            }
            if (valueCopy >= 1 << 32) {
                valueCopy >>= 32;
                length += 4;
            }
            if (valueCopy >= 1 << 16) {
                valueCopy >>= 16;
                length += 2;
            }
            if (valueCopy >= 1 << 8) {
                valueCopy >>= 8;
                length += 1;
            }
            // now, length is log256(value) + 1

            return toHexString(value, length);
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

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
  struct slice {
    uint256 _len;
    uint256 _ptr;
  }

  function memcpy(
    uint256 dest,
    uint256 src,
    uint256 len
  ) private pure {
    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint256 mask = type(uint256).max;
    if (len > 0) {
      mask = 256**(32 - len) - 1;
    }
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }
  }

  /*
   * @dev Returns a slice containing the entire string.
   * @param self The string to make a slice from.
   * @return A newly allocated slice containing the entire string.
   */
  function toSlice(string memory self) internal pure returns (slice memory) {
    uint256 ptr;
    assembly {
      ptr := add(self, 0x20)
    }
    return slice(bytes(self).length, ptr);
  }

  /*
   * @dev Returns the length of a null-terminated bytes32 string.
   * @param self The value to find the length of.
   * @return The length of the string, from 0 to 32.
   */
  function len(bytes32 self) internal pure returns (uint256) {
    uint256 ret;
    if (self == 0) return 0;
    if (uint256(self) & type(uint128).max == 0) {
      ret += 16;
      self = bytes32(uint256(self) / 0x100000000000000000000000000000000);
    }
    if (uint256(self) & type(uint64).max == 0) {
      ret += 8;
      self = bytes32(uint256(self) / 0x10000000000000000);
    }
    if (uint256(self) & type(uint32).max == 0) {
      ret += 4;
      self = bytes32(uint256(self) / 0x100000000);
    }
    if (uint256(self) & type(uint16).max == 0) {
      ret += 2;
      self = bytes32(uint256(self) / 0x10000);
    }
    if (uint256(self) & type(uint8).max == 0) {
      ret += 1;
    }
    return 32 - ret;
  }

  /*
   * @dev Returns a slice containing the entire bytes32, interpreted as a
   *      null-terminated utf-8 string.
   * @param self The bytes32 value to convert to a slice.
   * @return A new slice containing the value of the input argument up to the
   *         first null.
   */
  function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
    // Allocate space for `self` in memory, copy it there, and point ret at it
    assembly {
      let ptr := mload(0x40)
      mstore(0x40, add(ptr, 0x20))
      mstore(ptr, self)
      mstore(add(ret, 0x20), ptr)
    }
    ret._len = len(self);
  }

  /*
   * @dev Returns a new slice containing the same data as the current slice.
   * @param self The slice to copy.
   * @return A new slice containing the same data as `self`.
   */
  function copy(slice memory self) internal pure returns (slice memory) {
    return slice(self._len, self._ptr);
  }

  /*
   * @dev Copies a slice to a new string.
   * @param self The slice to copy.
   * @return A newly allocated string containing the slice's text.
   */
  function toString(slice memory self) internal pure returns (string memory) {
    string memory ret = new string(self._len);
    uint256 retptr;
    assembly {
      retptr := add(ret, 32)
    }

    memcpy(retptr, self._ptr, self._len);
    return ret;
  }

  /*
   * @dev Returns the length in runes of the slice. Note that this operation
   *      takes time proportional to the length of the slice; avoid using it
   *      in loops, and call `slice.empty()` if you only need to know whether
   *      the slice is empty or not.
   * @param self The slice to operate on.
   * @return The length of the slice in runes.
   */
  function len(slice memory self) internal pure returns (uint256 l) {
    // Starting at ptr-31 means the LSB will be the byte we care about
    uint256 ptr = self._ptr - 31;
    uint256 end = ptr + self._len;
    for (l = 0; ptr < end; l++) {
      uint8 b;
      assembly {
        b := and(mload(ptr), 0xFF)
      }
      if (b < 0x80) {
        ptr += 1;
      } else if (b < 0xE0) {
        ptr += 2;
      } else if (b < 0xF0) {
        ptr += 3;
      } else if (b < 0xF8) {
        ptr += 4;
      } else if (b < 0xFC) {
        ptr += 5;
      } else {
        ptr += 6;
      }
    }
  }

  /*
   * @dev Returns true if the slice is empty (has a length of 0).
   * @param self The slice to operate on.
   * @return True if the slice is empty, False otherwise.
   */
  function empty(slice memory self) internal pure returns (bool) {
    return self._len == 0;
  }

  /*
   * @dev Returns a positive number if `other` comes lexicographically after
   *      `self`, a negative number if it comes before, or zero if the
   *      contents of the two slices are equal. Comparison is done per-rune,
   *      on unicode codepoints.
   * @param self The first slice to compare.
   * @param other The second slice to compare.
   * @return The result of the comparison.
   */
  function compare(slice memory self, slice memory other) internal pure returns (int256) {
    uint256 shortest = self._len;
    if (other._len < self._len) shortest = other._len;

    uint256 selfptr = self._ptr;
    uint256 otherptr = other._ptr;
    for (uint256 idx = 0; idx < shortest; idx += 32) {
      uint256 a;
      uint256 b;
      assembly {
        a := mload(selfptr)
        b := mload(otherptr)
      }
      if (a != b) {
        // Mask out irrelevant bytes and check again
        uint256 mask = type(uint256).max; // 0xffff...
        if (shortest < 32) {
          mask = ~(2**(8 * (32 - shortest + idx)) - 1);
        }
        unchecked {
          uint256 diff = (a & mask) - (b & mask);
          if (diff != 0) return int256(diff);
        }
      }
      selfptr += 32;
      otherptr += 32;
    }
    return int256(self._len) - int256(other._len);
  }

  /*
   * @dev Returns true if the two slices contain the same text.
   * @param self The first slice to compare.
   * @param self The second slice to compare.
   * @return True if the slices are equal, false otherwise.
   */
  function equals(slice memory self, slice memory other) internal pure returns (bool) {
    return compare(self, other) == 0;
  }

  /*
   * @dev Extracts the first rune in the slice into `rune`, advancing the
   *      slice to point to the next rune and returning `self`.
   * @param self The slice to operate on.
   * @param rune The slice that will contain the first rune.
   * @return `rune`.
   */
  function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
    rune._ptr = self._ptr;

    if (self._len == 0) {
      rune._len = 0;
      return rune;
    }

    uint256 l;
    uint256 b;
    // Load the first byte of the rune into the LSBs of b
    assembly {
      b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
    }
    if (b < 0x80) {
      l = 1;
    } else if (b < 0xE0) {
      l = 2;
    } else if (b < 0xF0) {
      l = 3;
    } else {
      l = 4;
    }

    // Check for truncated codepoints
    if (l > self._len) {
      rune._len = self._len;
      self._ptr += self._len;
      self._len = 0;
      return rune;
    }

    self._ptr += l;
    self._len -= l;
    rune._len = l;
    return rune;
  }

  /*
   * @dev Returns the first rune in the slice, advancing the slice to point
   *      to the next rune.
   * @param self The slice to operate on.
   * @return A slice containing only the first rune from `self`.
   */
  function nextRune(slice memory self) internal pure returns (slice memory ret) {
    nextRune(self, ret);
  }

  /*
   * @dev Returns the number of the first codepoint in the slice.
   * @param self The slice to operate on.
   * @return The number of the first codepoint in the slice.
   */
  function ord(slice memory self) internal pure returns (uint256 ret) {
    if (self._len == 0) {
      return 0;
    }

    uint256 word;
    uint256 length;
    uint256 divisor = 2**248;

    // Load the rune into the MSBs of b
    assembly {
      word := mload(mload(add(self, 32)))
    }
    uint256 b = word / divisor;
    if (b < 0x80) {
      ret = b;
      length = 1;
    } else if (b < 0xE0) {
      ret = b & 0x1F;
      length = 2;
    } else if (b < 0xF0) {
      ret = b & 0x0F;
      length = 3;
    } else {
      ret = b & 0x07;
      length = 4;
    }

    // Check for truncated codepoints
    if (length > self._len) {
      return 0;
    }

    for (uint256 i = 1; i < length; i++) {
      divisor = divisor / 256;
      b = (word / divisor) & 0xFF;
      if (b & 0xC0 != 0x80) {
        // Invalid UTF-8 sequence
        return 0;
      }
      ret = (ret * 64) | (b & 0x3F);
    }

    return ret;
  }

  /*
   * @dev Returns the keccak-256 hash of the slice.
   * @param self The slice to hash.
   * @return The hash of the slice.
   */
  function keccak(slice memory self) internal pure returns (bytes32 ret) {
    assembly {
      ret := keccak256(mload(add(self, 32)), mload(self))
    }
  }

  /*
   * @dev Returns true if `self` starts with `needle`.
   * @param self The slice to operate on.
   * @param needle The slice to search for.
   * @return True if the slice starts with the provided text, false otherwise.
   */
  function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
    if (self._len < needle._len) {
      return false;
    }

    if (self._ptr == needle._ptr) {
      return true;
    }

    bool equal;
    assembly {
      let length := mload(needle)
      let selfptr := mload(add(self, 0x20))
      let needleptr := mload(add(needle, 0x20))
      equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
    }
    return equal;
  }

  /*
   * @dev If `self` starts with `needle`, `needle` is removed from the
   *      beginning of `self`. Otherwise, `self` is unmodified.
   * @param self The slice to operate on.
   * @param needle The slice to search for.
   * @return `self`
   */
  function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
    if (self._len < needle._len) {
      return self;
    }

    bool equal = true;
    if (self._ptr != needle._ptr) {
      assembly {
        let length := mload(needle)
        let selfptr := mload(add(self, 0x20))
        let needleptr := mload(add(needle, 0x20))
        equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
      }
    }

    if (equal) {
      self._len -= needle._len;
      self._ptr += needle._len;
    }

    return self;
  }

  /*
   * @dev Returns true if the slice ends with `needle`.
   * @param self The slice to operate on.
   * @param needle The slice to search for.
   * @return True if the slice starts with the provided text, false otherwise.
   */
  function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
    if (self._len < needle._len) {
      return false;
    }

    uint256 selfptr = self._ptr + self._len - needle._len;

    if (selfptr == needle._ptr) {
      return true;
    }

    bool equal;
    assembly {
      let length := mload(needle)
      let needleptr := mload(add(needle, 0x20))
      equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
    }

    return equal;
  }

  /*
   * @dev If `self` ends with `needle`, `needle` is removed from the
   *      end of `self`. Otherwise, `self` is unmodified.
   * @param self The slice to operate on.
   * @param needle The slice to search for.
   * @return `self`
   */
  function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
    if (self._len < needle._len) {
      return self;
    }

    uint256 selfptr = self._ptr + self._len - needle._len;
    bool equal = true;
    if (selfptr != needle._ptr) {
      assembly {
        let length := mload(needle)
        let needleptr := mload(add(needle, 0x20))
        equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
      }
    }

    if (equal) {
      self._len -= needle._len;
    }

    return self;
  }

  // Returns the memory address of the first byte of the first occurrence of
  // `needle` in `self`, or the first byte after `self` if not found.
  function findPtr(
    uint256 selflen,
    uint256 selfptr,
    uint256 needlelen,
    uint256 needleptr
  ) private pure returns (uint256) {
    uint256 ptr = selfptr;
    uint256 idx;

    if (needlelen <= selflen) {
      if (needlelen <= 32) {
        bytes32 mask;
        if (needlelen > 0) {
          mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
        }

        bytes32 needledata;
        assembly {
          needledata := and(mload(needleptr), mask)
        }

        uint256 end = selfptr + selflen - needlelen;
        bytes32 ptrdata;
        assembly {
          ptrdata := and(mload(ptr), mask)
        }

        while (ptrdata != needledata) {
          if (ptr >= end) return selfptr + selflen;
          ptr++;
          assembly {
            ptrdata := and(mload(ptr), mask)
          }
        }
        return ptr;
      } else {
        // For long needles, use hashing
        bytes32 hash;
        assembly {
          hash := keccak256(needleptr, needlelen)
        }

        for (idx = 0; idx <= selflen - needlelen; idx++) {
          bytes32 testHash;
          assembly {
            testHash := keccak256(ptr, needlelen)
          }
          if (hash == testHash) return ptr;
          ptr += 1;
        }
      }
    }
    return selfptr + selflen;
  }

  // Returns the memory address of the first byte after the last occurrence of
  // `needle` in `self`, or the address of `self` if not found.
  function rfindPtr(
    uint256 selflen,
    uint256 selfptr,
    uint256 needlelen,
    uint256 needleptr
  ) private pure returns (uint256) {
    uint256 ptr;

    if (needlelen <= selflen) {
      if (needlelen <= 32) {
        bytes32 mask;
        if (needlelen > 0) {
          mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
        }

        bytes32 needledata;
        assembly {
          needledata := and(mload(needleptr), mask)
        }

        ptr = selfptr + selflen - needlelen;
        bytes32 ptrdata;
        assembly {
          ptrdata := and(mload(ptr), mask)
        }

        while (ptrdata != needledata) {
          if (ptr <= selfptr) return selfptr;
          ptr--;
          assembly {
            ptrdata := and(mload(ptr), mask)
          }
        }
        return ptr + needlelen;
      } else {
        // For long needles, use hashing
        bytes32 hash;
        assembly {
          hash := keccak256(needleptr, needlelen)
        }
        ptr = selfptr + (selflen - needlelen);
        while (ptr >= selfptr) {
          bytes32 testHash;
          assembly {
            testHash := keccak256(ptr, needlelen)
          }
          if (hash == testHash) return ptr + needlelen;
          ptr -= 1;
        }
      }
    }
    return selfptr;
  }

  /*
   * @dev Modifies `self` to contain everything from the first occurrence of
   *      `needle` to the end of the slice. `self` is set to the empty slice
   *      if `needle` is not found.
   * @param self The slice to search and modify.
   * @param needle The text to search for.
   * @return `self`.
   */
  function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
    self._len -= ptr - self._ptr;
    self._ptr = ptr;
    return self;
  }

  /*
   * @dev Modifies `self` to contain the part of the string from the start of
   *      `self` to the end of the first occurrence of `needle`. If `needle`
   *      is not found, `self` is set to the empty slice.
   * @param self The slice to search and modify.
   * @param needle The text to search for.
   * @return `self`.
   */
  function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
    uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
    self._len = ptr - self._ptr;
    return self;
  }

  /*
   * @dev Splits the slice, setting `self` to everything after the first
   *      occurrence of `needle`, and `token` to everything before it. If
   *      `needle` does not occur in `self`, `self` is set to the empty slice,
   *      and `token` is set to the entirety of `self`.
   * @param self The slice to split.
   * @param needle The text to search for in `self`.
   * @param token An output parameter to which the first token is written.
   * @return `token`.
   */
  function split(
    slice memory self,
    slice memory needle,
    slice memory token
  ) internal pure returns (slice memory) {
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
    token._ptr = self._ptr;
    token._len = ptr - self._ptr;
    if (ptr == self._ptr + self._len) {
      // Not found
      self._len = 0;
    } else {
      self._len -= token._len + needle._len;
      self._ptr = ptr + needle._len;
    }
    return token;
  }

  /*
   * @dev Splits the slice, setting `self` to everything after the first
   *      occurrence of `needle`, and returning everything before it. If
   *      `needle` does not occur in `self`, `self` is set to the empty slice,
   *      and the entirety of `self` is returned.
   * @param self The slice to split.
   * @param needle The text to search for in `self`.
   * @return The part of `self` up to the first occurrence of `delim`.
   */
  function split(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory token)
  {
    split(self, needle, token);
  }

  /*
   * @dev Splits the slice, setting `self` to everything before the last
   *      occurrence of `needle`, and `token` to everything after it. If
   *      `needle` does not occur in `self`, `self` is set to the empty slice,
   *      and `token` is set to the entirety of `self`.
   * @param self The slice to split.
   * @param needle The text to search for in `self`.
   * @param token An output parameter to which the first token is written.
   * @return `token`.
   */
  function rsplit(
    slice memory self,
    slice memory needle,
    slice memory token
  ) internal pure returns (slice memory) {
    uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
    token._ptr = ptr;
    token._len = self._len - (ptr - self._ptr);
    if (ptr == self._ptr) {
      // Not found
      self._len = 0;
    } else {
      self._len -= token._len + needle._len;
    }
    return token;
  }

  /*
   * @dev Splits the slice, setting `self` to everything before the last
   *      occurrence of `needle`, and returning everything after it. If
   *      `needle` does not occur in `self`, `self` is set to the empty slice,
   *      and the entirety of `self` is returned.
   * @param self The slice to split.
   * @param needle The text to search for in `self`.
   * @return The part of `self` after the last occurrence of `delim`.
   */
  function rsplit(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory token)
  {
    rsplit(self, needle, token);
  }

  /*
   * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
   * @param self The slice to search.
   * @param needle The text to search for in `self`.
   * @return The number of occurrences of `needle` found in `self`.
   */
  function count(slice memory self, slice memory needle) internal pure returns (uint256 cnt) {
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
    while (ptr <= self._ptr + self._len) {
      cnt++;
      ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
    }
  }

  /*
   * @dev Returns True if `self` contains `needle`.
   * @param self The slice to search.
   * @param needle The text to search for in `self`.
   * @return True if `needle` is found in `self`, false otherwise.
   */
  function contains(slice memory self, slice memory needle) internal pure returns (bool) {
    return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
  }

  /*
   * @dev Returns a newly allocated string containing the concatenation of
   *      `self` and `other`.
   * @param self The first slice to concatenate.
   * @param other The second slice to concatenate.
   * @return The concatenation of the two strings.
   */
  function concat(slice memory self, slice memory other) internal pure returns (string memory) {
    string memory ret = new string(self._len + other._len);
    uint256 retptr;
    assembly {
      retptr := add(ret, 32)
    }
    memcpy(retptr, self._ptr, self._len);
    memcpy(retptr + self._len, other._ptr, other._len);
    return ret;
  }

  /*
   * @dev Joins an array of slices, using `self` as a delimiter, returning a
   *      newly allocated string.
   * @param self The delimiter to use.
   * @param parts A list of slices to join.
   * @return A newly allocated string containing all the slices in `parts`,
   *         joined with `self`.
   */
  function join(slice memory self, slice[] memory parts) internal pure returns (string memory) {
    if (parts.length == 0) return "";

    uint256 length = self._len * (parts.length - 1);
    for (uint256 i = 0; i < parts.length; i++) length += parts[i]._len;

    string memory ret = new string(length);
    uint256 retptr;
    assembly {
      retptr := add(ret, 32)
    }

    for (uint256 i = 0; i < parts.length; i++) {
      memcpy(retptr, parts[i]._ptr, parts[i]._len);
      retptr += parts[i]._len;
      if (i < parts.length - 1) {
        memcpy(retptr, self._ptr, self._len);
        retptr += self._len;
      }
    }

    return ret;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

library Console {
  address public constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

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

  function logInt(int256 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
  }

  function logUint(uint256 p0) internal view {
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

  function log(uint256 p0) internal view {
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

  function log(uint256 p0, uint256 p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
  }

  function log(uint256 p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
  }

  function log(uint256 p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
  }

  function log(uint256 p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
  }

  function log(string memory p0, uint256 p1) internal view {
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

  function log(bool p0, uint256 p1) internal view {
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

  function log(address p0, uint256 p1) internal view {
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

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3)
    );
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

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

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {VerifySignatureUtil as SigUtil} from "./VerifySignatureUtil.sol";
import {VerifyUtil} from "./VerifyUtil.sol";
import {KeyManagement} from "./KeyManagement.sol";
import {GlobalState} from "./GlobalState.sol";
import {CustodyWallet} from "./CustodyWallet.sol";
import {Console} from "./Console.sol";

/**
 * @author prometheumlabs/blockchain-team
 * @title  Container Manager known as <COWSManagement>
 * @dev This contract inherits 2 signature libraries and creates 3 child smart contracts
 * @notice This contract is responsible for returning contract addresses within various containers
 */
contract COWSManagement {
  using SigUtil for SigUtil.VerifiedSignature;

  address public boats;

  enum ActionType {
    TerminateCOWS,
    PauseCOWS,
    UnpauseCOWS
  }

  enum Status {
    Processing,
    Approved,
    Completed,
    ForceClosed
  }

  enum AccountType {
    Empty,
    Omnibus,
    Airdrop,
    CustomerInvestigation,
    Garbage
  }

  /**
   * @notice Stores the address of a COWS smart contract
   * @dev Custom struct used to store map unique int32 value to a keccak-256 hash of an ECDSA-derived address of a COWS smart contract
   * @member contractId 32-bytes integer value uniquely identifying a COWS smart contract
   * @member contractAddr Ethereum address within Prometheum's private EVM cloud RPC node
   */
  struct ContractInfo {
    int32 contractId;
    address contractAddr;
  }

  struct COWSInfo {
    string chain;
    AccountType accountType;
    mapping(string => ContractInfo) contracts;
  }

  struct RecognizeRecord {
    SigUtil.VerifiedSignature adminSignature;
  }

  struct RequestUnit {
    ActionType action;
    bytes32 cowId;
  }

  struct RequestData {
    bytes32 requestId;
    address requester;
    RequestUnit[] units;
    SigUtil.VerifiedSignature[] signatures;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    bool isExecuted;
    Status status;
  }

  struct InitUnit {
    bytes32 cowId;
    string chain;
    AccountType accountType;
    address[] castlKeys;
  }

  /**
   * @notice Unique identifier for each COWS Container for e.g. **CowsCluster1**
   * @dev 32-byte representation of an unique cowsID string using the formatBytes32String ethers function used to return data like chain protocol, the mapping of contract name to <ContractInfo> struct
   */
  mapping(bytes32 => COWSInfo) public COWS;

  /**
   * @notice Unique identifier for a COWS information change request
   * @dev 32-byte representation of a unique requestID using the formatBytes32String ethers function used to return a previously submitted COWS information change request
   */
  mapping(bytes32 => RequestData) public cowsChangeRequests;

  /**
   * @notice Returns record when COWS was first recognized
   * @dev 32-byte representation of a unique identifier using the formatBytes32String ethers function used to identify the initial one-time <recognize> request sent from CASTL
   */
  mapping(bytes32 => RecognizeRecord) public recognizeRecords;

  /**
   * @notice The **DeployNewCOWS** event is emitted when a new COWS smart contract is deployed
   * @dev The **DeployNewCOWS** event is emitted with a helpful message and a boolean value to denote whether the COWS deployment was successful or not
   */
  event DeployNewCOWS(string msg, bool isSuccess);

  /**
   * @notice The **Recognize** event is emitted at the end of the **recognize()** function
   * @dev The **Recognize** event is emitted with a boolean value that returns **true** if the <recognize> function is successful or **false** if it fails with 1 of 3 explanations: <br/> 1. COWS' recognize function has already been called <br/>  2. An invalid CASTL key is being used by the caller invoking the function <br/> 3. The CASTL signature passed by the caller was not signed by the expected CASTL pubKey
   */
  event Recognize(string msg, bool isSuccess);

  /**
   * @notice The **RequestChanges** event is emitted at the end of the **requestChanges()** function
   * @dev The **RequestChanges** event is emitted with a helpful message and a boolean value to denote whether the **requestChanges()** function was successful or not
   */
  event RequestChanges(string msg, bool isSuccess);

  /**
   * @notice The **ApproveChanges** event is emitted at the end of the **approveChanges()** function
   * @dev The **ApproveChanges** event is emitted with a helpful message and a boolean value to denote whether the **approveChanges()** function was successful or not
   */
  event ApproveChanges(string msg, bytes32 failedRequestId, bool isSuccess);

  /**
   * @notice The **ExecuteChanges** event is emitted at the end of the **executeChanges()** function
   * @dev The **ExecuteChanges** event is emitted with a helpful message and a boolean value to denote whether the **executeChanges()** function was successful or not
   */
  event ExecuteChanges(string msg, bytes32 failedCowId, bool isSuccess);

  /**
   * @notice The **ForceClose** event is emitted at the end of the **forceClose()** function
   * @dev The **ForceClose** event is emitted with a helpful message and a boolean value to denote whether the **forceClose()** function was successful or not
   */
  event ForceClose(string msg, bool isSuccess);

  constructor() {
    boats = tx.origin;
  }

  modifier onlyBoats() {
    require(tx.origin == boats, "txn. origin not boats!");
    _;
  }

  function setContractInfo(
    bytes32 _cowID,
    string memory _proto,
    AccountType _accountType,
    string memory _contractName,
    int32 _contractID,
    address _contractAddr
  ) public onlyBoats {
    COWSInfo storage defaultCows = COWS[_cowID];
    defaultCows.chain = _proto;
    defaultCows.accountType = _accountType;
    defaultCows.contracts[_contractName] = ContractInfo({
      contractId: _contractID,
      contractAddr: _contractAddr
    });
  }

  function getContractInfo(bytes32 _cowID, string memory _contractName)
    public
    view
    returns (int32, address)
  {
    return (
      COWS[_cowID].contracts[_contractName].contractId,
      COWS[_cowID].contracts[_contractName].contractAddr
    );
  }

  /**
   * @notice This function is used to get the location of a smart contract for e.g. KeyManagement -> 0x1234567890
   * @dev This function is used to get the contract address of a specific contract within a container context i.e. KeyManagement -> 0x1234567890
   * @param   cowId The container ID in [bytes32] format
   * @param   _contract The contract name as "String" type
   * @return  address  The storage address of the queried contract name based on the container ID
   */
  function returnContractAddress(bytes32 cowId, string memory _contract)
    public
    view
    returns (address)
  {
    ContractInfo memory _info = COWS[cowId].contracts[_contract];
    return _info.contractAddr;
  }

  /**
   * @notice This function is used to deem whether a container is Empty or Omnibus or Airdrop or Customer-Investigation or Garbage
   * @dev This function deems whether container type === Empty || Omnibus || Airdrop || CustomerInvestigation || Garbage
   * @param   cowId  The container ID in [bytes32] format
   * @return  accountType  The custom struct that denotes the type of account i.e. Ombnibus, Airdrop, CustomerInvestigation, Garbage or Empty
   */
  // function getAccountType(bytes32 cowId) public view returns (AccountType accountType) {
  //   return COWS[cowId].accountType;
  // }

  /**
   * @notice This function is returns the signatory who recognized the COWS container
   * @dev This function is a wrapper viewer to return **RecognizeRecord** struct from the **recognizeRecords** mapping
   * @param   cowId  The container ID in [bytes32] format
   * @return  record  The custom **RecognizeRecord** struct containing the **VerifiedSignature** from the **VerifySignatureUtil** library
  //  */
  // function getRecognizeRecord(bytes32 cowId) public view returns (RecognizeRecord memory record) {
  //   return recognizeRecords[cowId];
  // }

  /**
   * @notice This function is to deploy a new set of COWS contracts <br/> **Note:** Anyone can send this deployment request
   * @dev This function loops over an array of <InitUnit> expecting to set atleast 1 CASTL key & deploy 3 child contracts: <GlobalState>, <KeyManagement>, <CustodyWallet> <br/> **Note:** This function does not include signature verification
   * @param   cowsUnits  An array of <InitUnit> each containing the COWS ID, chain, account type, >1 CASTL keys
   * @return  bool Returns true if the deployment is successful, else false
   */
  function deployNewCOWS(InitUnit[] calldata cowsUnits) public returns (bool) {
    for (uint256 i; i < cowsUnits.length; ) {
      // bytes32 _cowId = cowsUnits[i].cowId;

      // Check if number of castl_keys > 1; if not, emit event DeployNewCOWS("Need at least 1 CASTL key when add a new COWS!", false)
      if (cowsUnits[i].castlKeys.length < 1) {
        emit DeployNewCOWS("Need at least 1 CASTL key when add a new COWS!", false);
        revert("Need 1+ CASTLkeys for new COWS!");
      }

      /* Deploy contracts, set init global state as Deployed and update info & activeStatus as Preparing for each COWS */

      // Deploy GlobalState contract
      // address _globalStateAddress;
      // try new GlobalState(GlobalState.COWSState.Deployed, address(this)) returns (
      //   GlobalState _address
      // ) {
      //   _globalStateAddress = address(_address);
      // } catch Error(string memory reason) {
      //   emit DeployNewCOWS("Failed to deploy COWS!", false);
      //   revert(string(abi.encodePacked("GLOBALSTATE: ", reason)));
      // }

      // COWSInfo storage _cowInfo = COWS[_cowId];
      // _cowInfo.chain = cowsUnits[i].chain;
      // _cowInfo.accountType = cowsUnits[i].accountType;

      // {
      //   string memory _globalState = string("GlobalState");
      //   ContractInfo storage _stateContractInfo = _cowInfo.contracts[_globalState];
      //   _stateContractInfo.contractId = 0;
      //   _stateContractInfo.contractAddr = _globalStateAddress; // deployed contract address
      // }

      // Deploy KeyManagement contract
      // address _keyManagementAddress;
      // try
      //   new KeyManagement(cowsUnits[i].castlKeys, _cowId, address(this), _globalStateAddress)
      // returns (KeyManagement _address) {
      //   _keyManagementAddress = address(_address);
      // } catch Error(string memory reason) {
      //   emit DeployNewCOWS("Failed to deploy COWS!", false);
      //   revert(string(abi.encodePacked("KEYMANAGEMENT: ", reason)));
      // }

      // {
      //   string memory _keyContract = string("KeyManagement");
      //   ContractInfo storage _keyContractInfo = _cowInfo.contracts[_keyContract];
      //   _keyContractInfo.contractId = 1;
      //   _keyContractInfo.contractAddr = _keyManagementAddress; // deployed contract address
      // }

      // Deploy CustodyWallet contract
      // address _custodyWalletAddress;

      // try new CustodyWallet(_cowId, address(this), _globalStateAddress) returns (
      //   CustodyWallet _address
      // ) {
      //   _custodyWalletAddress = address(_address);
      // } catch Error(string memory reason) {
      //   emit DeployNewCOWS("Failed to deploy COWS!", false);
      //   revert(string(abi.encodePacked("CUSTODYWALLET: ", reason)));
      // }

      // {
      //   string memory _custodyWallet = string("CustodyWallet");
      //   ContractInfo storage _custodyContractInfo = _cowInfo.contracts[_custodyWallet];
      //   _custodyContractInfo.contractId = 2;
      //   _custodyContractInfo.contractAddr = _custodyWalletAddress; // deployed contract address
      // }

      unchecked {
        ++i;
      }
      //emit SpillContractAddrs(_globalStateAddress, _keyManagementAddress, _custodyWalletAddress);
    }
    emit DeployNewCOWS("All deployed, preparing!", true);
    return true;
  }

  /**
   * @notice  This function is used by CASTL to recognize a deployed COWS contract suite and shows intent to initialize it
   * @dev     This function extracts nested attributes from the message parameter within adminSignature and conducts 2 checks <br/> 1. Check if the **cowId** already exists in **recognizeRecords** <br/> 2. Check if caller has a valid CASTL key <br/> **Note:** If CASTL key is deemed invalid the function reverts and the **Recognize** event is emitted as false, with the reason <br/> Next, the **verifySignature()** checks the validity of the caller's signature. <br/> **Note:** If signature is deemed invalid the function reverts and the **Recognize** event is emitted as false, with the reason <br/> If all checks are successful, <br/> 1. the **recognizeRecords** mapping is updated with the **RecognizeRecord** containing the adminSignature [VerifiedSignature] <br/> 2. Global state is set to Recognized
   * @param   adminSignature  The **BaseSignature** struct from the **VerifySignatureUtil** library including its **message** [string] and **signature** [bytes] parameters
   */
  function recognize(SigUtil.BaseSignature calldata adminSignature) public {
    // Extract params from message in adminSignature
    bytes32 cowsId;
    address signerAddr;
    {
      string[] memory _extractedMessage = SigUtil.extractMessage(adminSignature.message);
      SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(_extractedMessage);
      cowsId = message.cowId;
      signerAddr = message.signerPublicAddress;
    }

    // Check if the cowId is already existed in recognizeRecords
    if (recognizeRecords[cowsId].adminSignature.recoveredSigner != address(0)) {
      emit Recognize("COW is already recognized!", false);
      revert("cow id existed");
    }

    KeyManagement keyManagement;
    {
      address _keyAddr = returnContractAddress(cowsId, string("KeyManagement"));
      keyManagement = KeyManagement(_keyAddr);
    }

    // Check if caller has valid CASTL key;
    //   if not, emit event Recognize("Invalid CASTL key from caller!", false)
    KeyManagement.CASTLState castlState = keyManagement.castlKeys(signerAddr);
    if (castlState != KeyManagement.CASTLState.Enabled) {
      emit Recognize("Invalid CASTL key from caller!", false);
      revert("castl key not enabled");
    }

    // Call verifySignature() to check if the recovered signer of caller signature match;
    //   if not, emit event Recognize("Invalid CASTL signature from caller!", false)
    (bool isVerified, ) = VerifyUtil.verifySingleSignature(signerAddr, adminSignature);
    if (!isVerified) {
      emit Recognize("Invalid CASTL signature from caller!", false);
      revert("invalid castl signature");
    }

    // Update adminSignature to recognizeRecords
    RecognizeRecord storage _recognizeRecords = recognizeRecords[cowsId];

    _recognizeRecords.adminSignature = SigUtil.VerifiedSignature({
      signature: adminSignature,
      recoveredSigner: signerAddr,
      isVerified: true
    });

    // Update global state to Recognized
    {
      address _keyAddr = returnContractAddress(cowsId, string("GlobalState"));
      GlobalState globalState = GlobalState(_keyAddr);
      globalState.setGlobalState(GlobalState.COWSState.Recognized);
    }

    // Emit event Recognize("All passed!", true)
    emit Recognize("All passed!", true);
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Strings} from "./Strings.sol";
import {Console} from "./Console.sol";
import {StringUtils} from "./StringUtils.sol";
import {IERC20} from "./ERC20.sol";
import {VerifySignatureUtil as SigUtil} from "./VerifySignatureUtil.sol";
import {VerifyUtil} from "./VerifyUtil.sol";
import {GlobalState} from "./GlobalState.sol";
import {COWSManagement} from "./COWSManagement.sol";
import {KeyManagement} from "./KeyManagement.sol";

/**
 * Invalid withdrawAmount to transfer. Required `dasBalance` higher than requested `withdrawAmount`
 * @param withdrawAmount withdraw amount.
 * @param dasBalance minimum amount to send.
 */
error InvalidAmount(uint256 withdrawAmount, uint256 dasBalance);

contract CustodyWallet {
  using StringUtils for *;

  //*********************//
  //****** STRUCTS ******//
  //*********************//

  struct DASCheckRequest {
    bytes32 das; // DAS id (or name)
    uint256 currentBalance; // total DAS amount we custody at the time we checked
    SigUtil.VerifiedSignature[] verifiedApprovalSignatures; // signatures verified to be from correct approval keys
    SigUtil.VerifiedSignature castlSignature; // signed castl signature as finalizer
    bool multisigVerified; // default is false, when all signed signatures is verified, mark it as true
  }

  struct DASInfo {
    bytes32 dasTicker;
    address contractAddress;
    uint256 balance;
  }

  //***********************//
  //****** VARIABLES ******//
  //***********************//

  address public constant BOATS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
  COWSManagement public cowsManagement;
  KeyManagement public keyManagement;
  GlobalState public globalState;

  mapping(bytes32 => DASInfo) public dasBalance; // Store mapping of DAS id to DASInfo includes das ticker, total amount (balance) we custody
  mapping(bytes32 => DASCheckRequest) public dasCheckRequests; // Store mapping of DAS approval check request id to history check record

  bytes32 public cowId; // Set by COWS management contract

  //********************//
  //****** EVENTS ******//
  //********************//

  event DASApprovalCheck(string msg, int256 balance, bool isSuccess); // if any fail happened that we couldn't get correct balance, set it as -1
  event WithdrawalRequest(string actionType, string msg, bool isSuccess);

  modifier onlyActiveNormal() {
    GlobalState.COWSState _cowsState = globalState.globalState();
    require(_cowsState == GlobalState.COWSState.ActiveNormal, "Global State not active normal");
    _;
  }

  constructor(
    bytes32 _cowId,
    address _managementAddress,
    address _stateAddress
  ) {
    cowId = _cowId;
    cowsManagement = COWSManagement(_managementAddress);
    globalState = GlobalState(_stateAddress);

    address keyManagementAddr = cowsManagement.returnContractAddress(cowId, "KeyManagement");
    keyManagement = KeyManagement(keyManagementAddr);

    /* Testing only */
    dasCheckRequests[SigUtil.stringToBytes32("testReqId")].das = SigUtil.stringToBytes32("DAS3");
    dasCheckRequests[SigUtil.stringToBytes32("testReqId")].currentBalance = 10;
    dasCheckRequests[SigUtil.stringToBytes32("testReqId")].multisigVerified = true;
  }

  //********************//
  //****** GETTERS ******//
  //********************//

  function getDASInfo(bytes32 dasId) public view returns (DASInfo memory info) {
    return dasBalance[dasId];
  }

  function getDasCheckRequest(bytes32 requestId)
    public
    view
    returns (DASCheckRequest memory checkReq)
  {
    return dasCheckRequests[requestId];
  }

  function dasApprovalCheck(
    SigUtil.BaseSignature[5] calldata signedApprovals,
    SigUtil.BaseSignature calldata castleSignature
  ) public onlyActiveNormal returns (bool) {
    // Check global state (should be under ActiveNormal) <--- Move to onlyActiveNormal modifier

    bytes32 castlRequestID;
    bytes32 castlMsgdasID;
    uint256 totalSigNum;

    {
      // Extract params from message in caller_signature
      string[] memory extractedMsg = SigUtil.extractMessage(castleSignature.message);
      SigUtil.ExtractedSigningMessage memory castlMsg = SigUtil.convertToStruct(extractedMsg);

      // Check if number of signedApprovals (non-empty) matches totalSigNum from signed message
      uint256 numApprovals = VerifyUtil.getSignedMsgCount(signedApprovals);
      totalSigNum = castlMsg.totalSigNum;
      require(numApprovals == totalSigNum, "signedMsgs vs totalSigs mismatch");

      // Check if signed approval signatures included in castleSignature message matches signatures from signedApprovals
      require(
        VerifyUtil.checkSigsMatch(signedApprovals, castlMsg.approvalSignatures, totalSigNum),
        "signedApproval/callerSig discord"
      );

      // Call verifySignature() to check if the recovered signer of caller signature match; if not, emit event DASApprovalCheck("Invalid CASTL key from caller!", -1, false)
      address recoverCaller = SigUtil.verifySignature(
        castleSignature.signature,
        castleSignature.message
      );

      require(
        keyManagement.castlKeys(recoverCaller) == KeyManagement.CASTLState.Enabled,
        "Invalid CASTL key from caller!"
      );

      // Check if request id is existed
      bytes32 emptyStr = "";
      bytes32 _castlRequestID = castlMsg.requestId;
      if (dasCheckRequests[_castlRequestID].das != emptyStr) {
        // If yes, check if is_passed is true or not,
        // Return false if approvals are done and emit event DASApprovalCheck("This dasBalanceCheck is done", -1, false)
        require(
          dasCheckRequests[_castlRequestID].multisigVerified == false,
          "This dasBalanceCheck is done"
        );
      }

      // If request id is existed but multisigVerified != true, overwrite by new castleSignature
      // Create a new DASCheckRequest in dasCheckRequests with the request id
      castlRequestID = _castlRequestID;
      DASCheckRequest storage _newDASCheckRequest = dasCheckRequests[castlRequestID]; // new DASCheckRequest storage record with requestId

      SigUtil.VerifiedSignature storage checkRequestCASTLSig = _newDASCheckRequest.castlSignature; // init empty new castleSignature record from initialized DASCheckRequest storage record above

      // Update castleSignature to dasCheckRequests
      castlMsgdasID = castlMsg.dasId;
      _newDASCheckRequest.das = castlMsgdasID;

      checkRequestCASTLSig.signature = castleSignature;
      checkRequestCASTLSig.recoveredSigner = recoverCaller;
      checkRequestCASTLSig.isVerified = true;
    }

    DASCheckRequest storage newDASCheckRequest = dasCheckRequests[castlRequestID]; // Get DASCheckRequest storage record with requestId and assign to newDASCheckRequest

    // Loop iterates over array of signedApprovals [approval-block]
    bytes32[5] memory tempRecoverSigners;
    uint8 validCounter = 0;
    for (uint256 i = 0; i < totalSigNum; ) {
      string memory approvalMessage = signedApprovals[i].message;
      bytes memory approvalSignature = signedApprovals[i].signature;

      bytes32 _sigApprovalRequestID;
      bytes32 _sigApprovaldasID;
      bytes32 _sigApprovalUserID;
      address approvalSignedBy; // unique variable name for clarity
      // Extract params from message in one of signedApprovals
      {
        string[] memory extractedMsg = SigUtil.extractMessage(approvalMessage);
        SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(extractedMsg);

        _sigApprovalRequestID = message.requestId;
        _sigApprovaldasID = message.dasId;
        _sigApprovalUserID = message.userId[0];

        // Call verifySignature() to check if the recovered signer has valid approval key
        address recoverSigner = SigUtil.verifySignature(approvalSignature, approvalMessage);
        approvalSignedBy = recoverSigner;

        // Check if signed message from signedApprovals matches the one from castleSignature
        require(
          _sigApprovalRequestID == castlRequestID,
          "RequestID mismatch for Signer".toSlice().concat(Strings.toString(i + 1).toSlice())
        );

        require(
          _sigApprovaldasID == castlMsgdasID,
          "DAS ID mismatch for Signer".toSlice().concat(Strings.toString(i + 1).toSlice())
        );

        (, bool isEnabled, , , KeyManagement.ApprovalKeyUnit memory approvalKeyUnit) = keyManagement
          .complianceUserKeys(_sigApprovalUserID);

        {
          // Ensure signer's user is enabled else exit
          uint256 val = i + 1;
          StringUtils.Slice memory num = Strings.toString(val).toSlice();
          StringUtils.Slice memory str = "User is disabled for Signer".toSlice();
          string memory errorMsg = str.concat(num);
          require(isEnabled, errorMsg);
        }

        {
          // loops through user id's approval keys and checks if any of them match the recovered signer address
          uint256 val = i + 1;
          StringUtils.Slice memory num = Strings.toString(val).toSlice();
          StringUtils.Slice memory str = "Sig not of approvalKey of Signer".toSlice();
          string memory errorMsg = str.concat(num);
          require(
            VerifyUtil.isValidApprovalKey(approvalKeyUnit.approvalKeys, approvalSignedBy),
            errorMsg
          );
        }

        tempRecoverSigners[i] = _sigApprovalUserID;
      }

      {
        // If found matched approval key, update is_verified of the signature as true to dasCheckRequests
        newDASCheckRequest.verifiedApprovalSignatures.push(
          SigUtil.VerifiedSignature({
            signature: SigUtil.BaseSignature({
              message: approvalMessage,
              signature: approvalSignature
            }),
            recoveredSigner: approvalSignedBy,
            isVerified: true
          })
        );
      }

      unchecked {
        ++i;
        ++validCounter;
      }
    }

    // Check the signatures from signedApprovals to see if current signature come from different approvers; if not, emit event DASApprovalCheck("The request is already approved by same approver!", -1, false)
    require(
      !VerifyUtil.isDuplicateKey(tempRecoverSigners, totalSigNum),
      "Found duplicate approval key!"
    );

    // Count if the number of verified signatures hits min. threshold (3/5)
    require(validCounter > 2, "Not enough signatures passed");

    // If passed, update signedApprovals and is_passed as true to dasCheckRequests
    newDASCheckRequest.multisigVerified = true;

    // Get balance with extracted DAS id (from message) in dasBalance
    DASInfo memory info = dasBalance[castlMsgdasID];
    uint256 balance = info.balance;
    newDASCheckRequest.currentBalance = balance;

    // Emit event DASApprovalCheck("Approve to check DAS balance!", balance, true)
    emit DASApprovalCheck("Approve to check DAS balance!", int256(balance), true);
    Console.log("balance: ", balance);

    return true;
  }

  function addDAS(
    bytes32 dasId,
    bytes32 dasTicker,
    address contractAddress,
    uint256 initialDeposit
  ) external payable {
    IERC20 erc20 = IERC20(contractAddress);
    erc20.transferFrom(msg.sender, address(this), initialDeposit);

    DASInfo storage _info = dasBalance[dasId];
    _info.dasTicker = dasTicker;
    _info.contractAddress = contractAddress;
    _info.balance = initialDeposit;
  }

  function withdraw(
    SigUtil.BaseSignature[5] calldata approvalSignatures,
    SigUtil.BaseSignature calldata adminSignature
  ) external {
    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      require(
        _cowsState == GlobalState.COWSState.ActiveNormal ||
          _cowsState == GlobalState.COWSState.ActiveEmergency,
        "GlobalState != NORML || EMRGNCY"
      );
    }

    uint256 totalSigNum;
    {
      bool castlVerified = keyManagement.verifyCastlSignature(adminSignature);
      if (!castlVerified) {
        emit WithdrawalRequest("Approve", "Invalid CASTL key from caller!", false);
        revert("invalid castl key");
      }

      string[] memory _adminMessage = SigUtil.extractMessage(adminSignature.message);
      SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(_adminMessage);
      totalSigNum = message.totalSigNum;
    }

    uint256 verifiedApprovers;

    bytes32 dasId;
    uint256 amount;
    address to;
    {
      string[] memory _approver1Message = SigUtil.extractMessage(approvalSignatures[0].message);
      SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(_approver1Message);
      dasId = message.dasId;
      amount = message.amount;
      to = message.to;
      require(message.expiredAt > block.timestamp, "approver 1 request expired");

      (bool approver1Verified, ) = keyManagement.verifyApprovalSignature(
        message.userId[0],
        approvalSignatures[0]
      );
      if (approver1Verified) {
        unchecked {
          ++verifiedApprovers;
        }
      }
    }

    for (uint256 i = 1; i < totalSigNum; ) {
      string[] memory _approver1Message = SigUtil.extractMessage(approvalSignatures[i].message);
      SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(_approver1Message);

      require(message.dasId == dasId, "dasId mismatched");
      require(message.amount == amount, "amount mismatched");
      require(message.to == to, "to address mismatched");
      require(message.expiredAt > block.timestamp, "looped approver request expired");

      (bool loopedApproverVerified, ) = keyManagement.verifyApprovalSignature(
        message.userId[0],
        approvalSignatures[i]
      );
      if (loopedApproverVerified) {
        unchecked {
          ++verifiedApprovers;
        }
      }

      unchecked {
        ++i;
      }
    }

    require(verifiedApprovers > 2, "not enough verified signatures");

    DASInfo storage dasInfo = dasBalance[dasId];
    // require(dasInfo.balance >= amount, "amount higher than das balance");
    if (dasInfo.balance >= amount) {
      revert InvalidAmount({withdrawAmount: amount, dasBalance: dasInfo.balance});
    }

    dasInfo.balance -= amount;
    IERC20 erc20 = IERC20(dasInfo.contractAddress);
    bool successful = erc20.transfer(to, amount);
    require(successful, "withdraw transfer failed!");
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Strings} from "./Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
  enum RecoverError {
    NoError,
    InvalidSignature,
    InvalidSignatureLength,
    InvalidSignatureS,
    InvalidSignatureV // Deprecated in v4.8
  }

  function _throwError(RecoverError error) private pure {
    if (error == RecoverError.NoError) {
      return; // no error: do nothing
    } else if (error == RecoverError.InvalidSignature) {
      revert("ECDSA: invalid sig");
    } else if (error == RecoverError.InvalidSignatureLength) {
      revert("ECDSA: invalid sig length");
    } else if (error == RecoverError.InvalidSignatureS) {
      revert("ECDSA: invalid sig 's' value");
    }
  }

  /**
   * @dev Returns the address that signed a hashed message (`hash`) with
   * `signature` or error string. This address can then be used for verification purposes.
   *
   * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
   * this function rejects them by requiring the `s` value to be in the lower
   * half order, and the `v` value to be either 27 or 28.
   *
   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
   * verification to be secure: it is possible to craft signatures that
   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
   * this is by receiving a hash of the original message (which may otherwise
   * be too long), and then calling {toEthSignedMessageHash} on it.
   *
   * Documentation for signature generation:
   * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
   * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
   *
   * _Available since v4.3._
   */
  function tryRecover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address, RecoverError)
  {
    if (signature.length == 65) {
      bytes32 r;
      bytes32 s;
      uint8 v;
      // ecrecover takes the signature parameters, and the only way to get them
      // currently is to use assembly.
      /// @solidity memory-safe-assembly
      assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
      }
      return tryRecover(hash, v, r, s);
    } else {
      return (address(0), RecoverError.InvalidSignatureLength);
    }
  }

  /**
   * @dev Returns the address that signed a hashed message (`hash`) with
   * `signature`. This address can then be used for verification purposes.
   *
   * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
   * this function rejects them by requiring the `s` value to be in the lower
   * half order, and the `v` value to be either 27 or 28.
   *
   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
   * verification to be secure: it is possible to craft signatures that
   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
   * this is by receiving a hash of the original message (which may otherwise
   * be too long), and then calling {toEthSignedMessageHash} on it.
   */
  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
    (address recovered, RecoverError error) = tryRecover(hash, signature);
    _throwError(error);
    return recovered;
  }

  /**
   * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
   *
   * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
   *
   * _Available since v4.3._
   */
  function tryRecover(
    bytes32 hash,
    bytes32 r,
    bytes32 vs
  ) internal pure returns (address, RecoverError) {
    bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    uint8 v = uint8((uint256(vs) >> 255) + 27);
    return tryRecover(hash, v, r, s);
  }

  /**
   * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
   *
   * _Available since v4.2._
   */
  function recover(
    bytes32 hash,
    bytes32 r,
    bytes32 vs
  ) internal pure returns (address) {
    (address recovered, RecoverError error) = tryRecover(hash, r, vs);
    _throwError(error);
    return recovered;
  }

  /**
   * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
   * `r` and `s` signature fields separately.
   *
   * _Available since v4.3._
   */
  function tryRecover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (address, RecoverError) {
    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      return (address(0), RecoverError.InvalidSignatureS);
    }

    // If the signature is valid (and not malleable), return the signer address
    address signer = ecrecover(hash, v, r, s);
    if (signer == address(0)) {
      return (address(0), RecoverError.InvalidSignature);
    }

    return (signer, RecoverError.NoError);
  }

  /**
   * @dev Overload of {ECDSA-recover} that receives the `v`,
   * `r` and `s` signature fields separately.
   */
  function recover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (address) {
    (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
    _throwError(error);
    return recovered;
  }

  /**
   * @dev Returns an Ethereum Signed Message, created from a `hash`. This
   * produces hash corresponding to the one signed with the
   * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
   * JSON-RPC method as part of EIP-191.
   *
   * See {recover}.
   */
  function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  /**
   * @dev Returns an Ethereum Signed Message, created from `s`. This
   * produces hash corresponding to the one signed with the
   * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
   * JSON-RPC method as part of EIP-191.
   *
   * See {recover}.
   */
  function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
    return
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
  }

  /**
   * @dev Returns an Ethereum Signed Typed Data, created from a
   * `domainSeparator` and a `structHash`. This produces hash corresponding
   * to the one signed with the
   * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
   * JSON-RPC method as part of EIP-712.
   *
   * See {recover}.
   */
  function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;

  /**
   * @dev Sets the values for {name} and {symbol}.
   *
   * The default value of {decimals} is 18. To select a different value for
   * {decimals} you should overload it.
   *
   * All two of these values are immutable: they can only be set once during
   * construction.
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5.05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless this function is
   * overridden;
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  /**
   * @dev See {IERC20-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {IERC20-balanceOf}.
   */
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {IERC20-transfer}.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address to, uint256 amount) public virtual override returns (bool) {
    address owner = _msgSender();
    _transfer(owner, to, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {IERC20-approve}.
   *
   * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
   * `transferFrom`. This is semantically equivalent to an infinite approval.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, amount);
    return true;
  }

  /**
   * @dev See {IERC20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {ERC20}.
   *
   * NOTE: Does not update the allowance if the current allowance
   * is the maximum `uint256`.
   *
   * Requirements:
   *
   * - `from` and `to` cannot be the zero address.
   * - `from` must have a balance of at least `amount`.
   * - the caller must have allowance for ``from``'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    _transfer(from, to, amount);
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    address owner = _msgSender();
    _approve(owner, spender, allowance(owner, spender) + addedValue);
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {IERC20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    address owner = _msgSender();
    uint256 currentAllowance = allowance(owner, spender);
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
      _approve(owner, spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  /**
   * @dev Moves `amount` of tokens from `from` to `to`.
   *
   * This internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `from` must have a balance of at least `amount`.
   */
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    _beforeTokenTransfer(from, to, amount);

    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _balances[from] = fromBalance - amount;
      // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
      // decrementing then incrementing.
      _balances[to] += amount;
    }

    emit Transfer(from, to, amount);

    _afterTokenTransfer(from, to, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply += amount;
    unchecked {
      // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
      _balances[account] += amount;
    }
    emit Transfer(address(0), account, amount);

    _afterTokenTransfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: burn from the zero address");

    _beforeTokenTransfer(account, address(0), amount);

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
      _balances[account] = accountBalance - amount;
      // Overflow not possible: amount <= accountBalance <= totalSupply.
      _totalSupply -= amount;
    }

    emit Transfer(account, address(0), amount);

    _afterTokenTransfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
   *
   * This internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
   *
   * Does not update the allowance amount in case of infinite allowance.
   * Revert if not enough allowance is available.
   *
   * Might emit an {Approval} event.
   */
  function _spendAllowance(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= amount, "ERC20: insufficient allowance");
      unchecked {
        _approve(owner, spender, currentAllowance - amount);
      }
    }
  }

  /**
   * @dev Hook that is called before any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * will be transferred to `to`.
   * - when `from` is zero, `amount` tokens will be minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called after any transfer of tokens. This includes
   * minting and burning.
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
   * has been transferred to `to`.
   * - when `from` is zero, `amount` tokens have been minted for `to`.
   * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
   * - `from` and `to` are never both zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Console} from "../Console.sol";
import {StringUtils} from "../StringUtils.sol";
import {VerifySignatureUtil as SigUtil} from "../VerifySignatureUtil.sol";
import {GlobalState} from "../GlobalState.sol";
import {COWSManagement} from "../COWSManagement.sol";
import {Strings} from "../Strings.sol";

contract OptimizedKeyManagement {
  using StringUtils for *;
  using SigUtil for SigUtil.VerifiedSignature;

  //*******************//
  //****** ENUMS ******//
  //*******************//

  enum KeyType {
    Approval,
    CASTL,
    Emergency,
    Intervention
  }

  enum CASTLState {
    Nonexistant,
    Enabled,
    Expired
  }

  enum UserBlocks {
    None,
    Approval,
    All
  }

  enum RequestStatus {
    Nonexistant,
    Pending,
    Processing,
    Approved,
    Completed,
    ForceClosed
  }

  enum EmergencyRequestStatus {
    Nonexistant,
    Started,
    Executed,
    Rejected
  }

  //*********************//
  //****** STRUCTS ******//
  //*********************//

  struct Key {
    KeyType keyType;
    int32 derivationIndex;
    address keyAddress;
  }

  struct ApprovalKeyUnit {
    bytes32 uniqueDeviceId;
    Key[] approvalKeys;
  }

  struct EmergencyKeyUnit {
    uint256 delayTo;
    Key emergencyKey;
  }

  struct UserKeys {
    bool doesExist;
    bool isEnabled;
    UserBlocks userBlocks;
    EmergencyKeyUnit emergencyKeyUnit;
    ApprovalKeyUnit approvalKeyUnit;
  }

  struct AddApprovalRequest {
    bytes32 userId;
    Key addedApprovalKey;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct EmergencyReplacement {
    address gasWallet;
    bytes32 userId;
    UserKeys oldKeys;
    UserKeys newKeys;
    SigUtil.VerifiedSignature signedEmergencySignature;
    SigUtil.VerifiedSignature signedRejectionSignature;
    uint256 delayTo;
    bool isRejected;
    EmergencyRequestStatus status;
  }

  struct InitRecord {
    bytes32[5] addedUserIds;
    UserKeys[5] addedUserKeys;
    address[] interventionKeys;
    SigUtil.VerifiedSignature callerSignature;
  }

  //***********************//
  //****** VARIABLES ******//
  //***********************//

  COWSManagement public cowsManagement;
  GlobalState public globalState;

  mapping(bytes32 => UserKeys) public complianceUserKeys;

  mapping(address => bool) public interventionKeys;
  mapping(address => CASTLState) public castlKeys;

  mapping(bytes32 => AddApprovalRequest) public approvalKeyRequests;
  mapping(bytes32 => EmergencyReplacement) public emergencyKeyReplacements;

  bytes32 public currentDisabledUser;
  bytes32 public currentReplacingUserRequestId;
  bytes32 public cowId;
  InitRecord public initiator;
  bool public alreadyInitialized;

  //********************//
  //****** EVENTS ******//
  //********************//

  event Init(string msg, bool isSuccess);
  event AddApprovalKeyRequest(string actionType, string msg, bool isSuccess);
  event AddCASTLKeyRequest(string actionType, string msg, bool isSuccess);
  event ChangeInterventionKeyRequest(string actionType, string msg, bool isSuccess);
  event ReplaceKeyRequest(string actionType, string msg, bool isSuccess);
  event ReplaceCASTLKeyRequest(string actionType, string msg, bool isSuccess);
  event ChangeUserKeysStatusRequest(string actionType, string msg, bool isSuccess);
  event ReplaceUserRequest(string actionType, string msg, bool isSuccess);
  event EmergencyReplaceUserKeysRequest(string actionType, string msg, bool isSuccess);
  event ForceClose(string msg, bool isSuccess);

  //*************************//
  //****** CONSTRUCTOR ******//
  //*************************//

  constructor(
    address[] memory _castlKeys,
    bytes32 _cowId,
    address _managementAddress,
    address _stateAddress
  ) {
    uint256 _castlKeysCount = _castlKeys.length;
    require(_castlKeysCount > 0, "_castlKeys is empty");

    for (uint256 i; i < _castlKeysCount; ) {
      castlKeys[_castlKeys[i]] = CASTLState.Enabled;
      unchecked {
        ++i;
      }
    }
    cowId = _cowId;
    cowsManagement = COWSManagement(_managementAddress);
    globalState = GlobalState(_stateAddress);
  }

  //*********************//
  //****** HELPERS ******//
  //*********************//

  function verifyCastlSignature(
    SigUtil.BaseSignature calldata castlSignature
  ) external view returns (bool) {
    address _recoveredSigner = SigUtil.verifySignature(
      castlSignature.signature,
      castlSignature.message
    );

    if (castlKeys[_recoveredSigner] != CASTLState.Enabled) {
      return false;
    }
    return true;
  }

  function verifyApprovalSignature(
    bytes32 userId,
    SigUtil.BaseSignature calldata baseSignature
  ) external view returns (bool, address) {
    Key[] memory _approvalKeys = complianceUserKeys[userId].approvalKeyUnit.approvalKeys;

    address _recoveredApprover = SigUtil.verifySignature(
      baseSignature.signature,
      baseSignature.message
    );
    bool isVerified;
    uint256 _approvalKeyCount = _approvalKeys.length;
    for (uint256 k; k < _approvalKeyCount; ) {
      if (_approvalKeys[k].keyAddress == _recoveredApprover) {
        isVerified = true;
        break;
      }
      unchecked {
        ++k;
      }
    }
    return (isVerified, _recoveredApprover);
  }

  /* function verifySingleSignature(
    address expectedKeyAddress,
    SigUtil.BaseSignature calldata baseSignature
  ) public view returns (bool, address) {
    address _recoveredApprover = SigUtil.verifySignature(
      baseSignature.signature,
      baseSignature.message
    );

    Console.log("expectedKeyAddress: ", expectedKeyAddress);
    Console.log("_recoveredApprover: ", _recoveredApprover);

    bool isVerified;

    if (expectedKeyAddress == _recoveredApprover) {
      isVerified = true;
    }

    return (isVerified, _recoveredApprover);
  } */

  /// @dev may end up refactoring in a different way later
  function setUserBlock(bytes32 requestId, UserBlocks userBlock) external {
    require(msg.sender == address(globalState), "msg sender not global state");
    bytes32 userId = emergencyKeyReplacements[requestId].userId;
    complianceUserKeys[userId].userBlocks = userBlock;
  }

  //*********************//
  //****** GETTERS ******//
  //*********************//

  function getUserKeys(bytes32 userId) external view returns (UserKeys memory keys) {
    return complianceUserKeys[userId];
  }

  function isValidInterventionKey(address interventionKey) external view returns (bool) {
    return interventionKeys[interventionKey];
  }

  function getCASTLState(address castlKey) external view returns (CASTLState state) {
    return castlKeys[castlKey];
  }

  function getAddApprovalRequest(
    bytes32 requestId
  ) external view returns (AddApprovalRequest memory request) {
    return approvalKeyRequests[requestId];
  }

  function getEmergencyKeyReplacements(
    bytes32 requestId
  ) external view returns (EmergencyReplacement memory request) {
    return emergencyKeyReplacements[requestId];
  }

  function getCowId() external view returns (bytes32) {
    return cowId;
  }

  function getInitiator() external view returns (InitRecord memory record) {
    return initiator;
  }

  //******************//
  //****** INIT ******//
  //******************//

  function init(SigUtil.BaseSignature calldata adminSignature) external {
    require(!alreadyInitialized, "already initialized");
    alreadyInitialized = true;
    string memory adminSignedMsg = adminSignature.message;
    address _recoveredSigner = SigUtil.verifySignature(adminSignature.signature, adminSignedMsg);

    if (castlKeys[_recoveredSigner] != CASTLState.Enabled) {
      emit Init("Invalid CASTL signature from caller!", false);
      revert("invalid CASTL signature");
    }

    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      require(_cowsState == GlobalState.COWSState.Recognized, "Global State not recognized");
    }

    {
      bool isEmergency2 = globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2);
      require(!isEmergency2, "GlobalState at emergencyReplace2");
    }

    string[] memory extractedMessage = SigUtil.extractMessage(adminSignedMsg);
    SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(extractedMessage);

    uint256 interventionKeyCount = message.totalInventionKeyNum;
    require(
      interventionKeyCount > 0 && interventionKeyCount < 6,
      "invalid num of intervention keys"
    );
    for (uint256 i; i < interventionKeyCount; ) {
      address interventionKey = message.interventionKeys[i];
      if (interventionKey == address(0)) {
        emit Init("Invalid interventionKey address!", false);
        revert("interventionKey is zero address");
      }
      interventionKeys[interventionKey] = true;
      unchecked {
        ++i;
      }
    }

    InitRecord storage _init = initiator;

    {
      bytes32[5] memory _userIds;
      _userIds[0] = message.userId[0];
      _userIds[1] = message.userId[2];
      _userIds[2] = message.userId[4];
      _userIds[3] = message.userId[6];
      _userIds[4] = message.userId[8];
      _init.addedUserIds = _userIds;
    }

    _init.interventionKeys = message.interventionKeys;

    {
      SigUtil.VerifiedSignature storage _verifiedSig = _init.callerSignature;
      _verifiedSig.signature = adminSignature;
      _verifiedSig.recoveredSigner = _recoveredSigner;
      _verifiedSig.isVerified = true;
    }

    for (uint256 i; i < 5; ) {
      uint256 approvalIndex = i * 2;
      uint256 emergencyIndex = approvalIndex + 1;

      bytes32 userId = message.userId[approvalIndex];

      EmergencyKeyUnit memory defaultEmergencyKeyUnit = EmergencyKeyUnit({
        delayTo: 0, // no delay for init EmergencyKeys
        emergencyKey: Key({
          keyType: KeyType.Emergency,
          derivationIndex: message.derivationIndex[emergencyIndex],
          keyAddress: message.userKeys[emergencyIndex]
        })
      });

      // Set input keys info to complianceUserKeys
      {
        UserKeys storage _userKeys = complianceUserKeys[userId];
        _userKeys.doesExist = true;
        _userKeys.isEnabled = true;
        _userKeys.emergencyKeyUnit = defaultEmergencyKeyUnit;
        _userKeys.approvalKeyUnit.uniqueDeviceId = message.deviceId[approvalIndex];
        _userKeys.approvalKeyUnit.approvalKeys.push(
          Key({
            keyType: KeyType.Approval,
            derivationIndex: message.derivationIndex[approvalIndex],
            keyAddress: message.userKeys[approvalIndex]
          })
        );
      }

      // Set input keys info to initiator
      {
        UserKeys storage _addedKey = _init.addedUserKeys[i];
        _addedKey.doesExist = true;
        _addedKey.isEnabled = true;
        _addedKey.emergencyKeyUnit = defaultEmergencyKeyUnit;
        _addedKey.approvalKeyUnit.uniqueDeviceId = message.deviceId[approvalIndex];
        _addedKey.approvalKeyUnit.approvalKeys.push(
          Key({
            keyType: KeyType.Approval,
            derivationIndex: message.derivationIndex[approvalIndex],
            keyAddress: message.userKeys[approvalIndex]
          })
        );
      }
      unchecked {
        ++i;
      }
    }

    globalState.setGlobalState(GlobalState.COWSState.ActiveNormal);

    /* Testing only */
    UserKeys storage _disabledUserKeys = complianceUserKeys[keccak256(bytes("testUserId"))];
    _disabledUserKeys.doesExist = true;
    _disabledUserKeys.isEnabled = false;
    _disabledUserKeys.approvalKeyUnit.uniqueDeviceId = keccak256(bytes("testDeviceId"));
    Key[] storage k = _disabledUserKeys.approvalKeyUnit.approvalKeys;
    k.push(
      Key({
        derivationIndex: 0,
        keyAddress: 0x927D0903b604d9f01eEB3be8eC65D93D9Cbf2Ec1,
        keyType: KeyType.Approval
      })
    );
    // _disabledUserKeys.approvalKeyUnit.approvalKeys[0].derivationIndex = 0;
    // _disabledUserKeys.approvalKeyUnit.approvalKeys[0].keyAddress = 0x927D0903b604d9f01eEB3be8eC65D93D9Cbf2Ec1;
    // _disabledUserKeys.approvalKeyUnit.approvalKeys[0].keyType = KeyType.Approval;
  }

  //**********************************//
  //****** APPROVAL KEY REQUEST ******//
  //**********************************//

  function addApprovalKeyRequest(bytes32 requestId, bytes32 userId, Key calldata key) external {
    // 1) Check global state (should be under ActiveNormal)
    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      require(_cowsState == GlobalState.COWSState.ActiveNormal, "Global State not active normal");
    }

    // 2) Check if the number of new users + the number of existed users <= 5 (max. should be 5, use replace user if more than 5)
    //    if not, emit event AddApprovalKeyRequest("Request", "Exceed 5 keys!", false)
    require(key.keyType == KeyType.Approval, "Must be an Approval Key");

    // 3) Check if userId in each key is existed
    //    if not, emit event AddApprovalKeyRequest("Request", "Found unknown user!", false)
    Key[] memory currentUserKeys = complianceUserKeys[userId].approvalKeyUnit.approvalKeys;
    uint256 currentKeyCount = currentUserKeys.length;
    for (uint256 i; i < currentKeyCount; ) {
      require(currentUserKeys[i].keyAddress != key.keyAddress, "Key already in use!");
      unchecked {
        ++i;
      }
    }

    require(complianceUserKeys[userId].userBlocks == UserBlocks.None, "userBlock not None");

    if (!complianceUserKeys[userId].isEnabled) {
      emit AddApprovalKeyRequest("Add", "The request key is not enabled!", false);
      revert("user disabled");
    }

    // 4) Check if request id is existed
    //    if existed, emit event AddApprovalKeyRequest("Request", "The request add key id is already existed!", false)
    if (approvalKeyRequests[requestId].status != RequestStatus.Nonexistant) {
      emit AddApprovalKeyRequest("Request", "duplicate key add request", false);
      revert("already exists");
    }

    // 5) Add new AddApprovalRequest for request_id, added_keys, calculate expire_at_block by latest_block_time & expire_approval_key_request_in, set is_passed as false, set status as Processing
    AddApprovalRequest storage _request = approvalKeyRequests[requestId];
    _request.userId = userId;
    _request.addedApprovalKey = key;
    _request.status = RequestStatus.Pending;

    // 24 * 60 * 60 = 86400 seconds in 24 hours
    // 86400 / 12 (seconds per block) = 7200 blocks in 24 hours
    _request.expireAtBlock = block.timestamp + 1 days;

    // 6) emit event AddApprovalKeyRequest("Request", "The request is added successfully!", true)
    emit AddApprovalKeyRequest("Add", "The request is added successfully!", true);
  }

  function verifyApprovalKeyRequest(
    bytes32 requestId,
    bytes32[5] calldata userIds,
    bytes32[5] calldata deviceIds,
    address[5] calldata approversPublicAddress,
    int256[5] calldata approversNonce,
    bytes[5] calldata approvalSignatures,
    address adminPublicAddress,
    int256 adminNonce,
    bytes calldata adminSignature
  ) external {
    // 1) Check global state (should be under ActiveNormal)
    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      require(_cowsState == GlobalState.COWSState.ActiveNormal, "Global State not active normal");
    }

    // 2) Compose message in caller_signature
    string memory formatted_admin_message = string.concat("COWS//", SigUtil.bytes32ToString(cowId));
    // formatted_admin_message = string.concat(formatted_admin_message, address(this));
    formatted_admin_message = string.concat(
      formatted_admin_message,
      "//0x9a1eD2042c10C04f0D7dB58258152F05fB752cF5//approveApprovalKeyRequests//CASTL//Call//"
    );
    formatted_admin_message = string.concat(
      formatted_admin_message,
      Strings.toHexString(uint160(adminPublicAddress), 20)
    );
    formatted_admin_message = string.concat(formatted_admin_message, "//");
    formatted_admin_message = string.concat(
      formatted_admin_message,
      SigUtil.bytes32ToString(requestId)
    );
    formatted_admin_message = string.concat(formatted_admin_message, "//");
    formatted_admin_message = string.concat(
      formatted_admin_message,
      Strings.toString(approvalSignatures.length)
    );
    formatted_admin_message = string.concat(formatted_admin_message, "//");

    for (uint256 i; i < 5; ) {
      formatted_admin_message = string.concat(
        formatted_admin_message,
        string(approvalSignatures[i])
      );
      formatted_admin_message = string.concat(formatted_admin_message, "//");
    }

    formatted_admin_message = string.concat(
      formatted_admin_message,
      SigUtil.intToString(adminNonce)
    );
    formatted_admin_message = string.concat(formatted_admin_message, "//");

    // 3) Check if current block number < expireAtBlock;
    //    if not, emit event AddApprovalKeyRequest("Approve", "The request is already expired, please resubmit a new one!", false)
    if (block.timestamp > approvalKeyRequests[requestId].expireAtBlock) {
      emit AddApprovalKeyRequest(
        "Verify",
        "The request has expired, please resubmit a new one!",
        false
      );
      revert("already expired");
    }

    // 4) Check if caller has valid CASTL key
    //    if not, emit event AddApprovalKeyRequest("Approve", "Invalid CASTL key from caller!", false)

    // 6) Update caller_signature to approval_key_requests
    AddApprovalRequest storage _request = approvalKeyRequests[requestId];

    // 5) Call verifySignature() to check if the recovered signer of caller signature match
    //    if not, emit event AddApprovalKeyRequest("Approve", "Invalid CASTL signature from caller!", false)
    {
      address _recoveredSigner = SigUtil.verifySignature(adminSignature, formatted_admin_message);

      if (castlKeys[_recoveredSigner] != CASTLState.Enabled) {
        emit AddApprovalKeyRequest("Approve", "approval called from unknown CASTL address!", false);
        revert("castl key not enabled");
      }

      SigUtil.VerifiedSignature storage _verifiedSig = _request.callerSignature;
      _verifiedSig.signature = SigUtil.BaseSignature({
        signature: adminSignature,
        message: formatted_admin_message
      });
      _verifiedSig.recoveredSigner = _recoveredSigner;
      _verifiedSig.isVerified = true;
    }

    // 7) Loop starts:
    //      Extract params from message in one of signed_approvals
    //      Check if is_passed is true or not, return false if approvals are done and emit event AddApprovalKeyRequest("Approve", "The request is already approved!", current_request_id)
    //      Check the existed signatures from approval_key_requests to see if current signature come from different approvers; if not, emit event AddApprovalKeyRequest("Approve", "The request is already approved by same approver!", current_request_id)
    //      Call verifySignature() to check if the recovered signer has valid approval key
    //        If passed, update is_verified of the signature as true to approval_key_requests
    //        If failed, emit event AddApprovalKeyRequest("Approve", "Invalid approval signature!", current_request_id)
    //      Count if the number of verified signatures hits min. threshold (3/5)
    //        If passed, update signed_approvals and is_passed as true and status as Approved to approval_key_requests
    uint256 countOfVerifiedSignatures;
    bytes32 _requestId = requestId;
    for (uint256 i; i < 5; ) {
      bytes32 _userId = userIds[i];
      string memory formatted_approve_message = string.concat(
        "COWS//",
        SigUtil.bytes32ToString(cowId)
      );

      {
        // formatted_approve_message = string.concat(formatted_approve_message, address(this));
        bytes32 _deviceId = deviceIds[i];
        address _approverPublicAddress = approversPublicAddress[i];
        int256 _approverNonce = approversNonce[i];
        formatted_approve_message = string.concat(
          formatted_approve_message,
          "//0x9a1eD2042c10C04f0D7dB58258152F05fB752cF5//approveApprovalKeyRequests//Approval//Approve//"
        );
        formatted_approve_message = string.concat(formatted_approve_message, "//");
        formatted_approve_message = string.concat(
          formatted_admin_message,
          SigUtil.bytes32ToString(_userId)
        );
        formatted_approve_message = string.concat(formatted_approve_message, "//");
        formatted_approve_message = string.concat(
          formatted_admin_message,
          SigUtil.bytes32ToString(_deviceId)
        );
        formatted_approve_message = string.concat(formatted_approve_message, "//");
        formatted_approve_message = string.concat(
          formatted_approve_message,
          Strings.toHexString(uint160(_approverPublicAddress), 20)
        );
        formatted_approve_message = string.concat(formatted_approve_message, "//");
        formatted_approve_message = string.concat(
          formatted_approve_message,
          SigUtil.bytes32ToString(_requestId)
        );
        formatted_approve_message = string.concat(formatted_approve_message, "//");
        formatted_approve_message = string.concat(
          formatted_approve_message,
          SigUtil.intToString(_approverNonce)
        );
        formatted_approve_message = string.concat(formatted_approve_message, "//");
      }

      // if user is blocked in any way, skip user
      if (complianceUserKeys[_userId].userBlocks > UserBlocks.None) continue;

      {
        bytes calldata _approvalSignature = approvalSignatures[i];
        (bool isVerified, address recoveredApprover) = this.verifyApprovalSignature(
          _userId,
          SigUtil.BaseSignature({signature: _approvalSignature, message: formatted_approve_message})
        );

        if (isVerified) {
          SigUtil.VerifiedSignature storage _signedApprovals = _request.signedApprovals[i];
          _signedApprovals.signature = SigUtil.BaseSignature({
            signature: _approvalSignature,
            message: formatted_approve_message
          });
          _signedApprovals.recoveredSigner = recoveredApprover;
          _signedApprovals.isVerified = true;
          unchecked {
            ++countOfVerifiedSignatures;
          }
        }
      }

      unchecked {
        ++i;
      }
    }
    require(countOfVerifiedSignatures > 2, "Not enough signatures passed"); // Check if number of approval keys is 5 (should have 5 users when init)

    if (_request.isPassed) {
      emit AddApprovalKeyRequest("Verify", "The request is already approved!", false);
      revert("already approved");
    }

    _request.isPassed = true;
    _request.status = RequestStatus.Approved;

    // 8) Emit event AddApprovalKeyRequest("Approve", "All passed!", true)
    emit AddApprovalKeyRequest("Approve", "addApprovalKey multisig passed", true);
  }

  function executeApprovalKeyRequest(bytes32 requestId) external {
    // 1) Check global state (should be under ActiveNormal)
    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      require(_cowsState == GlobalState.COWSState.ActiveNormal, "Global State not active normal");
    }

    AddApprovalRequest storage _request = approvalKeyRequests[requestId];

    // 2) Check request id existed
    //    if not, emit event AddApprovalKeyRequest("Execute", "Cannot find the request!", false)

    // 3) Check if current block number < expireAtBlock
    //    if not, emit event AddApprovalKeyRequest("Execute", "The request is already expired, please resubmit a new one!", false)

    if (block.timestamp > _request.expireAtBlock) {
      emit AddApprovalKeyRequest(
        "Execute",
        "The request is already expired, please resubmit a new one!",
        false
      );
      revert("already expired");
    }

    // 4) Check if is_passed is true and status is Approved
    //    if not, emit event AddApprovalKeyRequest("Execute", "The request isn't fully approved yet!", false) and return false
    if (!_request.isPassed && _request.status != RequestStatus.Approved) {
      emit AddApprovalKeyRequest("Execute", "The request isn't fully approved yet!", false);
      revert("not approved");
    }

    // 5) Update new keys in approval_keys
    Key memory _key = _request.addedApprovalKey;
    complianceUserKeys[_request.userId].approvalKeyUnit.approvalKeys.push(_key);

    // 6) Update status as Completed
    _request.status = RequestStatus.Completed;

    // 7) If there's already a key/ keys exists for the device, don't update. It should go through replace key process

    // 8) Emit event AddApprovalKeyRequest("Execute", "Executed add request!", true)
    emit AddApprovalKeyRequest("Execute", "Executed add request!", true);
  }

  //************************************//
  //****** COMBINED ADD APPROVAL  ******//
  //************************************//
  // function addApprovalKey(
  //   bytes32 requestId,
  //   bytes32 userId,
  //   Key calldata key,
  //   bytes32[5] calldata userIds,
  //   bytes32[5] calldata deviceIds,
  //   address[5] calldata approversPublicAddress,
  //   int256[5] calldata approversNonce,
  //   bytes[5] calldata approvalSignatures,
  //   address adminPublicAddress,
  //   int256 adminNonce,
  //   bytes calldata adminSignature
  // ) public {
  //   addApprovalKeyRequest(requestId, userId, key);
  //
  //   verifyApprovalKeyRequest(
  //     requestId,
  //     userIds,
  //     deviceIds,
  //     approversPublicAddress,
  //     approversNonce,
  //     approvalSignatures,
  //     adminPublicAddress,
  //     adminNonce,
  //     adminSignature
  //   );
  //
  //   executeApprovalKeyRequest(requestId);
  // }

  //************************************//
  //****** EMERGENCY USER REPLACE ******//
  //************************************//

  function emergencyReplaceUserKeysStart(
    SigUtil.BaseSignature calldata emergencySignature
  ) external {
    // 1) Extract params from message in signed_emergency_signature
    SigUtil.ExtractedSigningMessage memory message;
    {
      string[] memory _extractedMessage = SigUtil.extractMessage(emergencySignature.message);
      message = SigUtil.convertToStruct(_extractedMessage);
    }

    if (block.timestamp < complianceUserKeys[message.userId[0]].emergencyKeyUnit.delayTo) {
      revert("emergency key in timeout");
    }

    require(
      complianceUserKeys[message.userId[0]].userBlocks != UserBlocks.All,
      "userBlock for all function calls"
    );

    // Check if requestId already existed
    //    if yes, emit event EmergencyReplaceUserKeysRequest("Request", "The request id is already existed!", false) and return false
    if (emergencyKeyReplacements[message.requestId].status != EmergencyRequestStatus.Nonexistant) {
      emit EmergencyReplaceUserKeysRequest("Request", "The request id already exists!", false);
      revert("already exists");
    }

    EmergencyReplacement storage _emergencyReplaceRequest = emergencyKeyReplacements[
      message.requestId
    ];

    // Call verifySignature() to check if the recovered signer has valid emergency key
    {
      address _emergencyKey = complianceUserKeys[message.userId[0]]
        .emergencyKeyUnit
        .emergencyKey
        .keyAddress;
      address _recoveredAddr = SigUtil.verifySignature(
        emergencySignature.signature,
        emergencySignature.message
      );
      require(_recoveredAddr == _emergencyKey, "invalid emergency signature");
    }

    // Check global state, if it's still Active Normal, update to ActiveEmergency
    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      if (_cowsState == GlobalState.COWSState.ActiveNormal) {
        globalState.setGlobalState(GlobalState.COWSState.ActiveEmergency);
        globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
        _emergencyReplaceRequest.delayTo = block.timestamp + 1 days;
      } else if (_cowsState == GlobalState.COWSState.ActiveEmergency) {
        if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
          revert("only 2 requests at a time");
        }
        if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
          globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, true);
          globalState.setFlaggedState(GlobalState.FlaggedState.Paused, true);
          _emergencyReplaceRequest.delayTo = block.timestamp + 2 days;
        }
      } else {
        revert("state not ActiveNormal/Emergency");
      }
    }

    currentReplacingUserRequestId = message.requestId;

    // Set status as Processing
    _emergencyReplaceRequest.status = EmergencyRequestStatus.Started;

    // Extract and remove all keys assigned to the userId from approvalKeys (old keys)
    _emergencyReplaceRequest.oldKeys = complianceUserKeys[message.userId[0]];
    // delete complianceUserKeys[userId];

    // Update caller as gasWallet to the emergencyKeyReplacements
    _emergencyReplaceRequest.gasWallet = msg.sender;

    // Add new EmergencyReplacement to emergencyKeyReplacements with requestId, userId, oldKeys, newKeys, isPassed as false
    _emergencyReplaceRequest.userId = message.userId[0];
    // _emergencyReplaceRequest.newKeys = newKeys;
    {
      bool hasEmergencyKey = false;
      _emergencyReplaceRequest.newKeys.doesExist = true;
      _emergencyReplaceRequest.newKeys.isEnabled = true;
      _emergencyReplaceRequest.newKeys.approvalKeyUnit.uniqueDeviceId = message.deviceId[0];

      for (uint256 i = 0; i < message.totalKeyNum; ) {
        StringUtils.Slice memory keyType = message.userKeyType[i].toSlice();

        if (keyType.equals("Emergency".toSlice()) && !hasEmergencyKey) {
          _emergencyReplaceRequest.newKeys.emergencyKeyUnit = EmergencyKeyUnit({
            delayTo: 0,
            emergencyKey: Key({
              keyType: KeyType.Emergency,
              derivationIndex: message.derivationIndex[i],
              keyAddress: message.userKeys[i]
            })
          });

          hasEmergencyKey = true;
        } else {
          _emergencyReplaceRequest.newKeys.approvalKeyUnit.approvalKeys.push(
            Key({
              keyType: KeyType.Approval,
              derivationIndex: message.derivationIndex[i],
              keyAddress: message.userKeys[i]
            })
          );
        }
        unchecked {
          ++i;
        }
      }
    }

    // Blocks user from all functionality
    complianceUserKeys[message.userId[0]].userBlocks = UserBlocks.All;

    // Emit event EmergencyReplaceUserKeysRequest("Start", "Emergency user key replacement starts!", true)
    emit EmergencyReplaceUserKeysRequest("Start", "Emergency user key replacement starts!", true);
  }

  // This function is for canceling emergency replacement by another emergency key or intervention key
  function emergencyReplaceUserKeysIntervene(
    SigUtil.BaseSignature calldata signedRejectApproval
  ) external returns (bool) {
    bytes32 requestId;
    address rejectorAddress;
    string memory keyType;
    {
      string[] memory _extractedMessage = SigUtil.extractMessage(signedRejectApproval.message);
      SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(_extractedMessage);
      requestId = message.requestId;
      rejectorAddress = message.signerPublicAddress;
      keyType = message.keyType;
    }

    // Check if caller has valid intervention key;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Intervene", "Invalid caller!", false)
    {
      bytes32 inputKeyType = bytes32(abi.encodePacked(keyType));
      bytes32 expectedKeyType = bytes32(abi.encodePacked("Intervention"));
      if (inputKeyType != expectedKeyType) {
        emit EmergencyReplaceUserKeysRequest(
          "Intervene",
          "intervention sig wrong key type!",
          false
        );
        revert("intervention sig wrong key type!");
      }
    }

    EmergencyReplacement storage _emergencyReplaceRequest = emergencyKeyReplacements[requestId];

    // Check if current block number exceeds delayTo block number;
    //   if exceed, emit event EmergencyReplaceUserKeysRequest("Intervene", "The delayed time is over now!", false)
    /* if (block.timestamp > _emergencyReplaceRequest.delayTo) {
      emit EmergencyReplaceUserKeysRequest("Intervene", "The delayed time is over now!", false);
      revert("request is expired");
    } */

    // Call verifySignature() to check if the recovered signer has a valid intervention key;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Intervene", "Invalid signature!", false)
    require(interventionKeys[rejectorAddress], "intervention from unknown addr!");
    address _recoveredAddr = SigUtil.verifySignature(
      signedRejectApproval.signature,
      signedRejectApproval.message
    );
    if (_recoveredAddr != rejectorAddress) {
      emit EmergencyReplaceUserKeysRequest("Intervene", "bad signature in intervention!", false);
      revert("bad signature in intervention!");
    }

    // Check if the recovered signer is an disabled user;
    //   if yes, emit event EmergencyReplaceUserKeysRequest("Intervene", "The signature signer is an disable user!", false)
    /* if (!complianceUserKeys[_emergencyReplaceRequest.userId].isEnabled) {
      emit EmergencyReplaceUserKeysRequest(
        "Intervene",
        "The signature signer is from a disabled user!",
        false
      );
      revert("user disabled");
    } */

    // Update signature and isVerified into signedToRejectApprovals
    _emergencyReplaceRequest.signedRejectionSignature = SigUtil.VerifiedSignature({
      recoveredSigner: rejectorAddress,
      isVerified: true,
      signature: signedRejectApproval
    });

    // Accept number of signed reject approvals >= 1
    //   If passed, set isRejected as true
    //   Set isEmergency in approvalKeys back to false (deprecated)
    //   Set isEmergencyReplace2 back to false and
    //     countOfCompletedEmergencyReplacements = 1 in global state contract
    //   Set status as Rejected
    _emergencyReplaceRequest.isRejected = true;
    _emergencyReplaceRequest.status = EmergencyRequestStatus.Rejected;

    bytes32 userId = _emergencyReplaceRequest.userId;
    if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, false);
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
      globalState.setFlaggedState(GlobalState.FlaggedState.Paused, false);
      complianceUserKeys[userId].emergencyKeyUnit.delayTo = block.timestamp + 24 hours;
      complianceUserKeys[userId].userBlocks = UserBlocks.None;
    } else if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, false);
      globalState.setGlobalState(GlobalState.COWSState.ActiveNormal);
      complianceUserKeys[userId].emergencyKeyUnit.delayTo = block.timestamp + 12 hours;
      complianceUserKeys[userId].userBlocks = UserBlocks.None;
    }

    // Emit event EmergencyReplaceUserKeysRequest("Intervene", "The request is intervened successfully!", true)
    emit EmergencyReplaceUserKeysRequest(
      "Intervene",
      "The request is intervened successfully!",
      true
    );
    return true;
  }

  // This function is for executing approved emergency replacement request
  function emergencyReplaceUserKeysExecute(bytes32 requestId) external {
    EmergencyReplacement memory _emergencyKeyReplacements = emergencyKeyReplacements[requestId];
    bytes32 parsedUserId = _emergencyKeyReplacements.userId;

    // Check if the request is already rejected by approvers;
    //   if yes, emit event EmergencyReplaceUserKeysRequest("Execute", "This request is rejected via intervention process!", false)
    if (_emergencyKeyReplacements.isRejected) {
      emit EmergencyReplaceUserKeysRequest(
        "Execute",
        "This request is rejected via intervention process!",
        false
      );
      revert("already rejected");
    }

    // Check if current block number exceeds delayTo block number;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Execute", "Execution should wait until the delayed time end!", false)
    if (block.timestamp < _emergencyKeyReplacements.delayTo) {
      emit EmergencyReplaceUserKeysRequest(
        "Execute",
        "Execution should wait until the delayed time end!",
        false
      );
      revert("not delayed long enough");
    }

    // If all passed,
    //   Update new key in approvalKeys
    {
      UserKeys storage existingUserKeys = complianceUserKeys[parsedUserId];
      UserKeys memory freshUserKeys = _emergencyKeyReplacements.newKeys;

      existingUserKeys.doesExist = true;
      existingUserKeys.isEnabled = true;
      existingUserKeys.emergencyKeyUnit = freshUserKeys.emergencyKeyUnit;
      existingUserKeys.approvalKeyUnit.uniqueDeviceId = freshUserKeys
        .approvalKeyUnit
        .uniqueDeviceId;

      delete existingUserKeys.approvalKeyUnit.approvalKeys;

      uint256 approvalKeyCount = freshUserKeys.approvalKeyUnit.approvalKeys.length;
      for (uint256 i; i < approvalKeyCount; ) {
        existingUserKeys.approvalKeyUnit.approvalKeys.push(
          freshUserKeys.approvalKeyUnit.approvalKeys[i]
        );
        unchecked {
          ++i;
        }
      }

      complianceUserKeys[parsedUserId].userBlocks = UserBlocks.None;
    }

    //   Set both isEmergencyReplace1 & isEmergencyReplace2 back as false in global state contract

    if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, false);
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
      globalState.setFlaggedState(GlobalState.FlaggedState.Paused, false);
    } else if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, false);
      globalState.setGlobalState(GlobalState.COWSState.ActiveNormal);
    }

    //   Set status as Executed
    emergencyKeyReplacements[requestId].status = EmergencyRequestStatus.Executed;

    //   Emit event EmergencyReplaceUserKeysRequest("Execute", "Execute emergency user keys replacement successfully!", true)
    emit EmergencyReplaceUserKeysRequest(
      "Execute",
      "Execute emergency user keys replacement successfully!",
      true
    );
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {StorageStruct} from "./StorageStruct.sol";
import {VerifySignatureUtil as SigUtil} from "../../VerifySignatureUtil.sol";
import {GlobalState} from "../../GlobalState.sol";

contract Proxy is StorageStruct {
    using SigUtil for SigUtil.VerifiedSignature;
    address delegate;

    constructor(address _implementation) {
        delegate = _implementation;
    }

    function verifyApprovalKeyRequest(
        SigUtil.BaseSignature[5] calldata approvalSignatures,
        SigUtil.BaseSignature calldata adminSignature
    ) public payable {
        // 1) Check global state (should be under ActiveNormal)
        {
        GlobalState.COWSState _cowsState = globalState.globalState();
        require(_cowsState == GlobalState.COWSState.ActiveNormal, "Global State not active normal");
        }

        // 2) Extract params from message in caller_signature
        string[] memory extractedMessage = SigUtil.extractMessage(adminSignature.message);
        SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(extractedMessage);
        bytes32 requestId = message.requestId;

        // 3) Check if current block number < expireAtBlock;
        //    if not, emit event AddApprovalKeyRequest("Approve", "The request is already expired, please resubmit a new one!", false)
        if (block.timestamp > approvalKeyRequests[requestId].expireAtBlock) {
        emit AddApprovalKeyRequest(
            "Verify",
            "The request has expired, please resubmit a new one!",
            false
        );
        revert("already expired");
        }

        (bool success, bytes memory data) = delegate.delegatecall(
            abi.encodeWithSignature("verifyApprovalKeyRequest(bytes32,([(bytes, string)], bytes, string))", requestId, approvalSignatures, adminSignature)
        );
    }

    fallback () external payable {
        address impl = delegate;  
        require(impl != address(0));  
        assembly {  
            let ptr := mload(0x40)  
            calldatacopy(ptr, 0, calldatasize())  
            let result := delegatecall(gas(), impl, ptr, calldatasize(), 0, 0)  
            let size := returndatasize()  
            returndatacopy(ptr, 0, size)  
            
            switch result  
            case 0 { revert(ptr, size) }  
            default { return(ptr, size) }  
        }  
    }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {VerifySignatureUtil as SigUtil} from "../../VerifySignatureUtil.sol";
import {GlobalState} from "../../GlobalState.sol";
import {COWSManagement} from "../../COWSManagement.sol";

contract StorageStruct {
  using SigUtil for SigUtil.VerifiedSignature;

  //*******************//
  //****** ENUMS ******//
  //*******************//

  enum KeyType {
    Approval,
    CASTL,
    Emergency,
    Intervention
  }

  enum CASTLState {
    Nonexistant,
    Enabled,
    Expired
  }

  enum CASTLRequestAction {
    Add,
    Expire
  }

  enum InterventionRequestAction {
    Add,
    Remove
  }

  enum ControlAction {
    Enable,
    Disable
  }

  enum UserBlocks {
    None,
    Approval,
    All
  }

  enum CloseType {
    AddApprovalKeyRequest,
    AddCASTLKeyRequest,
    ChangeInterventionKeyRequest,
    ReplaceKeyRequest,
    ReplaceCASTLKeyRequest,
    ChangeUserKeysStatusRequest,
    ReplaceUserRequest
  }

  enum RequestStatus {
    Nonexistant,
    Pending,
    Processing,
    Approved,
    Completed,
    ForceClosed
  }

  enum EmergencyRequestStatus {
    Nonexistant,
    Started,
    Executed,
    Rejected
  }

  //*********************//
  //****** STRUCTS ******//
  //*********************//

  struct Key {
    KeyType keyType;
    int32 derivationIndex;
    address keyAddress;
  }

  struct ApprovalKeyUnit {
    bytes32 uniqueDeviceId;
    Key[] approvalKeys;
  }

  struct EmergencyKeyUnit {
    uint256 delayTo;
    Key emergencyKey;
  }

  struct UserKeys {
    bool doesExist;
    bool isEnabled;
    UserBlocks userBlocks;
    EmergencyKeyUnit emergencyKeyUnit;
    ApprovalKeyUnit approvalKeyUnit;
  }

  struct SignatureBlock {
    bytes32 userId;
    SigUtil.BaseSignature baseSignature;
  }

  struct AddApprovalRequest {
    bytes32 userId;
    Key addedApprovalKey;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct AddCASTLRequest {
    address addedKey;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct AddInterventionRequest {
    InterventionRequestAction requestType;
    address key;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct ControlUserRequest {
    ControlAction actionType;
    KeyType signerKeyType;
    bytes32 userId;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct ReplacementUnit {
    KeyType keyType;
    address newKey;
    bytes32 deviceId;
    int32 newDerivationIndex;
  }

  struct UserReplacement {
    bytes32 oldUserId;
    bytes32 newUserId;
    ReplacementUnit[] newKeys;
    ReplacementUnit[] oldKeys;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct EmergencyReplacement {
    address gasWallet;
    bytes32 userId;
    UserKeys oldKeys;
    UserKeys newKeys;
    SigUtil.VerifiedSignature signedEmergencySignature;
    SigUtil.VerifiedSignature signedRejectionSignature;
    uint256 delayTo;
    bool isRejected;
    EmergencyRequestStatus status;
  }

  struct InitRecord {
    bytes32[5] addedUserIds;
    UserKeys[5] addedUserKeys;
    address[] interventionKeys;
    SigUtil.VerifiedSignature callerSignature;
  }

  //***********************//
  //****** VARIABLES ******//
  //***********************//

  COWSManagement public cowsManagement;
  GlobalState public globalState;

  mapping(bytes32 => UserKeys) public complianceUserKeys;

  mapping(address => bool) public interventionKeys;
  mapping(address => CASTLState) public castlKeys;

  mapping(bytes32 => AddApprovalRequest) public approvalKeyRequests;
  mapping(bytes32 => AddCASTLRequest) public castlKeyRequests;
  mapping(bytes32 => AddInterventionRequest) public interventionKeyRequests;
  mapping(bytes32 => ControlUserRequest) public controlUserKeysRequests;

  mapping(bytes32 => UserReplacement) public userReplacements;
  mapping(bytes32 => EmergencyReplacement) public emergencyKeyReplacements;

  bytes32 public currentDisabledUser;
  bytes32 public currentReplacingUserRequestId;
  bytes32 public currentChangeInterventionKeyRequestId;
  bytes32 public cowId;
  InitRecord public initiator;
  bool public alreadyInitialized;

  //********************//
  //****** EVENTS ******//
  //********************//

  event Init(string msg, bool isSuccess);
  event AddApprovalKeyRequest(string actionType, string msg, bool isSuccess);
  event AddCASTLKeyRequest(string actionType, string msg, bool isSuccess);
  event ChangeInterventionKeyRequest(string actionType, string msg, bool isSuccess);
  event ReplaceKeyRequest(string actionType, string msg, bool isSuccess);
  event ReplaceCASTLKeyRequest(string actionType, string msg, bool isSuccess);
  event ChangeUserKeysStatusRequest(string actionType, string msg, bool isSuccess);
  event ReplaceUserRequest(string actionType, string msg, bool isSuccess);
  event EmergencyReplaceUserKeysRequest(string actionType, string msg, bool isSuccess);
  event ForceClose(string msg, bool isSuccess);
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Console} from "../../Console.sol";
import {StringUtils} from "../../StringUtils.sol";
import {VerifySignatureUtil as SigUtil} from "../../VerifySignatureUtil.sol";
import {GlobalState} from "../../GlobalState.sol";
import {COWSManagement} from "../../COWSManagement.sol";
import {StorageStruct} from "./StorageStruct.sol";

contract T1KeyManagement is StorageStruct {
  using StringUtils for *;
  using SigUtil for SigUtil.VerifiedSignature;

  //*************************//
  //****** CONSTRUCTOR ******//
  //*************************//

  constructor(
    address[] memory _castlKeys,
    bytes32 _cowId,
    address _managementAddress,
    address _stateAddress
  ) {
    uint256 _castlKeysCount = _castlKeys.length;
    require(_castlKeysCount > 0, "_castlKeys is empty");

    for (uint256 i; i < _castlKeysCount; ) {
      castlKeys[_castlKeys[i]] = CASTLState.Enabled;
      unchecked {
        ++i;
      }
    }
    cowId = _cowId;
    cowsManagement = COWSManagement(_managementAddress);
    globalState = GlobalState(_stateAddress);
  }

  //*********************//
  //****** HELPERS ******//
  //*********************//

  function verifyCastlSignature(SigUtil.BaseSignature calldata castlSignature)
    public
    view
    returns (bool)
  {
    address _recoveredSigner = SigUtil.verifySignature(
      castlSignature.signature,
      castlSignature.message
    );

    if (castlKeys[_recoveredSigner] != CASTLState.Enabled) {
      return false;
    }
    return true;
  }

  function verifyApprovalSignature(bytes32 userId, SigUtil.BaseSignature calldata baseSignature)
    public
    view
    returns (bool, address)
  {
    Key[] memory _approvalKeys = complianceUserKeys[userId].approvalKeyUnit.approvalKeys;

    address _recoveredApprover = SigUtil.verifySignature(
      baseSignature.signature,
      baseSignature.message
    );
    bool isVerified;
    uint256 _approvalKeyCount = _approvalKeys.length;
    for (uint256 k; k < _approvalKeyCount; ) {
      if (_approvalKeys[k].keyAddress == _recoveredApprover) {
        isVerified = true;
        break;
      }
      unchecked {
        ++k;
      }
    }
    return (isVerified, _recoveredApprover);
  }

  function verifySingleSignature(
    address expectedKeyAddress,
    SigUtil.BaseSignature calldata baseSignature
  ) public view returns (bool, address) {
    address _recoveredApprover = SigUtil.verifySignature(
      baseSignature.signature,
      baseSignature.message
    );

    Console.log("expectedKeyAddress: ", expectedKeyAddress);
    Console.log("_recoveredApprover: ", _recoveredApprover);

    bool isVerified;

    if (expectedKeyAddress == _recoveredApprover) {
      isVerified = true;
    }

    return (isVerified, _recoveredApprover);
  }

  /// @dev may end up refactoring in a different way later
  function setUserBlock(bytes32 requestId, UserBlocks userBlock) external {
    require(msg.sender == address(globalState), "msg sender not global state");
    bytes32 userId = emergencyKeyReplacements[requestId].userId;
    complianceUserKeys[userId].userBlocks = userBlock;
  }

  //*********************//
  //****** GETTERS ******//
  //*********************//

  function getUserKeys(bytes32 userId) public view returns (UserKeys memory keys) {
    return complianceUserKeys[userId];
  }

  function isValidInterventionKey(address interventionKey) public view returns (bool) {
    return interventionKeys[interventionKey];
  }

  function getCASTLState(address castlKey) public view returns (CASTLState state) {
    return castlKeys[castlKey];
  }

  function getAddApprovalRequest(bytes32 requestId)
    public
    view
    returns (AddApprovalRequest memory request)
  {
    return approvalKeyRequests[requestId];
  }

  function getEmergencyKeyReplacements(bytes32 requestId)
    public
    view
    returns (EmergencyReplacement memory request)
  {
    return emergencyKeyReplacements[requestId];
  }

  function getCowId() public view returns (bytes32) {
    return cowId;
  }

  function getInitiator() public view returns (InitRecord memory record) {
    return initiator;
  }

  //******************//
  //****** INIT ******//
  //******************//

  function init(SigUtil.BaseSignature calldata adminSignature) public {
    require(!alreadyInitialized, "already initialized");
    alreadyInitialized = true;
    string memory adminSignedMsg = adminSignature.message;
    address _recoveredSigner = SigUtil.verifySignature(adminSignature.signature, adminSignedMsg);

    if (castlKeys[_recoveredSigner] != CASTLState.Enabled) {
      emit Init("Invalid CASTL signature from caller!", false);
      revert("invalid CASTL signature");
    }

    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      require(_cowsState == GlobalState.COWSState.Recognized, "Global State not recognized");
    }

    {
      bool isEmergency2 = globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2);
      require(!isEmergency2, "GlobalState at emergencyReplace2");
    }

    string[] memory extractedMessage = SigUtil.extractMessage(adminSignedMsg);
    SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(extractedMessage);

    uint256 interventionKeyCount = message.totalInventionKeyNum;
    require(
      interventionKeyCount > 0 && interventionKeyCount < 6,
      "invalid num of intervention keys"
    );
    for (uint256 i; i < interventionKeyCount; ) {
      address interventionKey = message.interventionKeys[i];
      if (interventionKey == address(0)) {
        emit Init("Invalid interventionKey address!", false);
        revert("interventionKey is zero address");
      }
      interventionKeys[interventionKey] = true;
      unchecked {
        ++i;
      }
    }

    InitRecord storage _init = initiator;

    {
      bytes32[5] memory _userIds;
      _userIds[0] = message.userId[0];
      _userIds[1] = message.userId[2];
      _userIds[2] = message.userId[4];
      _userIds[3] = message.userId[6];
      _userIds[4] = message.userId[8];
      _init.addedUserIds = _userIds;
    }

    _init.interventionKeys = message.interventionKeys;

    {
      SigUtil.VerifiedSignature storage _verifiedSig = _init.callerSignature;
      _verifiedSig.signature = adminSignature;
      _verifiedSig.recoveredSigner = _recoveredSigner;
      _verifiedSig.isVerified = true;
    }

    for (uint256 i; i < 5; ) {
      uint256 approvalIndex = i * 2;
      uint256 emergencyIndex = approvalIndex + 1;

      bytes32 userId = message.userId[approvalIndex];

      EmergencyKeyUnit memory defaultEmergencyKeyUnit = EmergencyKeyUnit({
        delayTo: 0, // no delay for init EmergencyKeys
        emergencyKey: Key({
          keyType: KeyType.Emergency,
          derivationIndex: message.derivationIndex[emergencyIndex],
          keyAddress: message.userKeys[emergencyIndex]
        })
      });

      // Set input keys info to complianceUserKeys
      {
        UserKeys storage _userKeys = complianceUserKeys[userId];
        _userKeys.doesExist = true;
        _userKeys.isEnabled = true;
        _userKeys.emergencyKeyUnit = defaultEmergencyKeyUnit;
        _userKeys.approvalKeyUnit.uniqueDeviceId = message.deviceId[approvalIndex];
        _userKeys.approvalKeyUnit.approvalKeys.push(
          Key({
            keyType: KeyType.Approval,
            derivationIndex: message.derivationIndex[approvalIndex],
            keyAddress: message.userKeys[approvalIndex]
          })
        );
      }

      // Set input keys info to initiator
      {
        UserKeys storage _addedKey = _init.addedUserKeys[i];
        _addedKey.doesExist = true;
        _addedKey.isEnabled = true;
        _addedKey.emergencyKeyUnit = defaultEmergencyKeyUnit;
        _addedKey.approvalKeyUnit.uniqueDeviceId = message.deviceId[approvalIndex];
        _addedKey.approvalKeyUnit.approvalKeys.push(
          Key({
            keyType: KeyType.Approval,
            derivationIndex: message.derivationIndex[approvalIndex],
            keyAddress: message.userKeys[approvalIndex]
          })
        );
      }
      unchecked {
        ++i;
      }
    }

    globalState.setGlobalState(GlobalState.COWSState.ActiveNormal);

    /* Testing only */
    UserKeys storage _disabledUserKeys = complianceUserKeys[keccak256(bytes("testUserId"))];
    _disabledUserKeys.doesExist = true;
    _disabledUserKeys.isEnabled = false;
    _disabledUserKeys.approvalKeyUnit.uniqueDeviceId = keccak256(bytes("testDeviceId"));
    Key[] storage k = _disabledUserKeys.approvalKeyUnit.approvalKeys;
    k.push(
      Key({
        derivationIndex: 0,
        keyAddress: 0x927D0903b604d9f01eEB3be8eC65D93D9Cbf2Ec1,
        keyType: KeyType.Approval
      })
    );
    // _disabledUserKeys.approvalKeyUnit.approvalKeys[0].derivationIndex = 0;
    // _disabledUserKeys.approvalKeyUnit.approvalKeys[0].keyAddress = 0x927D0903b604d9f01eEB3be8eC65D93D9Cbf2Ec1;
    // _disabledUserKeys.approvalKeyUnit.approvalKeys[0].keyType = KeyType.Approval;
  }

  //**********************************//
  //****** APPROVAL KEY REQUEST ******//
  //**********************************//

  function addApprovalKeyRequest(
    bytes32 requestId,
    bytes32 userId,
    Key calldata key
  ) public {
    // 1) Check global state (should be under ActiveNormal)
    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      require(_cowsState == GlobalState.COWSState.ActiveNormal, "Global State not active normal");
    }

    // 2) Check if the number of new users + the number of existed users <= 5 (max. should be 5, use replace user if more than 5)
    //    if not, emit event AddApprovalKeyRequest("Request", "Exceed 5 keys!", false)
    require(key.keyType == KeyType.Approval, "Must be an Approval Key");

    // 3) Check if userId in each key is existed
    //    if not, emit event AddApprovalKeyRequest("Request", "Found unknown user!", false)
    Key[] memory currentUserKeys = complianceUserKeys[userId].approvalKeyUnit.approvalKeys;
    uint256 currentKeyCount = currentUserKeys.length;
    for (uint256 i; i < currentKeyCount; ) {
      require(currentUserKeys[i].keyAddress != key.keyAddress, "Key already in use!");
      unchecked {
        ++i;
      }
    }

    require(complianceUserKeys[userId].userBlocks == UserBlocks.None, "userBlock not None");

    if (!complianceUserKeys[userId].isEnabled) {
      emit AddApprovalKeyRequest("Add", "The request key is not enabled!", false);
      revert("user disabled");
    }

    // 4) Check if request id is existed
    //    if existed, emit event AddApprovalKeyRequest("Request", "The request add key id is already existed!", false)
    if (approvalKeyRequests[requestId].status != RequestStatus.Nonexistant) {
      emit AddApprovalKeyRequest("Request", "duplicate key add request", false);
      revert("already exists");
    }

    // 5) Add new AddApprovalRequest for request_id, added_keys, calculate expire_at_block by latest_block_time & expire_approval_key_request_in, set is_passed as false, set status as Processing
    AddApprovalRequest storage _request = approvalKeyRequests[requestId];
    _request.userId = userId;
    _request.addedApprovalKey = key;
    _request.status = RequestStatus.Pending;

    // 24 * 60 * 60 = 86400 seconds in 24 hours
    // 86400 / 12 (seconds per block) = 7200 blocks in 24 hours
    _request.expireAtBlock = block.timestamp + 1 days;

    // 6) emit event AddApprovalKeyRequest("Request", "The request is added successfully!", true)
    emit AddApprovalKeyRequest("Add", "The request is added successfully!", true);
  }

  function verifyApprovalKeyRequest(
    bytes32 requestId,
    SigUtil.BaseSignature[5] calldata approvalSignatures,
    SigUtil.BaseSignature calldata adminSignature
  ) public {

    // 4) Check if caller has valid CASTL key
    //    if not, emit event AddApprovalKeyRequest("Approve", "Invalid CASTL key from caller!", false)

    // 6) Update caller_signature to approval_key_requests
    AddApprovalRequest storage _request = approvalKeyRequests[requestId];

    // 5) Call verifySignature() to check if the recovered signer of caller signature match
    //    if not, emit event AddApprovalKeyRequest("Approve", "Invalid CASTL signature from caller!", false)
    {
      address _recoveredSigner = SigUtil.verifySignature(
        adminSignature.signature,
        adminSignature.message
      );

      if (castlKeys[_recoveredSigner] != CASTLState.Enabled) {
        emit AddApprovalKeyRequest("Approve", "approval called from unknown CASTL address!", false);
        revert("castl key not enabled");
      }

      SigUtil.VerifiedSignature storage _verifiedSig = _request.callerSignature;
      _verifiedSig.signature = adminSignature;
      _verifiedSig.recoveredSigner = _recoveredSigner;
      _verifiedSig.isVerified = true;
    }

    // 7) Loop starts:
    //      Extract params from message in one of signed_approvals
    //      Check if is_passed is true or not, return false if approvals are done and emit event AddApprovalKeyRequest("Approve", "The request is already approved!", current_request_id)
    //      Check the existed signatures from approval_key_requests to see if current signature come from different approvers; if not, emit event AddApprovalKeyRequest("Approve", "The request is already approved by same approver!", current_request_id)
    //      Call verifySignature() to check if the recovered signer has valid approval key
    //        If passed, update is_verified of the signature as true to approval_key_requests
    //        If failed, emit event AddApprovalKeyRequest("Approve", "Invalid approval signature!", current_request_id)
    //      Count if the number of verified signatures hits min. threshold (3/5)
    //        If passed, update signed_approvals and is_passed as true and status as Approved to approval_key_requests
    uint256 countOfVerifiedSignatures;
    for (uint256 i; i < 5; ) {
      string[] memory _extractedMessage = SigUtil.extractMessage(approvalSignatures[i].message);
      SigUtil.ExtractedSigningMessage memory _message = SigUtil.convertToStruct(_extractedMessage);
      bytes32 _userId = _message.userId[0];

      // if user is blocked in any way, skip user
      if (complianceUserKeys[_userId].userBlocks > UserBlocks.None) continue;

      (bool isVerified, address recoveredApprover) = verifyApprovalSignature(
        _userId,
        approvalSignatures[i]
      );

      if (isVerified) {
        SigUtil.VerifiedSignature storage _signedApprovals = _request.signedApprovals[i];
        _signedApprovals.signature = approvalSignatures[i];
        _signedApprovals.recoveredSigner = recoveredApprover;
        _signedApprovals.isVerified = true;
        unchecked {
          ++countOfVerifiedSignatures;
        }
      }
      unchecked {
        ++i;
      }
    }
    require(countOfVerifiedSignatures > 2, "Not enough signatures passed"); // Check if number of approval keys is 5 (should have 5 users when init)

    if (_request.isPassed) {
      emit AddApprovalKeyRequest("Verify", "The request is already approved!", false);
      revert("already approved");
    }

    _request.isPassed = true;
    _request.status = RequestStatus.Approved;

    // 8) Emit event AddApprovalKeyRequest("Approve", "All passed!", true)
    emit AddApprovalKeyRequest("Approve", "addApprovalKey multisig passed", true);
  }

  function executeApprovalKeyRequest(bytes32 requestId) public {
    // 1) Check global state (should be under ActiveNormal)
    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      require(_cowsState == GlobalState.COWSState.ActiveNormal, "Global State not active normal");
    }

    AddApprovalRequest storage _request = approvalKeyRequests[requestId];

    // 2) Check request id existed
    //    if not, emit event AddApprovalKeyRequest("Execute", "Cannot find the request!", false)

    // 3) Check if current block number < expireAtBlock
    //    if not, emit event AddApprovalKeyRequest("Execute", "The request is already expired, please resubmit a new one!", false)

    if (block.timestamp > _request.expireAtBlock) {
      emit AddApprovalKeyRequest(
        "Execute",
        "The request is already expired, please resubmit a new one!",
        false
      );
      revert("already expired");
    }

    // 4) Check if is_passed is true and status is Approved
    //    if not, emit event AddApprovalKeyRequest("Execute", "The request isn't fully approved yet!", false) and return false
    if (!_request.isPassed && _request.status != RequestStatus.Approved) {
      emit AddApprovalKeyRequest("Execute", "The request isn't fully approved yet!", false);
      revert("not approved");
    }

    // 5) Update new keys in approval_keys
    Key memory _key = _request.addedApprovalKey;
    complianceUserKeys[_request.userId].approvalKeyUnit.approvalKeys.push(_key);

    // 6) Update status as Completed
    _request.status = RequestStatus.Completed;

    // 7) If there's already a key/ keys exists for the device, don't update. It should go through replace key process

    // 8) Emit event AddApprovalKeyRequest("Execute", "Executed add request!", true)
    emit AddApprovalKeyRequest("Execute", "Executed add request!", true);
  }

  //************************************//
  //****** COMBINED ADD APPROVAL  ******//
  //************************************//
  function addApprovalKey(
    bytes32 requestId,
    bytes32 userId,
    Key calldata key,
    SigUtil.BaseSignature[5] calldata approvalSignatures,
    SigUtil.BaseSignature calldata adminSignature
  ) public {
    addApprovalKeyRequest(requestId, userId, key);

    verifyApprovalKeyRequest(requestId, approvalSignatures, adminSignature);

    executeApprovalKeyRequest(requestId);
  }

  //************************************//
  //****** EMERGENCY USER REPLACE ******//
  //************************************//

  function emergencyReplaceUserKeysStart(SigUtil.BaseSignature calldata emergencySignature) public {
    // 1) Extract params from message in signed_emergency_signature
    SigUtil.ExtractedSigningMessage memory message;
    {
      string[] memory _extractedMessage = SigUtil.extractMessage(emergencySignature.message);
      message = SigUtil.convertToStruct(_extractedMessage);
    }

    if (block.timestamp < complianceUserKeys[message.userId[0]].emergencyKeyUnit.delayTo) {
      revert("emergency key in timeout");
    }

    require(
      complianceUserKeys[message.userId[0]].userBlocks != UserBlocks.All,
      "userBlock for all function calls"
    );

    // Check if requestId already existed
    //    if yes, emit event EmergencyReplaceUserKeysRequest("Request", "The request id is already existed!", false) and return false
    if (emergencyKeyReplacements[message.requestId].status != EmergencyRequestStatus.Nonexistant) {
      emit EmergencyReplaceUserKeysRequest("Request", "The request id already exists!", false);
      revert("already exists");
    }

    EmergencyReplacement storage _emergencyReplaceRequest = emergencyKeyReplacements[
      message.requestId
    ];

    // Call verifySignature() to check if the recovered signer has valid emergency key
    {
      address _emergencyKey = complianceUserKeys[message.userId[0]]
        .emergencyKeyUnit
        .emergencyKey
        .keyAddress;
      (bool isVerified, ) = verifySingleSignature(_emergencyKey, emergencySignature);
      require(isVerified, "invalid emergency signature");
    }

    // Check global state, if it's still Active Normal, update to ActiveEmergency
    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      if (_cowsState == GlobalState.COWSState.ActiveNormal) {
        globalState.setGlobalState(GlobalState.COWSState.ActiveEmergency);
        globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
        _emergencyReplaceRequest.delayTo = block.timestamp + 1 days;
      } else if (_cowsState == GlobalState.COWSState.ActiveEmergency) {
        if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
          revert("only 2 requests at a time");
        }
        if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
          globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, true);
          globalState.setFlaggedState(GlobalState.FlaggedState.Paused, true);
          _emergencyReplaceRequest.delayTo = block.timestamp + 2 days;
        }
      } else {
        revert("state not ActiveNormal/Emergency");
      }
    }

    currentReplacingUserRequestId = message.requestId;

    // Set status as Processing
    _emergencyReplaceRequest.status = EmergencyRequestStatus.Started;

    // Extract and remove all keys assigned to the userId from approvalKeys (old keys)
    _emergencyReplaceRequest.oldKeys = complianceUserKeys[message.userId[0]];
    // delete complianceUserKeys[userId];

    // Update caller as gasWallet to the emergencyKeyReplacements
    _emergencyReplaceRequest.gasWallet = msg.sender;

    // Add new EmergencyReplacement to emergencyKeyReplacements with requestId, userId, oldKeys, newKeys, isPassed as false
    _emergencyReplaceRequest.userId = message.userId[0];
    // _emergencyReplaceRequest.newKeys = newKeys;
    {
      bool hasEmergencyKey = false;
      _emergencyReplaceRequest.newKeys.doesExist = true;
      _emergencyReplaceRequest.newKeys.isEnabled = true;
      _emergencyReplaceRequest.newKeys.approvalKeyUnit.uniqueDeviceId = message.deviceId[0];

      for (uint256 i = 0; i < message.totalKeyNum; ) {
        StringUtils.Slice memory keyType = message.userKeyType[i].toSlice();

        if (keyType.equals("Emergency".toSlice()) && !hasEmergencyKey) {
          _emergencyReplaceRequest.newKeys.emergencyKeyUnit = EmergencyKeyUnit({
            delayTo: 0,
            emergencyKey: Key({
              keyType: KeyType.Emergency,
              derivationIndex: message.derivationIndex[i],
              keyAddress: message.userKeys[i]
            })
          });

          hasEmergencyKey = true;
        } else {
          _emergencyReplaceRequest.newKeys.approvalKeyUnit.approvalKeys.push(
            Key({
              keyType: KeyType.Approval,
              derivationIndex: message.derivationIndex[i],
              keyAddress: message.userKeys[i]
            })
          );
        }
        unchecked {
          ++i;
        }
      }
    }

    // Blocks user from all functionality
    complianceUserKeys[message.userId[0]].userBlocks = UserBlocks.All;

    // Emit event EmergencyReplaceUserKeysRequest("Start", "Emergency user key replacement starts!", true)
    emit EmergencyReplaceUserKeysRequest("Start", "Emergency user key replacement starts!", true);
  }

  // This function is for canceling emergency replacement by another emergency key or intervention key
  function emergencyReplaceUserKeysIntervene(SigUtil.BaseSignature calldata signedRejectApproval)
    public
    returns (bool)
  {
    bytes32 requestId;
    address rejectorAddress;
    string memory keyType;
    {
      string[] memory _extractedMessage = SigUtil.extractMessage(signedRejectApproval.message);
      SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(_extractedMessage);
      requestId = message.requestId;
      rejectorAddress = message.signerPublicAddress;
      keyType = message.keyType;
    }

    // Check if caller has valid intervention key;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Intervene", "Invalid caller!", false)
    {
      bytes32 inputKeyType = bytes32(abi.encodePacked(keyType));
      bytes32 expectedKeyType = bytes32(abi.encodePacked("Intervention"));
      if (inputKeyType != expectedKeyType) {
        emit EmergencyReplaceUserKeysRequest(
          "Intervene",
          "intervention sig wrong key type!",
          false
        );
        revert("intervention sig wrong key type!");
      }
    }

    EmergencyReplacement storage _emergencyReplaceRequest = emergencyKeyReplacements[requestId];

    // Check if current block number exceeds delayTo block number;
    //   if exceed, emit event EmergencyReplaceUserKeysRequest("Intervene", "The delayed time is over now!", false)
    /* if (block.timestamp > _emergencyReplaceRequest.delayTo) {
      emit EmergencyReplaceUserKeysRequest("Intervene", "The delayed time is over now!", false);
      revert("request is expired");
    } */

    // Call verifySignature() to check if the recovered signer has a valid intervention key;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Intervene", "Invalid signature!", false)
    require(interventionKeys[rejectorAddress], "intervention from unknown addr!");
    (bool isVerified, ) = verifySingleSignature(rejectorAddress, signedRejectApproval);
    if (!isVerified) {
      emit EmergencyReplaceUserKeysRequest("Intervene", "bad signature in intervention!", false);
      revert("bad signature in intervention!");
    }

    // Check if the recovered signer is an disabled user;
    //   if yes, emit event EmergencyReplaceUserKeysRequest("Intervene", "The signature signer is an disable user!", false)
    /* if (!complianceUserKeys[_emergencyReplaceRequest.userId].isEnabled) {
      emit EmergencyReplaceUserKeysRequest(
        "Intervene",
        "The signature signer is from a disabled user!",
        false
      );
      revert("user disabled");
    } */

    // Update signature and isVerified into signedToRejectApprovals
    _emergencyReplaceRequest.signedRejectionSignature = SigUtil.VerifiedSignature({
      recoveredSigner: rejectorAddress,
      isVerified: true,
      signature: signedRejectApproval
    });

    // Accept number of signed reject approvals >= 1
    //   If passed, set isRejected as true
    //   Set isEmergency in approvalKeys back to false (deprecated)
    //   Set isEmergencyReplace2 back to false and
    //     countOfCompletedEmergencyReplacements = 1 in global state contract
    //   Set status as Rejected
    _emergencyReplaceRequest.isRejected = true;
    _emergencyReplaceRequest.status = EmergencyRequestStatus.Rejected;

    bytes32 userId = _emergencyReplaceRequest.userId;
    if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, false);
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
      globalState.setFlaggedState(GlobalState.FlaggedState.Paused, false);
      complianceUserKeys[userId].emergencyKeyUnit.delayTo = block.timestamp + 24 hours;
      complianceUserKeys[userId].userBlocks = UserBlocks.None;
    } else if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, false);
      globalState.setGlobalState(GlobalState.COWSState.ActiveNormal);
      complianceUserKeys[userId].emergencyKeyUnit.delayTo = block.timestamp + 12 hours;
      complianceUserKeys[userId].userBlocks = UserBlocks.None;
    }

    // Emit event EmergencyReplaceUserKeysRequest("Intervene", "The request is intervened successfully!", true)
    emit EmergencyReplaceUserKeysRequest(
      "Intervene",
      "The request is intervened successfully!",
      true
    );
    return true;
  }

  // This function is for executing approved emergency replacement request
  function emergencyReplaceUserKeysExecute(bytes32 requestId) public {
    EmergencyReplacement memory _emergencyKeyReplacements = emergencyKeyReplacements[requestId];
    bytes32 parsedUserId = _emergencyKeyReplacements.userId;

    // Check if the request is already rejected by approvers;
    //   if yes, emit event EmergencyReplaceUserKeysRequest("Execute", "This request is rejected via intervention process!", false)
    if (_emergencyKeyReplacements.isRejected) {
      emit EmergencyReplaceUserKeysRequest(
        "Execute",
        "This request is rejected via intervention process!",
        false
      );
      revert("already rejected");
    }

    // Check if current block number exceeds delayTo block number;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Execute", "Execution should wait until the delayed time end!", false)
    if (block.timestamp < _emergencyKeyReplacements.delayTo) {
      emit EmergencyReplaceUserKeysRequest(
        "Execute",
        "Execution should wait until the delayed time end!",
        false
      );
      revert("not delayed long enough");
    }

    // If all passed,
    //   Update new key in approvalKeys
    {
      UserKeys storage existingUserKeys = complianceUserKeys[parsedUserId];
      UserKeys memory freshUserKeys = _emergencyKeyReplacements.newKeys;

      existingUserKeys.doesExist = true;
      existingUserKeys.isEnabled = true;
      existingUserKeys.emergencyKeyUnit = freshUserKeys.emergencyKeyUnit;
      existingUserKeys.approvalKeyUnit.uniqueDeviceId = freshUserKeys
        .approvalKeyUnit
        .uniqueDeviceId;

      delete existingUserKeys.approvalKeyUnit.approvalKeys;

      uint256 approvalKeyCount = freshUserKeys.approvalKeyUnit.approvalKeys.length;
      for (uint256 i; i < approvalKeyCount; ) {
        existingUserKeys.approvalKeyUnit.approvalKeys.push(
          freshUserKeys.approvalKeyUnit.approvalKeys[i]
        );
        unchecked {
          ++i;
        }
      }

      complianceUserKeys[parsedUserId].userBlocks = UserBlocks.None;
    }

    //   Set both isEmergencyReplace1 & isEmergencyReplace2 back as false in global state contract

    if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, false);
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
      globalState.setFlaggedState(GlobalState.FlaggedState.Paused, false);
    } else if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, false);
      globalState.setGlobalState(GlobalState.COWSState.ActiveNormal);
    }

    //   Set status as Executed
    emergencyKeyReplacements[requestId].status = EmergencyRequestStatus.Executed;

    //   Emit event EmergencyReplaceUserKeysRequest("Execute", "Execute emergency user keys replacement successfully!", true)
    emit EmergencyReplaceUserKeysRequest(
      "Execute",
      "Execute emergency user keys replacement successfully!",
      true
    );
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {VerifySignatureUtil as SigUtil} from "../../VerifySignatureUtil.sol";
import {GlobalState} from "../../GlobalState.sol";
import {COWSManagement} from "../../COWSManagement.sol";

library Lib {
  using SigUtil for SigUtil.VerifiedSignature;

  //*******************//
  //****** ENUMS ******//
  //*******************//

  enum KeyType {
    Approval,
    CASTL,
    Emergency,
    Intervention
  }

  enum CASTLState {
    Nonexistant,
    Enabled,
    Expired
  }

  enum CASTLRequestAction {
    Add,
    Expire
  }

  enum InterventionRequestAction {
    Add,
    Remove
  }

  enum ControlAction {
    Enable,
    Disable
  }

  enum UserBlocks {
    None,
    Approval,
    All
  }

  enum CloseType {
    AddApprovalKeyRequest,
    AddCASTLKeyRequest,
    ChangeInterventionKeyRequest,
    ReplaceKeyRequest,
    ReplaceCASTLKeyRequest,
    ChangeUserKeysStatusRequest,
    ReplaceUserRequest
  }

  enum RequestStatus {
    Nonexistant,
    Pending,
    Processing,
    Approved,
    Completed,
    ForceClosed
  }

  enum EmergencyRequestStatus {
    Nonexistant,
    Started,
    Executed,
    Rejected
  }

  //*********************//
  //****** STRUCTS ******//
  //*********************//

  struct Key {
    KeyType keyType;
    int32 derivationIndex;
    address keyAddress;
  }

  struct ApprovalKeyUnit {
    bytes32 uniqueDeviceId;
    Key[] approvalKeys;
  }

  struct EmergencyKeyUnit {
    uint256 delayTo;
    Key emergencyKey;
  }

  struct UserKeys {
    bool doesExist;
    bool isEnabled;
    UserBlocks userBlocks;
    EmergencyKeyUnit emergencyKeyUnit;
    ApprovalKeyUnit approvalKeyUnit;
  }

  struct SignatureBlock {
    bytes32 userId;
    SigUtil.BaseSignature baseSignature;
  }

  struct AddApprovalRequest {
    bytes32 userId;
    Key addedApprovalKey;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct AddCASTLRequest {
    address addedKey;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct AddInterventionRequest {
    InterventionRequestAction requestType;
    address key;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct ControlUserRequest {
    ControlAction actionType;
    KeyType signerKeyType;
    bytes32 userId;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct ReplacementUnit {
    KeyType keyType;
    address newKey;
    bytes32 deviceId;
    int32 newDerivationIndex;
  }

  struct UserReplacement {
    bytes32 oldUserId;
    bytes32 newUserId;
    ReplacementUnit[] newKeys;
    ReplacementUnit[] oldKeys;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct EmergencyReplacement {
    address gasWallet;
    bytes32 userId;
    UserKeys oldKeys;
    UserKeys newKeys;
    SigUtil.VerifiedSignature signedEmergencySignature;
    SigUtil.VerifiedSignature signedRejectionSignature;
    uint256 delayTo;
    bool isRejected;
    EmergencyRequestStatus status;
  }

  struct InitRecord {
    bytes32[5] addedUserIds;
    UserKeys[5] addedUserKeys;
    address[] interventionKeys;
    SigUtil.VerifiedSignature callerSignature;
  }

  function checkState(GlobalState.COWSState _cowsState) public {
    require(_cowsState == GlobalState.COWSState.ActiveNormal, "Global State not active normal");
  }

  function extractReqId(SigUtil.BaseSignature calldata adminSignature) public returns (bytes32) {
    string[] memory extractedMessage = SigUtil.extractMessage(adminSignature.message);
    SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(extractedMessage);
     return message.requestId;
  }

  function extractUserId(SigUtil.BaseSignature calldata approvalSignature) public returns (bytes32) {
    string[] memory _extractedMessage = SigUtil.extractMessage(approvalSignature.message);
    SigUtil.ExtractedSigningMessage memory _message = SigUtil.convertToStruct(_extractedMessage);

    return _message.userId[0];
  }

  function wrappedVerifyApprovalSignature(SigUtil.BaseSignature calldata baseSignature, Key[] memory approvalKeys) public returns (bool, address) {
    address _recoveredApprover = SigUtil.verifySignature(
      baseSignature.signature,
      baseSignature.message
    );
    bool isVerified;
    uint256 _approvalKeyCount = approvalKeys.length;
    for (uint256 k; k < _approvalKeyCount; ) {
      if (approvalKeys[k].keyAddress == _recoveredApprover) {
        isVerified = true;
        break;
      }
      unchecked {
        ++k;
      }
    }

    return (isVerified, _recoveredApprover);
  }

  function checkApprovals(
    SigUtil.BaseSignature calldata approvalSignature,
    Key[] memory approvalKeys,
    SigUtil.VerifiedSignature storage signedApprovals
  ) public returns (bool) {
      (bool isVerified, address recoveredApprover) = wrappedVerifyApprovalSignature(
        approvalSignature,
        approvalKeys
      );

      if (isVerified) {
        signedApprovals.signature = approvalSignature;
        signedApprovals.recoveredSigner = recoveredApprover;
        signedApprovals.isVerified = true;
      }

      return isVerified;
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Console} from "../../Console.sol";
import {StringUtils} from "../../StringUtils.sol";
import {VerifySignatureUtil as SigUtil} from "../../VerifySignatureUtil.sol";
import {GlobalState} from "../../GlobalState.sol";
import {COWSManagement} from "../../COWSManagement.sol";
import {Lib} from "./Lib.sol";

contract T2KeyManagement {
  using StringUtils for *;
  using SigUtil for SigUtil.VerifiedSignature;
  using Lib for *;

  //***********************//
  //****** VARIABLES ******//
  //***********************//

  COWSManagement public cowsManagement;
  GlobalState public globalState;

  mapping(bytes32 => Lib.UserKeys) public complianceUserKeys;

  mapping(address => bool) public interventionKeys;
  mapping(address => Lib.CASTLState) public castlKeys;

  mapping(bytes32 => Lib.AddApprovalRequest) public approvalKeyRequests;
  mapping(bytes32 => Lib.AddCASTLRequest) public castlKeyRequests;
  mapping(bytes32 => Lib.AddInterventionRequest) public interventionKeyRequests;
  mapping(bytes32 => Lib.ControlUserRequest) public controlUserKeysRequests;

  mapping(bytes32 => Lib.UserReplacement) public userReplacements;
  mapping(bytes32 => Lib.EmergencyReplacement) public emergencyKeyReplacements;

  bytes32 public currentDisabledUser;
  bytes32 public currentReplacingUserRequestId;
  bytes32 public currentChangeInterventionKeyRequestId;
  bytes32 public cowId;
  Lib.InitRecord public initiator;
  bool public alreadyInitialized;

  //********************//
  //****** EVENTS ******//
  //********************//

  event Init(string msg, bool isSuccess);
  event AddApprovalKeyRequest(string actionType, string msg, bool isSuccess);
  event AddCASTLKeyRequest(string actionType, string msg, bool isSuccess);
  event ChangeInterventionKeyRequest(string actionType, string msg, bool isSuccess);
  event ReplaceKeyRequest(string actionType, string msg, bool isSuccess);
  event ReplaceCASTLKeyRequest(string actionType, string msg, bool isSuccess);
  event ChangeUserKeysStatusRequest(string actionType, string msg, bool isSuccess);
  event ReplaceUserRequest(string actionType, string msg, bool isSuccess);
  event EmergencyReplaceUserKeysRequest(string actionType, string msg, bool isSuccess);
  event ForceClose(string msg, bool isSuccess);

  //*************************//
  //****** CONSTRUCTOR ******//
  //*************************//

  constructor(
    address[] memory _castlKeys,
    bytes32 _cowId,
    address _managementAddress,
    address _stateAddress
  ) {
    uint256 _castlKeysCount = _castlKeys.length;
    require(_castlKeysCount > 0, "_castlKeys is empty");

    for (uint256 i; i < _castlKeysCount; ) {
      castlKeys[_castlKeys[i]] = Lib.CASTLState.Enabled;
      unchecked {
        ++i;
      }
    }
    cowId = _cowId;
    cowsManagement = COWSManagement(_managementAddress);
    globalState = GlobalState(_stateAddress);
  }

  //*********************//
  //****** HELPERS ******//
  //*********************//

  function verifyCastlSignature(SigUtil.BaseSignature calldata castlSignature)
    public
    view
    returns (bool)
  {
    address _recoveredSigner = SigUtil.verifySignature(
      castlSignature.signature,
      castlSignature.message
    );

    if (castlKeys[_recoveredSigner] != Lib.CASTLState.Enabled) {
      return false;
    }
    return true;
  }

  function verifyApprovalSignature(bytes32 userId, SigUtil.BaseSignature calldata baseSignature)
    public
    returns (bool, address)
  {
    Lib.Key[] memory _approvalKeys = complianceUserKeys[userId].approvalKeyUnit.approvalKeys;
    return Lib.wrappedVerifyApprovalSignature(baseSignature, _approvalKeys);
  }

  function verifySingleSignature(
    address expectedKeyAddress,
    SigUtil.BaseSignature calldata baseSignature
  ) public view returns (bool, address) {
    address _recoveredApprover = SigUtil.verifySignature(
      baseSignature.signature,
      baseSignature.message
    );

    Console.log("expectedKeyAddress: ", expectedKeyAddress);
    Console.log("_recoveredApprover: ", _recoveredApprover);

    bool isVerified;

    if (expectedKeyAddress == _recoveredApprover) {
      isVerified = true;
    }

    return (isVerified, _recoveredApprover);
  }

  /// @dev may end up refactoring in a different way later
  function setUserBlock(bytes32 requestId, Lib.UserBlocks userBlock) external {
    require(msg.sender == address(globalState), "msg sender not global state");
    bytes32 userId = emergencyKeyReplacements[requestId].userId;
    complianceUserKeys[userId].userBlocks = userBlock;
  }

  //*********************//
  //****** GETTERS ******//
  //*********************//

  function getUserKeys(bytes32 userId) public view returns (Lib.UserKeys memory keys) {
    return complianceUserKeys[userId];
  }

  function isValidInterventionKey(address interventionKey) public view returns (bool) {
    return interventionKeys[interventionKey];
  }

  function getCASTLState(address castlKey) public view returns (Lib.CASTLState state) {
    return castlKeys[castlKey];
  }

  function getAddApprovalRequest(bytes32 requestId)
    public
    view
    returns (Lib.AddApprovalRequest memory request)
  {
    return approvalKeyRequests[requestId];
  }

  function getEmergencyKeyReplacements(bytes32 requestId)
    public
    view
    returns (Lib.EmergencyReplacement memory request)
  {
    return emergencyKeyReplacements[requestId];
  }

  function getCowId() public view returns (bytes32) {
    return cowId;
  }

  function getInitiator() public view returns (Lib.InitRecord memory record) {
    return initiator;
  }

  //******************//
  //****** INIT ******//
  //******************//

  function init(SigUtil.BaseSignature calldata adminSignature) public {
    require(!alreadyInitialized, "already initialized");
    alreadyInitialized = true;
    string memory adminSignedMsg = adminSignature.message;
    address _recoveredSigner = SigUtil.verifySignature(adminSignature.signature, adminSignedMsg);

    if (castlKeys[_recoveredSigner] != Lib.CASTLState.Enabled) {
      emit Init("Invalid CASTL signature from caller!", false);
      revert("invalid CASTL signature");
    }

    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      require(_cowsState == GlobalState.COWSState.Recognized, "Global State not recognized");
    }

    {
      bool isEmergency2 = globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2);
      require(!isEmergency2, "GlobalState at emergencyReplace2");
    }

    string[] memory extractedMessage = SigUtil.extractMessage(adminSignedMsg);
    SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(extractedMessage);

    uint256 interventionKeyCount = message.totalInventionKeyNum;
    require(
      interventionKeyCount > 0 && interventionKeyCount < 6,
      "invalid num of intervention keys"
    );
    for (uint256 i; i < interventionKeyCount; ) {
      address interventionKey = message.interventionKeys[i];
      if (interventionKey == address(0)) {
        emit Init("Invalid interventionKey address!", false);
        revert("interventionKey is zero address");
      }
      interventionKeys[interventionKey] = true;
      unchecked {
        ++i;
      }
    }

    Lib.InitRecord storage _init = initiator;

    {
      bytes32[5] memory _userIds;
      _userIds[0] = message.userId[0];
      _userIds[1] = message.userId[2];
      _userIds[2] = message.userId[4];
      _userIds[3] = message.userId[6];
      _userIds[4] = message.userId[8];
      _init.addedUserIds = _userIds;
    }

    _init.interventionKeys = message.interventionKeys;

    {
      SigUtil.VerifiedSignature storage _verifiedSig = _init.callerSignature;
      _verifiedSig.signature = adminSignature;
      _verifiedSig.recoveredSigner = _recoveredSigner;
      _verifiedSig.isVerified = true;
    }

    for (uint256 i; i < 5; ) {
      uint256 approvalIndex = i * 2;
      uint256 emergencyIndex = approvalIndex + 1;

      bytes32 userId = message.userId[approvalIndex];

      Lib.EmergencyKeyUnit memory defaultEmergencyKeyUnit = Lib.EmergencyKeyUnit({
        delayTo: 0, // no delay for init EmergencyKeys
        emergencyKey: Lib.Key({
          keyType: Lib.KeyType.Emergency,
          derivationIndex: message.derivationIndex[emergencyIndex],
          keyAddress: message.userKeys[emergencyIndex]
        })
      });

      // Set input keys info to complianceUserKeys
      {
        Lib.UserKeys storage _userKeys = complianceUserKeys[userId];
        _userKeys.doesExist = true;
        _userKeys.isEnabled = true;
        _userKeys.emergencyKeyUnit = defaultEmergencyKeyUnit;
        _userKeys.approvalKeyUnit.uniqueDeviceId = message.deviceId[approvalIndex];
        _userKeys.approvalKeyUnit.approvalKeys.push(
          Lib.Key({
            keyType: Lib.KeyType.Approval,
            derivationIndex: message.derivationIndex[approvalIndex],
            keyAddress: message.userKeys[approvalIndex]
          })
        );
      }

      // Set input keys info to initiator
      {
        Lib.UserKeys storage _addedKey = _init.addedUserKeys[i];
        _addedKey.doesExist = true;
        _addedKey.isEnabled = true;
        _addedKey.emergencyKeyUnit = defaultEmergencyKeyUnit;
        _addedKey.approvalKeyUnit.uniqueDeviceId = message.deviceId[approvalIndex];
        _addedKey.approvalKeyUnit.approvalKeys.push(
          Lib.Key({
            keyType: Lib.KeyType.Approval,
            derivationIndex: message.derivationIndex[approvalIndex],
            keyAddress: message.userKeys[approvalIndex]
          })
        );
      }
      unchecked {
        ++i;
      }
    }

    globalState.setGlobalState(GlobalState.COWSState.ActiveNormal);

    /* Testing only */
    Lib.UserKeys storage _disabledUserKeys = complianceUserKeys[keccak256(bytes("testUserId"))];
    _disabledUserKeys.doesExist = true;
    _disabledUserKeys.isEnabled = false;
    _disabledUserKeys.approvalKeyUnit.uniqueDeviceId = keccak256(bytes("testDeviceId"));
    Lib.Key[] storage k = _disabledUserKeys.approvalKeyUnit.approvalKeys;
    k.push(
      Lib.Key({
        derivationIndex: 0,
        keyAddress: 0x927D0903b604d9f01eEB3be8eC65D93D9Cbf2Ec1,
        keyType: Lib.KeyType.Approval
      })
    );
    // _disabledUserKeys.approvalKeyUnit.approvalKeys[0].derivationIndex = 0;
    // _disabledUserKeys.approvalKeyUnit.approvalKeys[0].keyAddress = 0x927D0903b604d9f01eEB3be8eC65D93D9Cbf2Ec1;
    // _disabledUserKeys.approvalKeyUnit.approvalKeys[0].keyType = KeyType.Approval;
  }

  //**********************************//
  //****** APPROVAL KEY REQUEST ******//
  //**********************************//

  function addApprovalKeyRequest(
    bytes32 requestId,
    bytes32 userId,
    Lib.Key calldata key
  ) public {
    // 1) Check global state (should be under ActiveNormal)
    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      require(_cowsState == GlobalState.COWSState.ActiveNormal, "Global State not active normal");
    }

    // 2) Check if the number of new users + the number of existed users <= 5 (max. should be 5, use replace user if more than 5)
    //    if not, emit event AddApprovalKeyRequest("Request", "Exceed 5 keys!", false)
    require(key.keyType == Lib.KeyType.Approval, "Must be an Approval Key");

    // 3) Check if userId in each key is existed
    //    if not, emit event AddApprovalKeyRequest("Request", "Found unknown user!", false)
    Lib.Key[] memory currentUserKeys = complianceUserKeys[userId].approvalKeyUnit.approvalKeys;
    uint256 currentKeyCount = currentUserKeys.length;
    for (uint256 i; i < currentKeyCount; ) {
      require(currentUserKeys[i].keyAddress != key.keyAddress, "Key already in use!");
      unchecked {
        ++i;
      }
    }

    require(complianceUserKeys[userId].userBlocks == Lib.UserBlocks.None, "userBlock not None");

    if (!complianceUserKeys[userId].isEnabled) {
      emit AddApprovalKeyRequest("Add", "The request key is not enabled!", false);
      revert("user disabled");
    }

    // 4) Check if request id is existed
    //    if existed, emit event AddApprovalKeyRequest("Request", "The request add key id is already existed!", false)
    if (approvalKeyRequests[requestId].status != Lib.RequestStatus.Nonexistant) {
      emit AddApprovalKeyRequest("Request", "duplicate key add request", false);
      revert("already exists");
    }

    // 5) Add new AddApprovalRequest for request_id, added_keys, calculate expire_at_block by latest_block_time & expire_approval_key_request_in, set is_passed as false, set status as Processing
    Lib.AddApprovalRequest storage _request = approvalKeyRequests[requestId];
    _request.userId = userId;
    _request.addedApprovalKey = key;
    _request.status = Lib.RequestStatus.Pending;

    // 24 * 60 * 60 = 86400 seconds in 24 hours
    // 86400 / 12 (seconds per block) = 7200 blocks in 24 hours
    _request.expireAtBlock = block.timestamp + 1 days;

    // 6) emit event AddApprovalKeyRequest("Request", "The request is added successfully!", true)
    emit AddApprovalKeyRequest("Add", "The request is added successfully!", true);
  }

  function verifyApprovalKeyRequest(
    SigUtil.BaseSignature[5] calldata approvalSignatures,
    SigUtil.BaseSignature calldata adminSignature
  ) public {
    // 1) Check global state (should be under ActiveNormal)
    {
      Lib.checkState(globalState.globalState());
    }

    // 2) Extract params from message in caller_signature
    bytes32 requestId = Lib.extractReqId(adminSignature);

    // 3) Check if current block number < expireAtBlock;
    //    if not, emit event AddApprovalKeyRequest("Approve", "The request is already expired, please resubmit a new one!", false)
    if (block.timestamp > approvalKeyRequests[requestId].expireAtBlock) {
      emit AddApprovalKeyRequest(
        "Verify",
        "The request has expired, please resubmit a new one!",
        false
      );
      revert("already expired");
    }

    // 4) Check if caller has valid CASTL key
    //    if not, emit event AddApprovalKeyRequest("Approve", "Invalid CASTL key from caller!", false)

    // 6) Update caller_signature to approval_key_requests
    Lib.AddApprovalRequest storage _request = approvalKeyRequests[requestId];

    // 5) Call verifySignature() to check if the recovered signer of caller signature match
    //    if not, emit event AddApprovalKeyRequest("Approve", "Invalid CASTL signature from caller!", false)
    {
      address _recoveredSigner = SigUtil.verifySignature(
        adminSignature.signature,
        adminSignature.message
      );

      if (castlKeys[_recoveredSigner] != Lib.CASTLState.Enabled) {
        emit AddApprovalKeyRequest("Approve", "approval called from unknown CASTL address!", false);
        revert("castl key not enabled");
      }

      SigUtil.VerifiedSignature storage _verifiedSig = _request.callerSignature;
      _verifiedSig.signature = adminSignature;
      _verifiedSig.recoveredSigner = _recoveredSigner;
      _verifiedSig.isVerified = true;
    }

    // 7) Loop starts:
    //      Extract params from message in one of signed_approvals
    //      Check if is_passed is true or not, return false if approvals are done and emit event AddApprovalKeyRequest("Approve", "The request is already approved!", current_request_id)
    //      Check the existed signatures from approval_key_requests to see if current signature come from different approvers; if not, emit event AddApprovalKeyRequest("Approve", "The request is already approved by same approver!", current_request_id)
    //      Call verifySignature() to check if the recovered signer has valid approval key
    //        If passed, update is_verified of the signature as true to approval_key_requests
    //        If failed, emit event AddApprovalKeyRequest("Approve", "Invalid approval signature!", current_request_id)
    //      Count if the number of verified signatures hits min. threshold (3/5)
    //        If passed, update signed_approvals and is_passed as true and status as Approved to approval_key_requests
    uint256 countOfVerifiedSignatures;
    for (uint256 i; i < 5; ) {
      bytes32 _userId = Lib.extractUserId(approvalSignatures[i]);
      Lib.Key[] memory _approvalKeys = complianceUserKeys[_userId].approvalKeyUnit.approvalKeys;
      SigUtil.VerifiedSignature storage _signedApprovals = _request.signedApprovals[i];

      // if user is blocked in any way, skip user
      if (complianceUserKeys[_userId].userBlocks > Lib.UserBlocks.None) continue;

      if(Lib.checkApprovals(approvalSignatures[i], _approvalKeys, _signedApprovals)) {
        unchecked {
          ++countOfVerifiedSignatures;
        }
      }
      unchecked {
        ++i;
      }
    }
    require(countOfVerifiedSignatures > 2, "Not enough signatures passed"); // Check if number of approval keys is 5 (should have 5 users when init)

    if (_request.isPassed) {
      emit AddApprovalKeyRequest("Verify", "The request is already approved!", false);
      revert("already approved");
    }

    _request.isPassed = true;
    _request.status = Lib.RequestStatus.Approved;

    // 8) Emit event AddApprovalKeyRequest("Approve", "All passed!", true)
    emit AddApprovalKeyRequest("Approve", "addApprovalKey multisig passed", true);
  }

  function executeApprovalKeyRequest(bytes32 requestId) public {
    // 1) Check global state (should be under ActiveNormal)
    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      require(_cowsState == GlobalState.COWSState.ActiveNormal, "Global State not active normal");
    }

    Lib.AddApprovalRequest storage _request = approvalKeyRequests[requestId];

    // 2) Check request id existed
    //    if not, emit event AddApprovalKeyRequest("Execute", "Cannot find the request!", false)

    // 3) Check if current block number < expireAtBlock
    //    if not, emit event AddApprovalKeyRequest("Execute", "The request is already expired, please resubmit a new one!", false)

    if (block.timestamp > _request.expireAtBlock) {
      emit AddApprovalKeyRequest(
        "Execute",
        "The request is already expired, please resubmit a new one!",
        false
      );
      revert("already expired");
    }

    // 4) Check if is_passed is true and status is Approved
    //    if not, emit event AddApprovalKeyRequest("Execute", "The request isn't fully approved yet!", false) and return false
    if (!_request.isPassed && _request.status != Lib.RequestStatus.Approved) {
      emit AddApprovalKeyRequest("Execute", "The request isn't fully approved yet!", false);
      revert("not approved");
    }

    // 5) Update new keys in approval_keys
    Lib.Key memory _key = _request.addedApprovalKey;
    complianceUserKeys[_request.userId].approvalKeyUnit.approvalKeys.push(_key);

    // 6) Update status as Completed
    _request.status = Lib.RequestStatus.Completed;

    // 7) If there's already a key/ keys exists for the device, don't update. It should go through replace key process

    // 8) Emit event AddApprovalKeyRequest("Execute", "Executed add request!", true)
    emit AddApprovalKeyRequest("Execute", "Executed add request!", true);
  }

  //************************************//
  //****** COMBINED ADD APPROVAL  ******//
  //************************************//
  function addApprovalKey(
    bytes32 requestId,
    bytes32 userId,
    Lib.Key calldata key,
    SigUtil.BaseSignature[5] calldata approvalSignatures,
    SigUtil.BaseSignature calldata adminSignature
  ) public {
    addApprovalKeyRequest(requestId, userId, key);

    verifyApprovalKeyRequest(approvalSignatures, adminSignature);

    executeApprovalKeyRequest(requestId);
  }

  //************************************//
  //****** EMERGENCY USER REPLACE ******//
  //************************************//

  function emergencyReplaceUserKeysStart(SigUtil.BaseSignature calldata emergencySignature) public {
    // 1) Extract params from message in signed_emergency_signature
    SigUtil.ExtractedSigningMessage memory message;
    {
      string[] memory _extractedMessage = SigUtil.extractMessage(emergencySignature.message);
      message = SigUtil.convertToStruct(_extractedMessage);
    }

    if (block.timestamp < complianceUserKeys[message.userId[0]].emergencyKeyUnit.delayTo) {
      revert("emergency key in timeout");
    }

    require(
      complianceUserKeys[message.userId[0]].userBlocks != Lib.UserBlocks.All,
      "userBlock for all function calls"
    );

    // Check if requestId already existed
    //    if yes, emit event EmergencyReplaceUserKeysRequest("Request", "The request id is already existed!", false) and return false
    if (emergencyKeyReplacements[message.requestId].status != Lib.EmergencyRequestStatus.Nonexistant) {
      emit EmergencyReplaceUserKeysRequest("Request", "The request id already exists!", false);
      revert("already exists");
    }

    Lib.EmergencyReplacement storage _emergencyReplaceRequest = emergencyKeyReplacements[
      message.requestId
    ];

    // Call verifySignature() to check if the recovered signer has valid emergency key
    {
      address _emergencyKey = complianceUserKeys[message.userId[0]]
        .emergencyKeyUnit
        .emergencyKey
        .keyAddress;
      (bool isVerified, ) = verifySingleSignature(_emergencyKey, emergencySignature);
      require(isVerified, "invalid emergency signature");
    }

    // Check global state, if it's still Active Normal, update to ActiveEmergency
    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      if (_cowsState == GlobalState.COWSState.ActiveNormal) {
        globalState.setGlobalState(GlobalState.COWSState.ActiveEmergency);
        globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
        _emergencyReplaceRequest.delayTo = block.timestamp + 1 days;
      } else if (_cowsState == GlobalState.COWSState.ActiveEmergency) {
        if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
          revert("only 2 requests at a time");
        }
        if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
          globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, true);
          globalState.setFlaggedState(GlobalState.FlaggedState.Paused, true);
          _emergencyReplaceRequest.delayTo = block.timestamp + 2 days;
        }
      } else {
        revert("state not ActiveNormal/Emergency");
      }
    }

    currentReplacingUserRequestId = message.requestId;

    // Set status as Processing
    _emergencyReplaceRequest.status = Lib.EmergencyRequestStatus.Started;

    // Extract and remove all keys assigned to the userId from approvalKeys (old keys)
    _emergencyReplaceRequest.oldKeys = complianceUserKeys[message.userId[0]];
    // delete complianceUserKeys[userId];

    // Update caller as gasWallet to the emergencyKeyReplacements
    _emergencyReplaceRequest.gasWallet = msg.sender;

    // Add new EmergencyReplacement to emergencyKeyReplacements with requestId, userId, oldKeys, newKeys, isPassed as false
    _emergencyReplaceRequest.userId = message.userId[0];
    // _emergencyReplaceRequest.newKeys = newKeys;
    {
      bool hasEmergencyKey = false;
      _emergencyReplaceRequest.newKeys.doesExist = true;
      _emergencyReplaceRequest.newKeys.isEnabled = true;
      _emergencyReplaceRequest.newKeys.approvalKeyUnit.uniqueDeviceId = message.deviceId[0];

      for (uint256 i = 0; i < message.totalKeyNum; ) {
        StringUtils.Slice memory keyType = message.userKeyType[i].toSlice();

        if (keyType.equals("Emergency".toSlice()) && !hasEmergencyKey) {
          _emergencyReplaceRequest.newKeys.emergencyKeyUnit = Lib.EmergencyKeyUnit({
            delayTo: 0,
            emergencyKey: Lib.Key({
              keyType: Lib.KeyType.Emergency,
              derivationIndex: message.derivationIndex[i],
              keyAddress: message.userKeys[i]
            })
          });

          hasEmergencyKey = true;
        } else {
          _emergencyReplaceRequest.newKeys.approvalKeyUnit.approvalKeys.push(
            Lib.Key({
              keyType: Lib.KeyType.Approval,
              derivationIndex: message.derivationIndex[i],
              keyAddress: message.userKeys[i]
            })
          );
        }
        unchecked {
          ++i;
        }
      }
    }

    // Blocks user from all functionality
    complianceUserKeys[message.userId[0]].userBlocks = Lib.UserBlocks.All;

    // Emit event EmergencyReplaceUserKeysRequest("Start", "Emergency user key replacement starts!", true)
    emit EmergencyReplaceUserKeysRequest("Start", "Emergency user key replacement starts!", true);
  }

  // This function is for canceling emergency replacement by another emergency key or intervention key
  function emergencyReplaceUserKeysIntervene(SigUtil.BaseSignature calldata signedRejectApproval)
    public
    returns (bool)
  {
    bytes32 requestId;
    address rejectorAddress;
    string memory keyType;
    {
      string[] memory _extractedMessage = SigUtil.extractMessage(signedRejectApproval.message);
      SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(_extractedMessage);
      requestId = message.requestId;
      rejectorAddress = message.signerPublicAddress;
      keyType = message.keyType;
    }

    // Check if caller has valid intervention key;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Intervene", "Invalid caller!", false)
    {
      bytes32 inputKeyType = bytes32(abi.encodePacked(keyType));
      bytes32 expectedKeyType = bytes32(abi.encodePacked("Intervention"));
      if (inputKeyType != expectedKeyType) {
        emit EmergencyReplaceUserKeysRequest(
          "Intervene",
          "intervention sig wrong key type!",
          false
        );
        revert("intervention sig wrong key type!");
      }
    }

    Lib.EmergencyReplacement storage _emergencyReplaceRequest = emergencyKeyReplacements[requestId];

    // Check if current block number exceeds delayTo block number;
    //   if exceed, emit event EmergencyReplaceUserKeysRequest("Intervene", "The delayed time is over now!", false)
    /* if (block.timestamp > _emergencyReplaceRequest.delayTo) {
      emit EmergencyReplaceUserKeysRequest("Intervene", "The delayed time is over now!", false);
      revert("request is expired");
    } */

    // Call verifySignature() to check if the recovered signer has a valid intervention key;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Intervene", "Invalid signature!", false)
    require(interventionKeys[rejectorAddress], "intervention from unknown addr!");
    (bool isVerified, ) = verifySingleSignature(rejectorAddress, signedRejectApproval);
    if (!isVerified) {
      emit EmergencyReplaceUserKeysRequest("Intervene", "bad signature in intervention!", false);
      revert("bad signature in intervention!");
    }

    // Check if the recovered signer is an disabled user;
    //   if yes, emit event EmergencyReplaceUserKeysRequest("Intervene", "The signature signer is an disable user!", false)
    /* if (!complianceUserKeys[_emergencyReplaceRequest.userId].isEnabled) {
      emit EmergencyReplaceUserKeysRequest(
        "Intervene",
        "The signature signer is from a disabled user!",
        false
      );
      revert("user disabled");
    } */

    // Update signature and isVerified into signedToRejectApprovals
    _emergencyReplaceRequest.signedRejectionSignature = SigUtil.VerifiedSignature({
      recoveredSigner: rejectorAddress,
      isVerified: true,
      signature: signedRejectApproval
    });

    // Accept number of signed reject approvals >= 1
    //   If passed, set isRejected as true
    //   Set isEmergency in approvalKeys back to false (deprecated)
    //   Set isEmergencyReplace2 back to false and
    //     countOfCompletedEmergencyReplacements = 1 in global state contract
    //   Set status as Rejected
    _emergencyReplaceRequest.isRejected = true;
    _emergencyReplaceRequest.status = Lib.EmergencyRequestStatus.Rejected;

    bytes32 userId = _emergencyReplaceRequest.userId;
    if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, false);
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
      globalState.setFlaggedState(GlobalState.FlaggedState.Paused, false);
      complianceUserKeys[userId].emergencyKeyUnit.delayTo = block.timestamp + 24 hours;
      complianceUserKeys[userId].userBlocks = Lib.UserBlocks.None;
    } else if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, false);
      globalState.setGlobalState(GlobalState.COWSState.ActiveNormal);
      complianceUserKeys[userId].emergencyKeyUnit.delayTo = block.timestamp + 12 hours;
      complianceUserKeys[userId].userBlocks = Lib.UserBlocks.None;
    }

    // Emit event EmergencyReplaceUserKeysRequest("Intervene", "The request is intervened successfully!", true)
    emit EmergencyReplaceUserKeysRequest(
      "Intervene",
      "The request is intervened successfully!",
      true
    );
    return true;
  }

  // This function is for executing approved emergency replacement request
  function emergencyReplaceUserKeysExecute(bytes32 requestId) public {
    Lib.EmergencyReplacement memory _emergencyKeyReplacements = emergencyKeyReplacements[requestId];
    bytes32 parsedUserId = _emergencyKeyReplacements.userId;

    // Check if the request is already rejected by approvers;
    //   if yes, emit event EmergencyReplaceUserKeysRequest("Execute", "This request is rejected via intervention process!", false)
    if (_emergencyKeyReplacements.isRejected) {
      emit EmergencyReplaceUserKeysRequest(
        "Execute",
        "This request is rejected via intervention process!",
        false
      );
      revert("already rejected");
    }

    // Check if current block number exceeds delayTo block number;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Execute", "Execution should wait until the delayed time end!", false)
    if (block.timestamp < _emergencyKeyReplacements.delayTo) {
      emit EmergencyReplaceUserKeysRequest(
        "Execute",
        "Execution should wait until the delayed time end!",
        false
      );
      revert("not delayed long enough");
    }

    // If all passed,
    //   Update new key in approvalKeys
    {
      Lib.UserKeys storage existingUserKeys = complianceUserKeys[parsedUserId];
      Lib.UserKeys memory freshUserKeys = _emergencyKeyReplacements.newKeys;

      existingUserKeys.doesExist = true;
      existingUserKeys.isEnabled = true;
      existingUserKeys.emergencyKeyUnit = freshUserKeys.emergencyKeyUnit;
      existingUserKeys.approvalKeyUnit.uniqueDeviceId = freshUserKeys
        .approvalKeyUnit
        .uniqueDeviceId;

      delete existingUserKeys.approvalKeyUnit.approvalKeys;

      uint256 approvalKeyCount = freshUserKeys.approvalKeyUnit.approvalKeys.length;
      for (uint256 i; i < approvalKeyCount; ) {
        existingUserKeys.approvalKeyUnit.approvalKeys.push(
          freshUserKeys.approvalKeyUnit.approvalKeys[i]
        );
        unchecked {
          ++i;
        }
      }

      complianceUserKeys[parsedUserId].userBlocks = Lib.UserBlocks.None;
    }

    //   Set both isEmergencyReplace1 & isEmergencyReplace2 back as false in global state contract

    if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, false);
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
      globalState.setFlaggedState(GlobalState.FlaggedState.Paused, false);
    } else if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, false);
      globalState.setGlobalState(GlobalState.COWSState.ActiveNormal);
    }

    //   Set status as Executed
    emergencyKeyReplacements[requestId].status = Lib.EmergencyRequestStatus.Executed;

    //   Emit event EmergencyReplaceUserKeysRequest("Execute", "Execute emergency user keys replacement successfully!", true)
    emit EmergencyReplaceUserKeysRequest(
      "Execute",
      "Execute emergency user keys replacement successfully!",
      true
    );
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {VerifySignatureUtil as SigUtil} from "../../VerifySignatureUtil.sol";
import {GlobalState} from "../../GlobalState.sol";
import {COWSManagement} from "../../COWSManagement.sol";

contract StorageStruct {
  using SigUtil for SigUtil.VerifiedSignature;

  //*******************//
  //****** ENUMS ******//
  //*******************//

  enum KeyType {
    Approval,
    CASTL,
    Emergency,
    Intervention
  }

  enum CASTLState {
    Nonexistant,
    Enabled,
    Expired
  }

  enum CASTLRequestAction {
    Add,
    Expire
  }

  enum InterventionRequestAction {
    Add,
    Remove
  }

  enum ControlAction {
    Enable,
    Disable
  }

  enum UserBlocks {
    None,
    Approval,
    All
  }

  enum CloseType {
    AddApprovalKeyRequest,
    AddCASTLKeyRequest,
    ChangeInterventionKeyRequest,
    ReplaceKeyRequest,
    ReplaceCASTLKeyRequest,
    ChangeUserKeysStatusRequest,
    ReplaceUserRequest
  }

  enum RequestStatus {
    Nonexistant,
    Pending,
    Processing,
    Approved,
    Completed,
    ForceClosed
  }

  enum EmergencyRequestStatus {
    Nonexistant,
    Started,
    Executed,
    Rejected
  }

  //*********************//
  //****** STRUCTS ******//
  //*********************//

  struct Key {
    KeyType keyType;
    int32 derivationIndex;
    address keyAddress;
  }

  struct ApprovalKeyUnit {
    bytes32 uniqueDeviceId;
    Key[] approvalKeys;
  }

  struct EmergencyKeyUnit {
    uint256 delayTo;
    Key emergencyKey;
  }

  struct UserKeys {
    bool doesExist;
    bool isEnabled;
    UserBlocks userBlocks;
    EmergencyKeyUnit emergencyKeyUnit;
    ApprovalKeyUnit approvalKeyUnit;
  }

  struct SignatureBlock {
    bytes32 userId;
    SigUtil.BaseSignature baseSignature;
  }

  struct AddApprovalRequest {
    bytes32 userId;
    Key addedApprovalKey;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct AddCASTLRequest {
    address addedKey;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct AddInterventionRequest {
    InterventionRequestAction requestType;
    address key;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct ControlUserRequest {
    ControlAction actionType;
    KeyType signerKeyType;
    bytes32 userId;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct ReplacementUnit {
    KeyType keyType;
    address newKey;
    bytes32 deviceId;
    int32 newDerivationIndex;
  }

  struct UserReplacement {
    bytes32 oldUserId;
    bytes32 newUserId;
    ReplacementUnit[] newKeys;
    ReplacementUnit[] oldKeys;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct EmergencyReplacement {
    address gasWallet;
    bytes32 userId;
    UserKeys oldKeys;
    UserKeys newKeys;
    SigUtil.VerifiedSignature signedEmergencySignature;
    SigUtil.VerifiedSignature signedRejectionSignature;
    uint256 delayTo;
    bool isRejected;
    EmergencyRequestStatus status;
  }

  struct InitRecord {
    bytes32[5] addedUserIds;
    UserKeys[5] addedUserKeys;
    address[] interventionKeys;
    SigUtil.VerifiedSignature callerSignature;
  }

  //***********************//
  //****** VARIABLES ******//
  //***********************//

  COWSManagement public cowsManagement;
  GlobalState public globalState;

  mapping(bytes32 => UserKeys) public complianceUserKeys;

  mapping(address => bool) public interventionKeys;
  mapping(address => CASTLState) public castlKeys;

  mapping(bytes32 => AddApprovalRequest) public approvalKeyRequests;
  mapping(bytes32 => AddCASTLRequest) public castlKeyRequests;
  mapping(bytes32 => AddInterventionRequest) public interventionKeyRequests;
  mapping(bytes32 => ControlUserRequest) public controlUserKeysRequests;

  mapping(bytes32 => UserReplacement) public userReplacements;
  mapping(bytes32 => EmergencyReplacement) public emergencyKeyReplacements;

  bytes32 public currentDisabledUser;
  bytes32 public currentReplacingUserRequestId;
  bytes32 public currentChangeInterventionKeyRequestId;
  bytes32 public cowId;
  InitRecord public initiator;
  bool public alreadyInitialized;

  constructor(
    address[] memory _castlKeys,
    bytes32 _cowId,
    address _managementAddress,
    address _stateAddress
  ) {
    uint256 _castlKeysCount = _castlKeys.length;
    require(_castlKeysCount > 0, "_castlKeys is empty");

    for (uint256 i; i < _castlKeysCount; ) {
      castlKeys[_castlKeys[i]] = CASTLState.Enabled;
      unchecked {
        ++i;
      }
    }
    cowId = _cowId;
    cowsManagement = COWSManagement(_managementAddress);
    globalState = GlobalState(_stateAddress);
  }

  //*********************//
  //****** GETTERS ******//
  //*********************//

  function getUserKeys(bytes32 userId) public view returns (StorageStruct.UserKeys memory keys) {
    return complianceUserKeys[userId];
  }

  function setUserKeys(bytes32 userId, EmergencyKeyUnit calldata emergencyKeyUnit, bytes32 deviceId, int32 derivationIndex, address key) public {
    StorageStruct.UserKeys storage _userKeys = complianceUserKeys[userId];
    _userKeys.doesExist = true;
    _userKeys.isEnabled = true;
    _userKeys.emergencyKeyUnit = emergencyKeyUnit;
    _userKeys.approvalKeyUnit.uniqueDeviceId = deviceId;
    _userKeys.approvalKeyUnit.approvalKeys.push(
      Key({
        keyType: KeyType.Approval,
        derivationIndex: derivationIndex,
        keyAddress: key
      })
    );
  }

  function setUserKeysByEmgOnly(bytes32 userId, bytes32 deviceId, EmergencyKeyUnit calldata emergencyKeyUnit) public {
    StorageStruct.UserKeys storage _userKeys = complianceUserKeys[userId];
    _userKeys.doesExist = true;
    _userKeys.isEnabled = true;
    _userKeys.emergencyKeyUnit = emergencyKeyUnit;
    _userKeys.approvalKeyUnit.uniqueDeviceId = deviceId;
  }

  function setUserKeysByApprovalOnly(bytes32 userId, Key memory key) public {
    StorageStruct.UserKeys storage _userKeys = complianceUserKeys[userId];
    _userKeys.approvalKeyUnit.approvalKeys.push(key);
  }

  function deleteUserKeys(bytes32 userId) public {
    StorageStruct.UserKeys storage _userKeys = complianceUserKeys[userId];
    delete _userKeys.approvalKeyUnit.approvalKeys;
  }

  function setUserKeysByDelay(bytes32 userId, uint256 delayTo) public {
    StorageStruct.UserKeys storage _userKeys = complianceUserKeys[userId];
    _userKeys.emergencyKeyUnit.delayTo = delayTo;
    _userKeys.userBlocks = UserBlocks.None;
  }

  function setUserKeysByUserBlockOnly(bytes32 userId, UserBlocks userBlock) public {
    StorageStruct.UserKeys storage _userKeys = complianceUserKeys[userId];
    _userKeys.userBlocks = userBlock;
  }

  function isValidInterventionKey(address interventionKey) public view returns (bool) {
    return interventionKeys[interventionKey];
  }

  function getCASTLState(address castlKey) public view returns (StorageStruct.CASTLState state) {
    return castlKeys[castlKey];
  }

  function getAddApprovalRequest(bytes32 requestId)
    public
    view
    returns (StorageStruct.AddApprovalRequest memory request)
  {
    return approvalKeyRequests[requestId];
  }

  function setApprovalRequestByIdKeys(bytes32 requestId, bytes32 userId, Key calldata key) public {
    StorageStruct.AddApprovalRequest storage _request = approvalKeyRequests[requestId];
    _request.userId = userId;
    _request.addedApprovalKey = key;
    _request.status = RequestStatus.Pending;

    // 24 * 60 * 60 = 86400 seconds in 24 hours
    // 86400 / 12 (seconds per block) = 7200 blocks in 24 hours
    _request.expireAtBlock = block.timestamp + 1 days;
  }

  function setApprovalRequestBySigs(bytes32 requestId, SigUtil.VerifiedSignature calldata verifiedSig) public {
    StorageStruct.AddApprovalRequest storage _request = approvalKeyRequests[requestId];
    _request.callerSignature = verifiedSig;
  }

  function setApprovalRequestByStatus(bytes32 requestId) public {
    StorageStruct.AddApprovalRequest storage _request = approvalKeyRequests[requestId];
    _request.isPassed = true;
    _request.status = StorageStruct.RequestStatus.Approved;
  }

  function setApprovalRequestComplete(bytes32 requestId) public {
    StorageStruct.AddApprovalRequest storage _request = approvalKeyRequests[requestId];
    _request.status = RequestStatus.Completed;
  }

  function getEmergencyKeyReplacements(bytes32 requestId)
    public
    view
    returns (StorageStruct.EmergencyReplacement memory request)
  {
    return emergencyKeyReplacements[requestId];
  }

  function setEmergencyKeyReplacements(bytes32 requestId, bytes32 userId, bytes32 deviceId) public {
    StorageStruct.EmergencyReplacement storage _emergencyReplaceRequest = emergencyKeyReplacements[
      requestId
    ];
    _emergencyReplaceRequest.status = EmergencyRequestStatus.Started;
    _emergencyReplaceRequest.oldKeys = complianceUserKeys[userId];
    _emergencyReplaceRequest.gasWallet = msg.sender;
    _emergencyReplaceRequest.userId = userId;

    _emergencyReplaceRequest.newKeys.doesExist = true;
    _emergencyReplaceRequest.newKeys.isEnabled = true;
    _emergencyReplaceRequest.newKeys.approvalKeyUnit.uniqueDeviceId = deviceId;
  }

  function setEmergencyKeyReplacementsByEmgKeys(bytes32 requestId, int32 derivationIndex, address key) public {
    StorageStruct.EmergencyReplacement storage _emergencyReplaceRequest = emergencyKeyReplacements[
      requestId
    ];

    _emergencyReplaceRequest.newKeys.emergencyKeyUnit = EmergencyKeyUnit({
      delayTo: 0,
      emergencyKey: Key({
        keyType: KeyType.Emergency,
        derivationIndex: derivationIndex,
        keyAddress: key
      })
    });
  }

  function setEmergencyKeyReplacementsByAprvKeys(bytes32 requestId, int32 derivationIndex, address key) public {
    StorageStruct.EmergencyReplacement storage _emergencyReplaceRequest = emergencyKeyReplacements[
      requestId
    ];

    _emergencyReplaceRequest.newKeys.approvalKeyUnit.approvalKeys.push(
      Key({
        keyType: KeyType.Approval,
        derivationIndex: derivationIndex,
        keyAddress: key
      })
    );
  }

  function setEmergencyKeyReplacementsByRejSig(bytes32 requestId, address rejectorAddress, SigUtil.BaseSignature calldata signedRejectApproval) public {
    StorageStruct.EmergencyReplacement storage _emergencyReplaceRequest = emergencyKeyReplacements[
      requestId
    ];

    _emergencyReplaceRequest.signedRejectionSignature = SigUtil.VerifiedSignature({
      recoveredSigner: rejectorAddress,
      isVerified: true,
      signature: signedRejectApproval
    });

    _emergencyReplaceRequest.isRejected = true;
    _emergencyReplaceRequest.status = EmergencyRequestStatus.Rejected;
  }

  function setEmergencyKeyReplacementsByDelay(bytes32 requestId, uint256 delayTo) public {
    StorageStruct.EmergencyReplacement storage _emergencyReplaceRequest = emergencyKeyReplacements[
      requestId
    ];
    _emergencyReplaceRequest.delayTo = delayTo;
  }

  function setEmergencyKeyReplacementsComplete(bytes32 requestId) public {
    StorageStruct.EmergencyReplacement storage _emergencyReplaceRequest = emergencyKeyReplacements[
      requestId
    ];
    _emergencyReplaceRequest.status = StorageStruct.EmergencyRequestStatus.Executed;
  }

  function getCowId() public view returns (bytes32) {
    return cowId;
  }

  function getInitiator() public view returns (StorageStruct.InitRecord memory record) {
    return initiator;
  }

  function getGlobStateContract() public view returns (GlobalState globState) {
    return globalState;
  }

  function getAlreadyInitialized() public view returns (bool isInit) {
    return alreadyInitialized;
  }

  function getCurrentReplacingUserRequestId() public view returns (bytes32 id) {
    return currentReplacingUserRequestId;
  }

  function setCurrentReplacingUserRequestId(bytes32 val) public {
    currentReplacingUserRequestId = val;
  }

  function setAlreadyInitialized(bool val) public {
    alreadyInitialized = val;
  }

  function setInterventionKey(address interventionKey) public {
    interventionKeys[interventionKey] = true;
  }

  function setIdsForInitiator(bytes32[5] calldata addedUserIds) public {
    StorageStruct.InitRecord storage _init = initiator;
    _init.addedUserIds = addedUserIds;
  }

  function setUserKeysForInitiator(uint i, EmergencyKeyUnit calldata emergencyKeyUnit, bytes32 deviceId, int32 derivationIndex, address key) public {
    StorageStruct.UserKeys storage _addedKey = initiator.addedUserKeys[i];
    _addedKey.doesExist = true;
    _addedKey.isEnabled = true;
    _addedKey.emergencyKeyUnit = emergencyKeyUnit;
    _addedKey.approvalKeyUnit.uniqueDeviceId = deviceId;
    _addedKey.approvalKeyUnit.approvalKeys.push(
      Key({
        keyType: KeyType.Approval,
        derivationIndex: derivationIndex,
        keyAddress: key
      })
    );
  }

  function setInterventionKeysForInitiator(address[5] memory keys) public {
    StorageStruct.InitRecord storage _init = initiator;
    _init.interventionKeys = keys;
  }

  function setSigForInitiator(SigUtil.VerifiedSignature calldata callerSignature) public {
    StorageStruct.InitRecord storage _init = initiator;
    _init.callerSignature = callerSignature;
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Console} from "../../Console.sol";
import {StringUtils} from "../../StringUtils.sol";
import {VerifySignatureUtil as SigUtil} from "../../VerifySignatureUtil.sol";
import {GlobalState} from "../../GlobalState.sol";
import {COWSManagement} from "../../COWSManagement.sol";
import {StorageStruct} from "./StorageStruct.sol";

contract T3KeyManagement {
  using StringUtils for *;
  using SigUtil for SigUtil.VerifiedSignature;

  //***********************//
  //****** VARIABLES ******//
  //***********************//
  address _keysStorageAddress;

  //********************//
  //****** EVENTS ******//
  //********************//

  event Init(string msg, bool isSuccess);
  event AddApprovalKeyRequest(string actionType, string msg, bool isSuccess);
  event AddCASTLKeyRequest(string actionType, string msg, bool isSuccess);
  event ChangeInterventionKeyRequest(string actionType, string msg, bool isSuccess);
  event ReplaceKeyRequest(string actionType, string msg, bool isSuccess);
  event ReplaceCASTLKeyRequest(string actionType, string msg, bool isSuccess);
  event ChangeUserKeysStatusRequest(string actionType, string msg, bool isSuccess);
  event ReplaceUserRequest(string actionType, string msg, bool isSuccess);
  event ForceClose(string msg, bool isSuccess);
  event DeployNewKeyStorage(string msg, bool isSuccess);

  //*************************//
  //****** CONSTRUCTOR ******//
  //*************************//

  constructor(
    address[] memory _castlKeys,
    bytes32 _cowId,
    address _managementAddress,
    address _stateAddress
  ) {
    try
    new StorageStruct(_castlKeys, _cowId, address(this), _stateAddress)
    returns (StorageStruct _address) {
    _keysStorageAddress = address(_address);
    } catch Error(string memory reason) {
    emit DeployNewKeyStorage("Failed to deploy new key storage!", false);
    revert(string(abi.encodePacked("KEYSTORAGE: ", reason)));
    }
  }

  //*********************//
  //****** HELPERS ******//
  //*********************//

  function verifyCastlSignature(SigUtil.BaseSignature calldata castlSignature)
    public
    view
    returns (bool)
  {
    address _recoveredSigner = SigUtil.verifySignature(
      castlSignature.signature,
      castlSignature.message
    );

    if (StorageStruct(_keysStorageAddress).getCASTLState(_recoveredSigner) != StorageStruct.CASTLState.Enabled) {
      return false;
    }
    return true;
  }

  function verifyApprovalSignature(bytes32 userId, SigUtil.BaseSignature calldata baseSignature)
    public
    view
    returns (bool, address)
  {
    StorageStruct.Key[] memory _approvalKeys = StorageStruct(_keysStorageAddress).getUserKeys(userId).approvalKeyUnit.approvalKeys;

    address _recoveredApprover = SigUtil.verifySignature(
      baseSignature.signature,
      baseSignature.message
    );
    bool isVerified;
    uint256 _approvalKeyCount = _approvalKeys.length;
    for (uint256 k; k < _approvalKeyCount; ) {
      if (_approvalKeys[k].keyAddress == _recoveredApprover) {
        isVerified = true;
        break;
      }
      unchecked {
        ++k;
      }
    }
    return (isVerified, _recoveredApprover);
  }

  function verifySingleSignature(
    address expectedKeyAddress,
    SigUtil.BaseSignature calldata baseSignature
  ) public view returns (bool, address) {
    address _recoveredApprover = SigUtil.verifySignature(
      baseSignature.signature,
      baseSignature.message
    );

    Console.log("expectedKeyAddress: ", expectedKeyAddress);
    Console.log("_recoveredApprover: ", _recoveredApprover);

    bool isVerified;

    if (expectedKeyAddress == _recoveredApprover) {
      isVerified = true;
    }

    return (isVerified, _recoveredApprover);
  }

  /// @dev may end up refactoring in a different way later
  function setUserBlock(bytes32 requestId, StorageStruct.UserBlocks userBlock) external {
    require(msg.sender == address(StorageStruct(_keysStorageAddress).getGlobStateContract()), "msg sender not global state");
    bytes32 userId = StorageStruct(_keysStorageAddress).getEmergencyKeyReplacements(requestId).userId;
    StorageStruct(_keysStorageAddress).getUserKeys(userId).userBlocks = userBlock;
  }

  //******************//
  //****** INIT ******//
  //******************//

  function init(SigUtil.BaseSignature calldata adminSignature) public {
    require(!StorageStruct(_keysStorageAddress).getAlreadyInitialized(), "already initialized");
    StorageStruct(_keysStorageAddress).setAlreadyInitialized(true);
    string memory adminSignedMsg = adminSignature.message;
    address _recoveredSigner = SigUtil.verifySignature(adminSignature.signature, adminSignedMsg);

    if (StorageStruct(_keysStorageAddress).getCASTLState(_recoveredSigner) != StorageStruct.CASTLState.Enabled) {
      emit Init("Invalid CASTL signature from caller!", false);
      revert("invalid CASTL signature");
    }

    {
      GlobalState.COWSState _cowsState = StorageStruct(_keysStorageAddress).getGlobStateContract().globalState();
      require(_cowsState == GlobalState.COWSState.Recognized, "Global State not recognized");
    }

    {
      bool isEmergency2 = StorageStruct(_keysStorageAddress).getGlobStateContract().getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2);
      require(!isEmergency2, "GlobalState at emergencyReplace2");
    }

    string[] memory extractedMessage = SigUtil.extractMessage(adminSignedMsg);
    SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(extractedMessage);

    uint256 interventionKeyCount = message.totalInventionKeyNum;
    require(
      interventionKeyCount > 0 && interventionKeyCount < 6,
      "invalid num of intervention keys"
    );
    for (uint256 i; i < interventionKeyCount; ) {
      address interventionKey = message.interventionKeys[i];
      if (interventionKey == address(0)) {
        emit Init("Invalid interventionKey address!", false);
        revert("interventionKey is zero address");
      }
      StorageStruct(_keysStorageAddress).setInterventionKey(interventionKey);
      unchecked {
        ++i;
      }
    }

    {
      bytes32[5] memory _userIds;
      _userIds[0] = message.userId[0];
      _userIds[1] = message.userId[2];
      _userIds[2] = message.userId[4];
      _userIds[3] = message.userId[6];
      _userIds[4] = message.userId[8];
      StorageStruct(_keysStorageAddress).setIdsForInitiator(_userIds);
    }

    StorageStruct(_keysStorageAddress).setInterventionKeysForInitiator(message.interventionKeys);

    {
      StorageStruct(_keysStorageAddress).setSigForInitiator(SigUtil.VerifiedSignature(adminSignature, _recoveredSigner, true));
    }

    for (uint256 i; i < 5; ) {
      uint256 approvalIndex = i * 2;
      uint256 emergencyIndex = approvalIndex + 1;

      bytes32 userId = message.userId[approvalIndex];

      StorageStruct.EmergencyKeyUnit memory defaultEmergencyKeyUnit = StorageStruct.EmergencyKeyUnit({
        delayTo: 0, // no delay for init EmergencyKeys
        emergencyKey: StorageStruct.Key({
          keyType: StorageStruct.KeyType.Emergency,
          derivationIndex: message.derivationIndex[emergencyIndex],
          keyAddress: message.userKeys[emergencyIndex]
        })
      });

      // Set input keys info to complianceUserKeys
      {
        StorageStruct(_keysStorageAddress).setUserKeys(userId, defaultEmergencyKeyUnit, message.deviceId[approvalIndex], message.derivationIndex[approvalIndex], message.userKeys[approvalIndex]);
      }

      // Set input keys info to initiator
      {
        StorageStruct(_keysStorageAddress).setUserKeysForInitiator(i, defaultEmergencyKeyUnit, message.deviceId[approvalIndex], message.derivationIndex[approvalIndex], message.userKeys[approvalIndex]);
      }
      unchecked {
        ++i;
      }
    }

    StorageStruct(_keysStorageAddress).getGlobStateContract().setGlobalState(GlobalState.COWSState.ActiveNormal);

    /* Testing only */
    StorageStruct(_keysStorageAddress).setUserKeys(keccak256(bytes("testUserId")), StorageStruct.EmergencyKeyUnit(0, StorageStruct.Key(StorageStruct.KeyType.Emergency,-1, address(0))), keccak256(bytes("testDeviceId")), 0, 0x927D0903b604d9f01eEB3be8eC65D93D9Cbf2Ec1);
  }

  //**********************************//
  //****** APPROVAL KEY REQUEST ******//
  //**********************************//

  function addApprovalKeyRequest(
    bytes32 requestId,
    bytes32 userId,
    StorageStruct.Key calldata key
  ) public {
    // 1) Check global state (should be under ActiveNormal)
    {
      GlobalState.COWSState _cowsState = StorageStruct(_keysStorageAddress).getGlobStateContract().globalState();
      require(_cowsState == GlobalState.COWSState.ActiveNormal, "Global State not active normal");
    }

    // 2) Check if the number of new users + the number of existed users <= 5 (max. should be 5, use replace user if more than 5)
    //    if not, emit event AddApprovalKeyRequest("Request", "Exceed 5 keys!", false)
    require(key.keyType == StorageStruct.KeyType.Approval, "Must be an Approval Key");

    // 3) Check if userId in each key is existed
    //    if not, emit event AddApprovalKeyRequest("Request", "Found unknown user!", false)
    StorageStruct.Key[] memory currentUserKeys = StorageStruct(_keysStorageAddress).getUserKeys(userId).approvalKeyUnit.approvalKeys;
    uint256 currentKeyCount = currentUserKeys.length;
    for (uint256 i; i < currentKeyCount; ) {
      require(currentUserKeys[i].keyAddress != key.keyAddress, "Key already in use!");
      unchecked {
        ++i;
      }
    }

    require(StorageStruct(_keysStorageAddress).getUserKeys(userId).userBlocks == StorageStruct.UserBlocks.None, "userBlock not None");

    if (!StorageStruct(_keysStorageAddress).getUserKeys(userId).isEnabled) {
      emit AddApprovalKeyRequest("Add", "The request key is not enabled!", false);
      revert("user disabled");
    }

    // 4) Check if request id is existed
    //    if existed, emit event AddApprovalKeyRequest("Request", "The request add key id is already existed!", false)
    if (StorageStruct(_keysStorageAddress).getAddApprovalRequest(requestId).status != StorageStruct.RequestStatus.Nonexistant) {
      emit AddApprovalKeyRequest("Request", "duplicate key add request", false);
      revert("already exists");
    }

    // 5) Add new AddApprovalRequest for request_id, added_keys, calculate expire_at_block by latest_block_time & expire_approval_key_request_in, set is_passed as false, set status as Processing
    StorageStruct(_keysStorageAddress).setApprovalRequestByIdKeys(requestId, userId, key);

    // 6) emit event AddApprovalKeyRequest("Request", "The request is added successfully!", true)
    emit AddApprovalKeyRequest("Add", "The request is added successfully!", true);
  }

  function verifyApprovalKeyRequest(
    SigUtil.BaseSignature[5] calldata approvalSignatures,
    SigUtil.BaseSignature calldata adminSignature
  ) public {
    // 1) Check global state (should be under ActiveNormal)
    {
      GlobalState.COWSState _cowsState = StorageStruct(_keysStorageAddress).getGlobStateContract().globalState();
      require(_cowsState == GlobalState.COWSState.ActiveNormal, "Global State not active normal");
    }

    // 2) Extract params from message in caller_signature
    string[] memory extractedMessage = SigUtil.extractMessage(adminSignature.message);
    SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(extractedMessage);
    bytes32 requestId = message.requestId;

    // 3) Check if current block number < expireAtBlock;
    //    if not, emit event AddApprovalKeyRequest("Approve", "The request is already expired, please resubmit a new one!", false)
    if (block.timestamp > StorageStruct(_keysStorageAddress).getAddApprovalRequest(requestId).expireAtBlock) {
      emit AddApprovalKeyRequest(
        "Verify",
        "The request has expired, please resubmit a new one!",
        false
      );
      revert("already expired");
    }

    // 4) Check if caller has valid CASTL key
    //    if not, emit event AddApprovalKeyRequest("Approve", "Invalid CASTL key from caller!", false)

    // 6) Update caller_signature to approval_key_requests

    // 5) Call verifySignature() to check if the recovered signer of caller signature match
    //    if not, emit event AddApprovalKeyRequest("Approve", "Invalid CASTL signature from caller!", false)
    {
      address _recoveredSigner = SigUtil.verifySignature(
        adminSignature.signature,
        adminSignature.message
      );

      if (StorageStruct(_keysStorageAddress).getCASTLState(_recoveredSigner) != StorageStruct.CASTLState.Enabled) {
        emit AddApprovalKeyRequest("Approve", "approval called from unknown CASTL address!", false);
        revert("castl key not enabled");
      }

    StorageStruct(_keysStorageAddress).setApprovalRequestBySigs(requestId, SigUtil.VerifiedSignature(adminSignature, _recoveredSigner, true));
    }

    // 7) Loop starts:
    //      Extract params from message in one of signed_approvals
    //      Check if is_passed is true or not, return false if approvals are done and emit event AddApprovalKeyRequest("Approve", "The request is already approved!", current_request_id)
    //      Check the existed signatures from approval_key_requests to see if current signature come from different approvers; if not, emit event AddApprovalKeyRequest("Approve", "The request is already approved by same approver!", current_request_id)
    //      Call verifySignature() to check if the recovered signer has valid approval key
    //        If passed, update is_verified of the signature as true to approval_key_requests
    //        If failed, emit event AddApprovalKeyRequest("Approve", "Invalid approval signature!", current_request_id)
    //      Count if the number of verified signatures hits min. threshold (3/5)
    //        If passed, update signed_approvals and is_passed as true and status as Approved to approval_key_requests
    uint256 countOfVerifiedSignatures;
    for (uint256 i; i < 5; ) {
      SigUtil.BaseSignature calldata approvalSignature = approvalSignatures[i];
      string[] memory _extractedMessage = SigUtil.extractMessage(approvalSignature.message);
      SigUtil.ExtractedSigningMessage memory _message = SigUtil.convertToStruct(_extractedMessage);
      bytes32 _userId = _message.userId[0];

      // if user is blocked in any way, skip user
      if (StorageStruct(_keysStorageAddress).getUserKeys(_userId).userBlocks > StorageStruct.UserBlocks.None) continue;

      (bool isVerified, address recoveredApprover) = verifyApprovalSignature(
        _userId,
        approvalSignature
      );

      if (isVerified) {
        StorageStruct(_keysStorageAddress).setApprovalRequestBySigs(requestId, SigUtil.VerifiedSignature(approvalSignature, recoveredApprover, true));
        
        unchecked {
          ++countOfVerifiedSignatures;
        }
      }
      unchecked {
        ++i;
      }
    }
    require(countOfVerifiedSignatures > 2, "Not enough signatures passed"); // Check if number of approval keys is 5 (should have 5 users when init)

    if (StorageStruct(_keysStorageAddress).getAddApprovalRequest(requestId).isPassed) {
      emit AddApprovalKeyRequest("Verify", "The request is already approved!", false);
      revert("already approved");
    }

    StorageStruct(_keysStorageAddress).setApprovalRequestByStatus(requestId);

    // 8) Emit event AddApprovalKeyRequest("Approve", "All passed!", true)
    emit AddApprovalKeyRequest("Approve", "addApprovalKey multisig passed", true);
  }

  function executeApprovalKeyRequest(bytes32 requestId) public {
    // 1) Check global state (should be under ActiveNormal)
    {
      GlobalState.COWSState _cowsState = StorageStruct(_keysStorageAddress).getGlobStateContract().globalState();
      require(_cowsState == GlobalState.COWSState.ActiveNormal, "Global State not active normal");
    }

    StorageStruct.AddApprovalRequest memory _request = StorageStruct(_keysStorageAddress).getAddApprovalRequest(requestId);

    // 2) Check request id existed
    //    if not, emit event AddApprovalKeyRequest("Execute", "Cannot find the request!", false)

    // 3) Check if current block number < expireAtBlock
    //    if not, emit event AddApprovalKeyRequest("Execute", "The request is already expired, please resubmit a new one!", false)

    if (block.timestamp > _request.expireAtBlock) {
      emit AddApprovalKeyRequest(
        "Execute",
        "The request is already expired, please resubmit a new one!",
        false
      );
      revert("already expired");
    }

    // 4) Check if is_passed is true and status is Approved
    //    if not, emit event AddApprovalKeyRequest("Execute", "The request isn't fully approved yet!", false) and return false
    if (!_request.isPassed && _request.status != StorageStruct.RequestStatus.Approved) {
      emit AddApprovalKeyRequest("Execute", "The request isn't fully approved yet!", false);
      revert("not approved");
    }

    // 5) Update new keys in approval_keys
    StorageStruct.Key memory _key = _request.addedApprovalKey;
    StorageStruct(_keysStorageAddress).setUserKeysByApprovalOnly(_request.userId, _key);

    // 6) Update status as Completed
    StorageStruct(_keysStorageAddress).setApprovalRequestComplete(_request.userId);

    // 7) If there's already a key/ keys exists for the device, don't update. It should go through replace key process

    // 8) Emit event AddApprovalKeyRequest("Execute", "Executed add request!", true)
    emit AddApprovalKeyRequest("Execute", "Executed add request!", true);
  }

  //************************************//
  //****** COMBINED ADD APPROVAL  ******//
  //************************************//
  function addApprovalKey(
    bytes32 requestId,
    bytes32 userId,
    StorageStruct.Key calldata key,
    SigUtil.BaseSignature[5] calldata approvalSignatures,
    SigUtil.BaseSignature calldata adminSignature
  ) public {
    addApprovalKeyRequest(requestId, userId, key);

    verifyApprovalKeyRequest(approvalSignatures, adminSignature);

    executeApprovalKeyRequest(requestId);
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Console} from "../../Console.sol";
import {StringUtils} from "../../StringUtils.sol";
import {VerifySignatureUtil as SigUtil} from "../../VerifySignatureUtil.sol";
import {GlobalState} from "../../GlobalState.sol";
import {COWSManagement} from "../../COWSManagement.sol";
import {StorageStruct} from "./StorageStruct.sol";

contract T3SplitKeyManagement {
  using StringUtils for *;
  using SigUtil for SigUtil.VerifiedSignature;

  //***********************//
  //****** VARIABLES ******//
  //***********************//
  address _keysStorageAddress;

  //********************//
  //****** EVENTS ******//
  //********************//

  event Init(string msg, bool isSuccess);
  event AddApprovalKeyRequest(string actionType, string msg, bool isSuccess);
  event AddCASTLKeyRequest(string actionType, string msg, bool isSuccess);
  event ChangeInterventionKeyRequest(string actionType, string msg, bool isSuccess);
  event ReplaceKeyRequest(string actionType, string msg, bool isSuccess);
  event ReplaceCASTLKeyRequest(string actionType, string msg, bool isSuccess);
  event ChangeUserKeysStatusRequest(string actionType, string msg, bool isSuccess);
  event ReplaceUserRequest(string actionType, string msg, bool isSuccess);
  event EmergencyReplaceUserKeysRequest(string actionType, string msg, bool isSuccess);
  event ForceClose(string msg, bool isSuccess);
  event DeployNewKeyStorage(string msg, bool isSuccess);

  //*************************//
  //****** CONSTRUCTOR ******//
  //*************************//

  constructor(
    address keysStorageAddress
  ) {
    _keysStorageAddress = keysStorageAddress;
  }

  //*********************//
  //****** HELPERS ******//
  //*********************//

  function verifySingleSignature(
    address expectedKeyAddress,
    SigUtil.BaseSignature calldata baseSignature
  ) public view returns (bool, address) {
    address _recoveredApprover = SigUtil.verifySignature(
      baseSignature.signature,
      baseSignature.message
    );

    Console.log("expectedKeyAddress: ", expectedKeyAddress);
    Console.log("_recoveredApprover: ", _recoveredApprover);

    bool isVerified;

    if (expectedKeyAddress == _recoveredApprover) {
      isVerified = true;
    }

    return (isVerified, _recoveredApprover);
  }

  //************************************//
  //****** EMERGENCY USER REPLACE ******//
  //************************************//

  function emergencyReplaceUserKeysStart(SigUtil.BaseSignature calldata emergencySignature) public {
    // 1) Extract params from message in signed_emergency_signature
    SigUtil.ExtractedSigningMessage memory message;
    {
      string[] memory _extractedMessage = SigUtil.extractMessage(emergencySignature.message);
      message = SigUtil.convertToStruct(_extractedMessage);
    }

    if (block.timestamp < StorageStruct(_keysStorageAddress).getUserKeys(message.userId[0]).emergencyKeyUnit.delayTo) {
      revert("emergency key in timeout");
    }

    require(
      StorageStruct(_keysStorageAddress).getUserKeys(message.userId[0]).userBlocks != StorageStruct.UserBlocks.All,
      "userBlock for all function calls"
    );

    // Check if requestId already existed
    //    if yes, emit event EmergencyReplaceUserKeysRequest("Request", "The request id is already existed!", false) and return false
    if (StorageStruct(_keysStorageAddress).getEmergencyKeyReplacements(message.requestId).status != StorageStruct.EmergencyRequestStatus.Nonexistant) {
      emit EmergencyReplaceUserKeysRequest("Request", "The request id already exists!", false);
      revert("already exists");
    }

    // Call verifySignature() to check if the recovered signer has valid emergency key
    {
      address _emergencyKey = StorageStruct(_keysStorageAddress).getUserKeys(message.userId[0])
        .emergencyKeyUnit
        .emergencyKey
        .keyAddress;
      (bool isVerified, ) = verifySingleSignature(_emergencyKey, emergencySignature);
      require(isVerified, "invalid emergency signature");
    }

    // Check global state, if it's still Active Normal, update to ActiveEmergency
    {
      GlobalState.COWSState _cowsState = StorageStruct(_keysStorageAddress).getGlobStateContract().globalState();
      if (_cowsState == GlobalState.COWSState.ActiveNormal) {
        StorageStruct(_keysStorageAddress).getGlobStateContract().setGlobalState(GlobalState.COWSState.ActiveEmergency);
        StorageStruct(_keysStorageAddress).getGlobStateContract().setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
        StorageStruct(_keysStorageAddress).setEmergencyKeyReplacementsByDelay(message.requestId, block.timestamp + 1 days);
      } else if (_cowsState == GlobalState.COWSState.ActiveEmergency) {
        if (StorageStruct(_keysStorageAddress).getGlobStateContract().getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
          revert("only 2 requests at a time");
        }
        if (StorageStruct(_keysStorageAddress).getGlobStateContract().getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
          StorageStruct(_keysStorageAddress).getGlobStateContract().setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, true);
          StorageStruct(_keysStorageAddress).getGlobStateContract().setFlaggedState(GlobalState.FlaggedState.Paused, true);
          StorageStruct(_keysStorageAddress).setEmergencyKeyReplacementsByDelay(message.requestId, block.timestamp + 2 days);
        }
      } else {
        revert("state not ActiveNormal/Emergency");
      }
    }

    StorageStruct(_keysStorageAddress).setCurrentReplacingUserRequestId(message.requestId);

    // Set status as Processing
    // Extract and remove all keys assigned to the userId from approvalKeys (old keys)
    // delete complianceUserKeys[userId];
    // Update caller as gasWallet to the emergencyKeyReplacements
    // Add new EmergencyReplacement to emergencyKeyReplacements with requestId, userId, oldKeys, newKeys, isPassed as false
    // _emergencyReplaceRequest.newKeys = newKeys;
    StorageStruct(_keysStorageAddress).setEmergencyKeyReplacements(message.requestId, message.userId[0], message.deviceId[0]);

    {
      bool hasEmergencyKey = false;

      for (uint256 i = 0; i < message.totalKeyNum; ) {
        StringUtils.Slice memory keyType = message.userKeyType[i].toSlice();

        if (keyType.equals("Emergency".toSlice()) && !hasEmergencyKey) {
          StorageStruct(_keysStorageAddress).setEmergencyKeyReplacementsByEmgKeys(message.requestId, message.derivationIndex[i], message.userKeys[i]);
          hasEmergencyKey = true;
        } else {
          StorageStruct(_keysStorageAddress).setEmergencyKeyReplacementsByAprvKeys(message.requestId, message.derivationIndex[i], message.userKeys[i]);
        }
        unchecked {
          ++i;
        }
      }
    }

    // Blocks user from all functionality
    StorageStruct(_keysStorageAddress).getUserKeys(message.userId[0]).userBlocks = StorageStruct.UserBlocks.All;

    // Emit event EmergencyReplaceUserKeysRequest("Start", "Emergency user key replacement starts!", true)
    emit EmergencyReplaceUserKeysRequest("Start", "Emergency user key replacement starts!", true);
  }

  // This function is for canceling emergency replacement by another emergency key or intervention key
  function emergencyReplaceUserKeysIntervene(SigUtil.BaseSignature calldata signedRejectApproval)
    public
    returns (bool)
  {
    bytes32 requestId;
    address rejectorAddress;
    string memory keyType;
    {
      string[] memory _extractedMessage = SigUtil.extractMessage(signedRejectApproval.message);
      SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(_extractedMessage);
      requestId = message.requestId;
      rejectorAddress = message.signerPublicAddress;
      keyType = message.keyType;
    }

    // Check if caller has valid intervention key;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Intervene", "Invalid caller!", false)
    {
      bytes32 inputKeyType = bytes32(abi.encodePacked(keyType));
      bytes32 expectedKeyType = bytes32(abi.encodePacked("Intervention"));
      if (inputKeyType != expectedKeyType) {
        emit EmergencyReplaceUserKeysRequest(
          "Intervene",
          "intervention sig wrong key type!",
          false
        );
        revert("intervention sig wrong key type!");
      }
    }

    // Check if current block number exceeds delayTo block number;
    //   if exceed, emit event EmergencyReplaceUserKeysRequest("Intervene", "The delayed time is over now!", false)
    /* if (block.timestamp > _emergencyReplaceRequest.delayTo) {
      emit EmergencyReplaceUserKeysRequest("Intervene", "The delayed time is over now!", false);
      revert("request is expired");
    } */

    // Call verifySignature() to check if the recovered signer has a valid intervention key;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Intervene", "Invalid signature!", false)
    require(StorageStruct(_keysStorageAddress).isValidInterventionKey(rejectorAddress), "intervention from unknown addr!");
    (bool isVerified, ) = verifySingleSignature(rejectorAddress, signedRejectApproval);
    if (!isVerified) {
      emit EmergencyReplaceUserKeysRequest("Intervene", "bad signature in intervention!", false);
      revert("bad signature in intervention!");
    }

    // Check if the recovered signer is an disabled user;
    //   if yes, emit event EmergencyReplaceUserKeysRequest("Intervene", "The signature signer is an disable user!", false)
    /* if (!complianceUserKeys[_emergencyReplaceRequest.userId].isEnabled) {
      emit EmergencyReplaceUserKeysRequest(
        "Intervene",
        "The signature signer is from a disabled user!",
        false
      );
      revert("user disabled");
    } */

    // Update signature and isVerified into signedToRejectApprovals
    StorageStruct(_keysStorageAddress).setEmergencyKeyReplacementsByRejSig(requestId, rejectorAddress, signedRejectApproval);

    // Accept number of signed reject approvals >= 1
    //   If passed, set isRejected as true
    //   Set isEmergency in approvalKeys back to false (deprecated)
    //   Set isEmergencyReplace2 back to false and
    //     countOfCompletedEmergencyReplacements = 1 in global state contract
    //   Set status as Rejected

    bytes32 userId = StorageStruct(_keysStorageAddress).getEmergencyKeyReplacements(requestId).userId;
    if (StorageStruct(_keysStorageAddress).getGlobStateContract().getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
      StorageStruct(_keysStorageAddress).getGlobStateContract().setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, false);
      StorageStruct(_keysStorageAddress).getGlobStateContract().setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
      StorageStruct(_keysStorageAddress).getGlobStateContract().setFlaggedState(GlobalState.FlaggedState.Paused, false);
      StorageStruct(_keysStorageAddress).setUserKeysByDelay(userId, block.timestamp + 24 hours);
    } else if (StorageStruct(_keysStorageAddress).getGlobStateContract().getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
      StorageStruct(_keysStorageAddress).getGlobStateContract().setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, false);
      StorageStruct(_keysStorageAddress).getGlobStateContract().setGlobalState(GlobalState.COWSState.ActiveNormal);
      StorageStruct(_keysStorageAddress).setUserKeysByDelay(userId, block.timestamp + 12 hours);
    }

    // Emit event EmergencyReplaceUserKeysRequest("Intervene", "The request is intervened successfully!", true)
    emit EmergencyReplaceUserKeysRequest(
      "Intervene",
      "The request is intervened successfully!",
      true
    );
    return true;
  }

  // This function is for executing approved emergency replacement request
  function emergencyReplaceUserKeysExecute(bytes32 requestId) public {
    StorageStruct.EmergencyReplacement memory _emergencyKeyReplacements = StorageStruct(_keysStorageAddress).getEmergencyKeyReplacements(requestId);
    bytes32 parsedUserId = _emergencyKeyReplacements.userId;

    // Check if the request is already rejected by approvers;
    //   if yes, emit event EmergencyReplaceUserKeysRequest("Execute", "This request is rejected via intervention process!", false)
    if (_emergencyKeyReplacements.isRejected) {
      emit EmergencyReplaceUserKeysRequest(
        "Execute",
        "This request is rejected via intervention process!",
        false
      );
      revert("already rejected");
    }

    // Check if current block number exceeds delayTo block number;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Execute", "Execution should wait until the delayed time end!", false)
    if (block.timestamp < _emergencyKeyReplacements.delayTo) {
      emit EmergencyReplaceUserKeysRequest(
        "Execute",
        "Execution should wait until the delayed time end!",
        false
      );
      revert("not delayed long enough");
    }

    // If all passed,
    //   Update new key in approvalKeys
    {
      StorageStruct.UserKeys memory freshUserKeys = _emergencyKeyReplacements.newKeys;
      StorageStruct(_keysStorageAddress).setUserKeysByEmgOnly(parsedUserId, freshUserKeys.approvalKeyUnit.uniqueDeviceId, freshUserKeys.emergencyKeyUnit);

      StorageStruct(_keysStorageAddress).deleteUserKeys(parsedUserId);

      uint256 approvalKeyCount = freshUserKeys.approvalKeyUnit.approvalKeys.length;
      for (uint256 i; i < approvalKeyCount; ) {
        StorageStruct(_keysStorageAddress).setUserKeysByApprovalOnly(parsedUserId, freshUserKeys.approvalKeyUnit.approvalKeys[i]);
        unchecked {
          ++i;
        }
      }

      StorageStruct(_keysStorageAddress).setUserKeysByUserBlockOnly(parsedUserId, StorageStruct.UserBlocks.None);
    }

    //   Set both isEmergencyReplace1 & isEmergencyReplace2 back as false in global state contract

    if (StorageStruct(_keysStorageAddress).getGlobStateContract().getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
      StorageStruct(_keysStorageAddress).getGlobStateContract().setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, false);
      StorageStruct(_keysStorageAddress).getGlobStateContract().setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
      StorageStruct(_keysStorageAddress).getGlobStateContract().setFlaggedState(GlobalState.FlaggedState.Paused, false);
    } else if (StorageStruct(_keysStorageAddress).getGlobStateContract().getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
      StorageStruct(_keysStorageAddress).getGlobStateContract().setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, false);
      StorageStruct(_keysStorageAddress).getGlobStateContract().setGlobalState(GlobalState.COWSState.ActiveNormal);
    }

    //   Set status as Executed
    StorageStruct(_keysStorageAddress).setEmergencyKeyReplacementsComplete(requestId);

    //   Emit event EmergencyReplaceUserKeysRequest("Execute", "Execute emergency user keys replacement successfully!", true)
    emit EmergencyReplaceUserKeysRequest(
      "Execute",
      "Execute emergency user keys replacement successfully!",
      true
    );
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {VerifySignatureUtil as SigUtil} from "./VerifySignatureUtil.sol";
import {VerifyUtil} from "./VerifyUtil.sol";
import {KeyManagement} from "./KeyManagement.sol";
import {COWSManagement} from "./COWSManagement.sol";

contract GlobalState {
  using SigUtil for SigUtil.VerifiedSignature;

  enum COWSState {
    Deployed,
    Recognized,
    ActiveNormal,
    ActiveEmergency,
    Decommissioned
  }

  enum FlaggedState {
    Paused,
    EmergencyReplace1,
    EmergencyReplace2
  }

  struct SetActiveNormalRec {
    bool isPassed;
    SigUtil.VerifiedSignature[5] approvalSignatures;
    SigUtil.VerifiedSignature adminSignature;
  }

  address public constant BOATS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
  COWSManagement public cowsManagement;
  COWSState public globalState;
  bool public isPaused;
  bool public isEmergencyReplace1;
  bool public isEmergencyReplace2;
  bytes32 public cowId;
  mapping(bytes32 => SetActiveNormalRec) public setActiveNormalRecords;

  event SetModeActiveNormal(string msg, bool success);

  constructor(COWSState _globalState, address _cowsManagement) {
    globalState = _globalState;
    cowsManagement = COWSManagement(_cowsManagement);
  }

  /***************************/
  /*         GETTERS         */
  /***************************/

  function getGlobalState() public view returns (COWSState) {
    return globalState;
  }

  function getFlaggedState(FlaggedState flaggedState) public view returns (bool isFlagged) {
    if (flaggedState == FlaggedState.Paused) return isPaused;

    if (flaggedState == FlaggedState.EmergencyReplace1) return isEmergencyReplace1;

    if (flaggedState == FlaggedState.EmergencyReplace2) return isEmergencyReplace2;
  }

  function getActiveNormalRecords(bytes32 requestId)
    public
    view
    returns (SetActiveNormalRec memory record)
  {
    return setActiveNormalRecords[requestId];
  }

  /***************************/
  /*         SETTERS         */
  /***************************/

  function setGlobalState(COWSState state) public returns (bool) {
    /// TODO Check if caller has a valid CASTL key or registered contracts in current COWS
    globalState = state; // Update globalState
    return true;
  }

  function setFlaggedState(FlaggedState flaggedState, bool value)
    public
    returns (bool isFlaggedStateSet)
  {
    if (flaggedState == FlaggedState.Paused) {
      isPaused = value;
      return value;
    }

    if (flaggedState == FlaggedState.EmergencyReplace1) {
      isEmergencyReplace1 = value;
      return value;
    }

    if (flaggedState == FlaggedState.EmergencyReplace2) {
      isEmergencyReplace2 = value;
      return value;
    }
  }

  // This function is for setting back global state as ActiveNormal after confirmed new keys from emergency replacement by CASTL
  function setModeActiveNormal(
    SigUtil.BaseSignature[5] calldata approvalSignatures,
    SigUtil.BaseSignature calldata castlSignature
  ) public {
    // Check if global state is at ActiveEmergency
    require(globalState == COWSState.ActiveEmergency, "not in active emergency");

    // Extract params from message in callerSignature
    bytes32 cowsId;
    bytes32 requestId;
    address inMsgPubAddr;
    {
      string[] memory _extractedMessage = SigUtil.extractMessage(castlSignature.message);
      SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(_extractedMessage);
      requestId = message.requestId;
      inMsgPubAddr = message.signerPublicAddress;
      cowsId = message.cowId;
    }

    KeyManagement keyManagement;
    {
      string memory keyManagementString = "KeyManagement";
      address keyManagementAddress = cowsManagement.returnContractAddress(
        cowsId,
        keyManagementString
      );
      keyManagement = KeyManagement(keyManagementAddress);
    }

    // Check if caller has valid CASTL key;
    //   if not, emit event SetModeActiveNormal("Invalid CASTL key from caller!", false)
    {
      KeyManagement.CASTLState castlState = keyManagement.castlKeys(inMsgPubAddr);
      if (castlState != KeyManagement.CASTLState.Enabled) {
        emit SetModeActiveNormal("Invalid CASTL key from caller!", false);
        revert("invalid castl key");
      }
    }

    // Call verifySignature() to check if the recovered signer of caller signature match;
    //   if not, emit event SetModeActiveNormal("Invalid CASTL signature from caller!", false)
    {
      (bool isVerified, ) = VerifyUtil.verifySingleSignature(inMsgPubAddr, castlSignature);
      if (!isVerified) {
        emit SetModeActiveNormal("Invalid CASTL signature from caller!", false);
        revert("invalid castl signature");
      }
    }

    SetActiveNormalRec storage _setActiveNormalRec = setActiveNormalRecords[requestId];
    {
      _setActiveNormalRec.adminSignature = SigUtil.VerifiedSignature({
        recoveredSigner: inMsgPubAddr,
        isVerified: true,
        signature: castlSignature
      });
    }

    // Loop starts (approvals)
    //   Extract params from message in one of signedApprovals
    //   Check the existed signatures from setActiveNormalRecords to see if current signature come from different approvers;
    //     if not, emit event SetModeActiveNormal("Signatures contain same approver!", false)
    //   Call verifySignature() to check if the recovered signer has valid approval key
    //     If passed, update isVerified of the signature as true to setActiveNormalRecords
    //     If failed, emit event SetModeActiveNormal("Invalid CASTL signature!", false)
    bytes32[5] memory approvalUserIds;

    for (uint256 i; i < 5; ) {
      SigUtil.BaseSignature memory approvalBaseSig = approvalSignatures[i];
      {
        string[] memory _extractedMessage = SigUtil.extractMessage(approvalBaseSig.message);
        SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(_extractedMessage);
        approvalUserIds[i] = message.userId[0];
      }

      (bool _isVerified, address _recoveredApproval) = keyManagement.verifyApprovalSignature(
        approvalUserIds[i],
        approvalBaseSig
      );
      if (!_isVerified) {
        emit SetModeActiveNormal("approvalSig not from valid approval key!", false);
        revert("invalid approver signature");
      }

      _setActiveNormalRec.approvalSignatures[i] = SigUtil.VerifiedSignature({
        recoveredSigner: _recoveredApproval,
        isVerified: true,
        signature: approvalBaseSig
      });

      unchecked {
        ++i;
      }
    }

    bool hasDuplicates = VerifyUtil.isDuplicateKey(approvalUserIds, 5);
    if (hasDuplicates) {
      emit SetModeActiveNormal("Signatures contain same approver!", false);
      revert("duplicate in approvalSignatures");
    }

    // Emit event SetModeActiveNormal("All passed!", true)
    emit SetModeActiveNormal("All passed!", true);
    _setActiveNormalRec.isPassed = true;

    isEmergencyReplace1 = false;
    isEmergencyReplace2 = false;
    globalState = COWSState.ActiveNormal;
    isPaused = false;

    keyManagement.setUserBlock(requestId, KeyManagement.UserBlocks.None);
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

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

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./IERC20.sol";

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

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Console} from "./Console.sol";
import {StringUtils} from "./StringUtils.sol";
import {VerifySignatureUtil as SigUtil} from "./VerifySignatureUtil.sol";
import {GlobalState} from "./GlobalState.sol";
import {COWSManagement} from "./COWSManagement.sol";

contract KeyManagement {
  using StringUtils for *;
  using SigUtil for SigUtil.VerifiedSignature;

  //*******************//
  //****** ENUMS ******//
  //*******************//

  enum KeyType {
    Approval,
    CASTL,
    Emergency,
    Intervention
  }

  enum CASTLState {
    Nonexistant,
    Enabled,
    Expired
  }

  enum CASTLRequestAction {
    Add,
    Expire
  }

  enum InterventionRequestAction {
    Add,
    Remove
  }

  enum ControlAction {
    Enable,
    Disable
  }

  enum UserBlocks {
    None,
    Approval,
    All
  }

  enum CloseType {
    AddApprovalKeyRequest,
    AddCASTLKeyRequest,
    ChangeInterventionKeyRequest,
    ReplaceKeyRequest,
    ReplaceCASTLKeyRequest,
    ChangeUserKeysStatusRequest,
    ReplaceUserRequest
  }

  enum RequestStatus {
    Nonexistant,
    Pending,
    Processing,
    Approved,
    Completed,
    ForceClosed
  }

  enum EmergencyRequestStatus {
    Nonexistant,
    Started,
    Executed,
    Rejected
  }

  //*********************//
  //****** STRUCTS ******//
  //*********************//

  struct Key {
    KeyType keyType;
    int32 derivationIndex;
    address keyAddress;
  }

  struct ApprovalKeyUnit {
    bytes32 uniqueDeviceId;
    Key[] approvalKeys;
  }

  struct EmergencyKeyUnit {
    uint256 delayTo;
    Key emergencyKey;
  }

  struct UserKeys {
    bool doesExist;
    bool isEnabled;
    UserBlocks userBlocks;
    EmergencyKeyUnit emergencyKeyUnit;
    ApprovalKeyUnit approvalKeyUnit;
  }

  struct SignatureBlock {
    bytes32 userId;
    SigUtil.BaseSignature baseSignature;
  }

  struct AddApprovalRequest {
    bytes32 userId;
    Key addedApprovalKey;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct AddCASTLRequest {
    address addedKey;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct AddInterventionRequest {
    InterventionRequestAction requestType;
    address key;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct ControlUserRequest {
    ControlAction actionType;
    KeyType signerKeyType;
    bytes32 userId;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct ReplacementUnit {
    KeyType keyType;
    address newKey;
    bytes32 deviceId;
    int32 newDerivationIndex;
  }

  struct UserReplacement {
    bytes32 oldUserId;
    bytes32 newUserId;
    ReplacementUnit[] newKeys;
    ReplacementUnit[] oldKeys;
    SigUtil.VerifiedSignature[5] signedApprovals;
    SigUtil.VerifiedSignature callerSignature;
    uint256 expireAtBlock;
    bool isPassed;
    RequestStatus status;
  }

  struct EmergencyReplacement {
    address gasWallet;
    bytes32 userId;
    UserKeys oldKeys;
    UserKeys newKeys;
    SigUtil.VerifiedSignature signedEmergencySignature;
    SigUtil.VerifiedSignature signedRejectionSignature;
    uint256 delayTo;
    bool isRejected;
    EmergencyRequestStatus status;
  }

  struct InitRecord {
    bytes32[5] addedUserIds;
    UserKeys[5] addedUserKeys;
    address[] interventionKeys;
    SigUtil.VerifiedSignature callerSignature;
  }

  //***********************//
  //****** VARIABLES ******//
  //***********************//

  COWSManagement public cowsManagement;
  GlobalState public globalState;

  mapping(bytes32 => UserKeys) public complianceUserKeys;

  mapping(address => bool) public interventionKeys;
  mapping(address => CASTLState) public castlKeys;

  mapping(bytes32 => AddApprovalRequest) public approvalKeyRequests;
  mapping(bytes32 => AddCASTLRequest) public castlKeyRequests;
  mapping(bytes32 => AddInterventionRequest) public interventionKeyRequests;
  mapping(bytes32 => ControlUserRequest) public controlUserKeysRequests;

  mapping(bytes32 => UserReplacement) public userReplacements;
  mapping(bytes32 => EmergencyReplacement) public emergencyKeyReplacements;

  bytes32 public currentDisabledUser;
  bytes32 public currentReplacingUserRequestId;
  bytes32 public currentChangeInterventionKeyRequestId;
  bytes32 public cowId;
  InitRecord public initiator;
  bool public alreadyInitialized;

  //********************//
  //****** EVENTS ******//
  //********************//

  event Init(string msg, bool isSuccess);
  event AddApprovalKey(string actionType, string msg, bool isSuccess);
  event AddCASTLKeyRequest(string actionType, string msg, bool isSuccess);
  event ChangeInterventionKeyRequest(string actionType, string msg, bool isSuccess);
  event ReplaceKeyRequest(string actionType, string msg, bool isSuccess);
  event ReplaceCASTLKeyRequest(string actionType, string msg, bool isSuccess);
  event ChangeUserKeysStatusRequest(string actionType, string msg, bool isSuccess);
  event ReplaceUserRequest(string actionType, string msg, bool isSuccess);
  event EmergencyReplaceUserKeysRequest(string actionType, string msg, bool isSuccess);
  event ForceClose(string msg, bool isSuccess);

  //*************************//
  //****** CONSTRUCTOR ******//
  //*************************//

  constructor(
    address[] memory _castlKeys,
    bytes32 _cowId,
    address _managementAddress,
    address _stateAddress
  ) {
    uint256 _castlKeysCount = _castlKeys.length;
    require(_castlKeysCount > 0, "_castlKeys is empty");

    for (uint256 i; i < _castlKeysCount; ) {
      castlKeys[_castlKeys[i]] = CASTLState.Enabled;
      unchecked {
        ++i;
      }
    }
    cowId = _cowId;
    cowsManagement = COWSManagement(_managementAddress);
    globalState = GlobalState(_stateAddress);
  }

  //*********************//
  //****** HELPERS ******//
  //*********************//

  function verifyCastlSignature(SigUtil.BaseSignature calldata castlSignature)
    public
    view
    returns (bool)
  {
    address _recoveredSigner = SigUtil.verifySignature(
      castlSignature.signature,
      castlSignature.message
    );

    if (castlKeys[_recoveredSigner] != CASTLState.Enabled) {
      return false;
    }
    return true;
  }

  function verifyApprovalSignature(bytes32 userId, SigUtil.BaseSignature calldata baseSignature)
    public
    view
    returns (bool, address)
  {
    Key[] memory _approvalKeys = complianceUserKeys[userId].approvalKeyUnit.approvalKeys;

    address _recoveredApprover = SigUtil.verifySignature(
      baseSignature.signature,
      baseSignature.message
    );
    bool isVerified;
    uint256 _approvalKeyCount = _approvalKeys.length;
    for (uint256 k; k < _approvalKeyCount; ) {
      if (_approvalKeys[k].keyAddress == _recoveredApprover) {
        isVerified = true;
        break;
      }
      unchecked {
        ++k;
      }
    }
    return (isVerified, _recoveredApprover);
  }

  function verifySingleSignature(
    address expectedKeyAddress,
    SigUtil.BaseSignature calldata baseSignature
  ) public view returns (bool, address) {
    address _recoveredApprover = SigUtil.verifySignature(
      baseSignature.signature,
      baseSignature.message
    );

    Console.log("expectedKeyAddress: ", expectedKeyAddress);
    Console.log("_recoveredApprover: ", _recoveredApprover);

    bool isVerified;

    if (expectedKeyAddress == _recoveredApprover) {
      isVerified = true;
    }

    return (isVerified, _recoveredApprover);
  }

  /// @dev may end up refactoring in a different way later
  function setUserBlock(bytes32 requestId, UserBlocks userBlock) external {
    require(msg.sender == address(globalState), "msg sender not global state");
    bytes32 userId = emergencyKeyReplacements[requestId].userId;
    complianceUserKeys[userId].userBlocks = userBlock;
  }

  //*********************//
  //****** GETTERS ******//
  //*********************//

  function getUserKeys(bytes32 userId) public view returns (UserKeys memory keys) {
    return complianceUserKeys[userId];
  }

  function isValidInterventionKey(address interventionKey) public view returns (bool) {
    return interventionKeys[interventionKey];
  }

  function getCASTLState(address castlKey) public view returns (CASTLState state) {
    return castlKeys[castlKey];
  }

  function getAddApprovalRequest(bytes32 requestId)
    public
    view
    returns (AddApprovalRequest memory request)
  {
    return approvalKeyRequests[requestId];
  }

  function getEmergencyKeyReplacements(bytes32 requestId)
    public
    view
    returns (EmergencyReplacement memory request)
  {
    return emergencyKeyReplacements[requestId];
  }

  function getCowId() public view returns (bytes32) {
    return cowId;
  }

  function getInitiator() public view returns (InitRecord memory record) {
    return initiator;
  }

  //******************//
  //****** INIT ******//
  //******************//

  function init(SigUtil.BaseSignature calldata adminSignature) public {
    require(!alreadyInitialized, "already initialized");
    alreadyInitialized = true;
    string memory adminSignedMsg = adminSignature.message;
    address _recoveredSigner = SigUtil.verifySignature(adminSignature.signature, adminSignedMsg);

    if (castlKeys[_recoveredSigner] != CASTLState.Enabled) {
      emit Init("Invalid CASTL signature from caller!", false);
      revert("invalid CASTL signature");
    }

    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      require(_cowsState == GlobalState.COWSState.Recognized, "Global State not recognized");
    }

    {
      bool isEmergency2 = globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2);
      require(!isEmergency2, "GlobalState at emergencyReplace2");
    }

    string[] memory extractedMessage = SigUtil.extractMessage(adminSignedMsg);
    SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(extractedMessage);

    uint256 interventionKeyCount = message.totalInventionKeyNum;
    require(
      interventionKeyCount > 0 && interventionKeyCount < 6,
      "invalid num of intervention keys"
    );
    for (uint256 i; i < interventionKeyCount; ) {
      address interventionKey = message.interventionKeys[i];
      if (interventionKey == address(0)) {
        emit Init("Invalid interventionKey address!", false);
        revert("interventionKey is zero address");
      }
      interventionKeys[interventionKey] = true;
      unchecked {
        ++i;
      }
    }

    InitRecord storage _init = initiator;

    {
      bytes32[5] memory _userIds;
      _userIds[0] = message.userId[0];
      _userIds[1] = message.userId[2];
      _userIds[2] = message.userId[4];
      _userIds[3] = message.userId[6];
      _userIds[4] = message.userId[8];
      _init.addedUserIds = _userIds;
    }

    _init.interventionKeys = message.interventionKeys;

    {
      SigUtil.VerifiedSignature storage _verifiedSig = _init.callerSignature;
      _verifiedSig.signature = adminSignature;
      _verifiedSig.recoveredSigner = _recoveredSigner;
      _verifiedSig.isVerified = true;
    }

    for (uint256 i; i < 5; ) {
      uint256 approvalIndex = i * 2;
      uint256 emergencyIndex = approvalIndex + 1;

      bytes32 userId = message.userId[approvalIndex];

      EmergencyKeyUnit memory defaultEmergencyKeyUnit = EmergencyKeyUnit({
        delayTo: 0, // no delay for init EmergencyKeys
        emergencyKey: Key({
          keyType: KeyType.Emergency,
          derivationIndex: message.derivationIndex[emergencyIndex],
          keyAddress: message.userKeys[emergencyIndex]
        })
      });

      // Set input keys info to complianceUserKeys
      {
        UserKeys storage _userKeys = complianceUserKeys[userId];
        _userKeys.doesExist = true;
        _userKeys.isEnabled = true;
        _userKeys.emergencyKeyUnit = defaultEmergencyKeyUnit;
        _userKeys.approvalKeyUnit.uniqueDeviceId = message.deviceId[approvalIndex];
        _userKeys.approvalKeyUnit.approvalKeys.push(
          Key({
            keyType: KeyType.Approval,
            derivationIndex: message.derivationIndex[approvalIndex],
            keyAddress: message.userKeys[approvalIndex]
          })
        );
      }

      // Set input keys info to initiator
      {
        UserKeys storage _addedKey = _init.addedUserKeys[i];
        _addedKey.doesExist = true;
        _addedKey.isEnabled = true;
        _addedKey.emergencyKeyUnit = defaultEmergencyKeyUnit;
        _addedKey.approvalKeyUnit.uniqueDeviceId = message.deviceId[approvalIndex];
        _addedKey.approvalKeyUnit.approvalKeys.push(
          Key({
            keyType: KeyType.Approval,
            derivationIndex: message.derivationIndex[approvalIndex],
            keyAddress: message.userKeys[approvalIndex]
          })
        );
      }
      unchecked {
        ++i;
      }
    }

    globalState.setGlobalState(GlobalState.COWSState.ActiveNormal);

    /* Testing only */
    UserKeys storage _disabledUserKeys = complianceUserKeys[keccak256(bytes("testUserId"))];
    _disabledUserKeys.doesExist = true;
    _disabledUserKeys.isEnabled = false;
    _disabledUserKeys.approvalKeyUnit.uniqueDeviceId = keccak256(bytes("testDeviceId"));
    Key[] storage k = _disabledUserKeys.approvalKeyUnit.approvalKeys;
    k.push(
      Key({
        derivationIndex: 0,
        keyAddress: 0x927D0903b604d9f01eEB3be8eC65D93D9Cbf2Ec1,
        keyType: KeyType.Approval
      })
    );
    // _disabledUserKeys.approvalKeyUnit.approvalKeys[0].derivationIndex = 0;
    // _disabledUserKeys.approvalKeyUnit.approvalKeys[0].keyAddress = 0x927D0903b604d9f01eEB3be8eC65D93D9Cbf2Ec1;
    // _disabledUserKeys.approvalKeyUnit.approvalKeys[0].keyType = KeyType.Approval;
  }

  //**********************************//
  //******** ADD APPROVAL KEY ********//
  //**********************************//

  function addApprovalKey(
    bytes32 userId,
    Key calldata key,
    SigUtil.BaseSignature[5] calldata approvalSignatures,
    SigUtil.BaseSignature calldata adminSignature
  ) external {
    // Check global state (should be under ActiveNormal)
    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      require(_cowsState == GlobalState.COWSState.ActiveNormal, "Global State not active normal");
    }

    require(key.keyType == KeyType.Approval, "Must be an Approval Key");

    // Check if userId in each key exists && Check if the number of new users + the number of existed users <= 5 (max. should be 5, use replace user if more than 5)
    Key[] memory currentUserKeys = complianceUserKeys[userId].approvalKeyUnit.approvalKeys;
    uint256 currentKeyCount = currentUserKeys.length;
    for (uint256 i; i < currentKeyCount; ) {
      require(currentUserKeys[i].keyAddress != key.keyAddress, "Key already in use!");
      unchecked {
        ++i;
      }
    }

    require(complianceUserKeys[userId].userBlocks == UserBlocks.None, "userBlock not None");
    if (!complianceUserKeys[userId].isEnabled) {
      emit AddApprovalKey("Add", "The user is not enabled!", false);
      revert("user disabled");
    }

    //Check if caller has valid CASTL key
    address _recoveredSigner = SigUtil.verifySignature(
      adminSignature.signature,
      adminSignature.message
    );

    if (castlKeys[_recoveredSigner] != CASTLState.Enabled) {
      emit AddApprovalKey("Add", "Approval called from unknown CASTL address!", false);
      revert("castl key not enabled");
    }

    {
      // Extract params from message in adminSignature
      string[] memory extractedMessage = SigUtil.extractMessage(adminSignature.message);
      SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(extractedMessage);
    }

    //  Extract params from message in one of signed_approvals
    //  Check if is_passed is true or not, return false if approvals are done and emit event AddApprovalKeyRequest("Approve", "The request is already approved!", current_request_id)
    //  Check the existed signatures from approval_key_requests to see if current signature come from different approvers; if not, emit event AddApprovalKeyRequest("Approve", "The request is already approved by same approver!", current_request_id)
    //  Call verifySignature() to check if the recovered signer has valid approval key
    //    If passed, update is_verified of the signature as true to approval_key_requests
    //    If failed, emit event AddApprovalKeyRequest("Approve", "Invalid approval signature!", current_request_id)
    //  Count if the number of verified signatures hits min. threshold (3/5)
    //    If passed, update signed_approvals and is_passed as true and status as Approved to approval_key_requests
    uint256 countOfVerifiedSignatures;
    for (uint256 i; i < 5; ) {
      string[] memory _extractedMessage = SigUtil.extractMessage(approvalSignatures[i].message);
      SigUtil.ExtractedSigningMessage memory _message = SigUtil.convertToStruct(_extractedMessage);
      bytes32 _userId = _message.userId[0];

      // if user is blocked in any way, skip user
      if (complianceUserKeys[_userId].userBlocks > UserBlocks.None) continue;

      (bool isVerified, ) = verifyApprovalSignature(_userId, approvalSignatures[i]);

      if (isVerified) {
        unchecked {
          ++countOfVerifiedSignatures;
        }
      }
      unchecked {
        ++i;
      }
    }
    require(countOfVerifiedSignatures > 2, "Not enough signatures passed"); // Check if number of approval keys is 5 (should have 5 users when init)

    complianceUserKeys[userId].approvalKeyUnit.approvalKeys.push(key);

    emit AddApprovalKey("Add", "Approval key added!", true);
  }

  //************************************//
  //****** EMERGENCY USER REPLACE ******//
  //************************************//

  function emergencyReplaceUserKeysStart(SigUtil.BaseSignature calldata emergencySignature) public {
    // 1) Extract params from message in signed_emergency_signature
    SigUtil.ExtractedSigningMessage memory message;
    {
      string[] memory _extractedMessage = SigUtil.extractMessage(emergencySignature.message);
      message = SigUtil.convertToStruct(_extractedMessage);
    }

    if (block.timestamp < complianceUserKeys[message.userId[0]].emergencyKeyUnit.delayTo) {
      revert("emergency key in timeout");
    }

    require(
      complianceUserKeys[message.userId[0]].userBlocks != UserBlocks.All,
      "userBlock for all function calls"
    );

    // Check if requestId already existed
    //    if yes, emit event EmergencyReplaceUserKeysRequest("Request", "The request id is already existed!", false) and return false
    if (emergencyKeyReplacements[message.requestId].status != EmergencyRequestStatus.Nonexistant) {
      emit EmergencyReplaceUserKeysRequest("Request", "The request id already exists!", false);
      revert("already exists");
    }

    EmergencyReplacement storage _emergencyReplaceRequest = emergencyKeyReplacements[
      message.requestId
    ];

    // Call verifySignature() to check if the recovered signer has valid emergency key
    {
      address _emergencyKey = complianceUserKeys[message.userId[0]]
        .emergencyKeyUnit
        .emergencyKey
        .keyAddress;
      (bool isVerified, ) = verifySingleSignature(_emergencyKey, emergencySignature);
      require(isVerified, "invalid emergency signature");
    }

    // Check global state, if it's still Active Normal, update to ActiveEmergency
    {
      GlobalState.COWSState _cowsState = globalState.globalState();
      if (_cowsState == GlobalState.COWSState.ActiveNormal) {
        globalState.setGlobalState(GlobalState.COWSState.ActiveEmergency);
        globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
        _emergencyReplaceRequest.delayTo = block.timestamp + 1 days;
      } else if (_cowsState == GlobalState.COWSState.ActiveEmergency) {
        if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
          revert("only 2 requests at a time");
        }
        if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
          globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, true);
          globalState.setFlaggedState(GlobalState.FlaggedState.Paused, true);
          _emergencyReplaceRequest.delayTo = block.timestamp + 2 days;
        }
      } else {
        revert("state not ActiveNormal/Emergency");
      }
    }

    currentReplacingUserRequestId = message.requestId;

    // Set status as Processing
    _emergencyReplaceRequest.status = EmergencyRequestStatus.Started;

    // Extract and remove all keys assigned to the userId from approvalKeys (old keys)
    _emergencyReplaceRequest.oldKeys = complianceUserKeys[message.userId[0]];
    // delete complianceUserKeys[userId];

    // Update caller as gasWallet to the emergencyKeyReplacements
    _emergencyReplaceRequest.gasWallet = msg.sender;

    // Add new EmergencyReplacement to emergencyKeyReplacements with requestId, userId, oldKeys, newKeys, isPassed as false
    _emergencyReplaceRequest.userId = message.userId[0];
    // _emergencyReplaceRequest.newKeys = newKeys;
    {
      bool hasEmergencyKey = false;
      _emergencyReplaceRequest.newKeys.doesExist = true;
      _emergencyReplaceRequest.newKeys.isEnabled = true;
      _emergencyReplaceRequest.newKeys.approvalKeyUnit.uniqueDeviceId = message.deviceId[0];

      for (uint256 i = 0; i < message.totalKeyNum; ) {
        StringUtils.Slice memory keyType = message.userKeyType[i].toSlice();

        if (keyType.equals("Emergency".toSlice()) && !hasEmergencyKey) {
          _emergencyReplaceRequest.newKeys.emergencyKeyUnit = EmergencyKeyUnit({
            delayTo: 0,
            emergencyKey: Key({
              keyType: KeyType.Emergency,
              derivationIndex: message.derivationIndex[i],
              keyAddress: message.userKeys[i]
            })
          });

          hasEmergencyKey = true;
        } else {
          _emergencyReplaceRequest.newKeys.approvalKeyUnit.approvalKeys.push(
            Key({
              keyType: KeyType.Approval,
              derivationIndex: message.derivationIndex[i],
              keyAddress: message.userKeys[i]
            })
          );
        }
        unchecked {
          ++i;
        }
      }
    }

    // Blocks user from all functionality
    complianceUserKeys[message.userId[0]].userBlocks = UserBlocks.All;

    // Emit event EmergencyReplaceUserKeysRequest("Start", "Emergency user key replacement starts!", true)
    emit EmergencyReplaceUserKeysRequest("Start", "Emergency user key replacement starts!", true);
  }

  // This function is for canceling emergency replacement by another emergency key or intervention key
  function emergencyReplaceUserKeysIntervene(SigUtil.BaseSignature calldata signedRejectApproval)
    public
    returns (bool)
  {
    bytes32 requestId;
    address rejectorAddress;
    string memory keyType;
    {
      string[] memory _extractedMessage = SigUtil.extractMessage(signedRejectApproval.message);
      SigUtil.ExtractedSigningMessage memory message = SigUtil.convertToStruct(_extractedMessage);
      requestId = message.requestId;
      rejectorAddress = message.signerPublicAddress;
      keyType = message.keyType;
    }

    // Check if caller has valid intervention key;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Intervene", "Invalid caller!", false)
    {
      bytes32 inputKeyType = bytes32(abi.encodePacked(keyType));
      bytes32 expectedKeyType = bytes32(abi.encodePacked("Intervention"));
      if (inputKeyType != expectedKeyType) {
        emit EmergencyReplaceUserKeysRequest(
          "Intervene",
          "intervention sig wrong key type!",
          false
        );
        revert("intervention sig wrong key type!");
      }
    }

    EmergencyReplacement storage _emergencyReplaceRequest = emergencyKeyReplacements[requestId];

    // Check if current block number exceeds delayTo block number;
    //   if exceed, emit event EmergencyReplaceUserKeysRequest("Intervene", "The delayed time is over now!", false)
    /* if (block.timestamp > _emergencyReplaceRequest.delayTo) {
      emit EmergencyReplaceUserKeysRequest("Intervene", "The delayed time is over now!", false);
      revert("request is expired");
    } */

    // Call verifySignature() to check if the recovered signer has a valid intervention key;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Intervene", "Invalid signature!", false)
    require(interventionKeys[rejectorAddress], "intervention from unknown addr!");
    (bool isVerified, ) = verifySingleSignature(rejectorAddress, signedRejectApproval);
    if (!isVerified) {
      emit EmergencyReplaceUserKeysRequest("Intervene", "bad signature in intervention!", false);
      revert("bad signature in intervention!");
    }

    // Check if the recovered signer is an disabled user;
    //   if yes, emit event EmergencyReplaceUserKeysRequest("Intervene", "The signature signer is an disable user!", false)
    /* if (!complianceUserKeys[_emergencyReplaceRequest.userId].isEnabled) {
      emit EmergencyReplaceUserKeysRequest(
        "Intervene",
        "The signature signer is from a disabled user!",
        false
      );
      revert("user disabled");
    } */

    // Update signature and isVerified into signedToRejectApprovals
    _emergencyReplaceRequest.signedRejectionSignature = SigUtil.VerifiedSignature({
      recoveredSigner: rejectorAddress,
      isVerified: true,
      signature: signedRejectApproval
    });

    // Accept number of signed reject approvals >= 1
    //   If passed, set isRejected as true
    //   Set isEmergency in approvalKeys back to false (deprecated)
    //   Set isEmergencyReplace2 back to false and
    //     countOfCompletedEmergencyReplacements = 1 in global state contract
    //   Set status as Rejected
    _emergencyReplaceRequest.isRejected = true;
    _emergencyReplaceRequest.status = EmergencyRequestStatus.Rejected;

    bytes32 userId = _emergencyReplaceRequest.userId;
    if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, false);
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
      globalState.setFlaggedState(GlobalState.FlaggedState.Paused, false);
      complianceUserKeys[userId].emergencyKeyUnit.delayTo = block.timestamp + 24 hours;
      complianceUserKeys[userId].userBlocks = UserBlocks.None;
    } else if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, false);
      globalState.setGlobalState(GlobalState.COWSState.ActiveNormal);
      complianceUserKeys[userId].emergencyKeyUnit.delayTo = block.timestamp + 12 hours;
      complianceUserKeys[userId].userBlocks = UserBlocks.None;
    }

    // Emit event EmergencyReplaceUserKeysRequest("Intervene", "The request is intervened successfully!", true)
    emit EmergencyReplaceUserKeysRequest(
      "Intervene",
      "The request is intervened successfully!",
      true
    );
    return true;
  }

  // This function is for executing approved emergency replacement request
  function emergencyReplaceUserKeysExecute(bytes32 requestId) public {
    EmergencyReplacement memory _emergencyKeyReplacements = emergencyKeyReplacements[requestId];
    bytes32 parsedUserId = _emergencyKeyReplacements.userId;

    // Check if the request is already rejected by approvers;
    //   if yes, emit event EmergencyReplaceUserKeysRequest("Execute", "This request is rejected via intervention process!", false)
    if (_emergencyKeyReplacements.isRejected) {
      emit EmergencyReplaceUserKeysRequest(
        "Execute",
        "This request is rejected via intervention process!",
        false
      );
      revert("already rejected");
    }

    // Check if current block number exceeds delayTo block number;
    //   if not, emit event EmergencyReplaceUserKeysRequest("Execute", "Execution should wait until the delayed time end!", false)
    if (block.timestamp < _emergencyKeyReplacements.delayTo) {
      emit EmergencyReplaceUserKeysRequest(
        "Execute",
        "Execution should wait until the delayed time end!",
        false
      );
      revert("not delayed long enough");
    }

    // If all passed,
    //   Update new key in approvalKeys
    {
      UserKeys storage existingUserKeys = complianceUserKeys[parsedUserId];
      UserKeys memory freshUserKeys = _emergencyKeyReplacements.newKeys;

      existingUserKeys.doesExist = true;
      existingUserKeys.isEnabled = true;
      existingUserKeys.emergencyKeyUnit = freshUserKeys.emergencyKeyUnit;
      existingUserKeys.approvalKeyUnit.uniqueDeviceId = freshUserKeys
        .approvalKeyUnit
        .uniqueDeviceId;

      delete existingUserKeys.approvalKeyUnit.approvalKeys;

      uint256 approvalKeyCount = freshUserKeys.approvalKeyUnit.approvalKeys.length;
      for (uint256 i; i < approvalKeyCount; ) {
        existingUserKeys.approvalKeyUnit.approvalKeys.push(
          freshUserKeys.approvalKeyUnit.approvalKeys[i]
        );
        unchecked {
          ++i;
        }
      }

      complianceUserKeys[parsedUserId].userBlocks = UserBlocks.None;
    }

    //   Set both isEmergencyReplace1 & isEmergencyReplace2 back as false in global state contract

    if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace2)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace2, false);
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, true);
      globalState.setFlaggedState(GlobalState.FlaggedState.Paused, false);
    } else if (globalState.getFlaggedState(GlobalState.FlaggedState.EmergencyReplace1)) {
      globalState.setFlaggedState(GlobalState.FlaggedState.EmergencyReplace1, false);
      globalState.setGlobalState(GlobalState.COWSState.ActiveNormal);
    }

    //   Set status as Executed
    emergencyKeyReplacements[requestId].status = EmergencyRequestStatus.Executed;

    //   Emit event EmergencyReplaceUserKeysRequest("Execute", "Execute emergency user keys replacement successfully!", true)
    emit EmergencyReplaceUserKeysRequest(
      "Execute",
      "Execute emergency user keys replacement successfully!",
      true
    );
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title ERC20Mock
/// @notice This mock just provides public mint and burn functions for testing purposes
contract ERC20Mock is ERC20 {
  constructor(string memory name, string memory ticker) ERC20(name, ticker) {}

  function mintToSender(uint256 amount) public {
    _mint(msg.sender, amount);
  }

  function mint(address to, uint256 amount) public {
    _mint(to, amount);
  }

  function burn(address to, uint256 amount) public {
    _burn(to, amount);
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract MyToken is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals,
    uint256 initialSupply
  ) ERC20(name, symbol, decimals) {
    _mint(msg.sender, initialSupply);
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "lib/solmate/src/tokens/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

error MintPriceNotPaid();
error MaxSupply();
error NonExistentTokenURI();
error WithdrawTransfer();

contract NFT is ERC721, Ownable {
  using Strings for uint256;
  string public baseURI;
  uint256 public currentTokenId;
  uint256 public constant TOTAL_SUPPLY = 10_000;
  uint256 public constant MINT_PRICE = 0.08 ether;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseURI
  ) ERC721(_name, _symbol) {
    baseURI = _baseURI;
  }

  function mintTo(address recipient) public payable returns (uint256) {
    if (msg.value != MINT_PRICE) {
      revert MintPriceNotPaid();
    }
    uint256 newTokenId = ++currentTokenId;
    if (newTokenId > TOTAL_SUPPLY) {
      revert MaxSupply();
    }
    _safeMint(recipient, newTokenId);
    return newTokenId;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (ownerOf(tokenId) == address(0)) {
      revert NonExistentTokenURI();
    }
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
  }

  function withdrawPayments(address payable payee) external onlyOwner {
    uint256 balance = address(this).balance;
    (bool transferTx, ) = payee.call{value: balance}("");
    if (!transferTx) {
      revert WithdrawTransfer();
    }
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @author prometheumlabs/blockchain-team
 * @title Sample alpha build of COWS known as <Registry>
 * @dev  The initial prototype of the Container Manager now only used by POKET for demonstrative purposes
 * @notice <Registry> interacts with POKET to show key replacements
 */
contract Registry {
  struct Asset {
    string name;
    address contractAddr;
  }
  enum AccountType {
    Omnibus,
    Suspense
  }
  enum State {
    Normal,
    Emergency
  }
  mapping(string => Asset) public dasDetails;
  struct ContainerInfo {
    string chain; // the container contracts are based on which chain
    bool activeStatus; // is container active or not, set as true if active
    AccountType accountType;
    string[] dasList;
    State currentState;
    uint256 emergencyDeclaredHeight;
  }
  mapping(uint256 => ContainerInfo) public containers;
  bytes32[] private signerList;
  struct Key {
    address approvalKey;
    uint256 approvalKeyLastUpdated;
    address emergencyKey;
    uint256 emergencyKeyLastUpdated;
  }
  address[] private containerAddrs;
  mapping(address => uint256) public addressToCowsID;
  mapping(address => mapping(bytes32 => Key)) public containerSigners;

  constructor() {
    address signerOneApprovalPubKey = 0xa7672eE4969E90dC446212266195D606D749B252;
    address signerOneEmergencyPubKey = 0x5719EA9E02DA174d3bcEa374996382d12fED7769;
    Key memory kleatonKeyPair = Key({
      approvalKey: signerOneApprovalPubKey,
      approvalKeyLastUpdated: block.number,
      emergencyKey: signerOneEmergencyPubKey,
      emergencyKeyLastUpdated: block.number
    });

    bytes32 kleaton = 0x551874518c757f93ceb5d342b118faafa7a9e44128124cb3e2b83fa7ff2a7321;
    signerList.push(kleaton);

    address container1smartContract = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
    uint256 firstCowsID = 1;
    addressToCowsID[container1smartContract] = firstCowsID;
    containerSigners[container1smartContract][kleaton] = kleatonKeyPair;
    containerAddrs.push(container1smartContract);
    address signerTwoApprovalPubKey = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address signerTwoEmergencyPubKey = 0x52f9b8afb5e5fc7De93c2234000890889A714584;

    Key memory djosephKeyPair = Key({
      approvalKey: signerTwoApprovalPubKey,
      approvalKeyLastUpdated: block.number,
      emergencyKey: signerTwoEmergencyPubKey,
      emergencyKeyLastUpdated: block.number
    });

    bytes32 djoseph = 0xfb719b9eb807f5c57981871e52e475d85365967cb3464e52e8d3890b605c6110;
    signerList.push(djoseph);

    address container2smartContract = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
    uint256 secondCowsID = 2;
    addressToCowsID[container2smartContract] = secondCowsID;
    containerSigners[container1smartContract][djoseph] = djosephKeyPair;
    containerAddrs.push(container2smartContract);

    address grtAddr = 0xc944E90C64B2c07662A292be6244BDf05Cda44a7;
    Asset memory graph = Asset({name: "The Graph Token", contractAddr: grtAddr});
    dasDetails["GRT"] = graph;

    address uniAddr = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    Asset memory uniswap = Asset({name: "Uniswap Protocol V3", contractAddr: uniAddr});
    dasDetails["UNI"] = uniswap;

    string memory protocol = "Ethereum";

    ContainerInfo storage evm1 = containers[firstCowsID];
    evm1.chain = protocol;
    evm1.activeStatus = true;
    evm1.accountType = AccountType.Omnibus;
    evm1.currentState = State.Normal;
    evm1.dasList.push("GRT");
    evm1.dasList.push("UNI");

    ContainerInfo storage evm2 = containers[secondCowsID];
    evm2.chain = protocol;
    evm2.activeStatus = true;
    evm2.accountType = AccountType.Suspense;
    evm2.currentState = State.Normal;
    evm2.dasList.push("UNI");
  }

  ////// ---------VIEW CALLS [NO GAS]-------- //////

  function hash(string memory _text) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_text));
  }

  function getSigners() public view returns (bytes32[] memory) {
    return signerList;
  }

  function getDas(string calldata _das) external view returns (Asset memory) {
    return dasDetails[_das];
  }

  function getContainers() public view returns (address[] memory) {
    return containerAddrs;
  }

  function getSignerKeyPair(address _containerAddr, bytes32 _signerID)
    public
    view
    returns (Key memory)
  {
    Key memory retrievedKeyPair = containerSigners[_containerAddr][_signerID];
    return retrievedKeyPair;
  }

  function getContainerInfo(uint8 containerID) external view returns (ContainerInfo memory) {
    return containers[containerID];
  }

  function getEnum(uint8 containerID) external view returns (AccountType accountType) {
    return containers[containerID].accountType;
  }

  function listDAS(uint8 containerID) external view returns (string[] memory dasList) {
    return containers[containerID].dasList;
  }

  function lastStatusChangeBlock(uint8 containerID) external view returns (uint256) {
    return containers[containerID].emergencyDeclaredHeight;
  }

  ////// ---------SET TRANSACTION [GAS]-------- //////

  function declareEmergency(address _containerAddr) external {
    uint256 targetContainerID = addressToCowsID[_containerAddr];
    ContainerInfo storage compromisedContainer = containers[targetContainerID];
    compromisedContainer.currentState = State.Emergency;
    compromisedContainer.emergencyDeclaredHeight = block.number;
  }

  function addContainerSigner(
    address _container,
    bytes32[] calldata _signers,
    address[] calldata _approvalKeys,
    address[] calldata _emergencyKeys
  ) external {
    require(
      _signers.length == _approvalKeys.length && _approvalKeys.length == _emergencyKeys.length,
      "argument array length mismatched"
    );
    require(_signers.length > 0, "empty param arrays");
    uint256 targetContainerID = addressToCowsID[_container];
    ContainerInfo storage targetContainer = containers[targetContainerID];
    targetContainer.currentState = State.Emergency;
    targetContainer.emergencyDeclaredHeight = block.number;
    for (uint256 i = 0; i < _signers.length; ) {
      Key storage _key = containerSigners[_container][_signers[i]];
      if (_key.approvalKey != _approvalKeys[i]) {
        _key.approvalKey = _approvalKeys[i];
        _key.approvalKeyLastUpdated = block.number;
      }
      if (_key.emergencyKey != _emergencyKeys[i]) {
        _key.emergencyKey = _emergencyKeys[i];
        _key.emergencyKeyLastUpdated = block.number;
      }
      unchecked {
        ++i;
      }
    }
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

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
      uint256 length = 1;

      // compute log10(value), and add it to length
      uint256 valueCopy = value;
      if (valueCopy >= 10**64) {
        valueCopy /= 10**64;
        length += 64;
      }
      if (valueCopy >= 10**32) {
        valueCopy /= 10**32;
        length += 32;
      }
      if (valueCopy >= 10**16) {
        valueCopy /= 10**16;
        length += 16;
      }
      if (valueCopy >= 10**8) {
        valueCopy /= 10**8;
        length += 8;
      }
      if (valueCopy >= 10**4) {
        valueCopy /= 10**4;
        length += 4;
      }
      if (valueCopy >= 10**2) {
        valueCopy /= 10**2;
        length += 2;
      }
      if (valueCopy >= 10**1) {
        length += 1;
      }
      // now, length is log10(value) + 1

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
      uint256 length = 1;

      // compute log256(value), and add it to length
      uint256 valueCopy = value;
      if (valueCopy >= 1 << 128) {
        valueCopy >>= 128;
        length += 16;
      }
      if (valueCopy >= 1 << 64) {
        valueCopy >>= 64;
        length += 8;
      }
      if (valueCopy >= 1 << 32) {
        valueCopy >>= 32;
        length += 4;
      }
      if (valueCopy >= 1 << 16) {
        valueCopy >>= 16;
        length += 2;
      }
      if (valueCopy >= 1 << 8) {
        valueCopy >>= 8;
        length += 1;
      }
      // now, length is log256(value) + 1

      return toHexString(value, length);
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

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

library StringUtils {
  struct Slice {
    uint256 _len;
    uint256 _ptr;
  }

  function memcpy(
    uint256 dest,
    uint256 src,
    uint256 wordLength
  ) private pure {
    // Copy word-length chunks while possible
    for (; wordLength >= 32; wordLength -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint256 mask = type(uint256).max;
    if (wordLength > 0) {
      mask = 256**(32 - wordLength) - 1;
    }
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }
  }

  /*
   * @dev Returns a Slice containing the entire string.
   * @param self The string to make a Slice from.
   * @return A newly allocated Slice containing the entire string.
   */
  function toSlice(string memory self) internal pure returns (Slice memory) {
    uint256 ptr;
    assembly {
      ptr := add(self, 0x20)
    }
    return Slice(bytes(self).length, ptr);
  }

  /*
   * @dev Returns the length of a null-terminated bytes32 string.
   * @param self The value to find the length of.
   * @return The length of the string, from 0 to 32.
   */
  function len(bytes32 self) internal pure returns (uint256) {
    uint256 ret;
    if (self == 0) return 0;
    if (uint256(self) & type(uint128).max == 0) {
      ret += 16;
      self = bytes32(uint256(self) / 0x100000000000000000000000000000000);
    }
    if (uint256(self) & type(uint64).max == 0) {
      ret += 8;
      self = bytes32(uint256(self) / 0x10000000000000000);
    }
    if (uint256(self) & type(uint32).max == 0) {
      ret += 4;
      self = bytes32(uint256(self) / 0x100000000);
    }
    if (uint256(self) & type(uint16).max == 0) {
      ret += 2;
      self = bytes32(uint256(self) / 0x10000);
    }
    if (uint256(self) & type(uint8).max == 0) {
      ret += 1;
    }
    return 32 - ret;
  }

  /*
   * @dev Returns a Slice containing the entire bytes32, interpreted as a
   *      null-terminated utf-8 string.
   * @param self The bytes32 value to convert to a Slice.
   * @return A new Slice containing the value of the input argument up to the
   *         first null.
   */
  function toSliceB32(bytes32 self) internal pure returns (Slice memory ret) {
    // Allocate space for `self` in memory, copy it there, and point ret at it
    assembly {
      let ptr := mload(0x40)
      mstore(0x40, add(ptr, 0x20))
      mstore(ptr, self)
      mstore(add(ret, 0x20), ptr)
    }
    ret._len = len(self);
  }

  /*
   * @dev Returns a new Slice containing the same data as the current Slice.
   * @param self The Slice to copy.
   * @return A new Slice containing the same data as `self`.
   */
  function copy(Slice memory self) internal pure returns (Slice memory) {
    return Slice(self._len, self._ptr);
  }

  /*
   * @dev Copies a Slice to a new string.
   * @param self The Slice to copy.
   * @return A newly allocated string containing the Slice's text.
   */
  function toString(Slice memory self) internal pure returns (string memory) {
    string memory ret = new string(self._len);
    uint256 retptr;
    assembly {
      retptr := add(ret, 32)
    }

    memcpy(retptr, self._ptr, self._len);
    return ret;
  }

  /*
   * @dev Returns the length in runes of the Slice. Note that this operation
   *      takes time proportional to the length of the Slice; avoid using it
   *      in loops, and call `Slice.empty()` if you only need to know whether
   *      the Slice is empty or not.
   * @param self The Slice to operate on.
   * @return The length of the Slice in runes.
   */
  function len(Slice memory self) internal pure returns (uint256 lemma) {
    // Starting at ptr-31 means the LSB will be the byte we care about
    uint256 ptr = self._ptr - 31;
    uint256 end = ptr + self._len;
    for (lemma = 0; ptr < end; lemma++) {
      uint8 b;
      assembly {
        b := and(mload(ptr), 0xFF)
      }
      if (b < 0x80) {
        ptr += 1;
      } else if (b < 0xE0) {
        ptr += 2;
      } else if (b < 0xF0) {
        ptr += 3;
      } else if (b < 0xF8) {
        ptr += 4;
      } else if (b < 0xFC) {
        ptr += 5;
      } else {
        ptr += 6;
      }
    }
  }

  /*
   * @dev Returns true if the Slice is empty (has a length of 0).
   * @param self The Slice to operate on.
   * @return True if the Slice is empty, False otherwise.
   */
  function empty(Slice memory self) internal pure returns (bool) {
    return self._len == 0;
  }

  /*
   * @dev Returns a positive number if `other` comes lexicographically after
   *      `self`, a negative number if it comes before, or zero if the
   *      contents of the two Slices are equal. Comparison is done per-rune,
   *      on unicode codepoints.
   * @param self The first Slice to compare.
   * @param other The second Slice to compare.
   * @return The result of the comparison.
   */
  function compare(Slice memory self, Slice memory other) internal pure returns (int256) {
    uint256 shortest = self._len;
    if (other._len < self._len) shortest = other._len;

    uint256 selfptr = self._ptr;
    uint256 otherptr = other._ptr;
    for (uint256 idx = 0; idx < shortest; idx += 32) {
      uint256 a;
      uint256 b;
      assembly {
        a := mload(selfptr)
        b := mload(otherptr)
      }
      if (a != b) {
        // Mask out irrelevant bytes and check again
        uint256 mask = type(uint256).max; // 0xffff...
        if (shortest < 32) {
          mask = ~(2**(8 * (32 - shortest + idx)) - 1);
        }
        unchecked {
          uint256 diff = (a & mask) - (b & mask);
          if (diff != 0) return int256(diff);
        }
      }
      selfptr += 32;
      otherptr += 32;
    }
    return int256(self._len) - int256(other._len);
  }

  /*
   * @dev Returns true if the two Slices contain the same text.
   * @param self The first Slice to compare.
   * @param self The second Slice to compare.
   * @return True if the Slices are equal, false otherwise.
   */
  function equals(Slice memory self, Slice memory other) internal pure returns (bool) {
    return compare(self, other) == 0;
  }

  /*
   * @dev Extracts the first rune in the Slice into `rune`, advancing the
   *      Slice to point to the next rune and returning `self`.
   * @param self The Slice to operate on.
   * @param rune The Slice that will contain the first rune.
   * @return `rune`.
   */
  function nextRune(Slice memory self, Slice memory rune) internal pure returns (Slice memory) {
    rune._ptr = self._ptr;

    if (self._len == 0) {
      rune._len = 0;
      return rune;
    }

    uint256 lemma;
    uint256 b;
    // Load the first byte of the rune into the LSBs of b
    assembly {
      b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
    }
    if (b < 0x80) {
      lemma = 1;
    } else if (b < 0xE0) {
      lemma = 2;
    } else if (b < 0xF0) {
      lemma = 3;
    } else {
      lemma = 4;
    }

    // Check for truncated codepoints
    if (lemma > self._len) {
      rune._len = self._len;
      self._ptr += self._len;
      self._len = 0;
      return rune;
    }

    self._ptr += lemma;
    self._len -= lemma;
    rune._len = lemma;
    return rune;
  }

  /*
   * @dev Returns the first rune in the Slice, advancing the Slice to point
   *      to the next rune.
   * @param self The Slice to operate on.
   * @return A Slice containing only the first rune from `self`.
   */
  function nextRune(Slice memory self) internal pure returns (Slice memory ret) {
    nextRune(self, ret);
  }

  /*
   * @dev Returns the number of the first codepoint in the Slice.
   * @param self The Slice to operate on.
   * @return The number of the first codepoint in the Slice.
   */
  function ord(Slice memory self) internal pure returns (uint256 ret) {
    if (self._len == 0) {
      return 0;
    }

    uint256 word;
    uint256 length;
    uint256 divisor = 2**248;

    // Load the rune into the MSBs of b
    assembly {
      word := mload(mload(add(self, 32)))
    }
    uint256 b = word / divisor;
    if (b < 0x80) {
      ret = b;
      length = 1;
    } else if (b < 0xE0) {
      ret = b & 0x1F;
      length = 2;
    } else if (b < 0xF0) {
      ret = b & 0x0F;
      length = 3;
    } else {
      ret = b & 0x07;
      length = 4;
    }

    // Check for truncated codepoints
    if (length > self._len) {
      return 0;
    }

    for (uint256 i = 1; i < length; i++) {
      divisor = divisor / 256;
      b = (word / divisor) & 0xFF;
      if (b & 0xC0 != 0x80) {
        // Invalid UTF-8 sequence
        return 0;
      }
      ret = (ret * 64) | (b & 0x3F);
    }

    return ret;
  }

  /*
   * @dev Returns the keccak-256 hash of the Slice.
   * @param self The Slice to hash.
   * @return The hash of the Slice.
   */
  function keccak(Slice memory self) internal pure returns (bytes32 ret) {
    assembly {
      ret := keccak256(mload(add(self, 32)), mload(self))
    }
  }

  /*
   * @dev Returns true if `self` starts with `needle`.
   * @param self The Slice to operate on.
   * @param needle The Slice to search for.
   * @return True if the Slice starts with the provided text, false otherwise.
   */
  function startsWith(Slice memory self, Slice memory needle) internal pure returns (bool) {
    if (self._len < needle._len) {
      return false;
    }

    if (self._ptr == needle._ptr) {
      return true;
    }

    bool equal;
    assembly {
      let length := mload(needle)
      let selfptr := mload(add(self, 0x20))
      let needleptr := mload(add(needle, 0x20))
      equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
    }
    return equal;
  }

  /*
   * @dev If `self` starts with `needle`, `needle` is removed from the
   *      beginning of `self`. Otherwise, `self` is unmodified.
   * @param self The Slice to operate on.
   * @param needle The Slice to search for.
   * @return `self`
   */
  function beyond(Slice memory self, Slice memory needle) internal pure returns (Slice memory) {
    if (self._len < needle._len) {
      return self;
    }

    bool equal = true;
    if (self._ptr != needle._ptr) {
      assembly {
        let length := mload(needle)
        let selfptr := mload(add(self, 0x20))
        let needleptr := mload(add(needle, 0x20))
        equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
      }
    }

    if (equal) {
      self._len -= needle._len;
      self._ptr += needle._len;
    }

    return self;
  }

  /*
   * @dev Returns true if the Slice ends with `needle`.
   * @param self The Slice to operate on.
   * @param needle The Slice to search for.
   * @return True if the Slice starts with the provided text, false otherwise.
   */
  function endsWith(Slice memory self, Slice memory needle) internal pure returns (bool) {
    if (self._len < needle._len) {
      return false;
    }

    uint256 selfptr = self._ptr + self._len - needle._len;

    if (selfptr == needle._ptr) {
      return true;
    }

    bool equal;
    assembly {
      let length := mload(needle)
      let needleptr := mload(add(needle, 0x20))
      equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
    }

    return equal;
  }

  /*
   * @dev If `self` ends with `needle`, `needle` is removed from the
   *      end of `self`. Otherwise, `self` is unmodified.
   * @param self The Slice to operate on.
   * @param needle The Slice to search for.
   * @return `self`
   */
  function until(Slice memory self, Slice memory needle) internal pure returns (Slice memory) {
    if (self._len < needle._len) {
      return self;
    }

    uint256 selfptr = self._ptr + self._len - needle._len;
    bool equal = true;
    if (selfptr != needle._ptr) {
      assembly {
        let length := mload(needle)
        let needleptr := mload(add(needle, 0x20))
        equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
      }
    }

    if (equal) {
      self._len -= needle._len;
    }

    return self;
  }

  // Returns the memory address of the first byte of the first occurrence of
  // `needle` in `self`, or the first byte after `self` if not found.
  function findPtr(
    uint256 selflen,
    uint256 selfptr,
    uint256 needlelen,
    uint256 needleptr
  ) private pure returns (uint256) {
    uint256 ptr = selfptr;
    uint256 idx;

    if (needlelen <= selflen) {
      if (needlelen <= 32) {
        bytes32 mask;
        if (needlelen > 0) {
          mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
        }

        bytes32 needledata;
        assembly {
          needledata := and(mload(needleptr), mask)
        }

        uint256 end = selfptr + selflen - needlelen;
        bytes32 ptrdata;
        assembly {
          ptrdata := and(mload(ptr), mask)
        }

        while (ptrdata != needledata) {
          if (ptr >= end) return selfptr + selflen;
          ptr++;
          assembly {
            ptrdata := and(mload(ptr), mask)
          }
        }
        return ptr;
      } else {
        // For long needles, use hashing
        bytes32 hash;
        assembly {
          hash := keccak256(needleptr, needlelen)
        }

        for (idx = 0; idx <= selflen - needlelen; idx++) {
          bytes32 testHash;
          assembly {
            testHash := keccak256(ptr, needlelen)
          }
          if (hash == testHash) return ptr;
          ptr += 1;
        }
      }
    }
    return selfptr + selflen;
  }

  // Returns the memory address of the first byte after the last occurrence of
  // `needle` in `self`, or the address of `self` if not found.
  function rfindPtr(
    uint256 selflen,
    uint256 selfptr,
    uint256 needlelen,
    uint256 needleptr
  ) private pure returns (uint256) {
    uint256 ptr;

    if (needlelen <= selflen) {
      if (needlelen <= 32) {
        bytes32 mask;
        if (needlelen > 0) {
          mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
        }

        bytes32 needledata;
        assembly {
          needledata := and(mload(needleptr), mask)
        }

        ptr = selfptr + selflen - needlelen;
        bytes32 ptrdata;
        assembly {
          ptrdata := and(mload(ptr), mask)
        }

        while (ptrdata != needledata) {
          if (ptr <= selfptr) return selfptr;
          ptr--;
          assembly {
            ptrdata := and(mload(ptr), mask)
          }
        }
        return ptr + needlelen;
      } else {
        // For long needles, use hashing
        bytes32 hash;
        assembly {
          hash := keccak256(needleptr, needlelen)
        }
        ptr = selfptr + (selflen - needlelen);
        while (ptr >= selfptr) {
          bytes32 testHash;
          assembly {
            testHash := keccak256(ptr, needlelen)
          }
          if (hash == testHash) return ptr + needlelen;
          ptr -= 1;
        }
      }
    }
    return selfptr;
  }

  /*
   * @dev Modifies `self` to contain everything from the first occurrence of
   *      `needle` to the end of the Slice. `self` is set to the empty Slice
   *      if `needle` is not found.
   * @param self The Slice to search and modify.
   * @param needle The text to search for.
   * @return `self`.
   */
  function find(Slice memory self, Slice memory needle) internal pure returns (Slice memory) {
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
    self._len -= ptr - self._ptr;
    self._ptr = ptr;
    return self;
  }

  /*
   * @dev Modifies `self` to contain the part of the string from the start of
   *      `self` to the end of the first occurrence of `needle`. If `needle`
   *      is not found, `self` is set to the empty Slice.
   * @param self The Slice to search and modify.
   * @param needle The text to search for.
   * @return `self`.
   */
  function rfind(Slice memory self, Slice memory needle) internal pure returns (Slice memory) {
    uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
    self._len = ptr - self._ptr;
    return self;
  }

  /*
   * @dev Splits the Slice, setting `self` to everything after the first
   *      occurrence of `needle`, and `token` to everything before it. If
   *      `needle` does not occur in `self`, `self` is set to the empty Slice,
   *      and `token` is set to the entirety of `self`.
   * @param self The Slice to split.
   * @param needle The text to search for in `self`.
   * @param token An output parameter to which the first token is written.
   * @return `token`.
   */
  function split(
    Slice memory self,
    Slice memory needle,
    Slice memory token
  ) internal pure returns (Slice memory) {
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
    token._ptr = self._ptr;
    token._len = ptr - self._ptr;
    if (ptr == self._ptr + self._len) {
      // Not found
      self._len = 0;
    } else {
      self._len -= token._len + needle._len;
      self._ptr = ptr + needle._len;
    }
    return token;
  }

  /*
   * @dev Splits the Slice, setting `self` to everything after the first
   *      occurrence of `needle`, and returning everything before it. If
   *      `needle` does not occur in `self`, `self` is set to the empty Slice,
   *      and the entirety of `self` is returned.
   * @param self The Slice to split.
   * @param needle The text to search for in `self`.
   * @return The part of `self` up to the first occurrence of `delim`.
   */
  function split(Slice memory self, Slice memory needle)
    internal
    pure
    returns (Slice memory token)
  {
    split(self, needle, token);
  }

  /*
   * @dev Splits the Slice, setting `self` to everything before the last
   *      occurrence of `needle`, and `token` to everything after it. If
   *      `needle` does not occur in `self`, `self` is set to the empty Slice,
   *      and `token` is set to the entirety of `self`.
   * @param self The Slice to split.
   * @param needle The text to search for in `self`.
   * @param token An output parameter to which the first token is written.
   * @return `token`.
   */
  function rsplit(
    Slice memory self,
    Slice memory needle,
    Slice memory token
  ) internal pure returns (Slice memory) {
    uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
    token._ptr = ptr;
    token._len = self._len - (ptr - self._ptr);
    if (ptr == self._ptr) {
      // Not found
      self._len = 0;
    } else {
      self._len -= token._len + needle._len;
    }
    return token;
  }

  /*
   * @dev Splits the Slice, setting `self` to everything before the last
   *      occurrence of `needle`, and returning everything after it. If
   *      `needle` does not occur in `self`, `self` is set to the empty Slice,
   *      and the entirety of `self` is returned.
   * @param self The Slice to split.
   * @param needle The text to search for in `self`.
   * @return The part of `self` after the last occurrence of `delim`.
   */
  function rsplit(Slice memory self, Slice memory needle)
    internal
    pure
    returns (Slice memory token)
  {
    rsplit(self, needle, token);
  }

  /*
   * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
   * @param self The Slice to search.
   * @param needle The text to search for in `self`.
   * @return The number of occurrences of `needle` found in `self`.
   */
  function count(Slice memory self, Slice memory needle) internal pure returns (uint256 cnt) {
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
    while (ptr <= self._ptr + self._len) {
      cnt++;
      ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
    }
  }

  /*
   * @dev Returns True if `self` contains `needle`.
   * @param self The Slice to search.
   * @param needle The text to search for in `self`.
   * @return True if `needle` is found in `self`, false otherwise.
   */
  function contains(Slice memory self, Slice memory needle) internal pure returns (bool) {
    return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
  }

  /*
   * @dev Returns a newly allocated string containing the concatenation of
   *      `self` and `other`.
   * @param self The first Slice to concatenate.
   * @param other The second Slice to concatenate.
   * @return The concatenation of the two strings.
   */
  function concat(Slice memory self, Slice memory other) internal pure returns (string memory) {
    string memory ret = new string(self._len + other._len);
    uint256 retptr;
    assembly {
      retptr := add(ret, 32)
    }
    memcpy(retptr, self._ptr, self._len);
    memcpy(retptr + self._len, other._ptr, other._len);
    return ret;
  }

  /*
   * @dev Joins an array of Slices, using `self` as a delimiter, returning a
   *      newly allocated string.
   * @param self The delimiter to use.
   * @param parts A list of Slices to join.
   * @return A newly allocated string containing all the Slices in `parts`,
   *         joined with `self`.
   */
  function join(Slice memory self, Slice[] memory parts) internal pure returns (string memory) {
    if (parts.length == 0) return "";

    uint256 length = self._len * (parts.length - 1);
    for (uint256 i = 0; i < parts.length; i++) length += parts[i]._len;

    string memory ret = new string(length);
    uint256 retptr;
    assembly {
      retptr := add(ret, 32)
    }

    for (uint256 i = 0; i < parts.length; i++) {
      memcpy(retptr, parts[i]._ptr, parts[i]._len);
      retptr += parts[i]._len;
      if (i < parts.length - 1) {
        memcpy(retptr, self._ptr, self._len);
        retptr += self._len;
      }
    }

    return ret;
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/solidity-stringutils/src/strings.sol";
import "lib/forge-std/src/console.sol";

library VerifySignatureUtil {
  using strings for *;
  struct BaseSignature {
    bytes signature;
    string message;
  }

  struct VerifiedSignature {
    BaseSignature signature;
    address recoveredSigner;
    bool isVerified;
  }

  struct SignatureParam {
    uint256 requestId;
    int256 userId;
    int256 deviceId;
    BaseSignature signature;
  }

  struct RootSignatureParam {
    uint256 requestId;
    int256 cowId;
    BaseSignature signature;
  }

  struct ExtractedSigningMessage {
    string levelType;
    bytes32 cowId;
    address contractAddr;
    string method;
    string keyType; // signer key type
    string signingFor;
    uint256 totalKeyNum;
    uint256 totalUserNum;
    bytes32[10] userId;
    bytes32[10] deviceId;
    string[10] userKeyType; // user key type
    int32[10] derivationIndex;
    address[10] userKeys;
    uint256 totalInventionKeyNum;
    address[5] interventionKeys;
    address signerPublicAddress;
    bytes32 requestId;
    string requestType;
    uint256 totalSigNum;
    bytes[5] approvalSignatures;
    bytes32 depositDirectId;
    address source;
    bytes32 dasId;
    uint256 amount;
    address to;
    bytes32 allowedCowId; // allowed_cow_id_on_behalf (for direct deposit)
    uint256 approvedAt; // approved_at_block_number (for direct deposit)
    uint256 moveType; // 0=withdrawal, 1=____ etc
    uint256 expiredAt;
    int256 nonce;
  }

  // This function is for converting string number to uint type
  function stringToUint(string memory s) public pure returns (uint256 result) {
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

  // This function is for converting string number to int32 type
  function stringToInt32(string memory s) public pure returns (int32) {
    bool isNegative = s.toSlice().startsWith("-".toSlice());
    bytes memory b = bytes(s);
    int32 result = 0;
    for (uint256 i = 0; i < b.length; i++) {
      int32 c = int32(uint32(uint8(b[i])));
      if (c >= 48 && c <= 57) {
        result = result * 10 + (c - 48);
      }
    }
    return isNegative ? -result : result;
  }

  // This function is for converting string to bytes32
  function stringToBytes32(string memory source) public pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
      return 0x0;
    }

    assembly {
      result := mload(add(source, 32))
    }
  }

  // This function is for converting string address to address type
  function stringToAddr(string memory _a) internal pure returns (address _parsedAddress) {
    bytes memory tmp = bytes(_a);
    uint160 iaddr = 0;
    uint160 b1;
    uint160 b2;
    for (uint256 i = 2; i < 2 + 2 * 20; i += 2) {
      iaddr *= 256;
      b1 = uint160(uint8(tmp[i]));
      b2 = uint160(uint8(tmp[i + 1]));
      if ((b1 >= 97) && (b1 <= 102)) {
        b1 -= 87;
      } else if ((b1 >= 65) && (b1 <= 70)) {
        b1 -= 55;
      } else if ((b1 >= 48) && (b1 <= 57)) {
        b1 -= 48;
      }
      if ((b2 >= 97) && (b2 <= 102)) {
        b2 -= 87;
      } else if ((b2 >= 65) && (b2 <= 70)) {
        b2 -= 55;
      } else if ((b2 >= 48) && (b2 <= 57)) {
        b2 -= 48;
      }
      iaddr += (b1 * 16 + b2);
    }
    return address(iaddr);
  }

  // This function is for converting an hexadecimal character to their value in uint8 type
  function fromHexChar(uint8 c) public pure returns (uint8) {
    if (bytes1(c) >= bytes1("0") && bytes1(c) <= bytes1("9")) {
      return c - uint8(bytes1("0"));
    }
    if (bytes1(c) >= bytes1("a") && bytes1(c) <= bytes1("f")) {
      return 10 + c - uint8(bytes1("a"));
    }
    if (bytes1(c) >= bytes1("A") && bytes1(c) <= bytes1("F")) {
      return 10 + c - uint8(bytes1("A"));
    }
    revert("fail");
  }

  // This function is for converting an hexadecimal string to raw bytes
  function fromHex(string memory s) public pure returns (bytes memory) {
    bytes memory ss = bytes(s);
    require(ss.length % 2 == 0, "string's byte-length is odd!"); // length must be even
    bytes memory r = new bytes(ss.length / 2);
    for (uint256 i = 0; i < ss.length / 2; ++i) {
      r[i] = bytes1(fromHexChar(uint8(ss[2 * i])) * 16 + fromHexChar(uint8(ss[2 * i + 1])));
    }
    return r;
  }

  // This function is for removing prefix '0x' and converting string type signature to bytes type
  function stringToBytes(string memory stringSig) public pure returns (bytes memory) {
    strings.slice memory sliceStr = stringSig.toSlice();
    // remove '0x' prefix and convert back to sting
    string memory sliceStr2 = sliceStr.beyond("0x".toSlice()).toString();
    // convert hex string to bytes
    bytes memory bytesSig = fromHex(sliceStr2);

    return bytesSig;
  }

  // This function is for converting bytes to hex string
  function bytesToHex(bytes32 data) public pure returns (string memory) {
    bytes memory buffer = abi.encodePacked(data);

    // Fixed buffer size for hexadecimal convertion
    bytes memory converted = new bytes(buffer.length * 2);

    bytes memory _base = "0123456789abcdef";

    for (uint256 i = 0; i < buffer.length; i++) {
      converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
      converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
    }

    return string(abi.encodePacked("0x", converted));
  }

  // This function is for converting bytes32 to bytes
  function bytes32ToBytes(bytes32 _bytes32) public pure returns (bytes memory) {
    // string memory str = string(_bytes32);
    // TypeError: Explicit type conversion not allowed from "bytes32" to "string storage pointer"
    bytes memory bytesArray = new bytes(32);
    for (uint256 i; i < 32; i++) {
      bytesArray[i] = _bytes32[i];
    }
    return bytesArray;
  }

  // This function is for converting bytes32 to string
  function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
    bytes memory bytesArray = bytes32ToBytes(_bytes32);
    return string(bytesArray);
  }

  // This function is for converting int to string
  function intToString(int256 i) internal pure returns (string memory) {
    if (i == 0) return "0";
    bool negative = i < 0;
    uint256 j = uint256(negative ? -i : i);
    uint256 l = j; // Keep an unsigned copy
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    if (negative) ++len; // Make room for '-' sign
    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;
    while (l != 0) {
      bstr[k--] = bytes1(uint8(48 + (l % 10)));
      l /= 10;
    }
    if (negative) {
      // Prepend '-'
      bstr[0] = "-";
    }
    return string(bstr);
  }

  // This function is for converting original formatted message into generic struct
  function convertToStruct(string[] memory extractedMsg)
    external
    pure
    returns (ExtractedSigningMessage memory)
  {
    uint256 total = extractedMsg.length;
    bytes[5] memory emptySigArr;
    bytes32[10] memory emptyUserIdArr;
    bytes32[10] memory emptyDeviceIdArr;
    string[10] memory emptyUserKeyType;
    int32[10] memory emptyDerivationIndexArr;
    address[10] memory emptyUserKeysArr;
    address[5] memory emptyInterventionArr;
    ExtractedSigningMessage memory message = ExtractedSigningMessage({
      levelType: extractedMsg[0],
      cowId: stringToBytes32(extractedMsg[1]),
      contractAddr: stringToAddr(extractedMsg[2]),
      method: extractedMsg[3],
      keyType: extractedMsg[4],
      signingFor: extractedMsg[5],
      totalKeyNum: 0,
      totalUserNum: 0,
      userId: emptyUserIdArr,
      deviceId: emptyDeviceIdArr,
      userKeyType: emptyUserKeyType,
      derivationIndex: emptyDerivationIndexArr,
      userKeys: emptyUserKeysArr,
      totalInventionKeyNum: 0,
      interventionKeys: emptyInterventionArr,
      signerPublicAddress: address(0),
      requestId: "",
      requestType: "",
      totalSigNum: 0,
      approvalSignatures: emptySigArr,
      depositDirectId: "",
      source: address(0),
      dasId: "",
      amount: 0,
      to: address(0),
      allowedCowId: "",
      approvedAt: 0,
      expiredAt: 0,
      moveType: 0,
      nonce: -1
    });

    // For approval signature in COWS Management- general operation
    if (
      extractedMsg[3].toSlice().equals("approveChanges".toSlice()) &&
      extractedMsg[4].toSlice().equals("Approval".toSlice()) &&
      extractedMsg[5].toSlice().equals("Approve".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.requestId = stringToBytes32(extractedMsg[7]);
      message.nonce = int256(stringToUint(extractedMsg[8]));
    }
    // For CASTL signature in COWS Management- general operation
    else if (
      extractedMsg[3].toSlice().equals("approveChanges".toSlice()) &&
      extractedMsg[4].toSlice().equals("CASTL".toSlice()) &&
      extractedMsg[5].toSlice().equals("Call".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.requestId = stringToBytes32(extractedMsg[7]);
      message.totalSigNum = stringToUint(extractedMsg[8]);
      for (uint256 i = 0; i < message.totalSigNum; i++) {
        message.approvalSignatures[i] = stringToBytes(
          extractedMsg[i + (total - message.totalSigNum - 1)]
        );
      }
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For CASTL signature in COWS Management- recognize (CASTL signatures submitter)
    else if (
      extractedMsg[3].toSlice().equals("recognize".toSlice()) &&
      extractedMsg[4].toSlice().equals("CASTL".toSlice()) &&
      extractedMsg[5].toSlice().equals("Call".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.totalSigNum = stringToUint(extractedMsg[7]);
      for (uint256 i = 0; i < message.totalSigNum; i++) {
        message.approvalSignatures[i] = stringToBytes(
          extractedMsg[i + (total - message.totalSigNum - 1)]
        );
      }
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For CASTL signature in COWS Management- recognize (CASTL approval)
    else if (
      extractedMsg[3].toSlice().equals("recognize".toSlice()) &&
      extractedMsg[4].toSlice().equals("CASTL".toSlice()) &&
      extractedMsg[5].toSlice().equals("Approve".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For approval signature in Key Management
    else if (
      (extractedMsg[3].toSlice().equals("approveApprovalKeyRequests".toSlice()) ||
        extractedMsg[3].toSlice().equals("approveCASTLKeyRequest".toSlice()) ||
        extractedMsg[3].toSlice().equals("approveInterventionKeyRequest".toSlice()) ||
        extractedMsg[3].toSlice().equals("approveReplaceKeyRequest".toSlice()) ||
        extractedMsg[3].toSlice().equals("approveReplaceCASTLKeyRequest".toSlice()) ||
        extractedMsg[3].toSlice().equals("approveUserKeysStatusRequest".toSlice()) ||
        extractedMsg[3].toSlice().equals("approveReplaceUserRequest".toSlice()) ||
        extractedMsg[3].toSlice().equals("emergencyReplaceUserKeysExecute".toSlice())) &&
      extractedMsg[4].toSlice().equals("Approval".toSlice()) &&
      extractedMsg[5].toSlice().equals("Approve".toSlice())
    ) {
      message.userId[0] = bytes32(stringToBytes(extractedMsg[6]));
      message.deviceId[0] = bytes32(stringToBytes(extractedMsg[7]));
      message.signerPublicAddress = stringToAddr(extractedMsg[8]);
      message.requestId = stringToBytes32(extractedMsg[9]);
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For CASTL signature in Key Management- init
    else if (
      extractedMsg[3].toSlice().equals("init".toSlice()) &&
      extractedMsg[4].toSlice().equals("CASTL".toSlice()) &&
      extractedMsg[5].toSlice().equals("Call".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.totalUserNum = stringToUint(extractedMsg[7]);
      message.totalInventionKeyNum = stringToUint(extractedMsg[7 + message.totalUserNum * 5 + 1]);
      uint256 startAt = total - (message.totalUserNum * 5) - (message.totalInventionKeyNum + 1) - 1;
      uint256 index = 0;
      for (uint256 i = 0; i < message.totalUserNum * 5; ) {
        message.userId[index] = bytes32(stringToBytes(extractedMsg[i + startAt]));
        message.deviceId[index] = bytes32(stringToBytes(extractedMsg[i + 1 + startAt]));
        message.userKeyType[index] = extractedMsg[i + 2 + startAt];
        message.derivationIndex[index] = int32(stringToInt32(extractedMsg[i + 3 + startAt]));
        message.userKeys[index] = stringToAddr(extractedMsg[i + 4 + startAt]);
        i += 5;
        index++;
      }

      startAt = total - (message.totalInventionKeyNum) - 1;
      for (uint256 i = 0; i < message.totalInventionKeyNum; i++) {
        message.interventionKeys[i] = stringToAddr(extractedMsg[i + startAt]);
      }
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For CASTL signature in Key Management- send approvals block
    else if (
      (extractedMsg[3].toSlice().equals("approveApprovalKeyRequests".toSlice()) ||
        extractedMsg[3].toSlice().equals("approveCASTLKeyRequest".toSlice()) ||
        extractedMsg[3].toSlice().equals("approveInterventionKeyRequest".toSlice()) ||
        extractedMsg[3].toSlice().equals("approveReplaceKeyRequest".toSlice()) ||
        extractedMsg[3].toSlice().equals("approveReplaceCASTLKeyRequest".toSlice()) ||
        extractedMsg[3].toSlice().equals("approveUserKeysStatusRequest".toSlice()) ||
        extractedMsg[3].toSlice().equals("approveReplaceUserRequest".toSlice())) &&
      extractedMsg[4].toSlice().equals("CASTL".toSlice()) &&
      extractedMsg[5].toSlice().equals("Call".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.requestId = stringToBytes32(extractedMsg[7]);
      message.totalSigNum = stringToUint(extractedMsg[8]);
      for (uint256 i = 0; i < message.totalSigNum; i++) {
        message.approvalSignatures[i] = stringToBytes(
          extractedMsg[i + (total - message.totalSigNum - 1)]
        );
      }
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For  CASTL signature in Key Management- emergency request execution
    else if (
      extractedMsg[3].toSlice().equals("emergencyReplaceUserKeysExecute".toSlice()) &&
      extractedMsg[4].toSlice().equals("CASTL".toSlice()) &&
      extractedMsg[5].toSlice().equals("Call".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.requestId = stringToBytes32(extractedMsg[7]);
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For  CASTL signature in Key Management- force close operation
    else if (
      extractedMsg[3].toSlice().equals("forceClose".toSlice()) &&
      extractedMsg[4].toSlice().equals("CASTL".toSlice()) &&
      extractedMsg[5].toSlice().equals("Call".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.requestType = extractedMsg[7];
      message.requestId = stringToBytes32(extractedMsg[8]);
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For emergency signature in Key Management- emergency request start
    else if (
      extractedMsg[3].toSlice().equals("emergencyReplaceUserKeysStart".toSlice()) &&
      extractedMsg[4].toSlice().equals("Emergency".toSlice())
    ) {
      message.userId[0] = bytes32(stringToBytes(extractedMsg[6]));
      message.deviceId[0] = bytes32(stringToBytes(extractedMsg[7]));
      message.signerPublicAddress = stringToAddr(extractedMsg[8]);
      message.totalKeyNum = stringToUint(extractedMsg[9]);
      uint256 startAt = total - (message.totalKeyNum * 3) - 2;
      uint256 index = 0;
      for (uint256 i = 0; i < message.totalKeyNum * 3; ) {
        message.userKeyType[index] = extractedMsg[i + startAt];
        message.derivationIndex[index] = int32(stringToInt32(extractedMsg[i + 1 + startAt]));
        message.userKeys[index] = stringToAddr(extractedMsg[i + 2 + startAt]);
        i += 3;
        index++;
      }
      message.requestId = stringToBytes32(extractedMsg[total - 2]);
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For emergency signature in Key Management- emergency request execution
    else if (
      extractedMsg[3].toSlice().equals("emergencyReplaceUserKeysExecute".toSlice()) &&
      extractedMsg[4].toSlice().equals("Emergency".toSlice()) &&
      extractedMsg[5].toSlice().equals("Call".toSlice())
    ) {
      message.userId[0] = bytes32(stringToBytes(extractedMsg[6]));
      message.signerPublicAddress = stringToAddr(extractedMsg[7]);
      message.requestId = stringToBytes32(extractedMsg[8]);
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For intervention signature in Key Management
    else if (
      extractedMsg[3].toSlice().equals("emergencyReplaceUserKeysIntervene".toSlice()) &&
      extractedMsg[4].toSlice().equals("Intervention".toSlice()) &&
      extractedMsg[5].toSlice().equals("RejectCall".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.requestId = stringToBytes32(extractedMsg[7]);
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For approval signature in Custody Wallet (withdrawal)
    else if (
      extractedMsg[3].toSlice().equals("approveWithdrawal".toSlice()) &&
      extractedMsg[4].toSlice().equals("Approval".toSlice()) &&
      extractedMsg[5].toSlice().equals("Approve".toSlice())
    ) {
      message.userId[0] = bytes32(stringToBytes(extractedMsg[6]));
      message.deviceId[0] = bytes32(stringToBytes(extractedMsg[7]));
      message.signerPublicAddress = stringToAddr(extractedMsg[8]);
      message.moveType = stringToUint(extractedMsg[9]);
      message.dasId = stringToBytes32(extractedMsg[10]);
      message.amount = stringToUint(extractedMsg[11]);
      message.to = stringToAddr(extractedMsg[12]);
      message.expiredAt = stringToUint(extractedMsg[13]);
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For CASTL signature in Custody Wallet (withdrawal)
    else if (
      extractedMsg[3].toSlice().equals("approveWithdrawal".toSlice()) &&
      extractedMsg[4].toSlice().equals("CASTL".toSlice()) &&
      extractedMsg[5].toSlice().equals("Call".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.totalSigNum = stringToUint(extractedMsg[7]);
      for (uint256 i = 0; i < message.totalSigNum; i++) {
        message.approvalSignatures[i] = stringToBytes(
          extractedMsg[i + (total - message.totalSigNum - 1)]
        );
      }
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For approval signature in Custody Wallet (DAS-approval-check)
    else if (
      extractedMsg[3].toSlice().equals("dasApprovalCheck".toSlice()) &&
      extractedMsg[4].toSlice().equals("Approval".toSlice()) &&
      extractedMsg[5].toSlice().equals("Approve".toSlice())
    ) {
      message.userId[0] = bytes32(stringToBytes(extractedMsg[6]));
      message.deviceId[0] = bytes32(stringToBytes(extractedMsg[7]));
      message.signerPublicAddress = stringToAddr(extractedMsg[8]);
      message.requestId = stringToBytes32(extractedMsg[9]);
      message.dasId = stringToBytes32(extractedMsg[10]);
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For CASTL signature in Custody Wallet (DAS-approval-check)
    else if (
      extractedMsg[3].toSlice().equals("dasApprovalCheck".toSlice()) &&
      extractedMsg[4].toSlice().equals("CASTL".toSlice()) &&
      extractedMsg[5].toSlice().equals("Call".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.requestId = stringToBytes32(extractedMsg[7]);
      message.dasId = stringToBytes32(extractedMsg[8]);
      message.totalSigNum = stringToUint(extractedMsg[9]);
      for (uint256 i = 0; i < message.totalSigNum; i++) {
        message.approvalSignatures[i] = stringToBytes(
          extractedMsg[i + (total - message.totalSigNum - 1)]
        );
      }
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For user approval signature in Direct Deposit
    else if (
      extractedMsg[3].toSlice().equals("directDeposit".toSlice()) &&
      extractedMsg[4].toSlice().equals("GeneralUser".toSlice()) &&
      extractedMsg[5].toSlice().equals("Call".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.depositDirectId = stringToBytes32(extractedMsg[7]);
      message.dasId = stringToBytes32(extractedMsg[8]);
      message.amount = stringToUint(extractedMsg[9]);
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For CASTL signature in Direct Deposit
    else if (
      extractedMsg[3].toSlice().equals("directDeposit".toSlice()) &&
      extractedMsg[4].toSlice().equals("CASTL".toSlice()) &&
      extractedMsg[5].toSlice().equals("Approve".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.depositDirectId = stringToBytes32(extractedMsg[7]);
      message.source = stringToAddr(extractedMsg[8]);
      message.dasId = stringToBytes32(extractedMsg[9]);
      message.amount = stringToUint(extractedMsg[10]);
      message.allowedCowId = stringToBytes32(extractedMsg[11]);
      message.approvedAt = stringToUint(extractedMsg[12]);
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For approval signature in Global State
    else if (
      extractedMsg[3].toSlice().equals("setModeActiveNormal".toSlice()) &&
      extractedMsg[4].toSlice().equals("Approval".toSlice()) &&
      extractedMsg[5].toSlice().equals("Approve".toSlice())
    ) {
      message.userId[0] = bytes32(stringToBytes(extractedMsg[6]));
      message.deviceId[0] = bytes32(stringToBytes(extractedMsg[7]));
      message.signerPublicAddress = stringToAddr(extractedMsg[8]);
      message.requestId = stringToBytes32(extractedMsg[9]);
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For CASTL signature in Global State (CASTL signatures submitter)
    else if (
      extractedMsg[3].toSlice().equals("setModeActiveNormal".toSlice()) &&
      extractedMsg[4].toSlice().equals("CASTL".toSlice()) &&
      extractedMsg[5].toSlice().equals("Call".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.requestId = stringToBytes32(extractedMsg[7]);
      message.totalSigNum = stringToUint(extractedMsg[8]);
      for (uint256 i = 0; i < message.totalSigNum; i++) {
        message.approvalSignatures[i] = stringToBytes(
          extractedMsg[i + (total - message.totalSigNum - 1)]
        );
      }
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }
    // For CASTL signature in Global State (CASTL approval)
    else if (
      extractedMsg[3].toSlice().equals("setModeActiveNormal".toSlice()) &&
      extractedMsg[4].toSlice().equals("CASTL".toSlice()) &&
      extractedMsg[5].toSlice().equals("Approve".toSlice())
    ) {
      message.signerPublicAddress = stringToAddr(extractedMsg[6]);
      message.requestId = stringToBytes32(extractedMsg[7]);
      message.nonce = int256(stringToUint(extractedMsg[total - 1]));
    }

    return message;
  }

  // This function is for extracting each parameter from original formatted message into string array
  function extractMessage(string calldata formattedMsg) external pure returns (string[] memory) {
    strings.slice memory sliceStr = formattedMsg.toSlice();
    strings.slice memory delim = "//".toSlice();
    string[] memory parts = new string[](sliceStr.count(delim));
    uint256 total = sliceStr.count(delim);
    for (uint256 i = 0; i < total; i++) {
      parts[i] = sliceStr.split(delim).toString();
      // console.log("splited part: ", parts[i]);
      // console.log("sliceStr: ", sliceStr.toString());
    }
    return parts;
  }

  // This function is for verifying signed signature by recovering signer from signature + message
  function verifySignature(bytes calldata signature, string calldata message)
    public
    pure
    returns (address)
  {
    // convert to Ethereum Signed Message
    bytes32 messageHash = ECDSA.toEthSignedMessageHash(bytes(message));

    // start recover signer from signatrue and hash of message
    return ECDSA.recover(messageHash, signature);
  }
}

// pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "lib/solidity-stringutils/src/strings.sol";
import "lib/forge-std/src/console.sol";
import {VerifySignatureUtil as SigUtil} from "./VerifySignatureUtil.sol";
import {KeyManagement} from "./KeyManagement.sol";

library VerifyUtil {
  using strings for *;

  // This function is for counting how many non-empty elements in a fixed-size array (ex. SigUtil.BaseSignature[5])
  function getSignedMsgCount(SigUtil.BaseSignature[5] calldata signedApprovals)
    public
    pure
    returns (uint256)
  {
    uint256 numApprovals;
    for (uint256 i; i < 5; ) {
      if (bytes(signedApprovals[i].message).length != 0) {
        unchecked {
          ++numApprovals;
        }
      }

      unchecked {
        ++i;
      }
    }

    return numApprovals;
  }

  // This function is for checking if signed approval signatures included in callerSignature message matches signatures from signedApprovals
  // The order/ index should be the same
  function checkSigsMatch(
    SigUtil.BaseSignature[5] calldata signedApprovals,
    bytes[5] calldata extractedSignedApprovals,
    uint256 numOfApprovals
  ) public pure returns (bool) {
    for (uint256 i = 0; i < numOfApprovals; ) {
      if (bytes(signedApprovals[i].message).length == 0) {
        continue;
      }
      if (keccak256(extractedSignedApprovals[i]) != keccak256(signedApprovals[i].signature)) {
        return false;
      }

      unchecked {
        ++i;
      }
    }

    return true;
  }

  // This function is for verifying the 'expectedKeyAddress' against the recovered signer from 'baseSignature'
  function verifySingleSignature(
    address expectedKeyAddress,
    SigUtil.BaseSignature calldata baseSignature
  ) public view returns (bool, address) {
    address _recoveredApprover = SigUtil.verifySignature(
      baseSignature.signature,
      baseSignature.message
    );

    console.log("expectedKeyAddress: ", expectedKeyAddress);
    console.log("_recoveredApprover: ", _recoveredApprover);

    bool isVerified;

    if (expectedKeyAddress == _recoveredApprover) {
      isVerified = true;
    }

    return (isVerified, _recoveredApprover);
  }

  // This function is for checking if a recovered signer has valid approval key in approvalKeyUnit for a specific user
  function isValidApprovalKey(KeyManagement.Key[] memory approvalKeys, address recoverSigner)
    public
    pure
    returns (bool)
  {
    uint256 approvalKeyCount = approvalKeys.length;
    for (uint256 i; i < approvalKeyCount; ) {
      if (approvalKeys[i].keyAddress == recoverSigner) {
        return true;
      }

      unchecked {
        ++i;
      }
    }

    return false;
  }

  // This function is for checking if duplicate key existed in same address array
  function isDuplicateKey(bytes32[5] memory recoverSigners, uint256 numOfSigner)
    public
    pure
    returns (bool)
  {
    for (uint256 i = 0; i < numOfSigner - 1; ) {
      for (uint256 j = 1 + i; j < numOfSigner; ) {
        if (recoverSigners[i] == recoverSigners[j]) {
          return true;
        }

        unchecked {
          ++j;
        }
      }

      unchecked {
        ++i;
      }
    }

    return false;
  }

  // This function is for checking if a single address signed 2 signatures
  function isDuplicateSigner(address[5] memory _signers) public pure returns (bool) {
    uint256 _signersLength = _signers.length;
    for (uint256 i = 0; i < _signersLength; ) {
      for (uint256 j = 1 + i; j < _signersLength; ) {
        if (_signers[i] == _signers[j]) {
          return true;
        }

        unchecked {
          ++j;
        }
      }

      unchecked {
        ++i;
      }
    }

    return false;
  }
}