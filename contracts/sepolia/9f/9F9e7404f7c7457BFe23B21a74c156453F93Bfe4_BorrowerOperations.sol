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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Interfaces/IERC3156FlashLender.sol";
import "./Interfaces/IERC3156FlashBorrower.sol";
import "./Interfaces/IBorrowerOperations.sol";
import "./Interfaces/ITroveManager.sol";
import "./Interfaces/ITroveManagerHelpers.sol";
import "./Interfaces/ISLSDToken.sol";
import "./Interfaces/ICollSurplusPool.sol";
import "./Interfaces/ISortedTroves.sol";
import "./Interfaces/IPSYStaking.sol";
import "./Interfaces/IStabilityPoolManager.sol";
import "./Dependencies/PSYBase.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/SafetyTransfer.sol";
import "./Dependencies/Initializable.sol";


contract BorrowerOperations is PSYBase, CheckContract, IBorrowerOperations, IERC3156FlashLender, Initializable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	string public constant NAME = "BorrowerOperations";
	bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

	// --- Connected contract declarations ---

	ITroveManager public troveManager;

	ITroveManagerHelpers public troveManagerHelpers;

	IStabilityPoolManager stabilityPoolManager;

	address gasPoolAddress;

	ICollSurplusPool collSurplusPool;

	IPSYStaking public PSYStaking;
	address public PSYStakingAddress;
	bool isPSYReady;

	address treasury;

	ISLSDToken public SLSDToken;

	// A doubly linked list of Troves, sorted by their collateral ratios
	ISortedTroves public sortedTroves;

	bool public isInitialized;

	/* --- Variable container structs  ---

    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */

	struct LocalVariables_adjustTrove {
		address asset;
		uint256 price;
		uint256 collChange;
		uint256 netDebtChange;
		bool isCollIncrease;
		uint256 debt;
		uint256 coll;
		uint256 oldICR;
		uint256 newICR;
		uint256 newTCR;
		uint256 SLSDFee;
		uint256 newDebt;
		uint256 newColl;
		uint256 stake;
	}

	struct LocalVariables_openTrove {
		address asset;
		uint256 price;
		uint256 SLSDFee;
		uint256 netDebt;
		uint256 compositeDebt;
		uint256 ICR;
		uint256 NICR;
		uint256 stake;
		uint256 arrayIndex;
	}

	struct ContractsCache {
		ITroveManager troveManager;
		ITroveManagerHelpers troveManagerHelpers;
		IActivePool activePool;
		ISLSDToken SLSDToken;
	}

	enum BorrowerOperation {
		openTrove,
		closeTrove,
		adjustTrove
	}

	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 stake,
		BorrowerOperation operation
	);

	// --- Dependency setters ---

	function setAddresses(
		address _troveManagerAddress,
		address _troveManagerHelpersAddress,
		address _stabilityPoolManagerAddress,
		address _gasPoolAddress,
		address _collSurplusPoolAddress,
		address _sortedTrovesAddress,
		address _slsdTokenAddress,
		address _PSYStakingAddress,
		address _treasury,
		address _psyParamsAddress
	) external override initializer onlyOwner {
		require(!isInitialized, "Already initialized");
		checkContract(_troveManagerAddress);
		checkContract(_troveManagerHelpersAddress);
		checkContract(_stabilityPoolManagerAddress);
		checkContract(_gasPoolAddress);
		checkContract(_collSurplusPoolAddress);
		checkContract(_sortedTrovesAddress);
		checkContract(_slsdTokenAddress);
		checkContract(_psyParamsAddress);
		isInitialized = true;

		troveManager = ITroveManager(_troveManagerAddress);
		troveManagerHelpers = ITroveManagerHelpers(_troveManagerHelpersAddress);
		stabilityPoolManager = IStabilityPoolManager(_stabilityPoolManagerAddress);
		gasPoolAddress = _gasPoolAddress;
		collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
		sortedTroves = ISortedTroves(_sortedTrovesAddress);
		SLSDToken = ISLSDToken(_slsdTokenAddress);

		if (_PSYStakingAddress != address(0)) {
			checkContract(_PSYStakingAddress);
			PSYStakingAddress = _PSYStakingAddress;
			PSYStaking = IPSYStaking(_PSYStakingAddress);
			isPSYReady = true;
		} else {
			changeTreasuryAddress(_treasury);	
		}

		setPSYParameters(_psyParamsAddress);

		emit TroveManagerAddressChanged(_troveManagerAddress);
		emit StabilityPoolAddressChanged(_stabilityPoolManagerAddress);
		emit GasPoolAddressChanged(_gasPoolAddress);
		emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
		emit SortedTrovesAddressChanged(_sortedTrovesAddress);
		emit SLSDTokenAddressChanged(_slsdTokenAddress);
		emit PSYStakingAddressChanged(_PSYStakingAddress);
	}

	// --- Borrower Trove Operations Getter functions ---

	function isContractBorrowerOps() public pure returns (bool) {
		return true;
	}

	// --- Borrower Trove Operations ---

	function openTrove(
		address _asset,
		uint256 _tokenAmount,
		uint256 _maxFeePercentage,
		uint256 _SLSDamount,
		address _upperHint,
		address _lowerHint
	) external payable override {
		
		psyParams.sanitizeParameters(_asset);

		ContractsCache memory contractsCache = ContractsCache(
			troveManager,
			troveManagerHelpers,
			psyParams.activePool(),
			SLSDToken
		);
		LocalVariables_openTrove memory vars;
		vars.asset = _asset;

		_tokenAmount = getMethodValue(vars.asset, _tokenAmount, false);
		vars.price = psyParams.priceFeed().fetchPrice(vars.asset);

		bool isRecoveryMode = _checkRecoveryMode(vars.asset, vars.price);

		_requireValidMaxFeePercentage(vars.asset, _maxFeePercentage, isRecoveryMode);
		_requireTroveisNotActive(
			vars.asset,
			contractsCache.troveManager,
			contractsCache.troveManagerHelpers,
			msg.sender
		);

		vars.netDebt = _SLSDamount;

		if (!isRecoveryMode) {
			vars.SLSDFee = _triggerBorrowingFee(
				vars.asset,
				contractsCache.troveManager,
				contractsCache.troveManagerHelpers,
				contractsCache.SLSDToken,
				_SLSDamount,
				_maxFeePercentage
			);
			vars.netDebt = vars.netDebt.add(vars.SLSDFee);
		}

		_requireAtLeastMinNetDebt(vars.asset, vars.netDebt);

		// ICR is based on the composite debt, i.e. the requested SLSD amount + SLSD borrowing fee + SLSD gas comp.
		vars.compositeDebt = _getCompositeDebt(vars.asset, vars.netDebt);
		assert(vars.compositeDebt > 0);

		vars.ICR = PSYMath._computeCR(_tokenAmount, vars.compositeDebt, vars.price);
		vars.NICR = PSYMath._computeNominalCR(_tokenAmount, vars.compositeDebt);

		if (isRecoveryMode) {
			_requireICRisAboveCCR(vars.asset, vars.ICR);
		} else {
			_requireICRisAboveMCR(vars.asset, vars.ICR);
			uint256 newTCR = _getNewTCRFromTroveChange(
				vars.asset,
				_tokenAmount,
				true,
				vars.compositeDebt,
				true,
				vars.price
			); // bools: coll increase, debt increase
			_requireNewTCRisAboveCCR(vars.asset, newTCR);
		}

		// Set the trove struct's properties
		contractsCache.troveManagerHelpers.setTroveStatus(vars.asset, msg.sender, 1);
		contractsCache.troveManagerHelpers.increaseTroveColl(vars.asset, msg.sender, _tokenAmount);
		contractsCache.troveManagerHelpers.increaseTroveDebt(
			vars.asset,
			msg.sender,
			vars.compositeDebt
		);

		contractsCache.troveManagerHelpers.updateTroveRewardSnapshots(vars.asset, msg.sender);
		vars.stake = contractsCache.troveManagerHelpers.updateStakeAndTotalStakes(
			vars.asset,
			msg.sender
		);

		sortedTroves.insert(vars.asset, msg.sender, vars.NICR, _upperHint, _lowerHint);
		vars.arrayIndex = contractsCache.troveManagerHelpers.addTroveOwnerToArray(
			vars.asset,
			msg.sender
		);
		emit TroveCreated(vars.asset, msg.sender, vars.arrayIndex);

		// Move the ether to the Active Pool, and mint the SLSDAmount to the borrower
		_activePoolAddColl(vars.asset, contractsCache.activePool, _tokenAmount);
		_withdrawSLSD(
			vars.asset,
			contractsCache.activePool,
			contractsCache.SLSDToken,
			msg.sender,
			_SLSDamount,
			vars.netDebt
		);
		// Move the SLSD gas compensation to the Gas Pool
		_withdrawSLSD(
			vars.asset,
			contractsCache.activePool,
			contractsCache.SLSDToken,
			gasPoolAddress,
			psyParams.SLSD_GAS_COMPENSATION(vars.asset),
			psyParams.SLSD_GAS_COMPENSATION(vars.asset)
		);

		emit TroveUpdated(
			vars.asset,
			msg.sender,
			vars.compositeDebt,
			_tokenAmount,
			vars.stake,
			BorrowerOperation.openTrove
		);
		emit SLSDBorrowingFeePaid(vars.asset, msg.sender, vars.SLSDFee);
	}

	// Send ETH as collateral to a trove
	function addColl(
		address _asset,
		uint256 _assetSent,
		address _upperHint,
		address _lowerHint
	) external payable override {
		_adjustTrove(
			_asset,
			getMethodValue(_asset, _assetSent, false),
			msg.sender,
			0,
			0,
			false,
			_upperHint,
			_lowerHint,
			0
		);
	}

	// Send ETH as collateral to a trove. Called by only the Stability Pool.
	function moveETHGainToTrove(
		address _asset,
		uint256 _amountMoved,
		address _borrower,
		address _upperHint,
		address _lowerHint
	) external payable override {
		_requireCallerIsStabilityPool();
		_adjustTrove(
			_asset,
			getMethodValue(_asset, _amountMoved, false),
			_borrower,
			0,
			0,
			false,
			_upperHint,
			_lowerHint,
			0
		);
	}

	// Withdraw ETH collateral from a trove
	function withdrawColl(
		address _asset,
		uint256 _collWithdrawal,
		address _upperHint,
		address _lowerHint
	) external override {
		_adjustTrove(_asset, 0, msg.sender, _collWithdrawal, 0, false, _upperHint, _lowerHint, 0);
	}

	// Withdraw SLSD tokens from a trove: mint new SLSD tokens to the owner, and increase the trove's debt accordingly
	function withdrawSLSD(
		address _asset,
		uint256 _maxFeePercentage,
		uint256 _SLSDamount,
		address _upperHint,
		address _lowerHint
	) external override {
		_adjustTrove(
			_asset,
			0,
			msg.sender,
			0,
			_SLSDamount,
			true,
			_upperHint,
			_lowerHint,
			_maxFeePercentage
		);
	}

	// Repay SLSD tokens to a Trove: Burn the repaid SLSD tokens, and reduce the trove's debt accordingly
	function repaySLSD(
		address _asset,
		uint256 _SLSDamount,
		address _upperHint,
		address _lowerHint
	) external override {
		_adjustTrove(_asset, 0, msg.sender, 0, _SLSDamount, false, _upperHint, _lowerHint, 0);
	}

	function adjustTrove(
		address _asset,
		uint256 _assetSent,
		uint256 _maxFeePercentage,
		uint256 _collWithdrawal,
		uint256 _SLSDChange,
		bool _isDebtIncrease,
		address _upperHint,
		address _lowerHint
	) external payable override {
		_adjustTrove(
			_asset,
			getMethodValue(_asset, _assetSent, true),
			msg.sender,
			_collWithdrawal,
			_SLSDChange,
			_isDebtIncrease,
			_upperHint,
			_lowerHint,
			_maxFeePercentage
		);
	}

	/*
	 * _adjustTrove(): Alongside a debt change, this function can perform either a collateral top-up or a collateral withdrawal.
	 *
	 * It therefore expects either a positive msg.value, or a positive _collWithdrawal argument.
	 *
	 * If both are positive, it will revert.
	 */
	function _adjustTrove(
		address _asset,
		uint256 _assetSent,
		address _borrower,
		uint256 _collWithdrawal,
		uint256 _SLSDChange,
		bool _isDebtIncrease,
		address _upperHint,
		address _lowerHint,
		uint256 _maxFeePercentage
	) internal {
		ContractsCache memory contractsCache = ContractsCache(
			troveManager,
			troveManagerHelpers,
			psyParams.activePool(),
			SLSDToken
		);
		LocalVariables_adjustTrove memory vars;
		vars.asset = _asset;

		require(
			msg.value == 0 || msg.value == _assetSent,
			"BorrowerOp: _AssetSent and Msg.value aren't the same!"
		);

		vars.price = psyParams.priceFeed().fetchPrice(vars.asset);
		bool isRecoveryMode = _checkRecoveryMode(vars.asset, vars.price);

		if (_isDebtIncrease) {
			_requireValidMaxFeePercentage(vars.asset, _maxFeePercentage, isRecoveryMode);
			_requireNonZeroDebtChange(_SLSDChange);
		}
		_requireSingularCollChange(_collWithdrawal, _assetSent);
		_requireNonZeroAdjustment(_collWithdrawal, _SLSDChange, _assetSent);
		_requireTroveisActive(vars.asset, contractsCache.troveManagerHelpers, _borrower);

		// Confirm the operation is either a borrower adjusting their own trove, or a pure ETH transfer from the Stability Pool to a trove
		assert(
			msg.sender == _borrower ||
				(stabilityPoolManager.isStabilityPool(msg.sender) &&
					_assetSent > 0 &&
					_SLSDChange == 0)
		);

		contractsCache.troveManagerHelpers.applyPendingRewards(vars.asset, _borrower);

		// Get the collChange based on whether or not ETH was sent in the transaction
		(vars.collChange, vars.isCollIncrease) = _getCollChange(_assetSent, _collWithdrawal);

		vars.netDebtChange = _SLSDChange;

		// If the adjustment incorporates a debt increase and system is in Normal Mode, then trigger a borrowing fee
		if (_isDebtIncrease && !isRecoveryMode) {
			vars.SLSDFee = _triggerBorrowingFee(
				vars.asset,
				contractsCache.troveManager,
				contractsCache.troveManagerHelpers,
				contractsCache.SLSDToken,
				_SLSDChange,
				_maxFeePercentage
			);
			vars.netDebtChange = vars.netDebtChange.add(vars.SLSDFee); // The raw debt change includes the fee
		}

		vars.debt = contractsCache.troveManagerHelpers.getTroveDebt(vars.asset, _borrower);
		vars.coll = contractsCache.troveManagerHelpers.getTroveColl(vars.asset, _borrower);

		// Get the trove's old ICR before the adjustment, and what its new ICR will be after the adjustment
		vars.oldICR = PSYMath._computeCR(vars.coll, vars.debt, vars.price);
		vars.newICR = _getNewICRFromTroveChange(
			vars.coll,
			vars.debt,
			vars.collChange,
			vars.isCollIncrease,
			vars.netDebtChange,
			_isDebtIncrease,
			vars.price
		);
		require(
			_collWithdrawal <= vars.coll,
			"BorrowerOp: Trying to remove more than the trove holds"
		);

		// Check the adjustment satisfies all conditions for the current system mode
		_requireValidAdjustmentInCurrentMode(
			vars.asset,
			isRecoveryMode,
			_collWithdrawal,
			_isDebtIncrease,
			vars
		);

		// When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough SLSD
		if (!_isDebtIncrease && _SLSDChange > 0) {
			_requireAtLeastMinNetDebt(
				vars.asset,
				_getNetDebt(vars.asset, vars.debt).sub(vars.netDebtChange)
			);
			_requireValidSLSDRepayment(vars.asset, vars.debt, vars.netDebtChange);
			_requireSufficientSLSDBalance(contractsCache.SLSDToken, _borrower, vars.netDebtChange);
		}

		(vars.newColl, vars.newDebt) = _updateTroveFromAdjustment(
			vars.asset,
			contractsCache.troveManager,
			contractsCache.troveManagerHelpers,
			_borrower,
			vars.collChange,
			vars.isCollIncrease,
			vars.netDebtChange,
			_isDebtIncrease
		);
		vars.stake = contractsCache.troveManagerHelpers.updateStakeAndTotalStakes(
			vars.asset,
			_borrower
		);

		// Re-insert trove in to the sorted list
		uint256 newNICR = _getNewNominalICRFromTroveChange(
			vars.coll,
			vars.debt,
			vars.collChange,
			vars.isCollIncrease,
			vars.netDebtChange,
			_isDebtIncrease
		);
		sortedTroves.reInsert(vars.asset, _borrower, newNICR, _upperHint, _lowerHint);

		emit TroveUpdated(
			vars.asset,
			_borrower,
			vars.newDebt,
			vars.newColl,
			vars.stake,
			BorrowerOperation.adjustTrove
		);
		emit SLSDBorrowingFeePaid(vars.asset, msg.sender, vars.SLSDFee);

		// Use the unmodified _SLSDChange here, as we don't send the fee to the user
		_moveTokensAndETHfromAdjustment(
			vars.asset,
			contractsCache.activePool,
			contractsCache.SLSDToken,
			msg.sender,
			vars.collChange,
			vars.isCollIncrease,
			_SLSDChange,
			_isDebtIncrease,
			vars.netDebtChange
		);
	}

	function closeTrove(address _asset) external override {
		ITroveManagerHelpers troveManagerHelpersCached = troveManagerHelpers;
		IActivePool activePoolCached = psyParams.activePool();
		ISLSDToken SLSDTokenCached = SLSDToken;

		_requireTroveisActive(_asset, troveManagerHelpersCached, msg.sender);
		uint256 price = psyParams.priceFeed().fetchPrice(_asset);
		_requireNotInRecoveryMode(_asset, price);

		troveManagerHelpersCached.applyPendingRewards(_asset, msg.sender);

		uint256 coll = troveManagerHelpersCached.getTroveColl(_asset, msg.sender);
		uint256 debt = troveManagerHelpersCached.getTroveDebt(_asset, msg.sender);

		_requireSufficientSLSDBalance(
			SLSDTokenCached,
			msg.sender,
			debt.sub(psyParams.SLSD_GAS_COMPENSATION(_asset))
		);

		uint256 newTCR = _getNewTCRFromTroveChange(_asset, coll, false, debt, false, price);
		_requireNewTCRisAboveCCR(_asset, newTCR);

		troveManagerHelpersCached.removeStake(_asset, msg.sender);
		troveManagerHelpersCached.closeTrove(_asset, msg.sender);

		emit TroveUpdated(_asset, msg.sender, 0, 0, 0, BorrowerOperation.closeTrove);

		// Burn the repaid SLSD from the user's balance and the gas compensation from the Gas Pool
		_repaySLSD(
			_asset,
			activePoolCached,
			SLSDTokenCached,
			msg.sender,
			debt.sub(psyParams.SLSD_GAS_COMPENSATION(_asset))
		);

		_repaySLSD(
			_asset,
			activePoolCached,
			SLSDTokenCached,
			gasPoolAddress,
			psyParams.SLSD_GAS_COMPENSATION(_asset)
		);

		// Send the collateral back to the user
		activePoolCached.sendAsset(_asset, msg.sender, coll);
	}

	/**
	 * Claim remaining collateral from a redemption or from a liquidation with ICR > MCR in Recovery Mode
	 */
	function claimCollateral(address _asset) external override {
		// send ETH from CollSurplus Pool to owner
		collSurplusPool.claimColl(_asset, msg.sender);
	}

	/*
	 * Add PSY token modules later if it is not added at launch
	 */
	function addPSYModules(address _PSYStakingAddress) external onlyOwner {
		require(!isPSYReady,"PSY modules already registered");
		PSYStakingAddress = _PSYStakingAddress;
		PSYStaking = IPSYStaking(_PSYStakingAddress);
		isPSYReady = true;
	}

	/*
	 * Add treasury address who receives fees until PSY modules get registered
	 */
	function changeTreasuryAddress(address _treasury) public onlyOwner {
		require(_treasury != address(0), "Treasury address is zero");
		treasury = _treasury;
		emit TreasuryAddressChanged(_treasury);
	}

	// --- Flashloan functions ---
	    

    /**
     * @dev Loan `amount` tokens to `receiver`, and takes it back plus a `flashFee` after the callback.
     * @param _receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param _token The loan currency.
     * @param _amount The amount of tokens lent.
     * @param _data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external override returns(bool) {
        uint256 _supplyBefore = SLSDToken.totalSupply();
		SLSDToken.mint(address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF), address(_receiver), _amount);
        require(
            _receiver.onFlashLoan(msg.sender, address(SLSDToken), _amount, 0, _data) == CALLBACK_SUCCESS,
            "FlashLoan: Callback failed"
        );
		SLSDToken.burn(address(_receiver), _amount);
		uint256 _supplyAfter = SLSDToken.totalSupply();
        require(
            _supplyAfter == _supplyBefore,
            "FlashLoan: Repay failed"
        );
        return true;
    }

    /**
     * @dev The fee to be charged for a given loan.
 	 * 	@param _token The loan currency.
     * @param _amount The amount of tokens len
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address _token,
        uint256 _amount
    ) external view override returns (uint256) {
        return 0;
    }

    /**
     * @dev The amount of currency available to be lent.
     * @param _token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address _token
    ) external view override returns (uint256) {
        if (_token == address(SLSDToken)) {
        	return type(uint256).max - SLSDToken.totalSupply();
    	}
	    return 0;
    }

	// --- Helper functions ---

	function _triggerBorrowingFee(
		address _asset,
		ITroveManager _troveManager,
		ITroveManagerHelpers _troveManagerHelpers,
		ISLSDToken _SLSDToken,
		uint256 _SLSDamount,
		uint256 _maxFeePercentage
	) internal returns (uint256) {
		_troveManagerHelpers.decayBaseRateFromBorrowing(_asset); // decay the baseRate state variable
		uint256 SLSDFee = _troveManagerHelpers.getBorrowingFee(_asset, _SLSDamount);

		_requireUserAcceptsFee(SLSDFee, _SLSDamount, _maxFeePercentage);

		// Send fee to PSY staking contract
		if (isPSYReady) {
			_SLSDToken.mint(_asset, PSYStakingAddress, SLSDFee);
			PSYStaking.increaseF_SLSD(SLSDFee);
		} else {
			_SLSDToken.mint(_asset, treasury, SLSDFee);
		}
		
		return SLSDFee;
	}

	function _getCollChange(uint256 _collReceived, uint256 _requestedCollWithdrawal)
		internal
		pure
		returns (uint256 collChange, bool isCollIncrease)
	{
		if (_collReceived != 0) {
			collChange = _collReceived;
			isCollIncrease = true;
		} else {
			collChange = _requestedCollWithdrawal;
		}
	}

	// Update trove's coll and debt based on whether they increase or decrease
	function _updateTroveFromAdjustment(
		address _asset,
		ITroveManager _troveManager,
		ITroveManagerHelpers _troveManagerHelpers,
		address _borrower,
		uint256 _collChange,
		bool _isCollIncrease,
		uint256 _debtChange,
		bool _isDebtIncrease
	) internal returns (uint256, uint256) {
		uint256 newColl = (_isCollIncrease)
			? _troveManagerHelpers.increaseTroveColl(_asset, _borrower, _collChange)
			: _troveManagerHelpers.decreaseTroveColl(_asset, _borrower, _collChange);
		uint256 newDebt = (_isDebtIncrease)
			? _troveManagerHelpers.increaseTroveDebt(_asset, _borrower, _debtChange)
			: _troveManagerHelpers.decreaseTroveDebt(_asset, _borrower, _debtChange);

		return (newColl, newDebt);
	}

	function _moveTokensAndETHfromAdjustment(
		address _asset,
		IActivePool _activePool,
		ISLSDToken _SLSDToken,
		address _borrower,
		uint256 _collChange,
		bool _isCollIncrease,
		uint256 _SLSDChange,
		bool _isDebtIncrease,
		uint256 _netDebtChange
	) internal {
		if (_isDebtIncrease) {
			_withdrawSLSD(_asset, _activePool, _SLSDToken, _borrower, _SLSDChange, _netDebtChange);
		} else {
			_repaySLSD(_asset, _activePool, _SLSDToken, _borrower, _SLSDChange);
		}

		if (_isCollIncrease) {
			_activePoolAddColl(_asset, _activePool, _collChange);
		} else {
			_activePool.sendAsset(_asset, _borrower, _collChange);
		}
	}

	// Send ETH to Active Pool and increase its recorded ETH balance
	function _activePoolAddColl(
		address _asset,
		IActivePool _activePool,
		uint256 _amount
	) internal {
		if (_asset == ETH_REF_ADDRESS) {
			(bool success, ) = address(_activePool).call{ value: _amount }("");
			require(success, "BorrowerOps: Sending ETH to ActivePool failed");
		} else {
			IERC20(_asset).safeTransferFrom(
				msg.sender,
				address(_activePool),
				SafetyTransfer.decimalsCorrection(_asset, _amount)
			);

			_activePool.receivedERC20(_asset, _amount);
		}
	}

	// Issue the specified amount of SLSD to _account and increases the total active debt (_netDebtIncrease potentially includes a SLSDFee)
	function _withdrawSLSD(
		address _asset,
		IActivePool _activePool,
		ISLSDToken _SLSDToken,
		address _account,
		uint256 _SLSDamount,
		uint256 _netDebtIncrease
	) internal {
		_activePool.increaseSLSDDebt(_asset, _netDebtIncrease);
		_SLSDToken.mint(_asset, _account, _SLSDamount);
	}

	// Burn the specified amount of SLSD from _account and decreases the total active debt
	function _repaySLSD(
		address _asset,
		IActivePool _activePool,
		ISLSDToken _SLSDToken,
		address _account,
		uint256 _SLSD
	) internal {
		_activePool.decreaseSLSDDebt(_asset, _SLSD);
		_SLSDToken.burn(_account, _SLSD);
	}

	// --- 'Require' wrapper functions ---

	function _requireSingularCollChange(uint256 _collWithdrawal, uint256 _amountSent)
		internal
		view
	{
		require(
			_collWithdrawal == 0 || _amountSent == 0,
			"BorrowerOperations: Cannot withdraw and add coll"
		);
	}

	function _requireNonZeroAdjustment(
		uint256 _collWithdrawal,
		uint256 _SLSDChange,
		uint256 _assetSent
	) internal view {
		require(
			msg.value != 0 || _collWithdrawal != 0 || _SLSDChange != 0 || _assetSent != 0,
			"BorrowerOps: There must be either a collateral change or a debt change"
		);
	}

	function _requireTroveisActive(
		address _asset,
		ITroveManagerHelpers _troveManagerHelpers,
		address _borrower
	) internal view {
		uint256 status = _troveManagerHelpers.getTroveStatus(_asset, _borrower);
		require(status == 1, "BorrowerOps: Trove does not exist or is closed");
	}

	function _requireTroveisNotActive(
		address _asset,
		ITroveManager _troveManager,
		ITroveManagerHelpers _troveManagerHelpers,
		address _borrower
	) internal view {
		uint256 status = _troveManagerHelpers.getTroveStatus(_asset, _borrower);
		require(status != 1, "BorrowerOps: Trove is active");
	}

	function _requireNonZeroDebtChange(uint256 _SLSDChange) internal pure {
		require(_SLSDChange > 0, "BorrowerOps: Debt increase requires non-zero debtChange");
	}

	function _requireNotInRecoveryMode(address _asset, uint256 _price) internal view {
		require(
			!_checkRecoveryMode(_asset, _price),
			"BorrowerOps: Operation not permitted during Recovery Mode"
		);
	}

	function _requireNoCollWithdrawal(uint256 _collWithdrawal) internal pure {
		require(
			_collWithdrawal == 0,
			"BorrowerOps: Collateral withdrawal not permitted Recovery Mode"
		);
	}

	function _requireValidAdjustmentInCurrentMode(
		address _asset,
		bool _isRecoveryMode,
		uint256 _collWithdrawal,
		bool _isDebtIncrease,
		LocalVariables_adjustTrove memory _vars
	) internal view {
		/*
		 *In Recovery Mode, only allow:
		 *
		 * - Pure collateral top-up
		 * - Pure debt repayment
		 * - Collateral top-up with debt repayment
		 * - A debt increase combined with a collateral top-up which makes the ICR >= 150% and improves the ICR (and by extension improves the TCR).
		 *
		 * In Normal Mode, ensure:
		 *
		 * - The new ICR is above MCR
		 * - The adjustment won't pull the TCR below CCR
		 */
		if (_isRecoveryMode) {
			_requireNoCollWithdrawal(_collWithdrawal);
			if (_isDebtIncrease) {
				_requireICRisAboveCCR(_asset, _vars.newICR);
				_requireNewICRisAboveOldICR(_vars.newICR, _vars.oldICR);
			}
		} else {
			// if Normal Mode
			_requireICRisAboveMCR(_asset, _vars.newICR);
			_vars.newTCR = _getNewTCRFromTroveChange(
				_asset,
				_vars.collChange,
				_vars.isCollIncrease,
				_vars.netDebtChange,
				_isDebtIncrease,
				_vars.price
			);
			_requireNewTCRisAboveCCR(_asset, _vars.newTCR);
		}
	}

	function _requireICRisAboveMCR(address _asset, uint256 _newICR) internal view {
		require(
			_newICR >= psyParams.MCR(_asset),
			"BorrowerOps: An operation that would result in ICR < MCR is not permitted"
		);
	}

	function _requireICRisAboveCCR(address _asset, uint256 _newICR) internal view {
		require(
			_newICR >= psyParams.CCR(_asset),
			"BorrowerOps: Operation must leave trove with ICR >= CCR"
		);
	}

	function _requireNewICRisAboveOldICR(uint256 _newICR, uint256 _oldICR) internal pure {
		require(
			_newICR >= _oldICR,
			"BorrowerOps: Cannot decrease your Trove's ICR in Recovery Mode"
		);
	}

	function _requireNewTCRisAboveCCR(address _asset, uint256 _newTCR) internal view {
		require(
			_newTCR >= psyParams.CCR(_asset),
			"BorrowerOps: An operation that would result in TCR < CCR is not permitted"
		);
	}

	function _requireAtLeastMinNetDebt(address _asset, uint256 _netDebt) internal view {
		require(
			_netDebt >= psyParams.MIN_NET_DEBT(_asset),
			"BorrowerOps: Trove's net debt must be greater than minimum"
		);
	}

	function _requireValidSLSDRepayment(
		address _asset,
		uint256 _currentDebt,
		uint256 _debtRepayment
	) internal view {
		require(
			_debtRepayment <= _currentDebt.sub(psyParams.SLSD_GAS_COMPENSATION(_asset)),
			"BorrowerOps: Amount repaid must not be larger than the Trove's debt"
		);
	}

	function _requireCallerIsStabilityPool() internal view {
		require(
			stabilityPoolManager.isStabilityPool(msg.sender),
			"BorrowerOps: Caller is not Stability Pool"
		);
	}

	function _requireSufficientSLSDBalance(
		ISLSDToken _SLSDToken,
		address _borrower,
		uint256 _debtRepayment
	) internal view {
		require(
			_SLSDToken.balanceOf(_borrower) >= _debtRepayment,
			"BorrowerOps: Caller doesnt have enough SLSD to make repayment"
		);
	}

	function _requireValidMaxFeePercentage(
		address _asset,
		uint256 _maxFeePercentage,
		bool _isRecoveryMode
	) internal view {
		if (_isRecoveryMode) {
			require(
				_maxFeePercentage <= psyParams.DECIMAL_PRECISION(),
				"Max fee percentage must less than or equal to 100%"
			);
		} else {
			require(
				_maxFeePercentage >= psyParams.BORROWING_FEE_FLOOR(_asset) &&
					_maxFeePercentage <= psyParams.DECIMAL_PRECISION(),
				"Max fee percentage must be between 0.5% and 100%"
			);
		}
	}

	// --- ICR and TCR getters ---

	// Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
	function _getNewNominalICRFromTroveChange(
		uint256 _coll,
		uint256 _debt,
		uint256 _collChange,
		bool _isCollIncrease,
		uint256 _debtChange,
		bool _isDebtIncrease
	) internal pure returns (uint256) {
		(uint256 newColl, uint256 newDebt) = _getNewTroveAmounts(
			_coll,
			_debt,
			_collChange,
			_isCollIncrease,
			_debtChange,
			_isDebtIncrease
		);

		uint256 newNICR = PSYMath._computeNominalCR(newColl, newDebt);
		return newNICR;
	}

	// Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
	function _getNewICRFromTroveChange(
		uint256 _coll,
		uint256 _debt,
		uint256 _collChange,
		bool _isCollIncrease,
		uint256 _debtChange,
		bool _isDebtIncrease,
		uint256 _price
	) internal pure returns (uint256) {
		(uint256 newColl, uint256 newDebt) = _getNewTroveAmounts(
			_coll,
			_debt,
			_collChange,
			_isCollIncrease,
			_debtChange,
			_isDebtIncrease
		);

		uint256 newICR = PSYMath._computeCR(newColl, newDebt, _price);
		return newICR;
	}

	function _getNewTroveAmounts(
		uint256 _coll,
		uint256 _debt,
		uint256 _collChange,
		bool _isCollIncrease,
		uint256 _debtChange,
		bool _isDebtIncrease
	) internal pure returns (uint256, uint256) {
		uint256 newColl = _coll;
		uint256 newDebt = _debt;

		newColl = _isCollIncrease ? _coll.add(_collChange) : _coll.sub(_collChange);
		newDebt = _isDebtIncrease ? _debt.add(_debtChange) : _debt.sub(_debtChange);

		return (newColl, newDebt);
	}

	function _getNewTCRFromTroveChange(
		address _asset,
		uint256 _collChange,
		bool _isCollIncrease,
		uint256 _debtChange,
		bool _isDebtIncrease,
		uint256 _price
	) internal view returns (uint256) {
		uint256 totalColl = getEntireSystemColl(_asset);
		uint256 totalDebt = getEntireSystemDebt(_asset);

		totalColl = _isCollIncrease ? totalColl.add(_collChange) : totalColl.sub(_collChange);
		totalDebt = _isDebtIncrease ? totalDebt.add(_debtChange) : totalDebt.sub(_debtChange);

		uint256 newTCR = PSYMath._computeCR(totalColl, totalDebt, _price);
		return newTCR;
	}

	function getCompositeDebt(address _asset, uint256 _debt)
		external
		view
		override
		returns (uint256)
	{
		return _getCompositeDebt(_asset, _debt);
	}

	function getMethodValue(
		address _asset,
		uint256 _amount,
		bool canBeZero
	) private view returns (uint256) {
		bool isEth = _asset == address(0);

		require(
			(canBeZero || (isEth && msg.value != 0)) || (!isEth && msg.value == 0),
			"BorrowerOp: Invalid Input. Override msg.value only if using ETH asset, otherwise use _tokenAmount"
		);

		if (_asset == address(0)) {
			_amount = msg.value;
		}

		return _amount;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

abstract contract BaseMath {
	uint256 public constant DECIMAL_PRECISION = 1 ether;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

contract CheckContract {
	function checkContract(address _account) internal view {
		require(_account != address(0), "Account cannot be zero address");

		uint256 size;
		assembly {
			size := extcodesize(_account)
		}
		require(size > 0, "Account code size cannot be zero");
	}
}

pragma solidity ^0.8.14;

interface ERC20Decimals {
	function decimals() external view returns (uint8);
}

pragma solidity ^0.8.14;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IERC2612Permit {
	/**
	 * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
	 * given `owner`'s signed approval.
	 *
	 * IMPORTANT: The same issues {IERC20-approve} has related to transaction
	 * ordering also apply here.
	 *
	 * Emits an {Approval} event.
	 *
	 * Requirements:
	 *
	 * - `owner` cannot be the zero address.
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
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	/**
	 * @dev Returns the current ERC2612 nonce for `owner`. This value must be
	 * included whenever a signature is generated for {permit}.
	 *
	 * Every successful call to {permit} increases ``owner``'s nonce by one. This
	 * prevents a signature from being used multiple times.
	 */
	function nonces(address owner) external view returns (uint256);
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
	using Counters for Counters.Counter;

	mapping(address => Counters.Counter) private _nonces;

	// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 public constant PERMIT_TYPEHASH =
		0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

	bytes32 public DOMAIN_SEPARATOR;

	constructor() {
		uint256 chainID;
		assembly {
			chainID := chainid()
		}

		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				keccak256(
					"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
				),
				keccak256(bytes(name())),
				keccak256(bytes("1")), // Version
				chainID,
				address(this)
			)
		);
	}

	/**
	 * @dev See {IERC2612Permit-permit}.
	 *
	 */
	function permit(
		address owner,
		address spender,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external virtual override {
		require(block.timestamp <= deadline, "Permit: expired deadline");

		bytes32 hashStruct = keccak256(
			abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline)
		);

		bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

		address signer = ecrecover(_hash, v, r, s);
		require(signer != address(0) && signer == owner, "ERC20Permit: Invalid signature");

		_nonces[owner].increment();
		_approve(owner, spender, amount);
	}

	/**
	 * @dev See {IERC2612Permit-nonces}.
	 */
	function nonces(address owner) public view override returns (uint256) {
		return _nonces[owner].current();
	}

	function chainId() public view returns (uint256 chainID) {
		assembly {
			chainID := chainid()
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Address.sol";

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./BaseMath.sol";
import "./PSYMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/IPriceFeed.sol";
import "../Interfaces/IPSYBase.sol";

/*
 * Base contract for TroveManager, BorrowerOperations and StabilityPool. Contains global system constants and
 * common functions.
 */
contract PSYBase is BaseMath, IPSYBase, Ownable {
	using SafeMath for uint256;
	address public constant ETH_REF_ADDRESS = address(0);

	IPSYParameters public override psyParams;

	function setPSYParameters(address _vaultParams) public onlyOwner {
		psyParams = IPSYParameters(_vaultParams);
		emit VaultParametersBaseChanged(_vaultParams);
	}

	// --- Gas compensation functions ---

	// Returns the composite debt (drawn debt + gas compensation) of a trove, for the purpose of ICR calculation
	function _getCompositeDebt(address _asset, uint256 _debt) internal view returns (uint256) {
		return _debt.add(psyParams.SLSD_GAS_COMPENSATION(_asset));
	}

	function _getNetDebt(address _asset, uint256 _debt) internal view returns (uint256) {
		return _debt.sub(psyParams.SLSD_GAS_COMPENSATION(_asset));
	}

	// Return the amount of ETH to be drawn from a trove's collateral and sent as gas compensation.
	function _getCollGasCompensation(address _asset, uint256 _entireColl)
		internal
		view
		returns (uint256)
	{
		return _entireColl / psyParams.PERCENT_DIVISOR(_asset);
	}

	function getEntireSystemColl(address _asset) public view returns (uint256 entireSystemColl) {
		uint256 activeColl = psyParams.activePool().getAssetBalance(_asset);
		uint256 liquidatedColl = psyParams.defaultPool().getAssetBalance(_asset);

		return activeColl.add(liquidatedColl);
	}

	function getEntireSystemDebt(address _asset) public view returns (uint256 entireSystemDebt) {
		uint256 activeDebt = psyParams.activePool().getSLSDDebt(_asset);
		uint256 closedDebt = psyParams.defaultPool().getSLSDDebt(_asset);

		return activeDebt.add(closedDebt);
	}

	function _getTCR(address _asset, uint256 _price) internal view returns (uint256 TCR) {
		uint256 entireSystemColl = getEntireSystemColl(_asset);
		uint256 entireSystemDebt = getEntireSystemDebt(_asset);

		TCR = PSYMath._computeCR(entireSystemColl, entireSystemDebt, _price);

		return TCR;
	}

	function _checkRecoveryMode(address _asset, uint256 _price) internal view returns (bool) {
		uint256 TCR = _getTCR(_asset, _price);

		return TCR < psyParams.CCR(_asset);
	}

	function _requireUserAcceptsFee(
		uint256 _fee,
		uint256 _amount,
		uint256 _maxFeePercentage
	) internal view {
		uint256 feePercentage = _fee.mul(psyParams.DECIMAL_PRECISION()).div(_amount);
		require(feePercentage <= _maxFeePercentage, "FM");
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library PSYMath {
	using SafeMath for uint256;

	uint256 internal constant DECIMAL_PRECISION = 1 ether;

	/* Precision for Nominal ICR (independent of price). Rationale for the value:
	 *
	 * - Making it “too high” could lead to overflows.
	 * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
	 *
	 * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
	 * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
	 *
	 */
	uint256 internal constant NICR_PRECISION = 1e20;

	function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a < _b) ? _a : _b;
	}

	function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a >= _b) ? _a : _b;
	}

	/*
	 * Multiply two decimal numbers and use normal rounding rules:
	 * -round product up if 19'th mantissa digit >= 5
	 * -round product down if 19'th mantissa digit < 5
	 *
	 * Used only inside the exponentiation, _decPow().
	 */
	function decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
		uint256 prod_xy = x.mul(y);

		decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
	}

	/*
	 * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
	 *
	 * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
	 *
	 * Called by two functions that represent time in units of minutes:
	 * 1) TroveManager._calcDecayedBaseRate
	 * 2) CommunityIssuance._getCumulativeIssuanceFraction
	 *
	 * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
	 * "minutes in 1000 years": 60 * 24 * 365 * 1000
	 *
	 * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
	 * negligibly different from just passing the cap, since:
	 *
	 * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
	 * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
	 */
	function _decPow(uint256 _base, uint256 _minutes) internal pure returns (uint256) {
		if (_minutes > 525600000) {
			_minutes = 525600000;
		} // cap to avoid overflow

		if (_minutes == 0) {
			return DECIMAL_PRECISION;
		}

		uint256 y = DECIMAL_PRECISION;
		uint256 x = _base;
		uint256 n = _minutes;

		// Exponentiation-by-squaring
		while (n > 1) {
			if (n % 2 == 0) {
				x = decMul(x, x);
				n = n.div(2);
			} else {
				// if (n % 2 != 0)
				y = decMul(x, y);
				x = decMul(x, x);
				n = (n.sub(1)).div(2);
			}
		}

		return decMul(x, y);
	}

	function _getAbsoluteDifference(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
	}

	function _computeNominalCR(uint256 _coll, uint256 _debt) internal pure returns (uint256) {
		if (_debt > 0) {
			return _coll.mul(NICR_PRECISION).div(_debt);
		}
		// Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
		else {
			// if (_debt == 0)
			return 2**256 - 1;
		}
	}

	function _computeCR(
		uint256 _coll,
		uint256 _debt,
		uint256 _price
	) internal pure returns (uint256) {
		if (_debt > 0) {

			return _coll.mul(_price).div(_debt);
		}
		// Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
		else {
			// if (_debt == 0)
			return type(uint256).max;
		}
	}
}

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC20Decimals.sol";

library SafetyTransfer {
	using SafeMath for uint256;

	//_amount is in ether (1e18) and we want to convert it to the token decimal
	function decimalsCorrection(address _token, uint256 _amount)
		internal
		view
		returns (uint256)
	{
		if (_token == address(0)) return _amount;
		if (_amount == 0) return 0;

		uint8 decimals = ERC20Decimals(_token).decimals();
		if (decimals < 18) {
			return _amount.div(10**(18 - decimals));
		} else {
			return _amount.mul(10**(decimals - 18));
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "./IPool.sol";

interface IActivePool is IPool {
	// --- Events ---
	event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event ActivePoolSLSDDebtUpdated(address _asset, uint256 _SLSDDebt);
	event ActivePoolAssetBalanceUpdated(address _asset, uint256 _balance);

	// --- Functions ---
	function sendAsset(
		address _asset,
		address _account,
		uint256 _amount
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

// Common interface for the Trove Manager.
interface IBorrowerOperations {
	// --- Events ---

	event TreasuryAddressChanged(address _treausury);
	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event StabilityPoolAddressChanged(address _stabilityPoolAddress);
	event GasPoolAddressChanged(address _gasPoolAddress);
	event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
	event SortedTrovesAddressChanged(address _sortedTrovesAddress);
	event SLSDTokenAddressChanged(address _slsdTokenAddress);
	event PSYStakingAddressChanged(address _PSYStakingAddress);

	event TroveCreated(address indexed _asset, address indexed _borrower, uint256 arrayIndex);
	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 stake,
		uint8 operation
	);
	event SLSDBorrowingFeePaid(
		address indexed _asset,
		address indexed _borrower,
		uint256 _SLSDFee
	);

	// --- Functions ---

	function setAddresses(
		address _troveManagerAddress,
		address _troveManagerHelpersAddress,
		address _stabilityPoolAddress,
		address _gasPoolAddress,
		address _collSurplusPoolAddress,
		address _sortedTrovesAddress,
		address _slsdTokenAddress,
		address _PSYStakingAddress,
		address _treasury,
		address _psyParamsAddress
	) external;

	function openTrove(
		address _asset,
		uint256 _tokenAmount,
		uint256 _maxFee,
		uint256 _SLSDamount,
		address _upperHint,
		address _lowerHint
	) external payable;

	function addColl(
		address _asset,
		uint256 _assetSent,
		address _upperHint,
		address _lowerHint
	) external payable;

	function moveETHGainToTrove(
		address _asset,
		uint256 _amountMoved,
		address _user,
		address _upperHint,
		address _lowerHint
	) external payable;

	function withdrawColl(
		address _asset,
		uint256 _amount,
		address _upperHint,
		address _lowerHint
	) external;

	function withdrawSLSD(
		address _asset,
		uint256 _maxFee,
		uint256 _amount,
		address _upperHint,
		address _lowerHint
	) external;

	function repaySLSD(
		address _asset,
		uint256 _amount,
		address _upperHint,
		address _lowerHint
	) external;

	function closeTrove(address _asset) external;

	function adjustTrove(
		address _asset,
		uint256 _assetSent,
		uint256 _maxFee,
		uint256 _collWithdrawal,
		uint256 _debtChange,
		bool isDebtIncrease,
		address _upperHint,
		address _lowerHint
	) external payable;

	function claimCollateral(address _asset) external;

	function getCompositeDebt(address _asset, uint256 _debt) external view returns (uint256);

	function isContractBorrowerOps() external pure returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IDeposit.sol";

interface ICollSurplusPool is IDeposit {
	// --- Events ---

	event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event ActivePoolAddressChanged(address _newActivePoolAddress);

	event CollBalanceUpdated(address indexed _account, uint256 _newBalance);
	event AssetSent(address _to, uint256 _amount);

	// --- Contract setters ---

	function setAddresses(
		address _borrowerOperationsAddress,
		address _troveManagerAddress,
		address _troveManagerHelpersAddress,
		address _activePoolAddress
	) external;

	function getAssetBalance(address _asset) external view returns (uint256);

	function getCollateral(address _asset, address _account) external view returns (uint256);

	function accountSurplus(
		address _asset,
		address _account,
		uint256 _amount
	) external;

	function claimColl(address _asset, address _account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "./IPool.sol";

interface IDefaultPool is IPool {
	// --- Events ---
	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event DefaultPoolSLSDDebtUpdated(address _asset, uint256 _SLSDDebt);
	event DefaultPoolAssetBalanceUpdated(address _asset, uint256 _balance);

	// --- Functions ---
	function sendAssetToActivePool(address _asset, uint256 _amount) external;
}

pragma solidity ^0.8.14;

interface IDeposit {
	function receivedERC20(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IDeposit.sol";

// Common interface for the Pools.
interface IPool is IDeposit {
	// --- Events ---

	event AssetBalanceUpdated(uint256 _newBalance);
	event SLSDBalanceUpdated(uint256 _newBalance);
	event ActivePoolAddressChanged(address _newActivePoolAddress);
	event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
	event AssetAddressChanged(address _assetAddress);
	event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
	event AssetSent(address _to, address indexed _asset, uint256 _amount);

	// --- Functions ---

	function getAssetBalance(address _asset) external view returns (uint256);

	function getSLSDDebt(address _asset) external view returns (uint256);

	function increaseSLSDDebt(address _asset, uint256 _amount) external;

	function decreaseSLSDDebt(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface IPriceFeed {

	struct RegisteredOracle {
		address oracle;
		bool isRegistered;
	}

	event RegisteredNewOracle(
		address token,
		address oracle
	);

	// --- Function ---
	function addOracle(
		address _token,
		address _oracle
	) external;

	function fetchPrice(address _asset) external returns (uint256);

	function getDirectPrice(address _asset) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "./IPSYParameters.sol";

interface IPSYBase {
	event VaultParametersBaseChanged(address indexed newAddress);

	function psyParams() external view returns (IPSYParameters);
}

pragma solidity ^0.8.14;

import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IPriceFeed.sol";
import "./IPSYBase.sol";

interface IPSYParameters {
	error SafeCheckError(
		string parameter,
		uint256 valueEntered,
		uint256 minValue,
		uint256 maxValue
	);

	event MCRChanged(uint256 oldMCR, uint256 newMCR);
	event CCRChanged(uint256 oldCCR, uint256 newCCR);
	event GasCompensationChanged(uint256 oldGasComp, uint256 newGasComp);
	event MinNetDebtChanged(uint256 oldMinNet, uint256 newMinNet);
	event PercentDivisorChanged(uint256 oldPercentDiv, uint256 newPercentDiv);
	event BorrowingFeeFloorChanged(uint256 oldBorrowingFloorFee, uint256 newBorrowingFloorFee);
	event MaxBorrowingFeeChanged(uint256 oldMaxBorrowingFee, uint256 newMaxBorrowingFee);
	event RedemptionFeeFloorChanged(
		uint256 oldRedemptionFeeFloor,
		uint256 newRedemptionFeeFloor
	);
	event MaxRedemptionFeeChanged(
		uint256 oldMaxRedemptionFee,
		uint256 newMaxRedemptionFee
	);
	event RedemptionBlockRemoved(address _asset);
	event PriceFeedChanged(address indexed addr);

	function DECIMAL_PRECISION() external view returns (uint256);

	function _100pct() external view returns (uint256);

	// Minimum collateral ratio for individual troves
	function MCR(address _collateral) external view returns (uint256);

	// Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
	function CCR(address _collateral) external view returns (uint256);

	function SLSD_GAS_COMPENSATION(address _collateral) external view returns (uint256);

	function MIN_NET_DEBT(address _collateral) external view returns (uint256);

	function PERCENT_DIVISOR(address _collateral) external view returns (uint256);

	function BORROWING_FEE_FLOOR(address _collateral) external view returns (uint256);

	function REDEMPTION_FEE_FLOOR(address _collateral) external view returns (uint256);

	function MAX_BORROWING_FEE(address _collateral) external view returns (uint256);

	function MAX_REDEMPTION_FEE(address _collateral) external view returns (uint256);

	function redemptionBlock(address _collateral) external view returns (uint256);

	function activePool() external view returns (IActivePool);

	function defaultPool() external view returns (IDefaultPool);

	function priceFeed() external view returns (IPriceFeed);

	function setAddresses(
		address _activePool,
		address _defaultPool,
		address _priceFeed,
		address _adminContract
	) external;

	function setPriceFeed(address _priceFeed) external;

	function setMCR(address _asset, uint256 newMCR) external;

	function setCCR(address _asset, uint256 newCCR) external;

	function sanitizeParameters(address _asset) external;

	function setAsDefault(address _asset) external;

	function setAsDefaultWithRemptionBlock(address _asset, uint256 blockInDays) external;

	function setSLSDGasCompensation(address _asset, uint256 gasCompensation) external;

	function setMinNetDebt(address _asset, uint256 minNetDebt) external;

	function setPercentDivisor(address _asset, uint256 precentDivisor) external;

	function setBorrowingFeeFloor(address _asset, uint256 borrowingFeeFloor) external;

	function setMaxBorrowingFee(address _asset, uint256 maxBorrowingFee) external;

	function setRedemptionFeeFloor(address _asset, uint256 redemptionFeeFloor) external;

	function setMaxRedemptionFee(address _asset, uint256 maxRedemptionFee) external;

	function removeRedemptionBlock(address _asset) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IPSYStaking {
	// --- Events --

	event TreasuryAddressChanged(address _treausury);
	event SentToTreasury(address indexed _asset, uint256 _amount);
	event PSYTokenAddressSet(address _PSYTokenAddress);
	event SLSDTokenAddressSet(address _slsdTokenAddress);
	event TroveManagerAddressSet(address _troveManager);
	event BorrowerOperationsAddressSet(address _borrowerOperationsAddress);
	event ActivePoolAddressSet(address _activePoolAddress);

	event StakeChanged(address indexed staker, uint256 newStake);
	event StakingGainsAssetWithdrawn(
		address indexed staker,
		address indexed asset,
		uint256 AssetGain
	);
	event StakingGainsSLSDWithdrawn(address indexed staker, uint256 SLSDGain);
	event F_AssetUpdated(address indexed _asset, uint256 _F_ASSET);
	event F_SLSDUpdated(uint256 _F_SLSD);
	event TotalPSYStakedUpdated(uint256 _totalPSYStaked);
	event AssetSent(address indexed _asset, address indexed _account, uint256 _amount);
	event StakerSnapshotsUpdated(address _staker, uint256 _F_Asset, uint256 _F_SLSD);

	function psyToken() external view returns (IERC20);

	// --- Functions ---

	function setAddresses(
		address _PSYTokenAddress,
		address _slsdTokenAddress,
		address _troveManagerAddress,
		address _troveManagerHelpersAddress,
		address _borrowerOperationsAddress,
		address _activePoolAddress,
		address _treasury
	) external;

	function stake(uint256 _PSYamount) external;

	function unstake(uint256 _PSYamount) external;

	function increaseF_Asset(address _asset, uint256 _AssetFee) external;

	function increaseF_SLSD(uint256 _PSYFee) external;

	function getPendingAssetGain(address _asset, address _user) external view returns (uint256);

	function getPendingSLSDGain(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "../Dependencies/ERC20Permit.sol";
import "../Interfaces/IStabilityPoolManager.sol";

abstract contract ISLSDToken is ERC20Permit {
	// --- Events ---

	event StabilityPoolAddressChanged(address _newStabilityPoolAddress);

	event SLSDTokenBalanceUpdated(address _user, uint256 _amount);

	function emergencyStopMinting(address _asset, bool status) external virtual;

	function addTroveManager(address _troveManager) external virtual;

	function removeTroveManager(address _troveManager) external virtual;

	function addBorrowerOps(address _borrowerOps) external virtual;

	function removeBorrowerOps(address _borrowerOps) external virtual;

	function mint(
		address _asset,
		address _account,
		uint256 _amount
	) external virtual;

	function burn(address _account, uint256 _amount) external virtual;

	function sendToPool(
		address _sender,
		address poolAddress,
		uint256 _amount
	) external virtual;

	function returnFromPool(
		address poolAddress,
		address user,
		uint256 _amount
	) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {
	// --- Events ---

	event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
	event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
	event NodeAdded(address indexed _asset, address _id, uint256 _NICR);
	event NodeRemoved(address indexed _asset, address _id);

	// --- Functions ---

	function setParams(
		address _TroveManagerAddress,
		address _troveManagerHelpersAddress,
		address _borrowerOperationsAddress
	) external;

	function insert(
		address _asset,
		address _id,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external;

	function remove(address _asset, address _id) external;

	function reInsert(
		address _asset,
		address _id,
		uint256 _newICR,
		address _prevId,
		address _nextId
	) external;

	function contains(address _asset, address _id) external view returns (bool);

	function isFull(address _asset) external view returns (bool);

	function isEmpty(address _asset) external view returns (bool);

	function getSize(address _asset) external view returns (uint256);

	function getMaxSize(address _asset) external view returns (uint256);

	function getFirst(address _asset) external view returns (address);

	function getLast(address _asset) external view returns (address);

	function getNext(address _asset, address _id) external view returns (address);

	function getPrev(address _asset, address _id) external view returns (address);

	function validInsertPosition(
		address _asset,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external view returns (bool);

	function findInsertPosition(
		address _asset,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external view returns (address, address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IDeposit.sol";

interface IStabilityPool is IDeposit {
	// --- Events ---
	event StabilityPoolAssetBalanceUpdated(uint256 _newBalance);
	event StabilityPoolSLSDBalanceUpdated(uint256 _newBalance);

	event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
	event TroveManagerAddressChanged(address _newTroveManagerAddress);
	event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
	event SLSDTokenAddressChanged(address _newSLSDTokenAddress);
	event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
	event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

	event P_Updated(uint256 _P);
	event S_Updated(uint256 _S, uint128 _epoch, uint128 _scale);
	event G_Updated(uint256 _G, uint128 _epoch, uint128 _scale);
	event EpochUpdated(uint128 _currentEpoch);
	event ScaleUpdated(uint128 _currentScale);

	event DepositSnapshotUpdated(address indexed _depositor, uint256 _P, uint256 _S, uint256 _G);
	event SystemSnapshotUpdated(uint256 _P, uint256 _G);
	event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);
	event StakeChanged(uint256 _newSystemStake, address _depositor);

	event AssetGainWithdrawn(address indexed _depositor, uint256 _Asset, uint256 _SLSDLoss);
	event PSYPaidToDepositor(address indexed _depositor, uint256 _PSY);
	event AssetSent(address _to, uint256 _amount);

	// --- Functions ---

	function NAME() external view returns (string memory name);

	/*
	 * Called only once on init, to set addresses of other PSY contracts
	 * Callable only by owner, renounces ownership at the end
	 */
	function setAddresses(
		address _assetAddress,
		address _borrowerOperationsAddress,
		address _troveManagerAddress,
		address _troveManagerHelperAddress,
		address _slsdTokenAddress,
		address _sortedTrovesAddress,
		address _communityIssuanceAddress,
		address _psyParamsAddress
	) external;

	/*
	 * Initial checks:
	 * - Frontend is registered or zero address
	 * - Sender is not a registered frontend
	 * - _amount is not zero
	 * ---
	 * - Triggers a PSY issuance, based on time passed since the last issuance. The PSY issuance is shared between *all* depositors and front ends
	 * - Tags the deposit with the provided front end tag param, if it's a new deposit
	 * - Sends depositor's accumulated gains (PSY, ETH) to depositor
	 * - Sends the tagged front end's accumulated PSY gains to the tagged front end
	 * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
	 */
	function provideToSP(uint256 _amount) external;

	/*
	 * Initial checks:
	 * - _amount is zero or there are no under collateralized troves left in the system
	 * - User has a non zero deposit
	 * ---
	 * - Triggers a PSY issuance, based on time passed since the last issuance. The PSY issuance is shared between *all* depositors and front ends
	 * - Removes the deposit's front end tag if it is a full withdrawal
	 * - Sends all depositor's accumulated gains (PSY, ETH) to depositor
	 * - Sends the tagged front end's accumulated PSY gains to the tagged front end
	 * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
	 *
	 * If _amount > userDeposit, the user withdraws all of their compounded deposit.
	 */
	function withdrawFromSP(uint256 _amount) external;

	/*
	 * Initial checks:
	 * - User has a non zero deposit
	 * - User has an open trove
	 * - User has some ETH gain
	 * ---
	 * - Triggers a PSY issuance, based on time passed since the last issuance. The PSY issuance is shared between *all* depositors and front ends
	 * - Sends all depositor's PSY gain to  depositor
	 * - Sends all tagged front end's PSY gain to the tagged front end
	 * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
	 * - Leaves their compounded deposit in the Stability Pool
	 * - Updates snapshots for deposit and tagged front end stake
	 */
	function withdrawAssetGainToTrove(address _upperHint, address _lowerHint) external;

	/*
	 * Initial checks:
	 * - Caller is TroveManager
	 * ---
	 * Cancels out the specified debt against the SLSD contained in the Stability Pool (as far as possible)
	 * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
	 * Only called by liquidation functions in the TroveManager.
	 */
	function offset(uint256 _debt, uint256 _coll) external;

	/*
	 * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
	 * to exclude edge cases like ETH received from a self-destruct.
	 */
	function getAssetBalance() external view returns (uint256);

	/*
	 * Returns SLSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
	 */
	function getTotalSLSDDeposits() external view returns (uint256);

	/*
	 * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
	 */
	function getDepositorAssetGain(address _depositor) external view returns (uint256);

	/*
	 * Calculate the PSY gain earned by a deposit since its last snapshots were taken.
	 * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
	 * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
	 * which they made their deposit.
	 */
	function getDepositorPSYGain(address _depositor) external view returns (uint256);

	/*
	 * Return the user's compounded deposit.
	 */
	function getCompoundedSLSDDeposit(address _depositor) external view returns (uint256);

	/*
	 * Return the front end's compounded stake.
	 *
	 * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
	 */
	function getCompoundedTotalStake() external view returns (uint256);

	function getNameBytes() external view returns (bytes32);

	function getAssetType() external view returns (address);

	/*
	 * Fallback function
	 * Only callable by Active Pool, it just accounts for ETH received
	 * receive() external payable;
	 */
}

pragma solidity ^0.8.14;

import "./IStabilityPool.sol";

interface IStabilityPoolManager {
	event StabilityPoolAdded(address asset, address stabilityPool);
	event StabilityPoolRemoved(address asset, address stabilityPool);

	function isStabilityPool(address stabilityPool) external view returns (bool);

	function addStabilityPool(address asset, address stabilityPool) external;

	function getAssetStabilityPool(address asset) external view returns (IStabilityPool);

	function unsafeGetAssetStabilityPool(address asset) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "./IPSYBase.sol";
import "./IStabilityPool.sol";
import "./ISLSDToken.sol";
import "./IPSYStaking.sol";
import "./ICollSurplusPool.sol";
import "./ISortedTroves.sol";
import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IStabilityPoolManager.sol";
import "./ITroveManagerHelpers.sol";

// Common interface for the Trove Manager.
interface ITroveManager is IPSYBase {
	enum Status {
		nonExistent,
		active,
		closedByOwner,
		closedByLiquidation,
		closedByRedemption
	}

	// Store the necessary data for a trove
	struct Trove {
		address asset;
		uint256 debt;
		uint256 coll;
		uint256 stake;
		Status status;
		uint128 arrayIndex;
	}

	/*
	 * --- Variable container structs for liquidations ---
	 *
	 * These structs are used to hold, return and assign variables inside the liquidation functions,
	 * in order to avoid the error: "CompilerError: Stack too deep".
	 **/

	struct LocalVariables_OuterLiquidationFunction {
		uint256 price;
		uint256 SLSDInStabPool;
		bool recoveryModeAtStart;
		uint256 liquidatedDebt;
		uint256 liquidatedColl;
	}

	struct LocalVariables_InnerSingleLiquidateFunction {
		uint256 collToLiquidate;
		uint256 pendingDebtReward;
		uint256 pendingCollReward;
	}

	struct LocalVariables_LiquidationSequence {
		uint256 remainingSLSDInStabPool;
		uint256 i;
		uint256 ICR;
		address user;
		bool backToNormalMode;
		uint256 entireSystemDebt;
		uint256 entireSystemColl;
	}

	struct LocalVariables_AssetBorrowerPrice {
		address _asset;
		address _borrower;
		uint256 _price;
	}

	struct LiquidationValues {
		uint256 entireTroveDebt;
		uint256 entireTroveColl;
		uint256 collGasCompensation;
		uint256 SLSDGasCompensation;
		uint256 debtToOffset;
		uint256 collToSendToSP;
		uint256 debtToRedistribute;
		uint256 collToRedistribute;
		uint256 collSurplus;
	}

	struct LiquidationTotals {
		uint256 totalCollInSequence;
		uint256 totalDebtInSequence;
		uint256 totalCollGasCompensation;
		uint256 totalSLSDGasCompensation;
		uint256 totalDebtToOffset;
		uint256 totalCollToSendToSP;
		uint256 totalDebtToRedistribute;
		uint256 totalCollToRedistribute;
		uint256 totalCollSurplus;
	}

	struct ContractsCache {
		IActivePool activePool;
		IDefaultPool defaultPool;
		ISLSDToken slsdToken;
		IPSYStaking psyStaking;
		ISortedTroves sortedTroves;
		ICollSurplusPool collSurplusPool;
		address gasPoolAddress;
	}
	// --- Variable container structs for redemptions ---

	struct RedemptionTotals {
		uint256 remainingSLSD;
		uint256 totalSLSDToRedeem;
		uint256 totalAssetDrawn;
		uint256 ETHFee;
		uint256 ETHToSendToRedeemer;
		uint256 decayedBaseRate;
		uint256 price;
		uint256 totalSLSDSupplyAtStart;
	}

	struct SingleRedemptionValues {
		uint256 SLSDLot;
		uint256 ETHLot;
		bool cancelledPartial;
	}

	// --- Events ---

	event Liquidation(
		address indexed _asset,
		uint256 _liquidatedDebt,
		uint256 _liquidatedColl,
		uint256 _collGasCompensation,
		uint256 _SLSDGasCompensation
	);
	event Redemption(
		address indexed _asset,
		uint256 _attemptedSLSDAmount,
		uint256 _actualSLSDAmount,
		uint256 _AssetSent,
		uint256 _AssetFee
	);
	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 stake,
		uint8 operation
	);
	event TroveLiquidated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint8 operation
	);
	event TreasuryAddressChanged(address _treausury);
	event BaseRateUpdated(address indexed _asset, uint256 _baseRate);
	event LastFeeOpTimeUpdated(address indexed _asset, uint256 _lastFeeOpTime);
	event TotalStakesUpdated(address indexed _asset, uint256 _newTotalStakes);
	event SystemSnapshotsUpdated(
		address indexed _asset,
		uint256 _totalStakesSnapshot,
		uint256 _totalCollateralSnapshot
	);
	event LTermsUpdated(address indexed _asset, uint256 _L_ETH, uint256 _L_SLSDDebt);
	event TroveSnapshotsUpdated(address indexed _asset, uint256 _L_ETH, uint256 _L_SLSDDebt);
	event TroveIndexUpdated(address indexed _asset, address _borrower, uint256 _newIndex);

	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 _stake,
		TroveManagerOperation _operation
	);
	event TroveLiquidated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		TroveManagerOperation _operation
	);

	enum TroveManagerOperation {
		applyPendingRewards,
		liquidateInNormalMode,
		liquidateInRecoveryMode,
		redeemCollateral
	}

	// --- Functions ---
	function isContractTroveManager() external pure returns (bool);

	function troveManagerHelpers() external view returns (ITroveManagerHelpers);

	function setAddresses(
		address _stabilityPoolManagerAddress,
		address _gasPoolAddress,
		address _collSurplusPoolAddress,
		address _slsdTokenAddress,
		address _sortedTrovesAddress,
		address _psyStakingAddress,
		address _treasury,
		address _psyParamsAddress,
		address _troveManagerHelpersAddress
	) external;

	function stabilityPoolManager() external view returns (IStabilityPoolManager);

	function slsdToken() external view returns (ISLSDToken);

	function psyStaking() external view returns (IPSYStaking);

	function liquidate(address _asset, address borrower) external;

	function liquidateTroves(address _asset, uint256 _n) external;

	function batchLiquidateTroves(address _asset, address[] memory _troveArray) external;

	function redeemCollateral(
		address _asset,
		uint256 _SLSDamount,
		address _firstRedemptionHint,
		address _upperPartialRedemptionHint,
		address _lowerPartialRedemptionHint,
		uint256 _partialRedemptionHintNICR,
		uint256 _maxIterations,
		uint256 _maxFee
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "./IPSYBase.sol";
import "./IStabilityPool.sol";
import "./ISLSDToken.sol";
import "./IPSYStaking.sol";
import "./ICollSurplusPool.sol";
import "./ISortedTroves.sol";
import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IStabilityPoolManager.sol";

// Common interface for the Trove Manager.
interface ITroveManagerHelpers is IPSYBase {
	enum Status {
		nonExistent,
		active,
		closedByOwner,
		closedByLiquidation,
		closedByRedemption
	}

	// Store the necessary data for a trove
	struct Trove {
		address asset;
		uint256 debt;
		uint256 coll;
		uint256 stake;
		Status status;
		uint128 arrayIndex;
	}

	/*
	 * --- Variable container structs for liquidations ---
	 *
	 * These structs are used to hold, return and assign variables inside the liquidation functions,
	 * in order to avoid the error: "CompilerError: Stack too deep".
	 **/

	struct LocalVariables_OuterLiquidationFunction {
		uint256 price;
		uint256 SLSDInStabPool;
		bool recoveryModeAtStart;
		uint256 liquidatedDebt;
		uint256 liquidatedColl;
	}

	struct LocalVariables_InnerSingleLiquidateFunction {
		uint256 collToLiquidate;
		uint256 pendingDebtReward;
		uint256 pendingCollReward;
	}

	struct LocalVariables_LiquidationSequence {
		uint256 remainingSLSDInStabPool;
		uint256 i;
		uint256 ICR;
		address user;
		bool backToNormalMode;
		uint256 entireSystemDebt;
		uint256 entireSystemColl;
	}

	struct LocalVariables_AssetBorrowerPrice {
		address _asset;
		address _borrower;
		uint256 _price;
	}

	struct LiquidationValues {
		uint256 entireTroveDebt;
		uint256 entireTroveColl;
		uint256 collGasCompensation;
		uint256 SLSDGasCompensation;
		uint256 debtToOffset;
		uint256 collToSendToSP;
		uint256 debtToRedistribute;
		uint256 collToRedistribute;
		uint256 collSurplus;
	}

	struct LiquidationTotals {
		uint256 totalCollInSequence;
		uint256 totalDebtInSequence;
		uint256 totalCollGasCompensation;
		uint256 totalSLSDGasCompensation;
		uint256 totalDebtToOffset;
		uint256 totalCollToSendToSP;
		uint256 totalDebtToRedistribute;
		uint256 totalCollToRedistribute;
		uint256 totalCollSurplus;
	}

	struct ContractsCache {
		IActivePool activePool;
		IDefaultPool defaultPool;
		ISLSDToken slsdToken;
		IPSYStaking psyStaking;
		ISortedTroves sortedTroves;
		ICollSurplusPool collSurplusPool;
		address gasPoolAddress;
	}
	// --- Variable container structs for redemptions ---

	struct RedemptionTotals {
		uint256 remainingSLSD;
		uint256 totalSLSDToRedeem;
		uint256 totalAssetDrawn;
		uint256 ETHFee;
		uint256 ETHToSendToRedeemer;
		uint256 decayedBaseRate;
		uint256 price;
		uint256 totalSLSDSupplyAtStart;
	}

	struct SingleRedemptionValues {
		uint256 SLSDLot;
		uint256 ETHLot;
		bool cancelledPartial;
	}

	// Object containing the ETH and SLSD snapshots for a given active trove
	struct RewardSnapshot {
		uint256 asset;
		uint256 SLSDDebt;
	}

	// --- Events ---

	event Liquidation(
		address indexed _asset,
		uint256 _liquidatedDebt,
		uint256 _liquidatedColl,
		uint256 _collGasCompensation,
		uint256 _SLSDGasCompensation
	);
	event Redemption(
		address indexed _asset,
		uint256 _attemptedSLSDAmount,
		uint256 _actualSLSDAmount,
		uint256 _AssetSent,
		uint256 _AssetFee
	);
	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 stake,
		uint8 operation
	);
	event TroveLiquidated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint8 operation
	);
	event BaseRateUpdated(address indexed _asset, uint256 _baseRate);
	event LastFeeOpTimeUpdated(address indexed _asset, uint256 _lastFeeOpTime);
	event TotalStakesUpdated(address indexed _asset, uint256 _newTotalStakes);
	event SystemSnapshotsUpdated(
		address indexed _asset,
		uint256 _totalStakesSnapshot,
		uint256 _totalCollateralSnapshot
	);
	event LTermsUpdated(address indexed _asset, uint256 _L_ETH, uint256 _L_SLSDDebt);
	event TroveSnapshotsUpdated(address indexed _asset, uint256 _L_ETH, uint256 _L_SLSDDebt);
	event TroveIndexUpdated(address indexed _asset, address _borrower, uint256 _newIndex);

	event TroveUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 _stake,
		TroveManagerOperation _operation
	);
	event TroveLiquidated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		TroveManagerOperation _operation
	);

	enum TroveManagerOperation {
		applyPendingRewards,
		liquidateInNormalMode,
		liquidateInRecoveryMode,
		redeemCollateral
	}

	// Functions

	function addTroveOwnerToArray(address _asset, address _borrower)
		external
		returns (uint256 index);

	function applyPendingRewards(address _asset, address _borrower) external;

	function checkRecoveryMode(address _asset, uint256 _price) external returns (bool);

	function closeTrove(address _asset, address _borrower) external;

	function decayBaseRateFromBorrowing(address _asset) external;

	function decreaseTroveColl(
		address _asset,
		address _borrower,
		uint256 _collDecrease
	) external returns (uint256);

	function decreaseTroveDebt(
		address _asset,
		address _borrower,
		uint256 _collDecrease
	) external returns (uint256);

	function getBorrowingFee(address _asset, uint256 SLSDDebt) external view returns (uint256);

	function getBorrowingRateWithDecay(address _asset) external view returns (uint256);

	function getBorrowingRate(address _asset) external view returns (uint256);

	function getCurrentICR(
		address _asset,
		address _borrower,
		uint256 _price
	) external view returns (uint256);

	function getEntireDebtAndColl(address _asset, address _borrower)
		external
		view
		returns (
			uint256 debt,
			uint256 coll,
			uint256 pendingSLSDDebtReward,
			uint256 pendingAssetReward
		);

	function getNominalICR(address _asset, address _borrower) external view returns (uint256);

	function getPendingAssetReward(address _asset, address _borrower)
		external
		view
		returns (uint256);

	function getPendingSLSDDebtReward(address _asset, address _borrower)
		external
		view
		returns (uint256);

	function getRedemptionFeeWithDecay(address _asset, uint256 _assetDraw)
		external
		view
		returns (uint256);

	function getRedemptionRate(address _asset) external view returns (uint256);

	function getRedemptionRateWithDecay(address _asset) external view returns (uint256);

	function getTCR(address _asset, uint256 _price) external view returns (uint256);

	function getTroveColl(address _asset, address _borrower) external view returns (uint256);

	function getTroveDebt(address _asset, address _borrower) external view returns (uint256);

	function getTroveStake(address _asset, address _borrower) external view returns (uint256);

	function getTroveStatus(address _asset, address _borrower) external view returns (uint256);

	function hasPendingRewards(address _asset, address _borrower) external view returns (bool);

	function increaseTroveColl(
		address _asset,
		address _borrower,
		uint256 _collIncrease
	) external returns (uint256);

	function increaseTroveDebt(
		address _asset,
		address _borrower,
		uint256 _debtIncrease
	) external returns (uint256);

	function setTroveStatus(
		address _asset,
		address _borrower,
		uint256 num
	) external;

	function updateTroveRewardSnapshots(address _asset, address _borrower) external;

	function getBorrowingFeeWithDecay(address _asset, uint256 _SLSDDebt)
		external
		view
		returns (uint256);

	function getTroveOwnersCount(address _asset) external view returns (uint256);

	function getTroveFromTroveOwnersArray(address _asset, uint256 _index)
		external
		view
		returns (address);

	function setTroveDeptAndColl(
		address _asset,
		address _borrower,
		uint256 _debt,
		uint256 _coll
	) external;

	function isTroveActive(address _asset, address _borrower) external view returns (bool);

	function movePendingTroveRewardsToActivePool(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _SLSD,
		uint256 _amount
	) external;

	function removeStake(address _asset, address _borrower) external;

	function closeTrove(
		// access control
		address _asset,
		address _borrower,
		Status closedStatus
	) external;

	function redistributeDebtAndColl(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		uint256 _debt,
		uint256 _coll
	) external;

	function updateSystemSnapshots_excludeCollRemainder(
		// access control
		address _asset,
		IActivePool _activePool,
		uint256 _collRemainder
	) external;

	function _checkPotentialRecoveryMode(
		// access control
		address _asset,
		uint256 _entireSystemColl,
		uint256 _entireSystemDebt,
		uint256 _price
	) external view returns (bool);

	function updateBaseRateFromRedemption(
		address _asset,
		uint256 _ETHDrawn,
		uint256 _price,
		uint256 _totalSLSDSupply
	) external returns (uint256);

	function updateStakeAndTotalStakes(address _asset, address _borrower)
		external
		returns (uint256);

	function _requireValidMaxFeePercentage(address _asset, uint256 _maxFeePercentage)
		external
		view;

	function _requireTCRoverMCR(address _asset, uint256 _price) external view;

	function _requireAmountGreaterThanZero(uint256 _amount) external pure;

	function _requireSLSDBalanceCoversRedemption(
		ISLSDToken _slsdToken,
		address _redeemer,
		uint256 _amount
	) external view;

	function applyPendingRewards(
		address _asset,
		IActivePool _activePool,
		IDefaultPool _defaultPool,
		address _borrower
	) external;

	function _getRedemptionFee(address _asset, uint256 _assetDraw)
		external
		view
		returns (uint256);

	function getTrove(address _asset, address _borrower)
		external
		view
		returns (
			address,
			uint256,
			uint256,
			uint256,
			Status,
			uint128
		);

	function getRewardSnapshots(address _asset, address _troveOwner)
		external
		view
		returns (uint256 asset, uint256 SLSDDebt);
}