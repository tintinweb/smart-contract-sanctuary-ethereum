//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import './Utils.sol';

interface AnyswapV1ERC20 {
	function mint(address to, uint256 amount) external returns (bool);

	function burn(address from, uint256 amount) external returns (bool);

	function setMinter(address _auth) external;

	function applyMinter() external;

	function revokeMinter(address _auth) external;

	function changeVault(address newVault) external returns (bool);

	function depositVault(uint256 amount, address to) external returns (uint256);

	function withdrawVault(
		address from,
		uint256 amount,
		address to
	) external returns (uint256);

	function underlying() external view returns (address);

	function deposit(uint256 amount, address to) external returns (uint256);

	function withdraw(uint256 amount, address to) external returns (uint256);
}

contract TestAnySwapRouter {
	event AnySwapOutUnderlying(address token, address from, address to, uint256 amount, uint256 toChainId);
	event AnySwapOut(address token, address from, address to, uint256 amount, uint256 toChainId);
	event AnySwapOutNative(address token, address from, address to, uint256 amount, uint256 toChainId);

	function anySwapOutUnderlying(
		address token,
		address to,
		uint256 amount,
		uint256 toChainID
	) external {
		// IERC20(AnyswapV1ERC20(token).underlying()).transferFrom(msg.sender, token, amount);
		IERC20(AnyswapV1ERC20(token).underlying()).transferFrom(msg.sender, to, amount);
		emit AnySwapOutUnderlying(token, msg.sender, to, amount, toChainID);
	}

	function anySwapOut(
		address token,
		address to,
		uint256 amount,
		uint256 toChainID
	) external {
		// AnyswapV1ERC20(token).burn(msg.sender, amount);
		IERC20(token).transferFrom(msg.sender, to, amount);
		emit AnySwapOut(token, msg.sender, to, amount, toChainID);
	}

	function anySwapOutNative(
		address token,
		address to,
		uint256 toChainID
	) external payable {
		payable(to).transfer(msg.value);
		emit AnySwapOutNative(token, msg.sender, to, msg.value, toChainID);
	}
}