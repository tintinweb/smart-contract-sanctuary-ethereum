// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

abstract contract PoolsharkHedgePoolEvents {

    event Mint(
        address indexed owner,
        uint256 amount0,
        uint256 amount1
    );

    event Burn(
        address indexed owner,
        uint256 amount0,
        uint256 amount1
    );

    event Collect(
        address indexed sender, 
        uint256 amount0, 
        uint256 amount1
    );

    event Swap(
        address indexed recipient, 
        address indexed tokenIn, 
        address indexed tokenOut, 
        uint256 amountIn,
        uint256 amountOut
    );

    event PoolCreated(
        address pool,
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../interfaces/IPoolsharkHedgePoolStructs.sol";
import "../interfaces/IPoolsharkHedgePoolFactory.sol";
import "../interfaces/IPoolsharkUtils.sol";
import "../utils/PoolsharkErrors.sol";
import "../libraries/Ticks.sol";

abstract contract PoolsharkHedgePoolStorage is IPoolsharkHedgePoolStructs, PoolsharkHedgePoolErrors {
    uint256 internal unlocked;

    IPoolsharkUtils public utils;
    address public feeTo;

    uint24 internal constant MAX_FEE = 10000; /// @dev Equivalent to 1%.
    /// @dev Reference: tickSpacing of 100 -> 2% between ticks.

    PoolState public pool0; /// @dev State for token0 as output
    PoolState public pool1; /// @dev State for token1 as output
    int24 public latestTick; /// @dev Latest updated inputPool price tick
    //TODO: size correctly
    uint256 public lastBlockNumber;
    
    mapping(int24 => TickNode) public tickNodes;  /// @dev Tick nodes in linked list
    mapping(int24 => Tick) public ticks0;         /// @dev Ticks containing token0 as output
    mapping(int24 => Tick) public ticks1;         /// @dev Ticks containing token1 as output
    mapping(address => mapping(int24 => mapping(int24 => Position))) public positions0; //positions with token0 deposited
    mapping(address => mapping(int24 => mapping(int24 => Position))) public positions1; //positions with token1 deposited
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title The interface for the Concentrated Liquidity Pool Factory
interface IConcentratedFactory {
    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeTierTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

interface IConcentratedPool 
{
    /// @notice This is to be used at hedge pool initialization in case the cardinality is too low for the hedge pool.
    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(
        uint16 observationCardinalityNext
    ) external;

    function token0() external view returns (address);
    function token1() external view returns (address);

    
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
    external view
    returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    );

    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(
        uint32[] calldata secondsAgos
    )
    external view
    returns (
        int56[] memory tickCumulatives,
        uint160[] memory secondsPerLiquidityCumulativeX128s
    );

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./IPoolsharkHedgePoolStructs.sol";

/// @notice Trident Concentrated Liquidity Pool interface.
interface IPoolsharkHedgePool is  IPoolsharkHedgePoolStructs {

    // function collect(int24 lower, int24 upper) external returns (uint256 amount0fees, uint256 amount1fees);

    function mint(
        int24 lowerOld,
        int24 lower,
        int24 upperOld,
        int24 upper,
        uint128 amountDesired,
        bool zeroForOne,
        bool native
    ) external;

    function burn(
        int24 lower,
        int24 upper,
        int24 claim,
        bool zeroForOne,
        uint128 amount
    ) external;

    function swap(
        address recipient,
        bool zeroForOne,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
        // bytes calldata data
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

abstract contract IPoolsharkHedgePoolFactory {

    mapping(uint256 => uint256) public feeTierTickSpacing;

    address public owner;
    address public concentratedFactory;
    address public libraries;

    mapping(bytes32 => address) public poolMapping;
    address[] public poolList;

    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    function createHedgePool(
        address fromToken,
        address destToken,
        uint256 fee
    ) external virtual returns (address book);

    function getHedgePool(
        address fromToken,
        address destToken,
        uint256 fee
    ) external virtual view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IPoolsharkHedgePoolStructs {

    struct PoolState {
        int24   nearestTick;       /// @dev Tick below current price
        uint160 price;             /// @dev Starting price current
        uint128 liquidity;         /// @dev Liquidity currently active
        uint232 feeGrowthGlobalIn; /// @dev Global fee growth per liquidity unit
    }

    struct TickNode {
        int24    previousTick;
        int24    nextTick;
    }

    struct Tick {
        int128   liquidityDelta;      //TODO: if feeGrowthGlobalIn > position.feeGrowthGlobal don't update liquidity
        uint128  liquidityDeltaMinus; // represent LPs for token0 -> token1
        uint232  feeGrowthGlobalIn;   // Used to check for claim updates
        int128   amountInDelta; 
        int128   amountOutDelta;
        uint64   amountInDeltaCarryPercent;
        uint64   amountOutDeltaCarryPercent;
    }
 
    // balance needs to be immediately transferred to the position owner
    struct Position {
        uint128 liquidity;           // expected amount to be used not actual
        uint232 feeGrowthGlobalIn; // last feeGrowth this position was updated at
        uint160 claimPriceLast;      // highest price claimed at
        uint128 amountIn;            // token amount already claimed; balance
        uint128 amountOut;           // necessary for non-custodial positions
    }

    //TODO: should we have a recipient field here?
    struct MintParams {
        int24 lowerOld;
        int24 lower;
        int24 upperOld;
        int24 upper;
        uint128 amountDesired;
        bool zeroForOne;
        bool native;
    }

    //TODO: optimize this struct
    struct SwapCache {
        uint256 price;
        uint256 liquidity;
        uint256 feeAmount;
        uint256 input;
    }

    struct UpdatePositionCache {
        Position position;
        uint232 feeGrowthGlobalIn;
        uint160 priceLower;
        uint160 priceUpper;
        uint160 claimPrice;
        bool removeLower;
        bool removeUpper;
        int24 upperRemove;
        int24 lowerRemove;
        int128 amountInDelta;
        int128 amountOutDelta;
    }

    struct AccumulateCache {
        int24   nextTickToCross0;
        int24   nextTickToCross1;
        int24   nextTickToAccum0;
        int24   nextTickToAccum1;
        int24   stopTick0;
        int24   stopTick1;
        uint160 price0;
        uint160 price1;
        uint128 liquidity0;
        uint128 liquidity1;
        int128   amountInDelta0; 
        int128   amountInDelta1; 
        int128   amountOutDelta0;
        int128   amountOutDelta1;

    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./utils/IDyDxMath.sol";
import "./utils/IFullPrecisionMath.sol";
import "./utils/IMathUtils.sol";
import "./utils/IRebaseLibrary.sol";
import "./utils/ISafeCast.sol";
import "./utils/ISwapLib.sol";
import "./utils/ITwapOracle.sol";
import "./utils/IUnsafeMath.sol";

interface IPoolsharkUtils is 
    IDyDxMath,
    IFullPrecisionMath,
    IMathUtils,
    IRebaseLibrary,
    ISafeCast,
    ISwapLib,
    ITwapOracle,
    IUnsafeMath
{}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IDyDxMath {
    function getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) external pure returns (uint256 dy);

    function getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) external pure returns (uint256 dx);

    function getLiquidityForAmounts(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 dy,
        uint256 dx
    ) external pure returns (uint256 liquidity);

    function getAmountsForLiquidity(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 liquidityAmount,
        bool roundUp
    ) external view returns (uint128 token0amount, uint128 token1amount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IFullPrecisionMath {
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256 result);

    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256 result);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

interface IMathUtils {
    function within1(
        uint256 a,
        uint256 b
    ) external pure returns (bool);

    function sqrt(
        uint256 x
    ) external pure returns (uint256 z);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

interface IRebaseLibrary {
    function toBase(
        Rebase memory total,
        uint256 elastic
    ) external pure returns (uint256 base);

    function toElastic(
        Rebase memory total,
        uint256 base
    ) external pure returns (uint256 elastic);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface ISafeCast {
    function toUint160(
        uint256 y
    ) external pure returns (uint160 z);

    function toUint128(
        uint256 y
    ) external pure returns (uint128 z);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface ISwapLib {
    function handleFees(
        uint256 output,
        uint24  swapFee,
        uint256 currentLiquidity,
        uint256 totalFeeAmount,
        uint256 amountOut,
        uint256 protocolFee,
        uint256 feeGrowthGlobal
    )
    external
    view
    returns (
        uint256 totalFeeAmount_,
        uint256 amountOut_,
        uint256 protocolFee_,
        uint256 feeGrowthGlobal_
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "../IConcentratedPool.sol";

interface ITwapOracle {
    function initializePoolObservations(
        IConcentratedPool pool
    ) external returns (int24 startingTick);

    function calculateAverageTick(
        IConcentratedPool pool
    ) external view returns (int24 averageTick);

    function isPoolObservationsEnough(
        IConcentratedPool pool
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IUnsafeMath {
    function divRoundingUp(
        uint256 x,
        uint256 y
    ) external pure returns (uint256 z);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./FullPrecisionMath.sol";
import "hardhat/console.sol";

/// @notice Math library that facilitates ranged liquidity calculations.
library DyDxMath
{
    function getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) external pure returns (uint256 dy) {
        return _getDy(liquidity, priceLower, priceUpper, roundUp);
    }

    function getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) external pure returns (uint256 dx) {
        return _getDx(liquidity, priceLower, priceUpper, roundUp);
    }

    function _getDy(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dy) {
        unchecked {
            if (roundUp) {
                dy = FullPrecisionMath.mulDivRoundingUp(liquidity, priceUpper - priceLower, 0x1000000000000000000000000);
            } else {
                dy = FullPrecisionMath.mulDiv(liquidity, priceUpper - priceLower, 0x1000000000000000000000000);
            }
        }
    }

    function _getDx(
        uint256 liquidity,
        uint256 priceLower,
        uint256 priceUpper,
        bool roundUp
    ) internal pure returns (uint256 dx) {
        unchecked {
            if (roundUp) {
                dx = FullPrecisionMath.divRoundingUp(FullPrecisionMath.mulDivRoundingUp(liquidity << 96, priceUpper - priceLower, priceUpper), priceLower);
            } else {
                dx = FullPrecisionMath.mulDiv(liquidity << 96, priceUpper - priceLower, priceUpper) / priceLower;
            }
        }
    }

    function getLiquidityForAmounts(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 dy,
        uint256 dx
    ) external pure returns (uint256 liquidity) {
        unchecked {
            if (priceUpper <= currentPrice) {
                liquidity = FullPrecisionMath.mulDiv(dy, 0x1000000000000000000000000, priceUpper - priceLower);
            } else if (currentPrice <= priceLower) {
                liquidity = FullPrecisionMath.mulDiv(
                    dx,
                    FullPrecisionMath.mulDiv(priceLower, priceUpper, 0x1000000000000000000000000),
                    priceUpper - priceLower
                );
            } else {
                uint256 liquidity1 = FullPrecisionMath.mulDiv(dy, 0x1000000000000000000000000, currentPrice - priceLower);
                liquidity = liquidity1;
            }
        }
    }

    function getAmountsForLiquidity(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 liquidityAmount,
        bool roundUp
    ) external view returns (uint128 token0amount, uint128 token1amount) {
        if (priceUpper <= currentPrice) {
            // Only supply `token1` (`token1` is Y).
            //TODO: confirm casting is safe
            token1amount = uint128(_getDy(liquidityAmount, priceLower, priceUpper, roundUp));
        } else if (currentPrice <= priceLower) {
            // Only supply `token0` (`token0` is X).
            token0amount = uint128(_getDx(liquidityAmount, priceLower, priceUpper, roundUp));
        } else {
            // Supply both tokens.
            token0amount = uint128(_getDx(liquidityAmount, currentPrice, priceUpper, roundUp));
            token1amount = uint128(_getDy(liquidityAmount, priceLower, currentPrice, roundUp));
        }
        console.log("tokenIn amount:        ", token0amount);
        console.log("tokenOut amount:       ", token1amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Math library that facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision.
library FullPrecisionMath
{
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256 result) {
        return _mulDiv(a, b, denominator);
    }

    // @dev no underflow or overflow checks
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }

    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256 result) {
        return _mulDivRoundingUp(a, b, denominator);
    }

    /// @notice Calculates floor(a×b÷denominator) with full precision - throws if result overflows an uint256 or denominator == 0.
    /// @param a The multiplicand.
    /// @param b The multiplier.
    /// @param denominator The divisor.
    /// @return result The 256-bit result.
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    function _mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b.
            // Compute the product mod 2**256 and mod 2**256 - 1,
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product.
            uint256 prod1; // Most significant 256 bits of the product.
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }
            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }
            // Make sure the result is less than 2**256 -
            // also prevents denominator == 0.
            require(denominator > prod1);
            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////
            // Make division exact by subtracting the remainder from [prod1 prod0] -
            // compute remainder using mulmod.
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number.
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }
            // Factor powers of two out of denominator -
            // compute largest power of two divisor of denominator
            // (always >= 1).
            uint256 twos = uint256(-int256(denominator)) & denominator;
            // Divide denominator by power of two.
            assembly {
                denominator := div(denominator, twos)
            }
            // Divide [prod1 prod0] by the factors of two.
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos -
            // if twos is zero, then it becomes one.
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;
            // Invert denominator mod 2**256 -
            // now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // for four bits. That is, denominator * inv = 1 mod 2**4.
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // Inverse mod 2**8.
            inv *= 2 - denominator * inv; // Inverse mod 2**16.
            inv *= 2 - denominator * inv; // Inverse mod 2**32.
            inv *= 2 - denominator * inv; // Inverse mod 2**64.
            inv *= 2 - denominator * inv; // Inverse mod 2**128.
            inv *= 2 - denominator * inv; // Inverse mod 2**256.
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

    /// @notice Calculates ceil(a×b÷denominator) with full precision - throws if result overflows an uint256 or denominator == 0.
    /// @param a The multiplicand.
    /// @param b The multiplier.
    /// @param denominator The divisor.
    /// @return result The 256-bit result.
    function _mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = _mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) != 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

/// @notice Math library for computing sqrt price for ticks of size 1.0001, i.e., sqrt(1.0001^tick) as fixed point Q64.96 numbers - supports
/// prices between 2**-128 and 2**128 - 1.
/// @author Adapted from https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/libraries/TickMath.sol.
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128.
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128 - 1.
    int24 internal constant MAX_TICK = -MIN_TICK;
    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick - equivalent to getSqrtRatioAtTick(MIN_TICK).
    uint160 internal constant MIN_SQRT_RATIO = 4294967296;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick - equivalent to getSqrtRatioAtTick(MAX_TICK).
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    error TickOutOfBounds();
    error PriceOutOfBounds(); 

    function getSqrtRatioAtTick(int24 tick) external pure returns (uint160 getSqrtPriceX96) {
        return _getSqrtRatioAtTick(tick);
    }

    function getTickAtSqrtRatio(uint160 sqrtPriceX96) external pure returns (int24 tick) {
        return _getTickAtSqrtRatio(sqrtPriceX96);
    }

    /// @notice Calculates sqrt(1.0001^tick) * 2^96.
    /// @dev Throws if |tick| > max tick.
    /// @param tick The input tick for the above formula.
    /// @return sqrtPriceX96 Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick.
    function _getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        if (absTick > uint256(uint24(MAX_TICK))) revert TickOutOfBounds();
        unchecked {
            uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
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
            // This divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // We then downcast because we know the result always fits within 160 bits due to our tick input constraint.
            // We round up in the division so getTickAtSqrtRatio of the output price is always consistent.
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    function validatePrice(uint160 price) external pure {
        if (price < MIN_SQRT_RATIO || price >= MAX_SQRT_RATIO) revert PriceOutOfBounds();
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio.
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96.
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio.
    function _getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (sqrtPriceX96 < MIN_SQRT_RATIO || sqrtPriceX96 >= MAX_SQRT_RATIO) revert PriceOutOfBounds();
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb;

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
        unchecked {
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

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number.

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : _getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import "./TickMath.sol";
import "../interfaces/IPoolsharkHedgePoolStructs.sol";
import "../utils/PoolsharkErrors.sol";
import "hardhat/console.sol";
import "./FullPrecisionMath.sol";
import "./DyDxMath.sol";

/// @notice Tick management library for ranged liquidity.
library Ticks
{
    error NotImplementedYet();
    error WrongTickOrder();
    error WrongTickLowerRange();
    error WrongTickUpperRange();
    error WrongTickLowerOld();
    error WrongTickUpperOld();
    error NoLiquidityToRollover();

    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    using Ticks for mapping(int24 => IPoolsharkHedgePoolStructs.Tick);

    function getMaxLiquidity(int24 tickSpacing) external pure returns (uint128) {
        return type(uint128).max / uint128(uint24(TickMath.MAX_TICK) / (2 * uint24(tickSpacing)));
    }

    function cross(
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        int24 currentTick,
        int24 nextTickToCross,
        uint128 currentLiquidity,
        bool zeroForOne
    ) external view returns (uint256, int24, int24) {
        return _cross(
            ticks,
            tickNodes,
            currentTick,
            nextTickToCross,
            currentLiquidity,
            zeroForOne
        );
    }

    //maybe call ticks on msg.sender to get tick
    function _cross(
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        int24 currentTick,
        int24 nextTickToCross,
        uint128 currentLiquidity,
        bool zeroForOne
    ) internal view returns (uint128, int24, int24) {
        currentTick = nextTickToCross;
        int128 liquidityDelta = ticks[nextTickToCross].liquidityDelta;
        console.log('cross tick');
        console.logInt(currentTick);
        console.logInt(nextTickToCross);
        console.logInt(liquidityDelta);
        console.log(currentLiquidity);
        if(liquidityDelta > 0) {
            currentLiquidity += uint128(liquidityDelta);
        } else {
            currentLiquidity -= uint128(-liquidityDelta);
        }
        if (zeroForOne) {
            nextTickToCross = tickNodes[nextTickToCross].previousTick;
        } else {
            nextTickToCross = tickNodes[nextTickToCross].nextTick;
        }
        return (currentLiquidity, currentTick, nextTickToCross);
    }
    //TODO: ALL TICKS NEED TO BE CREATED WITH 
    function insert(
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        int24 latestTick,
        uint232 feeGrowthGlobalIn,
        int24 lowerOld,
        int24 lower,
        int24 upperOld,
        int24 upper,
        uint128 amount,
        bool isPool0
    ) external {
        if (lower >= upper || lowerOld >= upperOld) {
            revert WrongTickOrder();
        }
        if (TickMath.MIN_TICK > lower) {
            revert WrongTickLowerRange();
        }
        if (upper > TickMath.MAX_TICK) {
            revert WrongTickUpperRange();
        }
        //TODO: merge Tick and TickData -> ticks0 and ticks1
        // Stack overflow.
        // console.log('current lower liquidity:', currentLowerLiquidity);
        //TODO: handle lower = latestTick
        if (ticks[lower].liquidityDelta != 0 
            || ticks[lower].liquidityDeltaMinus != 0
            || ticks[lower].amountInDelta != 0
        ) {
            // tick exists
            //TODO: ensure amount < type(int128).max()
            console.log('insert liq');
            if (isPool0) {
                ticks[lower].liquidityDelta      -= int128(amount);
                ticks[lower].liquidityDeltaMinus += amount;
            } else {
                ticks[lower].liquidityDelta      += int128(amount);
            }
            if(ticks[lower].feeGrowthGlobalIn == 0) {
                ticks[lower].feeGrowthGlobalIn = feeGrowthGlobalIn;
            } 
        } else {
            // tick does not exist and we must insert
            //TODO: handle new TWAP being in between lowerOld and lower
            if (isPool0) {
                ticks[lower] = IPoolsharkHedgePoolStructs.Tick(
                    -int128(amount),
                    amount,
                    feeGrowthGlobalIn,
                    0,0,0,0
                );
            } else {
                ticks[lower] = IPoolsharkHedgePoolStructs.Tick(
                    int128(amount),
                    0,
                    feeGrowthGlobalIn,
                    0,0,0,0
                );
            }

        }
        console.log('lower tick');
        console.logInt(tickNodes[lower].nextTick);
        console.logInt(tickNodes[lower].previousTick);
        if(tickNodes[lower].nextTick == tickNodes[lower].previousTick && lower != TickMath.MIN_TICK) {
                    console.log('lower tick');
            int24 oldNextTick = tickNodes[lowerOld].nextTick;
            if (upper < oldNextTick) { oldNextTick = upper; }
            /// @dev - don't set previous tick so upper can be initialized
            else { tickNodes[oldNextTick].previousTick = lower; }

            if (lowerOld >= lower || lower >= oldNextTick) {
                console.log('tick check');
                console.logInt(tickNodes[lowerOld].nextTick);
                console.logInt(tickNodes[lowerOld].previousTick);
                revert WrongTickLowerOld();
            }
            console.logInt(oldNextTick);
            tickNodes[lower] = IPoolsharkHedgePoolStructs.TickNode(
                lowerOld,
                oldNextTick
            );
            tickNodes[lowerOld].nextTick = lower;
        }
        console.log('lower tick');
        console.logInt(tickNodes[lower].nextTick);
        console.logInt(tickNodes[lower].previousTick);
                console.log('upper tick');
        console.logInt(tickNodes[upper].previousTick);
        console.logInt(tickNodes[upper].nextTick);
        if (ticks[upper].liquidityDelta != 0 
            || ticks[upper].liquidityDeltaMinus != 0
            || ticks[lower].amountInDelta != 0
        ) {
            // We are adding liquidity to an existing tick.
            if (isPool0) {
                ticks[upper].liquidityDelta      += int128(amount);
            } else {
                ticks[upper].liquidityDelta      -= int128(amount);
                ticks[upper].liquidityDeltaMinus += amount;
            }
            if (ticks[upper].feeGrowthGlobalIn == 0) {
                ticks[upper].feeGrowthGlobalIn = feeGrowthGlobalIn;
            }    
        } else {
            //TODO: set feeGrowth to 1 initially
            if (isPool0) {
                ticks[upper] = IPoolsharkHedgePoolStructs.Tick(
                    int128(amount),
                    0,
                    feeGrowthGlobalIn,
                    0,0,0,0
                );
            } else {
                            console.log('upper does not exist');
                ticks[upper] = IPoolsharkHedgePoolStructs.Tick(
                    -int128(amount),
                    amount,
                    feeGrowthGlobalIn,
                    0,0,0,0
                );
            }
        }
        console.log('upper tick');
        console.logInt(tickNodes[upper].previousTick);
        console.logInt(tickNodes[upper].nextTick);
        if(tickNodes[upper].nextTick == tickNodes[upper].previousTick && upper != TickMath.MAX_TICK) {
            int24 oldPrevTick = tickNodes[upperOld].previousTick;
            console.logInt(oldPrevTick);
            if (lower > oldPrevTick) oldPrevTick = lower;
            console.log('upper new');
            console.logInt(oldPrevTick);
            console.logInt(upperOld);
            console.logInt(upper);
            console.logInt(latestTick);

            // console.logInt(tickNodes[upperOld].nextTick);
            // console.logInt(tickNodes[upperOld].previousTick);
            // console.logInt(ticks[upper].liquidityDelta);
            // console.log(ticks[upper].liquidityDeltaMinus);
            //TODO: handle new TWAP being in between upperOld and upper
            /// @dev - if nextTick == previousTick this tick node is uninitialized
            if (tickNodes[upperOld].nextTick == tickNodes[upperOld].previousTick
                    || upperOld <= upper 
                    || upper <= oldPrevTick
                ) {
                revert WrongTickUpperOld();
            }

            tickNodes[upper] = IPoolsharkHedgePoolStructs.TickNode(
                oldPrevTick,
                upperOld
            );
            tickNodes[oldPrevTick].nextTick = upper;
            tickNodes[upperOld].previousTick = upper;
        }
    }

    function remove(
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        int24 lower,
        int24 upper,
        uint128 amount,
        bool isPool0,
        bool removeLower,
        bool removeUpper
    ) external {
        //TODO: we can only delete is lower != MIN_TICK or latestTick and all values are 0
        bool deleteLowerTick = false;
        //TODO: we can only delete is upper != MAX_TICK or latestTick and all values are 0
        bool deleteUpperTick = false;
        if (deleteLowerTick) {
            console.log('deleting lower tick');
            // Delete lower tick.
            int24 previous = tickNodes[lower].previousTick;
            int24 next     = tickNodes[lower].nextTick;
            if(next != upper || !deleteUpperTick) {
                tickNodes[previous].nextTick = next;
                tickNodes[next].previousTick = previous;
            } else {
                int24 upperNextTick = tickNodes[upper].nextTick;
                tickNodes[tickNodes[lower].previousTick].nextTick = upperNextTick;
                tickNodes[upperNextTick].previousTick = previous;
            }
        }
        if (removeLower) {
            if (isPool0) {
                ticks[lower].liquidityDelta += int128(amount);
                ticks[lower].liquidityDeltaMinus -= amount;
            } else {
                ticks[lower].liquidityDelta -= int128(amount);
            }
        }

        //TODO: could also modify amounts and then check if liquidityDelta and liquidityDeltaMinus are both zero
        if (deleteUpperTick) {
            // Delete upper tick.
            int24 previous = tickNodes[upper].previousTick;
            int24 next     = tickNodes[upper].nextTick;

            if(previous != lower || !deleteLowerTick) {
                tickNodes[previous].nextTick = next;
                tickNodes[next].previousTick = previous;
            } else {
                int24 lowerPrevTick = tickNodes[lower].previousTick;
                tickNodes[lowerPrevTick].nextTick = next;
                tickNodes[next].previousTick = lowerPrevTick;
            }
        }
        //TODO: we need to know what tick they're claiming from
        //TODO: that is the tick that should have liquidity values modified
        //TODO: keep unchecked block?
        if (removeUpper) {
            if (isPool0) {
                ticks[upper].liquidityDelta -= int128(amount);
            } else {
                ticks[upper].liquidityDelta += int128(amount);
                ticks[upper].liquidityDeltaMinus -= amount;
            }
        }
        /// @dev - we can never delete ticks due to amount deltas

        console.log('removed lower liquidity:', amount);
        console.log('removed upper liquidity:', amount);
    }

    function _accumulate(
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        int24 nextTickToCross,
        int24 nextTickToAccum,
        uint128 currentLiquidity,
        uint232 feeGrowthGlobal,
        int128 amountInDelta,
        int128 amountOutDelta,
        bool removeLiquidity
    ) internal returns (int128, int128) {
        console.log('fee growth accumulate check');
        console.log(ticks[nextTickToCross].feeGrowthGlobalIn);
        console.log(ticks[nextTickToAccum].feeGrowthGlobalIn);

        //update fee growth
        ticks[nextTickToAccum].feeGrowthGlobalIn = feeGrowthGlobal;

        //remove all liquidity from previous tick
        if (removeLiquidity) {
            ticks[nextTickToCross].liquidityDelta = 0;
            ticks[nextTickToCross].liquidityDeltaMinus = 0;
        }
        //check for deltas to carry
        if(ticks[nextTickToCross].amountInDeltaCarryPercent > 0){
            //TODO: will this work with negatives?
            int128 amountInDeltaCarry = int64(ticks[nextTickToCross].amountInDeltaCarryPercent) 
                                            * ticks[nextTickToCross].amountInDelta / 1e18;
            ticks[nextTickToCross].amountInDelta -= amountInDeltaCarry;
            ticks[nextTickToCross].amountInDeltaCarryPercent = 0;
            amountInDelta += amountInDeltaCarry;
            /// @dev - amountOutDelta cannot exist without amountInDelta
            if(ticks[nextTickToCross].amountOutDeltaCarryPercent > 0){
            //TODO: will this work with negatives?
                int256 amountOutDeltaCarry = int64(ticks[nextTickToCross].amountOutDeltaCarryPercent) 
                                                * ticks[nextTickToCross].amountOutDelta / 1e18;
                ticks[nextTickToCross].amountOutDelta -= int128(amountOutDeltaCarry);
                ticks[nextTickToCross].amountOutDeltaCarryPercent = 0;
                amountOutDelta += int128(amountOutDeltaCarry);
            }
        }
        if (currentLiquidity > 0) {
            //write amount deltas and set cache to zero
            uint128 liquidityDeltaMinus = ticks[nextTickToAccum].liquidityDeltaMinus;
            if (currentLiquidity != liquidityDeltaMinus) {
                //
                ticks[nextTickToAccum].amountInDelta  += amountInDelta;
                ticks[nextTickToAccum].amountOutDelta += amountOutDelta;
                int128 liquidityDeltaPlus = ticks[nextTickToAccum].liquidityDelta + int128(liquidityDeltaMinus);
                if (liquidityDeltaPlus > 0) {
                    /// @dev - amount deltas get diluted when liquidity is added
                    int128 liquidityPercentIncrease = liquidityDeltaPlus * 1e18 / int128(currentLiquidity - liquidityDeltaMinus);
                    amountOutDelta = amountOutDelta * (1e18 + liquidityPercentIncrease) / 1e18;
                    amountInDelta = amountInDelta * (1e18 + liquidityPercentIncrease) / 1e18;
                }
            } else {
                ticks[nextTickToAccum].amountInDelta += amountInDelta;
                ticks[nextTickToAccum].amountOutDelta += amountOutDelta;
                amountInDelta = 0;
                amountOutDelta = 0;
            }
            // update fee growth
        }
        return (amountInDelta, amountOutDelta);
    }

    function _rollover(
        int24 nextTickToCross,
        uint256 currentPrice,
        uint256 currentLiquidity,
        bool isPool0
    ) internal pure returns (int128 amountInDelta, int128 amountOutDelta) {
        if (currentLiquidity == 0) { revert NoLiquidityToRollover(); }
        uint160 nextPrice = TickMath.getSqrtRatioAtTick(nextTickToCross);

        if(currentPrice != nextPrice) {
            //handle liquidity rollover
            uint256 amountInUnfilled; uint256 amountOutLeftover;
            if(isPool0) {
                // leftover x provided
                amountOutLeftover = DyDxMath.getDx(
                    currentLiquidity,
                    currentPrice,
                    nextPrice,
                    false
                );
                // unfilled y amount
                amountInUnfilled = DyDxMath.getDy(
                    currentLiquidity,
                    currentPrice,
                    nextPrice,
                    false
                );
            } else {
                amountOutLeftover = DyDxMath.getDy(
                    currentLiquidity,
                    nextPrice,
                    currentPrice,
                    false
                );
                amountInUnfilled = DyDxMath.getDx(
                    currentLiquidity,
                    nextPrice,
                    currentPrice,
                    false
                );
            }

            //TODO: ensure this will not overflow with 32 bits
            //TODO: return this value to limit storage reads and writes
            amountInDelta -= int128(uint128(
                                                        FullPrecisionMath.mulDiv(
                                                            amountInUnfilled,
                                                            0x1000000000000000000000000, 
                                                            currentLiquidity
                                                        )
                                            )
                                    );
            amountOutDelta += int128(uint128(
                                                FullPrecisionMath.mulDiv(
                                                    amountOutLeftover,
                                                    0x1000000000000000000000000, 
                                                    currentLiquidity
                                                )
                                            )
                                    );
        }
    }

    function initialize(
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        IPoolsharkHedgePoolStructs.PoolState storage pool0,
        IPoolsharkHedgePoolStructs.PoolState storage pool1,
        int24 latestTick
    ) external {
        if (latestTick != TickMath.MIN_TICK && latestTick != TickMath.MAX_TICK) {
            tickNodes[latestTick] = IPoolsharkHedgePoolStructs.TickNode(
                TickMath.MIN_TICK, TickMath.MAX_TICK
            );
            tickNodes[TickMath.MIN_TICK] = IPoolsharkHedgePoolStructs.TickNode(
                TickMath.MIN_TICK, latestTick
            );
            tickNodes[TickMath.MAX_TICK] = IPoolsharkHedgePoolStructs.TickNode(
                latestTick, TickMath.MAX_TICK
            );
        } else if (latestTick == TickMath.MIN_TICK || latestTick == TickMath.MAX_TICK) {
            tickNodes[TickMath.MIN_TICK] = IPoolsharkHedgePoolStructs.TickNode(
                TickMath.MIN_TICK, TickMath.MAX_TICK
            );
            tickNodes[TickMath.MAX_TICK] = IPoolsharkHedgePoolStructs.TickNode(
                TickMath.MIN_TICK, TickMath.MAX_TICK
            );
        }
                //TODO: we might not need nearestTick; always with defined tickSpacing
        pool0.nearestTick = latestTick;
        pool1.nearestTick = TickMath.MIN_TICK;
        //TODO: the sqrtPrice cannot move more than 1 tickSpacing away
        pool0.price = TickMath.getSqrtRatioAtTick(latestTick);
        pool1.price = pool0.price;
    }

    function _updateAmountDeltas (
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks,
        int24 update,
        int128 amountInDelta,
        int128 amountOutDelta,
        uint128 currentLiquidity
    ) internal {
        // return since there is nothing to update
        if (currentLiquidity == 0) return;

        // handle amount in delta
        int128 amountInDeltaCarry = int64(ticks[update].amountInDeltaCarryPercent) * ticks[update].amountInDelta / 1e18;
        ticks[update].amountInDeltaCarryPercent = uint64(uint128((amountInDelta + amountInDeltaCarry) * 1e18 
                                                    / (ticks[update].amountInDelta + amountInDelta)));
        ticks[update].amountInDelta += amountInDelta;

        // handle amount out delta
        int128 amountOutDeltaCarry = int64(ticks[update].amountOutDeltaCarryPercent) * ticks[update].amountOutDelta / 1e18;
        ticks[update].amountOutDeltaCarryPercent = uint64(uint128((amountOutDelta + amountOutDeltaCarry) * 1e18 
                                                    / (ticks[update].amountOutDelta + amountOutDelta)));
        ticks[update].amountOutDelta += amountOutDelta;
    }

    //TODO: do both pool0 AND pool1
    function accumulateLastBlock(
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks0,
        mapping(int24 => IPoolsharkHedgePoolStructs.Tick) storage ticks1,
        mapping(int24 => IPoolsharkHedgePoolStructs.TickNode) storage tickNodes,
        IPoolsharkHedgePoolStructs.PoolState memory pool0,
        IPoolsharkHedgePoolStructs.PoolState memory pool1,
        int24 latestTick,
        int24 nextLatestTick,
        int24 tickSpacing
    ) external returns (
        IPoolsharkHedgePoolStructs.PoolState memory, 
        IPoolsharkHedgePoolStructs.PoolState memory,
        int24
    ) {
        console.log("-- START ACCUMULATE LAST BLOCK --");

        // only accumulate if latestTick needs to move
        if ((nextLatestTick / tickSpacing) == (latestTick / tickSpacing)) {
            console.log("-- EARLY END ACCUMULATE LAST BLOCK --");
            return (pool0, pool1, latestTick);
        }

        console.log('zero tick previous:');
        console.logInt(tickNodes[0].previousTick);

        //TODO: to save stack space can also use pool0/1 everywhere
        IPoolsharkHedgePoolStructs.AccumulateCache memory cache = IPoolsharkHedgePoolStructs.AccumulateCache({
            nextTickToCross0:  tickNodes[pool0.nearestTick].nextTick,
            nextTickToCross1:  pool1.nearestTick,
            nextTickToAccum0:  pool0.nearestTick,
            nextTickToAccum1:  tickNodes[pool1.nearestTick].nextTick,
            stopTick0:  (nextLatestTick > latestTick) ? latestTick : nextLatestTick,
            stopTick1:  (nextLatestTick > latestTick) ? nextLatestTick : latestTick,
            price0:     pool0.price,
            price1:     pool1.price,
            liquidity0: pool0.liquidity,
            liquidity1: pool1.liquidity,
            amountInDelta0:  0,
            amountInDelta1:  0,
            amountOutDelta0: 0,
            amountOutDelta1: 0
        });

        //TODO: handle ticks not crossed into as a result of big TWAP move
        console.log('check cache');
        console.logInt(cache.nextTickToCross1);
        console.logInt(cache.nextTickToAccum1);
        console.logInt(tickNodes[cache.nextTickToCross1].nextTick);
        // handle partial tick fill
        if(pool0.price != TickMath.getSqrtRatioAtTick(cache.nextTickToAccum0)) {
            if(cache.liquidity0 > 0) {
                console.log('rolling over pool0');
                (
                    cache.amountInDelta0,
                    cache.amountOutDelta0
                ) = _rollover(
                    cache.nextTickToCross0,
                    cache.price0,
                    cache.liquidity0,
                    true
                );
            }
            // update liquidity and ticks
            //TODO: do we return here is latestTick has not moved??
            //TODO: wipe tick data when tick is deleted
        }
        if(pool1.price != TickMath.getSqrtRatioAtTick(cache.nextTickToAccum1)) {
            if(cache.liquidity1 > 0) {
                console.log('rolling over pool1');
                (
                    cache.amountInDelta1,
                    cache.amountOutDelta1
                ) = _rollover(
                    cache.nextTickToCross1,
                    cache.price1,
                    cache.liquidity1,
                    false
                );
            }
            // update liquidity and ticks
            //TODO: do we return here is latestTick has not moved??
        }
        while (true) {
            //rollover if past latestTick and TWAP moves down
            if (cache.stopTick0 == nextLatestTick 
                && cache.nextTickToAccum0 < latestTick
            ) {
                if (cache.liquidity0 > 0) {
                    (
                        cache.amountInDelta0,
                        cache.amountOutDelta0
                    ) = _rollover(
                        cache.nextTickToCross0,
                        cache.price0,
                        cache.liquidity0,
                        false
                    );
                }
                ticks1[cache.nextTickToAccum0].feeGrowthGlobalIn = pool1.feeGrowthGlobalIn;
            }
            console.log('pool0 accumulate');
            console.logInt(cache.nextTickToCross0);
            console.logInt(cache.nextTickToAccum0);
            (
                cache.amountInDelta0,
                cache.amountOutDelta0
            ) = _accumulate(
                ticks0,
                cache.nextTickToCross0,
                cache.nextTickToAccum0,
                cache.liquidity0,
                pool0.feeGrowthGlobalIn,
                cache.amountInDelta0, /// @dev - amount deltas will be 0 initially
                cache.amountOutDelta0,
                true //TODO: only do this for below latestTick to keep liquidity between old and new latestTick
            );
            if(cache.nextTickToAccum0 >= latestTick) {
                ticks0[cache.nextTickToCross0].liquidityDelta = 0;
                ticks0[cache.nextTickToCross0].liquidityDeltaMinus = 0;
            }
            if (cache.nextTickToAccum0 > cache.stopTick0) {
                (
                    cache.liquidity0, 
                    cache.nextTickToCross0,
                    cache.nextTickToAccum0
                ) = _cross(
                    ticks0,
                    tickNodes,
                    cache.nextTickToCross0,
                    cache.nextTickToAccum0,
                    cache.liquidity0,
                    true
                ); 
            } else {
                if (nextLatestTick > latestTick)
                    ticks0[latestTick].liquidityDelta += int128(uint128(cache.liquidity0) 
                                                        - ticks0[latestTick].liquidityDeltaMinus);
                console.log('handle liquidity delta');
                break;
            }
        }
        // place leftover amount deltas at stopTick
        _updateAmountDeltas(
                ticks0,
                cache.stopTick0,
                cache.amountInDelta0,
                cache.amountOutDelta0,
                cache.liquidity0
        );
        while (true) {
            //rollover if past latestTick and TWAP moves up
            if (cache.stopTick1 == nextLatestTick 
                && cache.nextTickToAccum1 > latestTick
            ) {
                if (cache.liquidity1 > 0){
                    (
                        cache.amountInDelta1,
                        cache.amountOutDelta1
                    ) = _rollover(
                        cache.nextTickToCross1,
                        cache.price1, //TODO: update price on each iteration
                        cache.liquidity1,
                        false
                    );
                }
                ticks0[cache.nextTickToAccum1].feeGrowthGlobalIn = pool0.feeGrowthGlobalIn;
            }
            //accumulate to next tick
            console.log('pool1 accumulate');
            console.logInt(cache.nextTickToCross1);
            console.logInt(cache.nextTickToAccum1);
            (
                cache.amountInDelta1,
                cache.amountOutDelta1
            ) = _accumulate(
                ticks1,
                cache.nextTickToCross1,
                cache.nextTickToAccum1,
                cache.liquidity1,
                pool1.feeGrowthGlobalIn,
                cache.amountInDelta1, /// @dev - amount deltas will be 1 initially
                cache.amountOutDelta1,
                true
            );
            if(cache.nextTickToAccum0 <= latestTick) {
                ticks0[cache.nextTickToCross0].liquidityDelta = 0;
                ticks0[cache.nextTickToCross0].liquidityDeltaMinus = 0;
            }
            //cross otherwise break
            console.logInt(cache.nextTickToAccum1);
            console.logInt(cache.stopTick1);
            if (cache.nextTickToAccum1 < cache.stopTick1) {
                (
                    cache.liquidity1, 
                    cache.nextTickToCross1,
                    cache.nextTickToAccum1
                ) = _cross(
                    ticks1,
                    tickNodes,
                    cache.nextTickToCross1,
                    cache.nextTickToAccum1,
                    cache.liquidity1,
                    false
                );
            } else {
                if (nextLatestTick < latestTick)
                    ticks1[latestTick].liquidityDelta += int128(uint128(cache.liquidity1) 
                                                        - ticks1[latestTick].liquidityDeltaMinus);
                break;
            }
        }
        // place leftover amount deltas at stopTick
        _updateAmountDeltas(
                ticks1,
                cache.stopTick1,
                cache.amountInDelta1,
                cache.amountOutDelta1,
                cache.liquidity1
        );
        //TODO: remove liquidity from all ticks crossed
        //TODO: handle burn when price is between ticks
        //if TWAP moved up
        if (nextLatestTick > latestTick) {
            // if this is true we need to insert new latestTick
            if (cache.nextTickToAccum1 != nextLatestTick) {
                // if this is true we need to delete the old tick
                //TODO: don't delete old latestTick for now
                tickNodes[nextLatestTick] = IPoolsharkHedgePoolStructs.TickNode(
                        cache.nextTickToCross1,
                        cache.nextTickToAccum1
                );
                tickNodes[cache.nextTickToAccum1].previousTick = nextLatestTick;
                tickNodes[cache.nextTickToCross1].nextTick     = nextLatestTick;
                //TODO: replace nearestTick with priceLimit for swapping...maybe
            }
            pool0.liquidity = 0;
            pool1.liquidity = cache.liquidity1;
        // handle TWAP moving down
        } else if (nextLatestTick < latestTick) {
            //TODO: if tick is deleted rollover amounts if necessary
            //TODO: do we recalculate deltas if liquidity is removed?
            if (cache.nextTickToAccum0 != nextLatestTick) {
                // if this is true we need to delete the old tick
                //TODO: don't delete old latestTick for now
                tickNodes[nextLatestTick] = IPoolsharkHedgePoolStructs.TickNode(
                        cache.nextTickToAccum0,
                        cache.nextTickToCross0
                );
                tickNodes[cache.nextTickToCross0].previousTick = nextLatestTick;
                tickNodes[cache.nextTickToAccum0].nextTick     = nextLatestTick;
                //TODO: replace nearestTick with priceLimit for swapping...maybe
            }
            pool0.liquidity = cache.liquidity0;
            pool1.liquidity = 0;
        }
        //TODO: delete old latestTick if possible

        // console.log('cross last tick touched');
        // console.logInt(cache.tick);
        // console.logInt(tickNodes[cache.tick].nextTick);
        

        //TODO: handle pool0 AND pool1
        latestTick = nextLatestTick;
        pool0.nearestTick = tickNodes[nextLatestTick].nextTick;
        pool1.nearestTick = tickNodes[nextLatestTick].previousTick;
        pool0.price = TickMath.getSqrtRatioAtTick(nextLatestTick);
        pool1.price = pool0.price;

        // console.log('max tick previous:');
        // console.logInt(tickNodes[887272].previousTick);
        // console.logInt(tickNodes[887272].nextTick);
        console.log("-- END ACCUMULATE LAST BLOCK --");
        return (pool0, pool1, latestTick);
        //TODO: update liquidity
        // if latestTick didn't change we don't update liquidity
        // if it did we set to current liquidity


        // insert new latest tick
        // console.log('updated tick after insert');
        // console.logInt(ticks[cache.nextTick].previousTick);
        // console.logInt(latestTick);
        // console.logInt(ticks[latestTick].nextTick);
        // console.log('fee growth check:');
        // console.log(ticks[0].feeGrowthGlobalLast);
        // console.log(ticks[20].feeGrowthGlobalLast);
        // console.log(ticks[30].feeGrowthGlobalLast);
        // console.log(ticks[50].feeGrowthGlobalLast);

    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

//TODO: deploy library code once and reference from factory
// have interfaces for library contracts
import "./interfaces/IPoolsharkHedgePool.sol";
import "./interfaces/IConcentratedPool.sol";
import "./base/PoolsharkHedgePoolStorage.sol";
import "./base/PoolsharkHedgePoolEvents.sol";
import "./utils/SafeTransfers.sol";
import "./utils/PoolsharkErrors.sol";
import "hardhat/console.sol";

/// @notice Poolshark Directional Liquidity pool implementation.
/// @dev SafeTransfers contains PoolsharkHedgePoolErrors
contract PoolsharkHedgePool is
    IPoolsharkHedgePool,
    PoolsharkHedgePoolStorage,
    PoolsharkHedgePoolEvents,
    PoolsharkTicksErrors,
    PoolsharkMiscErrors,
    PoolsharkPositionErrors,
    SafeTransfers
{
    int24 internal immutable tickSpacing;
    uint24 internal immutable swapFee; /// @dev Fee measured in basis points (.e.g 1000 = 0.1%).
    uint128 internal immutable MAX_TICK_LIQUIDITY;

    address internal immutable factory;
    address internal immutable token0;
    address internal immutable token1;

    IConcentratedPool internal immutable inputPool;

    modifier lock() {
        if (unlocked == 2) revert Locked();
        unlocked = 2;
        _;
        unlocked = 1;
    }

    constructor(
        address _inputPool,
        address _libraries,
        uint24  _swapFee, 
        int24  _tickSpacing
    ) {
        // check for invalid params
        if (_swapFee > MAX_FEE) revert InvalidSwapFee();

        // set state variables from params
        factory     = msg.sender;
        inputPool   = IConcentratedPool(_inputPool);
        utils       = IPoolsharkUtils(_libraries);
        token0      = IConcentratedPool(inputPool).token0();
        token1      = IConcentratedPool(inputPool).token1();
        swapFee     = _swapFee;
        //TODO: should be 1% for .1% spacing on inputPool
        tickSpacing = _tickSpacing;

        // extrapolate other state variables
        feeTo = IPoolsharkHedgePoolFactory(factory).owner();
        MAX_TICK_LIQUIDITY = Ticks.getMaxLiquidity(_tickSpacing);

        // set default initial values
        //TODO: insertSingle or pass MAX_TICK as upper
        // @dev increase pool observations if not sufficient
        latestTick = utils.initializePoolObservations(IConcentratedPool(inputPool));
        if (latestTick >= TickMath.MIN_TICK) {
            _initialize();
            unlocked = 1;
            lastBlockNumber = block.number;
        }
    }

    //TODO: test this check
    function _ensureInitialized() internal {
        if (latestTick < TickMath.MIN_TICK) {
            if(utils.isPoolObservationsEnough(IConcentratedPool(inputPool))) {
                _initialize();
                unlocked = 1;
                lastBlockNumber = block.number;
            }
            revert WaitUntilEnoughObservations(); 
        }
    }

    function _initialize() internal {
        int24 initLatestTick = utils.initializePoolObservations(IConcentratedPool(inputPool));
        latestTick = initLatestTick / int24(tickSpacing) * int24(tickSpacing);
        Ticks.initialize(
            tickNodes,
            pool0,
            pool1,
            initLatestTick
        );
    }

    function mint(
        int24 lowerOld,
        int24 lower,
        int24 upperOld,
        int24 upper,
        uint128 amountDesired,
        bool zeroForOne,
        bool native
    ) external {
        internalMint(
            MintParams(
                lowerOld,
                lower,
                upperOld,
                upper,
                amountDesired,
                zeroForOne,
                native
            )
        );
    }

    /// @dev Mints LP tokens - should be called via the CL pool manager contract.
    function internalMint(MintParams memory mintParams) internal returns (uint256 liquidityMinted) {
        /// @dev - don't allow mints until we have enough observations from inputPool
        _ensureInitialized();
        //TODO: move tick update check here
        if(block.number != lastBlockNumber) {
            lastBlockNumber = block.number;
            //can save a couple 100 gas if we skip this when no update
            (pool0, pool1, latestTick) = Ticks.accumulateLastBlock(
                ticks0,
                ticks1,
                tickNodes,
                pool0,
                pool1,
                latestTick,
                utils.calculateAverageTick(inputPool),
                tickSpacing
            );
        }
        //TODO: handle upperOld and lowerOld being invalid
        uint256 priceLower = uint256(TickMath.getSqrtRatioAtTick(mintParams.lower));
        uint256 priceUpper = uint256(TickMath.getSqrtRatioAtTick(mintParams.upper));
        //TODO: maybe move to other function
        // handle partial mints
        if (mintParams.zeroForOne && mintParams.upper >= latestTick) {
            mintParams.upper = latestTick - int24(tickSpacing);
            mintParams.upperOld = latestTick;
            uint256 priceNewUpper = TickMath.getSqrtRatioAtTick(mintParams.upper);
            mintParams.amountDesired -= uint128(DyDxMath.getDx(liquidityMinted, priceNewUpper, priceUpper, false));
            priceUpper = priceNewUpper;
        }
        if (!mintParams.zeroForOne && mintParams.lower <= latestTick) {
            mintParams.lower = latestTick + int24(tickSpacing);
            mintParams.lowerOld = latestTick;
            uint256 priceNewLower = TickMath.getSqrtRatioAtTick(mintParams.lower);
            mintParams.amountDesired -= uint128(DyDxMath.getDy(liquidityMinted, priceLower, priceNewLower, false));
            priceLower = priceNewLower;
        }

        _validatePosition(mintParams);

        liquidityMinted = DyDxMath.getLiquidityForAmounts(
            priceLower,
            priceUpper,
            mintParams.zeroForOne ? priceLower : priceUpper,
            mintParams.zeroForOne ? 0 : uint256(mintParams.amountDesired),
            mintParams.zeroForOne ? uint256(mintParams.amountDesired) : 0
        );

        // Ensure no overflow happens when we cast from uint256 to int128.
        if (liquidityMinted > uint128(type(int128).max)) revert LiquidityOverflow();

        if(mintParams.zeroForOne){
            _transferIn(token0, mintParams.amountDesired);
        } else {
            _transferIn(token1, mintParams.amountDesired);
        }

        unchecked {
            _updatePosition(
                msg.sender,
                mintParams.lower,
                mintParams.upper,
                mintParams.zeroForOne ? mintParams.upper : mintParams.lower,
                mintParams.zeroForOne,
                int128(uint128(liquidityMinted))
            );
            /// @dev - pool current liquidity should never be increased on mint
        }

        Ticks.insert(
            mintParams.zeroForOne ? ticks0 : ticks1,
            tickNodes,
            latestTick,
            mintParams.zeroForOne ? pool0.feeGrowthGlobalIn : pool1.feeGrowthGlobalIn,
            mintParams.lowerOld,
            mintParams.lower,
            mintParams.upperOld,
            mintParams.upper,
            uint128(liquidityMinted),
            mintParams.zeroForOne
        );

        (uint128 amountInActual, uint128 amountOutActual) = DyDxMath.getAmountsForLiquidity(
            priceLower,
            priceUpper,
            mintParams.zeroForOne ? priceLower : priceUpper,
            liquidityMinted,
            true
        );

        emit Mint(msg.sender, amountInActual, amountOutActual);
    }

    function burn(
        int24 lower,
        int24 upper,
        int24 claim,
        bool zeroForOne,
        uint128 amount
    )
        public
        lock
    {

        /// @dev - not necessary since position will be empty
        // _ensureInitialized();
        // console.log('zero previous tick:');
        // console.logInt(ticks[0].previousTick);

        if(block.number != lastBlockNumber) {
            // console.log("accumulating last block");
            lastBlockNumber = block.number;
            (pool0, pool1, latestTick) = Ticks.accumulateLastBlock(
                ticks0,
                ticks1,
                tickNodes,
                pool0,
                pool1,
                latestTick,
                utils.calculateAverageTick(inputPool),
                tickSpacing
            );
        }
        // console.log('zero previous tick:');
        // console.logInt(ticks[0].previousTick);

        //TODO: burning liquidity should take liquidity out past the current auction
        
        // Ensure no overflow happens when we cast from uint128 to int128.
        if (amount > uint128(type(int128).max)) revert LiquidityOverflow();

        // _updatePosition(msg.sender, lower, upper, -int128(amount));
        _updatePosition(
            msg.sender,
            lower,
            upper,
            claim,
            zeroForOne,
            -int128(amount)
        );

        uint256 amountIn;
        uint256 amountOut;

        //TODO: get token amounts from _updatePosition return values
        emit Burn(msg.sender, amountIn, amountOut);
    }

    // function collect(int24 lower, int24 upper) public lock returns (uint256 amountInfees, uint256 amountOutfees) {
    //     (amountInfees, amountOutfees) = _updatePosition(
    //                                      msg.sender, 
    //                                      lower, 
    //                                      upper, 
    //                                      0
    //                                  );
    //     // address owner,
    //     // int24 lower,
    //     // int24 upper,
    //     // bool zeroForOne,
    //     // int128 amount,
    //     // bool claiming,
    //     // int24 claim

    //     _transferBothTokens(msg.sender, amountInfees, amountOutfees);

    //     emit Collect(msg.sender, amountInfees, amountOutfees);
    // }

    /// @dev Swaps one token for another. The router must prefund this contract and ensure there isn't too much slippage.
    function swap(
        address recipient,
        bool zeroForOne,
        uint256 amountIn,
        uint160 priceLimit
        // bytes calldata data
    ) external override lock returns (uint256 amountOut) {
        //TODO: is this needed?
        if (latestTick < TickMath.MIN_TICK) revert WaitUntilEnoughObservations();
        PoolState memory pool = zeroForOne ? pool1 : pool0;
        TickMath.validatePrice(priceLimit);

        _transferIn(zeroForOne ? token0 : token1, amountIn);

        if(block.number != lastBlockNumber) {
            lastBlockNumber = block.number;
            // console.log('min latest max');
            // console.logInt(tickNodes[-887272].nextTick);
            // console.logInt(tickNodes[-887272].previousTick);
            (pool0, pool1, latestTick) = Ticks.accumulateLastBlock(
                ticks0,
                ticks1,
                tickNodes,
                pool0,
                pool1,
                latestTick,
                utils.calculateAverageTick(inputPool),
                tickSpacing
            );
        }

        SwapCache memory cache = SwapCache({
            price: pool.price,
            liquidity: pool.liquidity,
            feeAmount: utils.mulDivRoundingUp(amountIn, swapFee, 1e6),
            // currentTick: nearestTick, //TODO: price goes to max latestTick + tickSpacing
            input: amountIn - utils.mulDivRoundingUp(amountIn, swapFee, 1e6)
        });

        // console.log('starting tick:');
        // console.logInt(latestTick);
        // console.log("liquidity:", cache.liquidity);

        /// @dev - liquidity range is limited to one tick within latestTick - should we add tick crossing?
        /// @dev not sure whether to handle greater than tickSpacing range
        /// @dev everything will always be cleared out except for the closest tick to latestTick
        uint256 nextTickPrice = zeroForOne ? uint256(TickMath.getSqrtRatioAtTick(latestTick - int24(tickSpacing))) :
                                             uint256(TickMath.getSqrtRatioAtTick(latestTick + int24(tickSpacing))) ;
        uint256 nextPrice = nextTickPrice;
        // console.log("next price:", nextPrice);

        if (zeroForOne) {
            // Trading token 0 (x) for token 1 (y).
            // price  is decreasing.
            if (nextPrice < priceLimit) { nextPrice = priceLimit; }
            uint256 maxDx = DyDxMath.getDx(cache.liquidity, nextPrice, cache.price, false);
            // console.log("max dx:", maxDx);
            if (cache.input <= maxDx) {
                // We can swap within the current range.
                uint256 liquidityPadded = cache.liquidity << 96;
                // calculate price after swap
                uint256 newPrice = uint256(
                    utils.mulDivRoundingUp(liquidityPadded, cache.price, liquidityPadded + cache.price * cache.input)
                );
                if (!(nextPrice <= newPrice && newPrice < cache.price)) {
                    newPrice = uint160(utils.divRoundingUp(liquidityPadded, liquidityPadded / cache.price + cache.input));
                }
                // Based on the sqrtPricedifference calculate the output of th swap: Δy = Δ√P · L.
                amountOut = DyDxMath.getDy(cache.liquidity, newPrice, cache.price, false);
                // console.log("dtokenOut:", output);
                cache.price= newPrice;
                cache.input = 0;
            } else {
                // Execute swap step and cross the tick.
                // console.log('nextsqrtprice:', nextPrice);
                // console.log('currentprice:', cache.price);
                amountOut = DyDxMath.getDy(cache.liquidity, nextPrice, cache.price, false);
                // console.log("dtokenOut:", output);
                cache.price= nextPrice;
                cache.input -= maxDx;
            }
        } else {
            // Price is increasing.
            if (nextPrice > priceLimit) { nextPrice = priceLimit; }
            uint256 maxDy = DyDxMath.getDy(cache.liquidity, cache.price, nextTickPrice, false);
            // console.log("max dy:", maxDy);
            if (cache.input <= maxDy) {
                // We can swap within the current range.
                // Calculate new price after swap: ΔP = Δy/L.
                uint256 newPrice = cache.price +
                    FullPrecisionMath.mulDiv(cache.input, 0x1000000000000000000000000, cache.liquidity);
                // Calculate output of swap
                amountOut = DyDxMath.getDx(cache.liquidity, cache.price, newPrice, false);
                cache.price = newPrice;
                cache.input = 0;
            } else {
                // Swap & cross the tick.
                amountOut = DyDxMath.getDx(cache.liquidity, cache.price, nextTickPrice, false);
                cache.price = nextTickPrice;
                cache.input -= maxDy;
            }
        }

        // It increases each swap step.
        // amountOut += output;

        zeroForOne ? pool1.price = uint160(cache.price) : 
                     pool0.price = uint160(cache.price) ;

        if (zeroForOne) {
            if(cache.input > 0) {
                uint128 feeReturn = uint128(
                                            cache.input * 1e18 
                                            / (amountIn - cache.feeAmount) 
                                            * cache.feeAmount / 1e18
                                           );
                cache.feeAmount -= feeReturn;
                pool.feeGrowthGlobalIn += uint232(cache.feeAmount); 
                _transferOut(recipient, token0, cache.input + feeReturn);
            }
            _transferOut(recipient, token1, amountOut);
            emit Swap(recipient, token0, token1, amountIn, amountOut);
        } else {
            if(cache.input > 0) {
                uint128 feeReturn = uint128(
                                            cache.input * 1e18 
                                            / (amountIn - cache.feeAmount) 
                                            * cache.feeAmount / 1e18
                                           );
                cache.feeAmount -= feeReturn;
                pool.feeGrowthGlobalIn += uint232(cache.feeAmount); 
                _transferOut(recipient, token1, cache.input + feeReturn);
            }
            _transferOut(recipient, token1, amountOut);
            emit Swap(recipient, token1, token0, amountIn, amountOut);
        }
    }

    function _validatePosition(MintParams memory mintParams) internal view {
        if (mintParams.lower % int24(tickSpacing) != 0) revert InvalidTick();
        if (mintParams.upper % int24(tickSpacing) != 0) revert InvalidTick();
        if (mintParams.amountDesired == 0) revert InvalidPosition();
        if (mintParams.lower >= mintParams.upper) revert InvalidPosition();
        if (mintParams.zeroForOne) {
            if (mintParams.lower >= latestTick) revert InvalidPosition();
        } else {
            // console.log('upper param');
            // console.logInt(mintParams.upper);
            // console.logInt(latestTick);
            if (mintParams.upper <= latestTick) revert InvalidPosition();
        }
    }

    function getAmountIn(
        bool zeroForOne,
        uint256 amountIn,
        uint160 priceLimit
    ) internal view returns (uint256 inAmount, uint256 outAmount) {
        // TODO: make override
        SwapCache memory cache = SwapCache({
            price: zeroForOne ? pool1.price : pool0.price,
            liquidity: zeroForOne ? pool1.liquidity : pool0.liquidity,
            feeAmount: utils.mulDivRoundingUp(amountIn, swapFee, 1e6),
            // currentTick: nearestTick, //TODO: price goes to max latestTick + tickSpacing
            input: amountIn - utils.mulDivRoundingUp(amountIn, swapFee, 1e6)
        });

        // console.log('starting tick:');
        // console.logInt(latestTick);
        // console.log("liquidity:", cache.liquidity);
        /// @dev - liquidity range is limited to one tick within latestTick - should we add tick crossing?
        /// @dev not sure whether to handle greater than tickSpacing range
        /// @dev everything will always be cleared out except for the closest tick to latestTick
        uint256 nextTickPrice = zeroForOne ? uint256(TickMath.getSqrtRatioAtTick(latestTick - int24(tickSpacing))) :
                                             uint256(TickMath.getSqrtRatioAtTick(latestTick + int24(tickSpacing))) ;
        uint256 nextPrice = nextTickPrice;
        // console.log("next price:", nextPrice);

        if (zeroForOne) {
            // Trading token 0 (x) for token 1 (y).
            // price  is decreasing.
            if (nextPrice < priceLimit) { nextPrice = priceLimit; }
            uint256 maxDx = DyDxMath.getDx(cache.liquidity, nextPrice, cache.price, false);
            // console.log("max dx:", maxDx);
            if (cache.input <= maxDx) {
                // We can swap within the current range.
                uint256 liquidityPadded = cache.liquidity << 96;
                // calculate price after swap
                uint256 newPrice = uint256(
                    utils.mulDivRoundingUp(liquidityPadded, cache.price, liquidityPadded + cache.price * cache.input)
                );
                if (!(nextPrice <= newPrice && newPrice < cache.price)) {
                    newPrice = uint160(utils.divRoundingUp(liquidityPadded, liquidityPadded / cache.price + cache.input));
                }
                // Based on the sqrtPricedifference calculate the output of th swap: Δy = Δ√P · L.
                outAmount = DyDxMath.getDy(cache.liquidity, newPrice, cache.price, false);
                inAmount  = amountIn;
                // console.log("dtokenOut:", output);
            } else {
                // Execute swap step and cross the tick.
                // console.log('nextsqrtprice:', nextPrice);
                // console.log('currentprice:', cache.price);
                outAmount = DyDxMath.getDy(cache.liquidity, nextPrice, cache.price, false);
                inAmount = maxDx;
            }
        } else {
            // Price is increasing.
            if (nextPrice > priceLimit) { nextPrice = priceLimit; }
            uint256 maxDy = DyDxMath.getDy(cache.liquidity, cache.price, nextTickPrice, false);
            // console.log("max dy:", maxDy);
            if (cache.input <= maxDy) {
                // We can swap within the current range.
                // Calculate new price after swap: ΔP = Δy/L.
                uint256 newPrice = cache.price +
                    FullPrecisionMath.mulDiv(cache.input, 0x1000000000000000000000000, cache.liquidity);
                // Calculate output of swap
                outAmount = DyDxMath.getDx(cache.liquidity, cache.price, newPrice, false);
                inAmount = amountIn;
            } else {
                // Swap & cross the tick.
                outAmount = DyDxMath.getDx(cache.liquidity, cache.price, nextTickPrice, false);
                inAmount = maxDy;
            }
        }
        if (zeroForOne) {
            if(cache.input > 0) {
                uint128 feeReturn = uint128(
                                            cache.input * 1e18 
                                            / (amountIn - cache.feeAmount) 
                                            * cache.feeAmount / 1e18
                                           );
                cache.input += feeReturn;
            }
        } else {
            if(cache.input > 0) {
                uint128 feeReturn = uint128(
                                            cache.input * 1e18 
                                            / (amountIn - cache.feeAmount) 
                                            * cache.feeAmount / 1e18
                                           );
                cache.input += feeReturn;
            }
        }
        inAmount -= cache.input;

        return (inAmount, outAmount);
    }


    function _transferBothTokens(
        address to,
        uint256 shares0,
        uint256 shares1
    ) internal {
        _transferOut(to, token0, shares0);
        _transferOut(to, token1, shares1);
    }

    //TODO: zap into LP position
    //TODO: use bitmaps to naiively search for the tick closest to the new TWAP
    //TODO: assume everything will get filled for now
    //TODO: remove old latest tick if necessary
    //TODO: after accumulation, all liquidity below old latest tick is removed
    //TODO: don't update latestTick until TWAP has moved +/- tickSpacing
    //TODO: latestTick needs to be a multiple of tickSpacing
    

    //TODO: factor in swapFee
    //TODO: consider partial fills and how that impacts claims
    //TODO: consider current price...we might have to skip claims/burns from current tick
    function _updatePosition(
        address owner,
        int24 lower,
        int24 upper,
        int24 claim,
        bool zeroForOne,
        int128 amount
    ) internal {
        mapping (int24 => Tick) storage ticks = zeroForOne ? ticks0 : ticks1;
        UpdatePositionCache memory cache = UpdatePositionCache({
            position: zeroForOne ? positions0[owner][lower][upper] : positions1[owner][lower][upper],
            feeGrowthGlobalIn: zeroForOne ? pool0.feeGrowthGlobalIn : pool1.feeGrowthGlobalIn,
            priceLower: TickMath.getSqrtRatioAtTick(lower),
            priceUpper: TickMath.getSqrtRatioAtTick(upper),
            claimPrice: TickMath.getSqrtRatioAtTick(claim),
            removeLower: true,
            removeUpper: true,
            upperRemove: 0,
            lowerRemove: 0,
            amountInDelta: 0,
            amountOutDelta: 0
        });

        // validate removal amount is less than position liquidity
        if (amount < 0 && uint128(-amount) > cache.position.liquidity) revert NotEnoughPositionLiquidity();
        else if (amount < 0) cache.position.liquidity -= uint128(-amount);

        if (cache.position.claimPriceLast == 0) {
            cache.position.feeGrowthGlobalIn = cache.feeGrowthGlobalIn;
            cache.position.claimPriceLast = zeroForOne ? uint160(cache.priceUpper) : uint160(cache.priceLower);
        }
        if (cache.position.claimPriceLast > cache.claimPrice) revert InvalidClaimTick();

        // handle claims
        //TODO: figure out how to calculate current auction and withdraw liquidity from that
        if(ticks[claim].feeGrowthGlobalIn > cache.position.feeGrowthGlobalIn) {
            // skip claim if lower == claim
            if(claim != (zeroForOne ? upper : lower)){
                // verify user passed highest tick with growth
                if (claim != (zeroForOne ? lower : upper)){

                    //TODO: if latestTick was just updated we can skip
                    //TODO: get dx from latestTick to current price for pool1
                    //TODO: get dy from currentPrice to claim tick for pool1
                    //TODO: do opposite for pool0
                    //TODO: add this to transferred amount if removing liquidity
                    {
                        // next tick should not have any fee growth
                        int24 claimNextTick = zeroForOne ? tickNodes[claim].previousTick : tickNodes[claim].nextTick;
                        if (ticks[claimNextTick].feeGrowthGlobalIn > cache.position.feeGrowthGlobalIn) revert WrongTickClaimedAt();
                    }
                    Ticks.remove(
                        zeroForOne ? ticks0 : ticks1,
                        tickNodes,
                        zeroForOne ? lower : claim,
                        zeroForOne ? claim : upper,
                        uint128(-amount),
                        zeroForOne,
                        true,
                        true
                    );

                    //TODO: does uint -> int check for overflow?
                    cache.amountInDelta  = ticks[claim].amountInDelta;
                    cache.amountOutDelta = ticks[claim].amountOutDelta;
                    //TODO: move into Ticks lib ~ this code is 1.125 kb
                    // handle partial fill between lastestTick and current pool price
                    if (zeroForOne ? 
                            (latestTick < claim && latestTick >= lower) //TODO: not sure if second condition is possible
                          : (latestTick > claim && latestTick <= upper) 
                       ) {
                        uint160 latestTickPrice = TickMath.getSqrtRatioAtTick(latestTick);
                        //TODO: stop accumulating the tick before latestTick when moving TWAP
                        cache.amountInDelta += int128(int256(zeroForOne ? 
                                DyDxMath.getDy(
                                    1, // multiplied by liquidity later
                                    latestTickPrice,
                                    pool0.price,
                                    false
                                )
                                : DyDxMath.getDx(
                                    1, 
                                    pool1.price,
                                    latestTickPrice, 
                                    false
                                )
                        ));
                        //TODO: implement stopPrice for pool0/1
                        cache.amountOutDelta += int128(int256(zeroForOne ? 
                            DyDxMath.getDx(
                                1, // multiplied by liquidity later
                                pool0.price,
                                cache.claimPrice,
                                false
                            )
                            : DyDxMath.getDy(
                                1, 
                                cache.claimPrice,
                                pool1.price, 
                                false
                            )
                        ));
                        //TODO: do we need to handle minus deltas correctly depending on direction
                        // modify current liquidity
                        if (amount < 0) {
                            zeroForOne ? pool0.liquidity -= uint128(-amount) 
                                       : pool1.liquidity -= uint128(-amount);
                        }
                    }
                } else {
                    {
                        // next tick having fee growth means liquidity was cleared
                        int24 claimNextTick = zeroForOne ? tickNodes[claim].previousTick : tickNodes[claim].nextTick;
                        if (ticks[claimNextTick].feeGrowthGlobalIn > cache.position.feeGrowthGlobalIn) zeroForOne ? cache.removeLower = false 
                                                                                                                  : cache.removeUpper = false;
                    }
                    /// @dev - no liquidity removed from last tick
                    //ignore carryover for last tick of position
                    cache.amountInDelta  = ticks[claim].amountInDelta - int64(ticks[claim].amountInDeltaCarryPercent) 
                                                                            * ticks[claim].amountInDelta / 1e18;
                    cache.amountOutDelta = ticks[claim].amountOutDelta - int64(ticks[claim].amountOutDeltaCarryPercent)
                                                                            * ticks[claim].amountInDelta / 1e18;
                }
                cache.position.claimPriceLast = cache.claimPrice;
                {
                    // calculate what is claimable
                    //TODO: should this be inside Ticks library?
                    uint256 amountInClaimable  = zeroForOne ? 
                                                    DyDxMath.getDy(
                                                        cache.position.liquidity,
                                                        cache.claimPrice,
                                                        cache.position.claimPriceLast,
                                                        false
                                                    )
                                                  : DyDxMath.getDx(
                                                        cache.position.liquidity, 
                                                        cache.position.claimPriceLast,
                                                        cache.claimPrice, 
                                                        false
                                                    );
                    if (cache.amountInDelta > 0) {
                        amountInClaimable += FullPrecisionMath.mulDiv(
                                                                        uint128(cache.amountInDelta),
                                                                        cache.position.liquidity, 
                                                                        Ticks.Q128
                                                                    );
                    } else if (cache.amountInDelta < 0) {
                        //TODO: handle underflow here
                        amountInClaimable -= FullPrecisionMath.mulDiv(
                                                                        uint128(-cache.amountInDelta),
                                                                        cache.position.liquidity, 
                                                                        Ticks.Q128
                                                                    );
                    }
                    //TODO: add to position
                    if (amountInClaimable > 0) {
                        amountInClaimable *= (1e6 + swapFee) / 1e6; // factor in swap fees
                        _transferOut(owner, zeroForOne ? token1 : token0, amountInClaimable);
                    }
                }
                {
                    if (cache.amountOutDelta > 0) {
                        uint256 amountOutClaimable = FullPrecisionMath.mulDiv(
                                                                        uint128(cache.amountOutDelta),
                                                                        cache.position.liquidity, 
                                                                        Ticks.Q128
                                                                    );
                        //TODO: change to one transfer
                        _transferOut(owner, zeroForOne ? token0 : token1, amountOutClaimable);
                    }
                    //TODO: add to position
                }
            }
        // user can claim with no updates from lower
        } else if ((zeroForOne ? claim == upper : claim == lower) && amount < 0) {
            //TODO: if claim is start of position, ignore deltas
            {
                // next tick should not have any fee growth
                //TODO: this should be impossible if lower fee growth is equal to position
                int24 claimNextTick = zeroForOne ? tickNodes[claim].previousTick : tickNodes[claim].nextTick;
                if (ticks[claimNextTick].feeGrowthGlobalIn > cache.position.feeGrowthGlobalIn) revert WrongTickClaimedAt();
            }
            if (amount < 0){
                Ticks.remove(
                    zeroForOne ? ticks0 : ticks1,
                    tickNodes,
                    lower,
                    upper,
                    uint128(-amount),
                    zeroForOne,
                    true,
                    true
                );
                uint256 amountOutRemoved = zeroForOne ? 
                                    DyDxMath.getDx(
                                        uint128(-amount),
                                        cache.priceLower,
                                        cache.claimPrice,
                                        false
                                    )
                                  : DyDxMath.getDy(
                                        uint128(-amount),
                                        cache.claimPrice,
                                        cache.priceUpper,
                                        false
                                    );
                _transferOut(owner, zeroForOne ? token0 : token1, amountOutRemoved);
            }
        } else if (zeroForOne ? claim != upper : claim != lower) {
            //user needs to withdraw liquidity from highest tick possible
            revert WrongTickClaimedAt();
        } 

        if (amount > 0) {
            //TODO: i'm not sure how to handle double mints just yet
            // one solution is to take all their current liquidity
            // and then respread it over whatever range they select
            // if they haven't claimed at all it's fine
            // second solution is to recalculate claimPriceLast
            // easiest option is to just reset the position
            // and store the leftover amounts in the position
            // or transfer the leftover balance to the owner
            //TODO: handle double minting of position
            if(cache.position.liquidity > 0) revert NotImplementedYet();
            cache.position.liquidity += uint128(amount);
            // Prevents a global liquidity overflow in even if all ticks are initialised.
            if (cache.position.liquidity > MAX_TICK_LIQUIDITY) revert LiquidityOverflow();
        }

        zeroForOne ? positions0[owner][lower][upper] = cache.position 
                   : positions1[owner][lower][upper] = cache.position;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./PoolsharkHedgePool.sol";
import "./interfaces/IPoolsharkHedgePoolFactory.sol";
import "./interfaces/IConcentratedFactory.sol";
import "./interfaces/IPoolsharkUtils.sol";

contract PoolsharkHedgePoolFactory is 
    IPoolsharkHedgePoolFactory
{
    error IdenticalTokenAddresses();
    error PoolAlreadyExists();
    error FeeTierNotSupported();
    
    constructor(
        address _concentratedFactory,
        address _libraries
    ) {
        owner = msg.sender;
        concentratedFactory = _concentratedFactory;
        libraries = _libraries;
    }

    function createHedgePool(
        address fromToken,
        address destToken,
        uint256 swapFee
    ) external override returns (address pool) {
        
        // validate token pair
        if (fromToken == destToken) {
            revert IdenticalTokenAddresses();
        }
        address token0 = fromToken < destToken ? fromToken : destToken;
        address token1 = fromToken < destToken ? destToken : fromToken;
        // if(ERC20(token0).decimals() == 0) revert("ERROR: token0 decimals are zero.");
        // if(ERC20(token1).decimals() == 0) revert("ERROR: token1 decimals are zero.");

        // generate key for pool
        bytes32 key = keccak256(abi.encode(token0, token1, swapFee));
        if (poolMapping[key] != address(0)){
            revert PoolAlreadyExists();
        }

        // check fee tier exists and get tick spacing
        int24 tickSpacing = IConcentratedFactory(concentratedFactory).feeTierTickSpacing(uint24(swapFee));
        if (tickSpacing == 0) {
            revert FeeTierNotSupported();
        }

        address inputPool = getInputPool(token0, token1, swapFee);

        // console.log("factory input pool:", inputPool);

        // launch pool and save address
        pool =  address(
                    new PoolsharkHedgePool(
                        inputPool,
                        libraries,
                        uint24(swapFee),
                        tickSpacing
                    )
                );

        poolMapping[key] = pool;
        poolList.push(pool);

        // emit event for indexers
        emit PoolCreated(token0, token1, uint24(swapFee), tickSpacing, pool);
    }

    function getHedgePool(
        address fromToken,
        address destToken,
        uint256 fee
    ) public override view returns (address) {

        // set lexographical token address ordering
        address token0 = fromToken < destToken ? fromToken : destToken;
        address token1 = fromToken < destToken ? destToken : fromToken;

        // get pool address from mapping
        bytes32 key = keccak256(abi.encode(token0, token1, fee));

        return poolMapping[key];
    }

    function getInputPool(
        address fromToken,
        address destToken,
        uint256 swapFee
    ) internal view returns (address) {
        return IConcentratedFactory(concentratedFactory).getPool(fromToken, destToken, uint24(swapFee));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

abstract contract PoolsharkHedgePoolErrors {
    error Locked();
    error InvalidToken();
    error InvalidPosition();
    error InvalidSwapFee();
    error LiquidityOverflow();
    error Token0Missing();
    error Token1Missing();
    error InvalidTick();
    error LowerNotEvenTick();
    error UpperNotOddTick();
    error MaxTickLiquidity();
    error Overflow();
    error NotEnoughOutputLiquidity();
    error WaitUntilEnoughObservations();
}

abstract contract PoolsharkTicksErrors {
    error WrongTickOrder();
    error WrongTickLowerRange();
    error WrongTickUpperRange();
    error WrongTickLowerOrder();
    error WrongTickUpperOrder();
    error WrongTickClaimedAt();
}

abstract contract PoolsharkMiscErrors {
    // to be removed before production
    error NotImplementedYet();
}

abstract contract PoolsharkPositionErrors {
    error NotEnoughPositionLiquidity();
    error InvalidClaimTick();
}

abstract contract PoolsharkHedgePoolFactoryErrors {
    error IdenticalTokenAddresses();
    error PoolAlreadyExists();
    error FeeTierNotSupported();
}

abstract contract PoolsharkTransferErrors {
    error TransferFailed(address from, address dest);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../utils/PoolsharkErrors.sol";

abstract contract SafeTransfers is PoolsharkTransferErrors {
    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    // slither-disable-next-line assembly
    function _transferIn(
        address token,
        uint256 amount
    ) internal virtual returns (uint256) {
        if (token == address(0)) {
            if (msg.value < amount) revert TransferFailed(msg.sender, address(this));
            return amount;
        }
        IERC20 erc20Token = IERC20(token);
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        
        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        erc20Token.transferFrom(msg.sender, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := 1 // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                success := 0
            }
        }
        if (!success) revert TransferFailed(msg.sender, address(this));

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));

        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    /**
    * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
    *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
    *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
    *      it is >= amount, this should not revert in normal conditions.
    *
    *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
    *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
    */
    // slither-disable-next-line assembly
    function _transferOut(
        address to,
        address token,
        uint256 amount
    ) internal virtual {
        if (token == address(0)) {
            if (address(this).balance < amount) revert TransferFailed(address(this), to);
            payable(to).transfer(amount);
            return;
        }
        IERC20 erc20Token = IERC20(token);
        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        erc20Token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := 1 // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                success := 0
            }
        }
        if (!success) revert TransferFailed(address(this), msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}