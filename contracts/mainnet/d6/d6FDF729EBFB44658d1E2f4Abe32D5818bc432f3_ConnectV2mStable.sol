// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

/**
 * @title mStable SAVE.
 * @dev Depositing and withdrawing directly to Save
 */

import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

import { TokenInterface } from "./interfaces.sol";
import { IMasset, IBoostedSavingsVault, IFeederPool } from "./interface.sol";

abstract contract mStableResolver is Events, Helpers {
	/***************************************
                    CORE
    ****************************************/

	/**
	 * @dev Deposit to Save via mUSD or bAsset
	 * @notice Deposits token supported by mStable to Save
	 * @param _token Address of token to deposit
	 * @param _amount Amount of token to deposit
	 * @param _minOut Minimum amount of token to mint/deposit, equal to _amount if mUSD
	 * @param _stake stake token in Vault?
	 * @param _getId ID to retrieve amt
	 * @param _setId ID stores the amount of tokens deposited
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function deposit(
		address _token,
		uint256 _amount,
		uint256 _minOut,
		bool _stake,
		uint256 _setId,
		uint256 _getId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 amount = getUint(_getId, _amount);
		amount = amount == uint256(-1)
			? TokenInterface(_token).balanceOf(address(this))
			: amount;
		uint256 mintedAmount;
		address path;

		// Check if needs to be minted first
		if (IMasset(mUsdToken).bAssetIndexes(_token) != 0) {
			// mint first
			approve(TokenInterface(_token), mUsdToken, amount);
			mintedAmount = IMasset(mUsdToken).mint(
				_token,
				amount,
				_minOut,
				address(this)
			);
			path = mUsdToken;
		} else {
			require(amount >= _minOut, "mintedAmount < _minOut");
			mintedAmount = amount;
			path = imUsdToken;
		}

		setUint(_setId, mintedAmount);
		(_eventName, _eventParam) = _deposit(
			_token,
			mintedAmount,
			path,
			_stake
		);
	}

	/**
	 * @dev Deposit to Save via feeder pool
	 * @notice Deposits token, requires _minOut for minting and _path
	 * @param _token Address of token to deposit
	 * @param _amount Amount of token to deposit
	 * @param _minOut Minimum amount of token to mint
	 * @param _path Feeder Pool address for _token
	 * @param _stake stake token in Vault?
	 * @param _getId ID to retrieve amt
	 * @param _setId ID stores the amount of tokens deposited
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function depositViaSwap(
		address _token,
		uint256 _amount,
		uint256 _minOut,
		address _path,
		bool _stake,
		uint256 _setId,
		uint256 _getId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(_path != address(0), "Path must be set");
		require(
			IMasset(mUsdToken).bAssetIndexes(_token) == 0,
			"Token is bAsset"
		);

		uint256 amount = getUint(_getId, _amount);
		amount = amount == uint256(-1)
			? TokenInterface(_token).balanceOf(address(this))
			: amount;

		approve(TokenInterface(_token), _path, amount);
		uint256 mintedAmount = IFeederPool(_path).swap(
			_token,
			mUsdToken,
			amount,
			_minOut,
			address(this)
		);

		setUint(_setId, mintedAmount);
		(_eventName, _eventParam) = _deposit(
			_token,
			mintedAmount,
			_path,
			_stake
		);
	}

	/**
	 * @dev Withdraw from Save to mUSD or bAsset
	 * @notice Withdraws from Save Vault to mUSD
	 * @param _token Address of token to withdraw
	 * @param _credits Credits to withdraw
	 * @param _minOut Minimum amount of token to withdraw
	 * @param _unstake from the Vault first?
	 * @param _getId ID to retrieve amt
	 * @param _setId ID stores the amount of tokens withdrawn
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function withdraw(
		address _token,
		uint256 _credits,
		uint256 _minOut,
		bool _unstake,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 credits = getUint(_getId, _credits);
		uint256 amountWithdrawn = _withdraw(credits, _unstake);

		// Check if needs to be redeemed
		if (IMasset(mUsdToken).bAssetIndexes(_token) != 0) {
			amountWithdrawn = IMasset(mUsdToken).redeem(
				_token,
				amountWithdrawn,
				_minOut,
				address(this)
			);
		} else {
			require(amountWithdrawn >= _minOut, "amountWithdrawn < _minOut");
		}

		setUint(_setId, amountWithdrawn);
		_eventName = "LogWithdraw(address,uint256,address,bool)";
		_eventParam = abi.encode(
			mUsdToken,
			amountWithdrawn,
			imUsdToken,
			_unstake
		);
	}

	/**
	 * @dev Withdraw from Save via Feeder Pool
	 * @notice Withdraws from Save Vault to asset via Feeder Pool
	 * @param _token bAsset to withdraw to
	 * @param _credits Credits to withdraw
	 * @param _minOut Minimum amount of token to mint
	 * @param _path Feeder Pool address for _token
	 * @param _unstake from the Vault first?
	 * @param _getId ID to retrieve amt
	 * @param _setId ID stores the amount of tokens withdrawn
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function withdrawViaSwap(
		address _token,
		uint256 _credits,
		uint256 _minOut,
		address _path,
		bool _unstake,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(_path != address(0), "Path must be set");
		require(
			IMasset(mUsdToken).bAssetIndexes(_token) == 0,
			"Token is bAsset"
		);

		uint256 credits = getUint(_getId, _credits);

		uint256 amountWithdrawn = _withdraw(credits, _unstake);

		approve(TokenInterface(mUsdToken), _path, amountWithdrawn);
		uint256 amountRedeemed = IFeederPool(_path).swap(
			mUsdToken,
			_token,
			amountWithdrawn,
			_minOut,
			address(this)
		);

		setUint(_setId, amountRedeemed);

		_eventName = "LogWithdraw(address,uint256,address,bool)";
		_eventParam = abi.encode(_token, amountRedeemed, _path, _unstake);
	}

	/**
	 * @dev Claims Rewards
	 * @notice Claims accrued rewards from the Vault
	 * @param _getId ID to retrieve amt
	 * @param _setId ID stores the amount of tokens withdrawn
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function claimRewards(uint256 _getId, uint256 _setId)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		address rewardToken = _getRewardTokens();
		uint256 rewardAmount = _getRewardInternalBal(rewardToken);

		IBoostedSavingsVault(imUsdVault).claimReward();

		uint256 rewardAmountUpdated = _getRewardInternalBal(rewardToken);

		uint256 claimedRewardToken = sub(rewardAmountUpdated, rewardAmount);

		setUint(_setId, claimedRewardToken);

		_eventName = "LogClaimRewards(address,uint256)";
		_eventParam = abi.encode(rewardToken, claimedRewardToken);
	}

	/**
	 * @dev Swap tokens
	 * @notice Swaps tokens via Masset basket
	 * @param _input Token address to swap from
	 * @param _output Token address to swap to
	 * @param _amount Amount of tokens to swap
	 * @param _minOut Minimum amount of token to mint
	 * @param _getId ID to retrieve amt
	 * @param _setId ID stores the amount of tokens swapped
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function swap(
		address _input,
		address _output,
		uint256 _amount,
		uint256 _minOut,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 amount = getUint(_getId, _amount);
		amount = amount == uint256(-1)
			? TokenInterface(_input).balanceOf(address(this))
			: amount;
		approve(TokenInterface(_input), mUsdToken, amount);
		uint256 amountSwapped;

		// Check the assets and swap accordingly
		if (_output == mUsdToken) {
			// bAsset to mUSD => mint
			amountSwapped = IMasset(mUsdToken).mint(
				_input,
				amount,
				_minOut,
				address(this)
			);
		} else if (_input == mUsdToken) {
			// mUSD to bAsset => redeem
			amountSwapped = IMasset(mUsdToken).redeem(
				_output,
				amount,
				_minOut,
				address(this)
			);
		} else {
			// bAsset to another bAsset => swap
			amountSwapped = IMasset(mUsdToken).swap(
				_input,
				_output,
				amount,
				_minOut,
				address(this)
			);
		}

		setUint(_setId, amountSwapped);
		_eventName = "LogSwap(address,address,uint256,uint256)";
		_eventParam = abi.encode(_input, _output, amount, amountSwapped);
	}

	/**
	 * @dev Swap tokens via Feeder Pool
	 * @notice Swaps tokens via Feeder Pool
	 * @param _input Token address to swap from
	 * @param _output Token address to swap to
	 * @param _amount Amount of tokens to swap
	 * @param _minOut Minimum amount of token to mint
	 * @param _path Feeder Pool address to use
	 * @param _getId ID to retrieve amt
	 * @param _setId ID stores the amount of tokens swapped
	 * @return _eventName Event name
	 * @return _eventParam Event parameters
	 */

	function swapViaFeeder(
		address _input,
		address _output,
		uint256 _amount,
		uint256 _minOut,
		address _path,
		uint256 _getId,
		uint256 _setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 amountSwapped;
		uint256 amount = getUint(_getId, _amount);
		amount = amount == uint256(-1)
			? TokenInterface(_input).balanceOf(address(this))
			: amount;

		approve(TokenInterface(_input), _path, amount);

		// swaps fAsset to mUSD via Feeder Pool
		// swaps mUSD to fAsset via Feeder Pool
		amountSwapped = IFeederPool(_path).swap(
			_input,
			_output,
			amount,
			_minOut,
			address(this)
		);

		setUint(_setId, amountSwapped);

		_eventName = "LogSwap(address,address,uint256,uint256)";
		_eventParam = abi.encode(_input, _output, amount, amountSwapped);
	}
}

contract ConnectV2mStable is mStableResolver {
	string public constant name = "mStable-v1.0";
}