// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
struct ZipTest__MyStruct {
	string  a;
	uint256  b;
}

/// @dev Wrapper for the zipped contract @ 0x020d882022295816E06C262769A419d2097CaD0d.
contract ZipTest {
	address constant ZIPPED = 0x020d882022295816E06C262769A419d2097CaD0d;

	function saySomething()
		external view
		returns (string memory )
	{ __forwardToZipped(); }
	
	function saySomethingWithAStruct(ZipTest__MyStruct calldata fields)
		external view
		returns (bytes32  h)
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