/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVestingFactory {
	function createVesting(
		address _implementation,
		bytes32 _salt,
		bytes calldata _data
	) external returns (address addr);
}

contract BatchVestings {
	function createVestings(
		IVestingFactory _factory,
		address _implementation,
		bytes32 _salt,
		bytes[] calldata _datas
	) external {
		for (uint256 i = 0; i < _datas.length; i++) {
			_factory.createVesting(_implementation, keccak256(abi.encode(_salt, i)), _datas[i]);
		}
	}
}