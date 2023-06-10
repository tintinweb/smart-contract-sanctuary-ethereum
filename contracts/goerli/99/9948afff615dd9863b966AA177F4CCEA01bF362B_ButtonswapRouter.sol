// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapRouter} from "./interfaces/IButtonswapRouter/IButtonswapRouter.sol";
import {IButtonswapFactory} from
    "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapFactory/IButtonswapFactory.sol";
import {IButtonswapPair} from "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapPair/IButtonswapPair.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {ButtonswapLibrary} from "./libraries/ButtonswapLibrary.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {ETHButtonswapRouter} from "./ETHButtonswapRouter.sol";

contract ButtonswapRouter is ETHButtonswapRouter, IButtonswapRouter {
    constructor(address _factory, address _WETH) ETHButtonswapRouter(_factory, _WETH) {}

    /**
     * @inheritdoc IButtonswapRouter
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair) {
        return IButtonswapFactory(factory).getPair(tokenA, tokenB);
    }

    // **** LIBRARY FUNCTIONS ****

    /**
     * @inheritdoc IButtonswapRouter
     */
    function quote(uint256 amountA, uint256 poolA, uint256 poolB)
        external
        pure
        virtual
        override
        returns (uint256 amountB)
    {
        return ButtonswapLibrary.quote(amountA, poolA, poolB);
    }

    /**
     * @inheritdoc IButtonswapRouter
     */
    function getAmountOut(uint256 amountIn, uint256 poolIn, uint256 poolOut)
        external
        pure
        virtual
        override
        returns (uint256 amountOut)
    {
        return ButtonswapLibrary.getAmountOut(amountIn, poolIn, poolOut);
    }

    /**
     * @inheritdoc IButtonswapRouter
     */
    function getAmountIn(uint256 amountOut, uint256 poolIn, uint256 poolOut)
        external
        pure
        virtual
        override
        returns (uint256 amountIn)
    {
        return ButtonswapLibrary.getAmountIn(amountOut, poolIn, poolOut);
    }

    /**
     * @inheritdoc IButtonswapRouter
     */
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return ButtonswapLibrary.getAmountsOut(factory, amountIn, path);
    }

    /**
     * @inheritdoc IButtonswapRouter
     */
    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return ButtonswapLibrary.getAmountsIn(factory, amountOut, path);
    }

    /**
     * @inheritdoc IButtonswapRouter
     */
    function getMintSwappedAmounts(address tokenA, address tokenB, uint256 mintAmountA)
        external
        view
        virtual
        override
        returns (uint256 tokenAToSwap, uint256 swappedReservoirAmountB)
    {
        return ButtonswapLibrary.getMintSwappedAmounts(factory, tokenA, tokenB, mintAmountA);
    }

    /**
     * @inheritdoc IButtonswapRouter
     */
    function getBurnSwappedAmounts(address tokenA, address tokenB, uint256 liquidity)
        external
        view
        virtual
        override
        returns (uint256 tokenOutA, uint256 swappedReservoirAmountA)
    {
        return ButtonswapLibrary.getBurnSwappedAmounts(factory, tokenA, tokenB, liquidity);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IETHButtonswapRouter} from "./IETHButtonswapRouter.sol";

interface IButtonswapRouter is IETHButtonswapRouter {
    /**
     * @notice Returns the Pair contract for given tokens. Returns the zero address if no pair exists
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return pair The pair address
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @notice Given some amount of an asset and pair pools, returns an equivalent amount of the other asset
     * @param amountA The amount of token A
     * @param poolA The balance of token A in the pool
     * @param poolB The balance of token B in the pool
     * @return amountB The amount of token B
     */
    function quote(uint256 amountA, uint256 poolA, uint256 poolB) external pure returns (uint256 amountB);

    /**
     * @notice Given an input amount of an asset and pair pools, returns the maximum output amount of the other asset
     * Factors in the fee on the input amount.
     * @param amountIn The input amount of the asset
     * @param poolIn The balance of the input asset in the pool
     * @param poolOut The balance of the output asset in the pool
     * @return amountOut The output amount of the other asset
     */
    function getAmountOut(uint256 amountIn, uint256 poolIn, uint256 poolOut)
        external
        pure
        returns (uint256 amountOut);

    /**
     * @notice Given an output amount of an asset and pair pools, returns a required input amount of the other asset
     * @param amountOut The output amount of the asset
     * @param poolIn The balance of the input asset in the pool
     * @param poolOut The balance of the output asset in the pool
     * @return amountIn The required input amount of the other asset
     */
    function getAmountIn(uint256 amountOut, uint256 poolIn, uint256 poolOut) external pure returns (uint256 amountIn);

    /**
     * @notice Given an ordered array of tokens and an input amount of the first asset, performs chained getAmountOut calculations to calculate the output amount of the final asset
     * @param amountIn The input amount of the first asset
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @return amounts The output amounts of each asset in the path
     */
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    /**
     * @notice Given an ordered array of tokens and an output amount of the final asset, performs chained getAmountIn calculations to calculate the input amount of the first asset
     * @param amountOut The output amount of the final asset
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @return amounts The input amounts of each asset in the path
     */
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    /**
     * @notice Returns how much of the much of mintAmountA will be swapped for tokenB and for how much during a mintWithReservoir operation.
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param mintAmountA The amount of tokenA to be minted
     * @return tokenAToSwap The amount of tokenA to be exchanged for tokenB from the reservoir
     * @return swappedReservoirAmountB The amount of tokenB returned from the reservoir
     */
    function getMintSwappedAmounts(address tokenA, address tokenB, uint256 mintAmountA)
        external
        view
        returns (uint256 tokenAToSwap, uint256 swappedReservoirAmountB);

    /**
     * @notice Returns how much of tokenA will be withdrawn from the pair and how much of it came from the reservoir during a burnFromReservoir operation.
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param liquidity The amount of liquidity to be burned
     * @return tokenOutA The amount of tokenA to be withdrawn from the pair
     * @return swappedReservoirAmountA The amount of tokenA returned from the reservoir
     */
    function getBurnSwappedAmounts(address tokenA, address tokenB, uint256 liquidity)
        external
        view
        returns (uint256 tokenOutA, uint256 swappedReservoirAmountA);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapFactoryErrors} from "./IButtonswapFactoryErrors.sol";
import {IButtonswapFactoryEvents} from "./IButtonswapFactoryEvents.sol";

interface IButtonswapFactory is IButtonswapFactoryErrors, IButtonswapFactoryEvents {
    /**
     * @notice Returns the current address for `feeTo`.
     * The owner of this address receives the protocol fee as it is collected over time.
     * @return _feeTo The `feeTo` address
     */
    function feeTo() external view returns (address _feeTo);

    /**
     * @notice Returns the current address for `feeToSetter`.
     * The owner of this address has the power to update both `feeToSetter` and `feeTo`.
     * @return _feeToSetter The `feeToSetter` address
     */
    function feeToSetter() external view returns (address _feeToSetter);

    /**
     * @notice Returns the current state of restricted creation.
     * If true, then no new pairs, only feeToSetter can create new pairs
     * @return _isCreationRestricted The `isCreationRestricted` state
     */
    function isCreationRestricted() external view returns (bool _isCreationRestricted);

    /**
     * @notice Returns the current default pause state of Pairs
     * New pairs are created with this value as their initial pause state
     * @return _isPaused The `isPaused` state
     */
    function isPaused() external view returns (bool _isPaused);

    /**
     * @notice Get the (unique) Pair address created for the given combination of `tokenA` and `tokenB`.
     * If the Pair does not exist then zero address is returned.
     * @param tokenA The first unsorted token
     * @param tokenB The second unsorted token
     * @return pair The address of the Pair instance
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @notice Get the Pair address at the given `index`, ordered chronologically.
     * @param index The index to query
     * @return pair The address of the Pair created at the given `index`
     */
    function allPairs(uint256 index) external view returns (address pair);

    /**
     * @notice Get the current total number of Pairs created
     * @return count The total number of Pairs created
     */
    function allPairsLength() external view returns (uint256 count);

    /**
     * @notice Creates a new {ButtonswapPair} instance for the given unsorted tokens `tokenA` and `tokenB`.
     * @dev The tokens are sorted later, but can be provided to this method in either order.
     * @param tokenA The first unsorted token address
     * @param tokenB The second unsorted token address
     * @return pair The address of the new {ButtonswapPair} instance
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /**
     * @notice Updates the address that receives the protocol fee.
     * This can only be called by the `feeToSetter` address.
     * @param _feeTo The new address
     */
    function setFeeTo(address _feeTo) external;

    /**
     * @notice Updates the address that has the power to set the `feeToSetter` and `feeTo` addresses.
     * This can only be called by the `feeToSetter` address.
     * @param _feeToSetter The new address
     */
    function setFeeToSetter(address _feeToSetter) external;

    /**
     * @notice Updates the state of restricted creation.
     * This can only be called by the `feeToSetter` address.
     * @param _isCreationRestricted The new state
     */
    function setIsCreationRestricted(bool _isCreationRestricted) external;

    /**
     * @notice Updates the default pause state of Pairs.
     * This can only be called by the `feeToSetter` address.
     * @param _isPaused The new state
     */
    function setIsPaused(bool _isPaused) external;

    /**
     * @notice Returns the last token pair created.
     * @return token0 The first token address
     * @return token1 The second token address
     */
    function lastCreatedPairTokens() external returns (address token0, address token1);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapPairErrors} from "./IButtonswapPairErrors.sol";
import {IButtonswapPairEvents} from "./IButtonswapPairEvents.sol";
import {IButtonswapERC20} from "../IButtonswapERC20/IButtonswapERC20.sol";

interface IButtonswapPair is IButtonswapPairErrors, IButtonswapPairEvents, IButtonswapERC20 {
    /**
     * @notice The smallest value that {IButtonswapERC20-totalSupply} can be.
     * @dev After the first mint the total liquidity (represented by the liquidity token total supply) can never drop below this value.
     *
     * This is to protect against an attack where the attacker mints a very small amount of liquidity, and then donates pool tokens to skew the ratio.
     * This results in future minters receiving no liquidity tokens when they deposit.
     * By enforcing a minimum liquidity value this attack becomes prohibitively expensive to execute.
     * @return MINIMUM_LIQUIDITY The MINIMUM_LIQUIDITY value
     */
    function MINIMUM_LIQUIDITY() external pure returns (uint256 MINIMUM_LIQUIDITY);

    /**
     * @notice The address of the {ButtonswapFactory} instance used to create this Pair.
     * @dev Set to `msg.sender` in the Pair constructor.
     * @return factory The factory address
     */
    function factory() external view returns (address factory);

    /**
     * @notice The address of the first sorted token.
     * @return token0 The token address
     */
    function token0() external view returns (address token0);

    /**
     * @notice The address of the second sorted token.
     * @return token1 The token address
     */
    function token1() external view returns (address token1);

    /**
     * @notice Whether the Pair is currently paused
     * @return isPaused The paused state
     */
    function isPaused() external view returns (uint128 isPaused);

    /**
     * @notice The time-weighted average price of the Pair.
     * The price is of `token0` in terms of `token1`.
     * @dev The price is represented as a [UQ112x112](https://en.wikipedia.org/wiki/Q_(number_format)) to maintain precision.
     * Consequently this value must be divided by `2^112` to get the actual price.
     *
     * Because of the time weighting, `price0CumulativeLast` must also be divided by the total Pair lifetime to get the average price over that time period.
     * @return price0CumulativeLast The current cumulative `token0` price
     */
    function price0CumulativeLast() external view returns (uint256 price0CumulativeLast);

    /**
     * @notice The time-weighted average price of the Pair.
     * The price is of `token1` in terms of `token0`.
     * @dev The price is represented as a [UQ112x112](https://en.wikipedia.org/wiki/Q_(number_format)) to maintain precision.
     * Consequently this value must be divided by `2^112` to get the actual price.
     *
     * Because of the time weighting, `price1CumulativeLast` must also be divided by the total Pair lifetime to get the average price over that time period.
     * @return price1CumulativeLast The current cumulative `token1` price
     */
    function price1CumulativeLast() external view returns (uint256 price1CumulativeLast);

    /**
     * @notice The timestamp for when the single-sided timelock concludes.
     * The timelock is initiated based on price volatility of swaps over the last 24 hours, and can be extended by new
     *   swaps if they are sufficiently volatile.
     * The timelock protects against attempts to manipulate the price that is used to valuate the reservoir tokens during
     *   single-sided operations.
     * It also guards against general legitimate volatility, as it is preferable to defer single-sided operations until
     *   it is clearer what the market considers the price to be.
     * @return singleSidedTimelockDeadline The current deadline timestamp
     */
    function singleSidedTimelockDeadline() external view returns (uint128 singleSidedTimelockDeadline);

    /**
     * @notice The timestamp by which the amount of reservoir tokens that can be exchanged during a single-sided operation
     *   reaches its maximum value.
     * This maximum value is not necessarily the entirety of the reservoir, instead being calculated as a fraction of the
     *   corresponding token's active liquidity.
     * @return swappableReservoirLimitReachesMaxDeadline The current deadline timestamp
     */
    function swappableReservoirLimitReachesMaxDeadline()
        external
        view
        returns (uint128 swappableReservoirLimitReachesMaxDeadline);

    /**
     * @notice Returns the current limit on the number of reservoir tokens that can be exchanged during a single-sided mint/burn operation.
     * @return swappableReservoirLimit The amount of reservoir token that can be exchanged
     */
    function getSwappableReservoirLimit() external view returns (uint256 swappableReservoirLimit);

    /**
     * @notice Get the current liquidity values.
     * @return _pool0 The active `token0` liquidity
     * @return _pool1 The active `token1` liquidity
     * @return _reservoir0 The inactive `token0` liquidity
     * @return _reservoir1 The inactive `token1` liquidity
     * @return _blockTimestampLast The timestamp of when the price was last updated
     */
    function getLiquidityBalances()
        external
        view
        returns (uint112 _pool0, uint112 _pool1, uint112 _reservoir0, uint112 _reservoir1, uint32 _blockTimestampLast);

    /**
     * @notice The current `movingAveragePrice0` value, based on the current block timestamp.
     * @dev This is the `token0` price, time weighted to prevent manipulation.
     * Refer to [reservoir-valuation.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/reservoir-valuation.md#price-stability) for more detail.
     *
     * The price is represented as a [UQ112x112](https://en.wikipedia.org/wiki/Q_(number_format)) to maintain precision.
     * It is used to valuate the reservoir tokens that are exchanged during single-sided operations.
     * @return _movingAveragePrice0 The current `movingAveragePrice0` value
     */
    function movingAveragePrice0() external view returns (uint256 _movingAveragePrice0);

    /**
     * @notice Mints new liquidity tokens to `to` based on `amountIn0` of `token0` and `amountIn1  of`token1` deposited.
     * Expects both tokens to be deposited in a ratio that matches the current Pair price.
     * @dev The token deposits are deduced to be the delta between token balance before and after the transfers in order to account for unusual tokens.
     * Refer to [mint-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/mint-math.md#dual-sided-mint) for more detail.
     * @param amountIn0 The amount of `token0` that should be transferred in from the user
     * @param amountIn1 The amount of `token1` that should be transferred in from the user
     * @param to The account that receives the newly minted liquidity tokens
     * @return liquidityOut THe amount of liquidity tokens minted
     */
    function mint(uint256 amountIn0, uint256 amountIn1, address to) external returns (uint256 liquidityOut);

    /**
     * @notice Mints new liquidity tokens to `to` based on how much `token0` or `token1` has been deposited.
     * The token transferred is the one that the Pair does not have a non-zero inactive liquidity balance for.
     * Expects only one token to be deposited, so that it can be paired with the other token's inactive liquidity.
     * @dev The token deposits are deduced to be the delta between token balance before and after the transfers in order to account for unusual tokens.
     * Refer to [mint-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/mint-math.md#single-sided-mint) for more detail.
     * @param amountIn The amount of tokens that should be transferred in from the user
     * @param to The account that receives the newly minted liquidity tokens
     * @return liquidityOut THe amount of liquidity tokens minted
     */
    function mintWithReservoir(uint256 amountIn, address to) external returns (uint256 liquidityOut);

    /**
     * @notice Burns `liquidityIn` liquidity tokens to redeem to `to` the corresponding `amountOut0` of `token0` and `amountOut1` of `token1`.
     * @dev Refer to [burn-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/burn-math.md#dual-sided-burn) for more detail.
     * @param liquidityIn The amount of liquidity tokens to burn
     * @param to The account that receives the redeemed tokens
     * @return amountOut0 The amount of `token0` that the liquidity tokens are redeemed for
     * @return amountOut1 The amount of `token1` that the liquidity tokens are redeemed for
     */
    function burn(uint256 liquidityIn, address to) external returns (uint256 amountOut0, uint256 amountOut1);

    /**
     * @notice Burns `liquidityIn` liquidity tokens to redeem to `to` the corresponding `amountOut0` of `token0` and `amountOut1` of `token1`.
     * Only returns tokens from the non-zero inactive liquidity balance, meaning one of `amountOut0` and `amountOut1` will be zero.
     * @dev Refer to [burn-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/burn-math.md#single-sided-burn) for more detail.
     * @param liquidityIn The amount of liquidity tokens to burn
     * @param to The account that receives the redeemed tokens
     * @return amountOut0 The amount of `token0` that the liquidity tokens are redeemed for
     * @return amountOut1 The amount of `token1` that the liquidity tokens are redeemed for
     */
    function burnFromReservoir(uint256 liquidityIn, address to)
        external
        returns (uint256 amountOut0, uint256 amountOut1);

    /**
     * @notice Swaps one token for the other, taking `amountIn0` of `token0` and `amountIn1` of `token1` from the sender and sending `amountOut0` of `token0` and `amountOut1` of `token1` to `to`.
     * The price of the swap is determined by maintaining the "K Invariant".
     * A 0.3% fee is collected to distribute between liquidity providers and the protocol.
     * @dev The token deposits are deduced to be the delta between the current Pair contract token balances and the last stored balances.
     * Optional calldata can be passed to `data`, which will be used to confirm the output token transfer with `to` if `to` is a contract that implements the {IButtonswapCallee} interface.
     * Refer to [swap-math.md](https://github.com/buttonwood-protocol/buttonswap-core/blob/main/notes/swap-math.md) for more detail.
     * @param amountIn0 The amount of `token0` that the sender sends
     * @param amountIn1 The amount of `token1` that the sender sends
     * @param amountOut0 The amount of `token0` that the recipient receives
     * @param amountOut1 The amount of `token1` that the recipient receives
     * @param to The account that receives the swap output
     */
    function swap(uint256 amountIn0, uint256 amountIn1, uint256 amountOut0, uint256 amountOut1, address to) external;

    /**
     * @notice Updates the pause state of the pair to the default value of the factory.
     */
    function updateIsPaused() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// ToDo: Replace with solmate/SafeTransferLib
pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

pragma solidity ^0.8.13;

import {IButtonswapPair} from "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapPair/IButtonswapPair.sol";
import {Math} from "buttonswap-periphery_buttonswap-core/libraries/Math.sol";
import {IERC20} from "../interfaces/IERC20.sol";

library ButtonswapLibrary {
    /// @notice Identical addresses provided
    error IdenticalAddresses();
    /// @notice Zero address provided
    error ZeroAddress();
    /// @notice Insufficient amount provided
    error InsufficientAmount();
    /// @notice Insufficient liquidity provided
    error InsufficientLiquidity();
    /// @notice Insufficient input amount provided
    error InsufficientInputAmount();
    /// @notice Insufficient output amount provided
    error InsufficientOutputAmount();
    /// @notice Invalid path provided
    error InvalidPath();

    /**
     * @dev Returns sorted token addresses, used to handle return values from pairs sorted in this order
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return token0 First sorted token address
     * @return token1 Second sorted token address
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        if (tokenA == tokenB) {
            revert IdenticalAddresses();
        }
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // If the tokens are different and sorted, only token0 can be the zero address
        if (token0 == address(0)) {
            revert ZeroAddress();
        }
    }

    /**
     * @dev Predicts the address that the Pair contract for given tokens would have been deployed to
     * @dev Specifically, this calculates the CREATE2 address for a Pair contract.
     * @dev It's done this way to avoid making any external calls, and thus saving on gas versus other approaches.
     * @param factory The address of the ButtonswapFactory used to create the pair
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return pair The pair address
     */
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        // Init Hash Code is generated by the following command:
        //        bytes32 initHashCode = keccak256(abi.encodePacked(type(ButtonswapPair).creationCode));
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"879b01d93295b8ad5e4bdaaa402748838640cd696912627a1bda7a6f254a6ec0" // init code hash
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev Fetches and sorts the pools for a pair. Pools are the current token balances in the pair contract serving as liquidity.
     * @param factory The address of the ButtonswapFactory
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return poolA Pool corresponding to tokenA
     * @return poolB Pool corresponding to tokenB
     */
    function getPools(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 poolA, uint256 poolB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 pool0, uint256 pool1,,,) = IButtonswapPair(pairFor(factory, tokenA, tokenB)).getLiquidityBalances();
        (poolA, poolB) = tokenA == token0 ? (pool0, pool1) : (pool1, pool0);
    }

    /**
     * @dev Fetches and sorts the reservoirs for a pair. Reservoirs are the current token balances in the pair contract not actively serving as liquidity.
     * @param factory The address of the ButtonswapFactory
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return reservoirA Reservoir corresponding to tokenA
     * @return reservoirB Reservoir corresponding to tokenB
     */
    function getReservoirs(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reservoirA, uint256 reservoirB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (,, uint256 reservoir0, uint256 reservoir1,) =
            IButtonswapPair(pairFor(factory, tokenA, tokenB)).getLiquidityBalances();
        (reservoirA, reservoirB) = tokenA == token0 ? (reservoir0, reservoir1) : (reservoir1, reservoir0);
    }

    /**
     * @dev Fetches and sorts the pools and reservoirs for a pair.
     *   - Pools are the current token balances in the pair contract serving as liquidity.
     *   - Reservoirs are the current token balances in the pair contract not actively serving as liquidity.
     * @param factory The address of the ButtonswapFactory
     * @param tokenA First token address
     * @param tokenB Second token address
     * @return poolA Pool corresponding to tokenA
     * @return poolB Pool corresponding to tokenB
     * @return reservoirA Reservoir corresponding to tokenA
     * @return reservoirB Reservoir corresponding to tokenB
     */
    function getLiquidityBalances(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 poolA, uint256 poolB, uint256 reservoirA, uint256 reservoirB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 pool0, uint256 pool1, uint256 reservoir0, uint256 reservoir1,) =
            IButtonswapPair(pairFor(factory, tokenA, tokenB)).getLiquidityBalances();
        (poolA, poolB, reservoirA, reservoirB) =
            tokenA == token0 ? (pool0, pool1, reservoir0, reservoir1) : (pool1, pool0, reservoir1, reservoir0);
    }

    /**
     * @dev Given some amount of an asset and pair pools, returns an equivalent amount of the other asset
     * @param amountA The amount of token A
     * @param poolA The balance of token A in the pool
     * @param poolB The balance of token B in the pool
     * @return amountB The amount of token B
     */
    function quote(uint256 amountA, uint256 poolA, uint256 poolB) internal pure returns (uint256 amountB) {
        if (amountA == 0) {
            revert InsufficientAmount();
        }
        if (poolA == 0 || poolB == 0) {
            revert InsufficientLiquidity();
        }
        amountB = (amountA * poolB) / poolA;
    }

    /**
     * @dev Given a factory, two tokens, and a mintAmount of the first, returns how much of the much of the mintAmount will be swapped for the other token and for how much during a mintWithReservoir operation.
     * @dev The logic is a condensed version of PairMath.getSingleSidedMintLiquidityOutAmountA and PairMath.getSingleSidedMintLiquidityOutAmountB
     * @param factory The address of the ButtonswapFactory that created the pairs
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param mintAmountA The amount of tokenA to be minted
     * @return tokenAToSwap The amount of tokenA to be exchanged for tokenB from the reservoir
     * @return swappedReservoirAmountB The amount of tokenB returned from the reservoir
     */
    function getMintSwappedAmounts(address factory, address tokenA, address tokenB, uint256 mintAmountA)
        internal
        view
        returns (uint256 tokenAToSwap, uint256 swappedReservoirAmountB)
    {
        IButtonswapPair pair = IButtonswapPair(pairFor(factory, tokenA, tokenB));
        uint256 totalA = IERC20(tokenA).balanceOf(address(pair));
        uint256 totalB = IERC20(tokenB).balanceOf(address(pair));
        uint256 movingAveragePrice0 = pair.movingAveragePrice0();

        // tokenA == token0
        if (tokenA < tokenB) {
            tokenAToSwap =
                (mintAmountA * totalB) / (Math.mulDiv(movingAveragePrice0, (totalA + mintAmountA), 2 ** 112) + totalB);
            swappedReservoirAmountB = (tokenAToSwap * movingAveragePrice0) / 2 ** 112;
        } else {
            tokenAToSwap =
                (mintAmountA * totalB) / (((2 ** 112 * (totalA + mintAmountA)) / movingAveragePrice0) + totalB);
            // Inverse price so again we can use it without overflow risk
            swappedReservoirAmountB = (tokenAToSwap * (2 ** 112)) / movingAveragePrice0;
        }
    }

    /**
     * @dev Given a factory, two tokens, and a liquidity amount, returns how much of the first token will be withdrawn from the pair and how much of it came from the reservoir during a burnFromReservoir operation.
     * @dev The logic is a condensed version of PairMath.getSingleSidedBurnOutputAmountA and PairMath.getSingleSidedBurnOutputAmountB
     * @param factory The address of the ButtonswapFactory that created the pairs
     * @param tokenA First token address
     * @param tokenB Second token address
     * @param liquidity The amount of liquidity to be burned
     * @return tokenOutA The amount of tokenA to be withdrawn from the pair
     * @return swappedReservoirAmountA The amount of tokenA returned from the reservoir
     */
    function getBurnSwappedAmounts(address factory, address tokenA, address tokenB, uint256 liquidity)
        internal
        view
        returns (uint256 tokenOutA, uint256 swappedReservoirAmountA)
    {
        IButtonswapPair pair = IButtonswapPair(pairFor(factory, tokenA, tokenB));
        uint256 totalLiquidity = pair.totalSupply();
        uint256 totalA = IERC20(tokenA).balanceOf(address(pair));
        uint256 totalB = IERC20(tokenB).balanceOf(address(pair));
        uint256 movingAveragePrice0 = pair.movingAveragePrice0();
        uint256 tokenBToSwap = (totalB * liquidity) / totalLiquidity;
        tokenOutA = (totalA * liquidity) / totalLiquidity;

        // tokenA == token0
        if (tokenA < tokenB) {
            swappedReservoirAmountA = (tokenBToSwap * (2 ** 112)) / movingAveragePrice0;
        } else {
            swappedReservoirAmountA = (tokenBToSwap * movingAveragePrice0) / 2 ** 112;
        }
        tokenOutA += swappedReservoirAmountA;
    }

    /**
     * @dev Given an input amount of an asset and pair pools, returns the maximum output amount of the other asset
     * Factors in the fee on the input amount.
     * @param amountIn The input amount of the asset
     * @param poolIn The balance of the input asset in the pool
     * @param poolOut The balance of the output asset in the pool
     * @return amountOut The output amount of the other asset
     */
    function getAmountOut(uint256 amountIn, uint256 poolIn, uint256 poolOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        if (amountIn == 0) {
            revert InsufficientInputAmount();
        }
        if (poolIn == 0 || poolOut == 0) {
            revert InsufficientLiquidity();
        }
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * poolOut;
        uint256 denominator = (poolIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /**
     * @dev Given an output amount of an asset and pair pools, returns a required input amount of the other asset
     * @param amountOut The output amount of the asset
     * @param poolIn The balance of the input asset in the pool
     * @param poolOut The balance of the output asset in the pool
     * @return amountIn The required input amount of the other asset
     */
    function getAmountIn(uint256 amountOut, uint256 poolIn, uint256 poolOut) internal pure returns (uint256 amountIn) {
        if (amountOut == 0) {
            revert InsufficientOutputAmount();
        }
        if (poolIn == 0 || poolOut == 0) {
            revert InsufficientLiquidity();
        }
        uint256 numerator = poolIn * amountOut * 1000;
        uint256 denominator = (poolOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    /**
     * @dev Given an ordered array of tokens and an input amount of the first asset, performs chained getAmountOut calculations to calculate the output amount of the final asset
     * @param factory The address of the ButtonswapFactory that created the pairs
     * @param amountIn The input amount of the first asset
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @return amounts The output amounts of each asset in the path
     */
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        if (path.length < 2) {
            revert InvalidPath();
        }
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 poolIn, uint256 poolOut,,) = getLiquidityBalances(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], poolIn, poolOut);
        }
    }

    /**
     * @dev Given an ordered array of tokens and an output amount of the final asset, performs chained getAmountIn calculations to calculate the input amount of the first asset
     * @param factory The address of the ButtonswapFactory that created the pairs
     * @param amountOut The output amount of the final asset
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @return amounts The input amounts of each asset in the path
     */
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        if (path.length < 2) {
            revert InvalidPath();
        }
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 poolIn, uint256 poolOut,,) = getLiquidityBalances(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], poolIn, poolOut);
        }
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapFactory} from
    "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapFactory/IButtonswapFactory.sol";
import {IButtonswapPair} from "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapPair/IButtonswapPair.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {IETHButtonswapRouter} from "./interfaces/IButtonswapRouter/IETHButtonswapRouter.sol";
import {ButtonswapLibrary} from "./libraries/ButtonswapLibrary.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {BasicButtonswapRouter} from "./BasicButtonswapRouter.sol";

contract ETHButtonswapRouter is BasicButtonswapRouter, IETHButtonswapRouter {
    /**
     * @inheritdoc IETHButtonswapRouter
     */
    address public immutable override WETH;

    constructor(address _factory, address _WETH) BasicButtonswapRouter(_factory) {
        WETH = _WETH;
    }

    /**
     * @dev Only accepts ETH via fallback from the WETH contract
     */
    receive() external payable {
        if (msg.sender != WETH) {
            revert NonWETHSender();
        }
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
    {
        (amountToken, amountETH) =
            _addLiquidity(token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
        address pair = ButtonswapLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountToken);
        TransferHelper.safeApprove(token, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        TransferHelper.safeApprove(WETH, pair, amountETH);

        (address token0,) = ButtonswapLibrary.sortTokens(token, WETH);
        liquidity = (token == token0)
            ? IButtonswapPair(pair).mint(amountToken, amountETH, to)
            : IButtonswapPair(pair).mint(amountETH, amountToken, to);

        // refund dust eth, if any
        if (msg.value > amountETH) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        }
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function addLiquidityETHWithReservoir(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
    {
        (amountToken, amountETH) =
            _addLiquidityWithReservoir(token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
        address pair = ButtonswapLibrary.pairFor(factory, token, WETH);
        if (amountToken > 0) {
            TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountToken);
            TransferHelper.safeApprove(token, pair, amountToken);
            liquidity = IButtonswapPair(pair).mintWithReservoir(amountToken, to);
        } else if (amountETH > 0) {
            IWETH(WETH).deposit{value: amountETH}();
            TransferHelper.safeApprove(WETH, pair, amountETH);
            liquidity = IButtonswapPair(pair).mintWithReservoir(amountETH, to);
        }
        // refund dust eth, if any
        if (msg.value > amountETH) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
        }
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) =
            removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function removeLiquidityETHFromReservoir(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) =
            removeLiquidityFromReservoir(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        if (amountToken > 0) {
            TransferHelper.safeTransfer(token, to, amountToken);
        } else if (amountETH > 0) {
            IWETH(WETH).withdraw(amountETH);
            TransferHelper.safeTransferETH(to, amountETH);
        }
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountToken, uint256 amountETH) {
        address pair = ButtonswapLibrary.pairFor(factory, token, WETH);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IButtonswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        if (path[0] != WETH) {
            revert InvalidPath();
        }
        amounts = ButtonswapLibrary.getAmountsOut(factory, msg.value, path);
        if (amounts[amounts.length - 1] < amountOutMin) {
            revert InsufficientOutputAmount();
        }

        IWETH(WETH).deposit{value: amounts[0]}();
        if(!IWETH(WETH).transfer(address(this), amounts[0])) {
            revert FailedWETHTransfer();
        }
        _swap(amounts, path, to);
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        if (path[path.length - 1] != WETH) {
            revert InvalidPath();
        }
        amounts = ButtonswapLibrary.getAmountsIn(factory, amountOut, path);
        if (amounts[0] > amountInMax) {
            revert ExcessiveInputAmount();
        }

        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amounts[0]);
        _swap(amounts, path, address(this));

        // Convert final token to ETH and send to `to`
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        if (path[path.length - 1] != WETH) {
            revert InvalidPath();
        }
        amounts = ButtonswapLibrary.getAmountsOut(factory, amountIn, path);
        if (amounts[amounts.length - 1] < amountOutMin) {
            revert InsufficientOutputAmount();
        }

        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amounts[0]);
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     * @inheritdoc IETHButtonswapRouter
     */
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        if (path[0] != WETH) {
            revert InvalidPath();
        }
        amounts = ButtonswapLibrary.getAmountsIn(factory, amountOut, path);
        if (amounts[0] > msg.value) {
            revert ExcessiveInputAmount();
        }

        IWETH(WETH).deposit{value: amounts[0]}();
        if(!IWETH(WETH).transfer(address(this), amounts[0])) {
            revert FailedWETHTransfer();
        }

        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) {
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IBasicButtonswapRouter} from "./IBasicButtonswapRouter.sol";
import {IETHButtonswapRouterErrors} from "./IETHButtonswapRouterErrors.sol";

interface IETHButtonswapRouter is IBasicButtonswapRouter, IETHButtonswapRouterErrors {
    /**
     * @notice Returns the address of the WETH token
     * @return WETH The address of the WETH token
     */
    function WETH() external view returns (address WETH);

    /**
     * @notice Similar to `addLiquidity` but one of the tokens is ETH wrapped into WETH.
     * Adds liquidity to a pair, creating it if it doesn't exist yet, and transfers the liquidity tokens to the recipient.
     * @dev If the pair is empty, amountTokenMin and amountETHMin are ignored.
     * If the pair is nonempty, it deposits as much of token and WETH as possible while maintaining 3 conditions:
     * 1. The ratio of token to WETH in the pair remains approximately the same
     * 2. The amount of token in the pair is at least amountTokenMin but less than or equal to amountTokenDesired
     * 3. The amount of WETH in the pair is at least amountETHMin but less than or equal to ETH sent
     * @param token The address of the non-WETH token in the pair.
     * @param amountTokenDesired The maximum amount of the non-ETH token to add to the pair.
     * @param amountTokenMin The minimum amount of the non-ETH token to add to the pair.
     * @param amountETHMin The minimum amount of ETH/WETH to add to the pair.
     * @param to The address to send the liquidity tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountToken The amount of token actually added to the pair.
     * @return amountETH The amount of ETH/WETH actually added to the pair.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    /**
     * @notice Similar to `addLiquidityWithReservoir` but one of the tokens is ETH wrapped into WETH.
     *     Adds liquidity to a pair, opposite to the existing reservoir, and transfers the liquidity tokens to the recipient
     * @dev Since there at most one reservoir at a given time, some conditions are checked:
     * 1. If there is no reservoir, it rejects
     * 2. If the non-WETH token has the reservoir, amountTokenDesired parameter ignored.
     * 3. The token/WETH with the reservoir has its amount deducted from the reservoir (checked against corresponding amountMin parameter)
     * @param token The address of the non-WETH token in the pair.
     * @param amountTokenDesired The maximum amount of the non-WETH token to add to the pair.
     * @param amountTokenMin The minimum amount of the non-WETH token to add to the pair.
     * @param amountETHMin The minimum amount of WETH to add to the pair.
     * @param to The address to send the liquidity tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountToken The amount of the non-ETH token actually added to the pair.
     * @return amountETH The amount of WETH actually added to the pair.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidityETHWithReservoir(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    /**
     * @notice Similar to `removeLiquidity()` but one of the tokens is ETH wrapped into WETH.
     * Removes liquidity from a pair, and transfers the tokens to the recipient.
     * @param token The address of the non-WETH token in the pair.
     * @param liquidity The amount of liquidity tokens to burn.
     * @param amountTokenMin The minimum amount of the non-WETH token to withdraw from the pair.
     * @param amountETHMin The minimum amount of ETH/WETH to withdraw from the pair.
     * @param to The address to send the tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountToken The amount of the non-WETH token actually withdrawn from the pair.
     * @return amountETH The amount of ETH/WETH actually withdrawn from the pair.
     */
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @notice Similar to `removeLiquidityFromReservoir()` but one of the tokens is ETH wrapped into WETH.
     * Removes liquidity from the reservoir of a pair and transfers the tokens to the recipient.
     * @param token The address of the non-WETH token in the pair.
     * @param liquidity The amount of liquidity tokens to burn.
     * @param amountTokenMin The minimum amount of the non-WETH token to withdraw from the pair.
     * @param amountETHMin The minimum amount of ETH/WETH to withdraw from the pair.
     * @param to The address to send the tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountToken The amount of the non-WETH token actually withdrawn from the pair.
     * @return amountETH The amount of ETH/WETH actually withdrawn from the pair.
     */
    function removeLiquidityETHFromReservoir(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @notice Similar to `removeLiquidityWETH()` but utilizes the Permit signatures to reduce gas consumption.
     * Removes liquidity from a pair where one of the tokens is ETH wrapped into WETH, and transfers the tokens to the recipient.
     * @param token The address of the non-WETH token in the pair.
     * @param liquidity The amount of liquidity tokens to burn.
     * @param amountTokenMin The minimum amount of the non-WETH token to withdraw from the pair.
     * @param amountETHMin The minimum amount of ETH/WETH to withdraw from the pair.
     * @param to The address to send the tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @param approveMax Whether the signature is for the max uint256 or liquidity value
     * @param v Part of the signature
     * @param r Part of the signature
     * @param s Part of the signature
     * @return amountToken The amount of the non-WETH token actually withdrawn from the pair.
     * @return amountETH The amount of ETH/WETH actually withdrawn from the pair.
     */
    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    /**
     * @notice Similar to `swapExactTokensForTokens()` the first token is ETH wrapped into WETH.
     * Given an ordered array of tokens, performs consecutive swaps from a specific amount of the first token to the last token in the array.
     * @param amountOutMin The minimum amount of the last token to receive from the swap.
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @param to The address to send the output token to.
     * @param deadline The time after which this transaction can no longer be executed.
     */
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);

    /**
     * @notice Similar to `swapTokensForExactTokens()` the last token is ETH wrapped into WETH.
     * Given an ordered array of tokens, performs consecutive swaps from the first token to a specific amount of the last token in the array.
     * @param amountOut The amount of ETH to receive from the swap.
     * @param amountInMax The maximum amount of the first token to swap.
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @param to The address to send the output token to.
     * @param deadline The time after which this transaction can no longer be executed.
     */
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Similar to `swapExactTokensForTokens()` but the last token is ETH wrapped into WETH.
     * Given an ordered array of tokens, performs consecutive swaps from a specific amount of the first token to the last token in the array.
     * @param amountIn The amount of the first token to swap.
     * @param amountOutMin The minimum amount of the last token to receive from the swap.
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @param to The address to send the output token to.
     * @param deadline The time after which this transaction can no longer be executed.
     */
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Similar to `swapTokensForExactTokens()` but the first token is ETH wrapped into WETH.
     * Given an ordered array of tokens, performs consecutive swaps from the first token to a specific amount of the last token in the array.
     * @param amountOut The amount of the last token to receive from the swap.
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @param to The address to send the output token to.
     * @param deadline The time after which this transaction can no longer be executed.
     */
    function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IButtonswapFactoryErrors {
    /**
     * @notice The given token addresses are the same
     */
    error TokenIdenticalAddress();

    /**
     * @notice The given token address is the zero address
     */
    error TokenZeroAddress();

    /**
     * @notice The given tokens already have a {ButtonswapPair} instance
     */
    error PairExists();

    /**
     * @notice User does not have permission for the attempted operation
     */
    error Forbidden();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IButtonswapFactoryEvents {
    /**
     * @notice Emitted when a new Pair is created.
     * @param token0 The first sorted token
     * @param token1 The second sorted token
     * @param pair The address of the new {ButtonswapPair} contract
     * @param count The new total number of Pairs created
     */
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 count);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapERC20Errors} from "../IButtonswapERC20/IButtonswapERC20Errors.sol";

interface IButtonswapPairErrors is IButtonswapERC20Errors {
    /**
     * @notice Re-entrancy guard prevented method call
     */
    error Locked();

    /**
     * @notice User does not have permission for the attempted operation
     */
    error Forbidden();

    /**
     * @notice Integer maximums exceeded
     */
    error Overflow();

    /**
     * @notice Initial deposit not yet made
     */
    error Uninitialized();

    /**
     * @notice There was not enough liquidity in the reservoir
     */
    error InsufficientReservoir();

    /**
     * @notice Not enough liquidity was created during mint
     */
    error InsufficientLiquidityMinted();

    /**
     * @notice Not enough funds added to mint new liquidity
     */
    error InsufficientLiquidityAdded();

    /**
     * @notice More liquidity must be burned to be redeemed for non-zero amounts
     */
    error InsufficientLiquidityBurned();

    /**
     * @notice Swap was attempted with zero input
     */
    error InsufficientInputAmount();

    /**
     * @notice Swap was attempted with zero output
     */
    error InsufficientOutputAmount();

    /**
     * @notice Pool doesn't have the liquidity to service the swap
     */
    error InsufficientLiquidity();

    /**
     * @notice The specified "to" address is invalid
     */
    error InvalidRecipient();

    /**
     * @notice The product of pool balances must not change during a swap (save for accounting for fees)
     */
    error KInvariant();

    /**
     * @notice The new price ratio after a swap is invalid (one or more of the price terms are zero)
     */
    error InvalidFinalPrice();

    /**
     * @notice Single sided operations are not executable at this point in time
     */
    error SingleSidedTimelock();

    /**
     * @notice The attempted operation would have swapped reservoir tokens above the current limit
     */
    error SwappableReservoirExceeded();

    /**
     * @notice All operations on the pair other than dual-sided burning are currently paused
     */
    error Paused();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapERC20Events} from "../IButtonswapERC20/IButtonswapERC20Events.sol";

interface IButtonswapPairEvents is IButtonswapERC20Events {
    /**
     * @notice Emitted when a {IButtonswapPair-mint} is performed.
     * Some `token0` and `token1` are deposited in exchange for liquidity tokens representing a claim on them.
     * @param from The account that supplied the tokens for the mint
     * @param amount0 The amount of `token0` that was deposited
     * @param amount1 The amount of `token1` that was deposited
     * @param amountOut The amount of liquidity tokens that were minted
     * @param to The account that received the tokens from the mint
     */
    event Mint(address indexed from, uint256 amount0, uint256 amount1, uint256 amountOut, address indexed to);

    /**
     * @notice Emitted when a {IButtonswapPair-burn} is performed.
     * Liquidity tokens are redeemed for underlying `token0` and `token1`.
     * @param from The account that supplied the tokens for the burn
     * @param amountIn The amount of liquidity tokens that were burned
     * @param amount0 The amount of `token0` that was received
     * @param amount1 The amount of `token1` that was received
     * @param to The account that received the tokens from the burn
     */
    event Burn(address indexed from, uint256 amountIn, uint256 amount0, uint256 amount1, address indexed to);

    /**
     * @notice Emitted when a {IButtonswapPair-swap} is performed.
     * @param from The account that supplied the tokens for the swap
     * @param amount0In The amount of `token0` that went into the swap
     * @param amount1In The amount of `token1` that went into the swap
     * @param amount0Out The amount of `token0` that came out of the swap
     * @param amount1Out The amount of `token1` that came out of the swap
     * @param to The account that received the tokens from the swap
     */
    event Swap(
        address indexed from,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapERC20Errors} from "./IButtonswapERC20Errors.sol";
import {IButtonswapERC20Events} from "./IButtonswapERC20Events.sol";

interface IButtonswapERC20 is IButtonswapERC20Errors, IButtonswapERC20Events {
    /**
     * @notice Returns the name of the token.
     * @return name The token name
     */
    function name() external pure returns (string memory name);

    /**
     * @notice Returns the symbol of the token, usually a shorter version of the name.
     * @return symbol The token symbol
     */
    function symbol() external pure returns (string memory symbol);

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * @dev This information is only used for _display_ purposes: it in no way affects any of the arithmetic of the contract.
     * @return decimals The number of decimals
     */
    function decimals() external pure returns (uint8 decimals);

    /**
     * @notice Returns the amount of tokens in existence.
     * @return totalSupply The amount of tokens in existence
     */
    function totalSupply() external view returns (uint256 totalSupply);

    /**
     * @notice Returns the amount of tokens owned by `account`.
     * @param owner The account the balance is being checked for
     * @return balance The amount of tokens owned by `owner`
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner` through {transferFrom}.
     * This is zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     * @param owner The account that owns the tokens
     * @param spender The account that can spend the tokens
     * @return allowance The amount of tokens owned by `owner` that the `spender` can transfer
     */
    function allowance(address owner, address spender) external view returns (uint256 allowance);

    /**
     * @notice Sets `value` as the allowance of `spender` over the caller's tokens.
     * @dev IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {IButtonswapERC20Events-Approval} event.
     * @param spender The account that is granted permission to spend the tokens
     * @param value The amount of tokens that can be spent
     * @return success Whether the operation succeeded
     */
    function approve(address spender, uint256 value) external returns (bool success);

    /**
     * @notice Moves `value` tokens from the caller's account to `to`.
     * @dev Emits a {IButtonswapERC20Events-Transfer} event.
     * @param to The account that is receiving the tokens
     * @param value The amount of tokens being sent
     * @return success Whether the operation succeeded
     */
    function transfer(address to, uint256 value) external returns (bool success);

    /**
     * @notice Moves `value` tokens from `from` to `to` using the allowance mechanism.
     * `value` is then deducted from the caller's allowance.
     * @dev Emits a {IButtonswapERC20Events-Transfer} event.
     * @param from The account that is sending the tokens
     * @param to The account that is receiving the tokens
     * @param value The amount of tokens being sent
     * @return success Whether the operation succeeded
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /**
     * @notice Returns the domain separator used in the encoding of the signature for {permit}, as defined by [EIP712](https://eips.ethereum.org/EIPS/eip-712).
     * @return DOMAIN_SEPARATOR The `DOMAIN_SEPARATOR` value
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 DOMAIN_SEPARATOR);

    /**
     * @notice Returns the typehash used in the encoding of the signature for {permit}, as defined by [EIP712](https://eips.ethereum.org/EIPS/eip-712).
     * @return PERMIT_TYPEHASH The `PERMIT_TYPEHASH` value
     */
    function PERMIT_TYPEHASH() external pure returns (bytes32 PERMIT_TYPEHASH);

    /**
     * @notice Returns the current nonce for `owner`.
     * This value must be included whenever a signature is generated for {permit}.
     * @dev Every successful call to {permit} increases `owner`'s nonce by one.
     * This prevents a signature from being used multiple times.
     * @param owner The account to get the nonce for
     * @return nonce The current nonce for the given `owner`
     */
    function nonces(address owner) external view returns (uint256 nonce);

    /**
     * @notice Sets `value` as the allowance of `spender` over `owner`'s tokens, given `owner`'s signed approval.
     * @dev IMPORTANT: The same issues {approve} has related to transaction ordering also apply here.
     *
     * Emits an {IButtonswapERC20Events-Approval} event.
     *
     * Requirements:
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner` over the EIP712-formatted function arguments.
     * - the signature must use `owner`'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the [relevant EIP section](https://eips.ethereum.org/EIPS/eip-2612#specification).
     * @param owner The account that owns the tokens
     * @param spender The account that can spend the tokens
     * @param value The amount of `owner`'s tokens that `spender` can transfer
     * @param deadline The future time after which the permit is no longer valid
     * @param v Part of the signature
     * @param r Part of the signature
     * @param s Part of the signature
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // Borrowed implementation from solmate
    // https://github.com/transmissions11/solmate/blob/2001af43aedb46fdc2335d2a7714fb2dae7cfcd1/src/utils/FixedPointMathLib.sol#L164
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapFactory} from
    "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapFactory/IButtonswapFactory.sol";
import {IButtonswapPair} from "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapPair/IButtonswapPair.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {IBasicButtonswapRouter} from "./interfaces/IButtonswapRouter/IBasicButtonswapRouter.sol";
import {ButtonswapLibrary} from "./libraries/ButtonswapLibrary.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {RootButtonswapRouter} from "./RootButtonswapRouter.sol";

contract BasicButtonswapRouter is RootButtonswapRouter, IBasicButtonswapRouter {
    modifier ensure(uint256 deadline) {
        if (block.timestamp > deadline) {
            revert Expired();
        }
        _;
    }

    constructor(address _factory) RootButtonswapRouter(_factory) {}

    /**
     * @inheritdoc IBasicButtonswapRouter
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = ButtonswapLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountA);
        TransferHelper.safeApprove(tokenA, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountB);
        TransferHelper.safeApprove(tokenB, pair, amountB);

        (address token0,) = ButtonswapLibrary.sortTokens(tokenA, tokenB);
        if (tokenA == token0) {
            liquidity = IButtonswapPair(pair).mint(amountA, amountB, to);
        } else {
            liquidity = IButtonswapPair(pair).mint(amountB, amountA, to);
        }
    }

    /**
     * @inheritdoc IBasicButtonswapRouter
     */
    function addLiquidityWithReservoir(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) =
            _addLiquidityWithReservoir(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = ButtonswapLibrary.pairFor(factory, tokenA, tokenB);

        if (amountA > 0) {
            TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountA);
            TransferHelper.safeApprove(tokenA, pair, amountA);
            liquidity = IButtonswapPair(pair).mintWithReservoir(amountA, to);
        } else if (amountB > 0) {
            TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountB);
            TransferHelper.safeApprove(tokenB, pair, amountB);
            liquidity = IButtonswapPair(pair).mintWithReservoir(amountB, to);
        }
    }

    // **** REMOVE LIQUIDITY ****
    /**
     * @inheritdoc IBasicButtonswapRouter
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = ButtonswapLibrary.pairFor(factory, tokenA, tokenB);
        IButtonswapPair(pair).transferFrom(msg.sender, address(this), liquidity); // send liquidity to router
        (uint256 amount0, uint256 amount1) = IButtonswapPair(pair).burn(liquidity, to);
        (address token0,) = ButtonswapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        if (amountA < amountAMin) {
            revert InsufficientAAmount();
        }
        if (amountB < amountBMin) {
            revert InsufficientBAmount();
        }
    }

    /**
     * @inheritdoc IBasicButtonswapRouter
     */
    function removeLiquidityFromReservoir(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = ButtonswapLibrary.pairFor(factory, tokenA, tokenB);
        IButtonswapPair(pair).transferFrom(msg.sender, address(this), liquidity); // send liquidity to router
        (uint256 amount0, uint256 amount1) = IButtonswapPair(pair).burnFromReservoir(liquidity, to);
        (address token0,) = ButtonswapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        if (amountA < amountAMin) {
            revert InsufficientAAmount();
        }
        if (amountB < amountBMin) {
            revert InsufficientBAmount();
        }
    }

    /**
     * @inheritdoc IBasicButtonswapRouter
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        address pair = ButtonswapLibrary.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IButtonswapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    // **** SWAP ****
    /**
     * @inheritdoc IBasicButtonswapRouter
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = ButtonswapLibrary.getAmountsOut(factory, amountIn, path);
        if (amounts[amounts.length - 1] < amountOutMin) {
            revert InsufficientOutputAmount();
        }
        IButtonswapPair(ButtonswapLibrary.pairFor(factory, path[0], path[1]));

        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amounts[0]);
        _swap(amounts, path, to);
    }

    /**
     * @inheritdoc IBasicButtonswapRouter
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) returns (uint256[] memory amounts) {
        amounts = ButtonswapLibrary.getAmountsIn(factory, amountOut, path);
        if (amounts[0] > amountInMax) {
            revert ExcessiveInputAmount();
        }
        //        IButtonswapPair pair = IButtonswapPair(ButtonswapLibrary.pairFor(factory, path[0], path[1]));
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amounts[0]);
        _swap(amounts, path, to);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IRootButtonswapRouter} from "./IRootButtonswapRouter.sol";

interface IBasicButtonswapRouter is IRootButtonswapRouter {
    /**
     * @notice Adds liquidity to a pair, creating it if it doesn't exist yet, and transfers the liquidity tokens to the recipient.
     * @dev If the pair is empty, amountAMin and amountBMin are ignored.
     * If the pair is nonempty, it deposits as much of tokenA and tokenB as possible while maintaining 3 conditions:
     * 1. The ratio of tokenA to tokenB in the pair remains approximately the same
     * 2. The amount of tokenA in the pair is at least amountAMin but less than or equal to amountADesired
     * 3. The amount of tokenB in the pair is at least amountBMin but less than or equal to amountBDesired
     * @param tokenA The address of the first token in the pair.
     * @param tokenB The address of the second token in the pair.
     * @param amountADesired The maximum amount of the first token to add to the pair.
     * @param amountBDesired The maximum amount of the second token to add to the pair.
     * @param amountAMin The minimum amount of the first token to add to the pair.
     * @param amountBMin The minimum amount of the second token to add to the pair.
     * @param to The address to send the liquidity tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountA The amount of tokenA actually added to the pair.
     * @return amountB The amount of tokenB actually added to the pair.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /**
     * @notice Adds liquidity to a pair, opposite to the existing reservoir, and transfers the liquidity tokens to the recipient
     * @dev Since there at most one reservoir at a given time, some conditions are checked:
     * 1. If there is no reservoir, it rejects
     * 2. The token with the reservoir has its amountDesired parameter ignored
     * 3. The token with the reservoir has its amount deducted from the reservoir (checked against corresponding amountMin parameter)
     * @param tokenA The address of the first token in the pair.
     * @param tokenB The address of the second token in the pair.
     * @param amountADesired The maximum amount of the first token to add to the pair.
     * @param amountBDesired The maximum amount of the second token to add to the pair.
     * @param amountAMin The minimum amount of the first token to add to the pair.
     * @param amountBMin The minimum amount of the second token to add to the pair.
     * @param to The address to send the liquidity tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountA The amount of tokenA actually added to the pair.
     * @return amountB The amount of tokenB actually added to the pair.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidityWithReservoir(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /**
     * @notice Removes liquidity from a pair, and transfers the tokens to the recipient.
     * @param tokenA The address of the first token in the pair.
     * @param tokenB The address of the second token in the pair.
     * @param liquidity The amount of liquidity tokens to burn.
     * @param amountAMin The minimum amount of the first token to withdraw from the pair.
     * @param amountBMin The minimum amount of the second token to withdraw from the pair.
     * @param to The address to send the tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountA The amount of tokenA actually withdrawn from the pair.
     * @return amountB The amount of tokenB actually withdrawn from the pair.
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @notice Removes liquidity from the reservoir of a pair and transfers the tokens to the recipient.
     * @param tokenA The address of the first token in the pair.
     * @param tokenB The address of the second token in the pair.
     * @param liquidity The amount of liquidity tokens to burn.
     * @param amountAMin The minimum amount of the first token to withdraw from the pair.
     * @param amountBMin The minimum amount of the second token to withdraw from the pair.
     * @param to The address to send the tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @return amountA The amount of tokenA actually withdrawn from the pair.
     * @return amountB The amount of tokenB actually withdrawn from the pair.
     */
    function removeLiquidityFromReservoir(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @notice Similar to `removeLiquidity()` but utilizes the Permit signatures to reduce gas consumption.
     * Removes liquidity from a pair, and transfers the tokens to the recipient.
     * @param tokenA The address of the first token in the pair.
     * @param tokenB The address of the second token in the pair.
     * @param liquidity The amount of liquidity tokens to burn.
     * @param amountAMin The minimum amount of the first token to withdraw from the pair.
     * @param amountBMin The minimum amount of the second token to withdraw from the pair.
     * @param to The address to send the tokens to.
     * @param deadline The time after which this transaction can no longer be executed.
     * @param approveMax Whether the signature is for the max uint256 or liquidity value
     * @param v Part of the signature
     * @param r Part of the signature
     * @param s Part of the signature
     * @return amountA The amount of tokenA actually withdrawn from the pair.
     * @return amountB The amount of tokenB actually withdrawn from the pair.
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    /**
     * @notice Given an ordered array of tokens, performs consecutive swaps from a specific amount of the first token to the last token in the array.
     * @param amountIn The amount of the first token to swap.
     * @param amountOutMin The minimum amount of the last token to receive from the swap.
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @param to The address to send the output token to.
     * @param deadline The time after which this transaction can no longer be executed.
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * @notice Given an ordered array of tokens, performs consecutive swaps from the first token to a specific amount of the last token in the array.
     * @param amountOut The amount of the last token to receive from the swap.
     * @param amountInMax The maximum amount of the first token to swap.
     * @param path An array of token addresses [tokenA, tokenB, tokenC, ...] representing the path the input token takes to get to the output token
     * @param to The address to send the output token to.
     * @param deadline The time after which this transaction can no longer be executed.
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IETHButtonswapRouterErrors {
    /// @notice Only WETH contract can send ETH to contract
    error NonWETHSender();
    /// @notice WETH transfer failed
    error FailedWETHTransfer();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IButtonswapERC20Errors {
    /**
     * @notice Permit deadline was exceeded
     */
    error PermitExpired();

    /**
     * @notice Permit signature invalid
     */
    error PermitInvalidSignature();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IButtonswapERC20Events {
    /**
     * @notice Emitted when the allowance of a `spender` for an `owner` is set by a call to {IButtonswapERC20-approve}.
     * `value` is the new allowance.
     * @param owner The account that has granted approval
     * @param spender The account that has been given approval
     * @param value The amount the spender can transfer
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
     * @param from The account that sent the tokens
     * @param to The account that received the tokens
     * @param value The amount of tokens transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapFactory} from
    "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapFactory/IButtonswapFactory.sol";
import {IButtonswapPair} from "buttonswap-periphery_buttonswap-core/interfaces/IButtonswapPair/IButtonswapPair.sol";
import {TransferHelper} from "./libraries/TransferHelper.sol";
import {IRootButtonswapRouter} from "./interfaces/IButtonswapRouter/IRootButtonswapRouter.sol";
import {ButtonswapLibrary} from "./libraries/ButtonswapLibrary.sol";
import {IERC20} from "./interfaces/IERC20.sol";

contract RootButtonswapRouter is IRootButtonswapRouter {
    /**
     * @inheritdoc IRootButtonswapRouter
     */
    address public immutable override factory;

    constructor(address _factory) {
        factory = _factory;
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        address pair = IButtonswapFactory(factory).getPair(tokenA, tokenB);
        if (pair == address(0)) {
            IButtonswapFactory(factory).createPair(tokenA, tokenB);
        }

        uint256 totalA = IERC20(tokenA).balanceOf(pair);
        uint256 totalB = IERC20(tokenB).balanceOf(pair);

        if (totalA == 0 && totalB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = ButtonswapLibrary.quote(amountADesired, totalA, totalB);
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal < amountBMin) {
                    revert InsufficientBAmount();
                }
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = ButtonswapLibrary.quote(amountBDesired, totalB, totalA);
                assert(amountAOptimal <= amountADesired);
                if (amountAOptimal < amountAMin) {
                    revert InsufficientAAmount();
                }
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _addLiquidityWithReservoir(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // If the pair doesn't exist yet, there isn't any reservoir
        if (IButtonswapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            revert NoReservoir();
        }
        (uint256 poolA, uint256 poolB, uint256 reservoirA, uint256 reservoirB) =
            ButtonswapLibrary.getLiquidityBalances(factory, tokenA, tokenB);
        // the first liquidity addition should happen through _addLiquidity
        // can't initialize by matching with a reservoir
        if (poolA == 0 || poolB == 0) {
            revert NotInitialized();
        }
        if (reservoirA == 0 && reservoirB == 0) {
            revert NoReservoir();
        }

        if (reservoirA > 0) {
            // we take from reservoirA and the user-provided amountBDesired
            // But modify so that you don't do liquidityOut logic since you don't need it
            (, uint256 amountAOptimal) =
                ButtonswapLibrary.getMintSwappedAmounts(factory, tokenB, tokenA, amountBDesired);
            // User wants to drain to the res by amountAMin or more
            // Slippage-check
            if (amountAOptimal < amountAMin) {
                revert InsufficientAAmount();
            }
            (amountA, amountB) = (0, amountBDesired);
        } else {
            // we take from reservoirB and the user-provided amountADesired
            (, uint256 amountBOptimal) =
                ButtonswapLibrary.getMintSwappedAmounts(factory, tokenA, tokenB, amountADesired);
            if (amountBOptimal < amountBMin) {
                revert InsufficientBAmount();
            }
            (amountA, amountB) = (amountADesired, 0);
        }
    }

    // **** SWAP ****

    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = ButtonswapLibrary.sortTokens(input, output);
            uint256 amountIn = amounts[i];
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0In, uint256 amount1In) = input == token0 ? (amountIn, uint256(0)) : (uint256(0), amountIn);
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));

            address to = i < path.length - 2 ? address(this) : _to;
            IButtonswapPair pair = IButtonswapPair(ButtonswapLibrary.pairFor(factory, input, output));
            TransferHelper.safeApprove(input, address(pair), amountIn);
            pair.swap(amount0In, amount1In, amount0Out, amount1Out, to);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IButtonswapRouterErrors} from "./IButtonswapRouterErrors.sol";

interface IRootButtonswapRouter is IButtonswapRouterErrors {
    /**
     * @notice Returns the address of the Buttonswap Factory
     * @return factory The address of the Buttonswap Factory
     */
    function factory() external view returns (address factory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IButtonswapRouterErrors {
    /// @notice Deadline was exceeded
    error Expired();
    /// @notice Insufficient amount of token A available
    error InsufficientAAmount();
    /// @notice Insufficient amount of token B available
    error InsufficientBAmount();
    /// @notice Neither token in the pool has the required reservoir
    error NoReservoir();
    /// @notice Pools are not initialized
    error NotInitialized();
    /// @notice Insufficient amount of token A in the reservoir
    error InsufficientAReservoir();
    /// @notice Insufficient amount of token B in the reservoir
    error InsufficientBReservoir();
    /// @notice Insufficient tokens returned from operation
    error InsufficientOutputAmount();
    /// @notice Required input amount exceeds specified maximum
    error ExcessiveInputAmount();
    /// @notice Invalid path provided
    error InvalidPath();
}