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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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
        address owner = _ownerOf(tokenId);
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
            "ERC721: approve caller is not token owner or approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
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
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "src/ReferralSystem.sol";
import "src/RNSourceController.sol";
import "src/staking/Staking.sol";
import "src/LotterySetup.sol";
import "src/TicketUtils.sol";

/// @dev Lottery contract
/// It runs `selectionSize` / `selectionMax` type of lottery.
/// User buys the ticket by selecting total of `selectionSize` numbers from [1, selectionMax] range.
/// Ticket price is paid each time user buys a ticket.
/// Part of the price is staking reward, which is claimable to `stakingRewardRecipient`.
/// Part of the price is frontend reward which is claimable by frontend operators selling the ticket.
/// All fees, as well as rewards are paid in `rewardToken`.
/// All prizes are dynamic and dependant on the actual ticket sales.
contract Lottery is ILottery, Ticket, LotterySetup, ReferralSystem, RNSourceController {
    using SafeERC20 for IERC20;
    using TicketUtils for uint256;

    uint256 private claimedStakingRewardAtTicketId;
    mapping(address => uint256) private frontendDueTicketSales;
    mapping(uint128 => mapping(uint120 => uint256)) private unclaimedCount;

    address public immutable override stakingRewardRecipient;

    uint256 public override lastDrawFinalTicketId;

    bool public override drawExecutionInProgress;
    uint128 public override currentDraw;

    mapping(uint128 => uint120) public override winningTicket;
    mapping(uint128 => mapping(uint8 => uint256)) public override winAmount;

    mapping(uint128 => uint256) public override ticketsSold;
    int256 public override currentNetProfit;

    /// @dev Checks if ticket is a valid ticket, and reverts if invalid
    /// @param ticket Ticket being checked
    modifier requireValidTicket(uint256 ticket) {
        if (!ticket.isValidTicket(selectionSize, selectionMax)) {
            revert InvalidTicket();
        }
        _;
    }

    /// @dev Checks if we are not executing draw already.
    modifier whenNotExecutingDraw() {
        if (drawExecutionInProgress) {
            revert DrawAlreadyInProgress();
        }
        _;
    }

    /// @dev Checks if draw is being executed right now.
    modifier onlyWhenExecutingDraw() {
        if (!drawExecutionInProgress) {
            revert DrawNotInProgress();
        }
        _;
    }

    /// @dev Checks that ticket owner is caller of the function. Reverts if not called by ticket owner.
    /// @param ticketId Ticket id we are checking owner for.
    modifier onlyTicketOwner(uint256 ticketId) {
        if (ownerOf(ticketId) != msg.sender) {
            revert UnauthorizedClaim(ticketId, msg.sender);
        }
        _;
    }

    /// @dev Constructs a new lottery contract.
    /// @param lotterySetupParams Setup parameter for the lottery.
    /// @param playerRewardFirstDraw Rewards for players in native token for first draw.
    /// @param playerRewardDecreasePerDraw Decrease of rewards for players per each draw.
    /// @param rewardsToReferrersPerDraw Percentage of native token rewards going to players.
    /// @param maxRNFailedAttempts Maximum number of consecutive failed attempts for random number source.
    /// @param maxRNRequestDelay Time considered as maximum delay for RN request.
    // solhint-disable-next-line code-complexity
    constructor(
        LotterySetupParams memory lotterySetupParams,
        uint256 playerRewardFirstDraw,
        uint256 playerRewardDecreasePerDraw,
        uint256[] memory rewardsToReferrersPerDraw,
        uint256 maxRNFailedAttempts,
        uint256 maxRNRequestDelay
    )
        Ticket()
        LotterySetup(lotterySetupParams)
        ReferralSystem(playerRewardFirstDraw, playerRewardDecreasePerDraw, rewardsToReferrersPerDraw)
        RNSourceController(maxRNFailedAttempts, maxRNRequestDelay)
    {
        stakingRewardRecipient = address(
            new Staking(
            this,
            lotterySetupParams.token,
            nativeToken,
            "Staked LOT",
            "stLOT"
            )
        );

        nativeToken.safeTransfer(msg.sender, ILotteryToken(address(nativeToken)).INITIAL_SUPPLY());
    }

    function buyTickets(
        uint128[] calldata drawIds,
        uint120[] calldata tickets,
        address frontend,
        address referrer
    )
        external
        override
        requireJackpotInitialized
        returns (uint256[] memory ticketIds)
    {
        if (drawIds.length != tickets.length) {
            revert DrawsAndTicketsLenMismatch(drawIds.length, tickets.length);
        }
        ticketIds = new uint256[](tickets.length);
        for (uint256 i = 0; i < drawIds.length; ++i) {
            ticketIds[i] = registerTicket(drawIds[i], tickets[i], frontend, referrer);
        }
        referralRegisterTickets(currentDraw, referrer, msg.sender, tickets.length);
        frontendDueTicketSales[frontend] += tickets.length;
        rewardToken.safeTransferFrom(msg.sender, address(this), ticketPrice * tickets.length);
    }

    function executeDraw() external override whenNotExecutingDraw {
        // slither-disable-next-line timestamp
        if (block.timestamp < drawScheduledAt(currentDraw)) {
            revert ExecutingDrawTooEarly();
        }
        returnUnclaimedJackpotToThePot();
        drawExecutionInProgress = true;
        requestRandomNumber();
        emit StartedExecutingDraw(currentDraw);
    }

    function unclaimedRewards(LotteryRewardType rewardType) external view override returns (uint256 rewards) {
        uint256 dueTicketsSold = (rewardType == LotteryRewardType.FRONTEND)
            ? frontendDueTicketSales[msg.sender]
            : nextTicketId - claimedStakingRewardAtTicketId;
        rewards = LotteryMath.calculateRewards(ticketPrice, dueTicketsSold, rewardType);
    }

    function claimRewards(LotteryRewardType rewardType) external override returns (uint256 claimedAmount) {
        address beneficiary = (rewardType == LotteryRewardType.FRONTEND) ? msg.sender : stakingRewardRecipient;
        claimedAmount = LotteryMath.calculateRewards(ticketPrice, dueTicketsSoldAndReset(beneficiary), rewardType);

        emit ClaimedRewards(beneficiary, claimedAmount, rewardType);
        rewardToken.safeTransfer(beneficiary, claimedAmount);
    }

    function claimable(uint256 ticketId) external view override returns (uint256 claimableAmount, uint8 winTier) {
        TicketInfo memory ticketInfo = ticketsInfo[ticketId];
        if (!ticketInfo.claimed) {
            uint120 _winningTicket = winningTicket[ticketInfo.drawId];
            winTier = TicketUtils.ticketWinTier(ticketInfo.combination, _winningTicket, selectionSize, selectionMax);
            if (block.timestamp <= ticketRegistrationDeadline(ticketInfo.drawId + LotteryMath.DRAWS_PER_YEAR)) {
                claimableAmount = winAmount[ticketInfo.drawId][winTier];
            }
        }
    }

    function claimWinningTickets(uint256[] calldata ticketIds) external override returns (uint256 claimedAmount) {
        uint256 totalTickets = ticketIds.length;
        for (uint256 i = 0; i < totalTickets; ++i) {
            claimedAmount += claimWinningTicket(ticketIds[i]);
        }
        rewardToken.safeTransfer(msg.sender, claimedAmount);
    }

    /// @dev Registers the ticket in the system. To be called when user is buying the ticket.
    /// @param drawId Draw identifier ticket is bought for.
    /// @param ticket Combination packed as uint120.
    function registerTicket(
        uint128 drawId,
        uint120 ticket,
        address frontend,
        address referrer
    )
        private
        beforeTicketRegistrationDeadline(drawId)
        requireValidTicket(ticket)
        returns (uint256 ticketId)
    {
        ticketId = mint(msg.sender, drawId, ticket);
        unclaimedCount[drawId][ticket]++;
        ticketsSold[drawId]++;
        emit NewTicket(currentDraw, ticketId, drawId, msg.sender, ticket, frontend, referrer);
    }

    /// @dev Finalizes the draw after getting random number from source.
    /// Calculates the winning ticket. Splits jackpot rewards if there are matching tickets.
    /// Stores claimable amounts for each win tier and calculates net profit.
    /// Triggers referral system's mint for current draw to split the incentives.
    /// @param randomNumber The number that is received from source.
    function receiveRandomNumber(uint256 randomNumber) internal override onlyWhenExecutingDraw {
        uint120 _winningTicket = TicketUtils.reconstructTicket(randomNumber, selectionSize, selectionMax);
        uint128 drawFinalized = currentDraw++;
        uint256 jackpotWinners = unclaimedCount[drawFinalized][_winningTicket];

        if (jackpotWinners > 0) {
            winAmount[drawFinalized][selectionSize] = drawRewardSize(drawFinalized, selectionSize) / jackpotWinners;
        } else {
            for (uint8 winTier = 1; winTier < selectionSize; ++winTier) {
                winAmount[drawFinalized][winTier] = drawRewardSize(drawFinalized, winTier);
            }
        }

        currentNetProfit = LotteryMath.calculateNewProfit(
            currentNetProfit,
            ticketsSold[drawFinalized],
            ticketPrice,
            jackpotWinners > 0,
            fixedReward(selectionSize),
            expectedPayout
        );
        winningTicket[drawFinalized] = _winningTicket;
        drawExecutionInProgress = false;

        uint256 ticketsSoldDuringDraw = nextTicketId - lastDrawFinalTicketId;
        lastDrawFinalTicketId = nextTicketId;
        referralDrawFinalize(drawFinalized, ticketsSoldDuringDraw);

        emit FinishedExecutingDraw(drawFinalized, randomNumber, _winningTicket);
    }

    function currentRewardSize(uint8 winTier) public view override returns (uint256 rewardSize) {
        return drawRewardSize(currentDraw, winTier);
    }

    function drawRewardSize(uint128 drawId, uint8 winTier) private view returns (uint256 rewardSize) {
        return LotteryMath.calculateReward(
            currentNetProfit,
            fixedReward(winTier),
            fixedReward(selectionSize),
            ticketsSold[drawId],
            winTier == selectionSize,
            expectedPayout
        );
    }

    function dueTicketsSoldAndReset(address beneficiary) private returns (uint256 dueTickets) {
        if (beneficiary == stakingRewardRecipient) {
            dueTickets = nextTicketId - claimedStakingRewardAtTicketId;
            claimedStakingRewardAtTicketId = nextTicketId;
        } else {
            dueTickets = frontendDueTicketSales[beneficiary];
            frontendDueTicketSales[beneficiary] = 0;
        }
    }

    function claimWinningTicket(uint256 ticketId) private onlyTicketOwner(ticketId) returns (uint256 claimedAmount) {
        uint256 winTier;
        (claimedAmount, winTier) = this.claimable(ticketId);
        if (claimedAmount == 0) {
            revert NothingToClaim(ticketId);
        }

        unclaimedCount[ticketsInfo[ticketId].drawId][ticketsInfo[ticketId].combination]--;
        markAsClaimed(ticketId);
        emit ClaimedTicket(msg.sender, ticketId, claimedAmount);
    }

    function returnUnclaimedJackpotToThePot() private {
        if (currentDraw >= LotteryMath.DRAWS_PER_YEAR) {
            uint128 drawId = currentDraw - LotteryMath.DRAWS_PER_YEAR;
            uint256 unclaimedJackpotTickets = unclaimedCount[drawId][winningTicket[drawId]];
            currentNetProfit += int256(unclaimedJackpotTickets * winAmount[drawId][selectionSize]);
        }
    }

    function requireFinishedDraw(uint128 drawId) internal view override {
        if (drawId >= currentDraw) {
            revert DrawNotFinished(drawId);
        }
    }

    function mintNativeTokens(address mintTo, uint256 amount) internal override {
        ILotteryToken(address(nativeToken)).mint(mintTo, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "src/interfaces/ILottery.sol";
import "src/PercentageMath.sol";

/// @dev Implementation of lottery jackpot and fees calculations
library LotteryMath {
    using PercentageMath for uint256;
    using PercentageMath for int256;

    /// @dev percentage of ticket price being paid for staking reward
    uint256 public constant STAKING_REWARD = 20 * PercentageMath.ONE_PERCENT;
    /// @dev percentage of ticket price being paid to frontend operator
    uint256 public constant FRONTEND_REWARD = 10 * PercentageMath.ONE_PERCENT;
    /// @dev Percentage of the ticket price that goes to the pot
    uint256 public constant TICKET_PRICE_TO_POT = PercentageMath.PERCENTAGE_BASE - STAKING_REWARD - FRONTEND_REWARD;
    /// @dev safety margin used to calculate excess pot, in percentage
    uint256 public constant SAFETY_MARGIN = 67 * PercentageMath.ONE_PERCENT;
    /// @dev Percentage of excess pot reserved for bonus
    uint256 public constant EXCESS_BONUS_ALLOCATION = 50 * PercentageMath.ONE_PERCENT;
    /// @dev Number of lottery draws per year
    uint128 public constant DRAWS_PER_YEAR = 52;

    /// @dev Calculates new cumulative net profit and excess pot
    /// To be called when the draw is finalized
    /// @param oldProfit Current cumulative net profit, calculated when previous draw was finalized
    /// @param ticketsSold Number of tickets sold for the draw that is currently finalized
    /// @param ticketPrice One ticket price expressed in reward token
    /// @param jackpotWon True if jackpot is won in this round
    /// @param fixedJackpotSize Fixed jackpot price
    /// @param expectedPayout Expected payout to players per ticket, expressed in `rewardToken`
    /// @return newProfit New value for the cumulative net profit after the draw is finalised
    function calculateNewProfit(
        int256 oldProfit,
        uint256 ticketsSold,
        uint256 ticketPrice,
        bool jackpotWon,
        uint256 fixedJackpotSize,
        uint256 expectedPayout
    )
        internal
        pure
        returns (int256 newProfit)
    {
        uint256 ticketsSalesToPot = (ticketsSold * ticketPrice).getPercentage(TICKET_PRICE_TO_POT);
        newProfit = oldProfit + int256(ticketsSalesToPot);

        uint256 expectedRewardsOut = jackpotWon
            ? calculateReward(oldProfit, fixedJackpotSize, fixedJackpotSize, ticketsSold, true, expectedPayout)
            : calculateMultiplier(calculateExcessPot(oldProfit, fixedJackpotSize), ticketsSold, expectedPayout)
                * ticketsSold * expectedPayout;

        newProfit -= int256(expectedRewardsOut);
    }

    /// @dev Calculates excess pot based on netProfit
    /// @param netProfit Current net profit of the lottery
    /// @param fixedJackpotSize Fixed portion of the jackpot
    /// @return excessPot Resulting excess pot
    function calculateExcessPot(int256 netProfit, uint256 fixedJackpotSize) internal pure returns (uint256 excessPot) {
        int256 excessPotInt = netProfit.getPercentageInt(SAFETY_MARGIN);
        excessPotInt -= int256(fixedJackpotSize);
        excessPot = excessPotInt > 0 ? uint256(excessPotInt) : 0;
    }

    /// @dev Calculates multiplier to be used when calculating non jackpot rewards
    /// @param excessPot Excess pot, calculated when previous draw was finalized
    /// @param ticketsSold Number of tickets sold in the current draw
    /// @param expectedPayout Expected payout to players per ticket, expressed in `rewardToken`
    /// @return bonusMulti Multiplier to be used when calculating rewards, with `PERCENTAGE_BASE` precision
    function calculateMultiplier(
        uint256 excessPot,
        uint256 ticketsSold,
        uint256 expectedPayout
    )
        internal
        pure
        returns (uint256 bonusMulti)
    {
        bonusMulti = PercentageMath.PERCENTAGE_BASE;
        if (excessPot > 0 && ticketsSold > 0) {
            bonusMulti += (excessPot * EXCESS_BONUS_ALLOCATION) / (ticketsSold * expectedPayout);
        }
    }

    /// @dev Calculates reward for the winning ticket
    /// @param netProfit Current cumulative net profit, calculated when previous draw was finalized
    /// @param fixedReward Fixed reward for particular tier of the winning ticket
    /// @param fixedJackpot Fixed portion of the jackpot
    /// @param ticketsSold Number of tickets sold in the current draw
    /// @param isJackpot If it is jackpot reward
    /// @param expectedPayout Expected payout to players per ticket, expressed in `rewardToken`
    /// @return reward Reward size for the winning ticket
    function calculateReward(
        int256 netProfit,
        uint256 fixedReward,
        uint256 fixedJackpot,
        uint256 ticketsSold,
        bool isJackpot,
        uint256 expectedPayout
    )
        internal
        pure
        returns (uint256 reward)
    {
        uint256 excess = calculateExcessPot(netProfit, fixedJackpot);
        reward = isJackpot
            ? fixedReward + excess.getPercentage(EXCESS_BONUS_ALLOCATION)
            : fixedReward.getPercentage(calculateMultiplier(excess, ticketsSold, expectedPayout));
    }

    /// @dev Calculate frontend rewards amount for specific tickets sold
    /// @param ticketPrice One lottery ticket price
    /// @param ticketsSold Amount of tickets sold since last fee payout
    /// @param rewardType Type of the reward we are calculating
    /// @return dueRewards Total due rewards for the particular reward
    function calculateRewards(
        uint256 ticketPrice,
        uint256 ticketsSold,
        LotteryRewardType rewardType
    )
        internal
        pure
        returns (uint256 dueRewards)
    {
        uint256 rewardPercentage = (rewardType == LotteryRewardType.FRONTEND) ? FRONTEND_REWARD : STAKING_REWARD;
        dueRewards = (ticketsSold * ticketPrice).getPercentage(rewardPercentage);
    }
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "src/PercentageMath.sol";
import "src/LotteryToken.sol";
import "src/interfaces/ILotterySetup.sol";
import "src/Ticket.sol";

contract LotterySetup is ILotterySetup {
    using PercentageMath for uint256;

    uint256 public immutable override minInitialPot;
    uint256 public immutable override jackpotBound;

    IERC20 public immutable override rewardToken;
    IERC20 public immutable override nativeToken;

    uint256 public immutable override ticketPrice;

    uint256 public override initialPot;

    uint256 public immutable override initialPotDeadline;
    uint256 internal immutable firstDrawSchedule;
    uint256 public immutable override drawPeriod;
    uint256 public immutable override drawCoolDownPeriod;

    uint8 public immutable override selectionSize;
    uint8 public immutable override selectionMax;
    uint256 public immutable override expectedPayout;

    uint256 private immutable nonJackpotFixedRewards;

    uint256 private constant BASE_JACKPOT_PERCENTAGE = 30_030; // 30.03%

    /// @dev Constructs a new lottery contract
    /// @param lotterySetupParams Setup parameter for the lottery
    // solhint-disable-next-line code-complexity
    constructor(LotterySetupParams memory lotterySetupParams) {
        if (address(lotterySetupParams.token) == address(0)) {
            revert RewardTokenZero();
        }
        if (lotterySetupParams.ticketPrice == uint256(0)) {
            revert TicketPriceZero();
        }
        if (lotterySetupParams.selectionSize == 0) {
            revert SelectionSizeZero();
        }
        if (lotterySetupParams.selectionMax >= 120) {
            revert SelectionSizeMaxTooBig();
        }
        if (
            lotterySetupParams.expectedPayout < lotterySetupParams.ticketPrice / 100
                || lotterySetupParams.expectedPayout >= lotterySetupParams.ticketPrice
        ) {
            revert InvalidExpectedPayout();
        }
        if (
            lotterySetupParams.selectionSize > 16 || lotterySetupParams.selectionSize >= lotterySetupParams.selectionMax
        ) {
            revert SelectionSizeTooBig();
        }
        if (
            lotterySetupParams.drawSchedule.drawCoolDownPeriod >= lotterySetupParams.drawSchedule.drawPeriod
                || lotterySetupParams.drawSchedule.firstDrawScheduledAt < lotterySetupParams.drawSchedule.drawPeriod
        ) {
            revert DrawPeriodInvalidSetup();
        }
        initialPotDeadline =
            lotterySetupParams.drawSchedule.firstDrawScheduledAt - lotterySetupParams.drawSchedule.drawPeriod;
        // slither-disable-next-line timestamp
        if (initialPotDeadline < (block.timestamp + lotterySetupParams.drawSchedule.drawPeriod)) {
            revert InitialPotPeriodTooShort();
        }

        nativeToken = new LotteryToken();
        uint256 tokenUnit = 10 ** IERC20Metadata(address(lotterySetupParams.token)).decimals();
        minInitialPot = 4 * tokenUnit;
        jackpotBound = 2_000_000 * tokenUnit;
        rewardToken = lotterySetupParams.token;
        firstDrawSchedule = lotterySetupParams.drawSchedule.firstDrawScheduledAt;
        drawPeriod = lotterySetupParams.drawSchedule.drawPeriod;
        drawCoolDownPeriod = lotterySetupParams.drawSchedule.drawCoolDownPeriod;
        ticketPrice = lotterySetupParams.ticketPrice;
        selectionSize = lotterySetupParams.selectionSize;
        selectionMax = lotterySetupParams.selectionMax;
        expectedPayout = lotterySetupParams.expectedPayout;

        nonJackpotFixedRewards = packFixedRewards(lotterySetupParams.fixedRewards);

        emit LotteryDeployed(
            lotterySetupParams.token,
            lotterySetupParams.drawSchedule,
            lotterySetupParams.ticketPrice,
            lotterySetupParams.selectionSize,
            lotterySetupParams.selectionMax,
            lotterySetupParams.expectedPayout,
            lotterySetupParams.fixedRewards
        );
    }

    modifier requireJackpotInitialized() {
        // slither-disable-next-line incorrect-equality
        if (initialPot == 0) {
            revert JackpotNotInitialized();
        }
        _;
    }

    modifier beforeTicketRegistrationDeadline(uint128 drawId) {
        // slither-disable-next-line timestamp
        if (block.timestamp > ticketRegistrationDeadline(drawId)) {
            revert TicketRegistrationClosed(drawId);
        }
        _;
    }

    function fixedReward(uint8 winTier) public view override returns (uint256 amount) {
        if (winTier == selectionSize) {
            return _baseJackpot(initialPot);
        } else if (winTier == 0 || winTier > selectionSize) {
            return 0;
        } else {
            uint256 mask = uint256(type(uint16).max) << (winTier * 16);
            uint256 extracted = (nonJackpotFixedRewards & mask) >> (winTier * 16);
            return extracted * (10 ** (IERC20Metadata(address(rewardToken)).decimals() - 1));
        }
    }

    function finalizeInitialPotRaise() external override {
        if (initialPot > 0) {
            revert JackpotAlreadyInitialized();
        }
        // slither-disable-next-line timestamp
        if (block.timestamp <= initialPotDeadline) {
            revert FinalizingInitialPotBeforeDeadline();
        }
        uint256 raised = rewardToken.balanceOf(address(this));
        if (raised < minInitialPot) {
            revert RaisedInsufficientFunds(raised);
        }
        initialPot = raised;

        // must hold after this call, this will be used as a check that jackpot is initialized
        assert(initialPot > 0);

        emit InitialPotPeriodFinalized(raised);
    }

    function drawScheduledAt(uint128 drawId) public view override returns (uint256 time) {
        time = firstDrawSchedule + (drawId * drawPeriod);
    }

    function ticketRegistrationDeadline(uint128 drawId) public view override returns (uint256 time) {
        time = drawScheduledAt(drawId) - drawCoolDownPeriod;
    }

    function _baseJackpot(uint256 _initialPot) internal view returns (uint256) {
        return Math.min(_initialPot.getPercentage(BASE_JACKPOT_PERCENTAGE), jackpotBound);
    }

    function packFixedRewards(uint256[] memory rewards) private view returns (uint256 packed) {
        if (rewards.length != (selectionSize) || rewards[0] != 0) {
            revert InvalidFixedRewardSetup();
        }
        uint256 divisor = 10 ** (IERC20Metadata(address(rewardToken)).decimals() - 1);
        for (uint8 winTier = 1; winTier < selectionSize; ++winTier) {
            uint16 reward = uint16(rewards[winTier] / divisor);
            if ((rewards[winTier] % divisor) != 0) {
                revert InvalidFixedRewardSetup();
            }
            packed |= uint256(reward) << (winTier * 16);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "src/interfaces/ILotteryToken.sol";
import "src/LotteryMath.sol";

/// @dev Lottery token contract. The token has a fixed initial supply.
/// Additional tokens can be minted after each draw is finalized. Inflation rates (per draw) are defined for each year.
contract LotteryToken is ILotteryToken, ERC20 {
    uint256 public constant override INITIAL_SUPPLY = 1_000_000_000e18;

    address public immutable override owner;

    /// @dev Initializes lottery token with `INITIAL_SUPPLY` pre-minted tokens
    constructor() ERC20("Wenwin Lottery", "LOT") {
        owner = msg.sender;
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mint(address account, uint256 amount) external override {
        if (msg.sender != owner) {
            revert UnauthorizedMint();
        }
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

/// @dev Implementation of percentage math.
library PercentageMath {
    /// @dev percentage base we use for 100%.
    uint256 public constant PERCENTAGE_BASE = 100_000;

    /// @dev percentage number representing 1%.
    uint256 public constant ONE_PERCENT = 1000;

    /// @dev Calculates percentage of the number.
    /// @param number Input to calculate percentage for.
    /// @param percentage Percentage to calculate in `PERCENTAGE_BASE` precision.
    /// @return result Resulting number representing `percentage` of `number`.
    function getPercentage(uint256 number, uint256 percentage) internal pure returns (uint256 result) {
        return number * percentage / PERCENTAGE_BASE;
    }

    /// @dev Calculates percentage of signed number. See `getPercentage`.
    function getPercentageInt(int256 number, uint256 percentage) internal pure returns (int256 result) {
        return number * int256(percentage) / int256(PERCENTAGE_BASE);
    }
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "src/interfaces/IRNSource.sol";
import "src/interfaces/IRNSourceController.sol";

/// @dev A contract that controls the list of random number sources and dispatches random number requests to them.
abstract contract RNSourceController is Ownable2Step, IRNSourceController {
    IRNSource public override source;

    uint256 public override failedSequentialAttempts;
    uint256 public override maxFailedAttemptsReachedAt;
    uint256 public override lastRequestTimestamp;
    bool public override lastRequestFulfilled = true;
    uint256 public immutable override maxFailedAttempts;
    uint256 public immutable override maxRequestDelay;
    uint256 private constant MAX_MAX_FAILED_ATTEMPTS = 10;
    uint256 private constant MAX_REQUEST_DELAY = 5 hours;

    /// @dev Constructs a new random number source controller.
    /// @param _maxFailedAttempts The maximum number of sequential failed attempts to use a random number source before
    /// it is removed from the list of sources
    /// @param _maxRequestDelay The maximum delay between random number request and its fulfillment
    constructor(uint256 _maxFailedAttempts, uint256 _maxRequestDelay) {
        if (_maxFailedAttempts > MAX_MAX_FAILED_ATTEMPTS) {
            revert MaxFailedAttemptsTooBig();
        }
        if (_maxRequestDelay > MAX_REQUEST_DELAY) {
            revert MaxRequestDelayTooBig();
        }
        maxFailedAttempts = _maxFailedAttempts;
        maxRequestDelay = _maxRequestDelay;
    }

    /// @dev Requests a random number from the current random number source.
    function requestRandomNumber() internal {
        if (!lastRequestFulfilled) {
            revert PreviousRequestNotFulfilled();
        }

        requestRandomNumberFromSource();
    }

    function onRandomNumberFulfilled(uint256 randomNumber) external override {
        if (msg.sender != address(source)) {
            revert RandomNumberFulfillmentUnauthorized();
        }

        lastRequestFulfilled = true;
        failedSequentialAttempts = 0;
        maxFailedAttemptsReachedAt = 0;

        receiveRandomNumber(randomNumber);
    }

    function receiveRandomNumber(uint256 randomNumber) internal virtual;

    function retry() external override {
        if (lastRequestFulfilled) {
            revert CannotRetrySuccessfulRequest();
        }
        if (block.timestamp - lastRequestTimestamp <= maxRequestDelay) {
            revert CurrentRequestStillActive();
        }

        uint256 failedAttempts = ++failedSequentialAttempts;
        if (failedAttempts == maxFailedAttempts) {
            maxFailedAttemptsReachedAt = block.timestamp;
        }

        emit Retry(source, failedSequentialAttempts);
        requestRandomNumberFromSource();
    }

    function initSource(IRNSource rnSource) external override onlyOwner {
        if (address(rnSource) == address(0)) {
            revert RNSourceZeroAddress();
        }
        if (address(source) != address(0)) {
            revert AlreadyInitialized();
        }

        source = rnSource;
        emit SourceSet(rnSource);
    }

    function swapSource(IRNSource newSource) external override onlyOwner {
        if (address(newSource) == address(0)) {
            revert RNSourceZeroAddress();
        }
        bool notEnoughRetryInvocations = failedSequentialAttempts < maxFailedAttempts;
        bool notEnoughTimeReachingMaxFailedAttempts = block.timestamp < maxFailedAttemptsReachedAt + maxRequestDelay;
        if (notEnoughRetryInvocations || notEnoughTimeReachingMaxFailedAttempts) {
            revert NotEnoughFailedAttempts();
        }
        source = newSource;
        failedSequentialAttempts = 0;
        maxFailedAttemptsReachedAt = 0;

        emit SourceSet(newSource);
        requestRandomNumberFromSource();
    }

    function requestRandomNumberFromSource() private {
        lastRequestTimestamp = block.timestamp;
        lastRequestFulfilled = false;

        // slither-disable-start uninitialized-local
        // See Slither issue: https://github.com/crytic/slither/issues/511
        try source.requestRandomNumber() {
            emit SuccessfulRNRequest(source);
        } catch Error(string memory reason) {
            emit FailedRNRequest(source, bytes(reason));
        } catch (bytes memory reason) {
            emit FailedRNRequest(source, reason);
        }
        // slither-disable-end uninitialized-local
    }
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "src/interfaces/IReferralSystem.sol";
import "src/PercentageMath.sol";

abstract contract ReferralSystem is IReferralSystem {
    using PercentageMath for uint256;

    uint256 public immutable override playerRewardFirstDraw;
    uint256 public immutable override playerRewardDecreasePerDraw;

    uint256[] public override rewardsToReferrersPerDraw;

    mapping(uint128 => mapping(address => UnclaimedTicketsData)) public override unclaimedTickets;

    mapping(uint128 => uint256) public override totalTicketsForReferrersPerDraw;

    mapping(uint128 => uint256) public override referrerRewardPerDrawForOneTicket;

    mapping(uint128 => uint256) public override playerRewardsPerDrawForOneTicket;

    mapping(uint128 => uint256) public override minimumEligibleReferrals;

    constructor(
        uint256 _playerRewardFirstDraw,
        uint256 _playerRewardDecreasePerDraw,
        uint256[] memory _rewardsToReferrersPerDraw
    ) {
        if (_rewardsToReferrersPerDraw.length == 0) {
            revert ReferrerRewardsInvalid();
        }
        for (uint256 i = 0; i < _rewardsToReferrersPerDraw.length; ++i) {
            if (_rewardsToReferrersPerDraw[i] == 0) {
                revert ReferrerRewardsInvalid();
            }
        }

        rewardsToReferrersPerDraw = _rewardsToReferrersPerDraw;

        playerRewardFirstDraw = _playerRewardFirstDraw;
        playerRewardDecreasePerDraw = _playerRewardDecreasePerDraw;
    }

    /// @dev Registers tickets for player and referrer (if an address is not zero)
    /// @param currentDraw Currently active draw
    /// @param referrer The address of the referrer
    /// @param player The address of the player
    /// @param numberOfTickets Number of tickets we are registering
    function referralRegisterTickets(
        uint128 currentDraw,
        address referrer,
        address player,
        uint256 numberOfTickets
    )
        internal
    {
        if (referrer != address(0)) {
            uint256 minimumEligible = minimumEligibleReferrals[currentDraw];
            if (unclaimedTickets[currentDraw][referrer].referrerTicketCount + numberOfTickets >= minimumEligible) {
                if (unclaimedTickets[currentDraw][referrer].referrerTicketCount < minimumEligible) {
                    totalTicketsForReferrersPerDraw[currentDraw] +=
                        unclaimedTickets[currentDraw][referrer].referrerTicketCount;
                }
                totalTicketsForReferrersPerDraw[currentDraw] += numberOfTickets;
            }
            unclaimedTickets[currentDraw][referrer].referrerTicketCount += uint128(numberOfTickets);
        }
        unclaimedTickets[currentDraw][player].playerTicketCount += uint128(numberOfTickets);
    }

    function mintNativeTokens(address mintTo, uint256 amount) internal virtual;

    function claimReferralReward(uint128[] memory drawIds) external override returns (uint256 claimedReward) {
        for (uint256 counter = 0; counter < drawIds.length; ++counter) {
            claimedReward += claimPerDraw(drawIds[counter]);
        }

        mintNativeTokens(msg.sender, claimedReward);
    }

    /// @dev Draw is being finalized, does the rewards calculations for the draw
    /// @param drawFinalized Draw being finalized
    /// @param ticketsSoldDuringDraw Number of tickets sold during the draw that is finalized
    function referralDrawFinalize(uint128 drawFinalized, uint256 ticketsSoldDuringDraw) internal {
        // if no tickets sold there is no incentives, so no rewards to be set
        if (ticketsSoldDuringDraw == 0) {
            return;
        }

        minimumEligibleReferrals[drawFinalized + 1] =
            getMinimumEligibleReferralsFactorCalculation(ticketsSoldDuringDraw);

        uint256 referrerRewardForDraw = referrerRewardsPerDraw(drawFinalized);
        uint256 totalTicketsForReferrersPerCurrentDraw = totalTicketsForReferrersPerDraw[drawFinalized];
        if (totalTicketsForReferrersPerCurrentDraw > 0) {
            referrerRewardPerDrawForOneTicket[drawFinalized] =
                referrerRewardForDraw / totalTicketsForReferrersPerCurrentDraw;
        }

        uint256 playerRewardForDraw = playerRewardsPerDraw(drawFinalized);
        if (playerRewardForDraw > 0) {
            playerRewardsPerDrawForOneTicket[drawFinalized] = playerRewardForDraw / ticketsSoldDuringDraw;
        }

        emit CalculatedRewardsForDraw(drawFinalized, referrerRewardForDraw, playerRewardForDraw);
    }

    function getMinimumEligibleReferralsFactorCalculation(uint256 totalTicketsSoldPrevDraw)
        internal
        view
        virtual
        returns (uint256 minimumEligible)
    {
        if (totalTicketsSoldPrevDraw < 10_000) {
            // 1%
            return totalTicketsSoldPrevDraw.getPercentage(PercentageMath.ONE_PERCENT);
        }
        if (totalTicketsSoldPrevDraw < 100_000) {
            // 0.75%
            return totalTicketsSoldPrevDraw.getPercentage(PercentageMath.ONE_PERCENT * 75 / 100);
        }
        if (totalTicketsSoldPrevDraw < 1_000_000) {
            // 0.5%
            return totalTicketsSoldPrevDraw.getPercentage(PercentageMath.ONE_PERCENT * 50 / 100);
        }
        return 5000;
    }

    /// @dev Reverts if draw is not yet finalized
    /// @param drawId Draw identifier we are checking
    function requireFinishedDraw(uint128 drawId) internal view virtual;

    function claimPerDraw(uint128 drawId) private returns (uint256 claimedReward) {
        requireFinishedDraw(drawId);

        UnclaimedTicketsData memory _unclaimedTickets = unclaimedTickets[drawId][msg.sender];
        if (_unclaimedTickets.referrerTicketCount >= minimumEligibleReferrals[drawId]) {
            claimedReward = referrerRewardPerDrawForOneTicket[drawId] * _unclaimedTickets.referrerTicketCount;
            unclaimedTickets[drawId][msg.sender].referrerTicketCount = 0;
        }

        _unclaimedTickets = unclaimedTickets[drawId][msg.sender];
        if (_unclaimedTickets.playerTicketCount > 0) {
            claimedReward += playerRewardsPerDrawForOneTicket[drawId] * _unclaimedTickets.playerTicketCount;
            unclaimedTickets[drawId][msg.sender].playerTicketCount = 0;
        }

        if (claimedReward > 0) {
            emit ClaimedReferralReward(drawId, msg.sender, claimedReward);
        }
    }

    function playerRewardsPerDraw(uint128 drawId) internal view returns (uint256 rewards) {
        uint256 decrease = uint256(drawId) * playerRewardDecreasePerDraw;
        return playerRewardFirstDraw > decrease ? (playerRewardFirstDraw - decrease) : 0;
    }

    function referrerRewardsPerDraw(uint128 drawId) internal view returns (uint256 rewards) {
        return rewardsToReferrersPerDraw[Math.min(rewardsToReferrersPerDraw.length - 1, drawId)];
    }
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "src/interfaces/ITicket.sol";

/// @dev Ticket ownership is represented as NFT. Whoever owns NFT is the owner of particular ticket in Lottery.
/// If it represents a winning ticket, it can be used to claim a reward from Lottery.
/// Ticket can change ownership before or after ticket has been claimed.
/// Since mint is internal, only derived contracts can mint tickets.
abstract contract Ticket is ITicket, ERC721 {
    uint256 public override nextTicketId;
    mapping(uint256 => ITicket.TicketInfo) public override ticketsInfo;

    // solhint-disable-next-line no-empty-blocks
    constructor() ERC721("Wenwin Lottery Ticket", "WLT") { }

    function markAsClaimed(uint256 ticketId) internal {
        ticketsInfo[ticketId].claimed = true;
    }

    function mint(address to, uint128 drawId, uint120 combination) internal returns (uint256 ticketId) {
        ticketId = nextTicketId++;
        ticketsInfo[ticketId] = TicketInfo(drawId, combination, false);
        _mint(to, ticketId);
    }
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

/// @dev Helper library used for ticket utilities
/// Ticket is represented as uint120 packed ticket:
/// If `x`th bit of ticket is set, it means ticket contains number x + 1
library TicketUtils {
    /// @dev Checks if ticket is valid
    /// In order to be a valid ticket, it must:
    ///    - Have exactly `selectionSize` bits set to `1`
    ///    - Each bit after bit `selectionMax` must be set to `0`
    /// @param ticket Ticked represented as packed uint120
    /// @param selectionSize Selection size of the lottery
    /// @param selectionMax Selection max number for the lottery
    /// @return isValid Is ticked valid
    function isValidTicket(
        uint256 ticket,
        uint8 selectionSize,
        uint8 selectionMax
    )
        internal
        pure
        returns (bool isValid)
    {
        unchecked {
            uint256 ticketSize;
            for (uint8 i = 0; i < selectionMax; ++i) {
                ticketSize += (ticket & uint256(1));
                ticket >>= 1;
            }
            return (ticketSize == selectionSize) && (ticket == uint256(0));
        }
    }

    /// @dev Reconstructs ticket from random number. Each number is selected from appropriate 8 bits from random number.
    /// In each iteration, we calculate the modulo of a random number and then shift it for 8 bits to the right.
    /// The modulo is used to select one number from the numbers that are not already selected.
    /// @param randomNumber Random number used to reconstruct ticket
    /// @param selectionSize Selection size of the lottery
    /// @param selectionMax Selection max number for the lottery
    /// @return ticket Resulting ticket, packed as uint120
    function reconstructTicket(
        uint256 randomNumber,
        uint8 selectionSize,
        uint8 selectionMax
    )
        internal
        pure
        returns (uint120 ticket)
    {
        /// Ticket must contain unique numbers, so we are using smaller selection count in each iteration
        /// It basically means that, once `x` numbers are selected our choice is smaller for `x` numbers
        uint8[] memory numbers = new uint8[](selectionSize);
        uint256 currentSelectionCount = uint256(selectionMax);

        for (uint256 i = 0; i < selectionSize; ++i) {
            numbers[i] = uint8(randomNumber % currentSelectionCount);
            randomNumber /= currentSelectionCount;
            currentSelectionCount--;
        }

        bool[] memory selected = new bool[](selectionMax);

        for (uint256 i = 0; i < selectionSize; ++i) {
            uint8 currentNumber = numbers[i];
            // check current selection for numbers smaller than current and increase if needed
            for (uint256 j = 0; j <= currentNumber; ++j) {
                if (selected[j]) {
                    currentNumber++;
                }
            }
            selected[currentNumber] = true;
            ticket |= ((uint120(1) << currentNumber));
        }
    }

    /// @dev Checks how many hits particular ticket has compared to winning ticket combination.
    /// @param ticket Ticket we are checking hits for
    /// @param winningTicket Winning ticket for the draw
    /// @param selectionSize Selection size for lottery
    /// @param selectionMax Selection max for the lottery
    function ticketWinTier(
        uint120 ticket,
        uint120 winningTicket,
        uint8 selectionSize,
        uint8 selectionMax
    )
        internal
        pure
        returns (uint8 winTier)
    {
        unchecked {
            uint120 intersection = ticket & winningTicket;
            for (uint8 i = 0; i < selectionMax; ++i) {
                winTier += uint8(intersection & uint120(1));
                intersection >>= 1;
            }
            assert((winTier <= selectionSize) && (intersection == uint256(0)));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "src/interfaces/ILotterySetup.sol";
import "src/interfaces/IRNSourceController.sol";
import "src/interfaces/ITicket.sol";
import "src/interfaces/IReferralSystem.sol";

/// @dev Invalid ticket is provided. This means the selection count is not `selectionSize`,
/// or one of the numbers is not in range [1, selectionMax].
error InvalidTicket();

/// @dev Cannot execute draw if it is already in progress.
error DrawAlreadyInProgress();

/// @dev Cannot finalize draw if it is not in executing phase.
error DrawNotInProgress();

/// @dev Executing draw before it's scheduled period.
error ExecutingDrawTooEarly();

/// @dev Provided arrays of drawIds and Tickets with different length.
/// @param drawIdsLen Length of drawIds array.
/// @param ticketsLen Length of tickets array.
error DrawsAndTicketsLenMismatch(uint256 drawIdsLen, uint256 ticketsLen);

/// @dev Claim executed by someone else other than ticket owner.
/// @param ticketId Unique ticket identifier being claimed.
/// @param claimer User trying to execute claim.
error UnauthorizedClaim(uint256 ticketId, address claimer);

/// @dev Trying to claim win for a non-winning ticket or a ticket that was already claimed.
/// @param ticketId Unique ticket identifier being claimed.
error NothingToClaim(uint256 ticketId);

/// @dev The draw with @param drawId is not finished
/// @param drawId Unique identifier for draw
error DrawNotFinished(uint128 drawId);

/// @dev List of implemented rewards.
/// @param FRONTEND Reward paid to frontend operators for each ticket sold.
/// @param STAKING Reward for stakers of LotteryToken.
enum LotteryRewardType {
    FRONTEND,
    STAKING
}

/// @dev Interface that decentralized lottery implements
interface ILottery is ITicket, ILotterySetup, IRNSourceController, IReferralSystem {
    /// @dev New ticket has been purchased by `user` for `drawId`.
    /// @param currentDraw Currently active draw.
    /// @param ticketId Ticket unique identifier.
    /// @param drawId Draw for which the ticket was purchased.
    /// @param user Address of the user buying ticket.
    /// @param combination Ticket combination represented as packed uint120.
    /// @param frontend Frontend operator that sold the ticket.
    /// @param referrer Referrer address that referred ticket sale.
    event NewTicket(
        uint128 currentDraw,
        uint256 ticketId,
        uint128 drawId,
        address indexed user,
        uint120 combination,
        address indexed frontend,
        address indexed referrer
    );

    /// @dev Rewards are claimed from the lottery.
    /// @param rewardRecipient Address that received the reward.
    /// @param amount Total amount of rewards claimed.
    /// @param rewardType 0 - staking reward, 1 - frontend reward.
    event ClaimedRewards(address indexed rewardRecipient, uint256 indexed amount, LotteryRewardType indexed rewardType);

    /// @dev Winnings are claimed from the lottery for particular ticket
    /// @param user Address of the user claiming winnings.
    /// @param ticketId Ticket unique identifier.
    /// @param amount Total amount of winnings claimed.
    event ClaimedTicket(address indexed user, uint256 indexed ticketId, uint256 indexed amount);

    /// @dev Started executing draw for the drawId.
    /// @param drawId Draw that is being executed.
    event StartedExecutingDraw(uint128 indexed drawId);

    /// @dev Triggered after finishing the draw process.
    /// @param drawId Draw being finished.
    /// @param randomNumber Random number used for reconstructing ticket.
    /// @param winningTicket Winning ticket represented as packed uint120.
    event FinishedExecutingDraw(uint128 indexed drawId, uint256 indexed randomNumber, uint120 indexed winningTicket);

    /// @return rewardRecipient Staking fee recipient.
    function stakingRewardRecipient() external view returns (address rewardRecipient);

    /// @return ticketId Next ticket id to be minted after the last draw was finalized.
    function lastDrawFinalTicketId() external view returns (uint256 ticketId);

    /// @return Is executing draw in progress.
    function drawExecutionInProgress() external view returns (bool);

    /// @dev Checks amount to payout for winning ticket for particular draw.
    /// @param drawId Unique identifier of a draw we are querying.
    /// @param winTier Tier of the win (selectionSize for jackpot).
    /// @return amount Amount claimable by winning ticket holder.
    function winAmount(uint128 drawId, uint8 winTier) external view returns (uint256 amount);

    /// @dev Checks the current reward size for the particular win tier.
    /// @param winTier Tier of the win, `selectionSize` for jackpot.
    /// @return rewardSize Size of the reward for win tier.
    function currentRewardSize(uint8 winTier) external view returns (uint256 rewardSize);

    /// @param drawId Unique identifier of a draw we are querying.
    /// @return sold Number of tickets sold per draw.
    function ticketsSold(uint128 drawId) external view returns (uint256 sold);

    /// @return netProfit Current cumulative net profit calculated when the last draw was finished.
    function currentNetProfit() external view returns (int256 netProfit);

    /// @param rewardType type of the reward being checked.
    /// @return rewards Amount of rewards to be paid out.
    function unclaimedRewards(LotteryRewardType rewardType) external view returns (uint256 rewards);

    /// @return drawId Current game in progress.
    function currentDraw() external view returns (uint128 drawId);

    /// @dev Checks winning combination for particular draw.
    /// @param drawId Unique identifier of a draw we are querying.
    /// @return winningCombination Actual winning combination for a draw.
    function winningTicket(uint128 drawId) external view returns (uint120 winningCombination);

    /// @dev Buy set of tickets for the upcoming lotteries.
    /// `msg.sender` pays `ticketPrice` for each ticket and provides combination of numbers for each ticket.
    /// Reverts in case of invalid number combination in any of the tickets.
    /// Reverts in case of insufficient `rewardToken`(`tickets.length * ticketPrice`) in `msg.sender`'s account.
    /// Requires approval to spend `msg.sender`'s `rewardToken` of at least `tickets.length * ticketPrice`
    /// @param drawIds Draw identifiers user buys ticket for.
    /// @param tickets list of uint120 packed tickets. Needs to be of same length as `drawIds`.
    /// @param frontend Address of a frontend operator selling the ticket.
    /// @param referrer The address of a referrer.
    /// @return ticketIds List of minted ticket identifiers.
    function buyTickets(
        uint128[] calldata drawIds,
        uint120[] calldata tickets,
        address frontend,
        address referrer
    )
        external
        returns (uint256[] memory ticketIds);

    /// @dev Transfers all unclaimed rewards to frontend operator, or staking recipient.
    /// @param rewardType type of the reward being claimed.
    /// @return claimedAmount Amount of tokens claimed to `feeRecipient`
    function claimRewards(LotteryRewardType rewardType) external returns (uint256 claimedAmount);

    /// @dev Transfer all winnings to `msg.sender` for the winning tickets.
    /// It reverts in case of non winning ticket.
    /// Only ticket owner can claim win, if any of the tickets is not owned by `msg.sender` it will revert.
    /// @param ticketIds List of ids of the tickets being claimed.
    /// @return claimedAmount Amount of reward tokens claimed to `msg.sender`.
    function claimWinningTickets(uint256[] calldata ticketIds) external returns (uint256 claimedAmount);

    /// @dev checks claimable amount for specific ticket.
    /// @param ticketId Id of the ticket.
    /// @return claimableAmount Amount that can be claimed with this ticket.
    /// @return winTier Tier of the winning ticket (selectionSize for jackpot).
    function claimable(uint256 ticketId) external view returns (uint256 claimableAmount, uint8 winTier);

    /// @dev Starts draw process. Requests a random number from `randomNumberSource`.
    function executeDraw() external;
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "src/interfaces/ITicket.sol";

/// @dev Provided reward token is zero
error RewardTokenZero();

/// @dev Provided draw cooldown period >= drawPeriod
error DrawPeriodInvalidSetup();

/// @dev Provided initial pot deadline set to be in past
error InitialPotPeriodTooShort();

/// @dev Provided ticket price is zero
error TicketPriceZero();

/// @dev Provided selection size iz zero
error SelectionSizeZero();

/// @dev Provided selection size max is too big
error SelectionSizeMaxTooBig();

/// @dev Provided selection size is too big
error SelectionSizeTooBig();

/// @dev Provided expected payout is too low or too big
error InvalidExpectedPayout();

/// @dev Invalid fixed rewards setup was provided
error InvalidFixedRewardSetup();

/// @dev Trying to finalize initial pot raise before the deadline
error FinalizingInitialPotBeforeDeadline();

/// @dev Raised insufficient funds for the initial pot
/// @param potSize size of the pot raised
error RaisedInsufficientFunds(uint256 potSize);

/// @dev Jackpot is not yet initialized, it means we are still in initial pot raise timeframe
error JackpotNotInitialized();

/// @dev Trying to initialize already initialized jackpot
error JackpotAlreadyInitialized();

/// @dev Cannot buy tickets for this draw anymore as it is in cooldown mode
/// @param drawId Draw identifier that is in cooldown mode
error TicketRegistrationClosed(uint128 drawId);

/// @dev Lottery draw schedule parameters
struct LotteryDrawSchedule {
    /// @dev First draw is scheduled to take place at this timestamp
    uint256 firstDrawScheduledAt;
    /// @dev Period for running lottery
    uint256 drawPeriod;
    /// @dev Cooldown period when users cannot register tickets for draw anymore
    uint256 drawCoolDownPeriod;
}

/// @dev Parameters used to setup a new lottery
struct LotterySetupParams {
    /// @dev Token to be used as reward token for the lottery
    IERC20 token;
    /// @dev Parameters of the draw schedule for the lottery
    LotteryDrawSchedule drawSchedule;
    /// @dev Price to pay for playing single game (including fee)
    uint256 ticketPrice;
    /// @dev Count of numbers user picks for the ticket
    uint8 selectionSize;
    /// @dev Max number user can pick
    uint8 selectionMax;
    /// @dev Expected payout for one ticket, expressed in `rewardToken`
    uint256 expectedPayout;
    /// @dev Array of fixed rewards per each non jackpot win
    uint256[] fixedRewards;
}

interface ILotterySetup {
    /// @dev Triggered when new Lottery is deployed
    /// @param token Token to be used as reward token for the lottery
    /// @param drawSchedule Parameters of the draw schedule for the lottery
    /// @param ticketPrice Price to pay for playing single game (including fee)
    /// @param selectionSize Count of numbers user picks for the ticket
    /// @param selectionMax Max number user can pick
    /// @param expectedPayout Expected payout for one ticket, expressed in `rewardToken`
    /// @param fixedRewards List of fixed non jackpot rewards
    event LotteryDeployed(
        IERC20 token,
        LotteryDrawSchedule indexed drawSchedule,
        uint256 ticketPrice,
        uint8 indexed selectionSize,
        uint8 indexed selectionMax,
        uint256 expectedPayout,
        uint256[] fixedRewards
    );

    /// @dev Triggered when the initial pot raise period is over
    /// @param amountRaised Total amount raised during this period
    event InitialPotPeriodFinalized(uint256 indexed amountRaised);

    /// @return minPot Minimum amount to be raised in initial funding period
    function minInitialPot() external view returns (uint256 minPot);

    /// @return bound Maximum base jackpot
    function jackpotBound() external view returns (uint256 bound);

    /// @dev Token to be used as reward token for the lottery
    /// It is used for both rewards and paying for tickets
    /// @return token Reward token address
    function rewardToken() external view returns (IERC20 token);

    /// @return token Native token of the lottery. Used for staking and for referral rewards.
    function nativeToken() external view returns (IERC20 token);

    /// @dev Price to pay for playing single game of lottery
    /// User pays it when registering the ticket for the game
    /// It is expressed in `rewardToken`
    /// @return price Price per ticket
    function ticketPrice() external view returns (uint256 price);

    /// @param winTier Tier of the win (selectionSize for jackpot)
    /// @return amount Fixed reward for particular win tier
    function fixedReward(uint8 winTier) external view returns (uint256 amount);

    /// @return potSize The size of the pot after initial pot period is over
    function initialPot() external view returns (uint256 potSize);

    /// @dev When registering ticket, user selects total of `selectionSize` numbers
    /// @return size Count of numbers user picks for the ticket
    function selectionSize() external view returns (uint8 size);

    /// @dev When registering ticket, user selects total of `selectionSize` numbers
    /// These numbers must be in range [1, `selectionMax`]
    /// @return max Max number user can pick
    function selectionMax() external view returns (uint8 max);

    /// @return payout Expected payout for one ticket in reward token
    function expectedPayout() external view returns (uint256 payout);

    /// @return period Period between 2 draws
    function drawPeriod() external view returns (uint256 period);

    /// @return topUpEndsAt Timestamp when initial pot raising is finished
    function initialPotDeadline() external view returns (uint256 topUpEndsAt);

    /// @return period Cooldown period, just before draw is scheduled, at this time tickets cannot be registered
    function drawCoolDownPeriod() external view returns (uint256 period);

    /// @dev Checks for the scheduled time for particular draw
    /// @param drawId Draw identifier we check schedule for
    /// @return time Timestamp after which draw can be executed
    function drawScheduledAt(uint128 drawId) external view returns (uint256 time);

    /// @dev Checks for the last time at which tickets can be bought
    /// @param drawId Draw identifier we check deadline for
    /// @return time Timestamp after which tickets can not be bought
    function ticketRegistrationDeadline(uint128 drawId) external view returns (uint256 time);

    /// @dev Finalize the initial pot raising and initialize jackpot
    function finalizeInitialPotRaise() external;
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Caller is not allowed to mint tokens.
error UnauthorizedMint();

/// @dev Interface for the Lottery token.
interface ILotteryToken is IERC20 {
    /// @dev Initial supply minted at the token deployment.
    function INITIAL_SUPPLY() external view returns (uint256 initialSupply);

    /// @return _owner The owner of the contract
    function owner() external view returns (address _owner);

    /// @dev Mints number of tokens for particular draw and assigns them to `account`, increasing the total supply.
    /// Mint is done for the `nextDrawToBeMintedFor`
    /// @param account The recipient of tokens
    /// @param amount Number of tokens to be minted
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

interface IRNSource {
    /// @dev Non existent request, this should never happen as it means the underlying source
    /// reported number for a non-existent request ID
    /// @param requestId id of the request that is being checked
    error RequestNotFound(uint256 requestId);

    /// @dev The generated request ID was used before
    /// @param requestId The duplicate generated request ID
    error RequestAlreadyFulfilled(uint256 requestId);

    /// @dev Consumer is not allowed to request random numbers
    /// @param consumer Address of consumer that tried requesting random number
    error UnauthorizedConsumer(address consumer);

    /// @dev The generated request ID was used before
    /// @param requestId The duplicate generated request ID
    error requestIdAlreadyExists(uint256 requestId);

    /// @dev Emitted when a random number is requested
    /// @param consumer Consumer requested random number
    /// @param requestId identifier of the request
    event RequestedRandomNumber(address indexed consumer, uint256 indexed requestId);

    /// @dev Request is fulfilled
    /// @param requestId identifier of the request being fulfilled
    /// @param randomNumber random number generated
    event RequestFulfilled(uint256 indexed requestId, uint256 indexed randomNumber);

    enum RequestStatus {
        None,
        Pending,
        Fulfilled
    }

    struct RandomnessRequest {
        /// @dev specifies the request status
        RequestStatus status;
        /// @dev Random number generated for particular request
        uint256 randomNumber;
    }

    /// @dev Requests a new random number from the source
    function requestRandomNumber() external;
}

interface IRNSourceConsumer {
    /// @dev After requesting random number from IRNSource
    /// this method will be called by IRNSource to deliver generated number
    /// @param randomNumber Generated random number
    function onRandomNumberFulfilled(uint256 randomNumber) external;
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "src/interfaces/IRNSource.sol";

/// @dev Provided Random number source is zero
error RNSourceZeroAddress();

/// @dev Current random number request is still active.
error CurrentRequestStillActive();

/// @dev Thrown when trying to invoke `retry` while there is no pending request.
error CannotRetrySuccessfulRequest();

/// @dev Thrown when trying to request a random number while a pending request exists.
error PreviousRequestNotFulfilled();

/// @dev Thrown when trying to deploy a contract with a `maxFailedAttempts` param that is too big.
error MaxFailedAttemptsTooBig();

/// @dev Thrown when trying to deploy a contract with a `maxRequestsDelay` param that is too big.
error MaxRequestDelayTooBig();

/// @dev Thrown when trying to swap randomness source before the current source failed `maxFailedAttempts` times.
error NotEnoughFailedAttempts();

/// @dev Thrown when trying to initialize a randomness source after one was already initialized.
error AlreadyInitialized();

/// @dev Random number fulfillment is unauthorized.
error RandomNumberFulfillmentUnauthorized();

/// @dev A contract that controls the list of random number sources and dispatches random number requests to them.
interface IRNSourceController is IRNSourceConsumer {
    /// @dev Emitted on request retry.
    /// @param failedSource The address of the failed source
    /// @param numberOfFailedAttempts A total number of failed attempts for @param failedSource
    event Retry(IRNSource indexed failedSource, uint256 indexed numberOfFailedAttempts);

    /// @dev Emitted when a new randomness source is set.
    /// @param source The randomness source which was set
    event SourceSet(IRNSource indexed source);

    /// @dev Emitted on a successful randomness request.
    /// @param source The source from which randomness was successfully requested
    event SuccessfulRNRequest(IRNSource indexed source);

    /// @dev Emitted on a failed randomness request.
    /// @param source The source from which randomness was unsuccessfully requested
    /// @param reason The reason why the randomness request, directly propagated from the randomness source
    event FailedRNRequest(IRNSource indexed source, bytes indexed reason);

    /// @dev The current randomness source.
    function source() external view returns (IRNSource source);

    /// @dev Retrieves the number of failed sequential request attempts for the current source.
    function failedSequentialAttempts() external view returns (uint256 numberOfAttempts);

    /// @dev Retrieves the timestamp at which the current source reached `maxFailedAttempts` number of retries.
    function maxFailedAttemptsReachedAt() external view returns (uint256 numberOfAttempts);

    /// @return numberOfAttempts The number of the maximum failed attempts after the source will be removed
    function maxFailedAttempts() external view returns (uint256 numberOfAttempts);

    /// @return timestamp A timestamp for the last data request
    function lastRequestTimestamp() external view returns (uint256 timestamp);

    /// @return isFulfilled Get is last request fulfilled
    function lastRequestFulfilled() external view returns (bool isFulfilled);

    /// @return delay The maximum delay between random number request and its fulfillment
    function maxRequestDelay() external view returns (uint256 delay);

    /// @dev Called by the current random number source to deliver a generated random number.
    /// @param randomNumber A random number generated by the current random number source
    function onRandomNumberFulfilled(uint256 randomNumber) external;

    /// @dev Initializes the controller's underlying randomness source.
    function initSource(IRNSource rnSource) external;

    /// @dev Retries a randomness request. Can only be called when at least `maxRequestDelay` amount of time
    /// passed since `lastRequestTimestamp`.
    function retry() external;

    /// @dev Swaps the controller's underlying randomness source. Can only be called by the owner and after
    /// at least `maxFailedAttempts` retries were invoked.
    /// @param newSource A new random number source to be added to the list of sources
    function swapSource(IRNSource newSource) external;
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "src/interfaces/ILotteryToken.sol";

/// @dev Referrer rewards setup is invalid
error ReferrerRewardsInvalid();

interface IReferralSystem {
    /// @dev Data about number of tickets user did not claim rewards for
    struct UnclaimedTicketsData {
        /// @dev Number of tickets sold as referrer for which rewards are unclaimed
        uint128 referrerTicketCount;
        /// @dev Number of tickets user has bought for which rewards are unclaimed
        uint128 playerTicketCount;
    }

    /// @dev Referrer with address @param referrer claimed amount @param claimedAmount for a draw @param drawId
    /// @param drawId Unique identifier for draw
    /// @param user The address of the referrer or player
    /// @param claimedAmount Claimed reward in the lotteryToken
    event ClaimedReferralReward(uint128 indexed drawId, address indexed user, uint256 indexed claimedAmount);

    /// @dev Reward amounts for referrers and players are calculated for draw with @param drawId
    /// @param drawId Unique identifier for draw
    /// @param referrerRewardForDraw Reward amount for referrers for draw with @param drawId
    /// @param playerRewardForDraw Reward amount for players for draw with @param drawId
    event CalculatedRewardsForDraw(
        uint128 indexed drawId, uint256 indexed referrerRewardForDraw, uint256 indexed playerRewardForDraw
    );

    /// @dev The setup for the rewards for referrers.
    /// @param drawId Unique identifier of the draw rewards are queried for.
    /// @return reffererRewards Total reward amount going to referrers.
    function rewardsToReferrersPerDraw(uint256 drawId) external view returns (uint256 reffererRewards);

    /// @dev Retrieves total reward for players for first draw.
    function playerRewardFirstDraw() external view returns (uint256);

    /// @dev Retrieves decrease size for the each draw after the first one.
    /// Reward for players is calculated as `playerRewardFirstDraw - drawId * playerRewardDecreasePerDraw`.
    function playerRewardDecreasePerDraw() external view returns (uint256);

    function unclaimedTickets(
        uint128 drawId,
        address user
    )
        external
        view
        returns (uint128 referrerTicketCount, uint128 playerTicketCount);

    /// @param drawId Unique identifier for draw
    /// @return totalNumberOfTickets The total number of tickets that are added for referrers for @param drawId
    function totalTicketsForReferrersPerDraw(uint128 drawId) external view returns (uint256 totalNumberOfTickets);

    /// @dev Referrer's rewards per draw for one ticket
    /// @param drawId Unique identifier for draw
    function referrerRewardPerDrawForOneTicket(uint128 drawId) external view returns (uint256 rewardsPerDraw);

    /// @dev Player's rewards per draw for one ticket
    /// @param drawId Unique identifier for draw
    function playerRewardsPerDrawForOneTicket(uint128 drawId) external view returns (uint256 rewardsPerDraw);

    /// @dev Claims both player and referrer reward if applicable
    /// @param drawIds List of draws reward is claimed for
    /// @return claimedReward Total amount claimed containing both player and referrer reward
    function claimReferralReward(uint128[] memory drawIds) external returns (uint256 claimedReward);

    /// @param drawId Unique identifier for draw
    /// @return minimumEligibleReferrals Calculate the minimum eligible referrals that are needed for the referrer to be
    /// rewarded
    function minimumEligibleReferrals(uint128 drawId) external view returns (uint256 minimumEligibleReferrals);
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @dev Interface representing Ticket NTF.
/// Ticket NFT represents ownership of the lottery ticket.
interface ITicket is IERC721 {
    /// @dev Information about the ticket.
    struct TicketInfo {
        /// @dev Unique identifier of the draw ticket was bought for.
        uint128 drawId;
        /// @dev Ticket combination that is packed as uint120.
        uint120 combination;
        /// @dev If ticket is already claimed, in case of winning ticket.
        bool claimed;
    }

    /// @dev Identifier that will be assigned to the next minted token
    /// @return nextId Next identifier to be assigned
    function nextTicketId() external view returns (uint256 nextId);

    /// @dev Retrieves information about a ticket given a `ticketId`.
    /// @param ticketId Unique identifier of the ticket.
    /// @return drawId Unique identifier of the draw ticket was bought for.
    /// @return combination Ticket combination that is packed as uint120.
    /// @return claimed If ticket is already claimed, in case of winning ticket.
    function ticketsInfo(uint256 ticketId) external view returns (uint128 drawId, uint120 combination, bool claimed);
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "src/interfaces/ILottery.sol";
import "src/LotteryMath.sol";
import "src/staking/interfaces/IStaking.sol";

contract Staking is IStaking, ERC20 {
    using SafeERC20 for IERC20;

    ILottery public immutable override lottery;
    IERC20 public immutable override rewardsToken;
    IERC20 public immutable override stakingToken;
    uint256 public override rewardPerTokenStored;
    uint256 public override lastUpdateTicketId;
    mapping(address => uint256) public override userRewardPerTokenPaid;
    mapping(address => uint256) public override rewards;

    constructor(
        ILottery _lottery,
        IERC20 _rewardsToken,
        IERC20 _stakingToken,
        string memory name,
        string memory symbol
    )
        ERC20(name, symbol)
    {
        if (address(_lottery) == address(0)) {
            revert ZeroAddressInput();
        }
        if (address(_rewardsToken) == address(0)) {
            revert ZeroAddressInput();
        }
        if (address(_stakingToken) == address(0)) {
            revert ZeroAddressInput();
        }

        lottery = _lottery;
        rewardsToken = _rewardsToken;
        stakingToken = _stakingToken;
    }

    /* ========== VIEWS ========== */

    function rewardPerToken() public view override returns (uint256 _rewardPerToken) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        uint256 ticketsSoldSinceUpdate = lottery.nextTicketId() - lastUpdateTicketId;
        uint256 unclaimedRewards =
            LotteryMath.calculateRewards(lottery.ticketPrice(), ticketsSoldSinceUpdate, LotteryRewardType.STAKING);

        return rewardPerTokenStored + (unclaimedRewards * 1e18 / _totalSupply);
    }

    function earned(address account) public view override returns (uint256 _earned) {
        return balanceOf(account) * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external override {
        // _updateReward is not needed here as it's handled by _beforeTokenTransfer
        if (amount == 0) {
            revert ZeroAmountInput();
        }

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override {
        // _updateReward is not needed here as it's handled by _beforeTokenTransfer
        if (amount == 0) {
            revert ZeroAmountInput();
        }

        _burn(msg.sender, amount);
        stakingToken.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public override {
        _updateReward(msg.sender);
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            // slither-disable-next-line unused-return
            lottery.claimRewards(LotteryRewardType.STAKING);
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external override {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal override {
        if (from != address(0)) {
            _updateReward(from);
        }

        if (to != address(0)) {
            _updateReward(to);
        }
    }

    function _updateReward(address account) internal {
        uint256 currentRewardPerToken = rewardPerToken();
        rewardPerTokenStored = currentRewardPerToken;
        lastUpdateTicketId = lottery.nextTicketId();
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = currentRewardPerToken;
    }
}

// SPDX-License-Identifier: UNLICENSED
// slither-disable-next-line solc-version
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "src/interfaces/ILottery.sol";

/// @dev Thrown when a zero amount is provided as input.
error ZeroAmountInput();

/// @dev Thrown when a zero address is provided as input.
error ZeroAddressInput();

interface IStaking is IERC20 {
    /// @dev Stakes the stakeToken. Caller must pre-approve the staking contract.
    /// @param amount Amount of tokens to be staked
    function stake(uint256 amount) external;

    /// @dev Withdraws staked tokens.
    /// @param amount Amount of tokens to be withdrawn
    function withdraw(uint256 amount) external;

    /// @dev Claims accrued rewards.
    function getReward() external;

    /// @dev Withdraws the entire staked balance and claims accrued rewards.
    function exit() external;

    /// @dev Caches the latest rewardPerToken index at which rewards were paid.
    function rewardPerTokenStored() external view returns (uint256);

    /// @dev Keeps track of the latest ticket ID at the time of the last rewardPerToken index update.
    function lastUpdateTicketId() external view returns (uint256);

    /// @dev Caches the latest rewardPerToken index at which a given `account`'s pending rewards update was made.
    function userRewardPerTokenPaid(address account) external view returns (uint256);

    /// @dev Caches the amount of pending rewards for a given `account`, expressed in `rewardsToken`.
    function rewards(address account) external view returns (uint256);

    /// @return _lottery Lottery the contract is dependent on
    function lottery() external view returns (ILottery _lottery);

    /// @return _rewardPerToken Global tracker of rewards per staked token
    function rewardPerToken() external view returns (uint256 _rewardPerToken);

    /// @dev Retrieves the amount of unclaimed rewards of an account.
    /// @param account Address of the account to check its earnings
    /// @return _earned Earned rewards of the account
    function earned(address account) external view returns (uint256 _earned);

    /// @dev Retrieves the token in which staking rewards are paid.
    function rewardsToken() external view returns (IERC20);

    /// @dev Retrieves the token that is being staked in order to get rewards.
    function stakingToken() external view returns (IERC20);

    /// @dev Emitted when a user stakes tokens.
    /// @param user Address of the staking user
    /// @param amount Amount of tokens staked
    event Staked(address indexed user, uint256 indexed amount);

    /// @dev Emitted when a user withdraws staked tokens.
    /// @param user Address of the withdrawing user
    /// @param amount Amount of tokens withdrawn
    event Withdrawn(address indexed user, uint256 indexed amount);

    /// @dev Emitted when a user claims their rewards.
    /// @param user Address of the user claiming rewards
    /// @param reward Amount of rewards claimed
    event RewardPaid(address indexed user, uint256 indexed reward);
}