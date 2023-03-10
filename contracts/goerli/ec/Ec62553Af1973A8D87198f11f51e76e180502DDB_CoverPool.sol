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

abstract contract CoverPoolEvents {
    event Mint(
        address indexed owner,
        int24 indexed lower,
        int24 indexed upper,
        int24 claim,
        bool zeroForOne,
        uint128 liquidityMinted
    );

    event Burn(
        address indexed owner,
        int24 indexed lower,
        int24 indexed upper,
        int24 claim,
        bool zeroForOne,
        uint128 liquidityBurned
    );

    //TODO: implement Collect event for subgraph
    event Collect(address indexed sender, uint256 amount0, uint256 amount1);

    event Swap(
        address indexed recipient,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
    //TODO: PoolInitialized event
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import '../interfaces/ICoverPoolStructs.sol';
import '../interfaces/ICoverPoolFactory.sol';
import '../utils/CoverPoolErrors.sol';

abstract contract CoverPoolStorage is ICoverPoolStructs, CoverPoolErrors {
    GlobalState public globalState;
    PoolState public pool0; /// @dev State for token0 as output
    PoolState public pool1; /// @dev State for token1 as output

    address public feeTo;

    mapping(int24 => TickNode) public tickNodes; /// @dev Tick nodes in linked list
    mapping(int24 => Tick) public ticks0; /// @dev Ticks containing token0 as output
    mapping(int24 => Tick) public ticks1; /// @dev Ticks containing token1 as output
    mapping(address => mapping(int24 => mapping(int24 => Position))) public positions0; //positions with token0 deposited
    mapping(address => mapping(int24 => mapping(int24 => Position))) public positions1; //positions with token1 deposited
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './interfaces/ICoverPool.sol';
import './interfaces/IRangePool.sol';
import './base/CoverPoolStorage.sol';
import './base/CoverPoolEvents.sol';
import './utils/SafeTransfers.sol';
import './utils/CoverPoolErrors.sol';
import './libraries/Ticks.sol';
import './libraries/Positions.sol';
import './libraries/Epochs.sol';

/// @notice Poolshark Cover Pool Implementation
contract CoverPool is
    ICoverPool,
    CoverPoolStorage,
    CoverPoolEvents,
    CoverTicksErrors,
    CoverMiscErrors,
    CoverPositionErrors,
    SafeTransfers
{
    address internal immutable factory;
    address internal immutable token0;
    address internal immutable token1;

    modifier lock() {
        if (globalState.unlocked == 0) {
            globalState = Ticks.initialize(tickNodes, pool0, pool1, globalState);
        }
        if (globalState.unlocked == 0) revert WaitUntilEnoughObservations();
        if (globalState.unlocked == 2) revert Locked();
        globalState.unlocked = 2;
        _;
        globalState.unlocked = 1;
    }

    constructor(
        address _inputPool,
        int16 _tickSpread,
        uint16 _twapLength,
        uint16 _auctionLength
    ) {
        // validate tick spread
        int24 _tickSpacing = IRangePool(_inputPool).tickSpacing();
        int24 _tickMultiple = _tickSpread / _tickSpacing;
        if ((_tickMultiple < 2) || _tickMultiple * _tickSpacing != _tickSpread)
            revert InvalidTickSpread();

        // set addresses
        factory   = msg.sender;
        token0    = IRangePool(_inputPool).token0();
        token1    = IRangePool(_inputPool).token1();
        feeTo     = ICoverPoolFactory(msg.sender).owner();

        // set global state
        GlobalState memory state = GlobalState(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, IRangePool(address(0)));
        state.tickSpread    = _tickSpread;
        state.twapLength    = _twapLength;
        state.auctionLength = _auctionLength;
        state.genesisBlock  = uint32(block.number);
        state.inputPool     = IRangePool(_inputPool);

        // set initial ticks
        state = Ticks.initialize(
            tickNodes,
            pool0,
            pool1,
            state
        );

        globalState = state;
    }

    //TODO: create transfer function to transfer ownership
    /// @dev Mints LP tokens - should be called via the CL pool manager contract.
    function mint(
        int24 lowerOld,
        int24 lower,
        int24 claim,
        int24 upper,
        int24 upperOld,
        uint128 amountDesired,
        bool zeroForOne
    ) external lock {
        /// @dev - don't allow mints until we have enough observations from state.inputPool
        //TODO: move tick update check here
        if (block.number != globalState.lastBlock) {
            //can save a couple 100 gas if we skip this when no update
            (globalState, pool0, pool1) = Epochs.syncLatest(
                ticks0,
                ticks1,
                tickNodes,
                pool0,
                pool1,
                globalState
            );
        }
        uint256 liquidityMinted;
        (lowerOld, lower, upper, upperOld, amountDesired, liquidityMinted) = Positions.validate(
            ValidateParams(lowerOld, lower, upper, upperOld, zeroForOne, amountDesired, globalState)
        );
        //TODO: handle upperOld and lowerOld being invalid

        if (zeroForOne) {
            _transferIn(token0, amountDesired);
        } else {
            _transferIn(token1, amountDesired);
        }

        unchecked {
            // recreates position if required
            globalState = Positions.update(
                zeroForOne ? positions0 : positions1,
                zeroForOne ? ticks0 : ticks1,
                tickNodes,
                globalState,
                zeroForOne ? pool0 : pool1,
                UpdateParams(msg.sender, lower, upper, claim, zeroForOne, 0)
            );
            //TODO: check amount consumed from return value
            //TODO: would be nice to reject invalid claim ticks on mint
            //      don't think we can because of the 'double mint' scenario
            // creates new position
            (, globalState) = Positions.add(
                zeroForOne ? positions0 : positions1,
                zeroForOne ? ticks0 : ticks1,
                tickNodes,
                globalState,
                AddParams(
                    msg.sender,
                    lowerOld,
                    lower,
                    upper,
                    upperOld,
                    zeroForOne,
                    uint128(liquidityMinted)
                )
            );
            /// @dev - pool current liquidity should never be increased on mint
        }
        emit Mint(
            msg.sender,
            lower,
            upper,
            claim, //TODO: not sure if needed for subgraph
            zeroForOne,
            uint128(liquidityMinted)
        );
        // globalState = state;
    }

    function burn(
        int24 lower,
        int24 claim,
        int24 upper,
        bool zeroForOne,
        uint128 amount
    ) external lock {
        GlobalState memory state = globalState;
        if (block.number != state.lastBlock) {
            (state, pool0, pool1) = Epochs.syncLatest(
                ticks0,
                ticks1,
                tickNodes,
                pool0,
                pool1,
                state
            );
        }
        //TODO: burning liquidity should take liquidity out past the current auction

        // Ensure no overflow happens when we cast from uint128 to int128.
        if (amount > uint128(type(int128).max)) revert LiquidityOverflow();

        if (claim != (zeroForOne ? upper : lower) || claim == state.latestTick) {
            // update position and get new lower and upper
            state = Positions.update(
                zeroForOne ? positions0 : positions1,
                zeroForOne ? ticks0 : ticks1,
                tickNodes,
                state,
                zeroForOne ? pool0 : pool1,
                UpdateParams(msg.sender, lower, upper, claim, zeroForOne, amount)
            );
        }
        //TODO: add PositionUpdated event
        // if position hasn't changed remove liquidity
        else {
            (, state) = Positions.remove(
                zeroForOne ? positions0 : positions1,
                zeroForOne ? ticks0 : ticks1,
                tickNodes,
                state,
                RemoveParams(msg.sender, lower, upper, zeroForOne, amount)
            );
        }
        //TODO: get token amounts from _updatePosition return values
        //TODO: need to know old ticks and new ticks
        emit Burn(msg.sender, lower, upper, claim, zeroForOne, amount);
        globalState = state;
    }

    function collect(
        int24 lower,
        int24 claim,
        int24 upper,
        bool zeroForOne
    ) public lock {
        GlobalState memory state = globalState;
        if (block.number != state.lastBlock) {
            (state, pool0, pool1) = Epochs.syncLatest(
                ticks0,
                ticks1,
                tickNodes,
                pool0,
                pool1,
                state
            );
        }
        state = Positions.update(
            zeroForOne ? positions0 : positions1,
            zeroForOne ? ticks0 : ticks1,
            tickNodes,
            state,
            zeroForOne ? pool0 : pool1,
            UpdateParams(msg.sender, lower, upper, claim, zeroForOne, 0)
        );

        mapping(address => mapping(int24 => mapping(int24 => Position))) storage positions = zeroForOne ? positions0 : positions1;
        zeroForOne ? upper = claim : lower = claim;

        // store amounts for transferOut
        uint128 amountIn = positions[msg.sender][lower][upper].amountIn;
        uint128 amountOut = positions[msg.sender][lower][upper].amountOut;

        console.log('amountIn:', amountIn);
        console.log(zeroForOne ? ERC20(token1).balanceOf(address(this)) : ERC20(token0).balanceOf(address(this)));
        console.log('amountOut:', amountOut);
        console.log(zeroForOne ? ERC20(token0).balanceOf(address(this)) : ERC20(token1).balanceOf(address(this)));

        // zero out balances
        positions[msg.sender][lower][upper].amountIn = 0;
        positions[msg.sender][lower][upper].amountOut = 0;

        /// transfer out balances
        _transferOut(msg.sender, zeroForOne ? token1 : token0, amountIn);
        _transferOut(msg.sender, zeroForOne ? token0 : token1, amountOut);

        emit Collect(msg.sender, amountIn, amountOut);
        globalState = state;
    }

    /// @dev Swaps one token for another. The router must prefund this contract and ensure there isn't too much slippage.
    function swap(
        address recipient,
        bool zeroForOne,
        uint128 amountIn,
        uint160 priceLimit
    )
        external
        override
        // bytes calldata data
        lock
        returns (uint256 amountOut)
    {
        //TODO: is this needed?
        //TODO: implement stopPrice for pool/1
        GlobalState memory state = globalState;
        PoolState memory pool = zeroForOne ? pool1 : pool0;
        TickMath.validatePrice(priceLimit);
        if (block.number != state.lastBlock) {
            (state, pool0, pool1) = Epochs.syncLatest(
                ticks0,
                ticks1,
                tickNodes,
                pool0,
                pool1,
                state //TODO: move to syncLatest
            );
        }

        if (amountIn == 0) {
            globalState = state;
            return 0;
        }

        _transferIn(zeroForOne ? token0 : token1, amountIn);

        SwapCache memory cache = SwapCache({
            price: pool.price,
            liquidity: pool.liquidity,
            auctionDepth: block.number - state.genesisBlock - state.auctionStart,
            auctionBoost: 0,
            input: amountIn,
            inputBoosted: 0,
            amountInDelta: 0
        });

        /// @dev - liquidity range is limited to one tick within state.latestTick - should we add tick crossing?
        /// @dev not sure whether to handle greater than tickSpacing range
        /// @dev everything will always be cleared out except for the closest tick to state.latestTick
        (cache, amountOut) = Ticks.quote(zeroForOne, priceLimit, state, cache);

        // amountOut += output;

        if (zeroForOne) {
            pool1.price = uint160(cache.price);
            pool1.amountInDelta += uint128(cache.amountInDelta);
        } else {
            pool0.price = uint160(cache.price);
            pool0.amountInDelta += uint128(cache.amountInDelta);
        }

        if (zeroForOne) {
            if (cache.input > 0) {
                _transferOut(recipient, token0, cache.input);
            }
            _transferOut(recipient, token1, amountOut);
            emit Swap(recipient, token0, token1, amountIn - cache.input, amountOut);
        } else {
            if (cache.input > 0) {
                //TODO: add this delta across ticks in syncLatest / Positions.update
                _transferOut(recipient, token1, cache.input);
            }
            _transferOut(recipient, token0, amountOut);
            emit Swap(recipient, token1, token0, amountIn - cache.input, amountOut);
        }
        globalState = state;
    }

    //TODO: handle quoteAmountIn and quoteAmountOut
    function quote(
        bool zeroForOne,
        uint256 amountIn,
        uint160 priceLimit
    ) external view returns (uint256 inAmount, uint256 outAmount) {
        // TODO: make override
        GlobalState memory state = globalState;
        SwapCache memory cache = SwapCache({
            price: zeroForOne ? pool1.price : pool0.price,
            liquidity: zeroForOne ? pool1.liquidity : pool0.liquidity,
            auctionDepth: block.number - state.genesisBlock - state.auctionStart,
            auctionBoost: 0,
            input: amountIn,
            inputBoosted: 0,
            amountInDelta: 0
        });
        /// @dev - liquidity range is limited to one tick within state.latestTick - should we add tick crossing?
        /// @dev not sure whether to handle greater than tickSpacing range
        /// @dev everything will always be cleared out except for the closest tick to state.latestTick
        (cache, outAmount) = Ticks.quote(zeroForOne, priceLimit, state, cache);
        inAmount = amountIn - cache.input;

        return (inAmount, outAmount);
    }

    //TODO: zap into LP position
    //TODO: use bitmaps to naiively search for the tick closest to the new TWAP
    //TODO: assume everything will get filled for now
    //TODO: remove old latest tick if necessary
    //TODO: after accumulation, all liquidity below old latest tick is removed
    //TODO: don't update state.latestTick until TWAP has moved +/- tickSpacing
    //TODO: state.latestTick needs to be a multiple of tickSpacing
    //TODO: consider partial fills and how that impacts claims
    //TODO: consider current price...we might have to skip claims/burns from current tick
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './ICoverPoolStructs.sol';

//TODO: combine everything into one interface
interface ICoverPool is ICoverPoolStructs {
    function collect(
        int24 lower,
        int24 upper,
        int24 claim,
        bool zeroForOne
    ) external;

    function mint(
        int24 lowerOld,
        int24 lower,
        int24 upperOld,
        int24 upper,
        int24 claim,
        uint128 amountDesired,
        bool zeroForOne
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
        uint128 amountIn,
        uint160 priceLimit
    )
    external
    returns (
        // bytes calldata data
        uint256 amountOut
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

abstract contract ICoverPoolFactory {
    mapping(uint256 => uint256) public feeTierTickSpacing;

    address public owner;
    address public rangePoolFactory;
    address public libraries;

    mapping(bytes32 => address) public poolMapping;
    address[] public poolList;

    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpread,
        uint16 twapLength,
        uint16 auctionLength,
        address pool
    );

    function createCoverPool(
        address fromToken,
        address destToken,
        uint16 fee,
        int16 tickSpread,
        uint16 twapLength,
        uint16 auctionLength
    ) external virtual returns (address book);

    function getCoverPool(
        address fromToken,
        address destToken,
        uint16 fee,
        int16 tickSpread,
        uint16 twapLength,
        uint16 auctionLength
    ) external view virtual returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./IRangePool.sol";

interface ICoverPoolStructs {
    struct GlobalState {
        uint8    unlocked;
        int16    tickSpread; /// @dev this is a integer multiple of the inputPool tickSpacing
        uint16   twapLength; /// @dev number of blocks used for TWAP sampling
        uint16   auctionLength; /// @dev number of blocks to improve price by tickSpread
        int24    latestTick; /// @dev latest updated inputPool price tick
        uint32   genesisBlock; /// @dev reference block for which auctionStart is an offset of
        uint32   lastBlock;    /// @dev last block checked
        uint32   auctionStart; /// @dev last block price reference was updated
        uint32   accumEpoch;
        uint128  liquidityGlobal;
        uint160  latestPrice; /// @dev price of latestTick
        IRangePool inputPool;
    }

    //TODO: adjust nearestTick if someone burns all liquidity from current nearestTick
    struct PoolState {
        uint128 liquidity; /// @dev Liquidity currently active
        uint128 amountInDelta; /// @dev Delta for the current tick auction
        uint128 amountInDeltaMaxClaimed;  /// @dev - needed when users claim and don't burn; should be cleared when users burn liquidity
        uint128 amountOutDeltaMaxClaimed; /// @dev - needed when users claim and don't burn; should be cleared when users burn liquidity
        uint160 price; /// @dev Starting price current
    }

    struct TickNode {
        int24   previousTick;
        int24   nextTick;
        uint32  accumEpochLast; // Used to check for claim updates
    }

    struct Tick {
        int128  liquidityDelta;
        uint128 liquidityDeltaMinus;
        uint128 amountInDeltaMaxStashed;
        uint128 amountOutDeltaMaxStashed;
        Deltas deltas;
    }

    struct Deltas {
        uint128 amountInDelta;     // amt unfilled
        uint128 amountInDeltaMax;  // max unfilled
        uint128 amountOutDelta;    // amt unfilled
        uint128 amountOutDeltaMax; // max unfilled
    }

    // balance needs to be immediately transferred to the position owner
    struct Position {
        uint8   claimCheckpoint; // used to dictate claim state
        uint32  accumEpochLast; // last epoch this position was updated at
        uint128 liquidity; // expected amount to be used not actual
        uint128 liquidityStashed; // what percent of this position is stashed liquidity
        uint128 amountIn; // token amount already claimed; balance
        uint128 amountOut; // necessary for non-custodial positions
        uint160 claimPriceLast; // highest price claimed at
    }

    //TODO: should we have a recipient field here?
    struct AddParams {
        address owner;
        int24 lowerOld;
        int24 lower;
        int24 upper;
        int24 upperOld;
        bool zeroForOne;
        uint128 amount;
    }

    struct RemoveParams {
        address owner;
        int24 lower;
        int24 upper;
        bool zeroForOne;
        uint128 amount;
    }

    struct UpdateParams {
        address owner;
        int24 lower;
        int24 upper;
        int24 claim;
        bool zeroForOne;
        uint128 amount;
    }

    struct ValidateParams {
        int24 lowerOld;
        int24 lower;
        int24 upper;
        int24 upperOld;
        bool zeroForOne;
        uint128 amount;
        GlobalState state;
    }

    //TODO: optimize this struct
    struct SwapCache {
        uint256 price;
        uint256 liquidity;
        uint256 input;
        uint256 inputBoosted;
        uint256 auctionDepth;
        uint256 auctionBoost;
        uint256 amountInDelta;
    }

    struct PositionCache {
        uint160 priceLower;
        uint160 priceUpper;
        Position position;
    }

    struct UpdatePositionCache {
        uint160 priceLower;
        uint160 priceClaim;
        uint160 priceUpper;
        uint160 priceSpread;
        bool removeLower;
        bool removeUpper;
        uint256 amountInFilledMax;    // considers the range covered by each update
        uint256 amountOutUnfilledMax; // considers the range covered by each update
        Tick claimTick;
        TickNode claimTickNode;
        Position position;
        Deltas deltas;
        Deltas finalDeltas;
    }

    struct AccumulateCache {
        int24 nextTickToCross0;
        int24 nextTickToCross1;
        int24 nextTickToAccum0;
        int24 nextTickToAccum1;
        int24 stopTick0;
        int24 stopTick1;
        Deltas deltas0;
        Deltas deltas1;
    }

    struct AccumulateOutputs {
        Deltas deltas;
        TickNode accumTickNode;
        TickNode crossTickNode;
        Tick crossTick;
        Tick accumTick;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title The interface for the Concentrated Liquidity Pool Factory
interface IRangeFactory {
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

interface IRangePool {
    /// @notice This is to be used at hedge pool initialization in case the cardinality is too low for the hedge pool.
    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function tickSpacing() external view returns (int24);

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

    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './DyDxMath.sol';
import '../interfaces/ICoverPoolStructs.sol';
import 'hardhat/console.sol';
//TODO: stash and unstash
//TODO: transfer delta maxes as well in Positions.update()
library Deltas {
    function transfer(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Deltas memory toDeltas,
        uint256 percentInTransfer,
        uint256 percentOutTransfer
    ) external view returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Deltas memory
    ) {
        {
            uint128 amountInDeltaChange = uint128(uint256(fromDeltas.amountInDelta) * percentInTransfer / 1e38);
            fromDeltas.amountInDelta -= amountInDeltaChange;
            toDeltas.amountInDelta += amountInDeltaChange;
        }
        {
            uint128 amountOutDeltaChange = uint128(uint256(fromDeltas.amountOutDelta) * percentOutTransfer / 1e38);
            fromDeltas.amountOutDelta -= amountOutDeltaChange;
            toDeltas.amountOutDelta += amountOutDeltaChange;
        }
        return (fromDeltas, toDeltas);
    }

    function transferMax(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Deltas memory toDeltas,
        uint256 percentInTransfer,
        uint256 percentOutTransfer
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Deltas memory
    ) {
        {
            uint128 amountInDeltaMaxChange = uint128(uint256(fromDeltas.amountInDeltaMax) * percentInTransfer / 1e38);
            if (fromDeltas.amountInDeltaMax > amountInDeltaMaxChange) {
                fromDeltas.amountInDeltaMax -= amountInDeltaMaxChange;
                toDeltas.amountInDeltaMax += amountInDeltaMaxChange;
            } else {
                toDeltas.amountInDeltaMax += fromDeltas.amountInDeltaMax;
                fromDeltas.amountOutDeltaMax = 0;
            }
        }
        {
            uint128 amountOutDeltaMaxChange = uint128(uint256(fromDeltas.amountOutDeltaMax) * percentOutTransfer / 1e38);
            if (fromDeltas.amountOutDeltaMax > amountOutDeltaMaxChange) {
                fromDeltas.amountOutDeltaMax -= amountOutDeltaMaxChange;
                toDeltas.amountOutDeltaMax   += amountOutDeltaMaxChange;
            } else {
                toDeltas.amountOutDeltaMax += fromDeltas.amountOutDeltaMax;
                fromDeltas.amountOutDeltaMax = 0;
            }
        }
        return (fromDeltas, toDeltas);
    }

    function burn(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Deltas memory burnDeltas,
        bool maxOnly
    ) external pure returns (
        ICoverPoolStructs.Deltas memory
    ) {
        if(!maxOnly) {
            fromDeltas.amountInDelta  -= burnDeltas.amountInDelta;
            fromDeltas.amountOutDelta -= burnDeltas.amountOutDelta;
        }
        fromDeltas.amountInDeltaMax  -= burnDeltas.amountInDeltaMax;
        fromDeltas.amountOutDeltaMax -= burnDeltas.amountOutDeltaMax;
        return fromDeltas;
    }

    function from(
        ICoverPoolStructs.Tick memory fromTick,
        ICoverPoolStructs.Deltas memory toDeltas
    ) external pure returns (
        ICoverPoolStructs.Tick memory,
        ICoverPoolStructs.Deltas memory
    ) {
        uint256 percentOnTick = uint256(fromTick.deltas.amountInDeltaMax) * 1e38 / (uint256(fromTick.deltas.amountInDeltaMax) + uint256(fromTick.amountInDeltaMaxStashed));
        {
            uint128 amountInDeltaChange = uint128(uint256(fromTick.deltas.amountInDelta) * percentOnTick / 1e38);
            fromTick.deltas.amountInDelta -= amountInDeltaChange;
            toDeltas.amountInDelta += amountInDeltaChange;
            toDeltas.amountInDeltaMax += fromTick.deltas.amountInDeltaMax;
            fromTick.deltas.amountInDeltaMax = 0;
        }
        percentOnTick = uint256(fromTick.deltas.amountOutDeltaMax) * 1e38 / (uint256(fromTick.deltas.amountOutDeltaMax) + uint256(fromTick.amountOutDeltaMaxStashed));
        {
            uint128 amountOutDeltaChange = uint128(uint256(fromTick.deltas.amountOutDelta) * percentOnTick / 1e38);
            fromTick.deltas.amountOutDelta -= amountOutDeltaChange;
            toDeltas.amountOutDelta += amountOutDeltaChange;
            toDeltas.amountOutDeltaMax += fromTick.deltas.amountOutDeltaMax;
            fromTick.deltas.amountOutDeltaMax = 0;
        }
        return (fromTick, toDeltas);
    }

    function onto(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Tick memory toTick
    ) external view returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Tick memory
    ) {
        if (fromDeltas.amountInDeltaMax > toTick.deltas.amountInDeltaMax) {
            fromDeltas.amountInDeltaMax -= toTick.deltas.amountInDeltaMax;
        } else {
            fromDeltas.amountInDeltaMax = 0;
        }
        if (fromDeltas.amountOutDeltaMax > toTick.deltas.amountOutDeltaMax) {
            fromDeltas.amountOutDeltaMax -= toTick.deltas.amountOutDeltaMax;
        } else {
            fromDeltas.amountOutDeltaMax = 0;
        }
        
        return (fromDeltas, toTick);
    }

    function to(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Tick memory toTick
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Tick memory
    ) {
        toTick.deltas.amountInDelta     += fromDeltas.amountInDelta;
        toTick.deltas.amountInDeltaMax  += fromDeltas.amountInDeltaMax;
        toTick.deltas.amountOutDelta    += fromDeltas.amountOutDeltaMax;
        toTick.deltas.amountOutDeltaMax += fromDeltas.amountOutDeltaMax;
        fromDeltas = ICoverPoolStructs.Deltas(0,0,0,0);
        return (fromDeltas, toTick);
    }

    function stash(
        ICoverPoolStructs.Deltas memory fromDeltas,
        ICoverPoolStructs.Tick memory toTick
    ) external pure returns (
        ICoverPoolStructs.Deltas memory,
        ICoverPoolStructs.Tick memory
    ) {
        toTick.deltas.amountInDelta     += fromDeltas.amountInDelta;
        toTick.amountInDeltaMaxStashed  += fromDeltas.amountInDeltaMax;
        toTick.deltas.amountOutDelta    += fromDeltas.amountOutDelta;
        toTick.amountOutDeltaMaxStashed += fromDeltas.amountOutDeltaMax;
        fromDeltas = ICoverPoolStructs.Deltas(0,0,0,0);
        return (fromDeltas, toTick);
    }

    function unstash(
        ICoverPoolStructs.Tick memory fromTick,
        ICoverPoolStructs.Deltas memory toDeltas
    ) external pure returns (
        ICoverPoolStructs.Tick memory,
        ICoverPoolStructs.Deltas memory
    ) {
        toDeltas.amountInDeltaMax  += fromTick.amountInDeltaMaxStashed;
        toDeltas.amountOutDeltaMax += fromTick.amountOutDeltaMaxStashed;
        
        uint256 totalDeltaMax = uint256(fromTick.amountInDeltaMaxStashed) + uint256(fromTick.deltas.amountInDeltaMax);
        
        if (totalDeltaMax > 0) {
            uint256 percentStashed = uint256(fromTick.amountInDeltaMaxStashed) * 1e38 / totalDeltaMax;
            uint128 amountInDeltaChange = uint128(uint256(fromTick.deltas.amountInDelta) * percentStashed / 1e38);
            fromTick.deltas.amountInDelta -= amountInDeltaChange;
            toDeltas.amountInDelta += amountInDeltaChange;
        }
        
        totalDeltaMax = uint256(fromTick.amountOutDeltaMaxStashed) + uint256(fromTick.deltas.amountOutDeltaMax);
        
        if (totalDeltaMax > 0) {
            uint256 percentStashed = uint256(fromTick.amountOutDeltaMaxStashed) * 1e38 / totalDeltaMax;
            uint128 amountOutDeltaChange = uint128(uint256(fromTick.deltas.amountOutDelta) * percentStashed / 1e38);
            fromTick.deltas.amountOutDelta -= amountOutDeltaChange;
            toDeltas.amountOutDelta += amountOutDeltaChange;
        }

        fromTick.amountInDeltaMaxStashed = 0;
        fromTick.amountOutDeltaMaxStashed = 0;
        return (fromTick, toDeltas);
    }

    function max(
        uint128 liquidity,
        uint160 priceStart,
        uint160 priceEnd,
        bool   isPool0
    ) public pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? DyDxMath.getDy(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
                : DyDxMath.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? DyDxMath.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
                : DyDxMath.getDy(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
        );
    }

    function maxTest(
        uint128 liquidity,
        uint160 priceStart,
        uint160 priceEnd,
        bool   isPool0
    ) public pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? DyDxMath.getDy(
                    liquidity,
                    priceEnd,
                    priceStart,
                    true
                )
                : DyDxMath.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    true
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? DyDxMath.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
                : DyDxMath.getDy(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
        );
    }

    function maxAuction(
        uint128 liquidity,
        uint160 priceStart,
        uint160 priceEnd,
        bool isPool0
    ) external pure returns (
        uint128 amountInDeltaMax,
        uint128 amountOutDeltaMax
    ) {
        amountInDeltaMax = uint128(
            isPool0
                ? DyDxMath.getDy(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
                : DyDxMath.getDx(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
        );
        amountOutDeltaMax = uint128(
            isPool0
                ? DyDxMath.getDx(
                    liquidity,
                    priceStart,
                    priceEnd,
                    false
                )
                : DyDxMath.getDy(
                    liquidity,
                    priceEnd,
                    priceStart,
                    false
                )
        );
    }

    function update(
        ICoverPoolStructs.Deltas memory deltas,
        uint128 amount,
        uint160 priceLower,
        uint160 priceUpper,
        bool   isPool0,
        bool   isAdded
    ) external pure returns (
        ICoverPoolStructs.Deltas memory
    ) {
        // update max deltas
        uint128 amountInDeltaMax; uint128 amountOutDeltaMax;
        if (isPool0) {
            (
                amountInDeltaMax,
                amountOutDeltaMax
            ) = max(amount, priceUpper, priceLower, true);
        } else {
            (
                amountInDeltaMax,
                amountOutDeltaMax
            ) = max(amount, priceLower, priceUpper, false);
        }
        if (isAdded) {
            deltas.amountInDeltaMax  += amountInDeltaMax;
            deltas.amountOutDeltaMax += amountOutDeltaMax;
        } else {
            deltas.amountInDeltaMax  -= amountInDeltaMax;
            deltas.amountOutDeltaMax -= amountOutDeltaMax;
        }
        return deltas;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './FullPrecisionMath.sol';

/// @notice Math library that facilitates ranged liquidity calculations.
library DyDxMath {
    uint256 internal constant Q96 = 0x1000000000000000000000000;

    error PriceOutsideBounds();

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
                dy = FullPrecisionMath.mulDivRoundingUp(liquidity, priceUpper - priceLower, Q96);
            } else {
                dy = FullPrecisionMath.mulDiv(liquidity, priceUpper - priceLower, Q96);
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

    //TODO: debug math for this to validate numbers
    function getLiquidityForAmounts(
        uint256 priceLower,
        uint256 priceUpper,
        uint256 currentPrice,
        uint256 dy,
        uint256 dx
    ) external pure returns (uint256 liquidity) {
        unchecked {
            if (priceUpper == currentPrice) {
                liquidity = FullPrecisionMath.mulDiv(dy, Q96, priceUpper - priceLower);
            } else if (currentPrice == priceLower) {
                liquidity = FullPrecisionMath.mulDiv(
                    dx,
                    FullPrecisionMath.mulDiv(priceLower, priceUpper, Q96),
                    priceUpper - priceLower
                );
            } else {
                revert PriceOutsideBounds();
            }
            /// @dev - price should never be outside of lower and upper
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './TickMath.sol';
import './DyDxMath.sol';
import './TwapOracle.sol';
import '../interfaces/IRangePool.sol';
import '../interfaces/ICoverPoolStructs.sol';
import './Deltas.sol';
import 'hardhat/console.sol';

library Epochs {
    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    error InfiniteTickLoop0(int24);
    error InfiniteTickLoop1(int24);

    function syncLatest(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks0,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks1,
        mapping(int24 => ICoverPoolStructs.TickNode) storage tickNodes,
        ICoverPoolStructs.PoolState memory pool0,
        ICoverPoolStructs.PoolState memory pool1,
        ICoverPoolStructs.GlobalState memory state
    )
        external
        returns (
            ICoverPoolStructs.GlobalState memory,
            ICoverPoolStructs.PoolState memory,
            ICoverPoolStructs.PoolState memory
        )
    {
        // update last block checked
        int24 nextLatestTick = TwapOracle.calculateAverageTick(state.inputPool, state.twapLength);
        state.lastBlock = uint32(block.number);
        // only accumulate if latestTick needs to move
        if (nextLatestTick / (state.tickSpread) == state.latestTick / (state.tickSpread)) {
            return (state, pool0, pool1);
        }
        // console.log("-- START ACCUMULATE LAST BLOCK --");
        state.accumEpoch += 1;

        ICoverPoolStructs.AccumulateCache memory cache = ICoverPoolStructs.AccumulateCache({
            nextTickToCross0: state.latestTick,
            nextTickToCross1: state.latestTick,
            nextTickToAccum0: tickNodes[state.latestTick].previousTick, /// create tick if L > 0 and nextLatestTick != latestTick + tickSpread
            nextTickToAccum1: tickNodes[state.latestTick].nextTick, /// create tick if L > 0 and nextLatestTick != latestTick - tickSpread
            stopTick0: (nextLatestTick > state.latestTick)
                ? state.latestTick - state.tickSpread
                : nextLatestTick,
            stopTick1: (nextLatestTick > state.latestTick)
                ? nextLatestTick
                : state.latestTick + state.tickSpread,
            deltas0: ICoverPoolStructs.Deltas(0, 0, 0, 0), /// @dev - initialize to what was already on the pool
            deltas1: ICoverPoolStructs.Deltas(0, 0, 0, 0) /// @dev - initialize to what was already on the pool
        });

        // loop over ticks0 until stopTick0
        while (true) {
            // rollover deltas from current auction
            (cache, pool0) = _rollover(cache, pool0, true);
            // accumulate to next tick
            ICoverPoolStructs.AccumulateOutputs memory outputs;
            outputs = _accumulate(
                tickNodes[cache.nextTickToAccum0],
                tickNodes[cache.nextTickToCross0],
                ticks0[cache.nextTickToCross0],
                ticks0[cache.nextTickToAccum0],
                cache.deltas0,
                state.accumEpoch,
                true,
                nextLatestTick > state.latestTick
                    ? cache.nextTickToAccum0 < cache.stopTick0
                    : cache.nextTickToAccum0 > cache.stopTick0
            );
            cache.deltas0 = outputs.deltas;
            tickNodes[cache.nextTickToAccum0] = outputs.accumTickNode;
            tickNodes[cache.nextTickToCross0] = outputs.crossTickNode;
            ticks0[cache.nextTickToCross0] = outputs.crossTick;
            ticks0[cache.nextTickToAccum0] = outputs.accumTick;
            //cross otherwise break
            if (cache.nextTickToAccum0 > cache.stopTick0) {
                (pool0.liquidity, cache.nextTickToCross0, cache.nextTickToAccum0) = _cross(
                    tickNodes[cache.nextTickToAccum0],
                    ticks0[cache.nextTickToAccum0].liquidityDelta,
                    cache.nextTickToCross0,
                    cache.nextTickToAccum0,
                    pool0.liquidity,
                    true
                );
                if (cache.nextTickToCross0 == cache.nextTickToAccum0) {
                    revert InfiniteTickLoop0(cache.nextTickToAccum0);
                }
            } else break;
        }
        // pool0 post-loop sync
        {
            /// @dev - place liquidity at stopTick0 for continuation when TWAP moves back down
            if (nextLatestTick > state.latestTick) {
                if (cache.nextTickToAccum0 != cache.stopTick0) {
                    tickNodes[cache.stopTick0] = ICoverPoolStructs.TickNode(
                        cache.nextTickToAccum0,
                        cache.nextTickToCross0,
                        0
                    );
                    tickNodes[cache.nextTickToAccum0].nextTick = cache.stopTick0;
                    tickNodes[cache.nextTickToCross0].previousTick = cache.stopTick0;
                }
            }
            /// @dev - update amount deltas on stopTick
            ICoverPoolStructs.Tick memory stopTick0 = ticks0[cache.stopTick0];
            ICoverPoolStructs.TickNode memory stopTickNode0 = tickNodes[cache.stopTick0];
            (stopTick0) = _stash(
                stopTick0,
                cache,
                pool0.liquidity,
                true
            );
            if (nextLatestTick < state.latestTick) {
                if (cache.nextTickToAccum0 >= cache.stopTick0) {
                    // cross in and activate next auction
                    (pool0.liquidity, cache.nextTickToCross0, cache.nextTickToAccum0) = _cross(
                        tickNodes[cache.nextTickToAccum0],
                        ticks0[cache.nextTickToAccum0].liquidityDelta,
                        cache.nextTickToCross0,
                        cache.nextTickToAccum0,
                        pool0.liquidity,
                        true
                    );
                }
                if (cache.nextTickToCross0 != nextLatestTick) {
                    stopTickNode0 = ICoverPoolStructs.TickNode(
                        cache.nextTickToAccum0,
                        cache.nextTickToCross0,
                        state.accumEpoch
                    );
                    tickNodes[cache.nextTickToAccum0].nextTick = nextLatestTick;
                    tickNodes[cache.nextTickToCross0].previousTick = nextLatestTick;
                }
            }
            stopTick0.liquidityDelta += int128(
                stopTick0.liquidityDeltaMinus
            );
            stopTick0.liquidityDeltaMinus = 0;
            stopTickNode0.accumEpochLast = state.accumEpoch;
            ticks0[cache.stopTick0] = stopTick0;
            tickNodes[cache.stopTick0] = stopTickNode0; 
        }

        // loop over ticks1 until stopTick1
        while (true) {
            // rollover deltas from current auction
            (cache, pool1) = _rollover(cache, pool1, false);
            // accumulate to next tick
            ICoverPoolStructs.AccumulateOutputs memory outputs;
            outputs = _accumulate(
                tickNodes[cache.nextTickToAccum1],
                tickNodes[cache.nextTickToCross1],
                ticks1[cache.nextTickToCross1],
                ticks1[cache.nextTickToAccum1],
                cache.deltas1,
                state.accumEpoch,
                true,
                nextLatestTick > state.latestTick
                    ? cache.nextTickToAccum1 < cache.stopTick1
                    : cache.nextTickToAccum1 > cache.stopTick1
            );
            cache.deltas1 = outputs.deltas;
            tickNodes[cache.nextTickToAccum1] = outputs.accumTickNode;
            tickNodes[cache.nextTickToCross1] = outputs.crossTickNode;
            ticks1[cache.nextTickToCross1] = outputs.crossTick;
            ticks1[cache.nextTickToAccum1] = outputs.accumTick;
            //cross otherwise break
            if (cache.nextTickToAccum1 < cache.stopTick1) {
                (pool1.liquidity, cache.nextTickToCross1, cache.nextTickToAccum1) = _cross(
                    tickNodes[cache.nextTickToAccum1],
                    ticks1[cache.nextTickToAccum1].liquidityDelta,
                    cache.nextTickToCross1,
                    cache.nextTickToAccum1,
                    pool1.liquidity,
                    false
                );
                /// @audit - for testing; remove before production
                if (cache.nextTickToCross1 == cache.nextTickToAccum1)
                    revert InfiniteTickLoop1(cache.nextTickToCross1);
            } else break;
        }
        // post-loop pool1 sync
        {
            /// @dev - place liquidity at stopTick1 for continuation when TWAP moves back up
            if (nextLatestTick < state.latestTick) {
                if (cache.nextTickToAccum1 != cache.stopTick1) {
                    tickNodes[cache.stopTick1] = ICoverPoolStructs.TickNode(
                        cache.nextTickToCross1,
                        cache.nextTickToAccum1,
                        0
                    );
                    tickNodes[cache.nextTickToCross1].nextTick = cache.stopTick1;
                    tickNodes[cache.nextTickToAccum1].previousTick = cache.stopTick1;
                }
            }
            /// @dev - update amount deltas on stopTick
            ICoverPoolStructs.Tick memory stopTick1 = ticks1[cache.stopTick1];
            ICoverPoolStructs.TickNode memory stopTickNode1 = tickNodes[cache.stopTick1];
            (stopTick1) = _stash(
                stopTick1,
                cache,
                pool1.liquidity,
                false
            );
            if (nextLatestTick > state.latestTick) {
                // if this is true we need to insert new latestTick
                if (cache.nextTickToAccum1 != nextLatestTick) {
                    stopTickNode1 = ICoverPoolStructs.TickNode(
                        cache.nextTickToCross1,
                        cache.nextTickToAccum1,
                        state.accumEpoch
                    );
                    tickNodes[cache.nextTickToCross1].nextTick = nextLatestTick;
                    tickNodes[cache.nextTickToAccum1].previousTick = nextLatestTick;
                }
                //TODO: replace nearestTick with priceLimit for swapping...maybe
                if (cache.nextTickToAccum1 <= cache.stopTick1) {
                    (pool1.liquidity, cache.nextTickToCross1, cache.nextTickToAccum1) = _cross(
                        tickNodes[cache.nextTickToAccum1],
                        ticks1[cache.nextTickToAccum1].liquidityDelta,
                        cache.nextTickToCross1,
                        cache.nextTickToAccum1,
                        pool1.liquidity,
                        false
                    );
                }
                pool0.liquidity = 0;
            } else {
                pool1.liquidity = 0;
            }
            stopTick1.liquidityDelta += int128(
                stopTick1.liquidityDeltaMinus
            );
            stopTick1.liquidityDeltaMinus = 0;
            stopTickNode1.accumEpochLast = state.accumEpoch;
            ticks1[cache.stopTick1] = stopTick1;
            tickNodes[cache.stopTick1] = stopTickNode1;
        }
        // set pool price based on nextLatestTick
        pool0.price = TickMath.getSqrtRatioAtTick(nextLatestTick - state.tickSpread);
        pool1.price = TickMath.getSqrtRatioAtTick(nextLatestTick + state.tickSpread);
        // set auction start as an offset of the pool genesis block
        state.auctionStart = uint32(block.number - state.genesisBlock);
        state.latestTick = nextLatestTick;
        state.latestPrice = TickMath.getSqrtRatioAtTick(nextLatestTick);
        // console.log("-- END ACCUMULATE LAST BLOCK --");
        return (state, pool0, pool1);
    }

    function _rollover(
        ICoverPoolStructs.AccumulateCache memory cache,
        ICoverPoolStructs.PoolState memory pool,
        bool isPool0
    ) internal view returns (
        ICoverPoolStructs.AccumulateCache memory,
        ICoverPoolStructs.PoolState memory
    ) {
        if (pool.liquidity == 0) {
            /// @auditor - deltas should be zeroed out here
            return (cache, pool);
        }
        uint160 crossPrice = TickMath.getSqrtRatioAtTick(
            isPool0 ? cache.nextTickToCross0 : cache.nextTickToCross1
        );
        uint160 accumPrice;
        {
            int24 nextTickToAccum;
            if (isPool0) {
                nextTickToAccum = (cache.nextTickToAccum0 < cache.stopTick0)
                    ? cache.stopTick0
                    : cache.nextTickToAccum0;
            } else {
                nextTickToAccum = (cache.nextTickToAccum1 > cache.stopTick1)
                    ? cache.stopTick1
                    : cache.nextTickToAccum1;
            }
            accumPrice = TickMath.getSqrtRatioAtTick(nextTickToAccum);
        }
        uint160 currentPrice = pool.price;
        if (isPool0){
            if (!(pool.price > accumPrice && pool.price < crossPrice)) currentPrice = accumPrice;
        } else{
            if (!(pool.price < accumPrice && pool.price > crossPrice)) currentPrice = accumPrice;
        }

        //handle liquidity rollover
        if (isPool0) {
            // amountIn pool did not receive
            uint128 amountInDelta     = uint128(DyDxMath.getDy(pool.liquidity, currentPrice, crossPrice, true));
            uint128 amountInDeltaMax  = uint128(DyDxMath.getDy(pool.liquidity, accumPrice, crossPrice, false));
            amountInDelta      += pool.amountInDelta;
            amountInDeltaMax   -= pool.amountInDeltaMaxClaimed;
            pool.amountInDelta  = 0;
            pool.amountInDeltaMaxClaimed = 0;

            // amountOut pool has leftover
            uint128 amountOutDelta    = uint128(DyDxMath.getDx(pool.liquidity, currentPrice, crossPrice, false));
            uint128 amountOutDeltaMax = uint128(DyDxMath.getDx(pool.liquidity, accumPrice, crossPrice, false));
            amountOutDeltaMax -= pool.amountOutDeltaMaxClaimed;
            pool.amountOutDeltaMaxClaimed = 0;

            // update cache deltas
            cache.deltas0.amountInDelta += amountInDelta;
            cache.deltas0.amountInDeltaMax += amountInDeltaMax;
            cache.deltas0.amountOutDelta += amountOutDelta;
            cache.deltas0.amountOutDeltaMax += amountOutDeltaMax;
        } else {
            // amountIn pool did not receive
            uint128 amountInDelta = uint128(DyDxMath.getDx(pool.liquidity, crossPrice, currentPrice, false));
            uint128 amountInDeltaMax = uint128(DyDxMath.getDx(pool.liquidity, crossPrice, accumPrice, false));
            amountInDelta      += pool.amountInDelta;
            amountInDeltaMax   -= pool.amountInDeltaMaxClaimed;
            pool.amountInDelta  = 0;
            pool.amountInDeltaMaxClaimed = 0;

            // amountOut pool has leftover
            uint128 amountOutDelta   = uint128(DyDxMath.getDy(pool.liquidity, crossPrice, currentPrice, false));
            uint128 amountOutDeltaMax = uint128(DyDxMath.getDy(pool.liquidity, crossPrice, accumPrice, false));
            amountOutDeltaMax -= pool.amountOutDeltaMaxClaimed;
            pool.amountOutDeltaMaxClaimed = 0;

            // update cache deltas
            cache.deltas1.amountInDelta += amountInDelta + 1;
            cache.deltas1.amountInDeltaMax += amountInDeltaMax;
            cache.deltas1.amountOutDelta += amountOutDelta - 1;
            cache.deltas1.amountOutDeltaMax += amountOutDeltaMax;
        }
        return (cache, pool);
    }

    //TODO: deltas struct so just that can be passed in
    //TODO: accumulate takes Tick and TickNode structs instead of storage pointer
    //TODO: bool stashDeltas might be better to avoid duplicate code
    function _accumulate(
        ICoverPoolStructs.TickNode memory accumTickNode,
        ICoverPoolStructs.TickNode memory crossTickNode,
        ICoverPoolStructs.Tick memory crossTick,
        ICoverPoolStructs.Tick memory accumTick,
        ICoverPoolStructs.Deltas memory deltas,
        uint32 accumEpoch,
        bool removeLiquidity,
        bool updateAccumDeltas
    ) internal view returns (ICoverPoolStructs.AccumulateOutputs memory) {
        
        // update tick epoch
        if (accumTick.liquidityDeltaMinus > 0 && updateAccumDeltas) {
            accumTickNode.accumEpochLast = accumEpoch;
        }

        if (crossTick.amountInDeltaMaxStashed > 0) {
            /// @dev - else we migrate carry deltas onto cache
            // add carry amounts to cache
            (crossTick, deltas) = Deltas.unstash(crossTick, deltas);
        }
        if (updateAccumDeltas) {
            // migrate carry deltas from cache to accum tick
            ICoverPoolStructs.Deltas memory accumDeltas = accumTick.deltas;
            if (accumTick.deltas.amountInDeltaMax > 0) {
                uint256 percentInOnTick = uint256(accumDeltas.amountInDeltaMax) * 1e38 / (deltas.amountInDeltaMax + accumDeltas.amountInDeltaMax);
                uint256 percentOutOnTick = uint256(accumDeltas.amountOutDeltaMax) * 1e38 / (deltas.amountOutDeltaMax + accumDeltas.amountOutDeltaMax);
                (deltas, accumDeltas) = Deltas.transfer(deltas, accumDeltas, percentInOnTick, percentOutOnTick);
                accumTick.deltas = accumDeltas;
                // update delta maxes
                deltas.amountInDeltaMax -= uint128(uint256(deltas.amountInDeltaMax) * (1e38 - percentInOnTick) / 1e38);
                deltas.amountOutDeltaMax -= uint128(uint256(deltas.amountOutDeltaMax) * (1e38 - percentOutOnTick) / 1e38);
            }
        }

        //remove all liquidity from cross tick
        if (removeLiquidity) {
            crossTick.liquidityDelta = 0;
            crossTick.liquidityDeltaMinus = 0;
        }
        // clear out stash
        crossTick.amountInDeltaMaxStashed  = 0;
        crossTick.amountOutDeltaMaxStashed = 0;

        return
            ICoverPoolStructs.AccumulateOutputs(
                deltas,
                accumTickNode,
                crossTickNode,
                crossTick,
                accumTick
            );
    }

    //maybe call ticks on msg.sender to get tick
    function _cross(
        ICoverPoolStructs.TickNode memory accumTickNode,
        int128 liquidityDelta,
        int24 nextTickToCross,
        int24 nextTickToAccum,
        uint128 currentLiquidity,
        bool zeroForOne
    )
        internal
        pure
        returns (
            uint128,
            int24,
            int24
        )
    {
        nextTickToCross = nextTickToAccum;

        if (liquidityDelta > 0) {
            currentLiquidity += uint128(uint128(liquidityDelta));
        } else {
            currentLiquidity -= uint128(uint128(-liquidityDelta));
        }
        if (zeroForOne) {
            nextTickToAccum = accumTickNode.previousTick;
        } else {
            nextTickToAccum = accumTickNode.nextTick;
        }
        return (currentLiquidity, nextTickToCross, nextTickToAccum);
    }

    function _stash(
        ICoverPoolStructs.Tick memory stashTick,
        ICoverPoolStructs.AccumulateCache memory cache,
        uint128 currentLiquidity,
        bool isPool0
    ) internal view returns (ICoverPoolStructs.Tick memory) {
        // return since there is nothing to update
        if (currentLiquidity == 0) return (stashTick);
        // handle amount in delta
        ICoverPoolStructs.Deltas memory deltas = isPool0 ? cache.deltas0 : cache.deltas1;
        if (deltas.amountInDeltaMax > 0) {
            (deltas, stashTick.deltas) = Deltas.transfer(deltas, stashTick.deltas, 1e38, 1e38);
            (deltas, stashTick) = Deltas.onto(deltas, stashTick);
            (deltas, stashTick) = Deltas.stash(deltas, stashTick);
        }
        
        return (stashTick);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Math library that facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision.
library FullPrecisionMath {
    error MaxUintExceeded();

    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256 result) {
        return _mulDiv(a, b, denominator);
    }

    // @dev no underflow or overflow checks
    function divRoundingUp(uint256 x, uint256 y) external pure returns (uint256 z) {
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
                if (result >= type(uint256).max) revert MaxUintExceeded();
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './TickMath.sol';
import './Ticks.sol';
import './Deltas.sol';
import '../interfaces/ICoverPoolStructs.sol';
import './FullPrecisionMath.sol';
import './DyDxMath.sol';
import 'hardhat/console.sol';


/// @notice Position management library for ranged liquidity.
library Positions {
    error InvalidClaimTick();
    error LiquidityOverflow();
    error WrongTickClaimedAt();
    error PositionNotUpdated();
    error UpdatePositionFirstAt(int24, int24);
    error InvalidLowerTick();
    error InvalidUpperTick();
    error InvalidPositionAmount();
    error InvalidPositionBoundsOrder();
    error InvalidPositionBoundsTwap();
    error NotEnoughPositionLiquidity();
    error NotImplementedYet();

    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    using Positions for mapping(int24 => ICoverPoolStructs.Tick);

    function validate(ICoverPoolStructs.ValidateParams memory params)
        external
        pure
        returns (
            int24,
            int24,
            int24,
            int24,
            uint128,
            uint256 liquidityMinted
        )
    {
        if (params.lower < TickMath.MIN_TICK) revert InvalidLowerTick();
        if (params.upper > TickMath.MAX_TICK) revert InvalidUpperTick();
        if (params.lower % int24(params.state.tickSpread) != 0) revert InvalidLowerTick();
        if (params.upper % int24(params.state.tickSpread) != 0) revert InvalidUpperTick();
        if (params.amount == 0) revert InvalidPositionAmount();
        if (params.lower >= params.upper || params.lowerOld >= params.upperOld)
            revert InvalidPositionBoundsOrder();
        if (params.zeroForOne) {
            if (params.lower >= params.state.latestTick) revert InvalidPositionBoundsTwap();
        } else {
            if (params.upper <= params.state.latestTick) revert InvalidPositionBoundsTwap();
        }
        uint256 priceLower = uint256(TickMath.getSqrtRatioAtTick(params.lower));
        uint256 priceUpper = uint256(TickMath.getSqrtRatioAtTick(params.upper));

        liquidityMinted = DyDxMath.getLiquidityForAmounts(
            priceLower,
            priceUpper,
            params.zeroForOne ? priceLower : priceUpper,
            params.zeroForOne ? 0 : uint256(params.amount),
            params.zeroForOne ? uint256(params.amount) : 0
        );

        // handle partial mints
        if (params.zeroForOne) {
            if (params.upper >= params.state.latestTick) {
                params.upper = params.state.latestTick - int24(params.state.tickSpread);
                params.upperOld = params.state.latestTick;
                uint256 priceNewUpper = TickMath.getSqrtRatioAtTick(params.upper);
                params.amount -= uint128(
                    DyDxMath.getDx(liquidityMinted, priceNewUpper, priceUpper, false)
                );
                priceUpper = priceNewUpper;
            }
        } else {
            if (params.lower <= params.state.latestTick) {
                params.lower = params.state.latestTick + int24(params.state.tickSpread);
                params.lowerOld = params.state.latestTick;
                uint256 priceNewLower = TickMath.getSqrtRatioAtTick(params.lower);
                params.amount -= uint128(
                    DyDxMath.getDy(liquidityMinted, priceLower, priceNewLower, false)
                );
                priceLower = priceNewLower;
            }
        }

        if (liquidityMinted > uint128(type(int128).max)) revert LiquidityOverflow();
        if (params.lower == params.upper) revert InvalidPositionBoundsTwap();

        return (
            params.lowerOld,
            params.lower,
            params.upper,
            params.upperOld,
            params.amount,
            liquidityMinted
        );
    }

    function add(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        mapping(int24 => ICoverPoolStructs.TickNode) storage tickNodes,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.AddParams memory params
    ) external returns (uint128, ICoverPoolStructs.GlobalState memory) {
        //TODO: dilute amountDeltas when adding liquidity
        ICoverPoolStructs.PositionCache memory cache = ICoverPoolStructs.PositionCache({
            position: positions[params.owner][params.lower][params.upper],
            priceLower: TickMath.getSqrtRatioAtTick(params.lower),
            priceUpper: TickMath.getSqrtRatioAtTick(params.upper)
        });
        /// call if claim != lower and liquidity being added
        /// initialize new position
        if (params.amount == 0) return (0, state);
        if (cache.position.liquidity == 0) {
            cache.position.accumEpochLast = state.accumEpoch;
        } else {
            /// safety check...might be unnecessary given the user is forced to update()
            if (
                params.zeroForOne
                    ? state.latestTick < params.upper ||
                        tickNodes[params.upper].accumEpochLast > cache.position.accumEpochLast
                    : state.latestTick > params.lower ||
                        tickNodes[params.lower].accumEpochLast > cache.position.accumEpochLast
            ) {
                revert WrongTickClaimedAt();
            }
        }
        //TODO: if cPL is > 0, revert
        
        // add liquidity to ticks
        state = Ticks.insert(
            ticks,
            tickNodes,
            state,
            params.lowerOld,
            params.lower,
            params.upperOld,
            params.upper,
            uint128(params.amount),
            params.zeroForOne
        );

        {
            // update max deltas
            ICoverPoolStructs.Deltas memory tickDeltas = ticks[params.zeroForOne ? params.lower : params.upper].deltas;
            tickDeltas = Deltas.update(tickDeltas, params.amount, cache.priceLower, cache.priceUpper, params.zeroForOne, true);
            ticks[params.zeroForOne ? params.lower : params.upper].deltas = tickDeltas;
        }

        cache.position.liquidity += uint128(params.amount);

        positions[params.owner][params.lower][params.upper] = cache.position;

        return (params.amount, state);
    }

    function remove(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        mapping(int24 => ICoverPoolStructs.TickNode) storage tickNodes,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.RemoveParams memory params
    ) external returns (uint128, ICoverPoolStructs.GlobalState memory) {
        //TODO: dilute amountDeltas when adding liquidity
        ICoverPoolStructs.PositionCache memory cache = ICoverPoolStructs.PositionCache({
            position: positions[params.owner][params.lower][params.upper],
            priceLower: TickMath.getSqrtRatioAtTick(params.lower),
            priceUpper: TickMath.getSqrtRatioAtTick(params.upper)
        });
        if (params.amount == 0) return (0, state);
        if (params.amount > cache.position.liquidity) {
            revert NotEnoughPositionLiquidity();
        } else {
            /// @dev - validate user can remove from position using this function
            if (
                params.zeroForOne
                    ? state.latestTick < params.upper ||
                        tickNodes[params.upper].accumEpochLast > cache.position.accumEpochLast
                    : state.latestTick > params.lower ||
                        tickNodes[params.lower].accumEpochLast > cache.position.accumEpochLast
            ) {
                revert WrongTickClaimedAt();
            }
        }

        Ticks.remove(
            ticks,
            tickNodes,
            state,
            params.lower,
            params.upper,
            params.amount,
            0,
            params.zeroForOne,
            true,
            true
        );

        {
            // update max deltas
            ICoverPoolStructs.Deltas memory tickDeltas = ticks[params.zeroForOne ? params.lower : params.upper].deltas;
            tickDeltas = Deltas.update(tickDeltas, params.amount, cache.priceLower, cache.priceUpper, params.zeroForOne, false);
            ticks[params.zeroForOne ? params.lower : params.upper].deltas = tickDeltas;
        }

        cache.position.amountOut += uint128(
            params.zeroForOne
                ? DyDxMath.getDx(params.amount, cache.priceLower, cache.priceUpper, false)
                : DyDxMath.getDy(params.amount, cache.priceLower, cache.priceUpper, false)
        );

        cache.position.liquidity -= uint128(params.amount);
        positions[params.owner][params.lower][params.upper] = cache.position;

        return (params.amount, state);
    }

    //TODO: pass pool as memory and save pool changes using return value
    function update(
        mapping(address => mapping(int24 => mapping(int24 => ICoverPoolStructs.Position)))
            storage positions,
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        mapping(int24 => ICoverPoolStructs.TickNode) storage tickNodes,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.PoolState storage pool,
        ICoverPoolStructs.UpdateParams memory params
    )
        external
        returns (
            ICoverPoolStructs.GlobalState memory
        )
    {
        ICoverPoolStructs.UpdatePositionCache memory cache = ICoverPoolStructs.UpdatePositionCache({
            position: positions[params.owner][params.lower][params.upper],
            priceLower: TickMath.getSqrtRatioAtTick(params.lower),
            priceClaim: TickMath.getSqrtRatioAtTick(params.claim),
            priceUpper: TickMath.getSqrtRatioAtTick(params.upper),
            priceSpread: TickMath.getSqrtRatioAtTick(params.zeroForOne ? state.latestTick - state.tickSpread 
                                                                       : state.latestTick + state.tickSpread),
            amountInFilledMax: 0,
            amountOutUnfilledMax: 0,
            claimTick: ticks[params.claim],
            claimTickNode: tickNodes[params.claim],
            removeLower: true,
            removeUpper: true,
            deltas: ICoverPoolStructs.Deltas(0,0,0,0),
            finalDeltas: ICoverPoolStructs.Deltas(0,0,0,0)
        });

        // validate position liquidity
        if (params.amount > cache.position.liquidity) revert NotEnoughPositionLiquidity();
        if (cache.position.liquidity == 0) {
            return state;
        }
        // early return if no update
        if (
            (
                params.zeroForOne
                    ? params.claim == params.upper && cache.priceUpper != pool.price
                    : params.claim == params.lower && cache.priceLower != pool.price /// @dev - if pool price is start tick, set claimPriceLast to next tick crossed
            ) && params.claim == state.latestTick
        ) { if (cache.position.claimPriceLast == pool.price) return state; } /// @dev - nothing to update if pool price hasn't moved
        
        // claim tick sanity checks
        else if (
            cache.position.claimPriceLast > 0 &&
            (
                params.zeroForOne
                    ? cache.position.claimPriceLast < cache.priceClaim
                    : cache.position.claimPriceLast > cache.priceClaim
            ) && params.claim != state.latestTick
        ) revert InvalidClaimTick(); /// @dev - wrong claim tick
        if (params.claim < params.lower || params.claim > params.upper) revert InvalidClaimTick();

        // validate claim tick
        if (params.claim == (params.zeroForOne ? params.lower : params.upper)) {
             if (cache.claimTickNode.accumEpochLast <= cache.position.accumEpochLast)
                revert WrongTickClaimedAt();
            cache.position.liquidityStashed = 0;
            params.zeroForOne ? cache.removeLower = false : cache.removeUpper = false;
        } else {
            // zero fill or partial fill
            uint32 claimTickNextAccumEpoch = params.zeroForOne
                ? tickNodes[cache.claimTickNode.previousTick].accumEpochLast
                : tickNodes[cache.claimTickNode.nextTick].accumEpochLast;
            ///@dev - next accumEpoch should not be greater
            if (claimTickNextAccumEpoch > cache.position.accumEpochLast)
                revert WrongTickClaimedAt();

            // check if liquidity removal required
            if (params.amount > 0) {
                /// @dev - check if liquidity removal required
                cache.removeLower = params.zeroForOne
                    ? true
                    : tickNodes[cache.claimTickNode.nextTick].accumEpochLast <=
                        cache.position.accumEpochLast;
                cache.removeUpper = params.zeroForOne
                    ? tickNodes[cache.claimTickNode.previousTick].accumEpochLast <=
                        cache.position.accumEpochLast
                    : true;
            }
        }
        if (params.claim != params.upper && params.claim != params.lower) {
            // check accumEpochLast on claim tick
            if (tickNodes[params.claim].accumEpochLast <= cache.position.accumEpochLast)
                revert WrongTickClaimedAt();
            // prevent position overwriting at claim tick
            if (params.zeroForOne) {
                if (positions[params.owner][params.lower][params.claim].liquidity > 0) {
                    revert UpdatePositionFirstAt(params.lower, params.claim);
                }
            } else {
                if (positions[params.owner][params.claim][params.upper].liquidity > 0) {
                    revert UpdatePositionFirstAt(params.claim, params.upper);
                }
            }
            // 100% of liquidity is stashed
            //TODO: work through cases with this
            cache.position.liquidityStashed = cache.position.liquidity;
            /// @auditor - user cannot add liquidity if auction is active; checked for in Positions.validate()
        }
        // transfer deltas into cache
        if (params.claim == (params.zeroForOne ? params.lower : params.upper)) {
            (cache.claimTick, cache.deltas) = Deltas.from(cache.claimTick, cache.deltas);
        } else {
            /// @dev - deltas are applied once per each tick claimed at
            /// @dev - deltas should never be applied if position is not crossed into
            // check if tick already claimed at
            bool applyDeltas = (cache.position.claimPriceLast == 0
                               && (params.claim != (params.zeroForOne ? params.upper : params.lower)))
                               || (params.zeroForOne ? cache.position.claimPriceLast > cache.priceClaim
                                                     : cache.position.claimPriceLast < cache.priceClaim && cache.position.claimPriceLast != 0);
            if (applyDeltas) {
                (cache.claimTick, cache.deltas) = Deltas.unstash(cache.claimTick, cache.deltas);
            }
        } /// @dev - deltas transfer from claim tick are replaced after applying changes

        // delta check complete - update CPL for new position
        if(cache.position.claimPriceLast == 0) {
            cache.position.claimPriceLast = (params.zeroForOne ? cache.priceUpper 
                                                               : cache.priceLower);
        } else if (cache.position.claimPriceLast != (params.zeroForOne ? cache.priceUpper 
                                                                       : cache.priceLower)
                   && cache.priceClaim > cache.priceSpread ) {
            // section 1 - complete previous auction claim
            {
                // amounts claimed on this update
                uint128 amountInFilledMax; uint128 amountOutUnfilledMax;
                (
                    amountInFilledMax,
                    amountOutUnfilledMax
                ) = Deltas.maxAuction(
                    cache.position.liquidity,
                    cache.position.claimPriceLast,
                    params.zeroForOne ? cache.priceUpper
                                      : cache.priceLower,
                    params.zeroForOne
                );
                //TODO: modify delta max on claim tick and lower : upper tick
                cache.amountInFilledMax    += amountInFilledMax;
                cache.amountOutUnfilledMax += amountOutUnfilledMax;
            }
            // move price to next tick in sequence for section 2
            cache.position.claimPriceLast  = params.zeroForOne ? TickMath.getSqrtRatioAtTick(params.upper - state.tickSpread)
                                                               : TickMath.getSqrtRatioAtTick(params.lower + state.tickSpread);
        }
        // section 2 - position start up to claim tick
        if (cache.position.claimPriceLast != cache.priceClaim) {
            // calculate if we at least cover one full tick
            uint128 amountInFilledMax; uint128 amountOutUnfilledMax;
            (
                amountInFilledMax,
                amountOutUnfilledMax
            ) = Deltas.max(
                cache.position.liquidity,
                cache.position.claimPriceLast,
                cache.priceClaim,
                params.zeroForOne
            );
            cache.amountInFilledMax += amountInFilledMax;
            cache.amountOutUnfilledMax += amountOutUnfilledMax;
            params.zeroForOne ? ticks[params.lower].deltas.amountOutDeltaMax -= amountOutUnfilledMax
                              : ticks[params.upper].deltas.amountOutDeltaMax -= amountOutUnfilledMax;
        } else if (params.zeroForOne ? cache.priceClaim > cache.position.claimPriceLast 
                                     : cache.priceClaim < cache.position.claimPriceLast) {
            /// @dev - second claim within current auction
            cache.priceClaim = pool.price;
        }
        // section 3 - current auction unfilled section
        if (params.claim == state.latestTick 
            && params.claim != (params.zeroForOne ? params.lower : params.upper)) {
            // if auction is live
            if (params.amount > 0) {
                // remove if burn
                uint128 amountOutRemoved = uint128(
                    params.zeroForOne
                        ? DyDxMath.getDx(params.amount, pool.price, cache.priceClaim, false)
                        : DyDxMath.getDy(params.amount, cache.priceClaim, pool.price, false)
                );
                cache.position.amountOut += amountOutRemoved;
                // modify max deltas
                params.zeroForOne ? ticks[params.lower].deltas.amountOutDeltaMax -= amountOutRemoved
                                  : ticks[params.upper].deltas.amountOutDeltaMax -= amountOutRemoved;
                uint128 amountInOmitted = uint128(
                    params.zeroForOne
                        ? DyDxMath.getDy(params.amount, pool.price, cache.priceClaim, false)
                        : DyDxMath.getDx(params.amount, cache.priceClaim, pool.price, false)
                );
                params.zeroForOne ? ticks[params.lower].deltas.amountInDeltaMax -= amountInOmitted
                                  : ticks[params.upper].deltas.amountInDeltaMax -= amountInOmitted;
                //TODO: update amountInDelta on pool at end
                //TODO: update amounIn/OutDeltaMax on lower : upper tick for section 3
            }
            // section 4 - current auction filled section
            {
                // amounts claimed on this update
                uint128 amountInFilledMax; uint128 amountOutUnfilledMax;
                (
                    amountInFilledMax,
                    amountOutUnfilledMax
                ) = Deltas.maxAuction(
                    cache.position.liquidity,
                    (params.zeroForOne ? cache.position.claimPriceLast < cache.priceClaim
                                       : cache.position.claimPriceLast > cache.priceClaim) 
                                            ? cache.position.claimPriceLast 
                                            : cache.priceSpread,
                    pool.price,
                    params.zeroForOne
                );
                uint256 poolAmountInDeltaChange = uint256(cache.position.liquidity) * 1e38 / uint256(pool.liquidity) * uint256(pool.amountInDelta) / 1e38;   
                
                cache.position.amountIn += amountInFilledMax - uint128(poolAmountInDeltaChange);
                pool.amountInDelta -= uint128(poolAmountInDeltaChange);
                cache.finalDeltas.amountInDeltaMax += amountInFilledMax;
                cache.finalDeltas.amountOutDeltaMax += amountOutUnfilledMax;
                /// @dev - record how much delta max was claimed
                if (params.amount < cache.position.liquidity) {
                    (
                        amountInFilledMax,
                        amountOutUnfilledMax
                    ) = Deltas.maxAuction(
                        cache.position.liquidity - params.amount,
                        (params.zeroForOne ? cache.position.claimPriceLast < cache.priceClaim
                                        : cache.position.claimPriceLast > cache.priceClaim) 
                                                ? cache.position.claimPriceLast 
                                                : cache.priceSpread,
                        pool.price,
                        params.zeroForOne
                    );
                    pool.amountInDeltaMaxClaimed  += amountInFilledMax;
                    pool.amountOutDeltaMaxClaimed += amountOutUnfilledMax;
                }
            }
            if (params.amount > 0 /// @ dev - if removing L and second claim on same tick
                && (params.zeroForOne ? cache.position.claimPriceLast < cache.priceClaim
                                        : cache.position.claimPriceLast > cache.priceClaim)) {
                    // reduce delta max claimed based on liquidity removed
                    uint128 amountInMaxClaimedBefore; uint128 amountOutMaxClaimedBefore;
                    (
                        amountInMaxClaimedBefore,
                        amountOutMaxClaimedBefore
                    ) = Deltas.maxAuction(
                        params.amount,
                        cache.priceSpread,
                        cache.position.claimPriceLast,
                        params.zeroForOne
                    );
                    pool.amountInDeltaMaxClaimed  -= amountInMaxClaimedBefore;
                    pool.amountOutDeltaMaxClaimed -= amountOutMaxClaimedBefore;
            }
            // modify claim price for section 5
            cache.priceClaim = cache.priceSpread;
        }
        // section 5 - burned liquidity past claim tick
        {
            if (params.amount > 0) {
                // update max deltas based on liquidity removed
                uint128 amountInOmitted; uint128 amountOutRemoved;
                (
                    amountInOmitted,
                    amountOutRemoved
                ) = Deltas.maxTest(
                    params.amount,
                    cache.priceClaim,
                    params.zeroForOne ? cache.priceLower
                                      : cache.priceUpper,
                    params.zeroForOne
                );
                cache.position.amountOut += amountOutRemoved;
                if (params.claim != (params.zeroForOne ? params.lower : params.upper)) {
                    params.zeroForOne ? ticks[params.lower].deltas.amountInDeltaMax -= amountInOmitted
                                      : ticks[params.upper].deltas.amountInDeltaMax -= amountInOmitted;
                    params.zeroForOne ? ticks[params.lower].deltas.amountOutDeltaMax -= amountOutRemoved
                                      : ticks[params.upper].deltas.amountOutDeltaMax -= amountOutRemoved;
                }      
            }
        }
        // adjust based on deltas
        // calculate deltas applied
        uint256 percentInDelta; uint256 percentOutDelta;
        if(cache.deltas.amountInDeltaMax > 0) {
            percentInDelta = uint256(cache.amountInFilledMax) * 1e38 / uint256(cache.deltas.amountInDeltaMax);
            if (cache.deltas.amountOutDeltaMax > 0) {
                percentOutDelta = uint256(cache.amountOutUnfilledMax) * 1e38 / uint256(cache.deltas.amountOutDeltaMax);
            }
        }
        (cache.deltas, cache.finalDeltas) = Deltas.transfer(cache.deltas, cache.finalDeltas, percentInDelta, percentOutDelta);
        (cache.deltas, cache.finalDeltas) = Deltas.transferMax(cache.deltas, cache.finalDeltas, percentInDelta, percentOutDelta);
        console.log('delta max check 1');
        console.log(ticks[-40].deltas.amountInDeltaMax);
        // apply deltas and add to position
        if (cache.amountInFilledMax >= cache.finalDeltas.amountInDelta)
            cache.position.amountIn  += uint128(cache.amountInFilledMax) - cache.finalDeltas.amountInDelta;
        cache.position.amountOut += cache.finalDeltas.amountOutDelta;
        // add remaining deltas cached back to claim tick
        // cache.deltas, cache.claimTick) = Deltas.stash(cache.deltas, cache.claimTick, 1e38, 1e38);
        if (params.claim != (params.zeroForOne ? params.lower : params.upper)) {
            // burn deltas on final tick of position
            ICoverPoolStructs.Tick memory updateTick = ticks[params.zeroForOne ? params.lower : params.upper];
            console.log('delta max check 2');
        console.log(ticks[-40].deltas.amountInDeltaMax);
            (updateTick.deltas) = Deltas.burn(updateTick.deltas, cache.finalDeltas, true);
            console.log('delta max check 3');
        console.log(ticks[-40].deltas.amountInDeltaMax);
            ticks[params.zeroForOne ? params.lower : params.upper] = updateTick;
            console.log('delta max check 4');
            console.log(cache.deltas.amountOutDeltaMax);
        console.log(ticks[-40].deltas.amountInDeltaMax);
            //TODO: handle partial stashed and partial on tick
            if (params.claim == (params.zeroForOne ? params.upper : params.lower)) {
                (cache.deltas, cache.claimTick) = Deltas.to(cache.deltas, cache.claimTick);
            } else {
                (cache.deltas, cache.claimTick) = Deltas.stash(cache.deltas, cache.claimTick);
            }
            
        } else {
            (cache.deltas, cache.claimTick) = Deltas.to(cache.deltas, cache.claimTick);
        }
        if (cache.position.amountIn > 0) {
            cache.position.amountIn -= 1;
            //TODO: maybe take one off delta applied?
        }

        // save claim tick and tick node
        ticks[params.claim] = cache.claimTick;
        tickNodes[params.claim] = cache.claimTickNode;
        // update pool liquidity
        if (state.latestTick == params.claim
            && params.claim != (params.zeroForOne ? params.lower : params.upper)) 
            pool.liquidity -= params.amount;
        
        /// @dev - mark last claim price
        cache.priceClaim = TickMath.getSqrtRatioAtTick(params.claim);
        cache.position.claimPriceLast = (params.claim == state.latestTick)
            ? pool.price
            : cache.priceClaim;
        /// @dev - if tick 0% filled, set CPL to latestTick
        if (pool.price == cache.priceSpread) cache.position.claimPriceLast = cache.priceClaim;
        /// @dev - if tick 100% filled, set CPL to next tick to unlock
        if (pool.price == cache.priceClaim && params.claim == state.latestTick) cache.position.claimPriceLast = cache.priceClaim;
        /// @dev - prior to Ticks.remove() so we don't overwrite liquidity delta changes
        // if burn or second mint
        //TODO: handle claim of current auction and second mint
        if ((params.amount > 0)) {
            if (params.claim != (params.zeroForOne ? params.upper : params.lower)) {
                //TODO: switch to being the current price if necessary
                params.zeroForOne ? cache.removeUpper = false : cache.removeLower = false;
            }
            Ticks.remove(
                ticks,
                tickNodes,
                state,
                params.zeroForOne ? params.lower : params.claim,
                params.zeroForOne ? params.claim : params.upper,
                uint128(uint128(params.amount)),
                cache.position.liquidityStashed,
                params.zeroForOne,
                cache.removeLower,
                cache.removeUpper
            );
            cache.position.liquidity -= uint128(params.amount);
        }
        if (params.zeroForOne ? params.claim != params.upper 
                              : params.claim != params.lower) {
            // clear out position
            delete positions[params.owner][params.lower][params.upper];
        } 
        if (cache.position.liquidity == 0) {
            cache.position.accumEpochLast = 0;
            cache.position.claimPriceLast = 0;
            cache.position.claimCheckpoint = 0;
        }
        params.zeroForOne
            ? positions[params.owner][params.lower][params.claim] = cache.position
            : positions[params.owner][params.claim][params.upper] = cache.position;

        return state;
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
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick - equivalent to getSqrtRatioAtTick(MAX_TICK).
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    error TickOutOfBounds();
    error PriceOutOfBounds();
    error WaitUntilEnoughObservations();

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
            // This divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // We then downcast because we know the result always fits within 160 bits due to our tick input constraint.
            // We round up in the division so getTickAtSqrtRatio of the output price is always consistent.
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    function validatePrice(uint160 price) external pure {
        if (price < MIN_SQRT_RATIO || price >= MAX_SQRT_RATIO) {
            revert PriceOutOfBounds();
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio.
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96.
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio.
    function _getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // Second inequality must be < because the price can never reach the price at the max tick.
        if (sqrtPriceX96 < MIN_SQRT_RATIO || sqrtPriceX96 >= MAX_SQRT_RATIO)
            revert PriceOutOfBounds();
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

        tick = tickLow == tickHi ? tickLow : _getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
            ? tickHi
            : tickLow;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import './TickMath.sol';
import '../interfaces/ICoverPoolStructs.sol';
import '../utils/CoverPoolErrors.sol';
import './FullPrecisionMath.sol';
import './DyDxMath.sol';
import './TwapOracle.sol';
import 'hardhat/console.sol';

/// @notice Tick management library for ranged liquidity.
library Ticks {
    //TODO: alphabetize errors
    error NotImplementedYet();
    error InvalidLatestTick();
    error InfiniteTickLoop0(int24);
    error InfiniteTickLoop1(int24);
    error LiquidityOverflow();
    error WrongTickOrder();
    error WrongTickLowerRange();
    error WrongTickUpperRange();
    error WrongTickLowerOld();
    error WrongTickUpperOld();
    error NoLiquidityToRollover();
    error AmountInDeltaNeutral();
    error AmountOutDeltaNeutral();

    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    using Ticks for mapping(int24 => ICoverPoolStructs.Tick);

    function quote(
        bool zeroForOne,
        uint160 priceLimit,
        ICoverPoolStructs.GlobalState memory state,
        ICoverPoolStructs.SwapCache memory cache
    ) external view returns (ICoverPoolStructs.SwapCache memory, uint256 amountOut) {
        if (zeroForOne ? priceLimit >= cache.price : priceLimit <= cache.price || cache.price == 0 || cache.input == 0)
            return (cache, 0);
        uint256 nextTickPrice = state.latestPrice;
        uint256 nextPrice = nextTickPrice;

        // determine input boost from tick auction
        cache.auctionBoost = ((cache.auctionDepth <= state.auctionLength) ? cache.auctionDepth : state.auctionLength) * 1e14 / state.auctionLength * uint16(state.tickSpread);
        cache.inputBoosted = cache.input * (1e18 + cache.auctionBoost) / 1e18;

        if (zeroForOne) {
            // Trading token 0 (x) for token 1 (y).
            // price  is decreasing.
            if (priceLimit > nextPrice) {
                // stop at price limit
                nextPrice = priceLimit;
            }
            uint256 maxDx = DyDxMath.getDx(cache.liquidity, nextPrice, cache.price, false);
            // check if we can increase input to account for auction
            // if we can't, subtract amount inputted at the end
            // store amountInDelta in pool either way
            // putting in less either way
            if (cache.inputBoosted <= maxDx) {
                // We can swap within the current range.
                uint256 liquidityPadded = cache.liquidity << 96;
                // calculate price after swap
                uint256 newPrice = FullPrecisionMath.mulDivRoundingUp(
                    liquidityPadded,
                    cache.price,
                    liquidityPadded + cache.price * cache.inputBoosted
                );
                console.log('newPrice', newPrice);
                console.log('old price', cache.price);
                console.log(cache.liquidity);
                console.log(cache.price);
                console.log(cache.input);
                /// @auditor - check tests to see if we need overflow handle
                // if (!(nextTickPrice <= newPrice && newPrice < cache.price)) {
                //     console.log('overflow check');
                //     newPrice = uint160(FullPrecisionMath.divRoundingUp(liquidityPadded, liquidityPadded / cache.price + cache.input));
                // }
                amountOut = DyDxMath.getDy(cache.liquidity, newPrice, cache.price, false);
                cache.price = uint160(newPrice);
                cache.amountInDelta = maxDx - maxDx * cache.input / cache.inputBoosted;
                cache.input = 0;
            } else if (maxDx > 0) {
                amountOut = DyDxMath.getDy(cache.liquidity, nextPrice, cache.price, false);
                cache.price = nextPrice;
                cache.amountInDelta = maxDx - maxDx * cache.input / cache.inputBoosted;
                cache.input -= maxDx * cache.input / cache.inputBoosted; /// @dev - convert back to input amount
            }
        } else {
            // Price is increasing.
            if (priceLimit < nextPrice) {
                // stop at price limit
                nextPrice = priceLimit;
            }
            uint256 maxDy = DyDxMath.getDy(cache.liquidity, cache.price, nextPrice, false);
            if (cache.inputBoosted <= maxDy) {
                // We can swap within the current range.
                // Calculate new price after swap: ΔP = Δy/L.
                uint256 newPrice = cache.price +
                    FullPrecisionMath.mulDiv(cache.inputBoosted, Q96, cache.liquidity);
                console.log('newPrice', newPrice);
                // Calculate output of swap
                amountOut = DyDxMath.getDx(cache.liquidity, cache.price, newPrice, false);
                cache.price = newPrice;
                cache.amountInDelta = cache.inputBoosted - cache.input;
                cache.input = 0;
            } else if (maxDy > 0) {
                amountOut = DyDxMath.getDx(cache.liquidity, cache.price, nextTickPrice, false);
                cache.price = nextPrice;
                cache.amountInDelta = maxDy - maxDy * cache.input / cache.inputBoosted;
                cache.input -= maxDy * cache.input / cache.inputBoosted + 1; /// @dev - handles rounding errors with amountInDelta
            }
        }
        return (cache, amountOut);
    }

    function initialize(
        mapping(int24 => ICoverPoolStructs.TickNode) storage tickNodes,
        ICoverPoolStructs.PoolState storage pool0,
        ICoverPoolStructs.PoolState storage pool1,
        ICoverPoolStructs.GlobalState memory state
    ) external returns (ICoverPoolStructs.GlobalState memory) {
        /// @dev - assume latestTick is not MIN_TICK or MAX_TICK
        // if (latestTick == TickMath.MIN_TICK || latestTick == TickMath.MAX_TICK) revert InvalidLatestTick();
        if (state.unlocked == 0) {
            (state.unlocked, state.latestTick) = TwapOracle.initializePoolObservations(
                state.inputPool,
                state.twapLength
            );
            if (state.unlocked == 1) {

                state.latestTick = (state.latestTick / int24(state.tickSpread)) * int24(state.tickSpread);
                state.latestPrice = TickMath.getSqrtRatioAtTick(state.latestTick);
                state.auctionStart = uint32(block.number - state.genesisBlock);
                state.accumEpoch = 1;

                tickNodes[state.latestTick] = ICoverPoolStructs.TickNode(
                    TickMath.MIN_TICK,
                    TickMath.MAX_TICK,
                    state.accumEpoch
                );
                tickNodes[TickMath.MIN_TICK] = ICoverPoolStructs.TickNode(
                    TickMath.MIN_TICK,
                    state.latestTick,
                    state.accumEpoch
                );
                tickNodes[TickMath.MAX_TICK] = ICoverPoolStructs.TickNode(
                    state.latestTick,
                    TickMath.MAX_TICK,
                    state.accumEpoch
                );

                pool0.price = TickMath.getSqrtRatioAtTick(state.latestTick - state.tickSpread);
                pool1.price = TickMath.getSqrtRatioAtTick(state.latestTick + state.tickSpread);
            }
        }
        return state;
    }

    //TODO: ALL TICKS NEED TO BE CREATED WITH
    function insert(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        mapping(int24 => ICoverPoolStructs.TickNode) storage tickNodes,
        ICoverPoolStructs.GlobalState memory state,
        int24 lowerOld,
        int24 lower,
        int24 upperOld,
        int24 upper,
        uint128 amount,
        bool isPool0
    ) public returns (ICoverPoolStructs.GlobalState memory) {
        /// @auditor - validation of ticks is in Positions.validate
        // load into memory to reduce storage reads/writes
        if (amount > uint128(type(int128).max)) revert LiquidityOverflow();
        if ((uint128(type(int128).max) - state.liquidityGlobal) < amount)
            revert LiquidityOverflow();
        ICoverPoolStructs.Tick memory tickLower = ticks[lower];
        ICoverPoolStructs.Tick memory tickUpper = ticks[upper];
        ICoverPoolStructs.TickNode memory tickNodeLower = tickNodes[lower];
        ICoverPoolStructs.TickNode memory tickNodeUpper = tickNodes[upper];
        /// @auditor lower or upper = latestTick -> should not be possible
        /// @auditor - should we check overflow/underflow of lower and upper ticks?
        /// @auditor - we need to be able to deprecate pools if necessary; so not much reason to do overflow/underflow check
        if (tickNodeLower.nextTick != tickNodeLower.previousTick) {
            // tick exists
            if (isPool0) {
                tickLower.liquidityDelta -= int128(amount);
                tickLower.liquidityDeltaMinus += amount;
            } else {
                tickLower.liquidityDelta += int128(amount);
            }
        } else {
            // tick does not exist
            if (isPool0) {
                tickLower = ICoverPoolStructs.Tick(-int128(amount), amount, 0, 0, ICoverPoolStructs.Deltas(0, 0, 0, 0));
            } else {
                tickLower = ICoverPoolStructs.Tick(int128(amount), 0, 0, 0, ICoverPoolStructs.Deltas(0, 0, 0, 0));
            }
            /// @auditor new latestTick being in between lowerOld and lower handled by Positions.validate()
            int24 oldNextTick = tickNodes[lowerOld].nextTick;
            if (upper < oldNextTick) {
                oldNextTick = upper;
            }
            /// @auditor - don't set previous tick so upper can be initialized
            else {
                tickNodes[oldNextTick].previousTick = lower;
            }

            if (lowerOld >= lower || lower >= oldNextTick) {
                revert WrongTickLowerOld();
            }
            tickNodeLower = ICoverPoolStructs.TickNode(lowerOld, oldNextTick, 0);
            tickNodes[lowerOld].nextTick = lower;
        }

        /// @auditor -> is it safe to add to liquidityDelta w/o Tick struct initialization
        if (tickNodeUpper.nextTick != tickNodeUpper.previousTick) {
            if (isPool0) {
                tickUpper.liquidityDelta += int128(amount);
            } else {
                tickUpper.liquidityDelta -= int128(amount);
                tickUpper.liquidityDeltaMinus += amount;
            }
        } else {
            if (isPool0) {
                tickUpper = ICoverPoolStructs.Tick(int128(amount), 0, 0, 0, ICoverPoolStructs.Deltas(0, 0, 0, 0));
            } else {
                tickUpper = ICoverPoolStructs.Tick(-int128(amount), amount, 0, 0, ICoverPoolStructs.Deltas(0, 0, 0, 0));
            }
            int24 oldPrevTick = tickNodes[upperOld].previousTick;
            if (lower > oldPrevTick) oldPrevTick = lower;
            //TODO: handle new TWAP being in between upperOld and upper
            /// @dev - if nextTick == previousTick this tick node is uninitialized
            if (
                tickNodes[upperOld].nextTick == tickNodes[upperOld].previousTick ||
                upperOld <= upper ||
                upper <= oldPrevTick
            ) {
                revert WrongTickUpperOld();
            }
            tickNodeUpper = ICoverPoolStructs.TickNode(oldPrevTick, upperOld, 0);
            tickNodes[oldPrevTick].nextTick = upper;
            tickNodes[upperOld].previousTick = upper;
        }
        ticks[lower] = tickLower;
        ticks[upper] = tickUpper;
        tickNodes[lower] = tickNodeLower;
        tickNodes[upper] = tickNodeUpper;

        return state;
    }

    function remove(
        mapping(int24 => ICoverPoolStructs.Tick) storage ticks,
        mapping(int24 => ICoverPoolStructs.TickNode) storage tickNodes,
        ICoverPoolStructs.GlobalState memory state,
        int24 lower,
        int24 upper,
        uint128 amount,
        uint128 amountStashed,
        bool isPool0,
        bool removeLower,
        bool removeUpper
    ) external {
        //TODO: we can only delete is lower != MIN_TICK or latestTick and all values are 0
        // bool deleteLowerTick = false; bool deleteUpperTick = false;

        //TODO: we can only delete is upper != MAX_TICK or latestTick and all values are 0
        //TODO: can be handled by using inactiveLiquidity == 0 and activeLiquidity == 0
        {
            ICoverPoolStructs.Tick memory tickLower = ticks[lower];
            if (removeLower) {
                if (isPool0) {
                    tickLower.liquidityDelta += int128(amount);
                    tickLower.liquidityDeltaMinus -= amount;
                } else {
                    tickLower.liquidityDelta -= int128(amount);
                }
            }
            /// @dev - not deleting ticks just yet
            ticks[lower] = tickLower;
        }

        //TODO: can be handled using inactiveLiquidity and activeLiquidity == 0

        //TODO: we need to know what tick they're claiming from
        //TODO: that is the tick that should have liquidity values modified
        //TODO: keep unchecked block?
        {
            ICoverPoolStructs.Tick memory tickUpper = ticks[upper];
            if (removeUpper) {
                if (isPool0) {
                    tickUpper.liquidityDelta -= int128(amount);
                } else {
                    tickUpper.liquidityDelta += int128(amount);
                    tickUpper.liquidityDeltaMinus -= amount;
                }
            }
            ticks[upper] = tickUpper;
        }

        // if (deleteLowerTick) {
        //     // Delete lower tick.
        //     int24 previous = tickNodes[lower].previousTick;
        //     int24 next     = tickNodes[lower].nextTick;
        //     if(next != upper || !deleteUpperTick) {
        //         tickNodes[previous].nextTick = next;
        //         tickNodes[next].previousTick = previous;
        //     } else {
        //         int24 upperNextTick = tickNodes[upper].nextTick;
        //         tickNodes[tickNodes[lower].previousTick].nextTick = upperNextTick;
        //         tickNodes[upperNextTick].previousTick = previous;
        //     }
        // }
        // if (deleteUpperTick) {
        //     // Delete upper tick.
        //     int24 previous = tickNodes[upper].previousTick;
        //     int24 next     = tickNodes[upper].nextTick;

        //     if(previous != lower || !deleteLowerTick) {
        //         tickNodes[previous].nextTick = next;
        //         tickNodes[next].previousTick = previous;
        //     } else {
        //         int24 lowerPrevTick = tickNodes[lower].previousTick;
        //         tickNodes[lowerPrevTick].nextTick = next;
        //         tickNodes[next].previousTick = lowerPrevTick;
        //     }
        // }
        /// @dev - we can never delete ticks due to amount deltas
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IRangeFactory.sol';
import '../interfaces/IRangePool.sol';
import './TickMath.sol';

// will the blockTimestamp be consistent across the entire block?
library TwapOracle {
    error WaitUntilBelowMaxTick();
    error WaitUntilAboveMinTick();
    // @AUDIT - set for Ethereum mainnet; adjust for Arbitrum mainnet
    uint16 public constant blockTime = 12;
    /// @dev - adjust for deployment
    uint32 public constant startBlock = 0;

    // @dev increase pool observations if not sufficient
    // @dev must be deterministic since called externally
    function initializePoolObservations(IRangePool pool, uint16 twapLength)
        external
        returns (uint8 initializable, int24 startingTick)
    {
        if (!_isPoolObservationsEnough(pool, twapLength)) {
            _increaseV3Observations(address(pool), twapLength);
            return (0, 0);
        }
        return (1, _calculateAverageTick(pool, twapLength));
    }

    function calculateAverageTick(IRangePool pool, uint16 twapLength)
        external
        view
        returns (int24 averageTick)
    {
        return _calculateAverageTick(pool, twapLength);
    }

    function _calculateAverageTick(IRangePool pool, uint16 twapLength)
        internal
        view
        returns (int24 averageTick)
    {
        uint32[] memory secondsAgos = new uint32[](3);
        secondsAgos[0] = 0;
        secondsAgos[1] = blockTime * twapLength;
        (int56[] memory tickCumulatives, ) = pool.observe(secondsAgos);
        averageTick = int24(((tickCumulatives[0] - tickCumulatives[1]) / (int32(secondsAgos[1]))));
        if (averageTick == TickMath.MAX_TICK) revert WaitUntilBelowMaxTick();
        if (averageTick == TickMath.MIN_TICK) revert WaitUntilAboveMinTick();
    }

    function isPoolObservationsEnough(address pool, uint16 twapLength)
        external
        view
        returns (bool)
    {
        return _isPoolObservationsEnough(IRangePool(pool), twapLength);
    }

    function _isPoolObservationsEnough(IRangePool pool, uint16 twapLength)
        internal
        view
        returns (bool)
    {
        (, , , uint16 observationsCount, , , ) = pool.slot0();
        return observationsCount >= twapLength;
    }

    function _increaseV3Observations(address pool, uint16 twapLength) internal {
        IRangePool(pool).increaseObservationCardinalityNext(twapLength);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

abstract contract CoverPoolErrors {
    error Locked();
    error InvalidToken();
    error InvalidPosition();
    error InvalidSwapFee();
    error InvalidTickSpread();
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

abstract contract CoverTicksErrors {
    error WrongTickLowerRange();
    error WrongTickUpperRange();
    error WrongTickLowerOrder();
    error WrongTickUpperOrder();
    error WrongTickClaimedAt();
}

abstract contract CoverMiscErrors {
    // to be removed before production
    error NotImplementedYet();
}

abstract contract CoverPositionErrors {
    error NotEnoughPositionLiquidity();
    error InvalidClaimTick();
}

abstract contract CoverPoolFactoryErrors {
    error IdenticalTokenAddresses();
    error PoolAlreadyExists();
    error FeeTierNotSupported();
}

abstract contract CoverTransferErrors {
    error TransferFailed(address from, address dest);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '../utils/CoverPoolErrors.sol';
import 'hardhat/console.sol';

abstract contract SafeTransfers is CoverTransferErrors {
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
    function _transferIn(address token, uint256 amount) internal virtual returns (uint256) {
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