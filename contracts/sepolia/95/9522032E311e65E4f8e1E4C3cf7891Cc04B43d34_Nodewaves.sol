/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
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
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
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
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
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

// File: contracts/MyToken1.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

contract Nodewaves is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    struct Nodes {
        uint amount;
        uint lastWithdraw;
        address affiliate;
    }

    mapping(address => Nodes) public nodes;
    uint public numberOfNodes;

    uint public maxSupply = 10e9;

    uint decimal = 2;

    uint public payoutTime = 1 days;

    uint tokenForDistribuition;
    uint tokenForSP;
    uint tokenForNode;
    uint tokenForPoB;
    uint tokenForPoS;
    uint tokenForTeam;
    uint tokenForAdvisors;
    uint tokenForTreasure;
    uint tokenForP2E;
    uint tokenForM2E;
    uint tokenForLiquidity;
    uint tokenForDevAndEco;

    address[10] public payoutAddresses;

    uint[] public percentages = [3, 25, 25, 5, 2, 3, 25, 5, 5, 15, 15];

    uint public distributedateSP;
    uint public distributedateNode;
    uint public distributedatePoB;
    uint public distributedatePoS;
    uint public distributedateTeam;
    uint public distributedateAdvisors;
    uint public distributedateTreasure;
    uint public distributedateP2E;
    uint public distributedateM2E;
    uint public distributedateLiquidity;
    uint public distributedateDevAndEco;

    uint public distributePercentage = 10;
    uint public distributionTime = 365 days;

    ERC20 public token;

    uint[5] public burnPakages = [1000, 2000, 3000, 4000, 5000];
    uint[5] public burnRewards = [2000, 4000, 6000, 8000, 10000];

    constructor() ERC20("Nodewaves", "NWS") {
        _mint(address(this), maxSupply * 10 ** decimals());
        token = ERC20(address(this));
    }

    function distribute() public onlyOwner {
        _distribute();
    }

    function burn(uint amount) public override {
        if (amount == burnPakages[0]) {
            _burn(msg.sender, amount*10**18);
            transfer(msg.sender, burnRewards[0]*10**18);
        } else if (amount == burnPakages[1]) {
            _burn(msg.sender, amount*10**18);
            transfer(msg.sender, burnRewards[1]*10**18);
        } else if (amount == burnPakages[2]) {
            _burn(msg.sender, amount*10**18);
            transfer(msg.sender, burnRewards[2]*10**18);
        } else if (amount == burnPakages[3]) {
            _burn(msg.sender, amount*10**18);
            transfer(msg.sender, burnRewards[3]*10**18);
        } else if (amount == burnPakages[4]) {
            _burn(msg.sender, amount*10**18);
            transfer(msg.sender, burnRewards[4]*10**18);
        } else {
            revert("Invalid amount");
        }
    }

    function _distribute() private {
        // setting distribution times.
        distributedateSP = block.timestamp;
        distributedateNode = block.timestamp;
        distributedatePoB = block.timestamp;
        distributedatePoS = block.timestamp;
        distributedateTeam = block.timestamp;
        distributedateAdvisors = block.timestamp;
        distributedateTreasure = block.timestamp;
        distributedateP2E = block.timestamp;
        distributedateM2E = block.timestamp;
        distributedateLiquidity = block.timestamp;
        distributedateDevAndEco = block.timestamp;

        tokenForDistribuition = (maxSupply.mul(distributePercentage)).div(100);

        tokenForSP = tokenForSP + tokenForSP.add(
            (tokenForDistribuition.mul(percentages[0])).div(10 ** decimal)
        );
        tokenForNode = tokenForNode + tokenForNode.add(
            (tokenForDistribuition.mul(percentages[1])).div(10 ** decimal)
        );
        tokenForPoB =  tokenForPoB + tokenForPoB.add(
            (tokenForDistribuition.mul(percentages[2])).div(10 ** decimal)
        );
        tokenForPoS = tokenForPoS + tokenForPoS.add(
            (tokenForDistribuition.mul(percentages[3])).div(10 ** decimal)
        );
        tokenForTeam =  tokenForTeam + tokenForTeam.add(
            (tokenForDistribuition.mul(percentages[4])).div(10 ** decimal)
        );
        tokenForAdvisors = tokenForAdvisors  + tokenForAdvisors.add(
            (tokenForDistribuition.mul(percentages[5])).div(10 ** decimal)
        );
        tokenForTreasure = tokenForTreasure + tokenForTreasure.add(
            (tokenForDistribuition.mul(percentages[6])).div(10 ** decimal)
        );
        tokenForP2E = tokenForP2E + tokenForP2E.add(
            (tokenForDistribuition.mul(percentages[7])).div(10 ** decimal)
        );
        tokenForM2E = tokenForM2E + tokenForM2E.add(
            (tokenForDistribuition.mul(percentages[8])).div(10 ** decimal)
        );
        tokenForLiquidity = tokenForLiquidity + tokenForLiquidity.add(
            (tokenForDistribuition.mul(percentages[9])).div(10 ** decimal)
        );
        tokenForDevAndEco = tokenForDevAndEco + tokenForDevAndEco.add(
            (tokenForDistribuition.mul(percentages[10])).div(10 ** decimal)
        );
    }

    function addNodes(
        address[] memory _nodes,
        address[] memory _affiliate,
        uint _index
    ) public onlyOwner {
        for (uint i; i < _index; i++) {
            Nodes storage node = nodes[_nodes[i]];
            if (node.amount == 0) {
                node.affiliate = _affiliate[i];
                node.lastWithdraw = block.timestamp;
                node.amount = node.amount.add(1);
                numberOfNodes += 1;
            }
        }
    }

    function buyNode(address _affiliate) public payable {
        require(msg.value == 0.01 ether, "You need to send 0.01 ether");
        Nodes storage node = nodes[msg.sender];
        node.affiliate = _affiliate;
        node.lastWithdraw = block.timestamp;
        node.amount = node.amount.add(1);
        numberOfNodes += 1;
    }

    function nodeWithdraw() public {
        Nodes storage node = nodes[msg.sender];
        require(node.amount > 0, "You don't have a node");
        require(
            block.timestamp > node.lastWithdraw + payoutTime,
            "You can withdraw only once a day"
        );

        uint _amount = ((tokenForNode / payoutTime) * 365) / numberOfNodes;

        if (node.affiliate != address(0)) {
            uint _affiliateAmount = _amount.mul(10).div(10 ** decimal);
            if (tokenForDevAndEco >= _affiliateAmount) {
                tokenForDevAndEco = tokenForDevAndEco - _affiliateAmount;
                token.transfer(node.affiliate, _affiliateAmount);
            }
        }

        node.lastWithdraw = block.timestamp;
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    function pob() public view returns (uint) {
        uint _days = (block.timestamp.sub(distributedatePoB)).div(payoutTime);
        uint _amount = (tokenForPoB.div(365)).mul(_days);
        return _amount;
    }

    function pos() public view returns (uint) {
        uint _days = (block.timestamp.sub(distributedatePoS)).div(payoutTime);
        uint _amount = (tokenForPoS.div(365)).mul(_days);
        return _amount;
    }

    function team() public view returns (uint) {
        uint _days = (block.timestamp.sub(distributedateTeam)).div(payoutTime);
        uint _amount = (tokenForTeam.div(365)).mul(_days);
        return _amount;
    }

    function advisors() public view returns (uint) {
        uint _days = (block.timestamp.sub(distributedateAdvisors)).div(
            payoutTime
        );
        uint _amount = (tokenForAdvisors.div(365)).mul(_days);
        return _amount;
    }

    function treasure() public view returns (uint) {
        uint _days = (block.timestamp.sub(distributedateTreasure)).div(
            payoutTime
        );
        uint _amount = (tokenForTreasure.div(365)).mul(_days);
        return _amount;
    }

    function P2E() public view returns (uint) {
        uint _days = (block.timestamp.sub(distributedateP2E)).div(payoutTime);
        uint _amount = (tokenForP2E.div(365)).mul(_days);
        return _amount;
    }

    function M2E() public view returns (uint) {
        uint _days = (block.timestamp.sub(distributedateM2E)).div(payoutTime);
        uint _amount = (tokenForM2E.div(365)).mul(_days);
        return _amount;
    }

    function liquidity() public view returns (uint) {
        uint _days = (block.timestamp.sub(distributedateLiquidity)).div(
            payoutTime
        );
        uint _amount = (tokenForLiquidity.div(365)).mul(_days);
        return _amount;
    }

    function devAndEco() public view returns (uint) {
        uint _days = (block.timestamp.sub(distributedateDevAndEco)).div(
            payoutTime
        );
        uint _amount = (tokenForDevAndEco.div(365)).mul(_days);
        return _amount;
    }

    function sp() public view returns (uint) {
        uint _days = (block.timestamp.sub(distributedateSP)).div(payoutTime);
        uint _amount = (tokenForSP.div(365)).mul(_days);
        return _amount;
    }

    function withdrawToken(uint _index) public onlyOwner {
        if (_index == 0) {
            require(
                msg.sender == payoutAddresses[_index],
                "You are not allowed to withdraw"
            );
            
            token.transfer(msg.sender, pob());
            distributedatePoB = block.timestamp;
        }
        if (_index == 1) {
            require(
                msg.sender == payoutAddresses[_index],
                "You are not allowed to withdraw"
            );
            
            token.transfer(msg.sender, pos());
            distributedatePoS = block.timestamp;
        }
        if (_index == 2) {
            require(
                msg.sender == payoutAddresses[_index],
                "You are not allowed to withdraw"
            );
            
            token.transfer(msg.sender, team());
            distributedateTeam = block.timestamp;
        }
        if (_index == 3) {
            require(
                msg.sender == payoutAddresses[_index],
                "You are not allowed to withdraw"
            );
            
            token.transfer(msg.sender, advisors());
            distributedateAdvisors = block.timestamp;
        }
        if (_index == 4) {
            require(
                msg.sender == payoutAddresses[_index],
                "You are not allowed to withdraw"
            );
            
            token.transfer(msg.sender, treasure());
            distributedateTreasure = block.timestamp;
        }
        if (_index == 5) {
            require(
                msg.sender == payoutAddresses[_index],
                "You are not allowed to withdraw"
            );
            
            token.transfer(msg.sender, P2E());
            distributedateP2E = block.timestamp;
        }
        if (_index == 6) {
            require(
                msg.sender == payoutAddresses[_index],
                "You are not allowed to withdraw"
            );
            
            token.transfer(msg.sender, M2E());
            distributedateM2E = block.timestamp;
        }
        if (_index == 7) {
            require(
                msg.sender == payoutAddresses[_index],
                "You are not allowed to withdraw"
            );
            
            token.transfer(msg.sender, liquidity());
            distributedateLiquidity = block.timestamp;
        }
        if (_index == 8) {
            require(
                msg.sender == payoutAddresses[_index],
                "You are not allowed to withdraw"
            );
            
            token.transfer(msg.sender, devAndEco());
            distributedateDevAndEco = block.timestamp;
        }
        if (_index == 9) {
            require(
                msg.sender == payoutAddresses[_index],
                "You are not allowed to withdraw"
            );
            
            token.transfer(msg.sender, sp());
            distributedateSP = block.timestamp;
        }
    }

    function setDistributePercentage(uint _value) public onlyOwner {
        distributePercentage = _value;
    }

    function setBurnPakages(uint _index, uint _value) public onlyOwner {
        burnPakages[_index] = _value;
    }

    function setBurnRewards(uint _index, uint _value) public onlyOwner {
        burnRewards[_index] = _value;
    }

    function setPayoutaddress(address[] memory _addresses) public onlyOwner {
        for (uint i; i < _addresses.length; i++) {
            payoutAddresses[i] = _addresses[i];
        }
    }

    function setPayoutTime(uint _time) public onlyOwner {
        payoutTime = _time;
    }
}