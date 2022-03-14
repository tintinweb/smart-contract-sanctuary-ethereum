/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

interface IChainlinkPriceFeedProxy {
	function latestAnswer() external view returns (int256);

	function latestTimestamp() external view returns (uint256);
}

interface IAaveAssetToken {
	function balanceOf(address) external view returns (uint256);
}

contract CheckAhead {
	function checkAheadChainlink(address priceFeed, uint256 timestamp) public view {
		require(IChainlinkPriceFeedProxy(priceFeed).latestTimestamp() > timestamp);
	}

	function checkAheadAsset(
		address asset,
		address position,
		uint256 amount
	) public view {
		require(IAaveAssetToken(asset).balanceOf(position) > amount);
	}

	function checkAheadTwoAsset(
		address asset1,
		address asset2,
		address position,
		uint256 amount
	) public view {
		require(IAaveAssetToken(asset1).balanceOf(position) + IAaveAssetToken(asset2).balanceOf(position) > amount);
	}

	function checkAheadChainlinkAndAsset(
		address priceFeed,
		uint256 timestamp,
		address asset,
		address position,
		uint256 amount
	) public view {
		require(IChainlinkPriceFeedProxy(priceFeed).latestTimestamp() > timestamp);
		require(IAaveAssetToken(asset).balanceOf(position) > amount);
	}

	function checkAheadChainlinkAndTwoAsset(
		address priceFeed,
		uint256 timestamp,
		address asset1,
		address asset2,
		address position,
		uint256 amount
	) public view {
		require(IChainlinkPriceFeedProxy(priceFeed).latestTimestamp() > timestamp);
		require(IAaveAssetToken(asset1).balanceOf(position) + IAaveAssetToken(asset2).balanceOf(position) > amount);
	}
}