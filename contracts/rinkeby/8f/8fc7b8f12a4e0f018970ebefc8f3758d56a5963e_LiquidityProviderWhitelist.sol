// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/// @title Topos Investor Whitelist
/// @notice the contract contains in plain and visible the list of addresses that are allowed to make an investment
contract LiquidityProviderWhitelist {
	//
	// errors
	//

	error InvalidAddress();
	error NotAuthorized(address caller);

	//
	// events
	//

	event AllowedAddress(address indexed addr);
	event DeniedAddress(address indexed addr);

	//
	// state variables
	//

	address public immutable manager;
	string public name;

	//
	// structs, enums, arrays
	//

	/// @notice mapping of allowed addresses: address => bool (true = active)
	mapping(address => bool) public allowedAddresses;

	modifier notZeroAddress(address addr) {
		if (addr == address(0)) revert InvalidAddress();
		_;
	}

	modifier onlyManager() {
		if (msg.sender != manager) revert NotAuthorized(msg.sender);
		_;
	}

	/// @dev We use the constructor to precompute variables that only change rarely.
	/// @param _manager Address which can adjust parameters of the contract
	/// @param _name the contract name
	constructor(address _manager, string memory _name) notZeroAddress(_manager) {
		manager = _manager;
		name = _name;
	}

	//
	// permissioned functions
	//

	function allowAddress(address _address) external onlyManager notZeroAddress(_address) {
		allowedAddresses[_address] = true;
		emit AllowedAddress(_address);
	}

	function denyAddress(address _address) external onlyManager notZeroAddress(_address) {
		allowedAddresses[_address] = false;
		emit DeniedAddress(_address);
	}

	//
	// public functions
	//

	function checkAddress(address _address) external view returns (bool) {
		return allowedAddresses[_address];
	}
}