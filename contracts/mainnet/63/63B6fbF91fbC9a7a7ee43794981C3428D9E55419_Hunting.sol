// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
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
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
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
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
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
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
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
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
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

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
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

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
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

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
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

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
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

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
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

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
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

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
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

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
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

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
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

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
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

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
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

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
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

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
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

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
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

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
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

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
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
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../extensions/IERC721AQueryable.sol';

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.13;

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.9;

// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// import {ICurrencyManager} from "./interfaces/ICurrencyManager.sol";

// /**
//  * @title CurrencyManager
//  * @notice It allows adding/removing currencies for trading on the Joepeg exchange.
//  */
// contract CurrencyManager is
//     ICurrencyManager,
//     Ownable
// {
//     using EnumerableSet for EnumerableSet.AddressSet;

//     EnumerableSet.AddressSet private _whitelistedCurrencies;

//     event CurrencyRemoved(address indexed currency);
//     event CurrencyWhitelisted(address indexed currency);

//     /**
//      * @notice Add a currency in the system
//      * @param currency address of the currency to add
//      */
//     function addCurrency(address currency) external override onlyOwner {
//         require(
//             !_whitelistedCurrencies.contains(currency),
//             "Currency: Already whitelisted"
//         );
//         _whitelistedCurrencies.add(currency);

//         emit CurrencyWhitelisted(currency);
//     }

//     /**
//      * @notice Remove a currency from the system
//      * @param currency address of the currency to remove
//      */
//     function removeCurrency(address currency) external override onlyOwner {
//         require(
//             _whitelistedCurrencies.contains(currency),
//             "Currency: Not whitelisted"
//         );
//         _whitelistedCurrencies.remove(currency);

//         emit CurrencyRemoved(currency);
//     }

//     /**
//      * @notice Returns if a currency is in the system
//      * @param currency address of the currency
//      */
//     function isCurrencyWhitelisted(address currency)
//         external
//         view
//         override
//         returns (bool)
//     {
//         return _whitelistedCurrencies.contains(currency);
//     }

//     /**
//      * @notice View number of whitelisted currencies
//      */
//     function viewCountWhitelistedCurrencies()
//         external
//         view
//         override
//         returns (uint256)
//     {
//         return _whitelistedCurrencies.length();
//     }

//     /**
//      * @notice See whitelisted currencies in the system
//      * @param cursor cursor (should start at 0 for first request)
//      * @param size size of the response (e.g., 50)
//      */
//     function viewWhitelistedCurrencies(uint256 cursor, uint256 size)
//         external
//         view
//         override
//         returns (address[] memory, uint256)
//     {
//         uint256 length = size;

//         if (length > _whitelistedCurrencies.length() - cursor) {
//             length = _whitelistedCurrencies.length() - cursor;
//         }

//         address[] memory whitelistedCurrencies = new address[](length);

//         for (uint256 i = 0; i < length; i++) {
//             whitelistedCurrencies[i] = _whitelistedCurrencies.at(cursor + i);
//         }

//         return (whitelistedCurrencies, cursor + length);
//     }
// }

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTimeLibrary {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isLeapYear(uint256 timestamp)
        internal
        pure
        returns (bool leapYear)
    {
        (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        (uint256 year, uint256 month, ) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp)
        internal
        pure
        returns (uint256 dayOfWeek)
    {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp)
        internal
        pure
        returns (uint256 minute)
    {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp)
        internal
        pure
        returns (uint256 second)
    {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    /**
     * @notice Get the expiry timestamp based on cover duration
     *
     * @param _now           Current timestamp
     * @param _coverDuration Months to cover: 1-3
     */
    function _getExpiry(uint256 _now, uint256 _coverDuration)
        internal
        pure
        returns (
            uint256 endTimestamp,
            uint256 year,
            uint256 month
        )
    {
        // Get the day of the month
        (, , uint256 day) = timestampToDate(_now);

        // Cover duration of 1 month means current month
        // unless today is the 25th calendar day or later
        uint256 monthsToAdd = _coverDuration - 1;

        // TODO: whether need this auto-extending feature
        if (day >= 25) {
            // Add one month
            monthsToAdd += 1;
        }
        return _getFutureMonthEndTime(_now, monthsToAdd);
    }

    /**
     * @notice Get the end timestamp of a future month
     *
     * @param _timestamp   Current timestamp
     * @param _monthsToAdd Months to be added
     *
     * @return endTimestamp End timestamp of a future month
     */
    function _getFutureMonthEndTime(uint256 _timestamp, uint256 _monthsToAdd)
        private
        pure
        returns (
            uint256 endTimestamp,
            uint256 year,
            uint256 month
        )
    {
        uint256 futureTimestamp = addMonths(_timestamp, _monthsToAdd);
        return _getMonthEndTimestamp(futureTimestamp);
    }

    /**
     * @notice Get the last second of a month
     *
     * @param _timestamp Timestamp to be calculated
     *
     * @return endTimestamp End timestamp of the month
     */
    function _getMonthEndTimestamp(uint256 _timestamp)
        private
        pure
        returns (
            uint256 endTimestamp,
            uint256 year,
            uint256 month
        )
    {
        // Get the year and month from the date
        (year, month, ) = timestampToDate(_timestamp);
        
        // Count the total number of days of that month and year
        uint256 daysInMonth = _getDaysInMonth(year, month);
        // Get the month end timestamp
        endTimestamp = timestampFromDateTime(
            year,
            month,
            daysInMonth,
            23,
            59,
            59
        );
    }
}

// // SPDX-License-Identifier: MIT AND BSD-3-Clause

// pragma solidity >=0.8.9 <0.9.0;

// // ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
// // ██ ██ █▀▄▄▀█ ▄▄▀█ ▄▀█ ▄▄███ ▄▄▀█ ▄▄▀█ ▄▀████ ▄▄▄█ ▄▄▀█▀▄▀█▄ ▄██▄██▀▄▄▀█ ▄▄▀█ ▄▄
// // ██ ▄▄ █ ██ █ ▀▀▄█ █ █ ▄▄███ ▀▀ █ ██ █ █ ████ ▄▄██ ▀▀ █ █▀██ ███ ▄█ ██ █ ██ █▄▄▀
// // ██ ██ ██▄▄██▄█▄▄█▄▄██▄▄▄███▄██▄█▄██▄█▄▄█████ ████▄██▄██▄███▄██▄▄▄██▄▄██▄██▄█▄▄▄
// // ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
// //                                                         contract by: primata 🐵

// import "@ERC721A/contracts/interfaces/IERC721AQueryable.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "./interfaces/IHunting.sol";

// contract HordeAndFactions is Ownable {
//     struct Faction {
//         address leader;
//         uint256 limit;
//         uint256 background;
//         string name;
//         string logo;
//         address[] members;
//     }

//     // authorized kami
//     mapping(address => bool) public kami;

//     // leader address => faction ID
//     mapping(address => uint256) public leaders;

//     // faction ID => faction
//     mapping(uint256 => Faction) public factions;

//     // address => boolean
//     mapping(address => bool) public bloodPact;

//     address public hunting;
//     address public tokyoRebels;
//     address public backgrounds;

//     event AuthorizeLeader(address indexed leader);
//     event AuthorizeKami(address indexed kami);
//     event CreateFaction(address indexed leader, uint256 indexed limit, uint256 indexed space);

//     error NotKami();
//     error OnHuntingPeriod();
//     error RebelNotHunting();
//     error TenImmunity();
//     error NotALeader();
//     error AlreadyPartOfAFaction();
//     error NotBackgroundOwner();

//     modifier onlyKami() {
//         if (!kami[msg.sender]) revert NotKami();
//         _;
//     }

//     modifier onlyLeader() {
//         if (leaders[msg.sender] == 0) revert NotALeader();
//         _;
//     }

//     constructor(
//         address _kami,
//         address _tokyoRebels,
//         address _hunting,
//         string memory _hordeLogo
//     ) {
//         kami[_kami] = true;
//         tokyoRebels = _tokyoRebels;
//         hunting = _hunting;
//         leaders[_kami] = 1;
//         address[] memory members = new address[](1);
//         members[0] = _kami;
//         factions[1] = Faction(_kami, 10000, 0, "Horde", _hordeLogo, members);
//     }

//     function tokensOfOwner(address _account) public view returns (uint256[] memory ownerTokens) {
//         uint256[] memory owned = IERC721AQueryable(tokyoRebels).tokensOfOwner(_account);

//         uint256[] memory inHunting = IHunting(hunting).tokensOfOwner(_account);

//         uint256[] memory tokens = new uint256[](owned.length + inHunting.length);

//         uint256 i = 0;
//         for (; i < owned.length; i++) {
//             tokens[i] = owned[i];
//         }

//         uint256 j = 0;
//         while (j < inHunting.length) {
//             tokens[i++] = inHunting[j++];
//         }
//         return tokens;
//     }

//     function setKami(address _kami, bool _boolean) external onlyOwner {
//         kami[_kami] = _boolean;
//         emit AuthorizeKami(_kami);
//     }

//     function setLeader(address _leader, uint256 _factionId) external onlyKami {
//         leaders[_leader] = _factionId;
//         emit AuthorizeLeader(_leader);
//     }

//     function setHunting(address _hunting) public onlyOwner {
//         hunting = _hunting;
//     }

//     function createFaction(
//         uint256 _limit,
//         uint256 _background,
//         string memory _name,
//         string memory _logo
//     ) external onlyLeader {
//         address leader = msg.sender;
//         uint256 factionId = leaders[msg.sender];
//         address[] memory members;
//         members[0] = leader;
//         if (_background > 0) {
//             if (IERC721A(backgrounds).ownerOf(_background) != leader) revert NotBackgroundOwner();
//         }
//         factions[factionId] = Faction(leader, _limit, _background, _name, _logo, members);
//         emit CreateFaction(leader, _limit, _background);
//     }

//     function editFaction(
//         uint256 _limit,
//         uint256 _background,
//         string memory _name,
//         string memory _logo
//     ) external onlyLeader {
//         address leader = msg.sender;
//         uint256 factionId = leaders[leader];
//         Faction storage faction = factions[factionId];
//         if (_background > 0) {
//             if (IERC721A(backgrounds).ownerOf(_background) != leader)
//                 revert NotBackgroundOwner();
//         }
//         faction.limit = _limit;
//         faction.background = _background;
//         faction.name = _name;
//         faction.logo = _logo;
//     }

//     function joinFaction(uint256 _factionId) external {
//         if (!bloodPact[msg.sender]) revert AlreadyPartOfAFaction();
//         bloodPact[msg.sender] = true;
//         factions[_factionId].members.push(msg.sender);
//     }

//     function destroyFaction(uint256 _factionId) public onlyKami {
//         address[] memory members = factions[_factionId].members;

//         for (uint256 i = 0; i < members.length; i++) {
//             bloodPact[members[i]] = false;
//         }

//         delete factions[_factionId];
//     }
// }

// SPDX-License-Identifier: MIT AND BSD-3-Clause

pragma solidity >=0.8.9 <0.9.0;

// ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
// ██ ██ █ ██ █ ▄▄▀█▄ ▄██▄██ ▄▄▀█ ▄▄▄
// ██ ▄▄ █ ██ █ ██ ██ ███ ▄█ ██ █ █▄▀
// ██ ██ ██▄▄▄█▄██▄██▄██▄▄▄█▄██▄█▄▄▄▄
// ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
//            contract by: primata 🐵

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "lib/ERC721A/contracts/interfaces/IERC721AQueryable.sol";

import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "./interfaces/IMercenaryMarket.sol";
import "./DateTime.sol";

import "hardhat/console.sol";

contract Hunting is IERC721Receiver, OwnableUpgradeable {
    using DateTimeLibrary for uint256;

    enum Auction {
        Dutch,
        English
    }
    Auction public auctionType;

    // authorized managers
    mapping(uint256 => bool) public aTen;
    mapping(address => bool) public wish;
    // number of tokens per address on hunting
    mapping(address => uint256) public huntingPerOwner;
    // tokenId => owner
    mapping(uint256 => address) public hunting;

    address public tokyoRebels;
    address public kami;
    address public vault;
    address public hordeAndFactions;
    address public mercenaryMarket;
    address public WETH;
    uint256 public maxHunting;
    uint256 public dayLimit;
    uint256 public dutchAuctionDivisor;

    event Hunt(uint256 indexed tokenId, address indexed owner);
    event Retreat(uint256 indexed tokenId, address indexed owner);
    event Capture(uint256 indexed tokenId, address indexed owner);
    event SwitchSides(uint256 indexed tokenId, address indexed owner);

    error NotKami();
    error NotOwner();
    error OnHuntingPeriod();
    error NotHuntingOrNotOwner();
    error NotHunting();
    error NoWishAvailable();
    error AboveMaxHunting();
    error TenImmunity();
    error MercenaryMarketNotSet();

    modifier onlyKami() {
        if (kami != msg.sender) revert NotKami();
        _;
    }

    modifier notATen(uint256 _tokenId) {
        if (aTen[_tokenId]) revert TenImmunity();
        _;
    }

    modifier onlyCooldown() {
        uint256 weekday = DateTimeLibrary.getDayOfWeek(block.timestamp);
        if (weekday > dayLimit) revert OnHuntingPeriod();
        _;
    }

    function initialize(
        address _kami,
        address _vault,
        address _tokyoRebels,
        address _weth
    ) public initializer {
        __Ownable_init();
        kami = _kami;
        vault = _vault;
        tokyoRebels = _tokyoRebels;
        WETH = _weth;
        maxHunting = 1;
        dayLimit = 4;
        auctionType = Auction.Dutch;
        dutchAuctionDivisor = 10;
    }

    /**
     * @notice Returns array of token IDs of `account` owned by `account` in possession of the contract.
     *
     * @param account address of the owner
     *
     * @return tokens array of token IDs
     */
    function tokensOfOwner(address account) external view returns (uint256[] memory tokens) {
        uint256 supply = IERC721AQueryable(tokyoRebels).totalSupply();
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (hunting[tokenId] == account) {
                tmp[index] = tokenId;
                index += 1;
            }
        }

        tokens = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setMaxHunting(uint256 _maxHunting) external onlyOwner {
        maxHunting = _maxHunting;
    }

    function setTens(uint256[] calldata _tokenIds) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            aTen[_tokenIds[i]] = true;
        }
    }

    function setMercenaryMarket(address _mercenaryMarket) external onlyOwner {
        mercenaryMarket = _mercenaryMarket;
    }

    function setTokyoRebels(address _tokyoRebels) external onlyOwner {
        tokyoRebels = _tokyoRebels;
    }

    function setHordeAndFactions(address _hordeAndFactions) external onlyOwner {
        hordeAndFactions = _hordeAndFactions;
    }

    function setAuctionMode(uint256 _auctionType) external onlyOwner {
        auctionType = Auction(_auctionType);
    }

    function setDayLimit(uint256 _dayLimit) external onlyOwner {
        dayLimit = _dayLimit;
    }

    function setAuctionDivisor(uint256 _dutchAuctionDivisor) external onlyOwner {
        dutchAuctionDivisor = _dutchAuctionDivisor;
    }

    /**
     * @notice Stakes tokens to hunting contract
     *
     * @param _tokenIds token ID array to stake
     */
    function hunt(uint256[] calldata _tokenIds) external {
        if (maxHunting < huntingPerOwner[msg.sender] + _tokenIds.length) revert AboveMaxHunting();
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _hunt(_tokenIds[i]);
        }
    }

    /**
     * @notice Unstakes tokens from hunting contract. Only available on cooldown period.
     *
     * @param _tokenIds token ID array to unstake
     */
    function retreat(uint256[] calldata _tokenIds) external onlyCooldown {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _retreat(_tokenIds[i]);
        }
    }

    /**
     * @notice Transfers staked token Id to the vault address or starts an auction
     *
     * @param _tokenId token ID to transfer
     * @param _auctionPrice auction price to start. If 0, sent directly to vault
     */
    function capture(uint256 _tokenId, uint256 _auctionPrice) external onlyKami {
        _capture(_tokenId, _auctionPrice);
    }

    /**
     * @notice Transfers staked token Id to a new owner address
     *
     * @param _tokenId token ID to transfer
     * @param _newOwner new owner address
     */
    function switchSides(uint256 _tokenId, address _newOwner) external onlyKami {
        _switchSides(_tokenId, _newOwner);
    }

    /**
     * @notice Makes a wish to the Kamis. If the sender has a wish, the token is transferred to the vault address or starts an auction
     *
     * @param _tokenId token ID to transfer
     * @param _auctionPrice auction price to start. If 0, sent directly to vault
     */
    function makeWish(uint256 _tokenId, uint256 _auctionPrice) external notATen(_tokenId) {
        if (!wish[msg.sender]) revert NoWishAvailable();
        wish[msg.sender] = false;
        _capture(_tokenId, _auctionPrice);
    }

    /**
     * @notice Grants a wish to an address
     *
     * @param _blessed address to grant wish
     */
    function grantWish(address _blessed) external onlyKami {
        wish[_blessed] = true;
    }

    function _capture(uint256 _tokenId, uint256 _auctionPrice) internal {
        if (hunting[_tokenId] == address(0)) revert NotHunting();
        delete hunting[_tokenId];
        console.log(_auctionPrice);
        if (_auctionPrice == 0) {
            IERC721AQueryable(tokyoRebels).transferFrom(address(this), vault, _tokenId);
        } else {
            _auction(_tokenId, _auctionPrice);
        }
        emit Capture(_tokenId, msg.sender);
    }

    function _switchSides(uint256 _tokenId, address _newOwner) internal {
        if (hunting[_tokenId] == address(0)) revert NotHunting();
        hunting[_tokenId] = _newOwner;
        emit SwitchSides(_tokenId, _newOwner);
    }

    function _hunt(uint256 _tokenId) internal {
        if (IERC721AQueryable(tokyoRebels).ownerOf(_tokenId) != msg.sender) revert NotOwner();
        huntingPerOwner[msg.sender]++;
        hunting[_tokenId] = msg.sender;
        IERC721AQueryable(tokyoRebels).transferFrom(msg.sender, address(this), _tokenId);

        emit Hunt(_tokenId, msg.sender);
    }

    function _retreat(uint256 _tokenId) internal {
        if (hunting[_tokenId] != msg.sender) revert NotHuntingOrNotOwner();
        huntingPerOwner[msg.sender]--;
        delete hunting[_tokenId];
        IERC721AQueryable(tokyoRebels).transferFrom(address(this), msg.sender, _tokenId);

        emit Retreat(_tokenId, msg.sender);
    }

    function _auction(uint256 _tokenId, uint256 _auctionPrice) internal {
        if (mercenaryMarket == address(0)) revert MercenaryMarketNotSet();
        IERC721AQueryable(tokyoRebels).approve(mercenaryMarket, _tokenId);

        if (auctionType == Auction.Dutch) {
            IMercenaryMarket(mercenaryMarket).startDutchAuction(
                IERC721(tokyoRebels),
                _tokenId,
                IERC20(WETH),
                1 days,
                2 minutes,
                _auctionPrice,
                _auctionPrice / dutchAuctionDivisor
            );
        } else {
            IMercenaryMarket(mercenaryMarket).startEnglishAuction(
                IERC721(tokyoRebels),
                _tokenId,
                IERC20(WETH),
                1 days,
                _auctionPrice
            );
        }
    }
}

// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// interface ICurrencyManager {
//     function addCurrency(address currency) external;

//     function removeCurrency(address currency) external;

//     function isCurrencyWhitelisted(address currency)
//         external
//         view
//         returns (bool);

//     function viewWhitelistedCurrencies(uint256 cursor, uint256 size)
//         external
//         view
//         returns (address[] memory, uint256);

//     function viewCountWhitelistedCurrencies() external view returns (uint256);
// }

// pragma solidity >=0.8.9 <0.9.0;

// interface IHunting {
//     function tokensOfOwner(address _account) external view returns (uint256[] memory ownerTokens);
// }

pragma solidity >=0.8.9 <0.9.0;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


interface IMercenaryMarket {
    function startDutchAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _duration,
        uint256 _dropInterval,
        uint256 _startPrice,
        uint256 _endPrice
    ) external;

    function startEnglishAuction(
        IERC721 _collection,
        uint256 _tokenId,
        IERC20 _currency,
        uint96 _duration,
        uint256 _startPrice
    ) external;
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

// // SPDX-License-Identifier: MIT
// pragma solidity >=0.8.9 <0.9.0;

// // ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
// // ██ ▄▀▄ █ ▄▄█ ▄▄▀█▀▄▀█ ▄▄█ ▄▄▀█ ▄▄▀█ ▄▄▀█ ██ ████ ▄▀▄ █ ▄▄▀█ ▄▄▀█ █▀█ ▄▄█▄ ▄
// // ██ █ █ █ ▄▄█ ▀▀▄█ █▀█ ▄▄█ ██ █ ▀▀ █ ▀▀▄█ ▀▀ ████ █ █ █ ▀▀ █ ▀▀▄█ ▄▀█ ▄▄██ █
// // ██ ███ █▄▄▄█▄█▄▄██▄██▄▄▄█▄██▄█▄██▄█▄█▄▄█▀▀▀▄████ ███ █▄██▄█▄█▄▄█▄█▄█▄▄▄██▄█
// // ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
// //                                                     contract by: primata 🐵

// // MercenaryMarket.sol is a modified version of Joepegs's AuctionHouse.sol:
// // https://github.com/traderjoe-xyz/joepegs/blob/acf0ecf70577b9ad3a7969168f0f00e7ea375434/contracts/JoepegAuctionHouse.sol

// import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
// import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
// import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
// import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import {ICurrencyManager} from "./interfaces/ICurrencyManager.sol";
// import {IWETH} from "./interfaces/IWETH.sol";

// /**
//  * @title MercenaryMarket
//  * @notice An auction house that supports running English and Dutch auctions on ERC721 tokens
//  */
// contract MercenaryMarket is Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
//     using SafeCast for uint256;
//     using SafeERC20 for IERC20;

//     struct DutchAuction {
//         address creator;
//         uint96 startTime;
//         address currency;
//         uint96 endTime;
//         uint256 nonce;
//         uint256 startPrice;
//         uint256 endPrice;
//         uint256 dropInterval;
//     }

//     struct EnglishAuction {
//         address creator;
//         address currency;
//         uint96 startTime;
//         address lastBidder;
//         uint96 endTime;
//         uint256 nonce;
//         uint256 lastBidPrice;
//         uint256 startPrice;
//     }

//     uint256 public constant PERCENTAGE_PRECISION = 10000;

//     address public immutable WETH;

//     ICurrencyManager public currencyManager;
//     mapping(address => bool) public approved;

//     address public vault;

//     /// @notice Stores latest auction nonce per user
//     /// @dev (user address => latest nonce)
//     mapping(address => uint256) public userLatestAuctionNonce;

//     /// @notice Stores Dutch Auction data for NFTs
//     /// @dev (collection address => token id => dutch auction)
//     mapping(address => mapping(uint256 => DutchAuction)) public dutchAuctions;

//     /// @notice Stores English Auction data for NFTs
//     /// @dev (collection address => token id => english auction)
//     mapping(address => mapping(uint256 => EnglishAuction)) public englishAuctions;

//     /// @notice Required minimum percent increase from last bid in order to
//     /// place a new bid on an English Auction
//     uint256 public englishAuctionMinBidIncrementPct;

//     /// @notice Represents both:
//     /// - Number of seconds before an English Auction ends where any new
//     ///   bid will extend the auction's end time
//     /// - Number of seconds to extend an English Auction's end time by
//     uint96 public englishAuctionRefreshTime;

//     event DutchAuctionStart(
//         address indexed creator,
//         address currency,
//         address indexed collection,
//         uint256 indexed tokenId,
//         uint256 nonce,
//         uint256 startPrice,
//         uint256 endPrice,
//         uint96 startTime,
//         uint96 endTime,
//         uint256 dropInterval
//     );
//     event DutchAuctionSettle(
//         address indexed creator,
//         address buyer,
//         address currency,
//         address indexed collection,
//         uint256 indexed tokenId,
//         uint256 nonce,
//         uint256 price
//     );
//     event DutchAuctionCancel(
//         address indexed caller,
//         address creator,
//         address indexed collection,
//         uint256 indexed tokenId,
//         uint256 nonce
//     );

//     event EnglishAuctionStart(
//         address indexed creator,
//         address currency,
//         address indexed collection,
//         uint256 indexed tokenId,
//         uint256 nonce,
//         uint256 startPrice,
//         uint96 startTime,
//         uint96 endTime
//     );
//     event EnglishAuctionPlaceBid(
//         address indexed creator,
//         address bidder,
//         address currency,
//         address indexed collection,
//         uint256 indexed tokenId,
//         uint256 nonce,
//         uint256 bidAmount,
//         uint96 endTimeExtension
//     );
//     event EnglishAuctionSettle(
//         address indexed creator,
//         address buyer,
//         address currency,
//         address indexed collection,
//         uint256 indexed tokenId,
//         uint256 nonce,
//         uint256 price
//     );
//     event EnglishAuctionCancel(
//         address indexed caller,
//         address creator,
//         address indexed collection,
//         uint256 indexed tokenId,
//         uint256 nonce
//     );

//     event CurrencyManagerSet(
//         address indexed oldCurrencyManager,
//         address indexed newCurrencyManager
//     );
//     event EnglishAuctionMinBidIncrementPctSet(
//         uint256 indexed oldEnglishAuctionMinBidIncrementPct,
//         uint256 indexed newEnglishAuctionMinBidIncrementPct
//     );
//     event EnglishAuctionRefreshTimeSet(
//         uint96 indexed oldEnglishAuctionRefreshTime,
//         uint96 indexed newEnglishAuctionRefreshTime
//     );
//     event ProtocolFeeManagerSet(
//         address indexed oldProtocolFeeManager,
//         address indexed newProtocolFeeManager
//     );
//     event vaultSet(address indexed oldVault, address indexed newVault);
//     event ApprovalSet(address indexed oldAuctionManager, bool state);

//     event FlushedPayment(
//         address indexed collection,
//         uint256 indexed tokenId,
//         address indexed royaltyRecipient,
//         address currency,
//         uint256 amount
//     );

//     error MercenaryMarket__AuctionAlreadyExists();
//     error MercenaryMarket__CurrencyMismatch();
//     error MercenaryMarket__ExpectedNonNullAddress();
//     error MercenaryMarket__InvalidDropInterval();
//     error MercenaryMarket__InvalidDuration();
//     error MercenaryMarket__InvalidStartTime();
//     error MercenaryMarket__NoAuctionExists();
//     error MercenaryMarket__UnsupportedCurrency();
//     error MercenaryMarket__OnlyApproved();

//     error MercenaryMarket__EnglishAuctionCannotBidOnUnstartedAuction();
//     error MercenaryMarket__EnglishAuctionCannotBidOnEndedAuction();
//     error MercenaryMarket__EnglishAuctionCannotCancelWithExistingBid();
//     error MercenaryMarket__EnglishAuctionCannotSettleUnstartedAuction();
//     error MercenaryMarket__EnglishAuctionCannotSettleWithoutBid();
//     error MercenaryMarket__EnglishAuctionCreatorCannotPlaceBid();
//     error MercenaryMarket__EnglishAuctionInsufficientBidAmount();
//     error MercenaryMarket__EnglishAuctionInvalidMinBidIncrementPct();
//     error MercenaryMarket__EnglishAuctionInvalidRefreshTime();
//     error MercenaryMarket__EnglishAuctionOnlyCreatorCanSettleBeforeEndTime();

//     error MercenaryMarket__DutchAuctionCannotSettleUnstartedAuction();
//     error MercenaryMarket__DutchAuctionCreatorCannotSettle();
//     error MercenaryMarket__DutchAuctionInvalidStartEndPrice();

//     modifier isSupportedCurrency(IERC20 _currency) {
//         if (!currencyManager.isCurrencyWhitelisted(address(_currency))) {
//             revert MercenaryMarket__UnsupportedCurrency();
//         } else {
//             _;
//         }
//     }

//     modifier isValidStartTime(uint256 _startTime) {
//         if (_startTime < block.timestamp) {
//             revert MercenaryMarket__InvalidStartTime();
//         } else {
//             _;
//         }
//     }

//     modifier onlyApproved() {
//         if (!approved[msg.sender]) {
//             revert MercenaryMarket__OnlyApproved();
//         } else {
//             _;
//         }
//     }

//     ///  @notice Constructor
//     ///  @param _weth address of WETH
//     ///  @param _englishAuctionMinBidIncrementPct minimum bid increment percentage for English Auctions
//     ///  @param _englishAuctionRefreshTime refresh time for English auctions
//     ///  @param _currencyManager currency manager address
//     ///  @param _vault protocol fee recipient
//     constructor(
//         address _weth,
//         uint256 _englishAuctionMinBidIncrementPct,
//         uint96 _englishAuctionRefreshTime,
//         address _currencyManager,
//         address _hunting,
//         address _vault
//     ) {
//         WETH = _weth;
//         _updateEnglishAuctionMinBidIncrementPct(_englishAuctionMinBidIncrementPct);
//         _updateEnglishAuctionRefreshTime(_englishAuctionRefreshTime);
//         _updateCurrencyManager(_currencyManager);
//         _updateApproved(msg.sender, true);
//         _updateApproved(_hunting, true);
//         _updateVault(_vault);
//     }

//     /// @notice Required implementation for IERC721Receiver
//     function onERC721Received(
//         address,
//         address,
//         uint256,
//         bytes calldata
//     ) external pure returns (bytes4) {
//         return this.onERC721Received.selector;
//     }

//     /// @notice Starts an English Auction for an ERC721 token
//     /// @dev Note this requires the auction house to hold the ERC721 token in escrow
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     /// @param _currency address of currency to sell ERC721 token for
//     /// @param _duration number of seconds for English Auction to run
//     /// @param _startPrice minimum starting bid price
//     function startEnglishAuction(
//         IERC721 _collection,
//         uint256 _tokenId,
//         IERC20 _currency,
//         uint96 _duration,
//         uint256 _startPrice
//     ) external whenNotPaused isSupportedCurrency(_currency) nonReentrant {
//         _addEnglishAuction(
//             _collection,
//             _tokenId,
//             _currency,
//             block.timestamp.toUint96(),
//             _duration,
//             _startPrice
//         );
//     }

//     /// @notice Schedules an English Auction for an ERC721 token
//     /// @dev Note this requires the auction house to hold the ERC721 token in escrow
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     /// @param _currency address of currency to sell ERC721 token for
//     /// @param _startTime time to start the auction
//     /// @param _duration number of seconds for English Auction to run
//     /// @param _startPrice minimum starting bid price
//     function scheduleEnglishAuction(
//         IERC721 _collection,
//         uint256 _tokenId,
//         IERC20 _currency,
//         uint96 _startTime,
//         uint96 _duration,
//         uint256 _startPrice
//     )
//         external
//         whenNotPaused
//         isSupportedCurrency(_currency)
//         isValidStartTime(_startTime)
//         nonReentrant
//     {
//         _addEnglishAuction(_collection, _tokenId, _currency, _startTime, _duration, _startPrice);
//     }

//     function _addEnglishAuction(
//         IERC721 _collection,
//         uint256 _tokenId,
//         IERC20 _currency,
//         uint96 _startTime,
//         uint96 _duration,
//         uint256 _startPrice
//     ) internal onlyApproved {
//         if (_duration == 0) {
//             revert MercenaryMarket__InvalidDuration();
//         }
//         address collectionAddress = address(_collection);
//         if (englishAuctions[collectionAddress][_tokenId].creator != address(0)) {
//             revert MercenaryMarket__AuctionAlreadyExists();
//         }

//         uint256 nonce = userLatestAuctionNonce[msg.sender];
//         EnglishAuction memory auction = EnglishAuction({
//             creator: msg.sender,
//             nonce: nonce,
//             currency: address(_currency),
//             lastBidder: address(0),
//             lastBidPrice: 0,
//             startTime: _startTime,
//             endTime: _startTime + _duration,
//             startPrice: _startPrice
//         });
//         englishAuctions[collectionAddress][_tokenId] = auction;
//         userLatestAuctionNonce[msg.sender] = nonce + 1;

//         // Hold ERC721 token in escrow
//         _collection.safeTransferFrom(msg.sender, address(this), _tokenId);

//         emit EnglishAuctionStart(
//             auction.creator,
//             auction.currency,
//             collectionAddress,
//             _tokenId,
//             auction.nonce,
//             auction.startPrice,
//             _startTime,
//             auction.endTime
//         );
//     }

//     /// @notice Place bid on a running English Auction
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     /// @param _amount amount of currency to bid
//     function placeEnglishAuctionBid(
//         IERC721 _collection,
//         uint256 _tokenId,
//         uint256 _amount
//     ) external whenNotPaused nonReentrant {
//         EnglishAuction memory auction = englishAuctions[address(_collection)][_tokenId];
//         address currency = auction.currency;
//         if (currency == address(0)) {
//             revert MercenaryMarket__NoAuctionExists();
//         }

//         IERC20(currency).safeTransferFrom(msg.sender, address(this), _amount);
//         _placeEnglishAuctionBid(_collection, _tokenId, _amount, auction);
//     }

//     /// @notice Place bid on a running English Auction using AVAX and/or WETH
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     /// @param _wethAmount amount of WETH to bid
//     function placeEnglishAuctionBidWithETHAndWETH(
//         IERC721 _collection,
//         uint256 _tokenId,
//         uint256 _wethAmount
//     ) external payable whenNotPaused nonReentrant {
//         EnglishAuction memory auction = englishAuctions[address(_collection)][_tokenId];
//         address currency = auction.currency;
//         if (currency != WETH) {
//             revert MercenaryMarket__CurrencyMismatch();
//         }

//         if (msg.value > 0) {
//             // Wrap ETH into WETH
//             IWETH(WETH).deposit{value: msg.value}();
//         }
//         if (_wethAmount > 0) {
//             IERC20(WETH).safeTransferFrom(msg.sender, address(this), _wethAmount);
//         }
//         _placeEnglishAuctionBid(_collection, _tokenId, msg.value + _wethAmount, auction);
//     }

//     /// @notice Settles an English Auction
//     /// @dev Note:
//     /// - Can be called by creator at any time (including before the auction's end time to accept the
//     ///   current latest bid)
//     /// - Can be called by anyone after the auction ends
//     /// - Transfers funds and fees appropriately to seller, royalty receiver, and protocol fee recipient
//     /// - Transfers ERC721 token to last highest bidder
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     function settleEnglishAuction(
//         IERC721 _collection,
//         uint256 _tokenId
//     ) external whenNotPaused nonReentrant {
//         address collectionAddress = address(_collection);
//         EnglishAuction memory auction = englishAuctions[collectionAddress][_tokenId];
//         if (auction.creator == address(0)) {
//             revert MercenaryMarket__NoAuctionExists();
//         }
//         if (auction.lastBidPrice == 0) {
//             revert MercenaryMarket__EnglishAuctionCannotSettleWithoutBid();
//         }
//         if (block.timestamp < auction.startTime) {
//             revert MercenaryMarket__EnglishAuctionCannotSettleUnstartedAuction();
//         }
//         if (!approved[msg.sender] && block.timestamp < auction.endTime) {
//             revert MercenaryMarket__EnglishAuctionOnlyCreatorCanSettleBeforeEndTime();
//         }

//         delete englishAuctions[collectionAddress][_tokenId];

//         // Settle auction using latest bid
//         _transferFeesAndFunds(
//             collectionAddress,
//             _tokenId,
//             IERC20(auction.currency),
//             address(this),
//             auction.lastBidPrice
//         );

//         _collection.safeTransferFrom(address(this), auction.lastBidder, _tokenId);

//         emit EnglishAuctionSettle(
//             auction.creator,
//             auction.lastBidder,
//             auction.currency,
//             collectionAddress,
//             _tokenId,
//             auction.nonce,
//             auction.lastBidPrice
//         );
//     }

//     /// @notice Cancels an English Auction
//     /// @dev Note:
//     /// - Can only be called by auction creator
//     /// - Can only be cancelled if no bids have been placed
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     function cancelEnglishAuction(
//         IERC721 _collection,
//         uint256 _tokenId
//     ) external whenNotPaused nonReentrant onlyApproved {
//         address collectionAddress = address(_collection);
//         EnglishAuction memory auction = englishAuctions[collectionAddress][_tokenId];

//         if (auction.lastBidder != address(0)) {
//             revert MercenaryMarket__EnglishAuctionCannotCancelWithExistingBid();
//         }

//         delete englishAuctions[collectionAddress][_tokenId];

//         _collection.safeTransferFrom(address(this), vault, _tokenId);

//         emit EnglishAuctionCancel(
//             msg.sender,
//             auction.creator,
//             collectionAddress,
//             _tokenId,
//             auction.nonce
//         );
//     }

//     /// @notice Only owner function to cancel an English Auction in case of emergencies
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     function emergencyCancelEnglishAuction(
//         IERC721 _collection,
//         uint256 _tokenId
//     ) external nonReentrant onlyOwner {
//         address collectionAddress = address(_collection);
//         EnglishAuction memory auction = englishAuctions[collectionAddress][_tokenId];
//         if (auction.creator == address(0)) {
//             revert MercenaryMarket__NoAuctionExists();
//         }

//         address lastBidder = auction.lastBidder;
//         uint256 lastBidPrice = auction.lastBidPrice;

//         delete englishAuctions[collectionAddress][_tokenId];

//         _collection.safeTransferFrom(address(this), vault, _tokenId);

//         if (lastBidPrice > 0) {
//             IERC20(auction.currency).safeTransfer(lastBidder, lastBidPrice);
//         }

//         emit EnglishAuctionCancel(
//             msg.sender,
//             auction.creator,
//             collectionAddress,
//             _tokenId,
//             auction.nonce
//         );
//     }

//     /// @notice Starts a Dutch Auction for an ERC721 token
//     /// @dev Note:
//     /// - Requires the auction house to hold the ERC721 token in escrow
//     /// - Drops in price every `dutchAuctionDropInterval` seconds in equal
//     ///   amounts
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     /// @param _currency address of currency to sell ERC721 token for
//     /// @param _duration number of seconds for Dutch Auction to run
//     /// @param _dropInterval number of seconds between each drop in price
//     /// @param _startPrice starting sell price
//     /// @param _endPrice ending sell price
//     function startDutchAuction(
//         IERC721 _collection,
//         uint256 _tokenId,
//         IERC20 _currency,
//         uint96 _duration,
//         uint256 _dropInterval,
//         uint256 _startPrice,
//         uint256 _endPrice
//     ) external whenNotPaused isSupportedCurrency(_currency) nonReentrant {
//         _addDutchAuction(
//             _collection,
//             _tokenId,
//             _currency,
//             block.timestamp.toUint96(),
//             _duration,
//             _dropInterval,
//             _startPrice,
//             _endPrice
//         );
//     }

//     /// @notice Schedules a Dutch Auction for an ERC721 token
//     /// @dev Note:
//     /// - Requires the auction house to hold the ERC721 token in escrow
//     /// - Drops in price every `dutchAuctionDropInterval` seconds in equal
//     ///   amounts
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     /// @param _currency address of currency to sell ERC721 token for
//     /// @param _startTime time to start the auction
//     /// @param _duration number of seconds for Dutch Auction to run
//     /// @param _dropInterval number of seconds between each drop in price
//     /// @param _startPrice starting sell price
//     /// @param _endPrice ending sell price
//     function scheduleDutchAuction(
//         IERC721 _collection,
//         uint256 _tokenId,
//         IERC20 _currency,
//         uint96 _startTime,
//         uint96 _duration,
//         uint256 _dropInterval,
//         uint256 _startPrice,
//         uint256 _endPrice
//     )
//         external
//         whenNotPaused
//         isSupportedCurrency(_currency)
//         isValidStartTime(_startTime)
//         nonReentrant
//     {
//         _addDutchAuction(
//             _collection,
//             _tokenId,
//             _currency,
//             _startTime,
//             _duration,
//             _dropInterval,
//             _startPrice,
//             _endPrice
//         );
//     }

//     function _addDutchAuction(
//         IERC721 _collection,
//         uint256 _tokenId,
//         IERC20 _currency,
//         uint96 _startTime,
//         uint96 _duration,
//         uint256 _dropInterval,
//         uint256 _startPrice,
//         uint256 _endPrice
//     ) internal onlyApproved {
//         if (_duration == 0 || _duration < _dropInterval) {
//             revert MercenaryMarket__InvalidDuration();
//         }
//         if (_dropInterval == 0) {
//             revert MercenaryMarket__InvalidDropInterval();
//         }
//         address collectionAddress = address(_collection);
//         if (dutchAuctions[collectionAddress][_tokenId].creator != address(0)) {
//             revert MercenaryMarket__AuctionAlreadyExists();
//         }
//         if (_startPrice <= _endPrice || _endPrice == 0) {
//             revert MercenaryMarket__DutchAuctionInvalidStartEndPrice();
//         }

//         DutchAuction memory auction = DutchAuction({
//             creator: msg.sender,
//             nonce: userLatestAuctionNonce[msg.sender],
//             currency: address(_currency),
//             startPrice: _startPrice,
//             endPrice: _endPrice,
//             startTime: _startTime,
//             endTime: _startTime + _duration,
//             dropInterval: _dropInterval
//         });
//         dutchAuctions[collectionAddress][_tokenId] = auction;
//         userLatestAuctionNonce[msg.sender] += 1;

//         _collection.safeTransferFrom(msg.sender, address(this), _tokenId);

//         emit DutchAuctionStart(
//             auction.creator,
//             auction.currency,
//             collectionAddress,
//             _tokenId,
//             auction.nonce,
//             auction.startPrice,
//             auction.endPrice,
//             auction.startTime,
//             auction.endTime,
//             auction.dropInterval
//         );
//     }

//     /// @notice Settles a Dutch Auction
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     function settleDutchAuction(
//         IERC721 _collection,
//         uint256 _tokenId
//     ) external whenNotPaused nonReentrant {
//         DutchAuction memory auction = dutchAuctions[address(_collection)][_tokenId];
//         _settleDutchAuction(_collection, _tokenId, auction);
//     }

//     /// @notice Settles a Dutch Auction with ETH and/or WETH
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     function settleDutchAuctionWithETHAndWETH(
//         IERC721 _collection,
//         uint256 _tokenId
//     ) external payable whenNotPaused nonReentrant {
//         DutchAuction memory auction = dutchAuctions[address(_collection)][_tokenId];
//         address currency = auction.currency;
//         if (currency != WETH) {
//             revert MercenaryMarket__CurrencyMismatch();
//         }

//         _settleDutchAuction(_collection, _tokenId, auction);
//     }

//     /// @notice Calculates current Dutch Auction sale price for an ERC721 token.
//     /// Returns 0 if the auction hasn't started yet.
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     /// @return current Dutch Auction sale price for specified ERC721 token
//     function getDutchAuctionSalePrice(
//         address _collection,
//         uint256 _tokenId
//     ) public view returns (uint256) {
//         DutchAuction memory auction = dutchAuctions[_collection][_tokenId];
//         if (block.timestamp < auction.startTime) {
//             return 0;
//         }
//         if (block.timestamp >= auction.endTime) {
//             return auction.endPrice;
//         }
//         uint256 timeElapsed = block.timestamp - auction.startTime;
//         uint256 elapsedSteps = timeElapsed / auction.dropInterval;
//         uint256 totalPossibleSteps = (auction.endTime - auction.startTime) / auction.dropInterval;

//         uint256 priceDifference = auction.startPrice - auction.endPrice;

//         return auction.startPrice - (elapsedSteps * priceDifference) / totalPossibleSteps;
//     }

//     /// @notice Cancels a running Dutch Auction
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     function cancelDutchAuction(
//         IERC721 _collection,
//         uint256 _tokenId
//     ) external whenNotPaused nonReentrant onlyApproved {
//         address collectionAddress = address(_collection);
//         DutchAuction memory auction = dutchAuctions[collectionAddress][_tokenId];

//         delete dutchAuctions[collectionAddress][_tokenId];

//         _collection.safeTransferFrom(address(this), vault, _tokenId);

//         emit DutchAuctionCancel(
//             msg.sender,
//             auction.creator,
//             collectionAddress,
//             _tokenId,
//             auction.nonce
//         );
//     }

//     /// @notice Only owner function to cancel a Dutch Auction in case of emergencies
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     function emergencyCancelDutchAuction(
//         IERC721 _collection,
//         uint256 _tokenId
//     ) external nonReentrant onlyOwner {
//         address collectionAddress = address(_collection);
//         DutchAuction memory auction = dutchAuctions[collectionAddress][_tokenId];
//         if (auction.creator == address(0)) {
//             revert MercenaryMarket__NoAuctionExists();
//         }

//         delete dutchAuctions[collectionAddress][_tokenId];

//         _collection.safeTransferFrom(address(this), vault, _tokenId);

//         emit DutchAuctionCancel(
//             msg.sender,
//             auction.creator,
//             collectionAddress,
//             _tokenId,
//             auction.nonce
//         );
//     }

//     /// @notice Update `englishAuctionMinBidIncrementPct`
//     /// @param _englishAuctionMinBidIncrementPct new minimum bid increment percetange for English auctions
//     function updateEnglishAuctionMinBidIncrementPct(
//         uint256 _englishAuctionMinBidIncrementPct
//     ) external onlyOwner {
//         _updateEnglishAuctionMinBidIncrementPct(_englishAuctionMinBidIncrementPct);
//     }

//     /// @notice Update `englishAuctionMinBidIncrementPct`
//     /// @param _englishAuctionMinBidIncrementPct new minimum bid increment percetange for English auctions
//     function _updateEnglishAuctionMinBidIncrementPct(
//         uint256 _englishAuctionMinBidIncrementPct
//     ) internal {
//         if (
//             _englishAuctionMinBidIncrementPct == 0 ||
//             _englishAuctionMinBidIncrementPct > PERCENTAGE_PRECISION
//         ) {
//             revert MercenaryMarket__EnglishAuctionInvalidMinBidIncrementPct();
//         }

//         uint256 oldEnglishAuctionMinBidIncrementPct = englishAuctionMinBidIncrementPct;
//         englishAuctionMinBidIncrementPct = _englishAuctionMinBidIncrementPct;
//         emit EnglishAuctionMinBidIncrementPctSet(
//             oldEnglishAuctionMinBidIncrementPct,
//             _englishAuctionMinBidIncrementPct
//         );
//     }

//     /// @notice Update `englishAuctionRefreshTime`
//     /// @param _englishAuctionRefreshTime new refresh time for English auctions
//     function updateEnglishAuctionRefreshTime(uint96 _englishAuctionRefreshTime) external onlyOwner {
//         _updateEnglishAuctionRefreshTime(_englishAuctionRefreshTime);
//     }

//     /// @notice Update `englishAuctionRefreshTime`
//     /// @param _englishAuctionRefreshTime new refresh time for English auctions
//     function _updateEnglishAuctionRefreshTime(uint96 _englishAuctionRefreshTime) internal {
//         if (_englishAuctionRefreshTime == 0) {
//             revert MercenaryMarket__EnglishAuctionInvalidRefreshTime();
//         }
//         uint96 oldEnglishAuctionRefreshTime = englishAuctionRefreshTime;
//         englishAuctionRefreshTime = _englishAuctionRefreshTime;
//         emit EnglishAuctionRefreshTimeSet(oldEnglishAuctionRefreshTime, englishAuctionRefreshTime);
//     }

//     /// @notice Update currency manager
//     /// @param _currencyManager new currency manager address
//     function updateCurrencyManager(address _currencyManager) external onlyOwner {
//         _updateCurrencyManager(_currencyManager);
//     }

//     /// @notice Update currency manager
//     /// @param _currencyManager new currency manager address
//     function _updateCurrencyManager(address _currencyManager) internal {
//         if (_currencyManager == address(0)) {
//             revert MercenaryMarket__ExpectedNonNullAddress();
//         }
//         address oldCurrencyManagerAddress = address(currencyManager);
//         currencyManager = ICurrencyManager(_currencyManager);
//         emit CurrencyManagerSet(oldCurrencyManagerAddress, _currencyManager);
//     }

//     /// @notice Update protocol fee recipient
//     /// @param _vault new recipient for protocol fees
//     function updateVault(address _vault) external onlyOwner {
//         _updateVault(_vault);
//     }

//     /// @notice Update protocol fee recipient
//     /// @param _vault new recipient for protocol fees
//     function _updateVault(address _vault) internal {
//         if (_vault == address(0)) {
//             revert MercenaryMarket__ExpectedNonNullAddress();
//         }
//         address oldvault = vault;
//         vault = _vault;
//         emit vaultSet(oldvault, _vault);
//     }

//     /// @notice Update royalty fee manager
//     /// @param _approved new fee manager address
//     function addApproved(address _approved) external onlyOwner {
//         _updateApproved(_approved, true);
//     }

//     /// @notice Update royalty fee manager
//     /// @param _approved new fee manager address
//     function removeApproved(address _approved) external onlyOwner {
//         _updateApproved(_approved, false);
//     }

//     /// @notice Update auction manager
//     /// @param _approved new auction manager address
//     function _updateApproved(address _approved, bool _state) internal {
//         if (_approved == address(0)) {
//             revert MercenaryMarket__ExpectedNonNullAddress();
//         }

//         approved[_approved] = _state;
//         emit ApprovalSet(_approved, _state);
//     }

//     /// @notice Place bid on a running English Auction
//     /// @dev Note:
//     /// - Requires holding the bid in escrow until either a higher bid is placed
//     ///   or the auction is settled
//     /// - If a bid already exists, only bids at least `englishAuctionMinBidIncrementPct`
//     ///   percent higher can be placed
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     /// @param _bidAmount amount of currency to bid
//     function _placeEnglishAuctionBid(
//         IERC721 _collection,
//         uint256 _tokenId,
//         uint256 _bidAmount,
//         EnglishAuction memory auction
//     ) internal {
//         if (auction.creator == address(0)) {
//             revert MercenaryMarket__NoAuctionExists();
//         }
//         if (_bidAmount == 0) {
//             revert MercenaryMarket__EnglishAuctionInsufficientBidAmount();
//         }
//         if (msg.sender == auction.creator) {
//             revert MercenaryMarket__EnglishAuctionCreatorCannotPlaceBid();
//         }
//         if (block.timestamp < auction.startTime) {
//             revert MercenaryMarket__EnglishAuctionCannotBidOnUnstartedAuction();
//         }
//         if (block.timestamp >= auction.endTime) {
//             revert MercenaryMarket__EnglishAuctionCannotBidOnEndedAuction();
//         }

//         uint96 endTimeExtension;
//         if (auction.endTime - block.timestamp <= englishAuctionRefreshTime) {
//             endTimeExtension = englishAuctionRefreshTime;
//             auction.endTime += endTimeExtension;
//         }

//         if (auction.lastBidPrice == 0) {
//             if (_bidAmount < auction.startPrice) {
//                 revert MercenaryMarket__EnglishAuctionInsufficientBidAmount();
//             }
//             auction.lastBidder = msg.sender;
//             auction.lastBidPrice = _bidAmount;
//         } else {
//             if (msg.sender == auction.lastBidder) {
//                 // If bidder is same as last bidder, ensure their bid is at least
//                 // `englishAuctionMinBidIncrementPct` percent of their previous bid
//                 if (
//                     _bidAmount * PERCENTAGE_PRECISION <
//                     auction.lastBidPrice * englishAuctionMinBidIncrementPct
//                 ) {
//                     revert MercenaryMarket__EnglishAuctionInsufficientBidAmount();
//                 }
//                 auction.lastBidPrice += _bidAmount;
//             } else {
//                 // Ensure bid is at least `englishAuctionMinBidIncrementPct` percent greater
//                 // than last bid
//                 if (
//                     _bidAmount * PERCENTAGE_PRECISION <
//                     auction.lastBidPrice * (PERCENTAGE_PRECISION + englishAuctionMinBidIncrementPct)
//                 ) {
//                     revert MercenaryMarket__EnglishAuctionInsufficientBidAmount();
//                 }

//                 address previousBidder = auction.lastBidder;
//                 uint256 previousBidPrice = auction.lastBidPrice;

//                 auction.lastBidder = msg.sender;
//                 auction.lastBidPrice = _bidAmount;

//                 // Transfer previous bid back to bidder
//                 IERC20(auction.currency).safeTransfer(previousBidder, previousBidPrice);
//             }
//         }

//         address collectionAddress = address(_collection);
//         englishAuctions[collectionAddress][_tokenId] = auction;

//         emit EnglishAuctionPlaceBid(
//             auction.creator,
//             auction.lastBidder,
//             auction.currency,
//             collectionAddress,
//             _tokenId,
//             auction.nonce,
//             auction.lastBidPrice,
//             endTimeExtension
//         );
//     }

//     /// @notice Settles a Dutch Auction
//     /// @dev Note:
//     /// - Transfers funds and fees appropriately to seller, royalty receiver, and protocol fee recipient
//     /// - Transfers ERC721 token to buyer
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     function _settleDutchAuction(
//         IERC721 _collection,
//         uint256 _tokenId,
//         DutchAuction memory _auction
//     ) internal {
//         if (_auction.creator == address(0)) {
//             revert MercenaryMarket__NoAuctionExists();
//         }
//         if (msg.sender == _auction.creator) {
//             revert MercenaryMarket__DutchAuctionCreatorCannotSettle();
//         }
//         if (block.timestamp < _auction.startTime) {
//             revert MercenaryMarket__DutchAuctionCannotSettleUnstartedAuction();
//         }

//         // Get auction sale price
//         address collectionAddress = address(_collection);
//         uint256 salePrice = getDutchAuctionSalePrice(collectionAddress, _tokenId);

//         delete dutchAuctions[collectionAddress][_tokenId];

//         if (_auction.currency == WETH) {
//             // Transfer WETH if needed
//             if (salePrice > msg.value) {
//                 IERC20(WETH).transferFrom(msg.sender, address(this), salePrice - msg.value);
//             }

//             // Wrap ETH if needed
//             if (msg.value > 0) {
//                 IWETH(WETH).deposit{value: msg.value}();
//             }

//             // Refund excess ETH if needed
//             if (salePrice < msg.value) {
//                 IERC20(WETH).transfer(msg.sender, msg.value - salePrice);
//             }

//             _transferFeesAndFunds(
//                 collectionAddress,
//                 _tokenId,
//                 IERC20(WETH),
//                 address(this),
//                 salePrice
//             );
//         } else {
//             _transferFeesAndFunds(
//                 collectionAddress,
//                 _tokenId,
//                 IERC20(_auction.currency),
//                 msg.sender,
//                 salePrice
//             );
//         }

//         _collection.safeTransferFrom(address(this), msg.sender, _tokenId);

//         emit DutchAuctionSettle(
//             _auction.creator,
//             msg.sender,
//             _auction.currency,
//             collectionAddress,
//             _tokenId,
//             _auction.nonce,
//             salePrice
//         );
//     }

//     /// @notice Transfer fees and funds to royalty recipient, protocol, and seller
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     /// @param _currency address of token being used for the purchase (e.g. USDC)
//     /// @param _from sender of the funds
//     /// @param _amount amount being transferred (in currency)
//     function _transferFeesAndFunds(
//         address _collection,
//         uint256 _tokenId,
//         IERC20 _currency,
//         address _from,
//         uint256 _amount
//     ) internal {
//         // Initialize the final amount that is transferred to seller

//         _currency.safeTransferFrom(_from, vault, _amount);

//         emit FlushedPayment(_collection, _tokenId, vault, address(_currency), _amount);
//     }
// }

// // SPDX-License-Identifier: MIT AND BSD-3-Clause

// pragma solidity >=0.8.9 <0.9.0;

// // █▀▀██▀▀█         ▀██                           ▀██▀▀█▄           ▀██              ▀██
// //    ██      ▄▄▄    ██  ▄▄   ▄▄▄▄ ▄▄▄   ▄▄▄       ██   ██    ▄▄▄▄   ██ ▄▄▄    ▄▄▄▄   ██   ▄▄▄▄
// //    ██    ▄█  ▀█▄  ██ ▄▀     ▀█▄  █  ▄█  ▀█▄     ██▀▀█▀   ▄█▄▄▄██  ██▀  ██ ▄█▄▄▄██  ██  ██▄ ▀
// //    ██    ██   ██  ██▀█▄      ▀█▄█   ██   ██     ██   █▄  ██       ██    █ ██       ██  ▄ ▀█▄▄
// //   ▄██▄    ▀█▄▄█▀ ▄██▄ ██▄     ▀█     ▀█▄▄█▀    ▄██▄  ▀█▀  ▀█▄▄▄▀  ▀█▄▄▄▀   ▀█▄▄▄▀ ▄██▄ █▀▄▄█▀
// //                            ▄▄ █                                       contract by: primata 🐵
// //                             ▀▀

// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// contract NoodleShop is IERC721Receiver, OwnableUpgradeable {
//     struct Job {
//         address owner;
//         uint256 jobId;
//         uint256 deadline;
//         uint256 payment;
//     }

//     struct ComplexJob {
//         address owner;
//         uint256 jobId;
//         uint256 deadline;
//         uint256 payment;
//         address[] nftAddresses;
//         uint256[] nftTokenIds;
//         string description;
//         address fullfiler;
//     }

//     uint256 public jobCounter;
//     mapping(uint256 => Job) public complexJobs;
//     mapping(uint256 => Job) public jobs;

//     address protocolFeeRecipient;

//     function initialize(address _protocolFeeRecipient, uint256 _protocolFee) public initializer {
//         __Ownable_init();
//         _updateProtocolFeeRecipient(_protocolFeeRecipient);
//         _updateProtocolFee(_protocolFee);
//     }

//     function openComplexJob(
//         uint256 _deadline,
//         uint256 _payment,
//         address[] _nftAddresses,
//         uint256[] _nftTokenIds,
//         string _description
//     ) external payable returns (uint256 jobId) {
//         uint256 wethAmount = _payment - msg.value;

//         if (wethAmount > 0) {
//             IERC20(WETH).safeTransferFrom(msg.sender, address(this), wethAmount);
//             IERC20(WETH).withdraw(wethAmount);
//         }

//         jobId = jobCounter;
//         if (nftAddresses.length > 0) {
//             if (_nftAddresses.length != _nftTokenIds.length) {
//                 revert NoodleShop__NftArraysNotSameLength();
//             }
//             for (uint256 i = 0; i < nftAddresses.length; i++) {
//                 IERC721(nftAddresses[i]).transferFrom(msg.sender, address(this), nftTokenIds[i]);
//             }
//         }

//         jobs[jobId] = Job({
//             owner: msg.sender,
//             jobId: jobId,
//             deadline: block.timestamp + deadline,
//             payment: _payment,
//             nftPayment: _nftAddresses,
//             nftPaymentId: _nftTokenIds,
//             description: _description,
//             fullfiler: address(0)
//         });
//         jobCounter++;
//     }

//     function settleJob(uint256 _jobId) external {
        
//     }

//     /// @notice Transfer fees and funds to royalty recipient, protocol, and seller
//     /// @param _collection address of ERC721 token
//     /// @param _tokenId token id of ERC721 token
//     /// @param _currency address of token being used for the purchase (e.g. USDC)
//     /// @param _from sender of the funds
//     /// @param _to seller's recipient
//     /// @param _amount amount being transferred (in currency)
//     /// @param _minPercentageToAsk minimum percentage of the gross amount that goes to ask
//     function _transferFeesAndFunds(
//         uint256 _jobId,
//         address _from,
//         address _to,
//         uint256 _amount
//     ) internal {
//         // Initialize the final amount that is transferred to seller
//         uint256 finalProviderAmount = _amount;

//         // 1. Protocol fee
//         {
//             uint256 protocolFeeAmount = (_amount * protocolFee) / 10000;
//             address _protocolFeeRecipient = protocolFeeRecipient;

//             // Check if the protocol fee is different than 0 for this strategy
//             if ((_protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
//                 (bool sent,) = _protocolFeeRecipient.call{value: msg.value}("");
//                 if (!sent) revert NoodleShop__TransferFailed();
//                 finalSellerAmount -= protocolFeeAmount;
//             }
//         }

//         (bool sent,) = _to.call{value: msg.value}("");
//         if (!sent) revert NoodleShop__TransferFailed();
//     }

//     function onERC721Received(
//         address,
//         address,
//         uint256,
//         bytes calldata
//     ) external pure returns (bytes4) {
//         return this.onERC721Received.selector;
//     }

//     function updateProtocolRecipient(address _protocolFeeRecipient) external onlyOwner {
//         _udpdateProtocolFeeRecipiet(_protocolFeeRecipient);
//     }

//     function _updateProtocolRecipient(address _protocolFeeRecipient) internal {
//         protocolFeeRecipient = _protocolFeeRecipient;
//     }

//     function updateProtocolFee(address _protocolFee) external onlyOwner {
//         _udpdateProtocolFee(_protocolFee);
//     }

//     function _updateProtocolFee(address _protocolFee) internal {
//         protocolFee = _protocolFee;
//     }
// }

// // SPDX-License-Identifier: MIT AND BSD-3-Clause

// pragma solidity >=0.8.9 <0.9.0;

// // █▀▀██▀▀█         ▀██                           ▀██▀▀█▄           ▀██              ▀██
// //    ██      ▄▄▄    ██  ▄▄   ▄▄▄▄ ▄▄▄   ▄▄▄       ██   ██    ▄▄▄▄   ██ ▄▄▄    ▄▄▄▄   ██   ▄▄▄▄
// //    ██    ▄█  ▀█▄  ██ ▄▀     ▀█▄  █  ▄█  ▀█▄     ██▀▀█▀   ▄█▄▄▄██  ██▀  ██ ▄█▄▄▄██  ██  ██▄ ▀
// //    ██    ██   ██  ██▀█▄      ▀█▄█   ██   ██     ██   █▄  ██       ██    █ ██       ██  ▄ ▀█▄▄
// //   ▄██▄    ▀█▄▄█▀ ▄██▄ ██▄     ▀█     ▀█▄▄█▀    ▄██▄  ▀█▀  ▀█▄▄▄▀  ▀█▄▄▄▀   ▀█▄▄▄▀ ▄██▄ █▀▄▄█▀
// //                            ▄▄ █                                       contract by: primata 🐵
// //                             ▀▀

// import "@ERC721A/contracts/extensions/ERC721AQueryable.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/common/ERC2981.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract TokyoRebels is ERC721AQueryable, Ownable, ERC2981 {
//     uint256 public phase;
//     uint256 public constant MAX_REBELS = 10000;
//     uint256 public overrideCost = 0.01 ether;
//     uint256 public maxOverride = 20;
//     uint256 public discountDivisor = 100;
//     bytes32 private rebelMerkleRoot;
//     bytes32 private gcMerkleRoot;
//     bytes32 private wlMerkleRoot;

//     mapping(address => bool) public wlMinted;
//     mapping(address => bool) public gcMinted;
//     mapping(address => bool) public rebelMinted;
//     mapping(address => bool) public publicMinted;

//     string private _baseTokenURI;
//     string private _prerevealURI;

//     error WrongPhase();
//     error WrongAmount();
//     error ExceedsMaxRebels();
//     error AlreadyMinted();
//     error NotEnoughEth();
//     error NotAllowed();

//     /**
//      * @dev Sets default royalty receiver and fee. 
//      *
//      * @param receiver The address that will receive the royalties.
//      * @param feeNumerator The amount of royalties to be paid in bps.
//      * @param prerevealURI_ The prereveal URI for the token metadata.
//      */
//     constructor(address receiver, uint96 feeNumerator, string memory prerevealURI_) ERC721A("Tokyo Rebels", "REBEL") {
//         _setDefaultRoyalty(receiver, feeNumerator);
//         _prerevealURI = prerevealURI_;
//     }

//     //           ██
//     // ▄▄▄▄ ▄▄▄ ▄▄▄    ▄▄▄▄  ▄▄▄ ▄▄▄ ▄▄▄
//     //  ▀█▄  █   ██  ▄█▄▄▄██  ██  ██  █
//     //   ▀█▄█    ██  ██        ███ ███
//     //    ▀█    ▄██▄  ▀█▄▄▄▀    █   █

//     /**
//     @dev Verifies if the address is whitelisted.
//     @param _merkleProof Merkle Proof to verify with the caller address
//      */
//     function checkWhitelist(bytes32[] calldata _merkleProof) public view returns (bool) {
//         bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
//         return MerkleProof.verify(_merkleProof, wlMerkleRoot, leaf) && !wlMinted[msg.sender];
//     }

//     /**
//     @dev Verifies if the address is GCListed.
//     @param _merkleProof Merkle Proof to verify with the caller address
//      */
//     function checkGeneticChain(bytes32[] calldata _merkleProof) public view returns (bool) {
//         bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
//         return MerkleProof.verify(_merkleProof, gcMerkleRoot, leaf) && !gcMinted[msg.sender];
//     }

//     /**
//     @dev Verifies if the address is RebelListed.
//     @param _merkleProof Merkle Proof to verify with the caller address
//      */
//     function checkRebel(bytes32[] calldata _merkleProof) public view returns (bool) {
//         bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
//         return MerkleProof.verify(_merkleProof, rebelMerkleRoot, leaf) && !rebelMinted[msg.sender];
//     }

//     /**
//     @dev Verifies if contract supports interface.
//     @param interfaceId Id to verify
//      */
//     function supportsInterface(bytes4 interfaceId)
//         public
//         view
//         virtual
//         override(ERC721A, ERC2981, IERC721A)
//         returns (bool)
//     {
//         return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
//     }

//     /**
//     @dev Retrieves token URI.
//     @param tokenId token Id to retrieve URI
//      */
//     function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
//         if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

//         string memory baseURI = _baseURI();
//         return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : _prerevealURI;
//     }

//     //             ██             ▄
//     // ▄▄ ▄▄ ▄▄   ▄▄▄  ▄▄ ▄▄▄   ▄██▄
//     //  ██ ██ ██   ██   ██  ██   ██
//     //  ██ ██ ██   ██   ██  ██   ██
//     // ▄██ ██ ██▄ ▄██▄ ▄██▄ ██▄  ▀█▄▀

//     /**
//     @dev Mint a token to the caller during public phase (2).
//      */
//     function publicMint() external {
//         if (phase != 2) revert WrongPhase();
//         if (totalSupply() >= MAX_REBELS) revert ExceedsMaxRebels();
//         if (publicMinted[msg.sender]) revert AlreadyMinted();

//         _mint(msg.sender, 1);
//         publicMinted[msg.sender] = true;
//     }

//     /**
//     @dev Mints up to override limit to the caller during presale and public phase (1 and 2).
//     @param _amount Amount of tokens to mint
//      */
//     function overrideMint(uint256 _amount) external payable {
//         if (phase == 0) revert WrongPhase();
//         if (_amount > maxOverride) revert WrongAmount();
//         if (msg.value < _calculateTotalPrice(overrideCost, _amount)) revert NotEnoughEth();
//         if (totalSupply() + _amount > MAX_REBELS) revert ExceedsMaxRebels();

//         _mint(msg.sender, _amount);
//     }

//     /**
//     @dev Mints one token the caller during presale and public phase (1 and 2).
//     @param _merkleProof Merkle Proof to verify with the caller address
//      */
//     function whitelistMint(bytes32[] calldata _merkleProof) external {
//         if (phase == 0) revert WrongPhase();
//         if (totalSupply() >= MAX_REBELS) revert ExceedsMaxRebels();

//         if (!checkWhitelist(_merkleProof)) revert NotAllowed();

//         _mint(msg.sender, 1);
//         wlMinted[msg.sender] = true;
//     }

//     /**
//     @dev Mints up to two tokens to the caller during presale and public phase (1 and 2).
//     @param _amount Amount of tokens to mint
//     @param _merkleProof Merkle Proof to verify with the caller address
//      */
//     function geneticChainMint(uint256 _amount, bytes32[] calldata _merkleProof) external {
//         if (phase == 0) revert WrongPhase();
//         if (_amount > 2) revert WrongAmount();
//         if (totalSupply() + _amount > MAX_REBELS) revert ExceedsMaxRebels();
//         if (gcMinted[msg.sender]) revert AlreadyMinted();

//         if (!checkGeneticChain(_merkleProof)) revert NotAllowed();

//         _mint(msg.sender, _amount);
//         gcMinted[msg.sender] = true;
//     }

//     /**
//     @dev Mints up to three tokens to the caller during presale and public phase (1 and 2).
//     @param _amount Amount of tokens to mint
//     @param _merkleProof Merkle Proof to verify with the caller address
//      */
//     function rebelMint(uint256 _amount, bytes32[] calldata _merkleProof) external {
//         if (phase == 0) revert WrongPhase();
//         if (_amount > 3) revert WrongAmount();
//         if (totalSupply() + _amount > MAX_REBELS) revert ExceedsMaxRebels();
//         if (rebelMinted[msg.sender]) revert AlreadyMinted();

//         if (!checkRebel(_merkleProof)) revert NotAllowed();

//         _mint(msg.sender, _amount);
//         rebelMinted[msg.sender] = true;
//     }

//     //                                                                                   ▄
//     // ▄▄ ▄▄ ▄▄    ▄▄▄▄   ▄▄ ▄▄▄    ▄▄▄▄     ▄▄▄ ▄   ▄▄▄▄  ▄▄ ▄▄ ▄▄     ▄▄▄▄  ▄▄ ▄▄▄   ▄██▄
//     //  ██ ██ ██  ▀▀ ▄██   ██  ██  ▀▀ ▄██   ██ ██  ▄█▄▄▄██  ██ ██ ██  ▄█▄▄▄██  ██  ██   ██
//     //  ██ ██ ██  ▄█▀ ██   ██  ██  ▄█▀ ██    █▀▀   ██       ██ ██ ██  ██       ██  ██   ██
//     // ▄██ ██ ██▄ ▀█▄▄▀█▀ ▄██▄ ██▄ ▀█▄▄▀█▀  ▀████▄  ▀█▄▄▄▀ ▄██ ██ ██▄  ▀█▄▄▄▀ ▄██▄ ██▄  ▀█▄▀
//     //                                     ▄█▄▄▄▄▀

//     function teamAllocation(uint256 _amount, address _receiver) external onlyOwner {
//         if (totalSupply() + _amount > MAX_REBELS) revert ExceedsMaxRebels();
//         _mint(_receiver, _amount);
//     }

//     function setPhase(uint256 _phase) public onlyOwner {
//         phase = _phase;
//     }

//     function setDiscountDivisor(uint256 _discountDivisor) external onlyOwner {
//         discountDivisor = _discountDivisor;
//     }

//     function setWLMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
//         wlMerkleRoot = _merkleRoot;
//     }

//     function setGCMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
//         gcMerkleRoot = _merkleRoot;
//     }

//     function setRebelMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
//         rebelMerkleRoot = _merkleRoot;
//     }

//     function setOverrideCost(uint256 _cost) external onlyOwner {
//         overrideCost = _cost;
//     }

//     function setMaxOverride(uint256 _maxOverride) external onlyOwner {
//         maxOverride = _maxOverride;
//     }

//     function setPrerevealURI(string memory prerevealURI_) external onlyOwner {
//         _prerevealURI = prerevealURI_;
//     }

//     function setBaseURI(string memory baseURI) public onlyOwner {
//         _baseTokenURI = baseURI;
//     }

//     function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyOwner {
//         _setDefaultRoyalty(_receiver, _feeNumerator);
//     }

//     function withdraw() external onlyOwner {
//         address payable to = payable(msg.sender);
//         to.transfer(address(this).balance);
//     }

//     function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
//         IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
//     }

//     function recoverERC721(address _tokenAddress, uint256 _tokenId) external onlyOwner {
//         IERC721A(_tokenAddress).transferFrom(address(this), address(msg.sender), _tokenId);
//     }

//     //  ██             ▄                                    ▀██
//     // ▄▄▄  ▄▄ ▄▄▄   ▄██▄    ▄▄▄▄  ▄▄▄ ▄▄  ▄▄ ▄▄▄    ▄▄▄▄    ██
//     //  ██   ██  ██   ██   ▄█▄▄▄██  ██▀ ▀▀  ██  ██  ▀▀ ▄██   ██
//     //  ██   ██  ██   ██   ██       ██      ██  ██  ▄█▀ ██   ██
//     // ▄██▄ ▄██▄ ██▄  ▀█▄▀  ▀█▄▄▄▀ ▄██▄    ▄██▄ ██▄ ▀█▄▄▀█▀ ▄██▄

//     function _baseURI() internal view override returns (string memory) {
//         return _baseTokenURI;
//     }

//     function _calculateTotalPrice(uint256 _price, uint256 _num)
//         internal
//         view
//         returns (uint256 totalPrice)
//     {
//         totalPrice = (_price * _num * (discountDivisor - _num)) / discountDivisor;
//     }

//     function _startTokenId() internal pure override returns (uint256) {
//         return 1;
//     }
// }

/**
 *Submitted for verification at Etherscan.io on 2017-12-12
 */

// Copyright (C) 2015, 2016, 2017 Dapphub

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

pragma solidity >=0.8.9 <0.9.0;

contract WETH9 {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    fallback() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint256(0)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

/*
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    <program>  Copyright (C) <year>  <name of author>
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, your program's commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.

*/