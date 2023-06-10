// SPDX-License-Identifier: UNLICENSED
// Compiler: v0.8.20+commit.a1b79de6
// Optimizer: false
pragma solidity ^0.8.20;

/// @dev Wrapper for zipped contract poop (0x388C818CA8B9251b393131C08a736A67ccB19297).
contract poop {
	address constant ZIPPED = 0x388C818CA8B9251b393131C08a736A67ccB19297;

	function __checkStaticContext()
		external view
	{ __forwardToZipped(); }
	function __execZCall(address  unzipped,bytes calldata initCode,bytes calldata callData)
		external view
	{ __forwardToZipped(); }
	function __execZRun(bytes calldata initCode,bytes calldata initArgs)
		external view
	{ __forwardToZipped(); }
	function inflate(bytes calldata ,uint256  outputSize)
		external view
		returns (bytes memory )
	{ __forwardToZipped(); }
	function inflateFrom(address  dataAddr,uint256  dataOffset,uint256  dataSize,uint256  outputSize)
		external view
		returns (bytes memory )
	{ __forwardToZipped(); }
	function zcallWithRawResult(uint256  dataOffset,uint256  dataSize,uint256  unzippedSize,bytes32  unzippedHash,bytes calldata callData)
		external view
	{ __forwardToZipped(); }
	function zrunWithRawResult(uint256  dataOffset,uint256  dataSize,uint256  unzippedSize,bytes32  unzippedHash,bytes calldata initArgs)
		external view
	{ __forwardToZipped(); }

	function __forwardToZipped() private view {
		function () fwd = __forwardToZippedNonView;
		function () view vfwd;
		assembly ("memory-safe") { vfwd := fwd }
		vfwd();
	}

	function  __forwardToZippedNonView() private {
		assembly ("memory-safe") {
			calldatacopy(0x00, 0x00, calldatasize())
			let s := delegatecall(gas(), ZIPPED, 0x00, calldatasize(), 0x00, 0x00)
			returndatacopy(0x00, 0x00, returndatasize())
			if iszero(s) {
				revert(0x00, returndatasize())
			}
			return(0x00, returndatasize())
		}
	}
}