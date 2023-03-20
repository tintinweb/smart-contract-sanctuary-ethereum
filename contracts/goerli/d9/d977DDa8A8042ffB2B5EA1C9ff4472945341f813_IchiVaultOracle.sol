// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IBaseOracle {
    /// @dev Return the USD based price of the given input, multiplied by 10**18.
    /// @param token The ERC-20 token to check the value.
    function getPrice(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IICHIVault is IERC20, IERC20Metadata {
    function ichiVaultFactory() external view returns (address);

    function pool() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function allowToken0() external view returns (bool);

    function allowToken1() external view returns (bool);

    function fee() external view returns (uint24);

    function tickSpacing() external view returns (int24);

    function currentTick() external view returns (int24);

    function twapPeriod() external view returns (uint32);

    function affiliate() external view returns (address);

    function baseLower() external view returns (int24);

    function baseUpper() external view returns (int24);

    function limitLower() external view returns (int24);

    function limitUpper() external view returns (int24);

    function deposit0Max() external view returns (uint256);

    function deposit1Max() external view returns (uint256);

    function maxTotalSupply() external view returns (uint256);

    function hysteresis() external view returns (uint256);

    function getTotalAmounts() external view returns (uint256, uint256);

    function deposit(uint256, uint256, address) external returns (uint256);

    function withdraw(uint256, address) external returns (uint256, uint256);

    function rebalance(
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        int256 swapQuantity
    ) external;

    function setDepositMax(uint256 _deposit0Max, uint256 _deposit1Max) external;

    function setAffiliate(address _affiliate) external;

    event DeployICHIVault(
        address indexed sender,
        address indexed pool,
        bool allowToken0,
        bool allowToken1,
        address owner,
        uint256 twapPeriod
    );

    event SetTwapPeriod(address sender, uint32 newTwapPeriod);

    event Deposit(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event Withdraw(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event Rebalance(
        int24 tick,
        uint256 totalAmount0,
        uint256 totalAmount1,
        uint256 feeAmount0,
        uint256 feeAmount1,
        uint256 totalSupply
    );

    event MaxTotalSupply(address indexed sender, uint256 maxTotalSupply);

    event Hysteresis(address indexed sender, uint256 hysteresis);

    event DepositMax(
        address indexed sender,
        uint256 deposit0Max,
        uint256 deposit1Max
    );

    event Affiliate(address indexed sender, address affiliate);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

library UniV3WrappedLibMockup {
    // TickMath
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    // OracleLibrary
    function consult(address pool, uint32 secondsAgo)
        external
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {}

    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) external pure returns (uint256 quoteAmount) {}

    function getSqrtRatioAtTick(int24 tick)
        external
        pure
        returns (uint160 sqrtPriceX96)
    {}

    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) external pure returns (uint256 amount0, uint256 amount1) {}

    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) external pure returns (uint128 liquidity) {}
}

// SPDX-License-Identifier: MIT
/*
██████╗ ██╗     ██╗   ██╗███████╗██████╗ ███████╗██████╗ ██████╗ ██╗   ██╗
██╔══██╗██║     ██║   ██║██╔════╝██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝
██████╔╝██║     ██║   ██║█████╗  ██████╔╝█████╗  ██████╔╝██████╔╝ ╚████╔╝
██╔══██╗██║     ██║   ██║██╔══╝  ██╔══██╗██╔══╝  ██╔══██╗██╔══██╗  ╚██╔╝
██████╔╝███████╗╚██████╔╝███████╗██████╔╝███████╗██║  ██║██║  ██║   ██║
╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
*/

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "../utils/BlueBerryErrors.sol" as Errors;
import "../utils/BlueBerryConst.sol" as Constants;
import "../libraries/UniV3/UniV3WrappedLibMockup.sol";
import "./UsingBaseOracle.sol";
import "../interfaces/IBaseOracle.sol";
import "../interfaces/ichi/IICHIVault.sol";

/**
 * @author gmspacex
 * @title Ichi Vault Oracle
 * @notice Oracle contract provides price feeds of Ichi Vault tokens
 * @dev The logic of this oracle is using legacy & traditional mathematics of Uniswap V2 Lp Oracle.
 *      Base token prices are fetched from Chainlink or Band Protocol.
 *      To prevent flashloan price manipulations, it compares spot & twap prices from Uni V3 Pool.
 */
contract IchiVaultOracle is UsingBaseOracle, IBaseOracle, Ownable {
    mapping(address => uint256) public maxPriceDeviations;

    constructor(IBaseOracle _base) UsingBaseOracle(_base) {}

    event SetPriceDeviation(address indexed token, uint256 maxPriceDeviation);

    /// @notice Set price deviations for given token
    /// @dev Input token is the underlying token of ICHI Vaults which is token0 or token1 of Uni V3 Pool
    /// @param token Token to price deviation
    /// @param maxPriceDeviation Max price deviation (in 1e18) of price feeds
    function setPriceDeviation(
        address token,
        uint256 maxPriceDeviation
    ) external onlyOwner {
        // Validate inputs
        if (token == address(0)) revert Errors.ZERO_ADDRESS();
        if (maxPriceDeviation > Constants.MAX_PRICE_DEVIATION)
            revert Errors.OUT_OF_DEVIATION_CAP(maxPriceDeviation);

        maxPriceDeviations[token] = maxPriceDeviation;
        emit SetPriceDeviation(token, maxPriceDeviation);
    }

    /**
     * @notice Get token0 spot price quoted in token1
     * @dev Returns token0 price of 1e18 amount
     * @param vault ICHI Vault address
     * @return price spot price of token0 quoted in token1
     */
    function spotPrice0InToken1(
        IICHIVault vault
    ) public view returns (uint256) {
        return
            UniV3WrappedLibMockup.getQuoteAtTick(
                vault.currentTick(), // current tick
                uint128(Constants.PRICE_PRECISION), // amountIn
                vault.token0(), // tokenIn
                vault.token1() // tokenOut
            );
    }

    /**
     * @notice Get token0 twap price quoted in token1
     * @dev Returns token0 price of 1e18 amount
     * @param vault ICHI Vault address
     * @return price spot price of token0 quoted in token1
     */
    function twapPrice0InToken1(
        IICHIVault vault
    ) public view returns (uint256) {
        (int256 twapTick, ) = UniV3WrappedLibMockup.consult(
            vault.pool(),
            vault.twapPeriod()
        );
        return
            UniV3WrappedLibMockup.getQuoteAtTick(
                int24(twapTick), // can assume safe being result from consult()
                uint128(Constants.PRICE_PRECISION), // amountIn
                vault.token0(), // tokenIn
                vault.token1() // tokenOut
            );
    }

    /**
     * @notice Internal function to validate deviations of 2 given prices
     * @param price0 First price to validate, base 1e18
     * @param price1 Second price to validate, base 1e18
     * @param maxPriceDeviation Max price deviation of 2 prices, base 10000
     */
    function _isValidPrices(
        uint256 price0,
        uint256 price1,
        uint256 maxPriceDeviation
    ) internal pure returns (bool) {
        uint256 delta = price0 > price1 ? (price0 - price1) : (price1 - price0);
        return ((delta * Constants.DENOMINATOR) / price0) <= maxPriceDeviation;
    }

    /**
     * @notice Return vault token price in USD, with 18 decimals of precision.
     * @param token The vault token to get the price of.
     * @return price USD price of token in 18 decimal
     */
    function getPrice(address token) external view override returns (uint256) {
        IICHIVault vault = IICHIVault(token);
        uint256 totalSupply = vault.totalSupply();
        if (totalSupply == 0) return 0;

        address token0 = vault.token0();
        address token1 = vault.token1();

        // Check price manipulations on Uni V3 pool by flashloan attack
        uint256 spotPrice = spotPrice0InToken1(vault);
        uint256 twapPrice = twapPrice0InToken1(vault);
        uint256 maxPriceDeviation = maxPriceDeviations[token0];
        if (!_isValidPrices(spotPrice, twapPrice, maxPriceDeviation))
            revert Errors.EXCEED_DEVIATION();

        // Total reserve / total supply
        (uint256 r0, uint256 r1) = vault.getTotalAmounts();
        uint256 px0 = base.getPrice(address(token0));
        uint256 px1 = base.getPrice(address(token1));
        uint256 t0Decimal = IERC20Metadata(token0).decimals();
        uint256 t1Decimal = IERC20Metadata(token1).decimals();

        uint256 totalReserve = (r0 * px0) /
            10 ** t0Decimal +
            (r1 * px1) /
            10 ** t1Decimal;

        return (totalReserve * 1e18) / totalSupply;
    }
}

// SPDX-License-Identifier: MIT
/*
██████╗ ██╗     ██╗   ██╗███████╗██████╗ ███████╗██████╗ ██████╗ ██╗   ██╗
██╔══██╗██║     ██║   ██║██╔════╝██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝
██████╔╝██║     ██║   ██║█████╗  ██████╔╝█████╗  ██████╔╝██████╔╝ ╚████╔╝
██╔══██╗██║     ██║   ██║██╔══╝  ██╔══██╗██╔══╝  ██╔══██╗██╔══██╗  ╚██╔╝
██████╔╝███████╗╚██████╔╝███████╗██████╔╝███████╗██║  ██║██║  ██║   ██║
╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
*/

pragma solidity 0.8.16;

import "../interfaces/IBaseOracle.sol";

contract UsingBaseOracle {
    IBaseOracle public immutable base; // Base oracle source

    constructor(IBaseOracle _base) {
        base = _base;
    }
}

// SPDX-License-Identifier: MIT
/*
██████╗ ██╗     ██╗   ██╗███████╗██████╗ ███████╗██████╗ ██████╗ ██╗   ██╗
██╔══██╗██║     ██║   ██║██╔════╝██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝
██████╔╝██║     ██║   ██║█████╗  ██████╔╝█████╗  ██████╔╝██████╔╝ ╚████╔╝
██╔══██╗██║     ██║   ██║██╔══╝  ██╔══██╗██╔══╝  ██╔══██╗██╔══██╗  ╚██╔╝
██████╔╝███████╗╚██████╔╝███████╗██████╔╝███████╗██║  ██║██║  ██║   ██║
╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
*/

pragma solidity 0.8.16;

uint256 constant DENOMINATOR = 10000;

uint256 constant MIN_LIQ_THRESHOLD = 8000;

uint256 constant PRICE_PRECISION = 1e18;

uint256 constant MAX_PRICE_DEVIATION = 1000; // max price deviation, 10%

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

// Common Errors
error ZERO_AMOUNT();
error ZERO_ADDRESS();
error INPUT_ARRAY_MISMATCH();

// Oracle Errors
error TOO_LONG_DELAY(uint256 delayTime);
error NO_MAX_DELAY(address token);
error PRICE_OUTDATED(address token);
error NO_SYM_MAPPING(address token);
error PRICE_NEGATIVE(address token);

error OUT_OF_DEVIATION_CAP(uint256 deviation);
error EXCEED_SOURCE_LEN(uint256 length);
error NO_PRIMARY_SOURCE(address token);
error NO_VALID_SOURCE(address token);
error EXCEED_DEVIATION();

error TOO_LOW_MEAN(uint256 mean);
error NO_MEAN(address token);
error NO_STABLEPOOL(address token);

error PRICE_FAILED(address token);
error LIQ_THRESHOLD_TOO_HIGH(uint256 threshold);
error LIQ_THRESHOLD_TOO_LOW(uint256 threshold);

error ORACLE_NOT_SUPPORT(address token);
error ORACLE_NOT_SUPPORT_LP(address lp);
error ORACLE_NOT_SUPPORT_WTOKEN(address wToken);
error NO_ORACLE_ROUTE(address token);

// Spell
error NOT_BANK(address caller);
error REFUND_ETH_FAILED(uint256 balance);
error NOT_FROM_WETH(address from);
error LP_NOT_WHITELISTED(address lp);
error COLLATERAL_NOT_EXIST(uint256 strategyId, address colToken);
error STRATEGY_NOT_EXIST(address spell, uint256 strategyId);
error EXCEED_MAX_POS_SIZE(uint256 strategyId);
error EXCEED_MAX_LTV();
error INCORRECT_STRATEGY_ID(uint256 strategyId);

// Ichi Spell
error INCORRECT_LP(address lpToken);
error INCORRECT_PID(uint256 pid);
error INCORRECT_COLTOKEN(address colToken);
error INCORRECT_UNDERLYING(address uToken);
error INCORRECT_DEBT(address debtToken);
error NOT_FROM_UNIV3(address sender);

// Vault
error BORROW_FAILED(uint256 amount);
error REPAY_FAILED(uint256 amount);
error LEND_FAILED(uint256 amount);
error REDEEM_FAILED(uint256 amount);

// Wrapper
error INVALID_TOKEN_ID(uint256 tokenId);
error BAD_PID(uint256 pid);
error BAD_REWARD_PER_SHARE(uint256 rewardPerShare);

// Bank
error NOT_UNDER_EXECUTION();
error NOT_EOA(address from);
error NOT_FROM_SPELL(address from);
error NOT_FROM_OWNER(uint256 positionId, address sender);
error SPELL_NOT_WHITELISTED(address spell);
error TOKEN_NOT_WHITELISTED(address token);
error BANK_NOT_LISTED(address token);
error BANK_ALREADY_LISTED();
error BANK_LIMIT();
error BTOKEN_ALREADY_ADDED();
error LEND_NOT_ALLOWED();
error BORROW_NOT_ALLOWED();
error REPAY_NOT_ALLOWED();
error WITHDRAW_LEND_NOT_ALLOWED();
error LOCKED();
error NOT_IN_EXEC();

error DIFF_COL_EXIST(address collToken);
error NOT_LIQUIDATABLE(uint256 positionId);
error BAD_POSITION(uint256 posId);
error BAD_COLLATERAL(uint256 positionId);
error INSUFFICIENT_COLLATERAL();
error REPAY_EXCEEDS_DEBT(uint256 repay, uint256 debt);
error INVALID_UTOKEN(address uToken);
error BORROW_ZERO_SHARE(uint256 borrowAmount);

// Config
error RATIO_TOO_HIGH(uint256 ratio);
error INVALID_FEE_DISTRIBUTION();
error NO_TREASURY_SET();
error FEE_WINDOW_ALREADY_STARTED();

// Utilities
error CAST();