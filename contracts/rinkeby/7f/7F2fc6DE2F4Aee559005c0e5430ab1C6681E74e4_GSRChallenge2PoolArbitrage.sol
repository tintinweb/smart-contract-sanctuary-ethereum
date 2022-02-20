//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

contract GSRChallenge2PoolArbitrage {
    /// @notice enable user to get max arbitrage between 2 pools using getPrice2 function
    /// @param _token0 address of token0
    /// @param _token1 address of token1
    /// @param _router0 address of Dex0 router
    /// @param _router1 address of Dex1 router
    /// @param _amount0In input amount of token0, amount can have implications on the slippage
    function maxArbitragePossible(
        address _token0,
        address _token1,
        address _router0,
        address _router1,
        uint256 _amount0In
    )
        public
        view
        returns (
            uint256 price0,
            uint256 price1,
            uint256 arb
        )
    {
        // Implement code to calculate the maximum amount of arbitrage that can be traded for
        require(
            _token0 != address(0) && _token1 != address(0),
            "invalid_token_address"
        );
        require(_amount0In > 0, "invalid_input_amount");
        require(
            _router0 != address(0) && _router1 != address(0),
            "invalid_router_address"
        );
        price0 = _getPrice2(_token0, _token1, _router0, _amount0In);
        price1 = _getPrice2(_token0, _token1, _router1, _amount0In);
        require(price0 > 0 && price1 > 0, "invalid_prices");
        arb = price0 >= price1 ? (price0 - price1) : (price1 - price0);
    }

    /// @notice enable user to calculate max arbitrage among 3 tokens from 3 liquidity pools within 1 Dex
    /// @param _token0 address of token0
    /// @param _token1 address of token1
    /// @param _token2 address of token3
    /// @param _router address of Dex router
    /// @param amountIn input amount of token0, amount can have implications on the slippage
    function maxArbitrage3Tokens(
        address _token0,
        address _token1,
        address _token2,
        address _router,
        uint256 amountIn
    ) external view returns (uint256 arbProfit, uint256 newToken0Balance) {
        require(
            _token0 != address(0) &&
                _token1 != address(0) &&
                _token2 != address(0),
            "invalid_token_address"
        );
        require(amountIn > 0, "invalid_input_amount");
        require(_router != address(0), "invalid_router_address");
        IUniswapV2Router02 router = IUniswapV2Router02(_router);

        address[] memory path0 = new address[](2);
        path0[0] = _token0;
        path0[1] = _token1;
        address[] memory path1 = new address[](2);
        path1[0] = _token1;
        path1[1] = _token2;
        address[] memory path2 = new address[](2);
        path2[0] = _token2;
        path2[1] = _token0;

        // getAmountsOut returns amountIn and amountOut
        uint256[] memory result0 = router.getAmountsOut(amountIn, path0);
        uint256[] memory result1 = router.getAmountsOut(result0[1], path1);
        uint256[] memory result2 = router.getAmountsOut(result1[1], path2);

        newToken0Balance = result2[1];
        if (newToken0Balance > amountIn) {
            arbProfit = newToken0Balance - amountIn;
        } else {
            arbProfit = 0;
        }
    }

    ///@notice enable user to execute arbitrage of a token pair between 2 Dexes
    /// @param _token0 address of token0
    /// @param _token1 address of token1
    /// @param _router0 address of Dex0 router
    /// @param _router1 address of Dex1 router
    /// @param _amount0 input amount of token0, amount can have implications on the slippage
    function executeArb(
        address _token0,
        address _token1,
        address _router0,
        address _router1,
        uint256 _amount0
    ) external returns (uint256 amountOut, uint256 arbProfit) {
        require(
            _token0 != address(0) && _token1 != address(0),
            "invalid_token_address"
        );
        require(_amount0 > 0, "invalid_input_amount");
        require(
            _router0 != address(0) && _router1 != address(0),
            "invalid_router_address"
        );
        (uint256 price0, uint256 price1, ) = maxArbitragePossible(
            _token0,
            _token1,
            _router0,
            _router1,
            _amount0
        );
        uint256 arbitrage = (price0 > price1)
            ? ((price0 - price1) * 100) / price0
            : ((price1 - price0) * 100) / price1;
        // to check that price differential is greater than 1%
        require(arbitrage > 1, "no_arbitrage");
        uint256 balBeforeArb = ERC20(_token0).balanceOf(address(this));
        require(balBeforeArb >= _amount0, "insufficient_fund");
        // amount of token1 from swap
        uint256 _amount1;
        if (price0 > price1) {
            // sell token0 and swap for token1 at dex0
            _swapToken(_token0, _token1, _amount0, _router0);
            _amount1 = ERC20(_token1).balanceOf(address(this));
            // sell token1 and swap for token0 at dex1
            _swapToken(_token1, _token0, _amount1, _router1);
            amountOut = ERC20(_token0).balanceOf(address(this));
        } else if (price0 < price1) {
            _swapToken(_token0, _token1, _amount0, _router1);
            _amount1 = ERC20(_token1).balanceOf(address(this));
            _swapToken(_token1, _token0, _amount1, _router0);
            amountOut = ERC20(_token0).balanceOf(address(this));
        }
        // revert if amountOut is less than balBeforeArb
        require(amountOut >= balBeforeArb, "not_profitable");
        arbProfit = amountOut - _amount0;
    }

    ///@notice enable user to withdraw all token balance in the contract
    function withdrawToken(address token, address to) external {
        require(token != address(0), "invalid_token_address");
        require(to != address(0), "invalid_recipient_address");
        require(
            ERC20(token).transfer(to, ERC20(token).balanceOf(address(this))),
            "transfer_failed"
        );
    }

    ///@notice view only function that enables user to get token balance in this contract
    function getTokenBalance(address token) external view returns (uint256) {
        require(token != address(0), "invalid_token_address");
        return ERC20(token).balanceOf(address(this));
    }

    ///@notice enable user to deposit tokens to the contract
    function _depositToken(address token, uint256 amount) external {
        require(token != address(0), "invalid_token_address");
        require(amount > 0, "invalid_deposit_amount");
        require(
            ERC20(token).transferFrom(msg.sender, address(this), amount),
            "transfer_failed"
        );
    }

    ///@notice user can swap between 2 ERC20 tokens through router.swapExactTokensForTokens() function
    function _swapToken(
        address token0,
        address token1,
        uint256 amountIn,
        address routerAdd
    ) internal returns (uint256 amount1) {
        require(amountIn > 0, "invalid_amount");
        require(routerAdd != address(0), "invalid_address");
        require(
            token0 != token1 && token0 != address(0) && token1 != address(0),
            "invalid_token_address"
        );
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = token1;
        IUniswapV2Router02 exchange = IUniswapV2Router02(routerAdd);
        ERC20(token0).approve(routerAdd, amountIn);
        exchange.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp + 60
        );
        amount1 = ERC20(token1).balanceOf(address(this));
        require(amount1 > 0, "swap_failed");
    }

    ///@notice get liquidity pool address from factory contract
    function _getPairAddress(
        address _token0,
        address _token1,
        address _factory
    ) internal view returns (address pool) {
        require(
            _token0 != _token1 &&
                _token0 != address(0) &&
                _token1 != address(0),
            "invalid_token_address"
        );
        require(_factory != address(0), "invalid_factory_address");
        IUniswapV2Factory factory = IUniswapV2Factory(_factory);
        pool = factory.getPair(_token0, _token1);
        require(pool != address(0), "invalid_pool_address");
        return pool;
    }

    ///@notice get exchange rate for token0/token1 from Pair reserves, but this is not used
    function _getPrice(
        address _token0,
        address _token1,
        address factory
    ) internal view returns (uint256) {
        require(
            _token0 != address(0) &&
                _token1 != address(0) &&
                _token0 != _token1,
            "invalid_token_address"
        );
        require(factory != address(0), "invalid_factory_address");

        address pairAddress = _getPairAddress(_token0, _token1, factory);
        require(pairAddress != address(0), "invalid_pool_address");
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        (uint256 res0, uint256 res1, ) = pair.getReserves();
        // 8 decimals
        uint256 PRICE_DECIMALS = 1e18;
        return (res0 * PRICE_DECIMALS) / res1;
    }

    /// @notice get exchange rate for token0/token1 from router.getAmountsOut() function
    function _getPrice2(
        address _token0,
        address _token1,
        address routerAdd,
        uint256 amountIn
    ) internal view returns (uint256) {
        require(
            _token0 != address(0) &&
                _token1 != address(0) &&
                _token0 != _token1,
            "invalid_token_address"
        );
        require(routerAdd != address(0), "invalid_factory_address");
        require(amountIn > 0, "invalid_input_amount");

        IUniswapV2Router02 router = IUniswapV2Router02(routerAdd);
        address[] memory path = new address[](2);
        path[0] = _token0;
        path[1] = _token1;
        uint256[] memory result = router.getAmountsOut(amountIn, path);
        uint256 PRICE_DECIMALS = 1e18;
        return (result[1] * PRICE_DECIMALS) / result[0];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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