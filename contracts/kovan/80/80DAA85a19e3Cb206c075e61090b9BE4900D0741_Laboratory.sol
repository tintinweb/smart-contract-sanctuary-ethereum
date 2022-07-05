/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol
// SPDX-License-Identifier: GPL-3.0

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

// File: @openzeppelin\contracts\token\ERC20\extensions\IERC20Metadata.sol


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

// File: @openzeppelin\contracts\utils\Context.sol


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

// File: @openzeppelin\contracts\token\ERC20\ERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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

// File: @openzeppelin\contracts\access\Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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

// File: @openzeppelin\contracts\utils\math\SafeMath.sol


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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

// File: @openzeppelin\contracts\utils\introspection\IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin\contracts\token\ERC721\IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// File: @openzeppelin\contracts\token\ERC721\extensions\IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin\contracts\utils\Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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

// File: contracts\market-place\interfaces\IMarketPlaceEvent.sol


pragma solidity ^0.8.3;

/**
 * @title IMarketPlaceEvent - interface that contains the define of events 
 */
interface IMarketPlaceEvent {
    /**
     * @dev Emits when token adress is changed
     * @param oldToken is old address token
     * @param newToken is token address that will be changed
     */
    event TokenAdressChanged(address oldToken, address newToken);

    /**
     * @dev Emits when Laboratory adress is changed
     * @param oldLaboratory is old Laboratory address
     * @param newLaboratory is new Laboratory address
     */
    event LaboratoryAddressChanged(address oldLaboratory, address newLaboratory);

    /**
     * @dev Emits when modules token adress is changed
     * @param oldModules is old modules address
     * @param newModules is new modules address
     */
    event ModuleAddressChanged(address oldModules, address newModules);

    /**
     * @dev Emits when wallet adress is changed
     * @param oldWallet is old wallet address
     * @param newWallet is new wallet address
     */
    event WalletAddressChanged(address oldWallet, address newWallet);

    /**
     * @dev Emits when fee amount is changed
     * @param oldFeeAmount is old fee amount
     * @param newFeeAmount is new fee amount
     */
    event FeeQuoteAmountUpdated(uint oldFeeAmount, uint newFeeAmount);

    /**
     * @dev Emits when token price is changed
     * @param oldPrice is old price of token
     * @param newPrice is new price of token
     */
    event TokenPriceChanged(uint oldPrice, uint newPrice);

    /**
     * @dev Emits when account successfully added MetaCell to marketplace
     * @param ownerOf is owner address of MetaCell
     * @param tokenId is id of MetaCell
     * @param price is ETH price of MetaCell
     * @param timestamp is the time that event emitted
     */
    event MetaCellAddedToMarketplace(
        address indexed ownerOf, 
        uint indexed tokenId, 
        uint price, 
        uint timestamp
    );

    /**
     * @dev Emits when account successfully added NanoCell to marketplace
     * @param ownerOf is owner address of NanoCell
     * @param tokenId is id of NanoCell
     * @param price is MDMA price of NanoCell
     * @param timestamp is the time that event emitted
     */
    event NanoCellAddedToMarketPlace(
        address indexed ownerOf, 
        uint indexed tokenId, 
        uint price, 
        uint timestamp
    );

    /**
     * @dev Emits when account successfully added Module to marketplace
     * @param ownerOf is owner address of Module
     * @param tokenId is id of Module
     * @param price is MDMA price of Module
     * @param timestamp is the time that event emitted
     */
    event ModuleAddedToMarketPlace(
        address indexed ownerOf, 
        uint indexed tokenId, 
        uint price, 
        uint timestamp
    );

    /**
     * @dev Emits when user successfully removed MetaCell from marketplace
     * @param ownerOf is owner address of MetaCell
     * @param tokenId is id of MetaCell
     * @param timestamp is the time that event emitted
     */
    event MetaCellRemovedFromMarketPlace(
        address indexed ownerOf, 
        uint indexed tokenId, 
        uint timestamp
    );

    /**
     * @dev Emits when user successfully removed NanoCell from marketplace
     * @param ownerOf is owner address of NanoCell
     * @param tokenId is id of NanoCell
     * @param timestamp is the time that event emitted
     */
    event NanoCellRemovedFromMarketPlace(
        address indexed ownerOf, 
        uint indexed tokenId, 
        uint timestamp
    );

    /**
     * @dev Emits when user successfully removed Module from marketplace
     * @param ownerOf is owner address of Module
     * @param tokenId is id of Module
     * @param timestamp is the time that event emitted
     */
    event ModuleRemovedFromMarketPlace(
        address indexed ownerOf, 
        uint indexed tokenId, 
        uint timestamp
    );

    /**
     * @dev Emits when buyer successfully bought MetaCell from seller
     * @param seller is seller address of MetaCell
     * @param tokenId is id of the MetaCell that sold
     * @param buyer is buyer address that buyed the MetaCell
     * @param price is the ETH price at the time MetaCell sold
     * @param fee is the ETH fee charged
     * @param timestamp is the time that event emitted
     */
    event MetaCellSold(
        address indexed seller, 
        uint indexed tokenId, 
        address indexed buyer, 
        uint price,
        uint fee,
        uint timestamp
    );

    /**
     * @dev Emits when buyer successfully bought NanoCell from seller
     * @param seller is seller address of NanoCell
     * @param tokenId is id of the NanoCell that sold
     * @param buyer is buyer address that buyed the NanoCell
     * @param price is the MDMA token price at the time NanoCell sold
     * @param fee is the MDMA token fee charged
     * @param timestamp is the time that event emitted
     */
    event NanoCellSold(
        address indexed seller, 
        uint indexed tokenId, 
        address indexed buyer, 
        uint price,
        uint fee,
        uint timestamp
    );

    /**
     * @dev Emits when buyer successfully bought Module from seller
     * @param seller is seller address of Module
     * @param tokenId is id of the Module that sold
     * @param buyer is buyer address that buyed the Module
     * @param price is the MDMA token price at the time Module sold
     * @param fee is the MDMA token fee charged
     * @param timestamp is the time that event emitted
     */
    event ModuleSold(
        address indexed seller, 
        uint indexed tokenId, 
        address indexed buyer, 
        uint price,
        uint fee,
        uint timestamp
    );

    /**
     * @dev Emits when owner updated MetaCell price
     * @param ownerOf is owner address of MetaCell
     * @param tokenId is id of MetaCell
     * @param newPrice is new ETH price of MetaCell
     * @param timestamp is the time that event emitted
     */
    event MetaCellPriceUpdated(
        address indexed ownerOf, 
        uint indexed tokenId, 
        uint indexed newPrice, 
        uint timestamp
    );

    /**
     * @dev Emits when owner updated NanoCell price
     * @param ownerOf is owner address of NanoCell
     * @param tokenId is id of NanoCell
     * @param newPrice is new ETH price of NanoCell
     * @param timestamp is the time that event emitted
     */
    event NanoCellPriceUpdated(
        address indexed ownerOf, 
        uint indexed tokenId, 
        uint indexed newPrice, 
        uint timestamp
    );

    /**
     * @dev Emits when owner updated Module price
     * @param ownerOf is owner address of Module
     * @param tokenId is id of Module
     * @param newPrice is new ETH price of Module
     * @param timestamp is the time that event emitted
     */
    event ModulePriceUpdated(
        address indexed ownerOf, 
        uint indexed tokenId, 
        uint indexed newPrice, 
        uint timestamp
    );

    /**
     * @dev Emits when admin created the Enhancer
     * @param admin is admin address
     * @param id is id of Enhancer
     * @param typeId is the type id of Enhancer
     * @param probability is the probability which increases the chance to SPLIT when evolve MetaCell
     * @param basePrice is the price of each Enhancer id
     * @param amount is the amount of Enhancer
     * @param name is the name of Enhancer
     * @param tokenAddress is the token which is used to buy Enhancer, is ETH if `tokenAddress` is equal to address zero
     * @param timestamp is the time that event emitted
     */
    event EnhancerCreated(
        address admin,
        uint indexed id, 
        uint indexed typeId, 
        uint indexed probability, 
        uint basePrice,
        uint amount, 
        string name,
        address tokenAddress,
        uint timestamp
    );
    
    /**
     * @dev Emits when admin increased the amount of Enhancers
     * @param admin is admin address
     * @param id is id of Enhancer
     * @param amount is the current amount after admin increasing the Enhancers
     * @param timestamp is the time that event emitted
     */
    event EnhancersAmountIncreased(
        address indexed admin, 
        uint indexed id, 
        uint amount, 
        uint timestamp
    );

    /**
     * @dev Emits when admin modified the Enhancer
     * @param admin is admin address
     * @param id is id of Enhancer
     * @param typeId is the type id of Enhancer
     * @param probability is the probability which increases the chance to SPLIT when evolve MetaCell
     * @param basePrice is the price of each Enhancer id
     * @param amount is the amount of Enhancer
     * @param name is the name of Enhancer
     * @param tokenAddress is the token which is used to buy Enhancer, is ETH if `tokenAddress` is equal to address zero
     * @param timestamp is the time that event emitted
     */
    event EnhancerModified(
        address admin,
        uint indexed id, 
        uint indexed typeId, 
        uint indexed probability, 
        uint basePrice,
        uint amount, 
        string name,
        address tokenAddress,
        uint timestamp
    );

    /**
     * @dev Emits when admin removed the Enhancer from MarketPlace
     * @param admin is admin address
     * @param id is id of Enhancer
     * @param timestamp is the time that event emitted
     */
    event EnhancerRemoved(
        address indexed admin, 
        uint indexed id, 
        uint timestamp
    );

    /**
     * @dev Emits when user successfully bought Enhancer
     * @param buyer is buyer address
     * @param id is id of Enhancer
     * @param amount is the amount of Enhancers buyer has buyed
     * @param price is the ETH price that buyer has paid
     * @param timestamp is the time that event emitted
     */
    event EnhancerBought(
        address indexed buyer, 
        uint indexed id, 
        uint indexed amount, 
        uint price,
        uint timestamp
    );
}

// File: contracts\market-place\interfaces\IMarketPlaceGetter.sol


pragma solidity ^0.8.3;

interface IMarketPlaceGetter {
    /**
     * @dev Returns MDMA token address
     * @return address of MDMA token
     */
    function getMDMAToken() external view returns (address);

    /**
     * @dev function that returns ERC20 token address
     */
    function getMetaCellToken() external view returns (address);

    /**
     * @dev function that returns ERC20 token address
     */
    function getNanoCellToken() external view returns (address);

    /**
     * @dev  returns modules contract address
     */
    function getModuleAddress() external view returns (address module);

    /**
     * @dev function that returns ERC721 token address
     */
    function getLaboratory() external view returns (address laboratory);

    
}

// File: contracts\market-place\interfaces\IMarketPlaceSetter.sol


pragma solidity ^0.8.3;

interface IMarketPlaceSetter {
    /**
     * @dev function that sets ERC20 token address.
     * @dev emits TokenAdressChanged
     * @param _address is address of ERC20 token
     */
    function setMDMAToken(address _address) external;

    /**
     * @dev function that sets MetaCell token address.
     * @dev emits TokenAdressChanged
     * @param _address is address of MetaCell token
     */
    function setMetaCellToken(address _address) external;

    /**
     * @dev function that sets NanoCell token address.
     * @dev emits TokenAdressChanged
     * @param _address is address of NanoCell token
     */
    function setNanoCellToken(address _address) external;

    /**
     * @dev function that sets laboratory contract address.
     * @dev emits LaboratoryAddressChanged
     * @param _address is address of Laboratory address
     */
    function setLaboratory(address _address) external;

    /**
     * @dev set modules contract address
     * @dev emits ModulesAddressChanged
     */
    function setModulesAddress(address _address) external;

    /**
     * @dev function thats sets price of ERC20 token.
     * @dev emits TokenPriceChanged
     * @param _price is amount per 1 ERC20 token
     */
    function setMDMATokenPrice(uint256 _price) external;
}

// File: contracts\market-place\interfaces\IMarketPlaceMetaCell.sol


pragma solidity ^0.8.3;

interface IMarketPlaceMetaCell {
    function buyMetaCell(uint256 _tokenId, address payable _oldOwner)
        external
        payable;

    /**
     * @dev Marks meta cell token as available for selling
     * @param _tokenId id of the cell
     * @param _price selling price
     */
    function sellMetaCell(uint256 _tokenId, uint256 _price) external;

    /**
     * @dev Updates token sell price
     * @param _tokenId id of the cell
     * @param _newPrice new price of the token
     */
    function updateMetaCellPrice(uint256 _tokenId, uint256 _newPrice) external;

    /**
     * @dev Marks token as unavailable for selling
     * @param _tokenId id of the cell
     */
    function removeMetaCellFromSale(uint256 _tokenId) external;

    /**
     * @dev Returns all tokens that on sale now as an array of IDs
     */
    function getOnSaleMetaCells()
        external
        view
        returns (address[] memory, uint256[] memory);
}

// File: contracts\market-place\interfaces\IMarketPlaceNanoCell.sol


pragma solidity ^0.8.3;

interface IMarketPlaceNanoCell {
    /**
     * @dev function that buyer buy NanoCell from seller
     */
    function buyNanoCell(uint256 id) external;

    /**
     * @dev adds module to marketplace
     */
    function sellNanoCell(uint256 id, uint256 price) external;

    /**
     * @dev removes module from marketplace
     */
    function removeNanoCellFromSale(uint256 id) external;

    /**
     * @dev returns list of boxes on sale
     */
    function getNanoCellsOnSale() external view returns (uint256[] memory);

    /**
     * @dev returns list of boxes on sale
     */
    function getNanoCellPrice(uint256 id) external view returns (uint256);

    /**
     * @dev returns list of boxes on sale
     */
    function updateNanoCellPrice(uint256 id, uint256 price) external;
}

// File: contracts\market-place\interfaces\IMarketPlaceMDMA.sol


pragma solidity ^0.8.3;

interface IMarketPlaceMDMA {
    /**
     * @dev function that returns price per 1 token.
     */
    function getMDMATokenPrice() external view returns (uint256);

    /**
     * @dev payable function thata allows to buy ERC20 token for ether
     * @param _amount amount of ERC20 tokens to buy
     */
    function buyMDMAToken(uint256 _amount) external payable;

    /**
     * @dev withdraw MDMA rokens to owner
     */
    function withdrawTokens(address token, address to) external;
}

// File: contracts\market-place\interfaces\IMarketPlaceModule.sol


pragma solidity ^0.8.3;

interface IMarketPlaceModule {
    /**
     * @dev transfers module from one user to another
     */
    function buyModule(uint256 id) external;

    /**
     * @dev adds module to marketplace
     */
    function sellModule(uint256 id, uint256 price) external;

    /**
     * @dev removes module from marketplace
     */
    function removeModuleFromSale(uint256 id) external;

    /**
     * @dev returns list of boxes on sale
     */
    function getModulesOnSale() external view returns (uint256[] memory);

    /**
     * @dev returns list of boxes on sale
     */
    function getModulePrice(uint256 id) external view returns (uint256);

    /**
     * @dev returns list of boxes on sale
     */
    function updateModulesPrice(uint256 id, uint256 price) external;
}

// File: contracts\libs\Enhancer.sol


pragma solidity ^0.8.0;

/**
 * @title Representation of enhancer options
 */
library CellEnhancer {
    /**
     * @dev Enhancer
     * @param id - enhancer id
     * @param typeId - enhancer type id
     * @param probability - chance of successful enhancement
     * @param basePrice - default price
     * @param baseCurrency - default currency
     * @param enhancersAmount - amount of existing enhancers
     */
    struct Enhancer {
        uint256 id;
        uint8 typeId;
        uint16 probability;
        uint256 basePrice;
        string name;
        address tokenAddress;
        //todo uint256 amount; add
    }

    enum EnhancerType {
        UNKNOWN_ENHANCER,
        STAGE_ENHANCER,
        SPLIT_ENHANCER
    }

    function convertEnhancer(uint8 enhancerType)
        internal
        pure
        returns (EnhancerType)
    {
        if (enhancerType == 1) {
            return EnhancerType.STAGE_ENHANCER;
        } else if (enhancerType == 2) {
            return EnhancerType.SPLIT_ENHANCER;
        }

        return EnhancerType.UNKNOWN_ENHANCER;
    }
}

// File: contracts\market-place\interfaces\IMarketPlaceEnhancer.sol


pragma solidity ^0.8.3;
interface IMarketPlaceEnhancer {
    /**
     * @notice Buy enhancer for ETH
     * @dev Requirements:
     * - Sufficient quantity of Enhancers in the MarketPlace
     * - Token address to pay must be equal to address zero
     * - Base price multiple `amount` must be less than msg.value
     * @param enhancerId is id of Enhancer
     * @param amount is amount of enhancers that caller want to buy
     */
    function buyEnhancerForETH(
        uint256 enhancerId, 
        uint256 amount
    ) external 
        payable;

    /**
     * @notice Buy enhancer for token address
     * @dev Requirements:
     * - Sufficient quantity of Enhancers in the MarketPlace
     * - Token address to pay must be not equal to address zero
     * - Token address to pay must be equal to `tokenAddress`
     * @param tokenAddress is token address
     * @param enhancerId is id of Enhancer
     * @param amount is amount of enhancers that caller want to buy
     */
    function buyEnhancerForToken(
        address tokenAddress,
        uint256 enhancerId,
        uint256 amount
    ) external;

    /**
     * @dev Returns enhancer info by id
     * @param id is id of Enhancer
     * @return Enhancer info
     */
    function getEnhancer(uint256 id)
        external
        view
        returns (CellEnhancer.Enhancer memory);

    /**
     * @dev returns all available enhancers
     */
    function getAllEnhancers()
        external
        view
        returns (CellEnhancer.Enhancer[] memory);

    /**
     * @dev Returns amount of availbale enhancers by given id
     */
    function getEnhancersAmount(uint256 _id) external view returns (uint256);

    function numberOfEnhancersType() external view returns (uint);

    /**
     * @dev Creates enhancer with options
     */
    function createEnhancer(
        uint8 _typeId,
        uint16 _probability,
        uint256 _basePrice,
        uint256 _amount,
        string memory _name,
        address _tokenAddress
    ) external;

    /**
     * @dev Modifies enhancer's info
     * can be changed everything except enhancer's type
     */
    function modifyEnhancer(CellEnhancer.Enhancer memory, uint256) external;

    /**
     * @dev Increases enhancer amount by it's id
     */
    function addEnhancersAmount(uint256 _id, uint256 _amount) external;

    /**
     * @dev Removes enhancer from marketPlace
     */
    function removeEnhancerFromSale(uint256 id) external;

    
}

// File: contracts\market-place\interfaces\IMarketPlace.sol


pragma solidity ^0.8.3;
interface IMarketPlace is 
    IMarketPlaceEvent,
    IMarketPlaceGetter,
    IMarketPlaceSetter,
    IMarketPlaceMetaCell,
    IMarketPlaceNanoCell,
    IMarketPlaceMDMA,
    IMarketPlaceModule,
    IMarketPlaceEnhancer
{}

// File: @openzeppelin\contracts\utils\structs\EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// File: contracts\interfaces\IAdmin.sol


pragma solidity ^0.8.3;
/**
 * @title Interface to add alowed operator in additiona to owner
 */
abstract contract IAdmin {
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private admins;

    modifier isAdmin() {
        require(admins.contains(msg.sender), "You do not have rights");
        _;
    }

    event AdminAdded(address);
    event AdminRemoved(address);

    function addAdmin(address _admin) external virtual;

    function removeAdmin(address _admin) external virtual;

    function _addAdmin(address _admin) internal {
        require(_admin != address(0), "Address should not be empty");
        require(!admins.contains(_admin), "Already added");
        if (!admins.contains(_admin)) {
            admins.add(_admin);
            emit AdminAdded(_admin);
        }
    }

    function _removeAdmin(address _admin) internal {
        require(admins.contains(_admin), "Not exist");
        if (admins.contains(_admin)) {
            admins.remove(_admin);
            emit AdminRemoved(_admin);
        }
    }

    function getAdmins() external view returns (address[] memory) {
        return admins.values();
    }
}

// File: contracts\interfaces\IMintable.sol


pragma solidity ^0.8.3;

abstract contract IMintable {
    function burn(uint256) external virtual;

    function mint(address, uint256) external virtual returns (uint256);
}

// File: contracts\libs\CellData.sol


pragma solidity ^0.8.3;

/**
 * @title Representation of cell with it fields
 */
library CellData {
    /**
     *  Represents the standart roles
     *  on which cell can be divided
     */
    enum Class {
        INIT,
        COMMON,
        SPLITTABLE_NANO,
        SPLITTABLE_MAD,
        SPLITTABLE_ENHANCER,
        FINISHED
    }

    function isSplittable(Class _class) internal pure returns (bool) {
        return
            _class == Class.SPLITTABLE_NANO || _class == Class.SPLITTABLE_MAD || _class == Class.SPLITTABLE_ENHANCER;
    }

    /**
     *  Represents the basic parameters that describes cell
     */
    struct Cell {
        uint256 tokenId;
        address user;
        Class class;
        uint256 stage;
        uint256 nextEvolutionBlock;
        uint256 variant;
        bool onSale;
        uint256 price;
    }
}

// File: contracts\laboratory\interfaces\ILaboratoryEvent.sol


pragma solidity ^0.8.3;
interface ILaboratoryEvent {
    /**
     *  Event to show that meta cell
     *  has changed it's properties
     *  @dev has to be emited in `unpack` and evolve
     */
    event NewEvolutionCompleted(
        string methodName,
        CellData.Cell cell,
        uint timestamp
    );

    /**
     * @dev Emits when user evolve MetaCell and split NanoCell
     * @param receiver is receiver address
     * @param tokenId is id of NanoCell
     * @param timestamp is is the time that event emitted
     */
    event SplitNanoCell(
        address indexed receiver,
        uint indexed tokenId,
        uint timestamp
    );

    /**
     * @dev Emits when user evolve MetaCell and split MDMA token
     * @param receiver is receiver address
     * @param amount is MDMA token amount that split for user
     * @param timestamp is is the time that event emitted
     */
    event SplitMDMAToken(
        address indexed receiver,
        uint indexed amount,
        uint timestamp
    );

    /**
     * @dev Emits when user evolve MetaCell and split Enhancer
     * @param receiver is receiver address
     * @param enhancerId is id of Enhancer
     * @param timestamp is is the time that event emitted
     */
    event SplitEnhancer(
        address indexed receiver,
        uint indexed enhancerId,
        uint timestamp
    );

    /**
     *  Event to show the amount
     *  of blocks for next evolution
     *  @dev has to be emited in `boostCell`
     */
    event EvolutionTimeReduced(
        string name,
        CellData.Cell cell,
        uint timestamp
    );

    /**
     *  Event to show that price for boost is changed
     *   @dev has to be emited in `setBoostPerBlockPrice`
     */
    event BoostPricePerBlockChanged(uint indexed _price, uint timestamp);

    /**
     * @dev Emits when user creates MetaCell from ScientistId
     * @param ownerOf is owner of Scientist token id
     * @param tokenId is id of Scientist NFT
     * @param timestamp is the time that event emitted
     */
    event NewMetaCellCreated(
        address indexed ownerOf,
        uint indexed tokenId,
        uint timestamp
    );

    /**
     * @dev Emits when user adds NFT metadata 
     * @param owner is caller's address
     * @param tokenURI is the URI of NFT
     * @param tokenId is id of NFT
     * @param timestamp is the time that event emitted
     */
    event AddNFT(
        address indexed owner,
        string tokenURI,
        uint indexed tokenId,
        uint timestamp
    );

    /**
     * @dev Emits when user uses NFT for MetaCell 
     * @param owner is caller's address
     * @param tokenId is the id of MetaCell
     * @param nftId is the id of NFT
     * @param timestamp is the time that event emitted
     */
    event UseNFT(
        address indexed owner,
        uint indexed tokenId,
        uint indexed nftId,
        uint timestamp
    );
}

// File: contracts\laboratory\interfaces\ILaboratoryGetter.sol


pragma solidity ^0.8.3;
interface ILaboratoryGetter {
    /**
     *  @dev returns price for boost per 1 block
     */
    function getBoostPerBlockPrice() external view returns (uint256);

    /**
     *  @dev calculates how many block can user burn
     *  with passed amount
     */
    function getBoostedBlocks(uint256 _price) external view returns (uint256);

    function getMetaCellByID(uint256 tokenId)
        external
        view
        returns (CellData.Cell memory);

    function getMarketPlace() external view returns (address);

    function getWalletFee() external view returns (address);
}

// File: contracts\laboratory\interfaces\ILaboratorySetter.sol


pragma solidity ^0.8.3;

interface ILaboratorySetter {
    /**
     * @dev Sets nano cell address
     * can be used only for owner
     */
    function setNanoCell(address _token) external;

    /**
     * @dev Sets meta fuel address
     * can be used only for owner
     */
    function setMetaFuel(address _token) external;

    /**
     * @dev function that sets ERC721 token address.
     * @param _address is address of ERC721 token
     */
    function setScientist(address _address) external;

    /**
     *  @dev sets address for random contract
     */
    function setRandom(address randomAddress) external;

    /**
     *  @dev specifies price for boost per 1 block
     * could be called by contract owner
     */
    function setBoostPerBlockPrice(uint256 _price) external;

    function setMarketPlace(address newMarketPlace) external;

    function setWalletFee(address newWalletFee) external;
}

// File: contracts\laboratory\interfaces\ISeed.sol


pragma solidity ^0.8.3;

interface ISeed {
    /**
     * @dev Returns seed
     */
    function getSeed() external view returns (uint256);

    /**
     * @dev Sets seed value
     */
    function setSeed(uint256 seed) external;
}

// File: contracts\laboratory\interfaces\ILaboratory.sol


pragma solidity ^0.8.3;
interface ILaboratory is
    ILaboratoryEvent,
    ILaboratoryGetter,
    ILaboratorySetter,
    ISeed
{
    /**
     *  @dev user can evolve his token
     *  to a new stage
     *  can be called by any user
     *  NewEvoutionCompleted has to be emmited with string "Evolve"
     */
    function evolve(uint256 _tokenID, uint256 _enhancerID, uint256 _scientistID) external;

    /**
     *  @dev user can mutate his token
     *  with external nft metadata
     *  can be called by any user
     *  NewEvoutionCompleted has to be emmited with string "Mutate"
     */
    function mutate(uint256 _cellId, uint256 _nftId) external;

    /**
     *  @dev user can boost his
     *  awaiting time
     *  can be called by any user
     *  EvolutionTimeReduced has to be emmited
     */
    function boostCell(uint256 _tokenID, uint256 _amount) external;

    /**
     *  @dev Create additional MetaCells
     *  updateChildChainManager() should be called before for owner
     */
    function createMetaCell(uint256 positionId) external;
}

// File: contracts\meta-cell\interfaces\ICellRepository.sol


pragma solidity ^0.8.3;
/**
 * @title Interface for interaction with particular cell
 */
interface ICellRepository {
    

    function addMetaCell(CellData.Cell memory _cell) external;

    function removeMetaCell(uint256 _tokenId, address _owner) external;

    /**
     * @dev Returns meta cell id's for particular user
     */
    function getUserMetaCellsIndexes(address _user)
        external
        view
        returns (uint256[] memory);

    function updateMetaCell(CellData.Cell memory _cell, address _owner)
        external;

    function getMetaCell(uint256 _tokenId)
        external
        view
        returns (CellData.Cell memory);
}

// File: contracts\interfaces\IEnhancerRepository.sol


pragma solidity ^0.8.3;
/**
 * @title Interface for interaction with particular cell
 */
abstract contract IEnhancerRepository {
    using SafeMath for uint256;
    /**
     * @dev emits enhancer amount
     */
    event EnhancerAmountChanged(uint256, uint256);
    /**
     * @dev emits when enhancer is added
     */
    event EnhancerAdded(uint256);

    CellEnhancer.Enhancer[] private availableEnhancers;

    struct enhancer {
        uint256 id;
        uint256 amount;
    }
    mapping(address => enhancer[]) internal ownedEnhancers;

    /**
     * @dev Adds available enhancers to storage
     */
    function addAvailableEnhancers(CellEnhancer.Enhancer memory _enhancer)
        external
        virtual;

    function _addAvailableEnhancers(CellEnhancer.Enhancer memory _enhancer)
        internal
    {
        uint256 _index = findEnhancerById(_enhancer.id);
        if (_index == type(uint256).max) {
            availableEnhancers.push(_enhancer);
        } else {
            availableEnhancers[_index] = _enhancer;
        }
    }

    /**
     * @dev Returns enhancer info by it's id
     */
    function getEnhancerInfo(uint256 _id)
        public
        view
        returns (CellEnhancer.Enhancer memory)
    {
        uint256 _index = findEnhancerById(_id);
        if (_index == type(uint256).max) {
            CellEnhancer.Enhancer memory _enhancer;
            _enhancer.id = type(uint256).max;
            return _enhancer;
        }
        return availableEnhancers[_index];
    }

    /**
     * @dev Increases amount of enhancers of particular user
     */
    function increaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) external virtual;

    function _increaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) internal {
        uint256 len = ownedEnhancers[_owner].length;
        for (uint256 i = 0; i < len; i++) {
            if (ownedEnhancers[_owner][i].id == _id) {
                ownedEnhancers[_owner][i].amount = ownedEnhancers[_owner][i]
                    .amount
                    .add(_amount);
                return;
            }
        }

        enhancer memory _enhancer = enhancer(_id, _amount);
        ownedEnhancers[_owner].push(_enhancer);
    }

    /**
     * @dev Decreases available user enhancers
     */
    function decreaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) external virtual;

    function _decreaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) internal {
        uint256 index = type(uint256).max;
        for (uint256 i = 0; i < ownedEnhancers[_owner].length; i++) {
            if (ownedEnhancers[_owner][i].id == _id) {
                ownedEnhancers[_owner][i].amount = ownedEnhancers[_owner][i]
                    .amount
                    .sub(_amount);
                index = i;
                break;
            }
        }

        if (
            index != type(uint256).max &&
            ownedEnhancers[_owner][index].amount == 0
        ) {
            ownedEnhancers[_owner][index] = ownedEnhancers[_owner][
                ownedEnhancers[_owner].length - 1
            ];
            ownedEnhancers[_owner].pop();
        }
    }

    /**
     * @dev Returns ids of all available enhancers for particular user
     */
    function getUserEnhancers(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 len = ownedEnhancers[_owner].length;
        uint256[] memory _ids = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            _ids[i] = ownedEnhancers[_owner][i].id;
        }
        return _ids;
    }

    /**
     * @dev Returns types of all enhancers that are stored
     */
    function getEnhancerTypes() external view returns (uint8[] memory) {
        uint8[] memory _types = new uint8[](availableEnhancers.length);

        for (uint256 index = 0; index < availableEnhancers.length; index++) {
            _types[index] = availableEnhancers[index].typeId;
        }

        return _types;
    }

    /**
     * @dev Returns amount of enhancers by it"s id
     * for particular user
     */
    function getEnhancersAmount(address _owner, uint256 id)
        public
        view
        returns (uint256)
    {
        uint256 len = ownedEnhancers[_owner].length;
        for (uint256 index = 0; index < len; index++) {
            if (ownedEnhancers[_owner][index].id == id) {
                return ownedEnhancers[_owner][index].amount;
            }
        }
        return 0;
    }

    function findEnhancerById(uint256 _id) private view returns (uint256) {
        for (uint256 index = 0; index < availableEnhancers.length; index++) {
            if (_id == availableEnhancers[index].id) {
                return index;
            }
        }
        return type(uint256).max;
    }

    /**
     * @dev Returns all stored enhancer
     * that are available
     */
    function getAllEnhancers()
        external
        view
        returns (CellEnhancer.Enhancer[] memory)
    {
        return availableEnhancers;
    }
}

// File: contracts\interfaces\IExternalNftRepository.sol


pragma solidity ^0.8.3;
abstract contract IExternalNftRepository {
    struct NFT {
        uint256 tokenId;
        string metadataUri;
        bool isUsed;
    }

    using Counters for Counters.Counter;

    mapping(address => mapping(uint256 => NFT)) public nftAddressToMap;
    EnumerableSet.UintSet private nftIndexSet;
    Counters.Counter nftLatestId;

    /**
     * @dev Add NFT metadata uri to storage
     */
    function addNft(address _nftAddress, address _owner, uint _tokenId)
        external
        virtual;

    /**
     * @dev Returns token info by it's id for particular user
     */
    function getNft(uint256 _nftId, address _owner)
        external
        view
        virtual
        returns (NFT memory);

    function _addNft(string memory _metadataUri, address _owner) internal {
        nftLatestId.increment();
        uint256 newNftId = nftLatestId.current();

        NFT memory newNft = NFT(newNftId, _metadataUri, false);

        EnumerableSet.add(nftIndexSet, newNftId);

        nftAddressToMap[_owner][newNftId] = newNft;
    }

    function _getNft(uint256 _nftId, address _owner)
        internal
        view
        returns (NFT memory)
    {
        NFT memory nft;

        if (!EnumerableSet.contains(nftIndexSet, _nftId)) {
            nft.tokenId = type(uint256).max;
            return nft;
        }

        nft = nftAddressToMap[_owner][_nftId];
        return nft;
    }

    function _markNftAsUsed(uint256 _nftId, address _owner) internal {
        nftAddressToMap[_owner][_nftId].isUsed = true;
    }
}

// File: contracts\interfaces\IRandom.sol


pragma solidity ^0.8.3;

interface IRandom {
    /**
     * @dev Picks random image depends on the token stage
     */
    function getRandomVariant() external view returns (uint256);

    /**
     * @dev Picks random class for token during evolution from
     * [COMMON, SPLITTABLE_NANO, SPLITTABLE_MAD, FINISHED]
     */
    function getRandomClass() external view returns (uint8);

    /**
     * @dev Check whether token could be splittable
     */
    function getSplittableWithIncreaseChance(uint16 probability, uint256 increasedChanceSplitNanoCell)
        external
        returns (uint8);

    /**
     * @dev Generates next stage for token during evoution
     * in rage of [0;5]
     */
    function getRandomStage(uint256 _stage, uint16 probabilityIncrease)
        external
        view
        returns (uint256);

    /**
     * @dev Generates evolution time
     */
    function getEvolutionTime(uint256 decreasedRate) external returns (uint256);

    function randomEnhancerId(uint limit) external view returns (uint randomId);

    function randomRateSplitMadToken() external view returns (uint amount);
}

// File: contracts\meta-cell\interfaces\IMetaCellCreator.sol


pragma solidity ^0.8.3;

interface IMetaCellCreator {
    function create(address account) external returns (uint tokenId);
}

// File: contracts\nano-cell\interfaces\INanoCellCreator.sol


pragma solidity ^0.8.3;

interface INanoCellCreator {
    function create(address account) external returns (uint tokenId);
}

// File: contracts\scientist-researcher\interfaces\IScientistResearcher.sol


pragma solidity ^0.8.3;

interface IScientistResearcher {
    /**
     * @dev Emits when Scientist research each technical
     * @param owner is owner address of Scientist
     * @param tokenId is id of Scientist
     * @param levelTechnical is the level of technical Scientist researched
     * @param technicalSkill is the skill code in the level of technical
     * @param timestamp is the time that event emitted
     */
    event ResearchTech(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed levelTechnical,
        uint256 technicalSkill,
        uint256 timestamp
    );

    /**
     * @dev Structure about level of technical level 1
     * Research these technicals opens access to paths towards level 2 scientific research
     * NOTE Explainations of params in structure:
     * `physics` - the level of technical Physics
     * `chemistry` - the level of technical Chemistry
     * `biology` - the level of technical Biology
     * `sociology` - the level of technical sociology
     * `mathematics` - the level of technical Methematics
     */
    struct TechnicalLevelOne {
        uint8 physics;
        uint8 chemistry;
        uint8 biology;
        uint8 sociology;
        uint8 mathematics;
    }

    /**
     * @dev Structure about level of technical level 2
     * Research these technicals opens access to paths towards level 3 scientific research
     * NOTE Explainations of params in structure:
     * `genetics` - the level of technical Genetics
     * `nutrition` - the level of technical Nutrition
     * `engineering` - the level of technical Engineering
     * `astroPhysics` - the level of technical Astro Physics
     * `economics` - the level of technical Economics
     * `computerScience` - the level of technical Computer Science
     * `quantumMechanics` - the level of technical Quantum Mechanics
     * `cliodynamics` - the level of technical Cliodynamics
     */
    struct TechnicalLevelTwo {
        uint8 genetics;
        uint8 nutrition;
        uint8 engineering;
        uint8 astroPhysics;
        uint8 economics;
        uint8 computerScience;
        uint8 quantumMechanics;
        uint8 cliodynamics;
    }

    /**
     * @dev Structure about level of technical level 3
     * Research these technicals opens access to paths towards level 4 scientific research
     * NOTE Explainations of params in structure:
     * `exometeorology` - the level of technical Exometeorology
     * `nutrigenomics` - the level of technical Nutrigenomics
     * `syntheticBiology` - the level of technical Synthetic Biology
     * `recombinatMemetics` - the level of technical Recombinat Memetics
     * `computationalLexicology` - the level of technical Computational Lexicology
     * `computationalEconomics` - the level of technical Computational Economics
     * `computationalSociology` - the level of technical Computational Sociology
     * `cognitiveEconomics` - the level of technical Cognitive Economics
     */
    struct TechnicalLevelThree {
        uint8 exometeorology;
        uint8 nutrigenomics;
        uint8 syntheticBiology;
        uint8 recombinatMemetics;
        uint8 computationalLexicology;
        uint8 computationalEconomics;
        uint8 computationalSociology;
        uint8 cognitiveEconomics;
    }

    /**
     * @dev Structure about level of technical level 4
     * Research these technicals opens access to paths towards level 5 scientific research
     * NOTE Explainations of params in structure:
     * `culturomics` - the level of technical Culturomics
     * `quantumBiology` - the level of technical QuantumBiology
     */
    struct TechnicalLevelFour {
        uint8 culturomics;
        uint8 quantumBiology;
    }

    /**
     * @dev Structure about level of technical level 4
     * Research these technicals opens access to paths towards level 5 scientific research
     * NOTE Explainations of params in structure:
     * `computationalSocialScience` - the level of technical Computational Social Science
     */
    struct TechnicalLevelFive {
        uint8 computationalSocialScience;
    }

    /**
     * @dev Structure about all the effects that Scientist gained when it had researched
     * NOTE Explainations of params in structure:
     * `chanceSplitNanoCell` - the rate increase for splitting NanoCell when user evolve MetaCell
     * `buffEvolveMetaCellTime` - the rate use for reducing waiting time when user evolve MetaCell
     * `plusAttributeForNanoCell` - the attributes increased for splitted NanoCell when user evolve MetaCell
     */
    struct SpecialEffect {
        uint8 chanceSplitNanoCell;
        uint8 buffEvolveMetaCellTime;
        uint8 plusAttributesForNanoCell;
    }

    enum TechSetLevelOne {
        PHYSICS,
        CHEMISTRY,
        BIOLOGY,
        SCIOLOGY,
        MATHEMATICS
    }

    enum TechSetLevelTwo {
        GENETICS,
        NUTRITION,
        ENGINEERING,
        ASTRO_PHYSICS,
        ECONOMICS,
        COMPUTER_SCIENCE,
        QUANTUM_MECHANICS,
        CLIODYNAMICS
    }

    enum TechSetLevelThree {
        EXOMETEOROLOGY,
        NUTRIGENOMICS,
        SYNTHETIC_BIOLOGY,
        RECOMBINAT_MEMETIC,
        COMPUTATIONAL_LEXICOLOGY,
        COMPUTATIONAL_ECONOMICS,
        COMPUTATIONAL_SOCIOLOGY,
        COGNITIVE_ECONOMICS
    }

    enum TechSetLevelFour {
        CULTUROMICS,
        QUANTUM_BIOLOGY
    }

    enum TechSetLevelFive {
        COMPUTAIONAL_SOCIAL_SCIENCE
    }

    enum SpecialSetEffect {
        CHANCE_SPLIT_NANO_CELL,
        BUFF_EVOLVE_META_CELL_TIME,
        PLUS_ATTRIBUTES_FOR_NANO_CELL
    }

    enum TechLevel {
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE
    }

    function getSpecialEffects(uint256 tokenId)
        external
        view
        returns (SpecialEffect memory);

    function researchTechLevelOne(uint256 tokenId, TechSetLevelOne tech)
        external;
    
    function researchTechLevelTwo(uint256 tokenId, TechSetLevelTwo tech)
        external;

    function researchTechLevelThree(uint256 tokenId, TechSetLevelThree tech)
        external;

    function researchTechLevelFour(uint256 tokenId, TechSetLevelFour tech)
        external;

    function researchTechLevelFive(uint256 tokenId, TechSetLevelFive tech)
        external;
}

// File: contracts\laboratory\Laboratory.sol


pragma solidity ^0.8.3;
contract Laboratory is
    ILaboratory,
    IAdmin,
    IEnhancerRepository,
    IExternalNftRepository,
    Ownable
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    EnumerableSet.UintSet private scientistsUsed;

    address private random;
    address private metaCell;
    address private nanoCell;
    address private madToken;
    address private scientistToken;
    address private scientistResearcher;
    address private marketPlace;
    address private walletFee;

    uint16 private constant MAX_LEVEL_OF_EVOLUTION = 1000;
    uint256 private BOOST_PER_BLOCK_PRICE = 1; //TODO: change to real price
    uint256 private constant NUM_OPTIONS = 1000;

    modifier isAllowedToBoost(uint256 _tokenID, address owner) {
        CellData.Cell memory cell = ICellRepository(metaCell).getMetaCell(
            _tokenID
        );
        require(cell.user == msg.sender, "You are not an owner of token");
        require(cell.tokenId >= 0, "Non-existent cell");
        require(
            cell.class != CellData.Class.FINISHED,
            "You are not able to evolve more"
        );
        require(
            cell.nextEvolutionBlock != type(uint256).max,
            "You have the highest level"
        );
        _;
    }

    constructor(
        address _scientist,
        address _scientistResearcher,
        address _metaCell,
        address _nanoCell,
        address _metaFuel
    ) {
        _addAdmin(msg.sender);
        walletFee = msg.sender;
        scientistToken = _scientist;
        scientistResearcher = _scientistResearcher;
        metaCell = _metaCell;
        nanoCell = _nanoCell;
        madToken = _metaFuel;
        BOOST_PER_BLOCK_PRICE = 1000000000000000000;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        address owner = owner();
        super.transferOwnership(newOwner);
        _addAdmin(newOwner);
        _removeAdmin(owner);
    }

    function addAdmin(address _admin) external override onlyOwner {
        _addAdmin(_admin);
    }

    function removeAdmin(address _admin) external override onlyOwner {
        _removeAdmin(_admin);
    }

    function setRandom(address _random) external override onlyOwner {
        require(_random != address(0), "Address should not be empty");

        random = _random;
    }

    function setNanoCell(address _token) external override onlyOwner {
        require(_token != address(0), "Address should not be empty");
        nanoCell = _token;
    }

    function setScientist(address _token) external override onlyOwner {
        require(_token != address(0), "Address should not be empty");
        scientistToken = _token;
    }

    function setMetaFuel(address _token) external override onlyOwner {
        require(_token != address(0), "Address should not be empty");
        madToken = _token;
    }

    function evolve(
        uint256 _tokenID,
        uint256 _enhancerID,
        uint256 _scientistID
    ) external override {
        CellData.Cell memory cell = ICellRepository(metaCell).getMetaCell(
            _tokenID
        );
        bool isExist = true;
        if (
            cell.tokenId == 0 &&
            _tokenID != 0 &&
            IERC721(metaCell).ownerOf(_tokenID) == msg.sender
        ) {
            isExist = false;
            cell.tokenId = _tokenID;
            cell.user = msg.sender;
            cell.class = CellData.Class.INIT;
        }
        require(cell.tokenId != 0, "Non-existent cell");

        CellEnhancer.Enhancer memory enhancer;
        if (_enhancerID != 0) {
            enhancer = getEnhancerInfo(_enhancerID);
            require(enhancer.id != type(uint256).max, "Non-existent enhancer");
            require(
                getEnhancersAmount(msg.sender, _enhancerID) > 0,
                "Insufficient amount of enhancers"
            );
        }

        cell = _evolve(cell, enhancer, _scientistID);
        emit NewEvolutionCompleted("Evolve", cell, block.timestamp);

        if (_enhancerID != 0) {
            _decreaseEnhancersAmount(msg.sender, _enhancerID, 1);
            emit EnhancerAmountChanged(_enhancerID, 1);
        }
        if (CellData.isSplittable(cell.class)) {
            _processSplit(cell);
        }

        if (isExist) {
            ICellRepository(metaCell).updateMetaCell(cell, msg.sender);
        } else {
            ICellRepository(metaCell).addMetaCell(cell);
        }
    }

    function _processSplit(CellData.Cell memory cell) private {
        if (CellData.Class(cell.class) == CellData.Class.SPLITTABLE_NANO) {
            uint256 tokenId = INanoCellCreator(nanoCell).create(msg.sender);
            emit SplitNanoCell(msg.sender, tokenId, block.timestamp);
        } else if (
            CellData.Class(cell.class) == CellData.Class.SPLITTABLE_MAD
        ) {
            uint256 amount = IRandom(random).randomRateSplitMadToken() *
                10**IERC20Metadata(madToken).decimals();
            IMintable(madToken).mint(msg.sender, amount);
            emit SplitMDMAToken(msg.sender, amount, block.timestamp);
        } else if (
            CellData.Class(cell.class) == CellData.Class.SPLITTABLE_ENHANCER
        ) {
            uint256 randomEnhancerId = IRandom(random).randomEnhancerId(
                IMarketPlace(marketPlace).numberOfEnhancersType()
            );
            _increaseEnhancersAmount(msg.sender, randomEnhancerId, 1);
            emit SplitEnhancer(msg.sender, randomEnhancerId, block.timestamp);
        }
        cell.class = CellData.Class.COMMON;
    }

    function _evolve(
        CellData.Cell memory cell,
        CellEnhancer.Enhancer memory _enhancer,
        uint256 _scientistId
    ) private returns (CellData.Cell memory) {
        IScientistResearcher.SpecialEffect
            memory specialEffects = IScientistResearcher(scientistResearcher)
                .getSpecialEffects(_scientistId);
        if (_scientistId != 0) {
            require(
                msg.sender == IERC721(scientistToken).ownerOf(_scientistId)
            );
        }

        require(cell.user == msg.sender, "You are not an owner of token");
        require(
            cell.stage < MAX_LEVEL_OF_EVOLUTION,
            "You are not able to evolve more"
        );
        require(
            cell.class != CellData.Class.FINISHED,
            "You are not able to evolve more"
        );
        require(
            cell.nextEvolutionBlock <= block.number,
            "You can't evolve right now"
        );

        if (
            CellEnhancer.convertEnhancer(_enhancer.typeId) ==
            CellEnhancer.EnhancerType.STAGE_ENHANCER
        ) {
            cell.stage = IRandom(random).getRandomStage(
                cell.stage,
                _enhancer.probability
            );
        } else {
            cell.stage = IRandom(random).getRandomStage(cell.stage, 0);
        }

        if (
            CellEnhancer.convertEnhancer(_enhancer.typeId) ==
            CellEnhancer.EnhancerType.SPLIT_ENHANCER
        ) {
            cell.class = CellData.Class(
                IRandom(random).getSplittableWithIncreaseChance(
                    _enhancer.probability,
                    specialEffects.chanceSplitNanoCell
                )
            );
        } else {
            cell.class = CellData.Class(IRandom(random).getRandomClass());
        }

        cell.nextEvolutionBlock = IRandom(random).getEvolutionTime(
            specialEffects.buffEvolveMetaCellTime
        );
        if (cell.stage > MAX_LEVEL_OF_EVOLUTION) {
            cell.stage = MAX_LEVEL_OF_EVOLUTION;
        }
        if (
            cell.class == CellData.Class.FINISHED ||
            cell.stage == MAX_LEVEL_OF_EVOLUTION
        ) {
            cell.nextEvolutionBlock = type(uint256).max;
        }
        cell.variant = IRandom(random).getRandomVariant();
        return cell;
    }

    function boostCell(uint256 _tokenID, uint256 _amount)
        external
        override
        isAllowedToBoost(_tokenID, msg.sender)
    {
        require(
            IERC20(madToken).balanceOf(msg.sender) >= _amount,
            "Not enough funds"
        );
        CellData.Cell memory cell = ICellRepository(metaCell).getMetaCell(
            _tokenID
        );
        require(cell.tokenId >= 0, "Non-existent cell");
        uint256 _blocksAmount = _getBoostedBlocks(_amount);

        if (block.number >= cell.nextEvolutionBlock.sub(_blocksAmount)) {
            cell.nextEvolutionBlock = block.number;
        } else {
            cell.nextEvolutionBlock = cell.nextEvolutionBlock.sub(
                _blocksAmount
            );
        }
        require(
            IERC20(madToken).transferFrom(msg.sender, address(this), _amount),
            "Should be true"
        );
        ICellRepository(metaCell).updateMetaCell(cell, msg.sender);

        emit EvolutionTimeReduced("BoostCell", cell, block.timestamp);
    }

    function mutate(uint256 _cellId, uint256 _nftId) external override {
        CellData.Cell memory oldCell = ICellRepository(metaCell).getMetaCell(
            _cellId
        );
        NFT memory nft = _getNft(_nftId, msg.sender);

        CellData.Cell memory newCell = _mergeWithNft(oldCell, nft);
        _markNftAsUsed(_nftId, msg.sender);
        ICellRepository(metaCell).updateMetaCell(newCell, msg.sender);

        emit UseNFT(msg.sender, _cellId, _nftId, block.timestamp);
        emit NewEvolutionCompleted("Mutate", newCell, block.timestamp);
    }

    // NFT should be used somehow
    function _mergeWithNft(CellData.Cell memory _cellA, NFT memory)
        private
        returns (CellData.Cell memory)
    {
        CellData.Cell memory newCell = _createNewMetaCellData(
            msg.sender,
            _cellA.tokenId
        );
        return newCell;
    }

    function getSeed() external view override returns (uint256) {
        return ISeed(random).getSeed();
    }

    function setSeed(uint256 seed) external override isAdmin {
        ISeed(random).setSeed(seed);
    }

    function _createNewMetaCellData(address tokenOwner, uint256 _numOptions)
        private
        returns (CellData.Cell memory)
    {
        CellData.Class newClass = CellData.Class(
            IRandom(random).getRandomClass()
        );

        if (newClass == CellData.Class.FINISHED) {
            newClass = CellData.Class.COMMON;
        }
        uint256 newStage = 0;
        uint256 newEvoTime = IRandom(random).getEvolutionTime(0);

        uint256 variant = IRandom(random).getRandomVariant();
        CellData.Cell memory newCell = CellData.Cell({
            tokenId: _numOptions,
            user: tokenOwner,
            class: newClass,
            stage: newStage,
            nextEvolutionBlock: newEvoTime,
            variant: variant,
            onSale: false,
            price: 0
        });

        return newCell;
    }

    function setBoostPerBlockPrice(uint256 _price) external override isAdmin {
        BOOST_PER_BLOCK_PRICE = _price;
        emit BoostPricePerBlockChanged(_price, block.timestamp);
    }

    function getBoostPerBlockPrice() public view override returns (uint256) {
        return BOOST_PER_BLOCK_PRICE;
    }

    function getBoostedBlocks(uint256 _price)
        external
        view
        override
        returns (uint256)
    {
        return _getBoostedBlocks(_price);
    }

    function _getBoostedBlocks(uint256 _price) private view returns (uint256) {
        return _price.div(BOOST_PER_BLOCK_PRICE);
    }

    /**
     * @dev Calculates how much money needs to user to be ready to
     * run evolve
     */
    function getAmountForNextEvolution(uint256 _tokenID)
        external
        view
        returns (uint256)
    {
        CellData.Cell memory cell = ICellRepository(metaCell).getMetaCell(
            _tokenID
        );
        if (cell.nextEvolutionBlock <= block.number) {
            return 0;
        }
        return
            cell.nextEvolutionBlock.sub(block.number).mul(
                getBoostPerBlockPrice()
            );
    }

    function addAvailableEnhancers(CellEnhancer.Enhancer memory _enhancer)
        external
        override
        isAdmin
    {
        super._addAvailableEnhancers(_enhancer);
        emit EnhancerAdded(_enhancer.id);
    }

    function increaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) external override isAdmin {
        super._increaseEnhancersAmount(_owner, _id, _amount);
        emit EnhancerAmountChanged(_id, _amount);
    }

    function decreaseEnhancersAmount(
        address _owner,
        uint256 _id,
        uint256 _amount
    ) external override isAdmin {
        super._decreaseEnhancersAmount(_owner, _id, _amount);
        emit EnhancerAmountChanged(_id, _amount);
    }

    function addNft(
        address _nftAddress,
        address _owner,
        uint256 _tokenId
    ) external override {
        require(
            IERC721(_nftAddress).ownerOf(_tokenId) == _owner,
            "Incorrect owner of NFT"
        );
        string memory _metadataUri = IERC721Metadata(_nftAddress).tokenURI(
            _tokenId
        );
        require(
            bytes(_metadataUri).length != 0 && _owner != address(0),
            "Incorrect URI or owner address."
        );
        super._addNft(_metadataUri, _owner);
        emit AddNFT(
            _owner,
            _metadataUri,
            nftLatestId.current(),
            block.timestamp
        );
    }

    function getNft(uint256 _nftId, address _owner)
        external
        view
        override
        returns (NFT memory)
    {
        return super._getNft(_nftId, _owner);
    }

    function isCanCreateMetaCell(uint256 positionId)
        external
        view
        returns (bool)
    {
        return !EnumerableSet.contains(scientistsUsed, positionId);
    }

    function createMetaCell(uint256 positionId) external override {
        require(
            IERC721(scientistToken).ownerOf(positionId) == msg.sender,
            "Caller is not ower of Scientist"
        );
        require(
            !EnumerableSet.contains(scientistsUsed, positionId),
            "Already used scientist"
        );
        EnumerableSet.add(scientistsUsed, positionId);
        uint256 metaCellId = IMetaCellCreator(metaCell).create(msg.sender);
        emit NewMetaCellCreated(msg.sender, metaCellId, block.timestamp);
    }

    function getMetaCellByID(uint256 tokenId)
        external
        view
        override
        returns (CellData.Cell memory)
    {
        return ICellRepository(metaCell).getMetaCell(tokenId);
    }

    function setMarketPlace(address newMarketPlace)
        external
        override
        onlyOwner
    {
        marketPlace = newMarketPlace;
        _addAdmin(marketPlace);
    }

    function getMarketPlace() external view override returns (address) {
        return marketPlace;
    }

    function getWalletFee() external view override returns (address) {
        return walletFee;
    }

    function setWalletFee(address newWalletFee) external override onlyOwner {
        walletFee = newWalletFee;
    }

    function withdrawFee() external isAdmin {
        require(msg.sender == walletFee, "Caller is not wallet fee");
        IERC20(madToken).transfer(
            msg.sender,
            IERC20(madToken).balanceOf(address(this))
        );
    }
}