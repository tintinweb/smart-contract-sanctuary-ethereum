//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Compound III
 * @dev Lending & Borrowing.
 */

import { TokenInterface } from "../../../common/interfaces.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";
import { CometInterface } from "./interface.sol";

abstract contract CompoundV3Resolver is Events, Helpers {
	/**
	 * @dev Deposit base asset or collateral asset supported by the market.
	 * @notice Deposit a token to Compound for lending / collaterization.
	 * @param market The address of the market.
	 * @param token The address of the token to be supplied. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function deposit(
		address market,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);

		require(
			market != address(0) && token != address(0),
			"invalid market/token address"
		);

		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(token_);

		if (token_ == getBaseToken(market)) {
			require(
				CometInterface(market).borrowBalanceOf(address(this)) == 0,
				"debt-not-repaid"
			);
		}

		if (isEth) {
			amt_ = amt_ == uint256(-1) ? address(this).balance : amt_;
			convertEthToWeth(isEth, tokenContract, amt_);
		} else {
			amt_ = amt_ == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: amt_;
		}
		approve(tokenContract, market, amt_);

		CometInterface(market).supply(token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogDeposit(address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, amt_, getId, setId);
	}

	/**
	 * @dev Deposit base asset or collateral asset supported by the market on behalf of 'to'.
	 * @notice Deposit a token to Compound for lending / collaterization on behalf of 'to'.
	 * @param market The address of the market.
	 * @param token The address of the token to be supplied. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE).
	 * @param to The address on behalf of which the supply is made.
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function depositOnBehalf(
		address market,
		address token,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);

		require(
			market != address(0) && token != address(0) && to != address(0),
			"invalid market/token/to address"
		);

		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;
		TokenInterface tokenContract = TokenInterface(token_);

		if (token_ == getBaseToken(market)) {
			require(
				CometInterface(market).borrowBalanceOf(to) == 0,
				"to-address-position-debt-not-repaid"
			);
		}

		if (isEth) {
			amt_ = amt_ == uint256(-1) ? address(this).balance : amt_;
			convertEthToWeth(isEth, tokenContract, amt_);
		} else {
			amt_ = amt_ == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: amt_;
		}
		approve(tokenContract, market, amt_);

		CometInterface(market).supplyTo(to, token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogDepositOnBehalf(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, to, amt_, getId, setId);
	}

	/**
	 * @dev Deposit base asset or collateral asset supported by the market from 'from' address and update the position of 'to'.
	 * @notice Deposit a token to Compound for lending / collaterization from a address and update the position of 'to'.
	 * @param market The address of the market.
	 * @param token The address of the token to be supplied. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param from The address from where amount is to be supplied.
	 * @param to The address on account of which the supply is made or whose positions are updated.
	 * @param amt The amount of the token to deposit. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens deposited.
	 */
	function depositFromUsingManager(
		address market,
		address token,
		address from,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);

		require(
			market != address(0) && token != address(0) && to != address(0),
			"invalid market/token/to address"
		);
		require(from != address(this), "from-cannot-be-address(this)-use-depositOnBehalf");

		bool isEth = token == ethAddr;
		address token_ = isEth? wethAddr : token;

		if (token_ == getBaseToken(market)) {
			require(
				CometInterface(market).borrowBalanceOf(to) == 0,
				"to-address-position-debt-not-repaid"
			);
		}

		amt_ = _calculateFromAmount(
			market,
			token_,
			from,
			amt_,
			isEth,
			Action.DEPOSIT
		);

		CometInterface(market).supplyFrom(from, to, token_, amt_);
		setUint(setId, amt_);

		eventName_ = "LogDepositFromUsingManager(address,address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, from, to, amt_, getId, setId);
	}

	/**
	 * @dev Withdraw base/collateral asset.
	 * @notice Withdraw base token or deposited token from Compound.
	 * @param market The address of the market.
	 * @param token The address of the token to be withdrawn. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdraw(
		address market,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);

		require(
			market != address(0) && token != address(0),
			"invalid market/token address"
		);

		bool isEth = token == ethAddr;
		address token_ = isEth ? wethAddr : token;

		TokenInterface tokenContract = TokenInterface(token_);

		uint256 initialBal = _getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token_
		);

		if (token_ == getBaseToken(market)) {
			if (amt_ == uint256(-1)) {
				amt_ = initialBal;
			} else {
				//if there are supplies, ensure withdrawn amount is not greater than supplied i.e can't borrow using withdraw.
				require(amt_ <= initialBal, "withdraw-amt-greater-than-supplies");
			}

			//if borrow balance > 0, there are no supplies so no withdraw, borrow instead.
			require(
				CometInterface(market).borrowBalanceOf(address(this)) == 0,
				"withdraw-disabled-for-zero-supplies"
			);
		} else {
			amt_ = amt_ == uint256(-1) ? initialBal : amt_;
		}

		CometInterface(market).withdraw(token_, amt_);

		uint256 finalBal = _getAccountSupplyBalanceOfAsset(
			address(this),
			market,
			token_
		);

		amt_ = sub(initialBal, finalBal);

		convertWethToEth(isEth, tokenContract, amt_);

		setUint(setId, amt_);

		eventName_ = "LogWithdraw(address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, amt_, getId, setId);
	}

	/**
	 * @dev Withdraw base/collateral asset and transfer to 'to'.
	 * @notice Withdraw base token or deposited token from Compound on behalf of an address and transfer to 'to'.
	 * @param market The address of the market.
	 * @param token The address of the token to be withdrawn. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param to The address to which the borrowed assets are to be transferred.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdrawTo(
		address market,
		address token,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		(uint256 amt_, uint256 setId_) = _withdraw(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: address(this),
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			})
		);

		eventName_ = "LogWithdrawTo(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, to, amt_, getId, setId_);
	}

	/**
	 * @dev Withdraw base/collateral asset from an account and transfer to DSA.
	 * @notice Withdraw base token or deposited token from Compound from an address and transfer to DSA.
	 * @param market The address of the market.
	 * @param token The address of the token to be withdrawn. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param from The address from where asset is to be withdrawed.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdrawOnBehalf(
		address market,
		address token,
		address from,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		(uint256 amt_, uint256 setId_) = _withdraw(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: from,
				to: address(this),
				amt: amt,
				getId: getId,
				setId: setId
			})
		);

		eventName_ = "LogWithdrawOnBehalf(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, from, amt_, getId, setId_);
	}

	/**
	 * @dev Withdraw base/collateral asset from an account and transfer to 'to'.
	 * @notice Withdraw base token or deposited token from Compound from an address and transfer to 'to'.
	 * @param market The address of the market.
	 * @param token The address of the token to be withdrawn. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param from The address from where asset is to be withdrawed.
	 * @param to The address to which the borrowed assets are to be transferred.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens withdrawn.
	 */
	function withdrawOnBehalfAndTransfer(
		address market,
		address token,
		address from,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		public
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		(uint256 amt_, uint256 setId_) = _withdraw(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: from,
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			})
		);

		eventName_ = "LogWithdrawOnBehalfAndTransfer(address,address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token, from, to, amt_, getId, setId_);
	}

	/**
	 * @dev Borrow base asset.
	 * @notice Borrow base token from Compound.
	 * @param market The address of the market.
	 * @param token The address of the token to be borrowed. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of base token to borrow.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens borrowed.
	 */
	function borrow(
		address market,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);

		require(market != address(0), "invalid market address");

		bool isEth = token == ethAddr;
		address token_ = getBaseToken(market);
		require(token == token_ || isEth, "invalid-token");

		TokenInterface tokenContract = TokenInterface(token_);

		require(
			CometInterface(market).balanceOf(address(this)) == 0,
			"borrow-disabled-when-supplied-base"
		);

		uint256 initialBal = CometInterface(market).borrowBalanceOf(
			address(this)
		);

		CometInterface(market).withdraw(token_, amt_);

		uint256 finalBal = CometInterface(market).borrowBalanceOf(
			address(this)
		);

		amt_ = sub(finalBal, initialBal);

		convertWethToEth(isEth, tokenContract, amt_);

		setUint(setId, amt_);

		eventName_ = "LogBorrow(address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, amt_, getId, setId);
	}

	/**
	 * @dev Borrow base asset and transfer to 'to' account.
	 * @notice Borrow base token from Compound on behalf of an address.
	 * @param market The address of the market.
	 * @param token The address of the token to be borrowed. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param to The address to which the borrowed asset is transferred.
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens borrowed.
	 */
	function borrowTo(
		address market,
		address token,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		require(
			token == ethAddr || token == getBaseToken(market),
			"invalid-token"
		);
		(uint256 amt_, uint256 setId_) = _borrow(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: address(this),
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			})
		);
		eventName_ = "LogBorrowTo(address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, to, amt_, getId, setId_);
	}

	/**
	 * @dev Borrow base asset from 'from' and transfer to 'to'.
	 * @notice Borrow base token or deposited token from Compound.
	 * @param market The address of the market.
	 * @param token The address of the token to be borrowed. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param from The address from where asset is to be withdrawed.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens borrowed.
	 */
	function borrowOnBehalf(
		address market,
		address token,
		address from,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		require(
			token == ethAddr || token == getBaseToken(market),
			"invalid-token"
		);
		(uint256 amt_, uint256 setId_) = _borrow(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: from,
				to: address(this),
				amt: amt,
				getId: getId,
				setId: setId
			})
		);
		eventName_ = "LogBorrowOnBehalf(address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, from, amt_, getId, setId_);
	}

	/**
	 * @dev Borrow base asset from 'from' and transfer to 'to'.
	 * @notice Borrow base token or deposited token from Compound.
	 * @param market The address of the market.
	 * @param token The address of the token to be borrowed. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of the token to withdraw. (For max: `uint256(-1)`)
	 * @param from The address from where asset is to be withdrawed.
	 * @param to The address to which the borrowed assets are to be transferred.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens borrowed.
	 */
	function borrowOnBehalfAndTransfer(
		address market,
		address token,
		address from,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		require(
			token == ethAddr || token == getBaseToken(market),
			"invalid-token"
		);
		(uint256 amt_, uint256 setId_) = _borrow(
			BorrowWithdrawParams({
				market: market,
				token: token,
				from: from,
				to: to,
				amt: amt,
				getId: getId,
				setId: setId
			})
		);
		eventName_ = "LogBorrowOnBehalfAndTransfer(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, from, to, amt_, getId, setId_);
	}

	/**
	 * @dev Repays the borrowed base asset.
	 * @notice Repays the borrow of the base asset.
	 * @param market The address of the market.
	 * @param token The address of the token to be repaid. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount to be repaid.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens repaid.
	 */
	function payback(
		address market,
		address token,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);
		require(
			market != address(0) && token != address(0),
			"invalid market/token address"
		);

		bool isEth = token == ethAddr;
		address token_ = getBaseToken(market);
		require(token == token_ || isEth, "invalid-token");

		TokenInterface tokenContract = TokenInterface(token_);

		uint256 borrowedBalance_ = CometInterface(market).borrowBalanceOf(
			address(this)
		);

		if (amt_ == uint256(-1)) {
			amt_ = borrowedBalance_;
		} else {
			require(
				amt_ <= borrowedBalance_,
				"payback-amt-greater-than-borrows"
			);
		}

		//if supply balance > 0, there are no borrowing so no repay, supply instead.
		require(
			CometInterface(market).balanceOf(address(this)) == 0,
			"cannot-repay-when-supplied"
		);

		convertEthToWeth(isEth, tokenContract, amt_);
		approve(tokenContract, market, amt_);

		CometInterface(market).supply(token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogPayback(address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, amt_, getId, setId);
	}

	/**
	 * @dev Repays borrow of the base asset on behalf of 'to'.
	 * @notice Repays borrow of the base asset on behalf of 'to'.
	 * @param market The address of the market.
	 * @param token The address of the token to be repaid. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param to The address on behalf of which the borrow is to be repaid.
	 * @param amt The amount to be repaid.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens repaid.
	 */
	function paybackOnBehalf(
		address market,
		address token,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);
		require(
			market != address(0) && token != address(0) && to != address(0),
			"invalid market/token/to address"
		);

		address token_ = getBaseToken(market);
		bool isEth = token == ethAddr;
		require(token == token_ || isEth, "invalid-token");

		TokenInterface tokenContract = TokenInterface(token_);

		uint256 borrowedBalance_ = CometInterface(market).borrowBalanceOf(to);

		if (amt_ == uint256(-1)) {
			amt_ = borrowedBalance_;
		} else {
			require(
				amt_ <= borrowedBalance_,
				"payback-amt-greater-than-borrows"
			);
		}

		//if supply balance > 0, there are no borrowing so no repay, supply instead.
		require(
			CometInterface(market).balanceOf(to) == 0,
			"cannot-repay-when-supplied"
		);

		convertEthToWeth(isEth, tokenContract, amt_);
		approve(tokenContract, market, amt_);

		CometInterface(market).supplyTo(to, token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogPaybackOnBehalf(address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, to, amt_, getId, setId);
	}

	/**
	 * @dev Repays borrow of the base asset form 'from' on behalf of 'to'.
	 * @notice Repays borrow of the base asset on behalf of 'to'. 'From' address must approve the comet market.
	 * @param market The address of the market.
	 * @param token The address of the token to be repaid. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param from The address from which the borrow has to be repaid on behalf of 'to'.
	 * @param to The address on behalf of which the borrow is to be repaid.
	 * @param amt The amount to be repaid.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens repaid.
	 */
	function paybackFromUsingManager(
		address market,
		address token,
		address from,
		address to,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amt);
		require(
			market != address(0) && token != address(0) && to != address(0),
			"invalid market/token/to address"
		);
		require(from != address(this), "from-cannot-be-address(this)-use-paybackOnBehalf");

		address token_ = getBaseToken(market);
		bool isEth = token == ethAddr;
		require(token == token_ || isEth, "invalid-token");

		if (amt_ == uint256(-1)) {
			amt_ = _calculateFromAmount(
				market,
				token_,
				from,
				amt_,
				isEth,
				Action.REPAY
			);
		} else {
			uint256 borrowedBalance_ = CometInterface(market).borrowBalanceOf(to);
			require(
				amt_ <= borrowedBalance_,
				"payback-amt-greater-than-borrows"
			);
		}

		//if supply balance > 0, there are no borrowing so no repay, withdraw instead.
		require(
			CometInterface(market).balanceOf(to) == 0,
			"cannot-repay-when-supplied"
		);

		CometInterface(market).supplyFrom(from, to, token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogPaybackFromUsingManager(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, from, to, amt_, getId, setId);
	}

	/**
	 * @dev Buy collateral asset absorbed, from the market.
	 * @notice Buy collateral asset to increase protocol base reserves until targetReserves is reached.
	 * @param market The address of the market from where to withdraw.
	 * @param sellToken base token. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param buyAsset The collateral asset to purachase. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param unitAmt Minimum amount of collateral expected to be received.
	 * @param baseSellAmt Amount of base asset to be sold for collateral.
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of base tokens sold.
	 */
	function buyCollateral(
		address market,
		address sellToken,
		address buyAsset,
		uint256 unitAmt,
		uint256 baseSellAmt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		(eventName_, eventParam_) = _buyCollateral(
			BuyCollateralData({
				market: market,
				sellToken: sellToken,
				buyAsset: buyAsset,
				unitAmt: unitAmt,
				baseSellAmt: baseSellAmt
			}),
			getId,
			setId
		);
	}

	/**
	 * @dev Transfer base/collateral or base asset to dest address from this account.
	 * @notice Transfer base/collateral asset to dest address from caller's account.
	 * @param market The address of the market.
	 * @param token The collateral asset to transfer to dest address.
	 * @param dest The account where to transfer the base assets.
	 * @param amount The amount of the collateral token to transfer. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens transferred.
	 */
	function transferAsset(
		address market,
		address token,
		address dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amount);
		require(
			market != address(0) && token != address(0) && dest != address(0),
			"invalid market/token/to address"
		);

		address token_ = token == ethAddr ? wethAddr : token;

		amt_ = amt_ == uint256(-1) ? _getAccountSupplyBalanceOfAsset(address(this), market, token) : amt_;

		CometInterface(market).transferAssetFrom(address(this), dest, token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogTransferAsset(address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token_, dest, amt_, getId, setId);
	}

	/**
	 * @dev Transfer collateral or base asset to dest address from src account.
	 * @notice Transfer collateral asset to dest address from src's account.
	 * @param market The address of the market.
	 * @param token The collateral asset to transfer to dest address.
	 * @param src The account from where to transfer the collaterals.
	 * @param dest The account where to transfer the collateral assets.
	 * @param amount The amount of the collateral token to transfer. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setId ID stores the amount of tokens transferred.
	 */
	function transferAssetOnBehalf(
		address market,
		address token,
		address src,
		address dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory eventName_, bytes memory eventParam_)
	{
		uint256 amt_ = getUint(getId, amount);
		require(
			market != address(0) && token != address(0) && dest != address(0),
			"invalid market/token/to address"
		);

		address token_ = token == ethAddr ? wethAddr : token;

		amt_ = amt_ == uint256(-1) ? _getAccountSupplyBalanceOfAsset(src, market, token) : amt_;

		CometInterface(market).transferAssetFrom(src, dest, token_, amt_);

		setUint(setId, amt_);

		eventName_ = "LogTransferAssetOnBehalf(address,address,address,address,uint256,uint256,uint256)";
		eventParam_ = abi.encode(market, token_, src, dest, amt_, getId, setId);
	}

	/**
	 * @dev Allow/Disallow managers to handle position.
	 * @notice Authorize/Remove managers to perform write operations for the position.
	 * @param market The address of the market where to supply.
	 * @param manager The address to be authorized.
	 * @param isAllowed Whether to allow or disallow the manager.
	 */
	function toggleAccountManager(
		address market,
		address manager,
		bool isAllowed
	) external returns (string memory eventName_, bytes memory eventParam_) {
		CometInterface(market).allow(manager, isAllowed);
		eventName_ = "LogToggleAccountManager(address,address,bool)";
		eventParam_ = abi.encode(market, manager, isAllowed);
	}

	/**
	 * @dev Allow/Disallow managers to handle owner's position.
	 * @notice Authorize/Remove managers to perform write operations for owner's position.
	 * @param market The address of the market where to supply.
	 * @param owner The authorizind owner account.
	 * @param manager The address to be authorized.
	 * @param isAllowed Whether to allow or disallow the manager.
	 * @param nonce Signer's nonce.
	 * @param expiry The duration for which to permit the manager.
	 * @param v Recovery byte of the signature.
	 * @param r Half of the ECDSA signature pair.
	 * @param s Half of the ECDSA signature pair.
	 */
	function toggleAccountManagerWithPermit(
		address market,
		address owner,
		address manager,
		bool isAllowed,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (string memory eventName_, bytes memory eventParam_) {
		CometInterface(market).allowBySig(
			owner,
			manager,
			isAllowed,
			nonce,
			expiry,
			v,
			r,
			s
		);
		eventName_ = "LogToggleAccountManagerWithPermit(address,address,address,bool,uint256,uint256,uint8,bytes32,bytes32)";
		eventParam_ = abi.encode(
			market,
			owner,
			manager,
			isAllowed,
			expiry,
			nonce,
			v,
			r,
			s
		);
	}
}

contract ConnectV2CompoundV3 is CompoundV3Resolver {
	string public name = "CompoundV3-v1.0";
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32[] memory responses);
}

interface ListInterface {
    function accountID(address) external returns (uint64);
}

interface InstaConnectors {
    function isConnectors(string[] calldata) external returns (bool, address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import { TokenInterface } from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { CometInterface } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	struct BorrowWithdrawParams {
		address market;
		address token;
		address from;
		address to;
		uint256 amt;
		uint256 getId;
		uint256 setId;
	}

	struct BuyCollateralData {
		address market;
		address sellToken;
		address buyAsset;
		uint256 unitAmt;
		uint256 baseSellAmt;
	}

	enum Action {
		REPAY,
		DEPOSIT
	}

	function getBaseToken(address market)
		internal
		view
		returns (address baseToken)
	{
		baseToken = CometInterface(market).baseToken();
	}

	function _borrow(BorrowWithdrawParams memory params)
		internal
		returns (uint256 amt, uint256 setId)
	{
		uint256 amt_ = getUint(params.getId, params.amt);

		require(
			params.market != address(0) &&
				params.token != address(0) &&
				params.to != address(0),
			"invalid market/token/to address"
		);
		bool isEth = params.token == ethAddr;
		address token_ = isEth ? wethAddr : params.token;

		TokenInterface tokenContract = TokenInterface(token_);

		params.from = params.from == address(0) ? address(this) : params.from;

		require(
			CometInterface(params.market).balanceOf(params.from) == 0,
			"borrow-disabled-when-supplied-base"
		);

		uint256 initialBal = CometInterface(params.market).borrowBalanceOf(
			params.from
		);

		CometInterface(params.market).withdrawFrom(
			params.from,
			params.to,
			token_,
			amt_
		);

		uint256 finalBal = CometInterface(params.market).borrowBalanceOf(
			params.from
		);
		amt_ = sub(finalBal, initialBal);

		if (params.to == address(this))
			convertWethToEth(isEth, tokenContract, amt_);

		setUint(params.setId, amt_);

		amt = amt_;
		setId = params.setId;
	}

	function _withdraw(BorrowWithdrawParams memory params)
		internal
		returns (uint256 amt, uint256 setId)
	{
		uint256 amt_ = getUint(params.getId, params.amt);

		require(
			params.market != address(0) &&
				params.token != address(0) &&
				params.to != address(0),
			"invalid market/token/to address"
		);

		bool isEth = params.token == ethAddr;
		address token_ = isEth ? wethAddr : params.token;

		TokenInterface tokenContract = TokenInterface(token_);
		params.from = params.from == address(0) ? address(this) : params.from;

		uint256 initialBal = _getAccountSupplyBalanceOfAsset(
			params.from,
			params.market,
			token_
		);

		if (token_ == getBaseToken(params.market)) {
			//if there are supplies, ensure withdrawn amount is not greater than supplied i.e can't borrow using withdraw.
			if (amt_ == uint256(-1)) {
				amt_ = initialBal;
			} else {
				require(
					amt_ <= initialBal,
					"withdraw-amt-greater-than-supplies"
				);
			}

			//if borrow balance > 0, there are no supplies so no withdraw, borrow instead.
			require(
				CometInterface(params.market).borrowBalanceOf(params.from) == 0,
				"withdraw-disabled-for-zero-supplies"
			);
		} else {
			amt_ = amt_ == uint256(-1) ? initialBal : amt_;
		}

		CometInterface(params.market).withdrawFrom(
			params.from,
			params.to,
			token_,
			amt_
		);

		uint256 finalBal = _getAccountSupplyBalanceOfAsset(
			params.from,
			params.market,
			token_
		);
		amt_ = sub(initialBal, finalBal);

		if (params.to == address(this))
			convertWethToEth(isEth, tokenContract, amt_);

		setUint(params.setId, amt_);

		amt = amt_;
		setId = params.setId;
	}

	function _getAccountSupplyBalanceOfAsset(
		address account,
		address market,
		address asset
	) internal returns (uint256 balance) {
		if (asset == getBaseToken(market)) {
			//balance in base
			balance = CometInterface(market).balanceOf(account);
		} else {
			//balance in asset denomination
			balance = uint256(
				CometInterface(market).userCollateral(account, asset).balance
			);
		}
	}

	function _calculateFromAmount(
		address market,
		address token,
		address src,
		uint256 amt,
		bool isEth,
		Action action
	) internal view returns (uint256) {
		if (amt == uint256(-1)) {
			uint256 allowance_ = TokenInterface(token).allowance(src, market);
			uint256 bal_;

			if (action == Action.REPAY) {
				bal_ = CometInterface(market).borrowBalanceOf(src);
			} else if (action == Action.DEPOSIT) {
				if (isEth) bal_ = src.balance;
				else bal_ = TokenInterface(token).balanceOf(src);
			}

			amt = bal_ < allowance_ ? bal_ : allowance_;
		}

		return amt;
	}

	function _buyCollateral(
		BuyCollateralData memory params,
		uint256 getId,
		uint256 setId
	) internal returns (string memory eventName_, bytes memory eventParam_) {
		uint256 sellAmt_ = getUint(getId, params.baseSellAmt);
		require(
			params.market != address(0) && params.buyAsset != address(0),
			"invalid market/token address"
		);

		bool isEth = params.sellToken == ethAddr;
		params.sellToken = isEth ? wethAddr : params.sellToken;

		require(
			params.sellToken == getBaseToken(params.market),
			"invalid-sell-token"
		);

		if (sellAmt_ == uint256(-1)) {
			sellAmt_ = isEth
				? address(this).balance
				: TokenInterface(params.sellToken).balanceOf(address(this));
		}
		convertEthToWeth(isEth, TokenInterface(params.sellToken), sellAmt_);

		isEth = params.buyAsset == ethAddr;
		params.buyAsset = isEth ? wethAddr : params.buyAsset;

		uint256 slippageAmt_ = convert18ToDec(
			TokenInterface(params.buyAsset).decimals(),
			wmul(
				params.unitAmt,
				convertTo18(
					TokenInterface(params.sellToken).decimals(),
					sellAmt_
				)
			)
		);

		uint256 initialCollBal_ = TokenInterface(params.buyAsset).balanceOf(
			address(this)
		);

		approve(TokenInterface(params.sellToken), params.market, sellAmt_);
		CometInterface(params.market).buyCollateral(
			params.buyAsset,
			slippageAmt_,
			sellAmt_,
			address(this)
		);

		uint256 finalCollBal_ = TokenInterface(params.buyAsset).balanceOf(
			address(this)
		);

		uint256 buyAmt_ = sub(finalCollBal_, initialCollBal_);
		require(slippageAmt_ <= buyAmt_, "too-much-slippage");

		convertWethToEth(isEth, TokenInterface(params.buyAsset), buyAmt_);
		setUint(setId, sellAmt_);

		eventName_ = "LogBuyCollateral(address,address,uint256,uint256,uint256,uint256,uint256)";
		eventParam_ = abi.encode(
			params.market,
			params.buyAsset,
			sellAmt_,
			params.unitAmt,
			buyAmt_,
			getId,
			setId
		);
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Events {
	event LogDeposit(
		address indexed market,
		address indexed token,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogDepositOnBehalf(
		address indexed market,
		address indexed token,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogDepositFromUsingManager(
		address indexed market,
		address indexed token,
		address from,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogWithdraw(
		address indexed market,
		address indexed token,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawTo(
		address indexed market,
		address indexed token,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawOnBehalf(
		address indexed market,
		address indexed token,
		address from,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogWithdrawOnBehalfAndTransfer(
		address indexed market,
		address indexed token,
		address from,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBorrow(
		address indexed market,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowTo(
		address indexed market,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowOnBehalf(
		address indexed market,
		address from,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBorrowOnBehalfAndTransfer(
		address indexed market,
		address from,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogPayback(address indexed market, uint256 tokenAmt, uint256 getId, uint256 setId);

	event LogPaybackOnBehalf(
		address indexed market,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogPaybackFromUsingManager(
		address indexed market,
		address from,
		address to,
		uint256 tokenAmt,
		uint256 getId,
		uint256 setId
	);

	event LogBuyCollateral(
		address indexed market,
		address indexed buyToken,
		uint256 indexed baseSellAmt,
		uint256 unitAmt,
		uint256 buyAmount,
		uint256 getId,
		uint256 setId
	);

	event LogTransferAsset(
		address indexed market,
		address token,
		address indexed dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogTransferAssetOnBehalf(
		address indexed market,
		address token,
		address indexed from,
		address indexed dest,
		uint256 amount,
		uint256 getId,
		uint256 setId
	);

	event LogToggleAccountManager(
		address indexed market,
		address indexed manager,
		bool allow
	);

	event LogToggleAccountManagerWithPermit(
		address indexed market,
		address indexed owner,
		address indexed manager,
		bool allow,
		uint256 expiry,
		uint256 nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

struct UserCollateral {
	uint128 balance;
	uint128 _reserved;
}

struct RewardOwed {
	address token;
	uint256 owed;
}

interface CometInterface {
	function supply(address asset, uint256 amount) external virtual;

	function supplyTo(
		address dst,
		address asset,
		uint256 amount
	) external virtual;

	function supplyFrom(
		address from,
		address dst,
		address asset,
		uint256 amount
	) external virtual;

	function transfer(address dst, uint256 amount)
		external
		virtual
		returns (bool);

	function transferFrom(
		address src,
		address dst,
		uint256 amount
	) external virtual returns (bool);

	function transferAsset(
		address dst,
		address asset,
		uint256 amount
	) external virtual;

	function transferAssetFrom(
		address src,
		address dst,
		address asset,
		uint256 amount
	) external virtual;

	function withdraw(address asset, uint256 amount) external virtual;

	function withdrawTo(
		address to,
		address asset,
		uint256 amount
	) external virtual;

	function withdrawFrom(
		address src,
		address to,
		address asset,
		uint256 amount
	) external virtual;

	function approveThis(
		address manager,
		address asset,
		uint256 amount
	) external virtual;

	function withdrawReserves(address to, uint256 amount) external virtual;

	function absorb(address absorber, address[] calldata accounts)
		external
		virtual;

	function buyCollateral(
		address asset,
		uint256 minAmount,
		uint256 baseAmount,
		address recipient
	) external virtual;

	function quoteCollateral(address asset, uint256 baseAmount)
		external
		view
		returns (uint256);

	function userCollateral(address, address)
		external
		returns (UserCollateral memory);

	function baseToken() external view returns (address);

	function balanceOf(address account) external view returns (uint256);

	function borrowBalanceOf(address account) external view returns (uint256);

	function allow(address manager, bool isAllowed_) external;

	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

	function allowBySig(
		address owner,
		address manager,
		bool isAllowed_,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

  function toInt(uint x) internal pure returns (int y) {
    y = int(x);
    require(y >= 0, "int-overflow");
  }

  function toUint(int256 x) internal pure returns (uint256) {
      require(x >= 0, "int-overflow");
      return uint256(x);
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
  }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { TokenInterface } from "./interfaces.sol";
import { Stores } from "./stores.sol";
import { DSMath } from "./math.sol";

abstract contract Basic is DSMath, Stores {

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == ethAddr ? address(this).balance : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == ethAddr ?  18 : buyAddr.decimals();
        sellDec = address(sellAddr) == ethAddr ?  18 : sellAddr.decimals();
    }

    function encodeEvent(string memory eventName, bytes memory eventParam) internal pure returns (bytes memory) {
        return abi.encode(eventName, eventParam);
    }

    function approve(TokenInterface token, address spender, uint256 amount) internal {
        try token.approve(spender, amount) {

        } catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == ethAddr ? TokenInterface(wethAddr) : TokenInterface(buy);
        _sell = sell == ethAddr ? TokenInterface(wethAddr) : TokenInterface(sell);
    }

    function changeEthAddrToWethAddr(address token) internal pure returns(address tokenAddr){
        tokenAddr = token == ethAddr ? wethAddr : token;
    }

    function convertEthToWeth(bool isEth, TokenInterface token, uint amount) internal {
        if(isEth) token.deposit{value: amount}();
    }

    function convertWethToEth(bool isEth, TokenInterface token, uint amount) internal {
       if(isEth) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { MemoryInterface, InstaMapping, ListInterface, InstaConnectors } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F);

  /**
   * @dev Return InstaDApp Mapping Addresses
   */
  InstaMapping constant internal instaMapping = InstaMapping(0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88);

  /**
   * @dev Return InstaList Address
   */
  ListInterface internal constant instaList = ListInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);

  /**
	 * @dev Return connectors registry address
	 */
	InstaConnectors internal constant instaConnectors = InstaConnectors(0x97b0B3A8bDeFE8cB9563a3c610019Ad10DB8aD11);

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}