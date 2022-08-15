/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

/* Icosa is a collection of Ethereum / PulseChain smart contracts that  *
 * build upon the Hedron smart contract to provide additional functionality */

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
}

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

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

interface IHEX {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Claim(
        uint256 data0,
        uint256 data1,
        bytes20 indexed btcAddr,
        address indexed claimToAddr,
        address indexed referrerAddr
    );
    event ClaimAssist(
        uint256 data0,
        uint256 data1,
        uint256 data2,
        address indexed senderAddr
    );
    event DailyDataUpdate(uint256 data0, address indexed updaterAddr);
    event ShareRateChange(uint256 data0, uint40 indexed stakeId);
    event StakeEnd(
        uint256 data0,
        uint256 data1,
        address indexed stakerAddr,
        uint40 indexed stakeId
    );
    event StakeGoodAccounting(
        uint256 data0,
        uint256 data1,
        address indexed stakerAddr,
        uint40 indexed stakeId,
        address indexed senderAddr
    );
    event StakeStart(
        uint256 data0,
        address indexed stakerAddr,
        uint40 indexed stakeId
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event XfLobbyEnter(
        uint256 data0,
        address indexed memberAddr,
        uint256 indexed entryId,
        address indexed referrerAddr
    );
    event XfLobbyExit(
        uint256 data0,
        address indexed memberAddr,
        uint256 indexed entryId,
        address indexed referrerAddr
    );

    fallback() external payable;

    function allocatedSupply() external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function btcAddressClaim(
        uint256 rawSatoshis,
        bytes32[] memory proof,
        address claimToAddr,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 autoStakeDays,
        address referrerAddr
    ) external returns (uint256);

    function btcAddressClaims(bytes20) external view returns (bool);

    function btcAddressIsClaimable(
        bytes20 btcAddr,
        uint256 rawSatoshis,
        bytes32[] memory proof
    ) external view returns (bool);

    function btcAddressIsValid(
        bytes20 btcAddr,
        uint256 rawSatoshis,
        bytes32[] memory proof
    ) external pure returns (bool);

    function claimMessageMatchesSignature(
        address claimToAddr,
        bytes32 claimParamHash,
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external pure returns (bool);

    function currentDay() external view returns (uint256);

    function dailyData(uint256)
        external
        view
        returns (
            uint72 dayPayoutTotal,
            uint72 dayStakeSharesTotal,
            uint56 dayUnclaimedSatoshisTotal
        );

    function dailyDataRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list);

    function dailyDataUpdate(uint256 beforeDay) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function globalInfo() external view returns (uint256[13] memory);

    function globals()
        external
        view
        returns (
            uint72 lockedHeartsTotal,
            uint72 nextStakeSharesTotal,
            uint40 shareRate,
            uint72 stakePenaltyTotal,
            uint16 dailyDataCount,
            uint72 stakeSharesTotal,
            uint40 latestStakeId,
            uint128 claimStats
        );

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function merkleProofIsValid(bytes32 merkleLeaf, bytes32[] memory proof)
        external
        pure
        returns (bool);

    function name() external view returns (string memory);

    function pubKeyToBtcAddress(
        bytes32 pubKeyX,
        bytes32 pubKeyY,
        uint8 claimFlags
    ) external pure returns (bytes20);

    function pubKeyToEthAddress(bytes32 pubKeyX, bytes32 pubKeyY)
        external
        pure
        returns (address);

    function stakeCount(address stakerAddr) external view returns (uint256);

    function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) external;

    function stakeGoodAccounting(
        address stakerAddr,
        uint256 stakeIndex,
        uint40 stakeIdParam
    ) external;

    function stakeLists(address, uint256)
        external
        view
        returns (
            uint40 stakeId,
            uint72 stakedHearts,
            uint72 stakeShares,
            uint16 lockedDay,
            uint16 stakedDays,
            uint16 unlockedDay,
            bool isAutoStake
        );

    function stakeStart(uint256 newStakedHearts, uint256 newStakedDays)
        external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function xfLobby(uint256) external view returns (uint256);

    function xfLobbyEnter(address referrerAddr) external payable;

    function xfLobbyEntry(address memberAddr, uint256 entryId)
        external
        view
        returns (uint256 rawAmount, address referrerAddr);

    function xfLobbyExit(uint256 enterDay, uint256 count) external;

    function xfLobbyFlush() external;

    function xfLobbyMembers(uint256, address)
        external
        view
        returns (uint40 headIndex, uint40 tailIndex);

    function xfLobbyPendingDays(address memberAddr)
        external
        view
        returns (uint256[2] memory words);

    function xfLobbyRange(uint256 beginDay, uint256 endDay)
        external
        view
        returns (uint256[] memory list);
}

struct HEXGlobals {
    uint72 lockedHeartsTotal;
    uint72 nextStakeSharesTotal;
    uint40 shareRate;
    uint72 stakePenaltyTotal;
    uint16 dailyDataCount;
    uint72 stakeSharesTotal;
    uint40 latestStakeId;
    uint128 claimStats;
}

struct HEXStake {
    uint40 stakeId;
    uint72 stakedHearts;
    uint72 stakeShares;
    uint16 lockedDay;
    uint16 stakedDays;
    uint16 unlockedDay;
    bool   isAutoStake;
}

struct HEXStakeMinimal {
    uint40 stakeId;
    uint72 stakeShares;
    uint16 lockedDay;
    uint16 stakedDays;
}

struct HDRNDailyData {
    uint72 dayMintedTotal;
    uint72 dayLoanedTotal;
    uint72 dayBurntTotal;
    uint32 dayInterestRate;
    uint8  dayMintMultiplier;
}

struct HDRNShareCache {
    HEXStakeMinimal _stake;
    uint256         _mintedDays;
    uint256         _launchBonus;
    uint256         _loanStart;
    uint256         _loanedDays;
    uint256         _interestRate;
    uint256         _paymentsMade;
    bool            _isLoaned;
}

struct StakeStore {
    uint64  stakeStart;
    uint64  capitalAdded;
    uint120 stakePoints;
    bool    isActive;
    uint80  payoutPreCapitalAddIcsa;
    uint80  payoutPreCapitalAddHdrn;
    uint80  stakeAmount;
    uint16  minStakeLength;
}

struct StakeCache {
    uint256 _stakeStart;
    uint256 _capitalAdded;
    uint256 _stakePoints;
    bool    _isActive;
    uint256 _payoutPreCapitalAddIcsa;
    uint256 _payoutPreCapitalAddHdrn;
    uint256 _stakeAmount;
    uint256 _minStakeLength;
}

interface IHedron {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Claim(uint256 data, address indexed claimant, uint40 indexed stakeId);
    event LoanEnd(
        uint256 data,
        address indexed borrower,
        uint40 indexed stakeId
    );
    event LoanLiquidateBid(
        uint256 data,
        address indexed bidder,
        uint40 indexed stakeId,
        uint40 indexed liquidationId
    );
    event LoanLiquidateExit(
        uint256 data,
        address indexed liquidator,
        uint40 indexed stakeId,
        uint40 indexed liquidationId
    );
    event LoanLiquidateStart(
        uint256 data,
        address indexed borrower,
        uint40 indexed stakeId,
        uint40 indexed liquidationId
    );
    event LoanPayment(
        uint256 data,
        address indexed borrower,
        uint40 indexed stakeId
    );
    event LoanStart(
        uint256 data,
        address indexed borrower,
        uint40 indexed stakeId
    );
    event Mint(uint256 data, address indexed minter, uint40 indexed stakeId);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function calcLoanPayment(
        address borrower,
        uint256 hsiIndex,
        address hsiAddress
    ) external view returns (uint256, uint256);

    function calcLoanPayoff(
        address borrower,
        uint256 hsiIndex,
        address hsiAddress
    ) external view returns (uint256, uint256);

    function claimInstanced(
        uint256 hsiIndex,
        address hsiAddress,
        address hsiStarterAddress
    ) external;

    function claimNative(uint256 stakeIndex, uint40 stakeId)
        external
        returns (uint256);

    function currentDay() external view returns (uint256);

    function dailyDataList(uint256)
        external
        view
        returns (
            uint72 dayMintedTotal,
            uint72 dayLoanedTotal,
            uint72 dayBurntTotal,
            uint32 dayInterestRate,
            uint8 dayMintMultiplier
        );

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function hsim() external view returns (address);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function liquidationList(uint256)
        external
        view
        returns (
            uint256 liquidationStart,
            address hsiAddress,
            uint96 bidAmount,
            address liquidator,
            uint88 endOffset,
            bool isActive
        );

    function loanInstanced(uint256 hsiIndex, address hsiAddress)
        external
        returns (uint256);

    function loanLiquidate(
        address owner,
        uint256 hsiIndex,
        address hsiAddress
    ) external returns (uint256);

    function loanLiquidateBid(uint256 liquidationId, uint256 liquidationBid)
        external
        returns (uint256);

    function loanLiquidateExit(uint256 hsiIndex, uint256 liquidationId)
        external
        returns (address);

    function loanPayment(uint256 hsiIndex, address hsiAddress)
        external
        returns (uint256);

    function loanPayoff(uint256 hsiIndex, address hsiAddress)
        external
        returns (uint256);

    function loanedSupply() external view returns (uint256);

    function mintInstanced(uint256 hsiIndex, address hsiAddress)
        external
        returns (uint256);

    function mintNative(uint256 stakeIndex, uint40 stakeId)
        external
        returns (uint256);

    function name() external view returns (string memory);

    function proofOfBenevolence(uint256 amount) external;

    function shareList(uint256)
        external
        view
        returns (
            HEXStakeMinimal memory stake,
            uint16 mintedDays,
            uint8 launchBonus,
            uint16 loanStart,
            uint16 loanedDays,
            uint32 interestRate,
            uint8 paymentsMade,
            bool isLoaned
        );

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IHEXStakeInstance {
    function create(uint256 stakeLength) external;

    function destroy() external;

    function goodAccounting() external;

    function initialize(address hexAddress) external;

    function share()
        external
        view
        returns (
            HEXStakeMinimal memory stake,
            uint16 mintedDays,
            uint8 launchBonus,
            uint16 loanStart,
            uint16 loanedDays,
            uint32 interestRate,
            uint8 paymentsMade,
            bool isLoaned
        );

    function stakeDataFetch() external view returns (HEXStake memory);

    function update(HDRNShareCache memory _share) external;
}

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

abstract contract AbstractRoyalties {
    mapping (uint256 => LibPart.Part[]) internal royalties;

    function _saveRoyalties(uint256 id, LibPart.Part[] memory _royalties) internal {
        uint256 totalValue;
        for (uint i = 0; i < _royalties.length; i++) {
            require(_royalties[i].account != address(0x0), "Recipient should be present");
            require(_royalties[i].value != 0, "Royalty value should be positive");
            totalValue += _royalties[i].value;
            royalties[id].push(_royalties[i]);
        }
        require(totalValue < 10000, "Royalty total value should be < 10000");
        _onRoyaltiesSet(id, _royalties);
    }

    function _updateAccount(uint256 _id, address _from, address _to) internal {
        uint length = royalties[_id].length;
        for(uint i = 0; i < length; i++) {
            if (royalties[_id][i].account == _from) {
                royalties[_id][i].account = payable(address(uint160(_to)));
            }
        }
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) virtual internal;
}

interface RoyaltiesV2 {
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}

contract RoyaltiesV2Impl is AbstractRoyalties, RoyaltiesV2 {

    function getRaribleV2Royalties(uint256 id) override external view returns (LibPart.Part[] memory) {
        return royalties[id];
    }

    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) override internal {
        emit RoyaltiesSet(id, _royalties);
    }
}

interface IHEXStakeInstanceManager {
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event HSIDetokenize(
        uint256 timestamp,
        uint256 indexed hsiTokenId,
        address indexed hsiAddress,
        address indexed staker
    );
    event HSIEnd(
        uint256 timestamp,
        address indexed hsiAddress,
        address indexed staker
    );
    event HSIStart(
        uint256 timestamp,
        address indexed hsiAddress,
        address indexed staker
    );
    event HSITokenize(
        uint256 timestamp,
        uint256 indexed hsiTokenId,
        address indexed hsiAddress,
        address indexed staker
    );
    event HSITransfer(
        uint256 timestamp,
        address indexed hsiAddress,
        address indexed oldStaker,
        address indexed newStaker
    );
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function getApproved(uint256 tokenId) external view returns (address);

    function getRaribleV2Royalties(uint256 id)
        external
        view
        returns (LibPart.Part[] memory);

    function hexStakeDetokenize(uint256 tokenId) external returns (address);

    function hexStakeEnd(uint256 hsiIndex, address hsiAddress)
        external
        returns (uint256);

    function hexStakeStart(uint256 amount, uint256 length)
        external
        returns (address);

    function hexStakeTokenize(uint256 hsiIndex, address hsiAddress)
        external
        returns (uint256);

    function hsiCount(address user) external view returns (uint256);

    function hsiLists(address, uint256) external view returns (address);

    function hsiToken(uint256) external view returns (address);

    function hsiTransfer(
        address currentHolder,
        uint256 hsiIndex,
        address hsiAddress,
        address newHolder
    ) external;

    function hsiUpdate(
        address holder,
        uint256 hsiIndex,
        address hsiAddress,
        HDRNShareCache memory share
    ) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function name() external view returns (string memory);

    function owner() external pure returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function stakeCount(address user) external view returns (uint256);

    function stakeLists(address user, uint256 hsiIndex)
        external
        view
        returns (HEXStake memory);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

library LibRoyaltiesV2 {
    /*
     * bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
     */
    bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
}

contract WeAreAllTheSA is ERC721, ERC721Enumerable, RoyaltiesV2Impl {

    using Counters for Counters.Counter;

    address private constant _hdrnFlowAddress = address(0xF447BE386164dADfB5d1e7622613f289F17024D8);
    bytes4  private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint96  private constant _waatsaRoyaltyBasis = 369; // Rarible V2 royalty basis
    string  private constant _hostname = "https://api.icosa.pro/";
    string  private constant _endpoint = "/waatsa/";

    Counters.Counter private _tokenIds;
    address          private _creator;

    constructor() ERC721("We Are All the SA", "WAATSA")
    {
        /* _creator is not an admin key. It is set at contsruction to be a link
           to the parent contract. In this case Hedron */
        _creator = msg.sender;
    }

    function _baseURI(
    )
        internal
        view
        virtual
        override
        returns (string memory)
    {
        string memory chainid = Strings.toString(block.chainid);
        return string(abi.encodePacked(_hostname, chainid, _endpoint));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721, ERC721Enumerable) 
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Internal NFT Marketplace Glue

    /** @dev Sets the Rarible V2 royalties on a specific token
     *  @param tokenId Unique ID of the HSI NFT token.
     */
    function _setRoyalties(
        uint256 tokenId
    )
        internal
    {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _waatsaRoyaltyBasis;
        _royalties[0].account = payable(_hdrnFlowAddress);
        _saveRoyalties(tokenId, _royalties);
    }

    function mintStakeNft (address staker)
        external
        returns (uint256)
    {
        require(msg.sender == _creator,
            "WAATSA: NOT ICSA");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _setRoyalties(newTokenId);

        _mint(staker, newTokenId);
        return newTokenId;
    }

    function burnStakeNft (uint256 tokenId)
        external
    {
        require(msg.sender == _creator,
            "WAATSA: NOT ICSA");

        _burn(tokenId);
    }

    // External NFT Marketplace Glue

    /**
     * @dev Implements ERC2981 royalty functionality. We just read the royalty data from
     *      the Rarible V2 implementation. 
     * @param tokenId Unique ID of the HSI NFT token.
     * @param salePrice Price the HSI NFT token was sold for.
     * @return receiver address to send the royalties to as well as the royalty amount.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    )
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        LibPart.Part[] memory _royalties = royalties[tokenId];
        
        if (_royalties.length > 0) {
            return (_royalties[0].account, (salePrice * _royalties[0].value) / 10000);
        }

        return (address(0), 0);
    }

    /**
     * @dev returns _hdrnFlowAddress, needed for some NFT marketplaces. This is not
     *       an admin key.
     * @return _hdrnFlowAddress
     */
    function owner(
    )
        external
        pure
        returns (address) 
    {
        return _hdrnFlowAddress;
    }

    /**
     * @dev Adds Rarible V2 and ERC2981 interface support.
     * @param interfaceId Unique contract interface identifier.
     * @return True if the interface is supported, false if not.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

}

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
        require(absTick <= uint256(int256(MAX_TICK)), 'T');

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
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
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

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a├ùb├╖denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
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
        uint256 twos = uint256(-int256(denominator)) & denominator;
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

    /// @notice Calculates ceil(a├ùb├╖denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
        }
    }
}

contract Icosa is ERC20, ReentrancyGuard {

    IHEX    private _hx;
    IHedron private _hdrn;
    IHEXStakeInstanceManager private _hsim;

    // tunables
    uint8   private constant _stakeTypeHDRN         = 0;
    uint8   private constant _stakeTypeICSA         = 1;
    uint8   private constant _stakeTypeNFT          = 2;
    uint256 private constant _decimalResolution     = 1e18;
    uint16  private constant _icsaIntitialSeedDays  = 360;
    uint16  private constant _minStakeLengthDefault = 30;
    uint16  private constant _minStakeLengthSquid   = 90;
    uint16  private constant _minStakeLengthDolphin = 180;
    uint16  private constant _minStakeLengthShark   = 270;
    uint16  private constant _minStakeLengthWhale   = 360;
    uint8   private constant _stakeBonusDefault     = 0;
    uint8   private constant _stakeBonusSquid       = 5;
    uint8   private constant _stakeBonusDolphin     = 10;
    uint8   private constant _stakeBonusShark       = 15;
    uint8   private constant _stakeBonusWhale       = 20;
    uint8   private constant _twapInterval          = 15;
    uint8   private constant _waatsaEventLength     = 14;

    // address constants
    address         private constant _wethAddress     = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address         private constant _usdcAddress     = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address         private constant _hexAddress      = address(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);
    address         private constant _hdrnAddress     = address(0x3819f64f282bf135d62168C1e513280dAF905e06);
    address         private constant _maxiAddress     = address(0x0d86EB9f43C57f6FF3BC9E23D8F9d82503f0e84b);
    address payable private constant _hdrnFlowAddress = payable(address(0xF447BE386164dADfB5d1e7622613f289F17024D8));

    // We Are All the SA
    WeAreAllTheSA               private _waatsa;
    mapping(address => address) private _uniswapPools;
    address                     public  waatsa;

    // informational
    uint256 public launchDay;
    uint256 public currentDay;

    // seed liquidity spread out over multiple days
    mapping(uint256 => uint256) public hdrnSeedLiquidity;
    mapping(uint256 => uint256) public icsaSeedLiquidity;

    // HDRN Staking
    mapping(uint256 => uint256)    public hdrnPoolPoints;
    mapping(uint256 => uint256)    public hdrnPoolPayout;
    mapping(address => StakeStore) public hdrnStakes;
    uint256                        public hdrnPoolPointsRemoved;
    uint256                        public hdrnPoolIcsaCollected;
    
    // ICSA Staking
    mapping(uint256 => uint256)    public icsaPoolPoints;
    mapping(uint256 => uint256)    public icsaPoolPayoutIcsa;
    mapping(uint256 => uint256)    public icsaPoolPayoutHdrn;
    mapping(address => StakeStore) public icsaStakes;
    uint256                        public icsaPoolPointsRemoved;
    uint256                        public icsaPoolIcsaCollected;
    uint256                        public icsaPoolHdrnCollected;
    uint256                        public icsaStakedSupply;
    
    // NFT Staking
    mapping(uint256 => uint256)    public nftPoolPoints;
    mapping(uint256 => uint256)    public nftPoolPayout;
    mapping(uint256 => StakeStore) public nftStakes;
    uint256                        public nftPoolPointsRemoved;
    uint256                        public nftPoolIcsaCollected;

    constructor()
        ERC20("Icosa", "ICSA")
    {
        _hx   = IHEX(payable(_hexAddress));
        _hdrn = IHedron(_hdrnAddress);
        _hsim = IHEXStakeInstanceManager(_hdrn.hsim());

        // get total amount of burnt HDRN
        launchDay = currentDay = _hdrn.currentDay();
        uint256 hdrnBurntTotal;
        for (uint256 i = 0; i <= currentDay; i++) {
            HDRNDailyData memory hdrn = _hdrnDailyDataLoad(i);
            hdrnBurntTotal += hdrn.dayBurntTotal;
        }

        // calculate and seed intitial ICSA liquidity
        HEXGlobals memory hx = _hexGlobalsLoad();
        uint256 icsaInitialSeedTotal = hdrnBurntTotal / hx.shareRate;
        uint256 seedEnd = currentDay + _icsaIntitialSeedDays + 1;
        for (uint256 i = currentDay + 1; i < seedEnd; i++) {
            icsaSeedLiquidity[i] = icsaInitialSeedTotal / _icsaIntitialSeedDays;
        }

        // set up proof of benevolence
        _hdrn.approve(_hdrnAddress, type(uint256).max);

        // initialize We Are All the SA
        waatsa = address(new WeAreAllTheSA());
        _waatsa = WeAreAllTheSA(waatsa);

        // fill uniswap mappings
        _uniswapPools[_wethAddress] = address(0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640); // WETH/USDC V3 0.05%
        _uniswapPools[_hexAddress]  = address(0x69D91B94f0AaF8e8A2586909fA77A5c2c89818d5); // HEX/USDC  V3 0.3%
        _uniswapPools[_hdrnAddress] = address(0xE859041c9C6D70177f83DE991B9d757E13CEA26E); // HDRN/USDC V3 1.0%
        _uniswapPools[_maxiAddress] = address(0xF5595d56ccB6Cb87a463C558cAD04f49Faa61149); // MAXI/USDC V3 1.0%
    }

    function decimals()
        public
        view
        virtual
        override
        returns (uint8) 
    {
        return 9;
    }

     event HSIBuyBack(
        uint256         price,
        address indexed seller,
        uint40  indexed stakeId
    );

    event HDRNStakeStart(
        uint256         data,
        address indexed staker
    );

    event HDRNStakeAddCapital(
        uint256         data,
        address indexed staker
    );

    event HDRNStakeEnd(
        uint256         data,
        address indexed staker
    );

    event HDRNStakingStats (
        uint256         data,
        uint256         payout,
        uint256 indexed stakeDay
    );

    event ICSAStakeStart(
        uint256         data,
        address indexed staker
    );

    event ICSAStakeAddCapital(
        uint256         data,
        address indexed staker
    );

    event ICSAStakeEnd(
        uint256         data0,
        uint256         data1,
        address indexed staker
    );

    event ICSAStakingStats (
        uint256         data,
        uint256         payoutIcsa,
        uint256         payoutHdrn,
        uint256 indexed stakeDay
    );

    event NFTStakeStart(
        uint256         data,
        address indexed staker,
        uint96  indexed nftId,
        address indexed tokenAddress
    );

    event NFTStakeEnd(
        uint256         data,
        address indexed staker,
        uint96  indexed nftId
    );

    event NFTStakingStats (
        uint256         data,
        uint256         payout,
        uint256 indexed stakeDay
    );

    /**
     * @dev Loads HEX global values from the HEX contract into a "Globals" object.
     * @return "HEXGlobals" object containing the global values returned by the HEX contract.
     */
    function _hexGlobalsLoad()
        internal
        view
        returns (HEXGlobals memory)
    {
        uint72  lockedHeartsTotal;
        uint72  nextStakeSharesTotal;
        uint40  shareRate;
        uint72  stakePenaltyTotal;
        uint16  dailyDataCount;
        uint72  stakeSharesTotal;
        uint40  latestStakeId;
        uint128 claimStats;

        (lockedHeartsTotal,
         nextStakeSharesTotal,
         shareRate,
         stakePenaltyTotal,
         dailyDataCount,
         stakeSharesTotal,
         latestStakeId,
         claimStats) = _hx.globals();

        return HEXGlobals(
            lockedHeartsTotal,
            nextStakeSharesTotal,
            shareRate,
            stakePenaltyTotal,
            dailyDataCount,
            stakeSharesTotal,
            latestStakeId,
            claimStats
        );
    }

    /**
     * @dev Loads Hedron daily values from the Hedron contract into a "HDRNDailyData" object.
     * @param hdrnDay The Hedron day to retrieve daily data for.
     * @return "HDRNDailyData" object containing the daily values returned by the Hedron contract.
     */
    function _hdrnDailyDataLoad(uint256 hdrnDay)
        internal
        view
        returns (HDRNDailyData memory)
    {
        uint72 dayMintedTotal;
        uint72 dayLoanedTotal;
        uint72 dayBurntTotal;
        uint32 dayInterestRate;
        uint8  dayMintMultiplier;

        (dayMintedTotal,
         dayLoanedTotal,
         dayBurntTotal,
         dayInterestRate,
         dayMintMultiplier
         ) = _hdrn.dailyDataList(hdrnDay);

        return HDRNDailyData(
            dayMintedTotal,
            dayLoanedTotal,
            dayBurntTotal,
            dayInterestRate,
            dayMintMultiplier
        );
    }

    /**
     * @dev Loads share data from a HEX stake instance (HSI) into a "HDRNShareCache" object.
     * @param hsi The HSI to load share data from.
     * @return "HDRNShareCache" object containing the share data of the HSI.
     */
    function _hsiLoad(
        IHEXStakeInstance hsi
    ) 
        internal
        view
        returns (HDRNShareCache memory)
    {
        HEXStakeMinimal memory stake;

        uint16 mintedDays;
        uint8  launchBonus;
        uint16 loanStart;
        uint16 loanedDays;
        uint32 interestRate;
        uint8  paymentsMade;
        bool   isLoaned;

        (stake,
         mintedDays,
         launchBonus,
         loanStart,
         loanedDays,
         interestRate,
         paymentsMade,
         isLoaned) = hsi.share();

        return HDRNShareCache(
            stake,
            mintedDays,
            launchBonus,
            loanStart,
            loanedDays,
            interestRate,
            paymentsMade,
            isLoaned
        );
    }

    /**
     * @dev Calculates the minimum stake length (in days) based on staker class.
     * @param stakerClass Number representing a stakes percentage of total supply
     * @return Calculated minimum stake length (in days).
     */
    function _calcMinStakeLength(
        uint256 stakerClass
    )
        internal
        pure
        returns (uint256)
    {
        uint256 minStakeLength = _minStakeLengthDefault;

        if (stakerClass >= (_decimalResolution / 100)) {
            minStakeLength = _minStakeLengthWhale;
        } else if (stakerClass >= (_decimalResolution / 1000)) {
            minStakeLength = _minStakeLengthShark;
        } else if (stakerClass >= (_decimalResolution / 10000)) {
            minStakeLength = _minStakeLengthDolphin;
        } else if (stakerClass >= (_decimalResolution / 100000)) {
            minStakeLength = _minStakeLengthSquid;
        }

        return minStakeLength;
    }

    /**
     * @dev Calculates the end stake bonus based on staker class (in days) and base payout.
     * @param stakerClass Number representing a stakes percentage of total supply
     * @param payout Base payout of the stake.
     * @return Amount of bonus tokens
     */
    function _calcStakeBonus(
        uint256 stakerClass,
        uint256 payout
    )
        internal
        pure
        returns (uint256)
    {
        uint256 bonus = payout;

        if (stakerClass >= (_decimalResolution / 100)) {
            bonus = (payout * (_stakeBonusWhale + _decimalResolution)) / _decimalResolution;
        } else if (stakerClass >= (_decimalResolution / 1000)) {
            bonus = (payout * (_stakeBonusShark + _decimalResolution)) / _decimalResolution;
        } else if (stakerClass >= (_decimalResolution / 10000)) {
            bonus = (payout * (_stakeBonusDolphin + _decimalResolution)) / _decimalResolution;
        } else if (stakerClass >= (_decimalResolution / 100000)) {
            bonus = (payout * (_stakeBonusSquid + _decimalResolution)) / _decimalResolution;
        }

        return (bonus - payout);
    }

    /**
     * @dev Calculates the end stake penalty based on time served.
     * @param minStakeDays Minimum stake length of the stake.
     * @param servedDays Number of days actually served.
     * @param amount Amount of tokens to caculate the penalty against.
     * @return The penalized payout and the penalty as separate values.
     */
    function _calcStakePenalty (
        uint256 minStakeDays,
        uint256 servedDays,
        uint256 amount
    )
        internal
        pure
        returns (uint256, uint256)
    {
        uint256 payout;
        uint256 penalty;

        if (servedDays > 0) {
            uint256 servedPercentage = (minStakeDays * _decimalResolution) / servedDays;
            payout = (amount * _decimalResolution) / servedPercentage;
            penalty = (amount - payout);
        }
        else {
            payout = 0;
            penalty = amount;
        }

        return (payout, penalty); 
    }

    /**
     * @dev Adds a new stake to the stake mappings.
     * @param stakeType Type of stake to add.
     * @param stakePoints Amount of points the stake has been allocated.
     * @param stakeAmount Amount of tokens staked.
     * @param tokenId Token ID of the stake NFT (WAATSA only).
     * @param staker Address of the staker (HDRN / ICSA stakes only).
     * @param minStakeLength Minimum length the stake must serve without penalties.
     */
    function _stakeAdd(
        uint8   stakeType,
        uint256 stakePoints,
        uint256 stakeAmount,
        uint256 tokenId,
        address staker,
        uint256 minStakeLength
    )
        internal
    {
        if (stakeType == _stakeTypeHDRN) {
            hdrnStakes[staker] =
                StakeStore(
                    uint64(currentDay),
                    uint64(currentDay),
                    uint120(stakePoints),
                    true,
                    uint80(0),
                    uint80(0),
                    uint80(stakeAmount),
                    uint16(minStakeLength)
                );
        } else if (stakeType == _stakeTypeICSA) {
            icsaStakes[staker] =
                StakeStore(
                    uint64(currentDay),
                    uint64(currentDay),
                    uint120(stakePoints),
                    true,
                    uint80(0),
                    uint80(0),
                    uint80(stakeAmount),
                    uint16(minStakeLength)
                );
        } else if (stakeType == _stakeTypeNFT) {
            nftStakes[tokenId] =
                StakeStore(
                    uint64(currentDay),
                    uint64(currentDay),
                    uint120(stakePoints),
                    true,
                    uint80(0),
                    uint80(0),
                    uint80(stakeAmount),
                    uint16(minStakeLength)
                );
        } else {
            revert();
        }
    }

    /**
     * @dev Loads values from a "StakeStore" object into a "StakeCache" object.
     * @param stakeStore "StakeStore" object to be loaded.
     * @param stake "StakeCache" object to be populated with storage data.
     */
    function _stakeLoad(
        StakeStore storage stakeStore,
        StakeCache memory  stake
    )
        internal
        view
    {
        stake._stakeStart              = stakeStore.stakeStart;
        stake._capitalAdded            = stakeStore.capitalAdded;
        stake._stakePoints             = stakeStore.stakePoints;
        stake._isActive                = stakeStore.isActive;
        stake._payoutPreCapitalAddIcsa = stakeStore.payoutPreCapitalAddIcsa;
        stake._payoutPreCapitalAddHdrn = stakeStore.payoutPreCapitalAddHdrn;
        stake._stakeAmount             = stakeStore.stakeAmount;
        stake._minStakeLength          = stakeStore.minStakeLength;
    }

    /**
     * @dev Updates a "StakeStore" object with values stored in a "StakeCache" object.
     * @param stakeStore "StakeStore" object to be updated.
     * @param stake "StakeCache" object with updated values.
     */
    function _stakeUpdate(
        StakeStore storage stakeStore,
        StakeCache memory  stake
    )
        internal
    {
        stakeStore.stakeStart              = uint64 (stake._stakeStart);
        stakeStore.capitalAdded            = uint64 (stake._capitalAdded);
        stakeStore.stakePoints             = uint120(stake._stakePoints);
        stakeStore.isActive                = stake._isActive;
        stakeStore.payoutPreCapitalAddIcsa = uint80 (stake._payoutPreCapitalAddIcsa);
        stakeStore.payoutPreCapitalAddHdrn = uint80 (stake._payoutPreCapitalAddHdrn);
        stakeStore.stakeAmount             = uint80 (stake._stakeAmount);
        stakeStore.minStakeLength          = uint16 (stake._minStakeLength);
    }

    /**
     * @dev Updates all stake values which must wait for the follwing day to be
     *      properly accounted for. Primarily keeps track of payout per point
     *      and stake points per day.
     */
    function _stakeDailyUpdate ()
        internal
    {
        // Most of the magic happens in this function
        
        uint256 hdrnDay = _hdrn.currentDay();

        if (currentDay < hdrnDay) {
            uint256 daysPast = hdrnDay - currentDay;
            
            for (uint256 i = 0; i < daysPast; i++) {
                HEXGlobals    memory hx   = _hexGlobalsLoad();
                HDRNDailyData memory hdrn = _hdrnDailyDataLoad(currentDay);

                uint256 newPoolPoints;

                // HDRN Staking
                uint256 newHdrnPoolPayout;
                newPoolPoints = (hdrnPoolPoints[currentDay + 1] + hdrnPoolPoints[currentDay]) - hdrnPoolPointsRemoved;

                // if there are stakes in the pool, else carry the previous day forward.
                if (newPoolPoints > 0) {
                    // calculate next day's payout per point
                    newHdrnPoolPayout = ((hdrn.dayBurntTotal * _decimalResolution) / hx.shareRate) + (hdrnPoolIcsaCollected * _decimalResolution) + (icsaSeedLiquidity[currentDay + 1] * _decimalResolution);
                    newHdrnPoolPayout /= newPoolPoints;
                    newHdrnPoolPayout += hdrnPoolPayout[currentDay];

                    // drain the collection
                    hdrnPoolIcsaCollected = 0;
                } else {
                    newHdrnPoolPayout = hdrnPoolPayout[currentDay];
                    
                    // carry the would be payout forward until there are stakes in the pool
                    hdrnPoolIcsaCollected += (hdrn.dayBurntTotal / hx.shareRate) + icsaSeedLiquidity[currentDay + 1];
                }

                hdrnPoolPayout[currentDay + 1] = newHdrnPoolPayout;
                hdrnPoolPoints[currentDay + 1] = newPoolPoints;

                emit HDRNStakingStats (
                    uint256(uint48 (block.timestamp))
                        |  (uint256(uint104(newPoolPoints)) << 48)
                        |  (uint256(uint104(hdrnPoolPointsRemoved)) << 152),
                    newHdrnPoolPayout,
                    currentDay + 1
                );

                hdrnPoolPointsRemoved = 0;

                // ICSA Staking
                uint256 newIcsaPoolPayoutIcsa;
                uint256 newIcsaPoolPayoutHdrn;
                newPoolPoints = (icsaPoolPoints[currentDay + 1] + icsaPoolPoints[currentDay]) - icsaPoolPointsRemoved;

                // if there are stakes in the pool, else carry the previous day forward.
                if (newPoolPoints > 0) {
                    // calculate next day's ICSA payout per point
                    newIcsaPoolPayoutIcsa = ((hdrn.dayBurntTotal * _decimalResolution) / hx.shareRate) + (icsaPoolIcsaCollected * _decimalResolution) + (icsaSeedLiquidity[currentDay + 1] * _decimalResolution);
                    newIcsaPoolPayoutIcsa /= newPoolPoints;
                    newIcsaPoolPayoutIcsa += icsaPoolPayoutIcsa[currentDay];

                    // calculate next day's HDRN payout per point
                    newIcsaPoolPayoutHdrn = (icsaPoolHdrnCollected * _decimalResolution) + (hdrnSeedLiquidity[currentDay + 1] * _decimalResolution);
                    newIcsaPoolPayoutHdrn /= newPoolPoints;
                    newIcsaPoolPayoutHdrn += icsaPoolPayoutHdrn[currentDay];
                    // drain the collections
                    icsaPoolIcsaCollected = 0;
                    icsaPoolHdrnCollected = 0;
                } else {
                    newIcsaPoolPayoutIcsa = icsaPoolPayoutIcsa[currentDay];
                    newIcsaPoolPayoutHdrn = icsaPoolPayoutHdrn[currentDay];

                    // carry the would be payout forward until there are stakes in the pool
                    icsaPoolIcsaCollected += (hdrn.dayBurntTotal / hx.shareRate) + icsaSeedLiquidity[currentDay + 1];
                    icsaPoolHdrnCollected += hdrnSeedLiquidity[currentDay + 1];
                }

                icsaPoolPayoutIcsa[currentDay + 1] = newIcsaPoolPayoutIcsa;
                icsaPoolPayoutHdrn[currentDay + 1] = newIcsaPoolPayoutHdrn;
                icsaPoolPoints[currentDay + 1] = newPoolPoints;

                emit ICSAStakingStats (
                    uint256(uint48 (block.timestamp))
                        |  (uint256(uint104(newPoolPoints)) << 48)
                        |  (uint256(uint104(icsaPoolPointsRemoved)) << 152),
                    newIcsaPoolPayoutIcsa,
                    newIcsaPoolPayoutHdrn,
                    currentDay + 1
                );

                icsaPoolPointsRemoved = 0;

                // NFT Staking
                uint256 newNftPoolPayout;
                newPoolPoints = (nftPoolPoints[currentDay + 1] + nftPoolPoints[currentDay]) - nftPoolPointsRemoved;

                // if there are stakes in the pool, else carry the previous day forward.
                if (newPoolPoints > 0) {
                    // calculate next day's payout per point
                    newNftPoolPayout = ((hdrn.dayBurntTotal * _decimalResolution) / hx.shareRate) + (nftPoolIcsaCollected * _decimalResolution) + (icsaSeedLiquidity[currentDay + 1] * _decimalResolution);
                    newNftPoolPayout /= newPoolPoints;
                    newNftPoolPayout += nftPoolPayout[currentDay];

                    // drain the collection
                    nftPoolIcsaCollected = 0;
                } else {
                    newNftPoolPayout = nftPoolPayout[currentDay];

                    // carry the would be payout forward until there are stakes in the pool
                    nftPoolIcsaCollected += (hdrn.dayBurntTotal / hx.shareRate) + icsaSeedLiquidity[currentDay + 1];
                }
                
                nftPoolPayout[currentDay + 1] = newNftPoolPayout;
                nftPoolPoints[currentDay + 1] = newPoolPoints;

                emit NFTStakingStats (
                    uint256(uint48 (block.timestamp))
                        |  (uint256(uint104(newPoolPoints)) << 48)
                        |  (uint256(uint104(nftPoolPointsRemoved)) << 152),
                    newNftPoolPayout,
                    currentDay + 1
                );

                nftPoolPointsRemoved = 0;

                // all math is done, advance to the next day
                currentDay++;
            }
        }
    }

    /**
     * @dev Fetches time weighted price square root (scaled 2 ** 96) from a uniswap v3 pool. 
     * @param uniswapV3Pool Address of the uniswap v3 pool.
     * @return Time weighted square root token price (scaled 2 ** 96).
     */
    function getSqrtTwapX96(
        address uniswapV3Pool
    )
        internal
        view 
        returns (uint160)
    {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = _twapInterval;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(uniswapV3Pool).observe(secondsAgos);

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
            int24((tickCumulatives[1] - tickCumulatives[0]) / int8(_twapInterval))
        );

        return sqrtPriceX96;
    }

    /**
     * @dev Converts a uniswap v3 square root price into a token price (scaled 2 ** 96).
     * @param sqrtPriceX96 Square root uniswap pool price (scaled 2 ** 96).
     * @return Token price (scaled 2 ** 96).
     */
    function getPriceX96FromSqrtPriceX96(
        uint160 sqrtPriceX96
    )
        internal 
        pure
        returns(uint256)
    {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    // External Functions

    // HSI Buy-Back

    /**
     * @dev Sells an HSI NFT token to the Icosa contract.
     * @param tokenId Token ID of the HSI NFT.
     * @return Amount of ICSA paid to the seller.
     */
    function hexStakeSell (
        uint256 tokenId
    )
        external
        nonReentrant
        returns (uint256)
    {
        _stakeDailyUpdate();

        require(_hsim.ownerOf(tokenId) == msg.sender,
            "ICSA: NOT OWNER");

        // load HSI stake data and HEX share rate
        HDRNShareCache memory share  = _hsiLoad(IHEXStakeInstance(_hsim.hsiToken(tokenId)));
        HEXGlobals memory hexGlobals = _hexGlobalsLoad();

        // mint ICSA to the caller
        uint256 borrowableHdrn = share._stake.stakeShares * (share._stake.stakedDays - share._mintedDays);
        uint256 payout         = borrowableHdrn / (hexGlobals.shareRate / 10);
        
        require(payout > 0,
            "ICSA: LOW VALUE");

        uint256 qcBonus;
        uint256 hlBonus = ((payout * (1000 + share._launchBonus)) / 1000) - payout;

        if (share._stake.stakedDays == 5555) {
            qcBonus = ((payout * 110) / 100) - payout;
        }

        nftPoolIcsaCollected += qcBonus + hlBonus;

        _mint(msg.sender, (payout + qcBonus + hlBonus));

        // transfer and detokenize the HSI
        _hsim.transferFrom(msg.sender, address(this), tokenId);
        address hsiAddress = _hsim.hexStakeDetokenize(tokenId);
        uint256 hsiCount   = _hsim.hsiCount(address(this));

        // borrow HDRN against the HSI
        icsaPoolHdrnCollected += _hdrn.loanInstanced(hsiCount - 1, hsiAddress);

        emit HSIBuyBack(payout, msg.sender, share._stake.stakeId);

        return (payout + qcBonus + hlBonus);
    }

    // HDRN Staking

    /**
     * @dev Starts a HDRN stake.
     * @param amount Amount of HDRN to stake.
     * @return Number of stake points allocated to the stake.
     */
    function hdrnStakeStart (
        uint256 amount
    )
        external
        nonReentrant
        returns (uint256)
    {
        _stakeDailyUpdate();

        // load stake into memory
        StakeCache memory stake;
        _stakeLoad(hdrnStakes[msg.sender], stake);

        require(stake._isActive == false,
            "ICSA: STAKE EXISTS");

        require(_hdrn.balanceOf(msg.sender) >= amount,
            "ICSA: LOW BALANCE");

        // get the HEX share rate and calculate stake points
        HEXGlobals memory hexGlobals = _hexGlobalsLoad();
        uint256 stakePoints = amount / hexGlobals.shareRate;

        uint256 stakerClass = (amount * _decimalResolution) / _hdrn.totalSupply();
        
        require(stakePoints > 0,
            "ICSA: TOO SMALL");

        uint256 minStakeLength = _calcMinStakeLength(stakerClass);

        // add stake entry
        _stakeAdd (
            _stakeTypeHDRN,
            stakePoints,
            amount,
            0,
            msg.sender,
            minStakeLength
        );

        // add stake to the pool (following day)
        hdrnPoolPoints[currentDay + 1] += stakePoints;

        // transfer HDRN to the contract and return stake points
        _hdrn.transferFrom(msg.sender, address(this), amount);

        emit HDRNStakeStart(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint120(stakePoints))    << 40)
                |  (uint256(uint80 (amount))         << 160)
                |  (uint256(uint16 (minStakeLength)) << 240),
            msg.sender
        );

        return stakePoints;
    }

    /**
     * @dev Adds more HDRN to an existing stake.
     * @param amount Amount of HDRN to add to the stake.
     * @return Number of stake points allocated to the stake.
     */
    function hdrnStakeAddCapital (
        uint256 amount
    )
        external
        nonReentrant
        returns (uint256)
    {
        _stakeDailyUpdate();

        // load stake into memory
        StakeCache memory stake;
        _stakeLoad(hdrnStakes[msg.sender], stake);

        require(stake._isActive == true,
            "ICSA: NO STAKE");

        require(_hdrn.balanceOf(msg.sender) >= amount,
            "ICSA: LOW BALANCE");

        // get the HEX share rate and calculate additional stake points
        HEXGlobals memory hexGlobals = _hexGlobalsLoad();
        uint256 stakePoints = amount / hexGlobals.shareRate;

        uint256 stakerClass = ((stake._stakeAmount + amount) * _decimalResolution) / _hdrn.totalSupply();

        require(stakePoints > 0,
            "ICSA: TOO SMALL");

        // lock in payout from previous stake points
        uint256 payoutPerPoint = hdrnPoolPayout[currentDay] - hdrnPoolPayout[stake._capitalAdded];
        uint256 payout = (stake._stakePoints * payoutPerPoint) / _decimalResolution;

        uint256 minStakeLength = _calcMinStakeLength(stakerClass);

        // update stake entry
        stake._capitalAdded             = currentDay;
        stake._stakePoints             += stakePoints;
        stake._payoutPreCapitalAddIcsa += payout;
        stake._stakeAmount             += amount;
        stake._minStakeLength           = minStakeLength;
        _stakeUpdate(hdrnStakes[msg.sender], stake);

        // add additional points to the pool (following day)
        hdrnPoolPoints[currentDay + 1] += stakePoints;

        // transfer HDRN to the contract and return stake points
        _hdrn.transferFrom(msg.sender, address(this), amount);

        emit HDRNStakeAddCapital(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint120(stakePoints))    << 40)
                |  (uint256(uint80 (amount))         << 160)
                |  (uint256(uint16 (minStakeLength)) << 240),
            msg.sender
        );

        return stake._stakePoints;
    }

    /**
     * @dev Ends a HDRN stake.
     * @return ICSA yield, HDRN principal penalty, ICSA yield penalty.
     */
    function hdrnStakeEnd () 
        external
        nonReentrant
        returns (uint256, uint256, uint256)
    {
        _stakeDailyUpdate();

        // load stake into memory
        StakeCache memory stake;
        _stakeLoad(hdrnStakes[msg.sender], stake);

        require(stake._isActive == true,
            "ICSA: NO STAKE");

        // ended pending stake, just reverse it.
        if (stake._stakeStart == currentDay) {
            // return staked principal
            _hdrn.transfer(msg.sender, stake._stakeAmount);

            // remove points from the pool
            hdrnPoolPointsRemoved += stake._stakePoints;

            // update stake entry
            stake._stakeStart              = 0;
            stake._capitalAdded            = 0;
            stake._stakePoints             = 0;
            stake._isActive                = false;
            stake._payoutPreCapitalAddIcsa = 0;
            stake._stakeAmount             = 0;
            stake._minStakeLength          = 0;
            _stakeUpdate(hdrnStakes[msg.sender], stake);

            emit HDRNStakeEnd(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint72(0)) << 40)
                |  (uint256(uint72(0)) << 112)
                |  (uint256(uint72(0)) << 184),
            msg.sender
            );

            return (0,0,0);
        }

        // calculate payout per point
        uint256 payoutPerPoint = hdrnPoolPayout[currentDay] - hdrnPoolPayout[stake._capitalAdded];

        uint256 payout;
        uint256 bonus;
        uint256 payoutPenalty;
        uint256 principal;
        uint256 principalPenalty;

        if ((stake._capitalAdded + stake._minStakeLength) > currentDay) {
            uint256 servedDays = currentDay - stake._capitalAdded;
            
            payout = stake._payoutPreCapitalAddIcsa + ((stake._stakePoints * payoutPerPoint) / _decimalResolution);
            (payout, payoutPenalty) = _calcStakePenalty(stake._minStakeLength, servedDays, payout);

            // distribute ICSA penalties
            hdrnPoolIcsaCollected += payoutPenalty / 3;
            icsaPoolIcsaCollected += payoutPenalty / 3;
            nftPoolIcsaCollected  += payoutPenalty / 3;

            principal = stake._stakeAmount;
            (principal, principalPenalty) = _calcStakePenalty(stake._minStakeLength, servedDays, principal);

            // distribute HDRN penalties
            _hdrn.proofOfBenevolence(principalPenalty / 2);
            icsaPoolHdrnCollected += principalPenalty / 2;
        } else {
            uint256 stakerClass = (stake._stakeAmount * _decimalResolution) / _hdrn.totalSupply();

            payout = stake._payoutPreCapitalAddIcsa + ((stake._stakePoints * payoutPerPoint) / _decimalResolution);
            bonus  = _calcStakeBonus(stakerClass, payout);
            principal = stake._stakeAmount;
        }

        // remove points from the pool
        hdrnPoolPointsRemoved += stake._stakePoints;

        // update stake entry
        stake._stakeStart              = 0;
        stake._capitalAdded            = 0;
        stake._stakePoints             = 0;
        stake._isActive                = false;
        stake._payoutPreCapitalAddIcsa = 0;
        stake._stakeAmount             = 0;
        stake._minStakeLength          = 0;
        _stakeUpdate(hdrnStakes[msg.sender], stake);

        nftPoolIcsaCollected += bonus;

        // mint ICSA and return payout
        if (payout > 0) { _mint(msg.sender, (payout + bonus)); }

        // return staked principal
        if (principal > 0) { _hdrn.transfer(msg.sender, principal); }

        emit HDRNStakeEnd(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint72(payout + bonus))   << 40)
                |  (uint256(uint72(principalPenalty)) << 112)
                |  (uint256(uint72(payoutPenalty))    << 184),
            msg.sender
        );

        return ((payout + bonus), principalPenalty, payoutPenalty);
    }

    // ICSA Staking

    /**
     * @dev Starts an ICSA stake.
     * @param amount Amount of ICSA to stake.
     * @return Number of stake points allocated to the stake.
     */
    function icsaStakeStart (
        uint256 amount
    )
        external
        nonReentrant
        returns (uint256)
    {
        _stakeDailyUpdate();

        // load stake into memory
        StakeCache memory stake;
        _stakeLoad(icsaStakes[msg.sender], stake);

        require(stake._isActive == false,
            "ICSA: STAKE EXISTS");

        require(balanceOf(msg.sender) >= amount,
            "ICSA: LOW BALANCE");

        // get the HEX share rate and calculate stake points
        HEXGlobals memory hexGlobals = _hexGlobalsLoad();
        uint256 stakePoints = amount / hexGlobals.shareRate;

        uint256 stakerClass = (amount * _decimalResolution) / totalSupply();
        
        require(stakePoints > 0,
            "ICSA: TOO SMALL");

        uint256 minStakeLength = _calcMinStakeLength(stakerClass);

        // add stake entry
        _stakeAdd (
            _stakeTypeICSA,
            stakePoints,
            amount,
            0,
            msg.sender,
            minStakeLength
        );

        // add stake to the pool (following day)
        icsaPoolPoints[currentDay + 1] += stakePoints;

        // increase staked supply metric
        icsaStakedSupply += amount;

        // temporarily burn stakers ICSA
        _burn(msg.sender, amount);

        emit ICSAStakeStart(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint120(stakePoints))    << 40)
                |  (uint256(uint80 (amount))         << 160)
                |  (uint256(uint16 (minStakeLength)) << 240),
            msg.sender
        );

        return stakePoints;
    }

    /**
     * @dev Adds more ICSA to an existing stake.
     * @param amount Amount of ICSA to add to the stake.
     * @return Number of stake points allocated to the stake.
     */
    function icsaStakeAddCapital (
        uint256 amount
    )
        external
        nonReentrant
        returns (uint256)
    {
        _stakeDailyUpdate();

        // load stake into memory
        StakeCache memory stake;
        _stakeLoad(icsaStakes[msg.sender], stake);

        require(stake._isActive == true,
            "ICSA: NO STAKE");

        require(balanceOf(msg.sender) >= amount,
            "ICSA: LOW BALANCE");

        // get the HEX share rate and calculate additional stake points
        HEXGlobals memory hexGlobals = _hexGlobalsLoad();
        uint256 stakePoints = amount / hexGlobals.shareRate;

        uint256 stakerClass = ((stake._stakeAmount + amount) * _decimalResolution) / totalSupply();

        require(stakePoints > 0,
            "ICSA: TOO SMALL");

        // lock in payout from previous stake points
        uint256 payoutPerPointIcsa = icsaPoolPayoutIcsa[currentDay] - icsaPoolPayoutIcsa[stake._capitalAdded];
        uint256 payoutIcsa = (stake._stakePoints * payoutPerPointIcsa) / _decimalResolution;

        uint256 payoutPerPointHdrn = icsaPoolPayoutHdrn[currentDay] - icsaPoolPayoutHdrn[stake._capitalAdded];
        uint256 payoutHdrn = (stake._stakePoints * payoutPerPointHdrn) / _decimalResolution;

        uint256 minStakeLength = _calcMinStakeLength(stakerClass);

        // update stake entry
        stake._capitalAdded             = currentDay;
        stake._stakePoints             += stakePoints;
        stake._payoutPreCapitalAddIcsa += payoutIcsa;
        stake._payoutPreCapitalAddHdrn += payoutHdrn;
        stake._stakeAmount             += amount;
        stake._minStakeLength           = minStakeLength;
        _stakeUpdate(icsaStakes[msg.sender], stake);

        // add additional points to the pool (following day)
        icsaPoolPoints[currentDay + 1] += stakePoints;

        // increase staked supply metric
        icsaStakedSupply += amount;

        // temporarily burn stakers ICSA
        _burn(msg.sender, amount);

        emit ICSAStakeAddCapital(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint120(stakePoints))    << 40)
                |  (uint256(uint80 (amount))         << 160)
                |  (uint256(uint16 (minStakeLength)) << 240),
            msg.sender
        );

        return stake._stakePoints;
    }

    /**
     * @dev Ends an ICSA stake.
     * @return ICSA yield, HDRN yield, ICSA principal penalty, HDRN yield penalty, ICSA yield penalty.
     */
    function icsaStakeEnd () 
        external
        nonReentrant
        returns (uint256, uint256, uint256, uint256, uint256)
    {
        _stakeDailyUpdate();

        // load stake into memory
        StakeCache memory stake;
        _stakeLoad(icsaStakes[msg.sender], stake);

        require(stake._isActive == true,
            "ICSA: NO STAKE");

        // ended pending stake, just reverse it.
        if (stake._stakeStart == currentDay) {
            // return staked principal
            _mint(msg.sender, stake._stakeAmount);
            
            // remove points from the pool
            icsaPoolPointsRemoved += stake._stakePoints;

            // decrease staked supply metric
            icsaStakedSupply -= stake._stakeAmount;

            // update stake entry
            stake._stakeStart              = 0;
            stake._capitalAdded            = 0;
            stake._stakePoints             = 0;
            stake._isActive                = false;
            stake._payoutPreCapitalAddIcsa = 0;
            stake._payoutPreCapitalAddHdrn = 0;
            stake._stakeAmount             = 0;
            stake._minStakeLength          = 0;
            _stakeUpdate(icsaStakes[msg.sender], stake);

            emit ICSAStakeEnd(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint72(0)) << 40)
                |  (uint256(uint72(0)) << 112)
                |  (uint256(uint72(0)) << 184),
            uint256(uint128(0))
                |  (uint256(uint128(0)) << 128),
            msg.sender
            );

            return (0,0,0,0,0);
        }

        // calculate payout per point
        uint256 payoutPerPointIcsa = icsaPoolPayoutIcsa[currentDay] - icsaPoolPayoutIcsa[stake._capitalAdded];
        uint256 payoutPerPointHdrn = icsaPoolPayoutHdrn[currentDay] - icsaPoolPayoutHdrn[stake._capitalAdded];

        uint256 payoutIcsa;
        uint256 bonusIcsa;
        uint256 payoutHdrn;
        uint256 payoutPenaltyIcsa;
        uint256 payoutPenaltyHdrn;
        uint256 principal;
        uint256 principalPenalty;

        if ((stake._capitalAdded + stake._minStakeLength) > currentDay) {
            uint256 servedDays = currentDay - stake._capitalAdded;
            
            payoutIcsa = stake._payoutPreCapitalAddIcsa + ((stake._stakePoints * payoutPerPointIcsa) / _decimalResolution);
            (payoutIcsa, payoutPenaltyIcsa) = _calcStakePenalty(stake._minStakeLength, servedDays, payoutIcsa);

            payoutHdrn = stake._payoutPreCapitalAddHdrn + ((stake._stakePoints * payoutPerPointHdrn) / _decimalResolution);
            (payoutHdrn, payoutPenaltyHdrn) = _calcStakePenalty(stake._minStakeLength, servedDays, payoutHdrn);

            principal = stake._stakeAmount;
            (principal, principalPenalty) = _calcStakePenalty(stake._minStakeLength, servedDays, principal);

            // distribute ICSA penalties
            hdrnPoolIcsaCollected += (payoutPenaltyIcsa + principalPenalty) / 3;
            icsaPoolIcsaCollected += (payoutPenaltyIcsa + principalPenalty) / 3;
            nftPoolIcsaCollected  += (payoutPenaltyIcsa + principalPenalty) / 3;

            // distribute HDRN penalties
            _hdrn.proofOfBenevolence(payoutPenaltyHdrn / 2);
            icsaPoolHdrnCollected += payoutPenaltyHdrn / 2;
        } else {
            uint256 stakerClass = (stake._stakeAmount * _decimalResolution) / totalSupply();

            payoutIcsa = stake._payoutPreCapitalAddIcsa + ((stake._stakePoints * payoutPerPointIcsa) / _decimalResolution);
            payoutHdrn = stake._payoutPreCapitalAddHdrn + ((stake._stakePoints * payoutPerPointHdrn) / _decimalResolution);
            bonusIcsa = _calcStakeBonus(stakerClass, payoutIcsa);
            principal = stake._stakeAmount;
        }

        // remove points from the pool
        icsaPoolPointsRemoved += stake._stakePoints;

        // decrease staked supply metric
        icsaStakedSupply -= stake._stakeAmount;

        // update stake entry
        stake._stakeStart              = 0;
        stake._capitalAdded            = 0;
        stake._stakePoints             = 0;
        stake._isActive                = false;
        stake._payoutPreCapitalAddIcsa = 0;
        stake._payoutPreCapitalAddHdrn = 0;
        stake._stakeAmount             = 0;
        stake._minStakeLength          = 0;
        _stakeUpdate(icsaStakes[msg.sender], stake);

        nftPoolIcsaCollected += bonusIcsa;

        // mint ICSA
        if (payoutIcsa + principal > 0) { _mint(msg.sender, (payoutIcsa + principal + bonusIcsa)); }

        // transfer HDRN
        if (payoutHdrn > 0) { _hdrn.transfer(msg.sender, payoutHdrn); }

        emit ICSAStakeEnd(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint72(payoutIcsa + bonusIcsa))       << 40)
                |  (uint256(uint72(payoutHdrn))       << 112)
                |  (uint256(uint72(principalPenalty)) << 184),
            uint256(uint128(payoutPenaltyIcsa))
                |  (uint256(uint128(payoutPenaltyHdrn)) << 128),
            msg.sender
        );

        return ((payoutIcsa + bonusIcsa), payoutHdrn, principalPenalty, payoutPenaltyIcsa, payoutPenaltyHdrn);
    }

    // NFT Staking

    /**
     * @dev Starts an NFT stake.
     * @param amount Amount of tokens to buy the NFT with.
     * @param tokenAddress Address of the token contract.
     * @return Number of stake points allocated to the stake.
     */
    function nftStakeStart (
        uint256 amount,
        address tokenAddress
    )
        external
        payable
        nonReentrant
        returns (uint256)
    {
        _stakeDailyUpdate();

        require(currentDay < (launchDay + _waatsaEventLength),
            "ICSA: TOO LATE");

        // Fallback in case PulseChain launches mid-WAATSA
        require(block.chainid == 1,
            "ICSA: BAD CHAIN");

        uint256 tokenPrice;
        uint256 stakePoints;

        IERC20 token = IERC20(tokenAddress);

        // ETH handler
        if (tokenAddress == address(0)) {

            // amount does not match sent eth, nuke transaction.
            if (amount != msg.value) {
                revert();
            }

            // weth pools are backwards for some reason.
            tokenPrice = getPriceX96FromSqrtPriceX96(getSqrtTwapX96(_uniswapPools[_wethAddress]));
            stakePoints = (amount * (2**96)) / tokenPrice;
            
            _hdrnFlowAddress.transfer(amount);
        }

        // ERC20 handler
        else {
            address uniswapPool = _uniswapPools[tokenAddress];

            // invalid token, nuke the transaction.
            if (tokenAddress != _usdcAddress && uniswapPool == address(0)) {
                revert();
            }

            if (tokenAddress != _usdcAddress) {
                // weth pools are backwards for some reason.
                if (tokenAddress == _wethAddress) {
                    tokenPrice = getPriceX96FromSqrtPriceX96(getSqrtTwapX96(uniswapPool));
                    stakePoints = (amount * (2**96)) / tokenPrice;
                }

                else {
                    tokenPrice = getPriceX96FromSqrtPriceX96(getSqrtTwapX96(uniswapPool));
                    stakePoints = (amount * tokenPrice) / (2 ** 96);
                }
            }

            else {
                stakePoints = amount;
            }

            token.transferFrom(msg.sender, _hdrnFlowAddress, amount);
        }

        require(stakePoints > 0,
            "ICSA: TOO SMALL");

        uint256 nftId = _waatsa.mintStakeNft(msg.sender);

        // add stake entry
        _stakeAdd (
            _stakeTypeNFT,
            stakePoints,
            0,
            nftId,
            address(0),
            0
        );

        // add stake to the pool (following day)
        nftPoolPoints[currentDay + 1] += stakePoints;

        emit NFTStakeStart(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint216(stakePoints)) << 40),
            msg.sender,
            uint96(nftId),
            tokenAddress
        );

        return stakePoints;
    }

    /**
     * @dev Ends an NFT stake.
     * @param nftId Token id of the staking NFT.
     * @return ICSA yield.
     */
    function nftStakeEnd (
        uint256 nftId
    ) 
        external
        nonReentrant
        returns (uint256)
    {
        _stakeDailyUpdate();

        require(_waatsa.ownerOf(nftId) == msg.sender,
            "ICSA: NOT OWNER");
        
        // load stake into memory
        StakeCache memory stake;
        _stakeLoad(nftStakes[nftId], stake);

        require(stake._isActive == true,
            "ICSA: NO STAKE");

        uint256 payoutPerPoint = nftPoolPayout[currentDay] - nftPoolPayout[stake._capitalAdded];
        uint256 payout = (stake._stakePoints * payoutPerPoint) / _decimalResolution;

        // remove points from the pool
        nftPoolPointsRemoved += stake._stakePoints;

        // update stake entry
        stake._stakeStart              = 0;
        stake._capitalAdded            = 0;
        stake._stakePoints             = 0;
        stake._isActive                = false;
        stake._payoutPreCapitalAddIcsa = 0;
        stake._payoutPreCapitalAddHdrn = 0;
        stake._stakeAmount             = 0;
        stake._minStakeLength          = 0;
        _stakeUpdate(nftStakes[nftId], stake);

        // mint ICSA
        if (payout > 0 ) { _mint(msg.sender, payout); }
        _waatsa.burnStakeNft(nftId);

        emit NFTStakeEnd(
            uint256(uint40 (block.timestamp))
                |  (uint256(uint216(payout)) << 40),
            msg.sender,
            uint96(nftId)
        );

        return payout;
    }

    function injectSeedLiquidity (
        uint256 amount,
        uint256 seedDays
    ) 
        external
        nonReentrant
    {
        require(_hdrn.balanceOf(msg.sender) >= amount,
            "ICSA: LOW BALANCE");

        require(seedDays >= 1,
            "ICSA: LOW SEED");

        // calculate and seed ICSA liquidity
        HEXGlobals memory hx = _hexGlobalsLoad();
        uint256 icsaSeedTotal = amount / hx.shareRate;
        uint256 seedEnd = currentDay + seedDays + 1;

        for (uint256 i = currentDay + 1; i < seedEnd; i++) {
            icsaSeedLiquidity[i] += icsaSeedTotal / seedDays;
            hdrnSeedLiquidity[i] += amount / seedDays;
        }

        _hdrn.transferFrom(msg.sender, address(this), amount);
    }

    // Overrides

    /* In short, _stakeDailyUpdate needs to be called in all possible cases.
       This is to ensure the gas limit is never exceeded. By overriding these
       functions we ensure it is always called given any contract interraction. */
    
    function approve(
        address spender,
        uint256 amount
    ) 
        public
        virtual
        override
        returns (bool) 
    {
        _stakeDailyUpdate();
        return super.approve(spender, amount);
    }

    function transfer(
        address to,
        uint256 amount
    )
        public
        virtual
        override
        returns (bool)
    {
        _stakeDailyUpdate();
        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    )
        public
        virtual
        override
        returns (bool)
    {
        _stakeDailyUpdate();
        return super.transferFrom(from, to, amount);
    }
}