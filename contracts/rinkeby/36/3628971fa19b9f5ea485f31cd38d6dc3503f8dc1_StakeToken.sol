/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)


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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)


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


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)


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
// File: @openzeppelin/contracts/access/Ownable.sol
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
/**
 * @title StakePool
 * @notice Represents a contract where a token owner has put her tokens up for others to stake and earn said tokens.
 */
contract StakeToken is ERC20, Ownable {
  using SafeMath for uint256;
  bool public contractIsRemoved = false;

  IERC20 private _rewardsToken;
  IERC721 private _stakedERC721;
  PoolInfo public pool;
  address private constant _burner = 0x000000000000000000000000000000000000dEaD;
  struct PoolInfo {
    address creator; // address of contract creator
    address tokenOwner; // address of original rewards token owner
    uint256 origTotSupply; // supply of rewards tokens put up to be rewarded by original owner
    uint256 curRewardsSupply; // current supply of rewards
    uint256 creationBlock; // block this contract was created
    uint256 totalTokensStaked; // current amount of tokens staked
    uint256 stakeTimeLockSec; // number of seconds after depositing the user is required to stake before unstaking
    uint256[8] alloc; // the reward amount per day for common NFT, rare NFT, queenNFT, hyperNFT
    uint256[8] totalKindNFT; // the total amount of common nft, rare NFT, queenNFT, hyperNFT
  }

  struct StakerInfo {
    uint256 blockOriginallyStaked; // block the user originally staked
    uint256 timeOriginallyStaked; // unix timestamp in seconds that the user originally staked
    uint256 blockLastHarvested; // the block the user last claimed/harvested rewards
    uint256[8] kindNFT; // the common NFT count, rare NFT, queen NFT, hyper NFT
    uint256[] nftTokenIds; // if this is an NFT staking pool, make sure we store the token IDs here
  }

  //number of stakers
  uint256 public totalStakers;

  // mapping of userAddresses => tokenAddresses that can
  // can be evaluated to determine for a particular user which tokens
  // they are staking.
  mapping(address => StakerInfo) public stakers;
  
  // mapping of userAddresses => total reward paid amount
  mapping(address => uint256) public totalRewardPaid;

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);

  /**
   * @notice The constructor for the Staking Token.
   */
  constructor(
  ) ERC20("stakingToken", "STT") {

      uint256 _rewardSupply;
    address _rewardsTokenAddr;
    address _stakedTokenAddr;
    address _originalTokenOwner;
    uint256[8] memory _alloc;
    uint256 _stakeTimeLockSec;
    _rewardSupply = 10000;
    _rewardsTokenAddr = 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8;
    _stakedTokenAddr = 0xD4Fc541236927E2EAf8F27606bD7309C1Fc2cbee;
    _originalTokenOwner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    _alloc = [uint256(40),45,50,55,70,80,100,120];
    _stakeTimeLockSec = 0;
    _rewardsToken = IERC20(_rewardsTokenAddr);
    _stakedERC721 = IERC721(_stakedTokenAddr);
    

    pool = PoolInfo({
      creator: msg.sender,
      tokenOwner: _originalTokenOwner,
      origTotSupply: _rewardSupply,
      curRewardsSupply: _rewardSupply,
      creationBlock: 0,
      totalTokensStaked: 0,
      stakeTimeLockSec: _stakeTimeLockSec,
      alloc: _alloc,
      totalKindNFT: [uint256(0),0,0,0,0,0,0,0]
    });
  }
  
  // SHOULD ONLY BE CALLED AT CONTRACT CREATION and allows changing
  // the initial supply if tokenomics of token transfer causes
  // the original staking contract supply to be less than the original
  function updateSupply(uint256 _newSupply) external {
    require(
      msg.sender == pool.creator,
      'only contract creator can update the supply'
    );
    pool.origTotSupply = _newSupply;
    pool.curRewardsSupply = _newSupply;
  }
  function stakedTokenAddress() external view returns (address) {
    return address(_stakedERC721);
  }

  function rewardsTokenAddress() external view returns (address) {
    return address(_rewardsToken);
  }

  function tokenOwner() external view returns (address) {
    return pool.tokenOwner;
  }

  function getStakedTokenIds(address userAddress) external view returns(uint256[] memory) {
    uint len =  stakers[userAddress].nftTokenIds.length;

    uint256[] memory ret = new uint256[](len);
    for (uint i = 0; i < len; i++) {
        ret[i] = stakers[userAddress].nftTokenIds[i];
    }
    return ret;
  }

  function removeStakeableTokens() external {
    require(
      msg.sender == pool.creator || msg.sender == pool.tokenOwner,
      'caller must be the contract creator or owner to remove stakable tokens'
    );
    _rewardsToken.transfer(pool.tokenOwner, pool.curRewardsSupply);
    pool.curRewardsSupply = 0;
    contractIsRemoved = true;
  }

  function stakeTokens(uint256[] memory _tokenIds, uint256[8] memory kindNFT) public {
    require(
      getLastStakableBlock(),
      'this farm is expired and no more stakers can be added'
    );

    if (balanceOf(msg.sender) > 0) {
      _harvestTokens(msg.sender);
    }

    uint256 _finalAmountTransferred;
    require(
        _tokenIds.length > 0,
        "you need to provide NFT token IDs you're staking"
    );

    for (uint256 _i = 0; _i < _tokenIds.length; _i++) {
        _stakedERC721.transferFrom(msg.sender, address(this), _tokenIds[_i]);
    }

    _finalAmountTransferred = _tokenIds.length;

    if (totalSupply() == 0) {
      pool.creationBlock = block.number;
    }

    if(balanceOf(msg.sender) == 0) {
      totalStakers++;
    }

    _mint(msg.sender, _finalAmountTransferred);

    StakerInfo storage _staker = stakers[msg.sender];
    _staker.blockOriginallyStaked = block.number;
    _staker.timeOriginallyStaked = block.timestamp;
    _staker.blockLastHarvested = block.number;
    _staker.kindNFT[0] = _staker.kindNFT[0].add(kindNFT[0]); //base nft
    _staker.kindNFT[1] = _staker.kindNFT[1].add(kindNFT[1]); //bronze nft
    _staker.kindNFT[2] = _staker.kindNFT[2].add(kindNFT[2]); //silver nft
    _staker.kindNFT[3] = _staker.kindNFT[3].add(kindNFT[3]); //gold nft
    _staker.kindNFT[4] = _staker.kindNFT[4].add(kindNFT[4]); //diamond nft
    _staker.kindNFT[5] = _staker.kindNFT[5].add(kindNFT[5]); //prism nft
    _staker.kindNFT[6] = _staker.kindNFT[6].add(kindNFT[6]); //1/1 nft
    _staker.kindNFT[7] = _staker.kindNFT[7].add(kindNFT[7]); //antagonist nft

    pool.totalKindNFT[0] = pool.totalKindNFT[0].add(kindNFT[0]);
    pool.totalKindNFT[1] =  pool.totalKindNFT[1].add(kindNFT[1]);
    pool.totalKindNFT[2] = pool.totalKindNFT[2].add(kindNFT[2]);
    pool.totalKindNFT[3] = pool.totalKindNFT[3].add(kindNFT[3]);
    pool.totalKindNFT[4] = pool.totalKindNFT[4].add(kindNFT[4]);
    pool.totalKindNFT[5] =  pool.totalKindNFT[5].add(kindNFT[5]);
    pool.totalKindNFT[6] = pool.totalKindNFT[6].add(kindNFT[6]);
    pool.totalKindNFT[7] = pool.totalKindNFT[7].add(kindNFT[7]);

    for (uint256 _i = 0; _i < _tokenIds.length; _i++) {
      _staker.nftTokenIds.push(_tokenIds[_i]);
    }

    _updNumStaked(_finalAmountTransferred, 'add');
    emit Deposit(msg.sender, _finalAmountTransferred);
  }

  // pass 'false' for _shouldHarvest for emergency unstaking without claiming rewards
  function unstakeTokens(bool _shouldHarvest) external {
    StakerInfo memory _staker = stakers[msg.sender];
    uint256 _userBalance = balanceOf(msg.sender);

    // allow unstaking if the user is emergency unstaking and not getting rewards or
    // if theres a time lock that it's past the time lock or
    // the contract rewards were removed by the original contract creator or
    // the contract is expired
    require(
      !_shouldHarvest ||
        block.timestamp >=
        _staker.timeOriginallyStaked.add(pool.stakeTimeLockSec) ||
        contractIsRemoved ||
        getLastStakableBlock(),
      'you have not staked for minimum time lock yet and the pool is not expired'
    );

    if (_shouldHarvest) {
      _harvestTokens(msg.sender);
    }

    uint256 _amountToRemoveFromStaked = _userBalance;

    transfer(_burner, _amountToRemoveFromStaked);

    for (uint256 _i = 0; _i < _staker.nftTokenIds.length; _i++) {
        _stakedERC721.transferFrom(
            address(this),
            msg.sender,
            _staker.nftTokenIds[_i]
        );
    }

    pool.totalKindNFT[0] = pool.totalKindNFT[0].sub(_staker.kindNFT[0]);
    pool.totalKindNFT[1] =  pool.totalKindNFT[1].sub(_staker.kindNFT[1]);
    pool.totalKindNFT[2] = pool.totalKindNFT[2].sub(_staker.kindNFT[2]);
    pool.totalKindNFT[3] = pool.totalKindNFT[3].sub(_staker.kindNFT[3]);
    pool.totalKindNFT[4] = pool.totalKindNFT[4].sub(_staker.kindNFT[4]);
    pool.totalKindNFT[5] =  pool.totalKindNFT[5].sub(_staker.kindNFT[5]);
    pool.totalKindNFT[6] = pool.totalKindNFT[6].sub(_staker.kindNFT[6]);
    pool.totalKindNFT[7] = pool.totalKindNFT[7].sub(_staker.kindNFT[7]);

    if (balanceOf(msg.sender) <= 0) {
      delete stakers[msg.sender];
      if (totalStakers > 0) {
        totalStakers--;
      }
    }

    _updNumStaked(_amountToRemoveFromStaked, 'remove');
    emit Withdraw(msg.sender, _amountToRemoveFromStaked);
  }

  function emergencyUnstake() external {
    StakerInfo memory _staker = stakers[msg.sender];
    uint256 _amountToRemoveFromStaked = balanceOf(msg.sender);
    require(
      _amountToRemoveFromStaked > 0,
      'user can only unstake if they have tokens in the pool'
    );

    transfer(_burner, _amountToRemoveFromStaked);

    for (uint256 _i = 0; _i < _staker.nftTokenIds.length; _i++) {
        _stakedERC721.transferFrom(
            address(this),
            msg.sender,
            _staker.nftTokenIds[_i]
        );
    }
    
    pool.totalKindNFT[0] = pool.totalKindNFT[0].sub(_staker.kindNFT[0]);
    pool.totalKindNFT[1] =  pool.totalKindNFT[1].sub(_staker.kindNFT[1]);
    pool.totalKindNFT[2] = pool.totalKindNFT[2].sub(_staker.kindNFT[2]);
    pool.totalKindNFT[3] = pool.totalKindNFT[3].sub(_staker.kindNFT[3]);
    pool.totalKindNFT[4] = pool.totalKindNFT[4].sub(_staker.kindNFT[4]);
    pool.totalKindNFT[5] =  pool.totalKindNFT[5].sub(_staker.kindNFT[5]);
    pool.totalKindNFT[6] = pool.totalKindNFT[6].sub(_staker.kindNFT[6]);
    pool.totalKindNFT[7] = pool.totalKindNFT[7].sub(_staker.kindNFT[7]);

    delete stakers[msg.sender];

    if (totalStakers > 0) {
      totalStakers--;
    }

    _updNumStaked(_amountToRemoveFromStaked, 'remove');
    emit Withdraw(msg.sender, _amountToRemoveFromStaked);
  }

  function harvestForUser(address _userAddr)
    external
    returns (uint256)
  {
    require(
      msg.sender == pool.creator || msg.sender == _userAddr,
      'can only harvest tokens for someone else if this was the contract creator'
    );

    uint256 _tokensToUser = _harvestTokens(_userAddr);

    return _tokensToUser;
  }

  function getTotalRewardPaid(address _userAddr) external view returns (uint256) {
    return totalRewardPaid[_userAddr];
  }

  function getTotalStakers() external view returns (uint256) {
    return totalStakers;
  }

  function getLastStakableBlock() public view returns (bool) {

    uint256 _rewardBaseAmount = pool.alloc[0].mul(pool.totalKindNFT[0]).mul(1e36);
    _rewardBaseAmount = _rewardBaseAmount.div(86400);
    uint256 _rewardBronzeAmount = pool.alloc[1].mul(pool.totalKindNFT[1]).mul(1e36);
    _rewardBronzeAmount = _rewardBronzeAmount.div(86400);
    uint256 _rewardSilverAmount = pool.alloc[2].mul(pool.totalKindNFT[2]).mul(1e36);
    _rewardSilverAmount = _rewardSilverAmount.div(86400);
    uint256 _rewardGoldAmount = pool.alloc[3].mul(pool.totalKindNFT[3]).mul(1e36);
    _rewardGoldAmount = _rewardGoldAmount.div(86400);
    uint256 _rewardDiamondAmount = pool.alloc[4].mul(pool.totalKindNFT[4]).mul(1e36);
    _rewardDiamondAmount = _rewardDiamondAmount.div(86400);
    uint256 _rewardPrismAmount = pool.alloc[5].mul(pool.totalKindNFT[5]).mul(1e36);
    _rewardPrismAmount = _rewardPrismAmount.div(86400);
    uint256 _rewardOneOfOneAmount = pool.alloc[6].mul(pool.totalKindNFT[6]).mul(1e36);
    _rewardOneOfOneAmount = _rewardOneOfOneAmount.div(86400);
    uint256 _rewardAnagonistAmount = pool.alloc[7].mul(pool.totalKindNFT[7]).mul(1e36);
    _rewardAnagonistAmount = _rewardAnagonistAmount.div(86400);

    uint256 _rewardAmount = _rewardBaseAmount.add(_rewardBronzeAmount);
    _rewardAmount = _rewardAmount.add(_rewardSilverAmount);
    _rewardAmount = _rewardAmount.add(_rewardGoldAmount);
    _rewardAmount = _rewardAmount.add(_rewardDiamondAmount);
    _rewardAmount = _rewardAmount.add(_rewardPrismAmount);
    _rewardAmount = _rewardAmount.add(_rewardOneOfOneAmount);
    _rewardAmount = _rewardAmount.add(_rewardAnagonistAmount);

    _rewardAmount = _rewardAmount.div(1e36);

    if(pool.curRewardsSupply > _rewardAmount)
      return true;
    else
      return false;
  }

  function calcHarvestTot(address _userAddr) public view returns (uint256) {
    StakerInfo memory _staker = stakers[_userAddr];

    if (
      _staker.blockLastHarvested >= block.number ||
      _staker.blockOriginallyStaked == 0 ||
      pool.totalTokensStaked == 0 ||
      !getLastStakableBlock()
    ) {
      return uint256(0);
    }

    uint256 _lastBlock = block.number;
    uint256 _nrOfBlocks = _lastBlock.sub(_staker.blockLastHarvested);
      
    uint256 _rewardBaseAmount = pool.alloc[0].mul(_staker.kindNFT[0]).mul(_nrOfBlocks).mul(1e36).div(86400);
    uint256 _rewardBronzeAmount = pool.alloc[1].mul(_staker.kindNFT[1]).mul(_nrOfBlocks).mul(1e36).div(86400);
    uint256 _rewardSilverAmount = pool.alloc[2].mul(_staker.kindNFT[2]).mul(_nrOfBlocks).mul(1e36).div(86400);
    uint256 _rewardGoldAmount = pool.alloc[3].mul(_staker.kindNFT[3]).mul(_nrOfBlocks).mul(1e36).div(86400);
    uint256 _rewardDiamondAmount = pool.alloc[4].mul(_staker.kindNFT[4]).mul(_nrOfBlocks).mul(1e36).div(86400);
    uint256 _rewardPrismAmount = pool.alloc[5].mul(_staker.kindNFT[5]).mul(_nrOfBlocks).mul(1e36).div(86400);
    uint256 _rewardOneOfOneAmount = pool.alloc[6].mul(_staker.kindNFT[6]);
    _rewardOneOfOneAmount = _rewardOneOfOneAmount.mul(_nrOfBlocks).mul(1e36).div(86400);
    uint256 _rewardAnagonistAmount = pool.alloc[7].mul(_staker.kindNFT[7]);
    _rewardAnagonistAmount = _rewardAnagonistAmount.mul(_nrOfBlocks).mul(1e36).div(86400);

    uint256 _rewardAmount =  _rewardBaseAmount.add(_rewardBronzeAmount).add(_rewardSilverAmount).add(_rewardGoldAmount);
    _rewardAmount = _rewardAmount.add(_rewardDiamondAmount).add(_rewardPrismAmount).add(_rewardOneOfOneAmount).add(_rewardAnagonistAmount).div(1e36);

    return _rewardAmount;
  }

  function _harvestTokens(address _userAddr) private returns (uint256) {
    StakerInfo storage _staker = stakers[_userAddr];
    require(_staker.blockOriginallyStaked > 0, 'user must have tokens staked');

    uint256 _num2Trans = calcHarvestTot(_userAddr);
    if (_num2Trans > 0) {
      require(
        _rewardsToken.transfer(_userAddr, _num2Trans),
        'unable to send user their harvested tokens'
      );
      pool.curRewardsSupply = pool.curRewardsSupply.sub(_num2Trans);
    }
 
    _staker.blockLastHarvested = block.number;

    totalRewardPaid[_userAddr] = totalRewardPaid[_userAddr].add(_num2Trans);

    return _num2Trans;
  }

  // update the amount currently staked after a user harvests
  function _updNumStaked(uint256 _amount, string memory _operation) private {
    if (_compareStr(_operation, 'remove')) {
      pool.totalTokensStaked = pool.totalTokensStaked.sub(_amount);
    } else {
      pool.totalTokensStaked = pool.totalTokensStaked.add(_amount);
    }
  }

  function _compareStr(string memory a, string memory b)
    private
    pure
    returns (bool)
  {
    return (keccak256(abi.encodePacked((a))) ==
      keccak256(abi.encodePacked((b))));
  }
}