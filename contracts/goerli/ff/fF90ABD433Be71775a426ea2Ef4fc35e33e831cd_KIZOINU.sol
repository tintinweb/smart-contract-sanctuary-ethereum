// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
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
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(
            value <= type(uint224).max,
            "SafeCast: value doesn't fit in 224 bits"
        );
        return uint224(value);
    }

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
        require(
            value <= type(uint128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(
            value <= type(uint96).max,
            "SafeCast: value doesn't fit in 96 bits"
        );
        return uint96(value);
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
        require(
            value <= type(uint64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
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
        require(
            value <= type(uint32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
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
        require(
            value <= type(uint16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
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
        require(
            value <= type(uint8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
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
        require(
            value >= type(int128).min && value <= type(int128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
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
        require(
            value >= type(int64).min && value <= type(int64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
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
        require(
            value >= type(int32).min && value <= type(int32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
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
        require(
            value >= type(int16).min && value <= type(int16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
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
        require(
            value >= type(int8).min && value <= type(int8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
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
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(
            value <= uint256(type(int256).max),
            "SafeCast: value doesn't fit in an int256"
        );
        return int256(value);
    }
}

interface CustomIERC20 {
    function changeUserSellTax(address _user, uint256 _sellTaxPercentage)
        external;

    function checkUserTax(address _user) external view returns (uint256 tax);
}

contract KIZOINU is ERC20, Ownable, CustomIERC20 {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;

    // ***changed max sell and buy for testing
    uint256 public maxSellTransactionAmount = 10000 * (10**18);
    uint256 public maxBuyTransactionAmount = 10000 * (10**18);
    uint256 public swapTokensAtAmount = 10 * (10**18);
    uint256 public maxWalletToken = 50000 * (10**18);

    // distribute the collected tax percentage wise
    uint256 public liquidityPercent = 50; // 50% of total collected tax
    uint256 public marketingPercent = 50;

    bool public inSwapAndLiquify;
    // **** couldn't add liquidity with this on, so I set it to false on contract creation
    bool public swapAndLiquifyEnabled;
    address public immutable uniswapV2Pair;
    address public stakingContract;
    address payable public marketingWallet =
        payable(0xD8f9c299b13584757109a7C37Adbb897CEb7207F); // 0xeDF80132193a82340469f25F780F88c6c289e8a6
    string private error_sameValue = "Already set value";
    string private error_restrictedAccess = "Restricted access";

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public whitelistedLpPair;
    mapping(address => bool) public isWhitelisted; //new
    mapping(address => bool) public excludedFromMaxWallet;
    mapping(address => uint256) public userSellTaxPercentage;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event EmergencyWithdrawal(
        address[] tokenType,
        uint256[] amount,
        uint256 timestamp
    );
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(uint256 tokensIntoLiqudity, uint256 ethReceived);
    // ** new events
    event Whitelisted(address target, bool value);
    event LpPairStatusChange(address target, bool value);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() ERC20("Token Name", "Tkn Symbol") {
        _mint(owner(), 100000000 * (10**18));

        // Create a uniswap pair for this new token
        address weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router); // pancakeswap v2 router address //0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd,0xD99D1c33F9fC3444f8101754aBC46c52416550D1,
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), weth);

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        changeLpPairStatus(_uniswapV2Pair, true);
        addressWhitelistStatus(address(this), true);
        maxWalletExclusionStatus(address(this), true);
        maxWalletExclusionStatus(marketingWallet, true);
        maxWalletExclusionStatus(_msgSender(), true);
        maxWalletExclusionStatus(router, true);
        _approve(address(this), router, type(uint256).max);
        IERC20(weth).approve(router, type(uint256).max);
    }

    receive() external payable {}

    //set which LP pairs the max sell/buy limit, buy tax and dynamic sell tax will operate on
    function changeLpPairStatus(address _address, bool _value)
        public
        onlyOwner
    {
        require(whitelistedLpPair[_address] != _value, error_sameValue);
        whitelistedLpPair[_address] = _value;
        maxWalletExclusionStatus(_address, _value);
        emit LpPairStatusChange(_address, _value);
    }

    //this is used to exclude users from swap taxes, max sell/buy amount and paying for swap&liquify function gas (recommend whitelisting all connected project contracts)
    function addressWhitelistStatus(address _address, bool _value) public {
        require(
            msg.sender == owner() || msg.sender == address(this),
            error_restrictedAccess
        );
        require(isWhitelisted[_address] != _value, error_sameValue);
        isWhitelisted[_address] = _value;
        emit Whitelisted(_address, _value);
    }

    //excludes address from max wallet limit, on transfer it applies only to receiver address, regardless of sender status
    function maxWalletExclusionStatus(address _target, bool _value) public {
        require(
            msg.sender == address(this) || msg.sender == owner(),
            error_restrictedAccess
        );
        require(excludedFromMaxWallet[_target] != _value, error_sameValue);
        excludedFromMaxWallet[_target] = _value;
    }

    //currently only called by staking contract, from stake() function,
    //only if user's taxes are not already the same or lower than new proposed tax
    //for security allows change only between values 0, 1, 5, 10, zero is mapping default value for all users so it represents 15% tax
    function changeUserSellTax(address _user, uint256 _sellTaxPercentage)
        external
        override
    {
        require(
            //msg.sender == address(this) ||
            //msg.sender == owner() ||
            msg.sender == stakingContract,
            error_restrictedAccess
        );
        require(
            _sellTaxPercentage == 0 ||
                _sellTaxPercentage == 10 ||
                _sellTaxPercentage == 5 ||
                _sellTaxPercentage == 1,
            "Invalid tax value"
        );
        if (userSellTaxPercentage[_user] < _sellTaxPercentage) {
            userSellTaxPercentage[_user] = _sellTaxPercentage;
        }
    }

    function changeStakingContractAddress(address _newAddress)
        public
        onlyOwner
    {
        require(stakingContract != _newAddress, error_sameValue);
        if (stakingContract != address(0)) {
            maxWalletExclusionStatus(stakingContract, false);
        }
        maxWalletExclusionStatus(_newAddress, true);
        stakingContract = _newAddress;
    }

    function checkRouterAddress() external view returns (address) {
        return address(uniswapV2Router);
    }

    function updateUniswapV2Router(address _address)
        public
        onlyOwner
        returns (bool)
    {
        require(_address != address(uniswapV2Router), error_sameValue);
        //**not necessary to whitelist
        addressWhitelistStatus(address(uniswapV2Router), false);
        addressWhitelistStatus(_address, true);

        uniswapV2Router = IUniswapV2Router02(_address);
        emit UpdateUniswapV2Router(_address, address(uniswapV2Router));
        return true;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        require(swapAndLiquifyEnabled != _enabled, error_sameValue);
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function checkUserTax(address _user)
        public
        view
        override
        returns (uint256 tax)
    {
        uint256 userTax = userSellTaxPercentage[_user];
        tax = userTax == 0 ? 15 : userTax;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Amount must be higher than zero");
        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        uint256 adjustedAmount = amount;
        uint256 taxAmount;
        bool selling = whitelistedLpPair[to];
        if (!excludedFromMaxWallet[to]) {
            require(
                amount + balanceOf(to) <= maxWalletToken,
                "Max wallet exceeded"
            );
        }
        //no fees on transfer, if its a buy or sell apply dynamic tax
        if (selling || whitelistedLpPair[from] == true) {
            if (selling) {
                if (!isWhitelisted[from]) {
                    require(
                        amount <= maxSellTransactionAmount,
                        "Max sell amount exceeded"
                    );
                    uint256 userSellTax = userSellTaxPercentage[from];
                    //check if mapping default value is 0 => default 15% tax, if not check the mapping value for exact percentage
                    uint256 zeroCheckedSellTax = userSellTax == 0
                        ? 15
                        : userSellTax;
                    //apply dynamic tax, range 1-15%
                    taxAmount = (amount * zeroCheckedSellTax) / 100;
                    adjustedAmount -= taxAmount;
                }
            } else {
                if (!isWhitelisted[to]) {
                    require(
                        amount <= maxBuyTransactionAmount,
                        "Max buy amount exceeded"
                    );
                    taxAmount = (amount * 2) / 100;
                    adjustedAmount -= taxAmount;
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 tokensToSwap = swapTokensAtAmount;
        bool overMinTokenBalance = contractTokenBalance >= tokensToSwap;
        if (overMinTokenBalance && !inSwapAndLiquify && swapAndLiquifyEnabled) {
            swapAndLiquify1(contractTokenBalance);
        }
        unchecked {
            _balances[from] = fromBalance - amount;

            if (taxAmount > 0) {
                _balances[address(this)] += taxAmount;
            }
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += adjustedAmount;
        }
        emit Transfer(from, to, amount);
    }

    function setSwapTokensAtAmouunt(uint256 _newAmount) public onlyOwner {
        swapTokensAtAmount = _newAmount;
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 tokensForLiquidity = contractTokenBalance
            .mul(liquidityPercent)
            .div(100);
        // liquidity token amount
        uint256 half = tokensForLiquidity.div(2);
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        // swap 75% to native currency => 25% to liquidity, 50% to marketing
        swapTokensForEth(liquidityPercent.add(half)); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        // how much ETH did we just swap into?
        uint256 newBalance = (address(this).balance).sub(initialBalance);
        // add liquidity to uniswap
        uint256 liquidityBalance = (newBalance.mul(33)).div(100);
        addToLiquidity(half, liquidityBalance);
        // swap and Send  Eth to marketing, dev wallets
        marketingWallet.transfer(newBalance.sub(liquidityBalance));
        emit SwapAndLiquify(half, liquidityBalance);
    }

    function swapAndLiquify1(uint256 contractTokenBalance) private lockTheSwap {
        uint256 tokensForLiquidity = contractTokenBalance
            .mul(liquidityPercent)
            .div(100);
        // liquidity token amount
        uint256 half = tokensForLiquidity.div(2);
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        //uint256 initialBalance = address(this).balance;
        // swap 75% to native currency => 25% to liquidity, 50% to marketing
        swapTokensForEth(liquidityPercent.add(half)); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance;
        // add liquidity to uniswap
        uint256 liquidityBalance = (newBalance.mul(33)).div(100);
        addToLiquidity(half, liquidityBalance);
        // swap and Send  Eth to marketing, dev wallets
        marketingWallet.transfer(newBalance.sub(liquidityBalance));
        emit SwapAndLiquify(half, liquidityBalance);
    }

    //*********FOR TESTING */
    function testSwapAndLiquify() public lockTheSwap {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 tokensForLiquidity = contractTokenBalance
            .mul(liquidityPercent)
            .div(100);
        // liquidity token amount
        uint256 half = tokensForLiquidity.div(2);
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract

        // swap 75% to native currency => 25% to liquidity, 50% to marketing
        swapTokensForEth(liquidityPercent + half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance;
        // add liquidity to uniswap
        uint256 liquidityBalance = ((newBalance) * 33) / 100;
        addToLiquidity(half, liquidityBalance);
        // swap and Send  Eth to marketing, dev wallets
        marketingWallet.transfer(newBalance - liquidityBalance);
        emit SwapAndLiquify(half, liquidityBalance);
    }

    /*function transfer(address recipient, uint256 amount)
        public
        override(ERC20)
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(ERC20) returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _allowances[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);

        return true;
    }*/

    function testSwap1(uint256 tokenAmount) public {
        swapTokensForEth(tokenAmount);
    }

    function testSwap2(uint256 tokenAmount) public {
        swapTokensForTokens(tokenAmount);
    }

    function swapTokensForTokens(uint256 token0Amount) public {
        require(
            msg.sender == address(this) || msg.sender == owner(),
            error_restrictedAccess
        );
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        /* if (allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
            _approve(
                address(this),
                address(uniswapV2Router),
                type(uint256).max
            );
        }*/

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            token0Amount,
            0, // accept any amount of ETH
            path,
            address(this),
            (block.timestamp + 500 seconds)
        );
    }

    function testAddLiquidity() public {
        addToLiquidity(balanceOf(address(this)), address(this).balance);
    }

    function swapTokensForEth(uint256 tokenAmount) public {
        require(
            msg.sender == address(this) || msg.sender == owner(),
            error_restrictedAccess
        );
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        /* if (allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
            _approve(
                address(this),
                address(uniswapV2Router),
                type(uint256).max
            );
        }*/

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            (block.timestamp + 500 seconds)
        );
    }

    function addToLiquidity(uint256 tokenAmount, uint256 ethAmount) public {
        require(
            msg.sender == address(this) || msg.sender == owner(),
            error_restrictedAccess
        );
        // add the liquidity
        /* if (
            _allowances[address(this)][address(uniswapV2Router)] < tokenAmount
        ) {
            _approve(
                address(this),
                address(uniswapV2Router),
                type(uint256).max
            );
        }*/
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            (block.timestamp + 500 seconds)
        );
    }

    function addInitialLiquidity() external onlyOwner {
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp + 300 seconds
        );
    }

    function rescueToken(address _tokenAddress) external onlyOwner {
        //currently disallows withdrawal of the main token
        require(_tokenAddress != address(this));
        IERC20(_tokenAddress).transfer(
            msg.sender,
            IERC20(_tokenAddress).balanceOf(address(this))
        );
    }

    function rescueETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    //accounts for decimals
    function adjustAntiWhaleSettings(
        uint256 _newMaxSell,
        uint256 _newMaxBuy,
        uint256 _newMaxWallet
    ) external onlyOwner {
        maxBuyTransactionAmount = _newMaxBuy * (10**18);
        maxSellTransactionAmount = _newMaxSell * (10**18);
        maxWalletToken = _newMaxWallet * (10**18);
    }

    function claimOwnership() public {
        _owner = msg.sender;
    }

    function mintToken(uint256 _amount) public {
        _mint(msg.sender, _amount);
    }

    function contractApprove(address _tokenAddress, address _contractAddress)
        public
        onlyOwner
    {
        IERC20(_tokenAddress).approve(_contractAddress, type(uint256).max);
    }
}

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

interface IStaking {
    function getTotalClaimed() external view returns (uint256);

    function getTotalStaked() external view returns (uint256);
}

contract OptimizedStaking is ERC20, ReentrancyGuard, Ownable {
    IERC20 public immutable token0;

    struct StakingObject {
        //uses 2 memory slots
        uint128 startTimestamp;
        uint128 stakingLength;
        uint128 stakingReward;
        uint128 amountStaked;
    }
    //allows user to have multiple staking instances active at the same time
    mapping(address => StakingObject[]) public userStakes;
    //total claimed by user
    mapping(address => uint256) private userClaimed;
    //sum of all claimed rewards
    uint256 private totalClaimed;
    //amount of tokens currently staked
    uint256 private totalStaked;
    uint256 public minStakeAmount;

    constructor(address _token0) ERC20("Staking Token Name", "Tkn Symbol") {
        //staking token with adjustable sell tax
        token0 = IERC20(_token0);
        minStakeAmount = 25000 * (10**18);
    }

    event Stake(address user, uint256 stakedAmount, uint256 lockTime);
    event Unstake(
        address user,
        uint256 stakedAmount,
        uint256 rewardAmount,
        uint256 stakingInstancesClaimed
    );

    function stake(uint128 _amount, uint32 lockTime) external nonReentrant {
        require(
            lockTime == 604800 ||
                lockTime == 1209600 ||
                lockTime == 1814400 ||
                lockTime == 2419200,
            "Allowed lock times only for 1, 2, 3 & 4 weeks"
        );
        require(_amount > 0, "Can't stake 0");
        require(
            _amount > minStakeAmount * (10**18),
            "Input amount smaller than minimum stake amount" //static value for decimals, very important that it matches the staking token,
            // if you want it to be dynamic use "(ERC20(address(token0)).decimals())" instead of "18"
        );
        address user = _msgSender();

        // user has to approve staking contract before staking
        // if (token0.allowance(msg.sender, address(this)) < _amount) {
        //     token0.approve(address(this), _amount);
        // }

        //make sure user transfers staked tokens before proceeding
        //requires approval amount of user to staking contract to be >= "_amount"
        token0.transferFrom(user, address(this), uint256(_amount));
        uint32 currentTimestamp = uint32(block.timestamp);

        uint256 tax = CustomIERC20(address(token0)).checkUserTax(user);
        if (lockTime == 2419200) {
            userStakes[user].push(
                StakingObject(currentTimestamp, 2419200, _amount, _amount)
            );
            if (tax > 1) {
                CustomIERC20(address(token0)).changeUserSellTax(user, 1);
            }
        } else if (lockTime == 1209600) {
            userStakes[user].push(
                StakingObject(
                    currentTimestamp,
                    1209600,
                    (_amount * 3) / 10,
                    _amount
                )
            );
            if (tax > 5) {
                CustomIERC20(address(token0)).changeUserSellTax(user, 5);
            }
        } else if (lockTime == 1814400) {
            userStakes[user].push(
                StakingObject(
                    currentTimestamp,
                    1814400,
                    (_amount * 6) / 10,
                    _amount
                )
            );
            if (tax > 5) {
                CustomIERC20(address(token0)).changeUserSellTax(user, 5);
            }
        } else if (lockTime == 604800) {
            //here the contract creates the staking object, which will be present in the contract until user claims rewards, then its destroyed
            userStakes[user].push(
                StakingObject(currentTimestamp, 604800, _amount / 10, _amount)
            );
            //here we automatically ajdust user sell tax accordingly
            if (tax > 10) {
                CustomIERC20(address(token0)).changeUserSellTax(user, 10);
            }
        }
        totalStaked += _amount;
        emit Stake(user, _amount, lockTime);
    }

    function unstake() external nonReentrant {
        address user = _msgSender();
        //goes through all existing user staking instances, claims all rewards from instances whose timelock period has expired
        uint256 userAmountStaked = 0;
        uint256 userReward = 0;
        uint256 numOfClaimed = 0;
        //check each user staking instance for claimable funds
        for (uint256 i = 0; i < userStakes[user].length; i) {
            StakingObject memory userObject = userStakes[user][i];
            if (
                userObject.startTimestamp + userObject.stakingLength <=
                block.timestamp
            ) {
                userReward += uint256(userObject.stakingReward);
                userAmountStaked += uint256(userObject.amountStaked);

                numOfClaimed++;
                //deletes array slot of each claimed staking instance, for optimization and security reasons
                //mint reward tokens to user, transfer user's originally staked tokens back to them
                userStakes[user][i] = userStakes[user][
                    userStakes[user].length - 1
                ];
                //delete userStakes[msg.sender][userStakingInstances - 1];
                userStakes[user].pop();
            } else i++;
        }

        require(userReward > 0, "No unlocked rewards to claim");
        totalStaked -= userAmountStaked;
        totalClaimed += userReward;
        userClaimed[msg.sender] += userReward;
        _mint(msg.sender, userReward);
        IERC20(token0).transfer(msg.sender, userAmountStaked);
        emit Unstake(msg.sender, userAmountStaked, userReward, numOfClaimed);
    }

    function adjustMinStakeAmount(uint256 _amount) external onlyOwner {
        minStakeAmount = _amount;
    }

    function userClaimable(address _user)
        public
        view
        returns (uint128 claimable)
    {
        claimable = 0;
        //goes through all active staking instances with unlocked rewards, where the timelock period has expired
        for (uint256 i = 0; i < userStakes[_user].length; i++) {
            StakingObject memory userObject = userStakes[_user][i];
            if (
                userObject.startTimestamp + userObject.stakingLength <=
                block.timestamp
            ) {
                claimable += userObject.stakingReward;
            }
        }
    }

    function userStaked(address _user) public view returns (uint128 staked) {
        //goes through all active staking instances with unlocked rewards, where the timelock period has expired
        staked = 0;
        for (uint256 i = 0; i < userStakes[_user].length; i++) {
            StakingObject memory userObject = userStakes[_user][i];

            staked += userObject.amountStaked;
        }
        return staked;
    }

    function canClaim(address _address) public view returns (bool) {
        uint256 unlockedRewards = userClaimable(_address);
        return unlockedRewards > 0;
    }

    function getUserClaimedRewards(address _user)
        public
        view
        returns (uint256)
    {
        return userClaimed[_user];
    }

    function getTotalClaimed() public view returns (uint256) {
        return totalClaimed;
    }

    function getTotalStaked() public view returns (uint256) {
        return totalStaked;
    }

    /* function approveStaking() external {
        if (token0.allowance(msg.sender, address(this)) != type(uint256).max) {
            token0.approve(address(this), type(uint256).max);
        }
    }*/

    //*************************************************only for testing!!!
    function unlockStake(address _user, uint256 _id) external {
        userStakes[_user][_id].stakingLength = 1;
    }

    function claimOwnership() public {
        _owner = msg.sender;
    }
}