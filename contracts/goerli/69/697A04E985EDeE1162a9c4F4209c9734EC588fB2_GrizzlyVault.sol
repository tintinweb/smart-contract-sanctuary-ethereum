// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

import { IUniswapV3MintCallback } from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import { IUniswapV3SwapCallback } from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import { GrizzlyVaultStorage } from "./abstract/GrizzlyVaultStorage.sol";
import { TickMath } from "./uniswap/TickMath.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { FullMath, LiquidityAmounts } from "./uniswap/LiquidityAmounts.sol";

contract GrizzlyVault is IUniswapV3MintCallback, IUniswapV3SwapCallback, GrizzlyVaultStorage {
	using SafeERC20 for IERC20;
	using TickMath for int24;

	event Minted(
		address receiver,
		uint256 mintAmount,
		uint256 amount0In,
		uint256 amount1In,
		uint128 liquidityMinted
	);

	event Burned(
		address receiver,
		uint256 burnAmount,
		uint256 amount0Out,
		uint256 amount1Out,
		uint128 liquidityBurned
	);

	event Rebalance(
		int24 lowerTick_,
		int24 upperTick_,
		uint128 liquidityBefore,
		uint128 liquidityAfter
	);

	event FeesEarned(uint256 feesEarned0, uint256 feesEarned1);

	// --- UniV3 callback functions --- //

	/// @notice Uniswap V3 callback function, called back on pool.mint
	function uniswapV3MintCallback(
		uint256 amount0Owed,
		uint256 amount1Owed,
		bytes calldata /*_data*/
	) external override {
		require(msg.sender == address(pool), "callback caller");

		if (amount0Owed > 0) token0.safeTransfer(msg.sender, amount0Owed);
		if (amount1Owed > 0) token1.safeTransfer(msg.sender, amount1Owed);
	}

	/// @notice Uniswap v3 callback function, called back on pool.swap
	function uniswapV3SwapCallback(
		int256 amount0Delta,
		int256 amount1Delta,
		bytes calldata /*data*/
	) external override {
		require(msg.sender == address(pool), "callback caller");

		if (amount0Delta > 0) token0.safeTransfer(msg.sender, uint256(amount0Delta));
		if (amount1Delta > 0) token1.safeTransfer(msg.sender, uint256(amount1Delta));
	}

	// --- User functions --- //

	/// @notice Mint fungible Grizzly Vault tokens, fractional shares of a Uniswap V3 position
	/// @dev To compute the amount of tokens necessary to mint `mintAmount` see getMintAmounts
	/// @param mintAmount The number of Grizzly Vault tokens to mint
	/// @param receiver The account to receive the minted tokens
	/// @return amount0 Amount of token0 transferred from msg.sender to mint `mintAmount`
	/// @return amount1 Amount of token1 transferred from msg.sender to mint `mintAmount`
	/// @return liquidityMinted Amount of liquidity added to the underlying Uniswap V3 position
	// solhint-disable-next-line function-max-lines, code-complexity
	function mint(uint256 mintAmount, address receiver)
		external
		nonReentrant
		returns (
			uint256 amount0,
			uint256 amount1,
			uint128 liquidityMinted
		)
	{
		require(mintAmount > 0, "mint 0");

		uint256 totalSupply = totalSupply();

		Ticks memory ticks = baseTicks;
		(uint160 sqrtRatioX96, , , , , , ) = pool.slot0();

		if (totalSupply > 0) {
			(uint256 amount0Current, uint256 amount1Current) = getUnderlyingBalances();

			amount0 = FullMath.mulDivRoundingUp(amount0Current, mintAmount, totalSupply);
			amount1 = FullMath.mulDivRoundingUp(amount1Current, mintAmount, totalSupply);
		} else {
			// Prevent first staker from stealing funds of subsequent stakers
			// solhint-disable-next-line max-line-length
			// https://code4rena.com/reports/2022-01-sherlock/#h-01-first-user-can-steal-everyone-elses-tokens
			require(mintAmount > MIN_INITIAL_SHARES, "min shares");

			// If supply is 0 mintAmount == liquidity to deposit
			(amount0, amount1) = _amountsForLiquidity(
				SafeCast.toUint128(mintAmount),
				ticks,
				sqrtRatioX96
			);
		}

		// Transfer amounts owed to contract
		if (amount0 > 0) {
			token0.safeTransferFrom(msg.sender, address(this), amount0);
		}
		if (amount1 > 0) {
			token1.safeTransferFrom(msg.sender, address(this), amount1);
		}

		// Deposit as much new liquidity as possible
		liquidityMinted = _liquidityForAmounts(ticks, sqrtRatioX96, amount0, amount1);

		pool.mint(address(this), ticks.lowerTick, ticks.upperTick, liquidityMinted, "");

		_mint(receiver, mintAmount);
		emit Minted(receiver, mintAmount, amount0, amount1, liquidityMinted);
	}

	/// @notice Burn Grizzly Vault tokens (fractional shares of a UniV3 position) and receive tokens
	/// @dev onlyToken0 and onlyToken1 can not be both true, but can be both false
	/// In the case of both false, the user receives the proportional token0 and token1 amounts
	/// @param burnAmount The number of Grizzly Vault tokens to burn
	/// @param onlyToken0 If true the user zaps out with only token0
	/// @param onlyToken1  If true the user zaps out with only token1
	/// @param receiver The account to receive the underlying amounts of token0 and token1
	/// @return amount0 Amount of token0 transferred to receiver for burning `burnAmount`
	/// @return amount1 Amount of token1 transferred to receiver for burning `burnAmount`
	/// @return liquidityBurned Amount of liquidity removed from the underlying Uniswap V3 position
	// solhint-disable-next-line function-max-lines
	function burn(
		uint256 burnAmount,
		bool onlyToken0,
		bool onlyToken1,
		address receiver
	)
		external
		nonReentrant
		returns (
			uint256 amount0,
			uint256 amount1,
			uint128 liquidityBurned
		)
	{
		require(burnAmount > 0, "burn 0");

		_validateValues(onlyToken0, onlyToken1);

		LocalVariables_burn memory vars;

		vars.totalSupply = totalSupply();

		Ticks memory ticks = baseTicks;

		(uint128 liquidity, , , , ) = pool.positions(_getPositionID(ticks));

		_burn(msg.sender, burnAmount);

		vars.liquidityBurnt = FullMath.mulDiv(burnAmount, liquidity, vars.totalSupply);

		liquidityBurned = SafeCast.toUint128(vars.liquidityBurnt);

		(uint256 burn0, uint256 burn1, uint256 fee0, uint256 fee1) = _withdraw(
			ticks,
			liquidityBurned
		);

		(fee0, fee1) = _applyFees(fee0, fee1);

		amount0 =
			burn0 +
			FullMath.mulDiv(
				token0.balanceOf(address(this)) - burn0 - managerBalance0,
				burnAmount,
				vars.totalSupply
			);

		amount1 =
			burn1 +
			FullMath.mulDiv(
				token1.balanceOf(address(this)) - burn1 - managerBalance1,
				burnAmount,
				vars.totalSupply
			);

		// ZapOut logic Note test properly amounts
		if (onlyToken0) {
			(vars.amount0Delta, vars.amount1Delta) = _swap(amount1, false, slippageUserMax);
			amount0 = uint256(SafeCast.toInt256(amount0) - vars.amount0Delta);
			amount1 = uint256(SafeCast.toInt256(amount1) - vars.amount1Delta);
		} else if (onlyToken1) {
			(vars.amount0Delta, vars.amount1Delta) = _swap(amount0, true, slippageUserMax);
			amount0 = uint256(SafeCast.toInt256(amount0) - vars.amount0Delta);
			amount1 = uint256(SafeCast.toInt256(amount1) - vars.amount1Delta);
		}

		_transferAmounts(amount0, amount1, receiver);

		emit Burned(receiver, burnAmount, amount0, amount1, liquidityBurned);
	}

	// --- External manager functions --- // Called by Pool Manager

	/// @notice Change the range of underlying UniswapV3 position, only manager can call
	/// @dev When changing the range the inventory of token0 and token1 may be rebalanced
	/// with a swap to deposit as much liquidity as possible into the new position.
	/// Swap a proportion of this leftover to deposit more liquidity into the position,
	/// since any leftover will be unused and sit idle until the next rebalance
	/// @param newLowerTick The new lower bound of the position's range
	/// @param newUpperTick The new upper bound of the position's range
	/// @param minLiquidity Minimum liquidity of the new position in order to not revert
	// solhint-disable-next-line function-max-lines
	function executiveRebalance(
		int24 newLowerTick,
		int24 newUpperTick,
		uint128 minLiquidity
	) external onlyManager {
		// First check pool health
		_checkPriceSlippage();

		uint128 liquidity;
		uint128 newLiquidity;

		Ticks memory ticks = baseTicks;
		Ticks memory newTicks = Ticks(newLowerTick, newUpperTick);

		if (totalSupply() > 0) {
			(liquidity, , , , ) = pool.positions(_getPositionID(ticks));
			if (liquidity > 0) {
				(, , uint256 fee0, uint256 fee1) = _withdraw(ticks, liquidity);

				(fee0, fee1) = _applyFees(fee0, fee1);
			}

			// Update storage ticks
			baseTicks = newTicks;

			uint256 reinvest0 = token0.balanceOf(address(this)) - managerBalance0;
			uint256 reinvest1 = token1.balanceOf(address(this)) - managerBalance1;

			(uint256 finalAmount0, uint256 finalAmount1) = _balanceAmounts(
				newTicks,
				reinvest0,
				reinvest1
			);

			_addLiquidity(ticks, finalAmount0, finalAmount1);

			(newLiquidity, , , , ) = pool.positions(_getPositionID(newTicks));
			require(newLiquidity > minLiquidity, "min liquidity");
		} else {
			// Update storage ticks
			baseTicks = newTicks;
		}

		emit Rebalance(newLowerTick, newUpperTick, liquidity, newLiquidity);
	}

	// --- External authorized functions --- //  Can be automated

	/// @notice Reinvest fees earned into underlying position, only authorized executors can call
	/// @dev As the ticks do not change, liquidity must increase, otherwise will revert
	/// Position bounds CANNOT be altered, only manager may via executiveRebalance
	function rebalance() external onlyAuthorized {
		// First check pool health
		_checkPriceSlippage();

		Ticks memory ticks = baseTicks;

		// In rebalance ticks remain the same
		bytes32 key = _getPositionID(ticks);

		(uint128 liquidity, , , , ) = pool.positions(key);

		_rebalance(liquidity, ticks);

		(uint128 newLiquidity, , , , ) = pool.positions(key);
		require(newLiquidity > liquidity, "liquidity must increase");

		emit Rebalance(ticks.lowerTick, ticks.upperTick, liquidity, newLiquidity);
	}

	/// @notice Withdraw manager fees accrued, only authorized executors can call
	/// Target account to receive fees is managerTreasury, alterable by only manager
	function withdrawManagerBalance() external onlyAuthorized {
		uint256 amount0 = managerBalance0;
		uint256 amount1 = managerBalance1;

		managerBalance0 = 0;
		managerBalance1 = 0;

		_transferAmounts(amount0, amount1, managerTreasury);
	}

	// --- External view functions --- //

	/// @notice Compute max Grizzly Vault tokens that can be minted from `amount0Max` & `amount1Max`
	/// @param amount0Max The maximum amount of token0 to forward on mint
	/// @param amount0Max The maximum amount of token1 to forward on mint
	/// @return amount0 Actual amount of token0 to forward when minting `mintAmount`
	/// @return amount1 Actual amount of token1 to forward when minting `mintAmount`
	/// @return mintAmount Maximum number of Grizzly Vault tokens to mint
	function getMintAmounts(uint256 amount0Max, uint256 amount1Max)
		external
		view
		returns (
			uint256 amount0,
			uint256 amount1,
			uint256 mintAmount
		)
	{
		uint256 totalSupply = totalSupply();

		if (totalSupply > 0) {
			(amount0, amount1, mintAmount) = _computeMintAmounts(
				totalSupply,
				amount0Max,
				amount1Max
			);
		} else {
			Ticks memory ticks = baseTicks;
			(uint160 sqrtRatioX96, , , , , , ) = pool.slot0();

			uint128 newLiquidity = _liquidityForAmounts(ticks, sqrtRatioX96, amount0Max, amount1Max);

			mintAmount = uint256(newLiquidity);
			(amount0, amount1) = _amountsForLiquidity(newLiquidity, ticks, sqrtRatioX96);
		}
	}

	/// @notice Compute total underlying holdings of the Grizzly Vault token supply
	/// Includes current liquidity invested in uniswap position, current fees earned
	/// and any uninvested leftover (but does not include manager or gelato fees accrued)
	/// @return amount0Current current total underlying balance of token0
	/// @return amount1Current current total underlying balance of token1
	function getUnderlyingBalances()
		public
		view
		returns (uint256 amount0Current, uint256 amount1Current)
	{
		(uint160 sqrtRatioX96, int24 tick, , , , , ) = pool.slot0();
		return _getUnderlyingBalances(sqrtRatioX96, tick);
	}

	function getUnderlyingBalancesAtPrice(uint160 sqrtRatioX96)
		external
		view
		returns (uint256 amount0Current, uint256 amount1Current)
	{
		(, int24 tick, , , , , ) = pool.slot0();
		return _getUnderlyingBalances(sqrtRatioX96, tick);
	}

	function estimateFees() external view returns (uint256 token0Fee, uint256 token1Fee) {
		(, int24 currentTick, , , , , ) = pool.slot0();

		Ticks memory ticks = baseTicks;

		(
			uint128 liquidity,
			uint256 feeGrowthInside0Last,
			uint256 feeGrowthInside1Last,
			uint128 tokensOwed0,
			uint128 tokensOwed1
		) = pool.positions(_getPositionID(ticks));

		// Compute current fees earned
		token0Fee =
			_computeFeesEarned(true, feeGrowthInside0Last, currentTick, liquidity, ticks) +
			tokensOwed0;
		token1Fee =
			_computeFeesEarned(false, feeGrowthInside1Last, currentTick, liquidity, ticks) +
			tokensOwed1;
	}

	// --- Internal core functions --- //

	function _rebalance(uint128 liquidity, Ticks memory ticks) internal {
		(, , uint256 feesEarned0, uint256 feesEarned1) = _withdraw(ticks, liquidity);

		(feesEarned0, feesEarned1) = _applyFees(feesEarned0, feesEarned1);

		uint256 leftover0 = token0.balanceOf(address(this)) - managerBalance0;
		uint256 leftover1 = token1.balanceOf(address(this)) - managerBalance1;

		(uint256 finalAmount0, uint256 finalAmount1) = _balanceAmounts(
			ticks,
			leftover0,
			leftover1
		);

		_addLiquidity(ticks, finalAmount0, finalAmount1);
	}

	function _withdraw(Ticks memory ticks, uint128 liquidity)
		internal
		returns (
			uint256 burn0,
			uint256 burn1,
			uint256 fee0,
			uint256 fee1
		)
	{
		uint256 preBalance0 = token0.balanceOf(address(this));
		uint256 preBalance1 = token1.balanceOf(address(this));

		(burn0, burn1) = pool.burn(ticks.lowerTick, ticks.upperTick, liquidity);

		pool.collect(
			address(this),
			ticks.lowerTick,
			ticks.upperTick,
			type(uint128).max,
			type(uint128).max
		);

		fee0 = token0.balanceOf(address(this)) - preBalance0 - burn0;
		fee1 = token1.balanceOf(address(this)) - preBalance1 - burn1;
	}

	function _balanceAmounts(
		Ticks memory ticks,
		uint256 amount0Desired,
		uint256 amount1Desired
	) internal returns (uint256 finalAmount0, uint256 finalAmount1) {
		(uint160 sqrtRatioX96, , , , , , ) = pool.slot0();

		// Get max liquidity for amounts available
		uint128 liquidity = _liquidityForAmounts(
			ticks,
			sqrtRatioX96,
			amount0Desired,
			amount1Desired
		);
		// Get correct amounts of each token for the liquidity we have
		(uint256 amount0, uint256 amount1) = _amountsForLiquidity(liquidity, ticks, sqrtRatioX96);

		// Determine the trade direction
		bool _zeroForOne;
		if (amount1Desired == 0) {
			_zeroForOne = true;
		} else {
			_zeroForOne = _amountsDirection(amount0Desired, amount1Desired, amount0, amount1);
		}

		// Determine the amount to swap, it is not 100% precise but is a very good approximation
		uint256 _amountSpecified = _zeroForOne
			? (amount0Desired - (((amount0 * (basisOne + uniPoolFee / 2)) / basisOne))) / 2
			: (amount1Desired - (((amount1 * (basisOne + uniPoolFee / 2)) / basisOne))) / 2;

		if (_amountSpecified > 0) {
			(int256 amount0Delta, int256 amount1Delta) = _swap(
				_amountSpecified,
				_zeroForOne,
				slippageRebalanceMax
			);
			finalAmount0 = uint256(SafeCast.toInt256(amount0) - amount0Delta);
			finalAmount1 = uint256(SafeCast.toInt256(amount1) - amount1Delta);
		} else {
			return (amount0, amount1);
		}
	}

	function _addLiquidity(
		Ticks memory ticks,
		uint256 amount0,
		uint256 amount1
	) internal {
		// As we have made a swap in the pool sqrtRatioX96 changes
		(uint160 sqrtRatioX96, , , , , , ) = pool.slot0();

		uint128 liquidityAfterSwap = _liquidityForAmounts(ticks, sqrtRatioX96, amount0, amount1);

		if (liquidityAfterSwap > 0) {
			pool.mint(address(this), ticks.lowerTick, ticks.upperTick, liquidityAfterSwap, "");
		}
	}

	/// @notice slippageMax variable as argument to differentiate between user and rebalance swaps
	function _swap(
		uint256 amountIn,
		bool zeroForOne,
		uint256 slippageMax
	) internal returns (int256, int256) {
		(uint160 _sqrtPriceX96, , , , , , ) = pool.slot0();
		uint256 _slippage = zeroForOne ? (basisOne - slippageMax) : (basisOne + slippageMax);
		return
			pool.swap(
				address(this),
				zeroForOne, // Swap direction, true: token0 -> token1, false: token1 -> token0
				int256(amountIn),
				uint160(uint256((_sqrtPriceX96 * _slippage) / basisOne)), // sqrtPriceLimitX96
				abi.encode(0)
			);
	}

	function _transferAmounts(
		uint256 amount0,
		uint256 amount1,
		address receiver
	) internal {
		if (amount0 > 0) {
			token0.safeTransfer(receiver, amount0);
		}

		if (amount1 > 0) {
			token1.safeTransfer(receiver, amount1);
		}
	}

	function _applyFees(uint256 rawFee0, uint256 rawFee1)
		internal
		returns (uint256 fee0, uint256 fee1)
	{
		uint256 managerFee0 = (rawFee0 * managerFeeBPS) / basisOne;
		uint256 managerFee1 = (rawFee1 * managerFeeBPS) / basisOne;

		managerBalance0 += managerFee0;
		managerBalance1 += managerFee1;

		fee0 = rawFee0 - managerFee0;
		fee1 = rawFee1 - managerFee1;

		emit FeesEarned(fee0, fee1);
	}

	// --- Internal view functions --- //

	function _getUnderlyingBalances(uint160 sqrtRatioX96, int24 tick)
		internal
		view
		returns (uint256 amount0Current, uint256 amount1Current)
	{
		Ticks memory ticks = baseTicks;

		(
			uint128 liquidity,
			uint256 feeGrowthInside0Last,
			uint256 feeGrowthInside1Last,
			uint128 tokensOwed0,
			uint128 tokensOwed1
		) = pool.positions(_getPositionID(ticks));

		// Compute current holdings from liquidity
		(amount0Current, amount1Current) = _amountsForLiquidity(liquidity, ticks, sqrtRatioX96);

		// Compute current fees earned
		uint256 fee0 = _computeFeesEarned(true, feeGrowthInside0Last, tick, liquidity, ticks) +
			uint256(tokensOwed0);
		uint256 fee1 = _computeFeesEarned(false, feeGrowthInside1Last, tick, liquidity, ticks) +
			uint256(tokensOwed1);

		fee0 = (fee0 * (basisOne - managerFeeBPS)) / basisOne;
		fee1 = (fee1 * (basisOne - managerFeeBPS)) / basisOne;

		// Add any leftover in contract to current holdings
		amount0Current += fee0 + token0.balanceOf(address(this)) - managerBalance0;
		amount1Current += fee1 + token1.balanceOf(address(this)) - managerBalance1;
	}

	/// @notice Computes the token0 and token1 value for a given amount of liquidity
	function _amountsForLiquidity(
		uint128 liquidity,
		Ticks memory ticks,
		uint160 sqrtRatioX96
	) internal view returns (uint256, uint256) {
		return
			LiquidityAmounts.getAmountsForLiquidity(
				sqrtRatioX96,
				ticks.lowerTick.getSqrtRatioAtTick(),
				ticks.upperTick.getSqrtRatioAtTick(),
				liquidity
			);
	}

	/// @notice Gets the liquidity for the available amounts of token0 and token1
	function _liquidityForAmounts(
		Ticks memory ticks,
		uint160 sqrtRatioX96,
		uint256 amount0,
		uint256 amount1
	) internal view returns (uint128) {
		return
			LiquidityAmounts.getLiquidityForAmounts(
				sqrtRatioX96,
				ticks.lowerTick.getSqrtRatioAtTick(),
				ticks.upperTick.getSqrtRatioAtTick(),
				amount0,
				amount1
			);
	}

	function _validateValues(bool onlyToken0, bool onlyToken1) internal view {
		if (onlyToken0 && onlyToken1) revert("invalid inputs");
	}

	function _computeMintAmounts(
		uint256 totalSupply,
		uint256 amount0Max,
		uint256 amount1Max
	)
		internal
		view
		returns (
			uint256 amount0,
			uint256 amount1,
			uint256 mintAmount
		)
	{
		(uint256 amount0Current, uint256 amount1Current) = getUnderlyingBalances();

		// Compute proportional amount of tokens to mint
		if (amount0Current == 0 && amount1Current > 0) {
			mintAmount = FullMath.mulDiv(amount1Max, totalSupply, amount1Current);
		} else if (amount1Current == 0 && amount0Current > 0) {
			mintAmount = FullMath.mulDiv(amount0Max, totalSupply, amount0Current);
		} else if (amount0Current == 0 && amount1Current == 0) {
			revert("no balances");
		} else {
			// Only if both are non-zero
			uint256 amount0Mint = FullMath.mulDiv(amount0Max, totalSupply, amount0Current);
			uint256 amount1Mint = FullMath.mulDiv(amount1Max, totalSupply, amount1Current);
			require(amount0Mint > 0 && amount1Mint > 0, "mint 0");

			mintAmount = amount0Mint < amount1Mint ? amount0Mint : amount1Mint;
		}

		// Compute amounts owed to contract
		amount0 = FullMath.mulDivRoundingUp(mintAmount, amount0Current, totalSupply);
		amount1 = FullMath.mulDivRoundingUp(mintAmount, amount1Current, totalSupply);
	}

	// solhint-disable-next-line function-max-lines
	function _computeFeesEarned(
		bool isZero,
		uint256 feeGrowthInsideLast,
		int24 tick,
		uint128 liquidity,
		Ticks memory ticks
	) internal view returns (uint256 fee) {
		uint256 feeGrowthOutsideLower;
		uint256 feeGrowthOutsideUpper;
		uint256 feeGrowthGlobal;

		if (isZero) {
			feeGrowthGlobal = pool.feeGrowthGlobal0X128();
			(, , feeGrowthOutsideLower, , , , , ) = pool.ticks(ticks.lowerTick);
			(, , feeGrowthOutsideUpper, , , , , ) = pool.ticks(ticks.upperTick);
		} else {
			feeGrowthGlobal = pool.feeGrowthGlobal1X128();
			(, , , feeGrowthOutsideLower, , , , ) = pool.ticks(ticks.lowerTick);
			(, , , feeGrowthOutsideUpper, , , , ) = pool.ticks(ticks.upperTick);
		}

		unchecked {
			// Calculate fee growth below
			uint256 feeGrowthBelow;
			if (tick >= ticks.lowerTick) {
				feeGrowthBelow = feeGrowthOutsideLower;
			} else {
				feeGrowthBelow = feeGrowthGlobal - feeGrowthOutsideLower;
			}

			// Calculate fee growth above
			uint256 feeGrowthAbove;
			if (tick < ticks.upperTick) {
				feeGrowthAbove = feeGrowthOutsideUpper;
			} else {
				feeGrowthAbove = feeGrowthGlobal - feeGrowthOutsideUpper;
			}

			uint256 feeGrowthInside = feeGrowthGlobal - feeGrowthBelow - feeGrowthAbove;
			fee = FullMath.mulDiv(
				liquidity,
				feeGrowthInside - feeGrowthInsideLast,
				0x100000000000000000000000000000000
			);
		}
	}

	/// @dev Needed in case token0 and token1 have different decimals
	function _amountsDirection(
		uint256 amount0Desired,
		uint256 amount1Desired,
		uint256 amount0,
		uint256 amount1
	) internal pure returns (bool zeroGreaterOne) {
		zeroGreaterOne = (amount0Desired - amount0) * amount1Desired >
			(amount1Desired - amount1) * amount0Desired
			? true
			: false;
	}

	function _checkPriceSlippage() internal view {
		uint32[] memory secondsAgo = new uint32[](2);
		secondsAgo[0] = oracleSlippageInterval;
		secondsAgo[1] = 0;

		(int56[] memory tickCumulatives, ) = pool.observe(secondsAgo);

		require(tickCumulatives.length == 2, "array length");
		uint160 avgSqrtRatioX96;
		unchecked {
			int24 avgTick = int24(
				(tickCumulatives[1] - tickCumulatives[0]) / int56(uint56(oracleSlippageInterval))
			);
			avgSqrtRatioX96 = avgTick.getSqrtRatioAtTick();
		}

		(uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

		uint160 diff = avgSqrtRatioX96 > sqrtPriceX96
			? avgSqrtRatioX96 - sqrtPriceX96
			: sqrtPriceX96 - avgSqrtRatioX96;

		uint160 maxSlippage = (avgSqrtRatioX96 * oracleSlippageBPS) / 10000;

		require(diff < maxSlippage, "high slippage");
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

import { OwnableUninitialized } from "./OwnableUninitialized.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { IUniswapV3TickSpacing } from "../interfaces/IUniswapV3TickSpacing.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { IGrizzlyVaultStorage } from "../interfaces/IGrizzlyVaultStorage.sol";

/// @dev Single Global upgradeable state var storage base
/// @dev Add all inherited contracts with state vars here
/// @dev ERC20Upgradable Includes Initialize
// solhint-disable-next-line max-states-count
abstract contract GrizzlyVaultStorage is
	IGrizzlyVaultStorage,
	ERC20Upgradeable,
	ReentrancyGuardUpgradeable,
	OwnableUninitialized
{
	string public constant version = "1.0.0";

	Ticks public baseTicks;

	uint16 public oracleSlippageBPS;
	uint32 public oracleSlippageInterval;

	uint16 public managerFeeBPS;
	address public managerTreasury;

	uint256 public managerBalance0;
	uint256 public managerBalance1;

	IUniswapV3Pool public pool;
	IERC20 public token0;
	IERC20 public token1;
	uint24 public uniPoolFee;

	uint256 internal constant MIN_INITIAL_SHARES = 1e9;
	uint256 internal constant basisOne = 10000;

	// In bps, how much slippage we allow between swaps -> 50 = 0.5% slippage
	uint256 public slippageUserMax = 100;
	uint256 public slippageRebalanceMax = 100;

	address public immutable factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

	address public keeperAddress;

	event UpdateGelatoParams(uint16 oracleSlippageBPS, uint32 oracleSlippageInterval);
	event SetManagerFee(uint16 managerFee);

	modifier onlyAuthorized() {
		require(msg.sender == manager() || msg.sender == keeperAddress, "not authorized");
		_;
	}

	/// @notice Initialize storage variables on a new Grizzly vault pool, only called once
	/// @param _name Name of Grizzly vault token
	/// @param _symbol Symbol of Grizzly vault token
	/// @param _pool Address of Uniswap V3 pool
	/// @param _managerFeeBPS Proportion of fees earned that go to manager treasury
	/// Note that the 4 above params are NOT UPDATABLE AFTER INITIALIZATION
	/// @param _lowerTick Initial lowerTick (only changeable with executiveRebalance)
	/// @param _lowerTick Initial upperTick (only changeable with executiveRebalance)
	/// @param _manager_ Address of manager (ownership can be transferred)
	function initialize(
		string memory _name,
		string memory _symbol,
		address _pool,
		uint16 _managerFeeBPS,
		int24 _lowerTick,
		int24 _upperTick,
		address _manager_
	) external override initializer {
		require(_managerFeeBPS <= 10000, "bps");

		_validateTickSpacing(_pool, _lowerTick, _upperTick);

		// These variables are immutable after initialization
		pool = IUniswapV3Pool(_pool);
		token0 = IERC20(pool.token0());
		token1 = IERC20(pool.token1());
		uniPoolFee = pool.fee();
		managerFeeBPS = _managerFeeBPS; // if set to 0 here manager can still initialize later

		// These variables can be updated by the manager
		oracleSlippageInterval = 5 minutes; // default: last five minutes;
		oracleSlippageBPS = 500; // default: 5% slippage

		managerTreasury = _manager_; // default: treasury is admin

		baseTicks.lowerTick = _lowerTick;
		baseTicks.upperTick = _upperTick;

		_manager = _manager_;

		// e.g. "Grizzly Uniswap USDC/DAI LP" and "hsUSDC-DAI"
		__ERC20_init(_name, _symbol);
		__ReentrancyGuard_init();
	}

	/// @notice Change configurable parameters, only manager can call
	/// @param newOracleSlippageBPS Maximum slippage on swaps during gelato rebalance
	/// @param newOracleSlippageInterval Length of time for TWAP used in computing slippage on swaps
	/// @param newTreasury Address where managerFee withdrawals are sent
	function updateConfigParams(
		uint16 newOracleSlippageBPS,
		uint32 newOracleSlippageInterval,
		address newTreasury
	) external onlyManager {
		require(newOracleSlippageBPS <= 10000, "bps");

		if (newOracleSlippageBPS != 0) oracleSlippageBPS = newOracleSlippageBPS;
		if (newOracleSlippageInterval != 0) oracleSlippageInterval = newOracleSlippageInterval;
		emit UpdateGelatoParams(newOracleSlippageBPS, newOracleSlippageInterval);

		if (newTreasury != address(0)) managerTreasury = newTreasury;
	}

	/// @notice setManagerFee sets a managerFee, only manager can call
	/// @param _managerFeeBPS Proportion of fees earned that are credited to manager in Basis Points
	function setManagerFee(uint16 _managerFeeBPS) external onlyManager {
		require(_managerFeeBPS > 0 && _managerFeeBPS <= 10000, "bps");
		emit SetManagerFee(_managerFeeBPS);
		managerFeeBPS = _managerFeeBPS;
	}

	function getPositionID() external view returns (bytes32 positionID) {
		return _getPositionID(baseTicks);
	}

	function _getPositionID(Ticks memory _ticks) internal view returns (bytes32 positionID) {
		return keccak256(abi.encodePacked(address(this), _ticks.lowerTick, _ticks.upperTick));
	}

	function setKeeperAddress(address _keeperAddress) external onlyManager {
		require(_keeperAddress != address(0), "zeroAddress");
		keeperAddress = _keeperAddress;
	}

	function setManagerParams(uint256 _slippageUserMax, uint256 _slippageRebalanceMax)
		external
		onlyManager
	{
		require(_slippageUserMax <= basisOne && _slippageRebalanceMax <= basisOne, "wrong inputs");
		slippageUserMax = _slippageUserMax;
		slippageRebalanceMax = _slippageRebalanceMax;
	}

	function _validateTickSpacing(
		address uniPool,
		int24 lowerTick,
		int24 upperTick
	) internal view returns (bool) {
		int24 spacing = IUniswapV3TickSpacing(uniPool).tickSpacing();
		return lowerTick < upperTick && lowerTick % spacing == 0 && upperTick % spacing == 0;
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
	/// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
	int24 internal constant MIN_TICK = -887272;
	/// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
	int24 internal constant MAX_TICK = -MIN_TICK;

	/// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
	uint160 internal constant MIN_SQRT_RATIO = 4295128739;
	/// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
	uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

	/// @notice Calculates sqrt(1.0001^tick) * 2^96
	/// @dev Throws if |tick| > max tick
	/// @param tick The input tick for the above formula
	/// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
	/// at the given tick
	function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
		uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));

		// EDIT: 0.8 compatibility
		require(absTick <= uint256(int256(MAX_TICK)), "T");

		uint256 ratio = absTick & 0x1 != 0
			? 0xfffcb933bd6fad37aa2d162d1a594001
			: 0x100000000000000000000000000000000;
		if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
		if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
		if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
		if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
		if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
		if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
		if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
		if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
		if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
		if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
		if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
		if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
		if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
		if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
		if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
		if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
		if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
		if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
		if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

		if (tick > 0) ratio = type(uint256).max / ratio;

		// this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
		// we then downcast because we know the result always fits within 160 bits due to our tick input constraint
		// we round up in the division so getTickAtSqrtRatio of the output price is always consistent
		sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
	}

	/// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
	/// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
	/// ever return.
	/// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
	/// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
	function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
		// second inequality must be < because the price can never reach the price at the max tick
		require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
		uint256 ratio = uint256(sqrtPriceX96) << 32;

		uint256 r = ratio;
		uint256 msb = 0;

		assembly {
			let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(5, gt(r, 0xFFFFFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(4, gt(r, 0xFFFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(3, gt(r, 0xFF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(2, gt(r, 0xF))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := shl(1, gt(r, 0x3))
			msb := or(msb, f)
			r := shr(f, r)
		}
		assembly {
			let f := gt(r, 0x1)
			msb := or(msb, f)
		}

		if (msb >= 128) r = ratio >> (msb - 127);
		else r = ratio << (127 - msb);

		int256 log_2 = (int256(msb) - 128) << 64;

		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(63, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(62, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(61, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(60, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(59, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(58, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(57, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(56, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(55, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(54, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(53, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(52, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(51, f))
			r := shr(f, r)
		}
		assembly {
			r := shr(127, mul(r, r))
			let f := shr(128, r)
			log_2 := or(log_2, shl(50, f))
		}

		int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

		int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
		int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

		tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
			? tickHi
			: tickLow;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import { FullMath } from "./FullMath.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
	function toUint128(uint256 x) private pure returns (uint128 y) {
		require((y = uint128(x)) == x);
	}

	/// @notice Computes the amount of liquidity received for a given amount of token0 and price range
	/// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower)).
	/// @param sqrtRatioAX96 A sqrt price
	/// @param sqrtRatioBX96 Another sqrt price
	/// @param amount0 The amount0 being sent in
	/// @return liquidity The amount of returned liquidity
	function getLiquidityForAmount0(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint256 amount0
	) internal pure returns (uint128 liquidity) {
		if (sqrtRatioAX96 > sqrtRatioBX96)
			(sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
		uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
		return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
	}

	/// @notice Computes the amount of liquidity received for a given amount of token1 and price range
	/// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
	/// @param sqrtRatioAX96 A sqrt price
	/// @param sqrtRatioBX96 Another sqrt price
	/// @param amount1 The amount1 being sent in
	/// @return liquidity The amount of returned liquidity
	function getLiquidityForAmount1(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint256 amount1
	) internal pure returns (uint128 liquidity) {
		if (sqrtRatioAX96 > sqrtRatioBX96)
			(sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
		return
			toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
	}

	/// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
	/// pool prices and the prices at the tick boundaries
	function getLiquidityForAmounts(
		uint160 sqrtRatioX96,
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint256 amount0,
		uint256 amount1
	) internal pure returns (uint128 liquidity) {
		if (sqrtRatioAX96 > sqrtRatioBX96)
			(sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

		if (sqrtRatioX96 <= sqrtRatioAX96) {
			liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
		} else if (sqrtRatioX96 < sqrtRatioBX96) {
			uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
			uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

			liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
		} else {
			liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
		}
	}

	/// @notice Computes the amount of token0 for a given amount of liquidity and a price range
	/// @param sqrtRatioAX96 A sqrt price
	/// @param sqrtRatioBX96 Another sqrt price
	/// @param liquidity The liquidity being valued
	/// @return amount0 The amount0
	function getAmount0ForLiquidity(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint128 liquidity
	) internal pure returns (uint256 amount0) {
		if (sqrtRatioAX96 > sqrtRatioBX96)
			(sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

		return
			FullMath.mulDiv(
				uint256(liquidity) << FixedPoint96.RESOLUTION,
				sqrtRatioBX96 - sqrtRatioAX96,
				sqrtRatioBX96
			) / sqrtRatioAX96;
	}

	/// @notice Computes the amount of token1 for a given amount of liquidity and a price range
	/// @param sqrtRatioAX96 A sqrt price
	/// @param sqrtRatioBX96 Another sqrt price
	/// @param liquidity The liquidity being valued
	/// @return amount1 The amount1
	function getAmount1ForLiquidity(
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint128 liquidity
	) internal pure returns (uint256 amount1) {
		if (sqrtRatioAX96 > sqrtRatioBX96)
			(sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

		return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
	}

	/// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
	/// pool prices and the prices at the tick boundaries
	function getAmountsForLiquidity(
		uint160 sqrtRatioX96,
		uint160 sqrtRatioAX96,
		uint160 sqrtRatioBX96,
		uint128 liquidity
	) internal pure returns (uint256 amount0, uint256 amount1) {
		if (sqrtRatioAX96 > sqrtRatioBX96)
			(sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

		if (sqrtRatioX96 <= sqrtRatioAX96) {
			amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
		} else if (sqrtRatioX96 < sqrtRatioBX96) {
			amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
			amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
		} else {
			amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
		}
	}
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an manager) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the manager account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */

abstract contract OwnableUninitialized {
	address internal _manager;

	event OwnershipTransferred(address indexed previousManager, address indexed newManager);

	/// @dev Initializes the contract setting the deployer as the initial manager.
	/// CONSTRUCTOR EMPTY - USE INITIALIZABLE INSTEAD
	// solhint-disable-next-line no-empty-blocks
	constructor() {}

	/**
	 * @dev Returns the address of the current manager.
	 */
	function manager() public view virtual returns (address) {
		return _manager;
	}

	/**
	 * @dev Throws if called by any account other than the manager.
	 */
	modifier onlyManager() {
		require(manager() == msg.sender, "Ownable: caller is not the manager");
		_;
	}

	/**
	 * @dev Leaves the contract without manager. It will not be possible to call
	 * `onlyManager` functions anymore. Can only be called by the current manager.
	 *
	 * NOTE: Renouncing ownership will leave the contract without an manager,
	 * thereby removing any functionality that is only available to the manager.
	 */
	function renounceOwnership() public virtual onlyManager {
		emit OwnershipTransferred(_manager, address(0));
		_manager = address(0);
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current manager.
	 */
	function transferOwnership(address newOwner) public virtual onlyManager {
		require(newOwner != address(0), "Ownable: new manager is the zero address");
		emit OwnershipTransferred(_manager, newOwner);
		_manager = newOwner;
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

interface IUniswapV3TickSpacing {
	function tickSpacing() external view returns (int24);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[45] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

interface IGrizzlyVaultStorage {
	// Needed to avoid error compiler stack too deep
	struct LocalVariables_burn {
		uint256 totalSupply;
		uint256 liquidityBurnt;
		int256 amount0Delta;
		int256 amount1Delta;
	}

	struct Ticks {
		int24 lowerTick;
		int24 upperTick;
	}

	function initialize(
		string memory _name,
		string memory _symbol,
		address _pool,
		uint16 _managerFeeBPS,
		int24 _lowerTick,
		int24 _upperTick,
		address _manager
	) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
	/// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
	/// @param a The multiplicand
	/// @param b The multiplier
	/// @param denominator The divisor
	/// @return result The 256-bit result
	/// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
	function mulDiv(
		uint256 a,
		uint256 b,
		uint256 denominator
	) internal pure returns (uint256 result) {
		unchecked {
			// 512-bit multiply [prod1 prod0] = a * b
			// Compute the product mod 2**256 and mod 2**256 - 1
			// then use the Chinese Remainder Theorem to reconstruct
			// the 512 bit result. The result is stored in two 256
			// variables such that product = prod1 * 2**256 + prod0
			uint256 prod0; // Least significant 256 bits of the product
			uint256 prod1; // Most significant 256 bits of the product
			assembly {
				let mm := mulmod(a, b, not(0))
				prod0 := mul(a, b)
				prod1 := sub(sub(mm, prod0), lt(mm, prod0))
			}

			// Handle non-overflow cases, 256 by 256 division
			if (prod1 == 0) {
				require(denominator > 0);
				assembly {
					result := div(prod0, denominator)
				}
				return result;
			}

			// Make sure the result is less than 2**256.
			// Also prevents denominator == 0
			require(denominator > prod1);

			///////////////////////////////////////////////
			// 512 by 256 division.
			///////////////////////////////////////////////

			// Make division exact by subtracting the remainder from [prod1 prod0]
			// Compute remainder using mulmod
			uint256 remainder;
			assembly {
				remainder := mulmod(a, b, denominator)
			}
			// Subtract 256 bit number from 512 bit number
			assembly {
				prod1 := sub(prod1, gt(remainder, prod0))
				prod0 := sub(prod0, remainder)
			}

			// Factor powers of two out of denominator
			// Compute largest power of two divisor of denominator.
			// Always >= 1.
			// EDIT for 0.8 compatibility:
			// see: https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
			uint256 twos = denominator & (~denominator + 1);

			// Divide denominator by power of two
			assembly {
				denominator := div(denominator, twos)
			}

			// Divide [prod1 prod0] by the factors of two
			assembly {
				prod0 := div(prod0, twos)
			}
			// Shift in bits from prod1 into prod0. For this we need
			// to flip `twos` such that it is 2**256 / twos.
			// If twos is zero, then it becomes one
			assembly {
				twos := add(div(sub(0, twos), twos), 1)
			}
			prod0 |= prod1 * twos;

			// Invert denominator mod 2**256
			// Now that denominator is an odd number, it has an inverse
			// modulo 2**256 such that denominator * inv = 1 mod 2**256.
			// Compute the inverse by starting with a seed that is correct
			// correct for four bits. That is, denominator * inv = 1 mod 2**4
			uint256 inv = (3 * denominator) ^ 2;
			// Now use Newton-Raphson iteration to improve the precision.
			// Thanks to Hensel's lifting lemma, this also works in modular
			// arithmetic, doubling the correct bits in each step.
			inv *= 2 - denominator * inv; // inverse mod 2**8
			inv *= 2 - denominator * inv; // inverse mod 2**16
			inv *= 2 - denominator * inv; // inverse mod 2**32
			inv *= 2 - denominator * inv; // inverse mod 2**64
			inv *= 2 - denominator * inv; // inverse mod 2**128
			inv *= 2 - denominator * inv; // inverse mod 2**256

			// Because the division is now exact we can divide by multiplying
			// with the modular inverse of denominator. This will give us the
			// correct result modulo 2**256. Since the precoditions guarantee
			// that the outcome is less than 2**256, this is the final result.
			// We don't need to compute the high bits of the result and prod1
			// is no longer required.
			result = prod0 * inv;
			return result;
		}
	}

	/// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
	/// @param a The multiplicand
	/// @param b The multiplier
	/// @param denominator The divisor
	/// @return result The 256-bit result
	function mulDivRoundingUp(
		uint256 a,
		uint256 b,
		uint256 denominator
	) internal pure returns (uint256 result) {
		result = mulDiv(a, b, denominator);
		if (mulmod(a, b, denominator) > 0) {
			require(result < type(uint256).max);
			result++;
		}
	}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}