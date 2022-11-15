/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20TokenImplementation {
	function initialize(
		string memory tokenName,
		string memory tokenSymbol,
		uint8 tokenDecimals,
		address owner,
		address manager
	) external;
}

contract Manageable {
	address internal _owner;
	address internal _manager;

	modifier onlyOwner() {
		require(msg.sender == _owner);
		_;
	}
	
	modifier onlyManager() {
		require(msg.sender == _manager);
		_;
	}

	modifier onlyOwnerManager() {
		require(msg.sender == _owner || msg.sender == _manager);
		_;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		if (newOwner != address(0)) {
			_owner = newOwner;
		}
	}
	
	function setManager(address newManager) public onlyOwner {
		_manager = newManager;
	}

	function getOwner() public view returns (address) {
		return _owner;
	}
	
	function getManager() public view returns (address) {
		return _manager;
	}

}

contract ProxyERC20Token is Manageable {
	IERC20TokenImplementation internal _implementation;
	
	constructor(address owner, address manager, IERC20TokenImplementation implementation) {
		_owner = owner;
		_manager = manager;
		_implementation = implementation;
	}
	
	receive()   payable external {}
	
	fallback () payable external {
		assembly {
			calldatacopy(0, 0, calldatasize())
			let result := delegatecall(gas(), sload(_implementation.slot), 0, calldatasize(), 0, 0)
			returndatacopy(0, 0, returndatasize())
			switch result
			case 0 { revert(0, returndatasize()) }
			default { return(0, returndatasize()) }
		}
	}
	
	function setImplementation(IERC20TokenImplementation newImplementation) external onlyManager {
		_implementation = newImplementation;
	}
	
	function getImplementation() external view returns (IERC20TokenImplementation) {
		return _implementation;
	}	
}

contract ERC20TokenCreator{

	event ERC20TokenCreate(address indexed newERC20Token);
	
	function createERC20Token(
		address owner, 
		address manager, 
		IERC20TokenImplementation implementation,
		string memory tokenName,
		string memory tokenSymbol,
		uint8 tokenDecimals
	) external returns (address) {
		ProxyERC20Token tERC20 = new ProxyERC20Token(owner, manager, implementation);
		emit ERC20TokenCreate(address(tERC20));
		(bool success,) = address(tERC20).call{value: 0}(abi.encodeWithSelector(implementation.initialize.selector, tokenName, tokenSymbol, tokenDecimals, owner, manager));
		require(success);
		return address(tERC20);
	}

}