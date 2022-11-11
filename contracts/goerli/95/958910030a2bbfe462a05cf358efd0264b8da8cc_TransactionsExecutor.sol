/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20TransferFrom {
	function transferFrom(
		address from,
		address to,
		uint256 amount
	) external returns (bool);
}

contract Ownable {
	address internal _owner;

	constructor() {
		_owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == _owner);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		if (newOwner != address(0)) {
			_owner = newOwner;
		}
	}

	function renounceOwnership() public onlyOwner {
		_owner = address(0);
	}

	function getOwner() public view returns (address) {
		return _owner;
	}

}

contract TransactionsExecutor is Ownable {

	bool internal _initialized;

	function initialize(
		address newOwner
	) public {
		require(!_initialized);
		require(newOwner != address(0));
		_owner = newOwner;
		_initialized = true;
	}
	
	function batchTransferFrom(
		IERC20TransferFrom[] calldata _token,
		address[] calldata _from,
		address[] calldata _to,
		uint256[] calldata _value
	) public onlyOwner {
		
		uint len = _value.length;

		for (uint8 i=0; i < len;) {
			_token[i].transferFrom(_from[i], _to[i], _value[i]);
			unchecked {++i;}
		}
	}
}