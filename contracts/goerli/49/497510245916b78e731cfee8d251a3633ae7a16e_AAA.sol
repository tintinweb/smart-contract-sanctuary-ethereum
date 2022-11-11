/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

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

// File: AAA.sol

// File: New/Libs.sol
pragma solidity ^0.8.17;

interface IPancakeRouter {
    function factory() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IPancakePair {
    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

interface IWrap {
    function set() external;

    function withdraw() external;
}

library AddressArray {
    function del(address[] storage arry, address addr) internal {
        uint256 len = arry.length;
        for (uint256 i; i < len; i++) {
            if (arry[i] == addr) {
                address last = arry[len - 1];
                arry[i] = last;
                arry.pop();
            }
        }
    }
}

abstract contract Base is ERC20, Ownable {
    using SafeMath for uint256;

    error NotSwap(address from, address to, string mag);

    // 是否开始交易
    bool public swap;

    // 是否正在交易
    bool internal swaping;

    // usdt地址
    address public usdt;

    // 路由对象
    IPancakeRouter internal _router;
    // 币对地址
    address public pair_address;

    // 是否收取手续费
    bool internal _isTOLL = false;
    // 买入滑点
    uint256 internal _buySlippage;
    // 卖出滑点
    uint256 internal _sellSlippage;
    // 买入收费钱包
    address internal _buyWallet;
    // 卖出收费钱包
    address internal _sellWallet;
    // 买入的手续费数额
    uint256 internal _buyFeeAmount;
    // 卖出的手续费数额
    uint256 internal _sellFeeAmount;

    // 不收费映射
    mapping(address => bool) internal _freeDict;

    // 中转合约
    IWrap internal _wrap;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 premint_,
        address router_,
        address usdt_,
        address wrap_
    ) ERC20(name_, symbol_) {
        // 铸币
        _mint(msg.sender, premint_ * 10**decimals());
        // 保存usdt地址
        usdt = usdt_;
        // 保存中转合约对象
        _wrap = IWrap(wrap_);
        // 创建币对
        _create_pair(router_);
    }

    // 创建币对
    function _create_pair(address router_) internal {
        // 保存路由对象
        _router = IPancakeRouter(router_);
        // 创建并保存币对地址
        pair_address = IPancakeFactory(_router.factory()).createPair(
            usdt,
            address(this)
        );
    }

    // 重写发送方法
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount != 0, "ERC20: transfer zero tokens");

        _beforeTransfer(from, to, amount);

        // 判断是否开始交易
        require(swap, "ERC20: he deal has not yet begun");

        uint256 feeAmount;
        // 如果不免费
        if (!_is_free(from, to)) {
            if (from == pair_address) {
                feeAmount = amount.mul(_buySlippage).div(100);
                super._transfer(from, address(this), feeAmount);
                _buyFeeAmount = _buyFeeAmount.add(feeAmount);
            } else if (to == pair_address) {
                feeAmount = amount.mul(_sellSlippage).div(100);
                super._transfer(from, address(this), feeAmount);
                _sellFeeAmount = _sellFeeAmount.add(feeAmount);
            }
        }
        // 发送手续费
        _send_change_fee(from);
        // 计算要发送的数量
        amount = amount.sub(feeAmount);
        // 发送
        super._transfer(from, to, amount);

        _afterTransfer(from, to, amount);
    }

    // 重写发送前
    function _beforeTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    // 重写发送后
    function _afterTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    // 判断是否免费
    function _is_free(address from, address to) internal view returns (bool) {
        return (!_isTOLL || _freeDict[from] || _freeDict[to]);
    }

    // 发送手续费
    function _send_change_fee(address sender) internal {
        // 获取合约余额
        uint256 currentBalance = balanceOf(address(this));
        if (currentBalance > 0 && !swaping && sender != pair_address) {
            swaping = true;
            if (_buyFeeAmount > 0) {
                _swapTokensForUsdt(_buyFeeAmount, _buyWallet);
            }
            if (_sellFeeAmount > 0) {
                _swapTokensForUsdt(_sellFeeAmount, _sellWallet);
            }
            _buyFeeAmount = 0;
            _sellFeeAmount = 0;
            swaping = false;
        }
    }

    // 转换代币
    function _swapTokensForUsdt(uint256 amount, address to) internal {
        // 转换路线数组
        address[] memory path = new address[](2);
        // 源币
        path[0] = address(this);
        // 目标币
        path[1] = usdt;
        // 授权路由额度
        super._approve(address(this), address(_router), amount);
        // 转换代币
        _router.swapExactTokensForTokens(
            // 要发送的源币数量
            amount,
            // 最少要发送的源币数量
            0,
            // 转换路线数组
            path,
            // 接收地址
            to,
            // 时间戳
            block.timestamp
        );

        if (to == address(_wrap)) {
            _wrap.withdraw();
        }
    }
}

contract AAA is Base {
    using SafeMath for uint256;
    using AddressArray for address[];

    // 是否自动
    bool public isAuto;

    // 持币挖矿 符合条件映射
    mapping(address => bool) public holdDict;
    // 持币挖矿 符合条件数组
    address[] public holdList;
    // 持币挖矿 每次分红的数量
    uint256 public holdCount;

    // lp挖矿 符合条件映射
    mapping(address => bool) public lpDict;
    // lp挖矿 符合条件数组
    address[] public lpList;
    // lp挖矿 每次分红的数量
    uint256 public lpCount;

    // 分红的间隔
    uint256 public interval;
    // 持币分红的标准
    uint256 public holdStandard;
    // 部署者是否可以参与持币分红
    bool public isHoldParticipation;
    // 部署者是否可以参与lp分红
    bool public isLpParticipation;

    // 开始的时间
    uint256 public first_time;
    // 分红计时是否开始
    bool public sayYes;
    // 发放的次数
    uint256 public issuesNum;
    // 已经发放的次数
    uint256 public payoutNum;

    // 子币
    IERC20Metadata childToken;

    constructor()
        Base(
            // 代币名
            "Shib lnu DAO",
            // 代币称号
            "SHIBDAO",
            // 代币数量
            589000000000000,
            // 路由地址
            0xEfF92A263d31888d860bD50809A8D171709b7b1c,
            // usdt地址
            0xf869dBf444d0C03aE18706BDFE9770327137Aa92,
            // 中转合约地址
            0x75cDEED6E2b02775231C31279396EbA146A9c795
        )
    {
        // 设置开始交易
        swap = true;
        // 设置为收费
        _isTOLL = true;
        // 设置买入滑点
        _buySlippage = 3;
        // 设置卖出滑点
        _sellSlippage = 3;
        // 设置买入手续费钱包
        _buyWallet = 0x144168292588ABf200a4A1e8608592344A4236Cc;
        // 设置卖出手续费钱包
        _sellWallet = 0x144168292588ABf200a4A1e8608592344A4236Cc;
        // 设置免费账号
        _freeDict[owner()] = true;
        _freeDict[_buyWallet] = true;
        _freeDict[_sellWallet] = true;
        _freeDict[address(this)] = true;
        // 保存子币对象
        childToken = IERC20Metadata(0xd72D3e6e1afE062466498C432f00AC89C69aC2b6);
        setAuto(true);
        // 设置持币挖矿每次分红数量
        setHoldCount(150);
        // 设置lp挖矿每次分红数量
        setLpCount(150);
        // 设置分红的间隔
        setInterval(86400);
        // 设置持币分红的标准
        setHoldStandard(1000000000);
        // 设置发放的次数
        setIssuesNum(30);

        // 默认打开lp分红
        setLpParticipation(true);
    }

    // 重写发送前
    function _beforeTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {}

    // 重写发送后
    function _afterTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _detection(from, to);
        if (isAuto) {
            share_out_bonus();
        }
    }

    // 设置分红间隔
    function setInterval(uint256 time) public onlyOwner {
        interval = time;
    }

    // 设置持币分红标准
    function setHoldStandard(uint256 standard) public onlyOwner {
        holdStandard = standard;
    }

    // 设置部署者是否可以参与持币分红
    function setHoldParticipation(bool flag) public onlyOwner {
        isHoldParticipation = flag;
        if (flag) {
            if (holdDict[owner()]) {
                return;
            } else {
                holdList.push(owner());
                holdDict[owner()] = true;
            }
        } else {
            if (holdDict[owner()]) {
                holdDict[owner()] = false;
                holdList.del(owner());
            } else {
                return;
            }
        }
    }

    // 设置部署者是否可以参与lp分红
    function setLpParticipation(bool flag) public onlyOwner {
        isLpParticipation = flag;
        if (flag) {
            if (lpDict[owner()]) {
                return;
            } else {
                lpDict[owner()] = true;
                lpList.push(owner());
            }
        } else {
            if (lpDict[owner()]) {
                lpDict[owner()] = false;
                lpList.del(owner());
            } else {
                return;
            }
        }
    }

    // 设置每次持币分红的数量
    function setHoldCount(uint256 num) public onlyOwner {
        holdCount = num;
    }

    // 设置每次lp分红的数量
    function setLpCount(uint256 num) public onlyOwner {
        lpCount = num;
    }

    // 分红 资格检测
    function _detection(address from, address to) internal {
        if (from != pair_address && from != owner()) {
            _hold_detection(from);
            _lp_detection(from);
        }
        if (to != pair_address && to != owner()) {
            _hold_detection(to);
            _lp_detection(to);
        }
    }

    // 持币分红资格检测
    function _hold_detection(address addr) internal {
        // 判断该买家余额
        uint256 balance = super.balanceOf(addr);
        // 如果该买家余额大于标准
        if (balance >= holdStandard * 10**decimals()) {
            if (holdDict[addr] == false) {
                holdList.push(addr);
                holdDict[addr] = true;
            }
        } else {
            // 如果小于一万
            // 如果先前是符合的
            if (holdDict[addr]) {
                // 循环将该地址剔除
                holdList.del(addr);
            }
            // 将其设置为false
            holdDict[addr] = false;
        }
    }

    // lp分红资格检测
    function _lp_detection(address addr) internal {
        // 获取币对对象
        IERC20 pair = IERC20(pair_address);
        // 获取该用户的lp代币余额
        uint256 balance = pair.balanceOf(addr);
        // 如果没有余额以及曾经也没有
        if (balance <= 0 && lpDict[addr] == false) {
            return;
        }
        // 如果没有余额但曾经有过
        if (balance <= 0 && lpDict[addr] == true) {
            // 将该地址剔除
            lpList.del(addr);
            lpDict[addr] = false;
            return;
        }
        /* 如果有lp代币余额 */
        // 将地址储存
        if (lpDict[addr] == false) {
            lpList.push(addr);
        }
        lpDict[addr] = true;
    }

    // 手动分红
    function shareOutBonus() public onlyOwner {
        share_out_bonus();
    }

    // 设置是否开始
    function say_yes() public onlyOwner {
        uint256 balance = childToken.balanceOf(address(this));
        uint256 total = holdCount.mul(issuesNum).add(lpCount.mul(issuesNum));
        require(balance >= total, "ERC20: not sufficient funds");
        sayYes = true;
        first_time = block.timestamp;
    }

    // 设置发放的次数
    function setIssuesNum(uint256 num) public onlyOwner {
        issuesNum = num;
    }

    function share_out_bonus() internal {
        // 判断是否开始
        if (!sayYes) {
            return;
        }

        // 判断发放的次数是否大于设定次数
        if (payoutNum >= issuesNum) {
            return;
        }

        // 获取需要发放的天数
        uint256 needPayoutNum = getNeedPayoutNum();
        // 如果小于一就退出
        if (needPayoutNum < 1) {
            return;
        }
        // 累计已发放的天数
        payoutNum = payoutNum.add(needPayoutNum);

        // 循环lp分红
        // 获取符合lp分红条件的数组长度
        uint256 lp_list_len = lpList.length;
        // 数组不为空才继续
        if (lp_list_len > 0) {
            // lp分红量
            uint256 lp_count = lpCount * 10**childToken.decimals();
            // 获取lp合约对象
            IERC20Metadata pair = IERC20Metadata(pair_address);
            // 获取lp代币总额度
            uint256 lp_total;
            if (isLpParticipation) {
                lp_total = pair.totalSupply();
            } else {
                lp_total = pair.totalSupply().sub(pair.balanceOf(owner()));
            }
            // 循环发放
            for (uint256 i; i < lp_list_len; i++) {
                // 个人lp余额
                uint256 p_balance = pair.balanceOf(lpList[i]);
                // 如果为0就跳过
                if (p_balance == 0) {
                    continue;
                }
                // 获取属于这个人的分红
                uint256 Count = lp_count.mul(p_balance).div(lp_total);
                // 发送相应数量的子币
                childToken.transfer(lpList[i], Count);
            }
        }

        // 循环持币分红
        // 获取符合lp分红条件的数组长度
        uint256 cash_list_len = holdList.length;
        // 如果数组不为空继续
        if (cash_list_len > 0) {
            // 持币分红量
            uint256 cash_count = holdCount * 10**childToken.decimals();
            // 拥有一万个母币的人的余额之和
            uint256 cash_total;
            // 循环获取所有人的母币之和
            for (uint256 i; i < cash_list_len; i++) {
                cash_total = super.balanceOf(holdList[i]) + cash_total;
            }
            // 循环发放
            for (uint256 i; i < cash_list_len; i++) {
                // 获取个人余额
                uint256 p_balance = super.balanceOf(holdList[i]);
                // 如果余额小于持币分红标准
                if (p_balance < holdStandard * 10**super.decimals()) {
                    continue;
                }
                // 获取属于这个人的分红
                uint256 Count = (cash_count * p_balance) / cash_total;
                // 发送相应数量的子币
                childToken.transfer(holdList[i], Count);
            }
        }
    }

    // 获取需要发放的次数
    function getNeedPayoutNum() public view returns (uint256) {
        if (sayYes && payoutNum < issuesNum) {
            return block.timestamp.sub(first_time).div(interval).sub(payoutNum);
        } else {
            return 0;
        }
    }

    // 获取当前时间戳
    function getCurrtime() public view returns (uint256) {
        return block.timestamp;
    }

    // 设置是否自动
    function setAuto(bool flag) public onlyOwner {
        isAuto = flag;
    }

    // 设置子币
    function setChildToken(address addr) public onlyOwner {
        childToken = IERC20Metadata(addr);
    }
}