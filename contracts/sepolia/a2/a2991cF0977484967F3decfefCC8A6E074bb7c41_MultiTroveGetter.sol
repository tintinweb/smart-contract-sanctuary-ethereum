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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
pragma experimental ABIEncoderV2;

import "./Interfaces/ITroveManager.sol";
import "./Interfaces/ITroveManagerHelpers.sol";
import "./SortedTroves.sol";

/*  Helper contract for grabbing Trove data for the front end. Not part of the core PSY system. */
contract MultiTroveGetter {
	struct CombinedTroveData {
		address owner;
		address asset;
		uint256 debt;
		uint256 coll;
		uint256 stake;
		uint256 snapshotAsset;
		uint256 snapshotSLSDDebt;
	}

	ITroveManager public troveManager; // XXX Troves missing from ITroveManager?
	ITroveManagerHelpers public troveManagerHelpers;
	ISortedTroves public sortedTroves;

	constructor(
		ITroveManager _troveManager,
		ITroveManagerHelpers _troveManagerHelpers,
		ISortedTroves _sortedTroves
	) {
		troveManager = _troveManager;
		troveManagerHelpers = _troveManagerHelpers;
		sortedTroves = _sortedTroves;
	}

	function getMultipleSortedTroves(
		address _asset,
		int256 _startIdx,
		uint256 _count
	) external view returns (CombinedTroveData[] memory _troves) {
		uint256 startIdx;
		bool descend;

		if (_startIdx >= 0) {
			startIdx = uint256(_startIdx);
			descend = true;
		} else {
			startIdx = uint256(-(_startIdx + 1));
			descend = false;
		}

		uint256 sortedTrovesSize = sortedTroves.getSize(_asset);

		if (startIdx >= sortedTrovesSize) {
			_troves = new CombinedTroveData[](0);
		} else {
			uint256 maxCount = sortedTrovesSize - startIdx;

			if (_count > maxCount) {
				_count = maxCount;
			}

			if (descend) {
				_troves = _getMultipleSortedTrovesFromHead(_asset, startIdx, _count);
			} else {
				_troves = _getMultipleSortedTrovesFromTail(_asset, startIdx, _count);
			}
		}
	}

	function _getMultipleSortedTrovesFromHead(
		address _asset,
		uint256 _startIdx,
		uint256 _count
	) internal view returns (CombinedTroveData[] memory _troves) {
		address currentTroveowner = sortedTroves.getFirst(_asset);

		for (uint256 idx = 0; idx < _startIdx; ++idx) {
			currentTroveowner = sortedTroves.getNext(_asset, currentTroveowner);
		}

		_troves = new CombinedTroveData[](_count);

		for (uint256 idx = 0; idx < _count; ++idx) {
			_troves[idx].owner = currentTroveowner;
			(
				_troves[idx].asset,
				_troves[idx].debt,
				_troves[idx].coll,
				_troves[idx].stake,
				/* status */
				/* arrayIndex */
				,

			) = troveManagerHelpers.getTrove(_asset, currentTroveowner);
			(_troves[idx].snapshotAsset, _troves[idx].snapshotSLSDDebt) = troveManagerHelpers
				.getRewardSnapshots(_asset, currentTroveowner);

			currentTroveowner = sortedTroves.getNext(_asset, currentTroveowner);
		}
	}

	function _getMultipleSortedTrovesFromTail(
		address _asset,
		uint256 _startIdx,
		uint256 _count
	) internal view returns (CombinedTroveData[] memory _troves) {
		address currentTroveowner = sortedTroves.getLast(_asset);

		for (uint256 idx = 0; idx < _startIdx; ++idx) {
			currentTroveowner = sortedTroves.getPrev(_asset, currentTroveowner);
		}

		_troves = new CombinedTroveData[](_count);

		for (uint256 idx = 0; idx < _count; ++idx) {
			_troves[idx].owner = currentTroveowner;
			(
				_troves[idx].asset,
				_troves[idx].debt,
				_troves[idx].coll,
				_troves[idx].stake,
				/* status */
				/* arrayIndex */
				,

			) = troveManagerHelpers.getTrove(_asset, currentTroveowner);
			(_troves[idx].snapshotAsset, _troves[idx].snapshotSLSDDebt) = troveManagerHelpers
				.getRewardSnapshots(_asset, currentTroveowner);

			currentTroveowner = sortedTroves.getPrev(_asset, currentTroveowner);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;
import "./Interfaces/ISortedTroves.sol";
import "./Interfaces/ITroveManager.sol";
import "./Interfaces/ITroveManagerHelpers.sol";
import "./Interfaces/IBorrowerOperations.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Dependencies/CheckContract.sol";
import "./Dependencies/Initializable.sol";

/*
 * A sorted doubly linked list with nodes sorted in descending order.
 *
 * Nodes map to active Troves in the system - the ID property is the address of a Trove owner.
 * Nodes are ordered according to their current nominal individual collateral ratio (NICR),
 * which is like the ICR but without the price, i.e., just collateral / debt.
 *
 * The list optionally accepts insert position hints.
 *
 * NICRs are computed dynamically at runtime, and not stored on the Node. This is because NICRs of active Troves
 * change dynamically as liquidation events occur.
 *
 * The list relies on the fact that liquidation events preserve ordering: a liquidation decreases the NICRs of all active Troves,
 * but maintains their order. A node inserted based on current NICR will maintain the correct position,
 * relative to it's peers, as rewards accumulate, as long as it's raw collateral and debt have not changed.
 * Thus, Nodes remain sorted by current NICR.
 *
 * Nodes need only be re-inserted upon a Trove operation - when the owner adds or removes collateral or debt
 * to their position.
 *
 * The list is a modification of the following audited SortedDoublyLinkedList:
 * https://github.com/livepeer/protocol/blob/master/contracts/libraries/SortedDoublyLL.sol
 *
 *
 * Changes made in the PSY implementation:
 *
 * - Keys have been removed from nodes
 *
 * - Ordering checks for insertion are performed by comparing an NICR argument to the current NICR, calculated at runtime.
 *   The list relies on the property that ordering by ICR is maintained as the ETH:USD price varies.
 *
 * - Public functions with parameters have been made internal to save gas, and given an external wrapper function for external access
 */
contract SortedTroves is Ownable, CheckContract, Initializable, ISortedTroves {
	using SafeMath for uint256;

	bool public isInitialized;

	string public constant NAME = "SortedTroves";
	address constant ETH_REF_ADDRESS = address(0);
	uint256 constant MAX_UINT256 = type(uint256).max;

	event TroveManagerAddressChanged(address _troveManagerAddress);

	address public borrowerOperationsAddress;

	ITroveManager public troveManager;
	ITroveManagerHelpers public troveManagerHelpers;

	// Information for a node in the list
	struct Node {
		bool exists;
		address nextId; // Id of next node (smaller NICR) in the list
		address prevId; // Id of previous node (larger NICR) in the list
	}

	// Information for the list
	struct Data {
		address head; // Head of the list. Also the node in the list with the largest NICR
		address tail; // Tail of the list. Also the node in the list with the smallest NICR
		uint256 maxSize; // Maximum size of the list
		uint256 size; // Current size of the list
		mapping(address => Node) nodes; // Track the corresponding ids for each node in the list
	}

	mapping(address => Data) public data;

	// --- Dependency setters ---

	function setParams(
		address _troveManagerAddress,
		address _troveManagerHelpersAddress,
		address _borrowerOperationsAddress
	) external override initializer onlyOwner {
		require(!isInitialized, "Already initialized");
		checkContract(_troveManagerAddress);
		checkContract(_troveManagerHelpersAddress);
		checkContract(_borrowerOperationsAddress);
		isInitialized = true;

		data[ETH_REF_ADDRESS].maxSize = MAX_UINT256;

		troveManager = ITroveManager(_troveManagerAddress);
		troveManagerHelpers = ITroveManagerHelpers(_troveManagerHelpersAddress);
		borrowerOperationsAddress = _borrowerOperationsAddress;

		emit TroveManagerAddressChanged(_troveManagerAddress);
		emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);

		renounceOwnership();
	}

	/*
	 * @dev Add a node to the list
	 * @param _id Node's id
	 * @param _NICR Node's NICR
	 * @param _prevId Id of previous node for the insert position
	 * @param _nextId Id of next node for the insert position
	 */

	function insert(
		address _asset,
		address _id,
		uint256 _NICR,
		address _prevId,
		address _nextId
	) external override {
		ITroveManager troveManagerCached = troveManager;
		ITroveManagerHelpers troveManagerHelpersCached = troveManagerHelpers;
		_requireCallerIsBOorTroveM(troveManagerCached, troveManagerHelpersCached);
		_insert(
			_asset,
			troveManagerCached,
			troveManagerHelpersCached,
			_id,
			_NICR,
			_prevId,
			_nextId
		);
	}

	function _insert(
		address _asset,
		ITroveManager _troveManager,
		ITroveManagerHelpers _troveManagerHelpers,
		address _id,
		uint256 _NICR,
		address _prevId,
		address _nextId
	) internal {
		if (data[_asset].maxSize == 0) {
			data[_asset].maxSize = MAX_UINT256;
		}

		// List must not be full
		require(!isFull(_asset), "SortedTroves: List is full");
		// List must not already contain node
		require(!contains(_asset, _id), "SortedTroves: List already contains the node");
		// Node id must not be null
		require(_id != address(0), "SortedTroves: Id cannot be zero");
		// NICR must be non-zero
		require(_NICR > 0, "SortedTroves: NICR must be positive");

		address prevId = _prevId;
		address nextId = _nextId;

		if (!_validInsertPosition(_asset, _troveManagerHelpers, _NICR, prevId, nextId)) {
			// Sender's hint was not a valid insert position
			// Use sender's hint to find a valid insert position
			(prevId, nextId) = _findInsertPosition(
				_asset,
				_troveManagerHelpers,
				_NICR,
				prevId,
				nextId
			);
		}

		data[_asset].nodes[_id].exists = true;

		if (prevId == address(0) && nextId == address(0)) {
			// Insert as head and tail
			data[_asset].head = _id;
			data[_asset].tail = _id;
		} else if (prevId == address(0)) {
			// Insert before `prevId` as the head
			data[_asset].nodes[_id].nextId = data[_asset].head;
			data[_asset].nodes[data[_asset].head].prevId = _id;
			data[_asset].head = _id;
		} else if (nextId == address(0)) {
			// Insert after `nextId` as the tail
			data[_asset].nodes[_id].prevId = data[_asset].tail;
			data[_asset].nodes[data[_asset].tail].nextId = _id;
			data[_asset].tail = _id;
		} else {
			// Insert at insert position between `prevId` and `nextId`
			data[_asset].nodes[_id].nextId = nextId;
			data[_asset].nodes[_id].prevId = prevId;
			data[_asset].nodes[prevId].nextId = _id;
			data[_asset].nodes[nextId].prevId = _id;
		}

		data[_asset].size = data[_asset].size.add(1);
		emit NodeAdded(_asset, _id, _NICR);
	}

	function remove(address _asset, address _id) external override {
		_requireCallerIsTroveManager();
		_remove(_asset, _id);
	}

	/*
	 * @dev Remove a node from the list
	 * @param _id Node's id
	 */
	function _remove(address _asset, address _id) internal {
		// List must contain the node
		require(contains(_asset, _id), "SortedTroves: List does not contain the id");

		if (data[_asset].size > 1) {
			// List contains more than a single node
			if (_id == data[_asset].head) {
				// The removed node is the head
				// Set head to next node
				data[_asset].head = data[_asset].nodes[_id].nextId;
				// Set prev pointer of new head to null
				data[_asset].nodes[data[_asset].head].prevId = address(0);
			} else if (_id == data[_asset].tail) {
				// The removed node is the tail
				// Set tail to previous node
				data[_asset].tail = data[_asset].nodes[_id].prevId;
				// Set next pointer of new tail to null
				data[_asset].nodes[data[_asset].tail].nextId = address(0);
			} else {
				// The removed node is neither the head nor the tail
				// Set next pointer of previous node to the next node
				data[_asset].nodes[data[_asset].nodes[_id].prevId].nextId = data[_asset]
					.nodes[_id]
					.nextId;
				// Set prev pointer of next node to the previous node
				data[_asset].nodes[data[_asset].nodes[_id].nextId].prevId = data[_asset]
					.nodes[_id]
					.prevId;
			}
		} else {
			// List contains a single node
			// Set the head and tail to null
			data[_asset].head = address(0);
			data[_asset].tail = address(0);
		}

		delete data[_asset].nodes[_id];
		data[_asset].size = data[_asset].size.sub(1);
		emit NodeRemoved(_asset, _id);
	}

	/*
	 * @dev Re-insert the node at a new position, based on its new NICR
	 * @param _id Node's id
	 * @param _newNICR Node's new NICR
	 * @param _prevId Id of previous node for the new insert position
	 * @param _nextId Id of next node for the new insert position
	 */
	function reInsert(
		address _asset,
		address _id,
		uint256 _newNICR,
		address _prevId,
		address _nextId
	) external override {
		ITroveManager troveManagerCached = troveManager;
		ITroveManagerHelpers troveManagerHelpersCached = troveManagerHelpers;

		_requireCallerIsBOorTroveM(troveManagerCached, troveManagerHelpersCached);
		// List must contain the node
		require(contains(_asset, _id), "SortedTroves: List does not contain the id");
		// NICR must be non-zero
		require(_newNICR > 0, "SortedTroves: NICR must be positive");

		// Remove node from the list
		_remove(_asset, _id);

		_insert(
			_asset,
			troveManagerCached,
			troveManagerHelpersCached,
			_id,
			_newNICR,
			_prevId,
			_nextId
		);
	}

	/*
	 * @dev Checks if the list contains a node
	 */
	function contains(address _asset, address _id) public view override returns (bool) {
		return data[_asset].nodes[_id].exists;
	}

	/*
	 * @dev Checks if the list is full
	 */
	function isFull(address _asset) public view override returns (bool) {
		return data[_asset].size == data[_asset].maxSize;
	}

	/*
	 * @dev Checks if the list is empty
	 */
	function isEmpty(address _asset) public view override returns (bool) {
		return data[_asset].size == 0;
	}

	/*
	 * @dev Returns the current size of the list
	 */
	function getSize(address _asset) external view override returns (uint256) {
		return data[_asset].size;
	}

	/*
	 * @dev Returns the maximum size of the list
	 */
	function getMaxSize(address _asset) external view override returns (uint256) {
		return data[_asset].maxSize;
	}

	/*
	 * @dev Returns the first node in the list (node with the largest NICR)
	 */
	function getFirst(address _asset) external view override returns (address) {
		return data[_asset].head;
	}

	/*
	 * @dev Returns the last node in the list (node with the smallest NICR)
	 */
	function getLast(address _asset) external view override returns (address) {
		return data[_asset].tail;
	}

	/*
	 * @dev Returns the next node (with a smaller NICR) in the list for a given node
	 * @param _id Node's id
	 */
	function getNext(address _asset, address _id) external view override returns (address) {
		return data[_asset].nodes[_id].nextId;
	}

	/*
	 * @dev Returns the previous node (with a larger NICR) in the list for a given node
	 * @param _id Node's id
	 */
	function getPrev(address _asset, address _id) external view override returns (address) {
		return data[_asset].nodes[_id].prevId;
	}

	/*
	 * @dev Check if a pair of nodes is a valid insertion point for a new node with the given NICR
	 * @param _NICR Node's NICR
	 * @param _prevId Id of previous node for the insert position
	 * @param _nextId Id of next node for the insert position
	 */
	function validInsertPosition(
		address _asset,
		uint256 _NICR,
		address _prevId,
		address _nextId
	) external view override returns (bool) {
		return _validInsertPosition(_asset, troveManagerHelpers, _NICR, _prevId, _nextId);
	}

	function _validInsertPosition(
		address _asset,
		ITroveManagerHelpers _troveManagerHelpers,
		uint256 _NICR,
		address _prevId,
		address _nextId
	) internal view returns (bool) {
		if (_prevId == address(0) && _nextId == address(0)) {
			// `(null, null)` is a valid insert position if the list is empty
			return isEmpty(_asset);
		} else if (_prevId == address(0)) {
			// `(null, _nextId)` is a valid insert position if `_nextId` is the head of the list
			return
				data[_asset].head == _nextId &&
				_NICR >= _troveManagerHelpers.getNominalICR(_asset, _nextId);
		} else if (_nextId == address(0)) {
			// `(_prevId, null)` is a valid insert position if `_prevId` is the tail of the list
			return
				data[_asset].tail == _prevId &&
				_NICR <= _troveManagerHelpers.getNominalICR(_asset, _prevId);
		} else {
			// `(_prevId, _nextId)` is a valid insert position if they are adjacent nodes and `_NICR` falls between the two nodes' NICRs
			return
				data[_asset].nodes[_prevId].nextId == _nextId &&
				_troveManagerHelpers.getNominalICR(_asset, _prevId) >= _NICR &&
				_NICR >= _troveManagerHelpers.getNominalICR(_asset, _nextId);
		}
	}

	/*
	 * @dev Descend the list (larger NICRs to smaller NICRs) to find a valid insert position
	 * @param _troveManager TroveManager contract, passed in as param to save SLOAD’s
	 * @param _NICR Node's NICR
	 * @param _startId Id of node to start descending the list from
	 */
	function _descendList(
		address _asset,
		ITroveManagerHelpers _troveManagerHelpers,
		uint256 _NICR,
		address _startId
	) internal view returns (address, address) {
		// If `_startId` is the head, check if the insert position is before the head
		if (
			data[_asset].head == _startId &&
			_NICR >= _troveManagerHelpers.getNominalICR(_asset, _startId)
		) {
			return (address(0), _startId);
		}

		address prevId = _startId;
		address nextId = data[_asset].nodes[prevId].nextId;

		// Descend the list until we reach the end or until we find a valid insert position
		while (
			prevId != address(0) &&
			!_validInsertPosition(_asset, _troveManagerHelpers, _NICR, prevId, nextId)
		) {
			prevId = data[_asset].nodes[prevId].nextId;
			nextId = data[_asset].nodes[prevId].nextId;
		}

		return (prevId, nextId);
	}

	/*
	 * @dev Ascend the list (smaller NICRs to larger NICRs) to find a valid insert position
	 * @param _troveManager TroveManager contract, passed in as param to save SLOAD’s
	 * @param _NICR Node's NICR
	 * @param _startId Id of node to start ascending the list from
	 */
	function _ascendList(
		address _asset,
		ITroveManagerHelpers _troveManagerHelpers,
		uint256 _NICR,
		address _startId
	) internal view returns (address, address) {
		// If `_startId` is the tail, check if the insert position is after the tail
		if (
			data[_asset].tail == _startId &&
			_NICR <= _troveManagerHelpers.getNominalICR(_asset, _startId)
		) {
			return (_startId, address(0));
		}

		address nextId = _startId;
		address prevId = data[_asset].nodes[nextId].prevId;

		// Ascend the list until we reach the end or until we find a valid insertion point
		while (
			nextId != address(0) &&
			!_validInsertPosition(_asset, _troveManagerHelpers, _NICR, prevId, nextId)
		) {
			nextId = data[_asset].nodes[nextId].prevId;
			prevId = data[_asset].nodes[nextId].prevId;
		}

		return (prevId, nextId);
	}

	/*
	 * @dev Find the insert position for a new node with the given NICR
	 * @param _NICR Node's NICR
	 * @param _prevId Id of previous node for the insert position
	 * @param _nextId Id of next node for the insert position
	 */
	function findInsertPosition(
		address _asset,
		uint256 _NICR,
		address _prevId,
		address _nextId
	) external view override returns (address, address) {
		return _findInsertPosition(_asset, troveManagerHelpers, _NICR, _prevId, _nextId);
	}

	function _findInsertPosition(
		address _asset,
		ITroveManagerHelpers _troveManagerHelpers,
		uint256 _NICR,
		address _prevId,
		address _nextId
	) internal view returns (address, address) {
		address prevId = _prevId;
		address nextId = _nextId;

		if (prevId != address(0)) {
			if (
				!contains(_asset, prevId) || _NICR > _troveManagerHelpers.getNominalICR(_asset, prevId)
			) {
				// `prevId` does not exist anymore or now has a smaller NICR than the given NICR
				prevId = address(0);
			}
		}

		if (nextId != address(0)) {
			if (
				!contains(_asset, nextId) || _NICR < _troveManagerHelpers.getNominalICR(_asset, nextId)
			) {
				// `nextId` does not exist anymore or now has a larger NICR than the given NICR
				nextId = address(0);
			}
		}

		if (prevId == address(0) && nextId == address(0)) {
			// No hint - descend list starting from head
			return _descendList(_asset, _troveManagerHelpers, _NICR, data[_asset].head);
		} else if (prevId == address(0)) {
			// No `prevId` for hint - ascend list starting from `nextId`
			return _ascendList(_asset, _troveManagerHelpers, _NICR, nextId);
		} else if (nextId == address(0)) {
			// No `nextId` for hint - descend list starting from `prevId`
			return _descendList(_asset, _troveManagerHelpers, _NICR, prevId);
		} else {
			// Descend list starting from `prevId`
			return _descendList(_asset, _troveManagerHelpers, _NICR, prevId);
		}
	}

	// --- 'require' functions ---
	// add access control

	function _requireCallerIsTroveManager() internal view {
		require(
			msg.sender == address(troveManager) || msg.sender == address(troveManagerHelpers),
			"SortedTroves: Caller is not the TroveManager"
		);
	}

	function _requireCallerIsBOorTroveM(
		ITroveManager _troveManager,
		ITroveManagerHelpers _troveManagerHelpers
	) internal view {
		require(
			msg.sender == borrowerOperationsAddress ||
				msg.sender == address(_troveManager) ||
				msg.sender == address(_troveManagerHelpers),
			"SortedTroves: Caller is neither BO nor TroveM"
		);
	}
}