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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =========================== CurveAMOv5 =============================
// ====================================================================
// Invests FRAX protocol funds into various Curve & Convex pools for protocol yield.
// New features from older Curve/Convex AMOs:
// Cover interaction with all following types of curve pools (deposit/withdraw/swap):
//   - Basepools and Metapools
//   - Stable pools and Crypto pools
//   - two tokens pools and 3-token pools
// Convex Vaults Interactions LP staking
// FXS Personal Vault interactions for LP Locking 
// Governance update (Owner / Operator)
// Accounting update (multi token based accounting / FRAX + USDC based accounting)

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Amirnader Aghayeghazvini: https://github.com/amirnader-ghazvini

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna
// Sam Kazemian: https://github.com/samkazemian
// Dennis: https://github.com/denett

import "./interfaces/curve/IMinCurvePool.sol";
import "./interfaces/convex/IConvexBooster.sol";
import "./interfaces/convex/IConvexBaseRewardPool.sol";
import "./interfaces/convex/IVirtualBalanceRewardPool.sol";
import "./interfaces/convex/IConvexClaimZap.sol";
import "./interfaces/convex/IcvxRewardPool.sol";
import "./interfaces/convex/IBooster.sol";
import "./interfaces/convex/IFxsPersonalVault.sol";
import "./interfaces/ICurveAMOv5Helper.sol";
import "./interfaces/IFrax.sol";
import "./interfaces/IFraxAMOMinter.sol";
import './Uniswap/TransferHelper.sol';
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract CurveAMOv5 is Ownable {
    // SafeMath automatically included in Solidity >= 8.0.0

    /* ============================================= STATE VARIABLES ==================================================== */
    
    // Addresses Config
    address public operatorAddress;
    IFraxAMOMinter private amoMinter;
    ICurveAMOv5Helper private amoHelper;

    // Constants (ERC20)
    IFrax private constant FRAX = IFrax(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    ERC20 private constant USDC = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    ERC20 private constant cvx = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    
    // Curve pools 
    address[] public poolArray;
    struct CurvePool { 
        // General pool parameters
        bool isCryptoPool;
        bool isMetaPool;
        uint coinCount;
        bool hasFrax;
        uint fraxIndex;
        bool hasUsdc;
        uint usdcIndex;
        uint baseTokenIndex;

        // Pool Addresses
        address poolAddress; // Where the actual tokens are in the pool
        address lpTokenAddress; // The LP token address. Sometimes the same as poolAddress

        // Convex Related
        bool hasVault;
        uint256 lpDepositPid;
        address rewardsContractAddress;
        bool hasFxsVault;
        address fxsPersonalVaultAddress;

        // Accounting Parameters
        uint256[] tokenDeposited;
        uint256[] tokenMaxAllocation;
        uint256[] tokenProfitTaken;
        uint256 lpDepositedAsCollateral;
    }
    mapping(address => bool) public poolInitialized;
    mapping(address => CurvePool) private poolInfo;
    mapping(address => address) public lpTokenToPool;
    
    // FXS Personal Vault
    mapping(address => bytes32[]) public vaultKekIds;
    mapping(bytes32 => uint256) public kekIdTotalDeposit;

    // Addresses
    address private constant cvxCrvAddress = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    address private constant crvAddress = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address private constant fxsAddress = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    
    // Convex-related
    IConvexBooster private constant convexBooster = IConvexBooster(0xF403C135812408BFbE8713b5A23a04b3D48AAE31);
    IConvexClaimZap private constant convex_claim_zap = IConvexClaimZap(0x4890970BB23FCdF624A0557845A29366033e6Fa2);
    IBooster private constant convexFXSBooster = IBooster(0x569f5B842B5006eC17Be02B8b94510BA8e79FbCa);
    IcvxRewardPool private constant cvx_reward_pool = IcvxRewardPool(0xCF50b810E57Ac33B91dCF525C6ddd9881B139332);
    
    // Parameters
    // Number of decimals under 18, for collateral token
    uint256 private missingDecimals;

    // Discount
    bool public setDiscount;
    uint256 public discountRate;

    /* =============================================== CONSTRUCTOR ====================================================== */

    /// @notice constructor
    /// @param _amoMinterAddress AMO minter address
    /// @param _operatorAddress Address of CurveAMO Operator
    /// @param _amoHelperAddress Address of Curve AMO Helper contract
    constructor (
        address _amoMinterAddress,
        address _operatorAddress,
        address _amoHelperAddress
    ) Ownable() {
        amoMinter = IFraxAMOMinter(_amoMinterAddress);

        operatorAddress = _operatorAddress;

        amoHelper = ICurveAMOv5Helper(_amoHelperAddress);

        missingDecimals = 12;

        // Other variable initializations
        setDiscount = false;

        emit StartAMO(_amoMinterAddress, _operatorAddress, _amoHelperAddress);
    }

    /* ================================================ MODIFIERS ======================================================= */

    modifier onlyByOwnerOperator() {
        require(msg.sender == operatorAddress || msg.sender == owner(), "Not owner or operator");
        _;
    }

    modifier onlyByMinter() {
        require(msg.sender == address(amoMinter), "Not minter");
        _;
    }

    modifier approvedPool(address _poolAddress) {
        require(poolInitialized[_poolAddress], "Pool not approved");
        _;
    }

    modifier onBudget(address _poolAddress) {
        _;
        for(uint256 i = 0; i < poolInfo[_poolAddress].coinCount; i++){
            require(
                poolInfo[_poolAddress].tokenMaxAllocation[i] >= poolInfo[_poolAddress].tokenDeposited[i], 
                "Over token budget"
            );
        }
        
    }

    modifier hasVault(address _poolAddress) {
        require(poolInfo[_poolAddress].hasVault, "Pool has no vault");
        _;
    }

    modifier hasFxsVault(address _poolAddress) {
        require(poolInfo[_poolAddress].hasFxsVault, "Pool has no FXS vault");
        _;
    }

    /* ================================================= EVENTS ========================================================= */

    /// @notice The ```StartAMO``` event fires when the AMO deploys
    /// @param _amoMinterAddress AMO minter address
    /// @param _operatorAddress Address of operator
    /// @param _amoHelperAddress Address of Curve AMO Helper contract
    event StartAMO(address _amoMinterAddress, address _operatorAddress, address _amoHelperAddress); 

    /// @notice The ```SetOperator``` event fires when the operatorAddress is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetOperator(address _oldAddress, address _newAddress); 

    /// @notice The ```SetAMOHelper``` event fires when the AMO Helper is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetAMOHelper(address _oldAddress, address _newAddress); 

    /// @notice The ```SetAMOMinter``` event fires when the AMO Minter is set
    /// @param _oldAddress The original address
    /// @param _newAddress The new address
    event SetAMOMinter(address _oldAddress, address _newAddress);

    /// @notice The ```AddOrSetPool``` event fires when a pool is added to AMO
    /// @param _poolAddress The pool address
    /// @param _maxAllocations Max allowed allocation of AMO into the pair 
    event AddOrSetPool(address _poolAddress, uint256[] _maxAllocations);

    /// @notice The ```DepositToPool``` event fires when a deposit happens to a pair
    /// @param _poolAddress The pool address
    /// @param _amounts Deposited amounts
    /// @param _minLp Min recieved LP amount
    event DepositToPool(address _poolAddress, uint256[] _amounts, uint256 _minLp);

    /// @notice The ```WithdrawFromPool``` event fires when a withdrawal happens from a pool
    /// @param _poolAddress The pool address
    /// @param _minAmounts Min withdrawal amounts
    /// @param _lp Deposited LP amount
    event WithdrawFromPool(address _poolAddress, uint256[] _minAmounts, uint256 _lp);

    /// @param _poolAddress Address of Curve Pool
    /// @param _inIndex Curve Pool input coin index
    /// @param _outIndex Curve Pool output coin index
    /// @param _inAmount Amount of input coin
    /// @param _minOutAmount Min amount of output coin
    event Swap(address _poolAddress, uint256 _inIndex, uint256 _outIndex, uint256 _inAmount, uint256 _minOutAmount);

    /// @notice The ```DepositToVault``` event fires when a deposit happens to a pair
    /// @param _poolAddress The pool address
    /// @param _lp Deposited LP amount
    event DepositToVault(address _poolAddress, uint256 _lp);

    /// @notice The ```WithdrawFromVault``` event fires when a withdrawal happens from a pool
    /// @param _poolAddress The pool address
    /// @param _lp Withdrawn LP amount
    event WithdrawFromVault(address _poolAddress, uint256 _lp);



    /* ================================================== VIEWS ========================================================= */
    
    /// @notice Show allocations of CurveAMO in FRAX and USDC
    /// @return allocations [Free FRAX in AMO, Free USDC in AMO, Total FRAX Minted into Pools, Total USDC deposited into Pools, Total withdrawable Frax directly from pools, Total withdrawable USDC directly from pool, Total withdrawable Frax from pool and basepool LP, Total withdrawable USDC from pool and basepool LP, Total Frax, Total USDC]
    function showAllocations() public view returns (uint256[10] memory ) {
        return amoHelper.showAllocations(address(this), poolArray.length);
    }

    /// @notice Total FRAX balance
    /// @return fraxValE18 FRAX value
    /// @return collatValE18 FRAX collateral value
    function dollarBalances() external view returns (uint256 fraxValE18, uint256 collatValE18) {
        // Get the allocations
        uint256[10] memory allocations = showAllocations();

        fraxValE18 = (allocations[8]) + ((allocations[9]) * ((10 ** missingDecimals)));
        collatValE18 = ((allocations[8] * fraxDiscountRate())/ 1e6) + ((allocations[9]) * ((10 ** missingDecimals)));
    }

    /// @notice Show all rewards of CurveAMO
    /// @param _poolAddress Address of Curve Pool
    /// @return _crvReward Pool CRV rewards
    /// @return _extraRewardAmounts [CRV claimable, CVX claimable, cvxCRV claimable]
    /// @return _extraRewardTokens [Token Address]
    function showPoolRewards(address _poolAddress) external view returns (uint256 _crvReward, uint256[] memory _extraRewardAmounts, address[] memory _extraRewardTokens) {
        IConvexBaseRewardPool _convexBaseRewardPool = IConvexBaseRewardPool(poolInfo[_poolAddress].rewardsContractAddress);
        _crvReward = _convexBaseRewardPool.earned(address(this)); // CRV claimable
        
        uint256 _extraRewardsLength = _convexBaseRewardPool.extraRewardsLength();
        for (uint i = 0; i < _extraRewardsLength; i++) {   
            IVirtualBalanceRewardPool _convexExtraRewardsPool = IVirtualBalanceRewardPool(_convexBaseRewardPool.extraRewards(i));
            _extraRewardAmounts[i] = _convexExtraRewardsPool.earned(address(this));
            _extraRewardTokens[i] = _convexExtraRewardsPool.rewardToken();
        }
    }

    /// @notice Show all cvx rewards
    /// @return _cvxReward
    function showCVXRewards() external view returns (uint256 _cvxReward) {
        _cvxReward = cvx_reward_pool.earned(address(this)); // cvxCRV claimable
    }
    
    /// @notice Show lp tokens deposited in Convex vault
    /// @param _poolAddress Address of Curve Pool
    /// @return lp Tokens deposited in the Convex vault
    function lpInVault(address _poolAddress) public view returns (uint256) {
        uint256 _lpInVault = 0;
        if(poolInfo[_poolAddress].hasVault){
            IConvexBaseRewardPool _convexBaseRewardPool = IConvexBaseRewardPool(poolInfo[_poolAddress].rewardsContractAddress);
            _lpInVault += _convexBaseRewardPool.balanceOf(address(this));
       }
       if(poolInfo[_poolAddress].hasFxsVault){
            for (uint256 i = 0; i < vaultKekIds[_poolAddress].length; i++) {
                _lpInVault += kekIdTotalDeposit[vaultKekIds[_poolAddress][i]];
            }
       }
       return _lpInVault;
    }

    /// @notice Get the balances of the underlying tokens for the given amount of LP, 
    /// @notice assuming you withdraw at the current ratio.
    /// @notice May not necessarily = balanceOf(<underlying token address>) due to accumulated fees
    /// @param _poolAddress Address of Curve Pool
    /// @param _lpAmount LP Amount
    /// @return _withdrawables Amount of each token expected
    function getTknsForLPAtCurrRatio(address _poolAddress, uint256 _lpAmount) 
        public view 
        returns (uint256[] memory _withdrawables) 
    {
        CurvePool memory _poolInfo = poolInfo[_poolAddress];
        _withdrawables = amoHelper.getTknsForLPAtCurrRatio(address(this), _poolAddress, _poolInfo.lpTokenAddress, _lpAmount);
    }
    
    /// @notice Calculate recieving amount of FRAX and USDC after withdrawal  
    /// @notice Ignores other tokens that may be present in the LP (e.g. DAI, USDT, SUSD, CRV)
    /// @notice This can cause bonuses/penalties for withdrawing one coin depending on the balance of said coin.
    /// @param _poolAddress Address of Curve Pool
    /// @param _lpAmount LP Amount for withdraw
    /// @return _withdrawables [Total withdrawable Frax directly from pool, Total withdrawable USDC directly from pool, Total withdrawable Frax from pool and basepool lp, Total withdrawable USDC from pool and basepool lp] 
    function calcFraxAndUsdcWithdrawable(address _poolAddress, uint256 _lpAmount) 
        public view 
        returns (uint256[4] memory) 
    {   
        CurvePool memory _poolInfo = poolInfo[_poolAddress];
        return amoHelper.calcFraxAndUsdcWithdrawable(address(this), _poolAddress, _poolInfo.lpTokenAddress, _lpAmount);
    }
    
    /// @notice Calculate expected token amounts if this AMO fully withdraws/exits from the indicated LP
    /// @param _poolAddress Address of Curve Pool
    /// @return _withdrawables Recieving amount of each token after full withdrawal based on current pool ratio 
    function calcAllTknsFromFullLPExit(address _poolAddress) 
        public view 
        returns (uint256[] memory _withdrawables) 
    {
        uint256 _oneStepBurningLp = amoHelper.showOneStepBurningLp(address(this), _poolAddress);
        _withdrawables = getTknsForLPAtCurrRatio(_poolAddress, _oneStepBurningLp);
    }

    /// @notice Calculate expected FRAX and USDC amounts if this AMO fully withdraws/exits from the indicated LP
    /// @notice NOT the same as calcAllTknsFromFullLPExit because you are ignoring / not withdrawing other tokens (e.g. DAI, USDT, SUSD, CRV)
    /// @notice So you have to use calc_withdraw_one_coin and more calculations
    /// @param _poolAddress Address of Curve Pool
    /// @return _withdrawables Total withdrawable Frax directly from pool, Total withdrawable USDC directly from pool, Total withdrawable Frax from pool and basepool lp, Total withdrawable USDC from pool and basepool lp] 
    function calcFraxUsdcOnlyFromFullLPExit(address _poolAddress) 
        public view 
        returns (uint256[4] memory _withdrawables) 
    {
        uint256 _oneStepBurningLp = amoHelper.showOneStepBurningLp(address(this), _poolAddress);
        _withdrawables = calcFraxAndUsdcWithdrawable(_poolAddress, _oneStepBurningLp);
    }

    /// @notice Show allocations of CurveAMO into Curve Pool
    /// @param _poolAddress Address of Curve Pool
    /// @return _assetBalances Pool coins current AMO balances
    function showPoolAssetBalances(address _poolAddress) 
        public view 
        returns (
            uint256[] memory _assetBalances
        ) 
    {
        _assetBalances = amoHelper.showPoolAssetBalances(address(this), _poolAddress);
    }
    
    /// @notice Show allocations of CurveAMO into Curve Pool
    /// @param _poolAddress Address of Curve Pool
    /// @return _assetBalances Pool coins current AMO balances
    /// @return _depositedAmounts Pool coins deposited into pool
    /// @return _profitTakenAmounts Pool coins profit taken from pool
    /// @return _allocations [Current LP balance, LP deposited in metapools, LP deposited in vault]
    function showPoolAccounting(address _poolAddress) 
        public view 
        returns (
            uint256[] memory _assetBalances,
            uint256[] memory _depositedAmounts,
            uint256[] memory _profitTakenAmounts,
            uint256[3] memory _allocations
        ) 
    {
        _assetBalances = showPoolAssetBalances(_poolAddress);
        _depositedAmounts = poolInfo[_poolAddress].tokenDeposited;
        _profitTakenAmounts = poolInfo[_poolAddress].tokenProfitTaken;
        
        ERC20 _lpToken = ERC20(poolInfo[_poolAddress].lpTokenAddress); 
        _allocations[0] = _lpToken.balanceOf(address(this)); // Current LP balance
        
        _allocations[1] = poolInfo[_poolAddress].lpDepositedAsCollateral; // LP deposited in metapools

        _allocations[2] = lpInVault(_poolAddress); // LP deposited in vault
    }

    /// @notice Show FRAX discount rate
    /// @return FRAX discount rate
    function fraxDiscountRate() public view returns (uint256) {
        if(setDiscount){
            return discountRate;
        } else {
            return FRAX.global_collateral_ratio();
        }
    }
    
    /// @notice Backwards compatibility
    /// @return FRAX minted balance of the FraxlendAMO
    function mintedBalance() public view returns (int256) {
        return amoMinter.frax_mint_balances(address(this));
    }

    /// @notice Show Curve Pool parameters
    /// @param _poolAddress Address of Curve Pool
    /// @return _isMetapool
    /// @return _isCrypto
    /// @return _hasFrax
    /// @return _hasVault
    /// @return _hasUsdc
    function showPoolInfo(address _poolAddress) external view returns (bool _isMetapool, bool _isCrypto, bool _hasFrax, bool _hasVault, bool _hasUsdc) {
        _hasVault = poolInfo[_poolAddress].hasVault;
        _isMetapool = poolInfo[_poolAddress].isMetaPool;
        _isCrypto = poolInfo[_poolAddress].isCryptoPool;
        _hasFrax = poolInfo[_poolAddress].hasFrax;
        _hasUsdc = poolInfo[_poolAddress].hasUsdc;
    }

    /// @notice Show Curve Pool parameters regading coins
    /// @param _poolAddress Address of Curve Pool
    /// @return _coinCount
    /// @return _fraxIndex
    /// @return _usdcIndex
    /// @return _baseTokenIndex
    function showPoolCoinIndexes(address _poolAddress) external view returns (uint256 _coinCount, uint256 _fraxIndex, uint256 _usdcIndex, uint256 _baseTokenIndex) {
        _coinCount = poolInfo[_poolAddress].coinCount;
        _fraxIndex = poolInfo[_poolAddress].fraxIndex;
        _usdcIndex = poolInfo[_poolAddress].usdcIndex;
        _baseTokenIndex = poolInfo[_poolAddress].baseTokenIndex;
    }

    /// @notice Show Pool coins max allocations for AMO
    /// @param _poolAddress Address of Curve Pool
    /// @return _tokenMaxAllocation
    function showPoolMaxAllocations(address _poolAddress) external view returns (uint256[] memory _tokenMaxAllocation) {
        _tokenMaxAllocation = poolInfo[_poolAddress].tokenMaxAllocation;
    }

    /// @notice Show Curve Pool parameters regading vaults
    /// @param _poolAddress Address of Curve Pool
    /// @return _lpDepositPid
    /// @return _rewardsContractAddress
    /// @return _fxsPersonalVaultAddress
    function showPoolVaults(address _poolAddress) external view returns (uint256 _lpDepositPid, address _rewardsContractAddress, address _fxsPersonalVaultAddress) {
        _lpDepositPid = poolInfo[_poolAddress].lpDepositPid;
        _rewardsContractAddress = poolInfo[_poolAddress].rewardsContractAddress;
        _fxsPersonalVaultAddress = poolInfo[_poolAddress].fxsPersonalVaultAddress;
    }

    /* ============================================== POOL FUNCTIONS ==================================================== */

    /// @notice Function to deposit tokens to specific Curve Pool 
    /// @param _poolAddress Address of Curve Pool
    /// @param _amounts Amount of Pool coins to be deposited
    /// @param _minLpOut Min LP out after deposit
    function depositToPool(address _poolAddress, uint256[] memory _amounts, uint256 _minLpOut) 
        external         
        approvedPool(_poolAddress)
        onBudget(_poolAddress)
        onlyByOwnerOperator 
    {
        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        for (uint i = 0; i < poolInfo[_poolAddress].coinCount; i++) {
            ERC20 _token = ERC20(pool.coins(i));
            if(_amounts[i] > 0){
                _token.approve(_poolAddress, 0); // For USDT and others
                _token.approve(_poolAddress, _amounts[i]);
                poolInfo[_poolAddress].tokenDeposited[i] += _amounts[i];
                if (poolInfo[_poolAddress].isMetaPool && poolInfo[_poolAddress].baseTokenIndex == i) {
                    address _basePoolAddress = lpTokenToPool[address(_token)];
                    poolInfo[_basePoolAddress].lpDepositedAsCollateral += _amounts[i];
                }
            }
        }
        if (poolInfo[_poolAddress].coinCount == 3){
            uint256[3] memory __amounts;
            __amounts[0] = _amounts[0];
            __amounts[1] = _amounts[1];
            __amounts[2] = _amounts[2];
            pool.add_liquidity(__amounts, _minLpOut);
        } else {
            uint256[2] memory __amounts;
            __amounts[0] = _amounts[0];
            __amounts[1] = _amounts[1];
            pool.add_liquidity(__amounts, _minLpOut);
        }

        emit DepositToPool(_poolAddress, _amounts, _minLpOut);
    }
    
    /// @notice Function to withdraw one token from specific Curve Pool 
    /// @param _poolAddress Address of Curve Pool
    /// @param _lpIn Amount of LP token
    /// @param _coinIndex Curve Pool target coin index
    /// @param _minAmountOut Min amount of target coin out
    function withdrawOneCoin(address _poolAddress, uint256 _lpIn, uint256 _coinIndex, uint256 _minAmountOut) 
        external 
        approvedPool(_poolAddress)
        onlyByOwnerOperator 
        returns (uint256 _amountReceived)
    {
        uint256[] memory _minAmounts = new uint256[](poolInfo[_poolAddress].coinCount);
        _minAmounts[_coinIndex] = _minAmountOut;

        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        ERC20 lpToken = ERC20(poolInfo[_poolAddress].lpTokenAddress);
        lpToken.approve(_poolAddress, 0);
        lpToken.approve(_poolAddress, _lpIn);
        
        ERC20 _token = ERC20(pool.coins(_coinIndex));
        uint256 _balance0 = _token.balanceOf(address(this));
        if(poolInfo[_poolAddress].isCryptoPool) {
            // _amountReceived = pool.remove_liquidity_one_coin(_lpIn, _coinIndex, _minAmountOut);
            pool.remove_liquidity_one_coin(_lpIn, _coinIndex, _minAmountOut);
        } else {
            int128 _index = int128(uint128(_coinIndex));
            // _amountReceived = pool.remove_liquidity_one_coin(_lpIn, _index, _minAmountOut);
            pool.remove_liquidity_one_coin(_lpIn, _index, _minAmountOut);
        }
        uint256 _balance1 = _token.balanceOf(address(this));
        _amountReceived =  _balance1 - _balance0;
        withdrawAccounting(_poolAddress, _amountReceived, _coinIndex);

        emit WithdrawFromPool(_poolAddress, _minAmounts, _lpIn);

        return _amountReceived;
    }

    /// @notice Function to withdraw tokens from specific Curve Pool based on current pool ratio
    /// @param _poolAddress Address of Curve Pool
    /// @param _lpIn Amount of LP token
    /// @param _minAmounts Min amounts of coin out
    function withdrawAtCurrRatio(address _poolAddress, uint256 _lpIn, uint256[] memory _minAmounts) 
        public
        approvedPool(_poolAddress) 
        onlyByOwnerOperator  
        returns (uint256[] memory _amountReceived)
    {
        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        ERC20 lpToken = ERC20(poolInfo[_poolAddress].lpTokenAddress);
        lpToken.approve(_poolAddress, 0);
        lpToken.approve(_poolAddress, _lpIn);
        
        uint256[] memory _assetBalances0 = showPoolAssetBalances(_poolAddress);
        if (poolInfo[_poolAddress].coinCount == 3){
            uint256[3] memory __minAmounts;
            __minAmounts[0] = _minAmounts[0];
            __minAmounts[1] = _minAmounts[1];
            __minAmounts[2] = _minAmounts[2];
            pool.remove_liquidity(_lpIn, __minAmounts);
            _amountReceived = new uint256[](3);
        } else {
            uint256[2] memory __minAmounts;
            __minAmounts[0] = _minAmounts[0];
            __minAmounts[1] = _minAmounts[1];
            pool.remove_liquidity(_lpIn, __minAmounts);
            _amountReceived = new uint256[](2);
        }
        uint256[] memory _assetBalances1 = showPoolAssetBalances(_poolAddress);
        for (uint i = 0; i < poolInfo[_poolAddress].coinCount; i++) {
            _amountReceived[i] = _assetBalances1[i] - _assetBalances0[i];
            withdrawAccounting(_poolAddress, _amountReceived[i], i);
        }

        emit WithdrawFromPool(_poolAddress, _minAmounts, _lpIn);
    }
    
    // @notice Function to perform accounting calculations for withdrawal
    /// @param _poolAddress Address of Curve Pool
    /// @param _amountReceived Coin recieved from withdrawal 
    /// @param _coinIndex Curve Pool target coin index
    function withdrawAccounting(address _poolAddress, uint256 _amountReceived, uint256 _coinIndex) internal {
        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        if (_amountReceived < poolInfo[_poolAddress].tokenDeposited[_coinIndex]) {
            poolInfo[_poolAddress].tokenDeposited[_coinIndex] -= _amountReceived;
        } else {
            poolInfo[_poolAddress].tokenProfitTaken[_coinIndex] += _amountReceived - poolInfo[_poolAddress].tokenDeposited[_coinIndex];
            poolInfo[_poolAddress].tokenDeposited[_coinIndex] = 0;
        }
        if (poolInfo[_poolAddress].isMetaPool && poolInfo[_poolAddress].baseTokenIndex == _coinIndex) {
            address _basePoolAddress = lpTokenToPool[pool.coins(_coinIndex)];
            if (poolInfo[_basePoolAddress].lpDepositedAsCollateral > _amountReceived){
                poolInfo[_basePoolAddress].lpDepositedAsCollateral -= _amountReceived;
            } else {
                poolInfo[_basePoolAddress].lpDepositedAsCollateral = 0;
            }
        }
    }
    // @notice Function to withdraw all tokens from specific Curve Pool based on current pool ratio
    /// @param _poolAddress Address of Curve Pool
    /// @param _minAmounts Min amounts of coin out
    function withdrawAllAtCurrRatio(address _poolAddress, uint256[] memory _minAmounts) 
        public
        approvedPool(_poolAddress) 
        onlyByOwnerOperator 
        returns (uint256[] memory _amountReceived) 
    {
        // Limitation : This function is not working for Crypto pools
        ERC20 lpToken = ERC20(poolInfo[_poolAddress].lpTokenAddress);
        uint256 _allLP = lpToken.balanceOf(address(this));
        _amountReceived = withdrawAtCurrRatio(_poolAddress, _allLP, _minAmounts);
    }

    // @notice Function to use Curve Pool to swap two tokens
    /// @param _poolAddress Address of Curve Pool
    /// @param _inIndex Curve Pool input coin index
    /// @param _outIndex Curve Pool output coin index
    /// @param _inAmount Amount of input coin
    /// @param _minOutAmount Min amount of output coin
    function poolSwap(address _poolAddress, uint256 _inIndex, uint256 _outIndex, uint256 _inAmount, uint256 _minOutAmount) 
        public
        approvedPool(_poolAddress) 
        onlyByOwnerOperator 
    {
        IMinCurvePool pool = IMinCurvePool(_poolAddress);
        ERC20 _token = ERC20(pool.coins(_inIndex));
        _token.approve(_poolAddress, 0); // For USDT and others
        _token.approve(_poolAddress, _inAmount);
        if(poolInfo[_poolAddress].isCryptoPool) {
            pool.exchange(_inIndex, _outIndex, _inAmount, _minOutAmount);
        } else {
            int128 __inIndex = int128(uint128(_inIndex));
            int128 __outIndex = int128(uint128(_outIndex));
            pool.exchange(__inIndex, __outIndex, _inAmount, _minOutAmount);
        }

        emit Swap(_poolAddress, _inIndex, _outIndex, _inAmount, _minOutAmount);
    }

    /* ============================================ BURNS AND GIVEBACKS ================================================= */

    /// @notice Return USDC back to minter
    /// @param _collateralAmount USDC amount
    function giveCollatBack(uint256 _collateralAmount) external onlyOwner {
        USDC.approve(address(amoMinter), _collateralAmount);
        amoMinter.receiveCollatFromAMO(_collateralAmount);
    }
   
    /// @notice Burn unneeded or excess FRAX. Goes through the minter
    /// @param _fraxAmount Amount of FRAX to burn
    function burnFRAX(uint256 _fraxAmount) external onlyOwner {
        FRAX.approve(address(amoMinter), _fraxAmount);
        amoMinter.burnFraxFromAMO(_fraxAmount);
    }

    
    /* ============================================== VAULT FUNCTIONS =================================================== */

    /// @notice Deposit Pool LP tokens, convert them to Convex LP, and deposit into their vault
    /// @param _poolAddress Address of Curve Pool
    /// @param _poolLpIn Amount of LP for deposit
    function depositToVault(address _poolAddress, uint256 _poolLpIn) 
        external 
        onlyByOwnerOperator 
        approvedPool(_poolAddress) 
        hasVault(_poolAddress)
    {
        // Approve the isMetaPool LP tokens for the vault contract
        ERC20 _poolLpToken = ERC20(poolInfo[_poolAddress].lpTokenAddress);
        _poolLpToken.approve(address(convexBooster), _poolLpIn);
        
        // Deposit the isMetaPool LP into the vault contract
        convexBooster.deposit(poolInfo[_poolAddress].lpDepositPid, _poolLpIn, true);

        emit DepositToVault(_poolAddress, _poolLpIn);
    }

    /// @notice Withdraw Convex LP, convert it back to Pool LP tokens, and give them back to the sender
    /// @param _poolAddress Address of Curve Pool
    /// @param amount Amount of LP for withdraw
    /// @param claim if claim rewards or not
    function withdrawAndUnwrapFromVault(address _poolAddress, uint256 amount, bool claim) 
        external 
        onlyByOwnerOperator
        approvedPool(_poolAddress) 
        hasVault(_poolAddress)
    {
        IConvexBaseRewardPool _convexBaseRewardPool = IConvexBaseRewardPool(poolInfo[_poolAddress].rewardsContractAddress);
        _convexBaseRewardPool.withdrawAndUnwrap(amount, claim);

        emit WithdrawFromVault(_poolAddress, amount);
    }

    /// @notice Withdraw rewards
    /// @param crvAmount CRV Amount to withdraw
    /// @param cvxAmount CVX Amount to withdraw
    /// @param cvxCRVAmount cvxCRV Amount to withdraw
    /// @param fxsAmount FXS Amount to withdraw
    function withdrawRewards(
        uint256 crvAmount,
        uint256 cvxAmount,
        uint256 cvxCRVAmount,
        uint256 fxsAmount
    ) external onlyByOwnerOperator {
        if (crvAmount > 0) TransferHelper.safeTransfer(crvAddress, owner(), crvAmount);
        if (cvxAmount > 0) TransferHelper.safeTransfer(address(cvx), owner(), cvxAmount);
        if (cvxCRVAmount > 0) TransferHelper.safeTransfer(cvxCrvAddress, owner(), cvxCRVAmount);
        if (fxsAmount > 0) TransferHelper.safeTransfer(fxsAddress, owner(), fxsAmount);
    }

    /// @notice Deposit Pool LP tokens, convert them to Convex LP, and deposit into their vault
    /// @param _poolAddress Address of Curve Pool
    /// @param _poolLpIn Amount of LP for deposit
    /// @param _secs Lock time in sec
    /// @return _kek_id lock stake ID
    function depositToFxsVault(address _poolAddress, uint256 _poolLpIn, uint256 _secs) 
        external 
        onlyByOwnerOperator 
        approvedPool(_poolAddress) 
        hasFxsVault(_poolAddress)
        returns (bytes32 _kek_id)
    {
        // Approve the LP tokens for the vault contract
        ERC20 _poolLpToken = ERC20(poolInfo[_poolAddress].lpTokenAddress);
        _poolLpToken.approve(poolInfo[_poolAddress].fxsPersonalVaultAddress, _poolLpIn);
        
        // Deposit the LP into the fxs vault contract
        IFxsPersonalVault fxsVault = IFxsPersonalVault(poolInfo[_poolAddress].fxsPersonalVaultAddress);
        _kek_id = fxsVault.stakeLockedCurveLp(_poolLpIn, _secs);
        vaultKekIds[_poolAddress].push(_kek_id);
        kekIdTotalDeposit[_kek_id] = _poolLpIn;
    }

    /// @notice Increase lock time
    /// @param _poolAddress Address of Curve Pool
    /// @param _kek_id lock stake ID
    /// @param new_ending_ts new ending timestamp 
    function lockLongerInFxsVault (address _poolAddress, bytes32 _kek_id, uint256 new_ending_ts ) 
        external 
        onlyByOwnerOperator 
        approvedPool(_poolAddress) 
        hasFxsVault(_poolAddress)
    {
        IFxsPersonalVault fxsVault = IFxsPersonalVault(poolInfo[_poolAddress].fxsPersonalVaultAddress);
        fxsVault.lockLonger(_kek_id, new_ending_ts);
    }

    /// @notice Increase locked LP amount
    /// @param _poolAddress Address of Curve Pool
    /// @param _kek_id lock stake ID
    /// @param _addl_liq Amount of LP for deposit
    function lockMoreInFxsVault (address _poolAddress, bytes32 _kek_id, uint256 _addl_liq ) 
        external 
        onlyByOwnerOperator 
        approvedPool(_poolAddress) 
        hasFxsVault(_poolAddress)
    {
        kekIdTotalDeposit[_kek_id] += _addl_liq;
        // Approve the LP tokens for the vault contract
        ERC20 _poolLpToken = ERC20(poolInfo[_poolAddress].lpTokenAddress);
        _poolLpToken.approve(poolInfo[_poolAddress].fxsPersonalVaultAddress, _addl_liq);

        IFxsPersonalVault fxsVault = IFxsPersonalVault(poolInfo[_poolAddress].fxsPersonalVaultAddress);
        fxsVault.lockAdditionalCurveLp(_kek_id, _addl_liq);
    }

    /// @notice Withdraw Convex LP, convert it back to Pool LP tokens, and give them back to the sender
    /// @param _poolAddress Address of Curve Pool
    /// @param _kek_id lock stake ID
    function withdrawAndUnwrapFromFxsVault(address _poolAddress, bytes32 _kek_id) 
        external 
        onlyByOwnerOperator
        approvedPool(_poolAddress) 
        hasFxsVault(_poolAddress)
    {
        kekIdTotalDeposit[_kek_id] = 0;
        IFxsPersonalVault fxsVault = IFxsPersonalVault(poolInfo[_poolAddress].fxsPersonalVaultAddress);
        fxsVault.withdrawLockedAndUnwrap(_kek_id);
    }

    /// @notice Claim CVX, CRV, and FXS rewards
    /// @param _poolAddress Address of Curve Pool
    /// @param _claimConvexVault Claim convex vault rewards
    /// @param _claimFxsVault Claim FXS personal vault rewards
    function claimRewards(address _poolAddress, bool _claimConvexVault, bool _claimFxsVault) 
        external 
        onlyByOwnerOperator
        approvedPool(_poolAddress) 
    {
        if (_claimConvexVault) {
            address[] memory rewardContracts = new address[](1);
            rewardContracts[0] = poolInfo[_poolAddress].rewardsContractAddress;
            uint256[] memory chefIds = new uint256[](0);

            convex_claim_zap.claimRewards(
                rewardContracts, 
                chefIds, 
                false, 
                false, 
                false, 
                0, 
                0
            );
        }
        if (_claimFxsVault) {
            if(poolInfo[_poolAddress].hasFxsVault){
                IFxsPersonalVault fxsVault = IFxsPersonalVault(poolInfo[_poolAddress].fxsPersonalVaultAddress);
                fxsVault.getReward();
            }
        }
        
    }

    /* ====================================== RESTRICTED GOVERNANCE FUNCTIONS =========================================== */

    /// @notice Add new Curve Pool
    /// @param _configData config data for a new pool
    /// @param _poolAddress Address of Curve Pool
    function addOrSetPool(
        bytes memory _configData,
        address _poolAddress
    ) external onlyOwner {
        (   bool _isCryptoPool,
            bool _hasFrax,
            bool _hasUsdc,
            bool _isMetaPool,
            uint _coinCount,
            uint _fraxIndex,
            uint _usdcIndex,
            uint _baseTokenIndex,
            address _lpTokenAddress
        ) = abi.decode(_configData, (bool, bool, bool, bool, uint, uint, uint, uint, address));
        if (poolInitialized[_poolAddress]){
            poolInfo[_poolAddress].isCryptoPool = _isCryptoPool;
            poolInfo[_poolAddress].hasFrax = _hasFrax;
            poolInfo[_poolAddress].hasUsdc = _hasUsdc;
            poolInfo[_poolAddress].isMetaPool = _isMetaPool;
            poolInfo[_poolAddress].coinCount = _coinCount;
            poolInfo[_poolAddress].fraxIndex = _fraxIndex;
            poolInfo[_poolAddress].usdcIndex = _usdcIndex;
            poolInfo[_poolAddress].baseTokenIndex = _baseTokenIndex;
            poolInfo[_poolAddress].lpTokenAddress = _lpTokenAddress;
        } else {
            poolInitialized[_poolAddress] = true;
            poolArray.push(_poolAddress);
            poolInfo[_poolAddress] = CurvePool({
                isCryptoPool: _isCryptoPool,
                hasFrax: _hasFrax,
                hasUsdc: _hasUsdc,
                isMetaPool: _isMetaPool,
                hasVault: false,
                coinCount: _coinCount,
                fraxIndex: _fraxIndex,
                usdcIndex: _usdcIndex,
                // Pool Addresses
                poolAddress: _poolAddress,
                lpTokenAddress: _lpTokenAddress,
                // Convex Vault Addresses
                lpDepositPid: 0,
                rewardsContractAddress: address(0),
                hasFxsVault: false, 
                fxsPersonalVaultAddress: address(0),
                // Accounting params
                baseTokenIndex: _baseTokenIndex,
                tokenDeposited: new uint256[](_coinCount),
                tokenMaxAllocation: new uint256[](_coinCount),
                tokenProfitTaken: new uint256[](_coinCount),
                lpDepositedAsCollateral: 0
            });
            lpTokenToPool[_lpTokenAddress] = _poolAddress;
        }
        
        emit AddOrSetPool(_poolAddress, new uint256[](_coinCount));
    }

    /// @notice Set Curve Pool Convex vault
    /// @param _poolAddress Address of Curve Pool
    /// @param _rewardsContractAddress Convex Rewards Contract Address
    function setPoolVault(
        address _poolAddress,
        address _rewardsContractAddress
    ) external onlyOwner approvedPool(_poolAddress) {
        poolInfo[_poolAddress].hasVault = true;
        IConvexBaseRewardPool _convexBaseRewardPool = IConvexBaseRewardPool(_rewardsContractAddress);
        uint256 _lpDepositPid = _convexBaseRewardPool.pid();
        poolInfo[_poolAddress].lpDepositPid = _lpDepositPid;
        poolInfo[_poolAddress].rewardsContractAddress = _rewardsContractAddress;
    }

    /// @notice Create a personal vault for that pool
    /// @param _poolAddress Address of Curve Pool
    /// @param _pid Pool id in FXS booster pool registry
    function createFxsVault(address _poolAddress, uint256 _pid) 
        external 
        onlyOwner 
        approvedPool(_poolAddress) 
        hasVault(_poolAddress)
    {
        poolInfo[_poolAddress].hasFxsVault = true;
        address _fxsPersonalVaultAddress = convexFXSBooster.createVault(_pid);
        poolInfo[_poolAddress].fxsPersonalVaultAddress = _fxsPersonalVaultAddress;
        IFxsPersonalVault fxsVault = IFxsPersonalVault(_fxsPersonalVaultAddress);
        require(poolInfo[_poolAddress].lpTokenAddress == fxsVault.curveLpToken(), "LP token is not matching");
    }

    /// @notice Set Curve Pool max allocations
    /// @param _poolAddress Address of Curve Pool
    /// @param _poolMaxAllocations Max allocation for each Pool coin
    function setPoolAllocation(
        address _poolAddress,
        uint256[] memory _poolMaxAllocations
    ) external onlyOwner approvedPool(_poolAddress) {
        for(uint256 i = 0; i < poolInfo[_poolAddress].coinCount; i++){
            poolInfo[_poolAddress].tokenMaxAllocation[i] = _poolMaxAllocations[i];
        }

        emit AddOrSetPool(_poolAddress, poolInfo[_poolAddress].tokenMaxAllocation);
    }

    /// @notice Change the FRAX Minter
    /// @param _amoMinterAddress FRAX AMO minter
    function setAMOMinter(address _amoMinterAddress) external onlyOwner {
        emit SetAMOMinter(address(amoMinter), _amoMinterAddress);

        amoMinter = IFraxAMOMinter(_amoMinterAddress);
    }

    /// @notice Change the AMO Helper
    /// @param _amoHelperAddress AMO Helper Address
    function setAMOHelper(address _amoHelperAddress) external onlyOwner {
        emit SetAMOHelper(address(amoHelper), _amoHelperAddress);

        amoHelper = ICurveAMOv5Helper(_amoHelperAddress);
    }

    /// @notice Change the Operator address
    /// @param _newOperatorAddress Operator address
    function setOperatorAddress(address _newOperatorAddress) external onlyOwner {
        emit SetOperator(operatorAddress, _newOperatorAddress);

        operatorAddress = _newOperatorAddress;
    }

    /// @notice in terms of 1e6 (overriding global_collateral_ratio)
    /// @param _state overriding / not
    /// @param _discountRate New Discount Rate
    function setDiscountRate(bool _state, uint256 _discountRate) external onlyOwner {
        setDiscount = _state;
        discountRate = _discountRate;
    }

    /// @notice Recover ERC20 tokens 
    /// @param tokenAddress address of ERC20 token
    /// @param tokenAmount amount to be withdrawn
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        // Can only be triggered by owner
        TransferHelper.safeTransfer(address(tokenAddress), msg.sender, tokenAmount);
    }

    // Generic proxy
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value:_value}(_data);
        return (success, result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface ICurveAMOv5Helper {
  function calcFraxAndUsdcWithdrawable ( address _curveAMOAddress, address _poolAddress, address _poolLpTokenAddress, uint256 _lpAmount ) external view returns ( uint256[4] memory _withdrawables );
  function getTknsForLPAtCurrRatio ( address _curveAMOAddress, address _poolAddress, address _poolLpTokenAddress, uint256 _lpAmount ) external view returns ( uint256[] memory _withdrawables );
  function showAllocations ( address _curveAMOAddress, uint256 _poolArrayLength ) external view returns ( uint256[10] memory allocations );
  function showOneStepBurningLp ( address _curveAMOAddress, address _poolAddress ) external view returns ( uint256 _oneStepBurningLp );
  function showPoolAssetBalances ( address _curveAMOAddress, address _poolAddress ) external view returns ( uint256[] memory _assetBalances );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IFrax {
  function COLLATERAL_RATIO_PAUSER() external view returns (bytes32);
  function DEFAULT_ADMIN_ADDRESS() external view returns (address);
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
  function addPool(address pool_address ) external;
  function allowance(address owner, address spender ) external view returns (uint256);
  function approve(address spender, uint256 amount ) external returns (bool);
  function balanceOf(address account ) external view returns (uint256);
  function burn(uint256 amount ) external;
  function burnFrom(address account, uint256 amount ) external;
  function collateral_ratio_paused() external view returns (bool);
  function controller_address() external view returns (address);
  function creator_address() external view returns (address);
  function decimals() external view returns (uint8);
  function decreaseAllowance(address spender, uint256 subtractedValue ) external returns (bool);
  function eth_usd_consumer_address() external view returns (address);
  function eth_usd_price() external view returns (uint256);
  function frax_eth_oracle_address() external view returns (address);
  function frax_info() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
  function frax_pools(address ) external view returns (bool);
  function frax_pools_array(uint256 ) external view returns (address);
  function frax_price() external view returns (uint256);
  function frax_step() external view returns (uint256);
  function fxs_address() external view returns (address);
  function fxs_eth_oracle_address() external view returns (address);
  function fxs_price() external view returns (uint256);
  function genesis_supply() external view returns (uint256);
  function getRoleAdmin(bytes32 role ) external view returns (bytes32);
  function getRoleMember(bytes32 role, uint256 index ) external view returns (address);
  function getRoleMemberCount(bytes32 role ) external view returns (uint256);
  function globalCollateralValue() external view returns (uint256);
  function global_collateral_ratio() external view returns (uint256);
  function grantRole(bytes32 role, address account ) external;
  function hasRole(bytes32 role, address account ) external view returns (bool);
  function increaseAllowance(address spender, uint256 addedValue ) external returns (bool);
  function last_call_time() external view returns (uint256);
  function minting_fee() external view returns (uint256);
  function name() external view returns (string memory);
  function owner_address() external view returns (address);
  function pool_burn_from(address b_address, uint256 b_amount ) external;
  function pool_mint(address m_address, uint256 m_amount ) external;
  function price_band() external view returns (uint256);
  function price_target() external view returns (uint256);
  function redemption_fee() external view returns (uint256);
  function refreshCollateralRatio() external;
  function refresh_cooldown() external view returns (uint256);
  function removePool(address pool_address ) external;
  function renounceRole(bytes32 role, address account ) external;
  function revokeRole(bytes32 role, address account ) external;
  function setController(address _controller_address ) external;
  function setETHUSDOracle(address _eth_usd_consumer_address ) external;
  function setFRAXEthOracle(address _frax_oracle_addr, address _weth_address ) external;
  function setFXSAddress(address _fxs_address ) external;
  function setFXSEthOracle(address _fxs_oracle_addr, address _weth_address ) external;
  function setFraxStep(uint256 _new_step ) external;
  function setMintingFee(uint256 min_fee ) external;
  function setOwner(address _owner_address ) external;
  function setPriceBand(uint256 _price_band ) external;
  function setPriceTarget(uint256 _new_price_target ) external;
  function setRedemptionFee(uint256 red_fee ) external;
  function setRefreshCooldown(uint256 _new_cooldown ) external;
  function setTimelock(address new_timelock ) external;
  function symbol() external view returns (string memory);
  function timelock_address() external view returns (address);
  function toggleCollateralRatio() external;
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount ) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
  function weth_address() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

// MAY need to be updated
interface IFraxAMOMinter {
  function FRAX() external view returns(address);
  function FXS() external view returns(address);
  function acceptOwnership() external;
  function addAMO(address amo_address, bool sync_too) external;
  function allAMOAddresses() external view returns(address[] memory);
  function allAMOsLength() external view returns(uint256);
  function amos(address) external view returns(bool);
  function amos_array(uint256) external view returns(address);
  function burnFraxFromAMO(uint256 frax_amount) external;
  function burnFxsFromAMO(uint256 fxs_amount) external;
  function col_idx() external view returns(uint256);
  function collatDollarBalance() external view returns(uint256);
  function collatDollarBalanceStored() external view returns(uint256);
  function collat_borrow_cap() external view returns(int256);
  function collat_borrowed_balances(address) external view returns(int256);
  function collat_borrowed_sum() external view returns(int256);
  function collateral_address() external view returns(address);
  function collateral_token() external view returns(address);
  function correction_offsets_amos(address, uint256) external view returns(int256);
  function custodian_address() external view returns(address);
  function dollarBalances() external view returns(uint256 frax_val_e18, uint256 collat_val_e18);
  // function execute(address _to, uint256 _value, bytes _data) external returns(bool, bytes);
  function fraxDollarBalanceStored() external view returns(uint256);
  function fraxTrackedAMO(address amo_address) external view returns(int256);
  function fraxTrackedGlobal() external view returns(int256);
  function frax_mint_balances(address) external view returns(int256);
  function frax_mint_cap() external view returns(int256);
  function frax_mint_sum() external view returns(int256);
  function fxs_mint_balances(address) external view returns(int256);
  function fxs_mint_cap() external view returns(int256);
  function fxs_mint_sum() external view returns(int256);
  function giveCollatToAMO(address destination_amo, uint256 collat_amount) external;
  function min_cr() external view returns(uint256);
  function mintFraxForAMO(address destination_amo, uint256 frax_amount) external;
  function mintFxsForAMO(address destination_amo, uint256 fxs_amount) external;
  function missing_decimals() external view returns(uint256);
  function nominateNewOwner(address _owner) external;
  function nominatedOwner() external view returns(address);
  function oldPoolCollectAndGive(address destination_amo) external;
  function oldPoolRedeem(uint256 frax_amount) external;
  function old_pool() external view returns(address);
  function owner() external view returns(address);
  function pool() external view returns(address);
  function receiveCollatFromAMO(uint256 usdc_amount) external;
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
  function removeAMO(address amo_address, bool sync_too) external;
  function setAMOCorrectionOffsets(address amo_address, int256 frax_e18_correction, int256 collat_e18_correction) external;
  function setCollatBorrowCap(uint256 _collat_borrow_cap) external;
  function setCustodian(address _custodian_address) external;
  function setFraxMintCap(uint256 _frax_mint_cap) external;
  function setFraxPool(address _pool_address) external;
  function setFxsMintCap(uint256 _fxs_mint_cap) external;
  function setMinimumCollateralRatio(uint256 _min_cr) external;
  function setTimelock(address new_timelock) external;
  function syncDollarBalances() external;
  function timelock_address() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

interface IBooster {
  function acceptPendingOwner (  ) external;
  function addPool ( address _implementation, address _stakingAddress, address _stakingToken ) external;
  function addProxyOwner ( address _proxy, address _owner ) external;
  function checkpointFeeRewards ( address _distroContract ) external;
  function claimFees ( address _distroContract, address _token ) external;
  function claimOperatorRoles (  ) external;
  function createVault ( uint256 _pid ) external returns ( address );
  function deactivatePool ( uint256 _pid ) external;
  function feeClaimMap ( address, address ) external view returns ( bool );
  function feeQueue (  ) external view returns ( address );
  function feeRegistry (  ) external view returns ( address );
  function feeclaimer (  ) external view returns ( address );
  function fxs (  ) external view returns ( address );
  function isShutdown (  ) external view returns ( bool );
  function owner (  ) external view returns ( address );
  function pendingOwner (  ) external view returns ( address );
  function poolManager (  ) external view returns ( address );
  function poolRegistry (  ) external view returns ( address );
  function proxy (  ) external view returns ( address );
  function proxyOwners ( address ) external view returns ( address );
  function recoverERC20 ( address _tokenAddress, uint256 _tokenAmount, address _withdrawTo ) external;
  function recoverERC20FromProxy ( address _tokenAddress, uint256 _tokenAmount, address _withdrawTo ) external;
  function rewardManager (  ) external view returns ( address );
  function setDelegate ( address _delegateContract, address _delegate, bytes32 _space ) external;
  function setFeeClaimPair ( address _claimAddress, address _token, bool _active ) external;
  function setFeeClaimer ( address _claimer ) external;
  function setFeeQueue ( address _queue ) external;
  function setPendingOwner ( address _po ) external;
  function setPoolFeeDeposit ( address _deposit ) external;
  function setPoolFees ( uint256 _cvxfxs, uint256 _cvx, uint256 _platform ) external;
  function setPoolManager ( address _pmanager ) external;
  function setPoolRewardImplementation ( address _impl ) external;
  function setRewardActiveOnCreation ( bool _active ) external;
  function setRewardManager ( address _rmanager ) external;
  function setVeFXSProxy ( address _vault, address _newproxy ) external;
  function shutdownSystem (  ) external;
  function voteGaugeWeight ( address _controller, address[] memory _gauge, uint256[] memory _weight ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IConvexBaseRewardPool {
  function addExtraReward(address _reward) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function clearExtraRewards() external;
  function currentRewards() external view returns (uint256);
  function donate(uint256 _amount) external returns (bool);
  function duration() external view returns (uint256);
  function earned(address account) external view returns (uint256);
  function extraRewards(uint256) external view returns (address);
  function extraRewardsLength() external view returns (uint256);
  function getReward() external returns (bool);
  function getReward(address _account, bool _claimExtras) external returns (bool);
  function historicalRewards() external view returns (uint256);
  function lastTimeRewardApplicable() external view returns (uint256);
  function lastUpdateTime() external view returns (uint256);
  function newRewardRatio() external view returns (uint256);
  function operator() external view returns (address);
  function periodFinish() external view returns (uint256);
  function pid() external view returns (uint256);
  function queueNewRewards(uint256 _rewards) external returns (bool);
  function queuedRewards() external view returns (uint256);
  function rewardManager() external view returns (address);
  function rewardPerToken() external view returns (uint256);
  function rewardPerTokenStored() external view returns (uint256);
  function rewardRate() external view returns (uint256);
  function rewardToken() external view returns (address);
  function rewards(address) external view returns (uint256);
  function stake(uint256 _amount) external returns (bool);
  function stakeAll() external returns (bool);
  function stakeFor(address _for, uint256 _amount) external returns (bool);
  function stakingToken() external view returns (address);
  function totalSupply() external view returns (uint256);
  function userRewardPerTokenPaid(address) external view returns (uint256);
  function withdraw(uint256 amount, bool claim) external returns (bool);
  function withdrawAll(bool claim) external;
  function withdrawAllAndUnwrap(bool claim) external;
  function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IConvexBooster {
  function FEE_DENOMINATOR() external view returns (uint256);
  function MaxFees() external view returns (uint256);
  function addPool(address _lptoken, address _gauge, uint256 _stashVersion) external returns (bool);
  function claimRewards(uint256 _pid, address _gauge) external returns (bool);
  function crv() external view returns (address);
  function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns (bool);
  function depositAll(uint256 _pid, bool _stake) external returns (bool);
  function distributionAddressId() external view returns (uint256);
  function earmarkFees() external returns (bool);
  function earmarkIncentive() external view returns (uint256);
  function earmarkRewards(uint256 _pid) external returns (bool);
  function feeDistro() external view returns (address);
  function feeManager() external view returns (address);
  function feeToken() external view returns (address);
  function gaugeMap(address) external view returns (bool);
  function isShutdown() external view returns (bool);
  function lockFees() external view returns (address);
  function lockIncentive() external view returns (uint256);
  function lockRewards() external view returns (address);
  function minter() external view returns (address);
  function owner() external view returns (address);
  function platformFee() external view returns (uint256);
  function poolInfo(uint256) external view returns (address lptoken, address token, address gauge, address crvRewards, address stash, bool shutdown);
  function poolLength() external view returns (uint256);
  function poolManager() external view returns (address);
  function registry() external view returns (address);
  function rewardArbitrator() external view returns (address);
  function rewardClaimed(uint256 _pid, address _address, uint256 _amount) external returns (bool);
  function rewardFactory() external view returns (address);
  function setArbitrator(address _arb) external;
  function setFactories(address _rfactory, address _sfactory, address _tfactory) external;
  function setFeeInfo() external;
  function setFeeManager(address _feeM) external;
  function setFees(uint256 _lockFees, uint256 _stakerFees, uint256 _callerFees, uint256 _platform) external;
  function setGaugeRedirect(uint256 _pid) external returns (bool);
  function setOwner(address _owner) external;
  function setPoolManager(address _poolM) external;
  function setRewardContracts(address _rewards, address _stakerRewards) external;
  function setTreasury(address _treasury) external;
  function setVoteDelegate(address _voteDelegate) external;
  function shutdownPool(uint256 _pid) external returns (bool);
  function shutdownSystem() external;
  function staker() external view returns (address);
  function stakerIncentive() external view returns (uint256);
  function stakerRewards() external view returns (address);
  function stashFactory() external view returns (address);
  function tokenFactory() external view returns (address);
  function treasury() external view returns (address);
  function vote(uint256 _voteId, address _votingAddress, bool _support) external returns (bool);
  function voteDelegate() external view returns (address);
  function voteGaugeWeight(address[] memory _gauge, uint256[] memory _weight) external returns (bool);
  function voteOwnership() external view returns (address);
  function voteParameter() external view returns (address);
  function withdraw(uint256 _pid, uint256 _amount) external returns (bool);
  function withdrawAll(uint256 _pid) external returns (bool);
  function withdrawTo(uint256 _pid, uint256 _amount, address _to) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IConvexClaimZap {
  function chefRewards() external view returns (address);
  function claimRewards(address[] calldata rewardContracts, uint256[] calldata chefIds, bool claimCvx, bool claimCvxStake, bool claimcvxCrv, uint256 depositCrvMaxAmount, uint256 depositCvxMaxAmount) external;
  function crv() external view returns (address);
  function crvDeposit() external view returns (address);
  function cvx() external view returns (address);
  function cvxCrv() external view returns (address);
  function cvxCrvRewards() external view returns (address);
  function cvxRewards() external view returns (address);
  function owner() external view returns (address);
  function setApprovals() external;
  function setChefRewards(address _rewards) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

interface IFxsPersonalVault {
  function FEE_DENOMINATOR (  ) external view returns ( uint256 );
  function changeRewards ( address _rewardsAddress ) external;
  function checkpointRewards (  ) external;
  function convexCurveBooster (  ) external view returns ( address );
  function convexDepositToken (  ) external view returns ( address );
  function crv (  ) external view returns ( address );
  function curveLpToken (  ) external view returns ( address );
  function cvx (  ) external view returns ( address );
  function earned (  ) external view returns ( address[] memory token_addresses, uint256[] memory total_earned );
  function feeRegistry (  ) external view returns ( address );
  function fxs (  ) external view returns ( address );
  function getReward (  ) external;
  function getReward ( bool _claim, address[] memory _rewardTokenList ) external;
  function getReward ( bool _claim ) external;
  function initialize ( address _owner, address _stakingAddress, address _stakingToken, address _rewardsAddress ) external;
  function lockAdditional ( bytes32 _kek_id, uint256 _addl_liq ) external;
  function lockAdditionalConvexToken ( bytes32 _kek_id, uint256 _addl_liq ) external;
  function lockAdditionalCurveLp ( bytes32 _kek_id, uint256 _addl_liq ) external;
  function lockLonger ( bytes32 _kek_id, uint256 new_ending_ts ) external;
  function owner (  ) external view returns ( address );
  function poolRegistry (  ) external view returns ( address );
  function rewards (  ) external view returns ( address );
  function setVeFXSProxy ( address _proxy ) external;
  function stakeLocked ( uint256 _liquidity, uint256 _secs ) external returns ( bytes32 kek_id );
  function stakeLockedConvexToken ( uint256 _liquidity, uint256 _secs ) external returns ( bytes32 kek_id );
  function stakeLockedCurveLp ( uint256 _liquidity, uint256 _secs ) external returns ( bytes32 kek_id );
  function stakingAddress (  ) external view returns ( address );
  function stakingToken (  ) external view returns ( address );
  function usingProxy (  ) external view returns ( address );
  function vaultType (  ) external pure returns ( uint8 );
  function vaultVersion (  ) external pure returns ( uint256 );
  function vefxsProxy (  ) external view returns ( address );
  function withdrawLocked ( bytes32 _kek_id ) external;
  function withdrawLockedAndUnwrap ( bytes32 _kek_id ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IVirtualBalanceRewardPool {
    function balanceOf(address account) external view returns (uint256);
    function currentRewards() external view returns (uint256);
    function deposits() external view returns (address);
    function donate(uint256 _amount) external returns (bool);
    function duration() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getReward() external;
    function getReward(address _account) external;
    function historicalRewards() external view returns (uint256);
    function lastTimeRewardApplicable() external view returns (uint256);
    function lastUpdateTime() external view returns (uint256);
    function newRewardRatio() external view returns (uint256);
    function operator() external view returns (address);
    function periodFinish() external view returns (uint256);
    function queueNewRewards(uint256 _rewards) external;
    function queuedRewards() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function rewardPerTokenStored() external view returns (uint256);
    function rewardRate() external view returns (uint256);
    function rewardToken() external view returns (address);
    function rewards(address) external view returns (uint256);
    function stake(address _account, uint256 amount) external;
    function totalSupply() external view returns (uint256);
    function userRewardPerTokenPaid(address) external view returns (uint256);
    function withdraw(address _account, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.11;

interface IcvxRewardPool {
  function FEE_DENOMINATOR() external view returns (uint256);
  function addExtraReward(address _reward) external;
  function balanceOf(address account) external view returns (uint256);
  function clearExtraRewards() external;
  function crvDeposits() external view returns (address);
  function currentRewards() external view returns (uint256);
  function cvxCrvRewards() external view returns (address);
  function cvxCrvToken() external view returns (address);
  function donate(uint256 _amount) external returns (bool);
  function duration() external view returns (uint256);
  function earned(address account) external view returns (uint256);
  function extraRewards(uint256) external view returns (address);
  function extraRewardsLength() external view returns (uint256);
  function getReward(bool _stake) external;
  function getReward(address _account, bool _claimExtras, bool _stake) external;
  function historicalRewards() external view returns (uint256);
  function lastTimeRewardApplicable() external view returns (uint256);
  function lastUpdateTime() external view returns (uint256);
  function newRewardRatio() external view returns (uint256);
  function operator() external view returns (address);
  function periodFinish() external view returns (uint256);
  function queueNewRewards(uint256 _rewards) external;
  function queuedRewards() external view returns (uint256);
  function rewardManager() external view returns (address);
  function rewardPerToken() external view returns (uint256);
  function rewardPerTokenStored() external view returns (uint256);
  function rewardRate() external view returns (uint256);
  function rewardToken() external view returns (address);
  function rewards(address) external view returns (uint256);
  function stake(uint256 _amount) external;
  function stakeAll() external;
  function stakeFor(address _for, uint256 _amount) external;
  function stakingToken() external view returns (address);
  function totalSupply() external view returns (uint256);
  function userRewardPerTokenPaid(address) external view returns (uint256);
  function withdraw(uint256 _amount, bool claim) external;
  function withdrawAll(bool claim) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

interface IMinCurvePool{
    function get_virtual_price() external view returns ( uint256 );
    function coins ( uint256 arg0 ) external view returns ( address );
    function balances ( uint256 arg0 ) external view returns ( uint256 );
    function add_liquidity ( uint256[2] memory _amounts, uint256 _min_mint_amount ) external returns ( uint256 );
    function add_liquidity ( uint256[3] memory _amounts, uint256 _min_mint_amount ) external ;
    function remove_liquidity ( uint256 _burn_amount, uint256[2] memory _min_amounts ) external;
    function remove_liquidity ( uint256 _burn_amount, uint256[3] memory _min_amounts ) external;

    // USD Pools
    function get_dy ( int128 i, int128 j, uint256 dx ) external view returns ( uint256 );
    function calc_token_amount ( uint256[] memory _amounts, bool _is_deposit ) external view returns ( uint256 );
    function calc_withdraw_one_coin ( uint256 _token_amount, int128 i ) external view returns ( uint256 );
    function remove_liquidity_one_coin ( uint256 _burn_amount, int128 i, uint256 _min_received ) external;
    // function remove_liquidity_one_coin ( uint256 _burn_amount, int128 i, uint256 _min_received ) external returns ( uint256 );
    function exchange ( int128 i, int128 j, uint256 dx, uint256 min_dy ) external;

    // metapool
    function get_dy ( int128 i, int128 j, uint256 dx, uint256[] memory _balances ) external view returns ( uint256 );

    // Crypto Pool
    function get_dy ( uint256 i, uint256 j, uint256 dx ) external view returns ( uint256 );
    function price_oracle (  ) external view returns ( uint256 );
    function lp_price (  ) external view returns ( uint256 );
    function calc_token_amount ( uint256[] memory _amounts ) external view returns ( uint256 );
    function calc_withdraw_one_coin ( uint256 _token_amount, uint256 i ) external view returns ( uint256 );
    function remove_liquidity_one_coin ( uint256 token_amount, uint256 i, uint256 min_amount ) external returns ( uint256 );
    function exchange ( uint256 i, uint256 j, uint256 dx, uint256 min_dy ) external returns ( uint256 );
}