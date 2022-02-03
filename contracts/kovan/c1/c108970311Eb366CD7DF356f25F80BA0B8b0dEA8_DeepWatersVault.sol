/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

// File: ../deepwaters/contracts/libraries/Context.sol

pragma solidity ^0.8.10;

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

// File: ../deepwaters/contracts/access/Ownable.sol

pragma solidity ^0.8.10;


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

// File: ../deepwaters/contracts/interfaces/IERC20.sol

pragma solidity ^0.8.10;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// File: ../deepwaters/contracts/token/extensions/IERC20Metadata.sol

pragma solidity ^0.8.10;


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

// File: ../deepwaters/contracts/token/ERC20.sol

pragma solidity ^0.8.10;



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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
        _approve(_msgSender(), spender, amount);
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
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

// File: ../deepwaters/contracts/libraries/Address.sol

pragma solidity ^0.8.10;

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

// File: ../deepwaters/contracts/libraries/SafeERC20.sol

pragma solidity ^0.8.10;



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

// File: ../deepwaters/contracts/interfaces/IDeepWatersPriceOracle.sol

pragma solidity ^0.8.10;

/**
 * @dev Interface for a DeepWaters price oracle.
 */
interface IDeepWatersPriceOracle {
    function getAssetPrice(address asset) external view returns (uint256);
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
    function getFallbackAssetPrice(address asset) external view returns (uint256);
    function getFallbackAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
}

// File: ../deepwaters/contracts/interfaces/IDeepWatersVault.sol

pragma solidity ^0.8.10;

/**
* @dev Interface for a DeepWatersVault contract
 **/

interface IDeepWatersVault {
    function liquidationUserBorrow(address _asset, address _user) external;
    function getAssetDecimals(address _asset) external view returns (uint256);
    function getAssetIsActive(address _asset) external view returns (bool);
    function getAssetDTokenAddress(address _asset) external view returns (address);
    function getAssetTotalLiquidity(address _asset) external view returns (uint256);
    function getAssetTotalBorrowBalance(address _asset) external view returns (uint256);
    function getAssetScarcityRatio(address _asset) external view returns (uint256);
    function getAssetScarcityRatioTarget(address _asset) external view returns (uint256);
    function getAssetBaseInterestRate(address _asset) external view returns (uint256);
    function getAssetSafeBorrowInterestRateMax(address _asset) external view returns (uint256);
    function getAssetInterestRateGrowthFactor(address _asset) external view returns (uint256);
    function getAssetVariableInterestRate(address _asset) external view returns (uint256);
    function getAssetCurrentStableInterestRate(address _asset) external view returns (uint256);
    function getAssetLiquidityRate(address _asset) external view returns (uint256);
    function getAssetLog2CumulatedLiquidityIndex(address _asset) external view returns (uint256);
    function getAssetLog2CumulatedVariableBorrowIndex(address _asset) external view returns (uint256);
    function getAssetCumulatedLiquidityIndex(address _asset) external view returns (uint256);
    function getAssetCumulatedVariableBorrowIndex(address _asset) external view returns (uint256);
    function updateLog2CumulatedIndexes(address _asset) external;
    function getAssetPriceUSD(address _asset) external view returns (uint256);
    function setDepositUsedAsCollateral(address _asset, address _user, bool _useDepositAsCollateral) external;
    function getDepositUsedAsCollateral(address _asset, address _user) external view returns (bool);
    function getUserAssetBalance(address _asset, address _user) external view returns (uint256);
    function getUserBorrowBalance(address _asset, address _user) external view returns (uint256);
    function getUserBorrowAverageStableInterestRate(address _asset, address _user) external view returns (uint256);
    function isUserStableRateBorrow(address _asset, address _user) external view returns (bool);
    function getAssets() external view returns (address[] memory);
    function transferToVault(address _asset, address payable _depositor, uint256 _amount) external;
    function transferToUser(address _asset, address payable _user, uint256 _amount) external;
    function transferToRouter(address _asset, uint256 _amount) external;
    function updateBorrowBalance(address _asset, address _user, uint256 _newBorrowBalance) external;
    function setAverageStableInterestRate(address _asset, address _user, uint256 _newAverageStableInterestRate) external;
    function setBorrowRateMode(address _asset, address _user, bool _isStableRateBorrow) external;
    receive() external payable;
}

// File: ../deepwaters/contracts/interfaces/IDeepWatersDataAggregator.sol

pragma solidity ^0.8.10;

/**
* @dev Interface for a DeepWatersDataAggregator contract
 **/

interface IDeepWatersDataAggregator {
    function getUserData(address _user)
        external
        view
        returns (
            uint256 collateralBalanceUSD,
            uint256 borrowBalanceUSD,
            uint256 collateralRatio,
            uint256 healthFactor,
            uint256 availableToBorrowUSD
        );
        
    function setVault(address payable _newVault) external;
}

// File: ../deepwaters/contracts/interfaces/IDeepWatersLending.sol

pragma solidity ^0.8.10;

/**
* @dev Interface for a DeepWatersLending contract
 **/

interface IDeepWatersLending {
    function setVault(address payable _newVault) external;
    function setDataAggregator(address _newDataAggregator) external;
    function getDataAggregator() external view returns (address);
    function getLiquidator() external view returns (address);
    function beforeTransferDToken(address _asset, address _fromUser, address _toUser, uint256 _amount) external;
}

// File: ../deepwaters/contracts/interfaces/IDToken.sol

pragma solidity ^0.8.10;

/**
* @dev Interface for a DToken contract
 **/

interface IDToken {
    function balanceOf(address _user) external view returns(uint256);
    function changeDeepWatersContracts(address _newLendingContract, address payable _newVault) external;
    function mint(address _user, uint256 _amount) external;
    function burn(address _user, uint256 _amount) external;
}

// File: ../deepwaters/contracts/libraries/PRBMath.sol

pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

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
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

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

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// File: ../deepwaters/contracts/libraries/PRBMathUD60x18.sol

pragma solidity >=0.8.4;


/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// File: ../deepwaters/contracts/DeepWatersVault.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;










/**
* @title DeepWatersVault contract
* @author DeepWaters
* @notice Holds all the funds deposited
**/
contract DeepWatersVault is IDeepWatersVault, Ownable {
    using SafeERC20 for ERC20;
    using Address for address;
    using PRBMathUD60x18 for uint256;

    struct Asset {
        uint256 decimals; // the decimals of the asset
        address dTokenAddress; // the address of the dToken representing the asset
        bool isActive; // isActive = true means the asset has been activated (default is true)
        uint256 scarcityRatioTarget; // the scarcity ratio target of the asset (default is 70%)
        uint256 baseInterestRate; // the minimum interest rate charged to borrowers (default is 0.5%)
        uint256 safeBorrowInterestRateMax; // the interest rate growth factor of the asset (default is 4%)
        uint256 interestRateGrowthFactor; // the interest rate growth factor of the asset (default is 100%)
    }
    
    struct AssetTotalBorrowBalances {
        uint256 totalVariableBorrowBalance;
        uint256 totalStableBorrowBalance;
    }

    struct UserDebt {
        uint256 borrowBalance; // user borrow balance of the asset
        uint256 relativeVariableBorrowBalance; // user relative variable borrow balance of the asset
        uint256 averageStableInterestRate; // user average stable borrow rate of the asset
        bool isStableRateBorrow; // this is a fixed rate loan
        uint256 lastTimestamp; // timestamp of the last operation of the borrow or repay
    }
    
    struct Log2CumulatedIndexes {
        uint256 value; // binary logarithm of cumulated index of the asset
        uint256 lastUpdate; // timestamp of the last index change
    }
    
    address internal lendingContractAddress;
    IDeepWatersLending lendingContract;
    
    address internal previousVaultAddress;
    address public priceOracleAddress;
    address payable public routerContractAddress;
    
    /**
    * @dev only lending contract can use functions affected by this modifier
    **/
    modifier onlyLendingContract {
        require(lendingContractAddress == msg.sender, "The caller must be a lending contract");
        _;
    }
    
    /**
    * @dev only router contract can use functions affected by this modifier
    **/
    modifier onlyRouterContract {
        require(routerContractAddress == msg.sender, "The caller must be a router contract");
        _;
    }
    
    /**
    * @dev only previous vault contract can use functions affected by this modifier
    **/
    modifier onlyPreviousVault {
        require(previousVaultAddress == msg.sender, "The caller must be a previous vault contract");
        _;
    }
    
    // the address used to identify ETH
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    uint256 internal constant SECONDS_PER_YEAR = 31536000; // 365 days = 60*60*24*365 = 31536000 sec
    uint256 internal constant PRBMATH_ONE = 1e18;
    uint256 internal constant PRBMATH_HUNDRED = 1e20;
    uint256 internal constant HUNDRED = 1e2;
        
    mapping(address => Asset) internal assets;
    mapping(address => bool) internal users;
    
    // user debt
    // usersDebts[asset][user] => UserDebt
    mapping(address => mapping(address => UserDebt)) internal usersDebts;
    
    // depositsNoUsedAsCollateral[asset][user] => true if the deposit is being no used as collateral by the user
    mapping(address => mapping(address => bool)) internal depositsNoUsedAsCollateral;
    
    // total borrow balances of the assets
    // totalBorrowBalances[asset] => AssetTotalBorrowBalances
    mapping(address => AssetTotalBorrowBalances) internal totalBorrowBalances;
    
    // binary logarithm of cumulated liquidity indexes of the assets
    // log2CumulatedLiquidityIndexes[asset] => Log2CumulatedIndexes
    mapping(address => Log2CumulatedIndexes) internal log2CumulatedLiquidityIndexes;
    
    // binary logarithm of cumulated variable borrow indexes of the assets
    // log2CumulatedVariableBorrowIndexes[asset] => Log2CumulatedIndexes
    mapping(address => Log2CumulatedIndexes) internal log2CumulatedVariableBorrowIndexes;
    
    address[] public addedAssetsList;
    address[] public usersList;
    
    constructor(
        address _previousVaultAddress,
        address _priceOracleAddress
    ) {
        previousVaultAddress = _previousVaultAddress;
        priceOracleAddress = _priceOracleAddress;
    }
    
    /**
    * @dev liquidation the user's debt
    * @param _asset the address of the asset
    * @param _user the address of the liquidated user
    **/
    function liquidationUserBorrow(address _asset, address _user) external onlyLendingContract {
        UserDebt storage userDebt = usersDebts[_asset][_user];
        
        if (userDebt.borrowBalance > 0) {
            address liquidator = lendingContract.getLiquidator();
            
            updateBorrowBalance(
                _asset,
                liquidator,
                usersDebts[_asset][liquidator].borrowBalance +
                  getUserBorrowBalance(_asset, _user)
            );
            
            updateBorrowBalance(_asset, _user, 0);
        }
    }
    
    /**
    * @dev sets lendingContractAddress
    * @param _newLendingContract the address of the DeepWatersLending contract
    **/
    function setLendingContract(address _newLendingContract) external onlyOwner {
        lendingContractAddress = _newLendingContract;
        lendingContract = IDeepWatersLending(lendingContractAddress);
        
        Asset memory asset;
        IDToken dToken;
        
        for (uint256 i = 0; i < addedAssetsList.length; i++) {
            asset = assets[addedAssetsList[i]];
           
            dToken = IDToken(asset.dTokenAddress);
            dToken.changeDeepWatersContracts(_newLendingContract, payable(address(this)));
        }
    }
    
    /**
    * @dev sets priceOracleAddress
    * @param _newPriceOracleAddress the address of the DeepWatersPriceOracle contract
    **/
    function setPriceOracleContract(address _newPriceOracleAddress) external onlyOwner {
        priceOracleAddress = _newPriceOracleAddress;
    }
    
    /**
    * @dev sets routerContractAddress
    * @param _newRouterContractAddress the address of the DeepWatersRouter contract
    **/
    function setRouterContract(address payable _newRouterContractAddress) external onlyOwner {
        routerContractAddress = _newRouterContractAddress;
    }
    
    /**
    * @dev fallback function enforces that the caller is a contract
    **/
    receive() external payable {
        require(msg.sender.isContract(), "Only contracts can send ETH to the DeepWatersVault contract");
    }

    /**
    * @dev transfers an asset from a depositor to the DeepWatersVault contract
    * @param _asset the address of the asset where the amount is being transferred
    * @param _depositor the address of the depositor from where the transfer is happening
    * @param _amount the asset amount being transferred
    **/
    function transferToVault(address _asset, address payable _depositor, uint256 _amount) external onlyLendingContract {
        require(ERC20(_asset).balanceOf(_depositor) >= _amount, "The user does not have enough balance to transfer");
        
        ERC20(_asset).safeTransferFrom(_depositor, address(this), _amount);
    }
    
    /**
    * @dev transfers to the user a specific amount of asset from the DeepWatersVault contract.
    * @param _asset the address of the asset
    * @param _user the address of the user receiving the transfer
    * @param _amount the amount being transferred
    **/
    function transferToUser(address _asset, address payable _user, uint256 _amount) external onlyLendingContract {
        if (_asset == ETH_ADDRESS) {
            _user.transfer(_amount);
        } else {
            ERC20(_asset).safeTransfer(_user, _amount);
        }
    }
    
    /**
    * @dev transfers to the DeepWatersRouter contract a specific amount of asset from the DeepWatersVault contract.
    * @param _asset the address of the asset
    * @param _amount the amount being transferred
    **/
    function transferToRouter(address _asset, uint256 _amount) external onlyRouterContract {
        if (_asset == ETH_ADDRESS) {
            routerContractAddress.transfer(_amount);
        } else {
            ERC20(_asset).safeTransfer(routerContractAddress, _amount);
        }
    }

    /**
    * @dev updates the user's borrow balance and total borrow balance
    * @param _asset the address of the borrowed asset
    * @param _user the address of the borrower
    * @param _newBorrowBalance new value of borrow balance
    **/
    function updateBorrowBalance(address _asset, address _user, uint256 _newBorrowBalance) public {
        require(
            msg.sender == lendingContractAddress ||
            msg.sender == address(this) ||
            msg.sender == previousVaultAddress,
            "The caller must be a lending contract or vault contract"
        );
    
        if (!users[_user]) {
            users[_user] = true;
            usersList.push(_user);
        }
        
        UserDebt storage userDebt = usersDebts[_asset][_user];
        
        uint256 _newRelativeVariableBorrowBalance; 
                
        if (_user != lendingContract.getLiquidator()) {
            AssetTotalBorrowBalances storage assetTotalBorrowBalances = totalBorrowBalances[_asset];
            
            if (userDebt.isStableRateBorrow) {
                assetTotalBorrowBalances.totalStableBorrowBalance = 
                    assetTotalBorrowBalances.totalStableBorrowBalance -
                      userDebt.borrowBalance +
                      _newBorrowBalance;
                
                if (_newBorrowBalance == 0) {
                    userDebt.averageStableInterestRate = 0;
                    userDebt.isStableRateBorrow = false;
                }
            } else {
                _newRelativeVariableBorrowBalance = _newBorrowBalance * PRBMATH_HUNDRED / getAssetCumulatedVariableBorrowIndex(_asset);
                
                assetTotalBorrowBalances.totalVariableBorrowBalance = 
                    assetTotalBorrowBalances.totalVariableBorrowBalance -
                    userDebt.borrowBalance +
                    _newBorrowBalance;
            }
        }
        
        userDebt.borrowBalance = _newBorrowBalance;
        userDebt.relativeVariableBorrowBalance = _newRelativeVariableBorrowBalance;
        userDebt.lastTimestamp = block.timestamp;
    }
    
    
    
    /**
    * @dev sets the user's average stable interest rate
    * @param _asset the address of the borrowed asset
    * @param _user the address of the borrower
    * @param _newAverageStableInterestRate new value of average stable interest rate
    **/
    function setAverageStableInterestRate(address _asset, address _user, uint256 _newAverageStableInterestRate) public onlyLendingContract {
        UserDebt storage userDebt = usersDebts[_asset][_user];
        userDebt.averageStableInterestRate = _newAverageStableInterestRate;
    }
    
    /**
    * @dev sets the user's borrow interest rate mode (stable or variable) for asset-specific borrows
    * @param _asset the address of the borrowed asset
    * @param _user the address of the borrower
    * @param _isStableRateBorrow the true for stable mode and the false for variable mode
    **/
    function setBorrowRateMode(address _asset, address _user, bool _isStableRateBorrow) public onlyLendingContract {
        UserDebt storage userDebt = usersDebts[_asset][_user];
        userDebt.isStableRateBorrow = _isStableRateBorrow;
    }
    
    /**
    * @dev gets total borrow balance of the specified asset
    * @param _asset the address of the basic asset
    **/
    function getAssetTotalBorrowBalance(address _asset) public view returns (uint256) {
        return totalBorrowBalances[_asset].totalVariableBorrowBalance + totalBorrowBalances[_asset].totalStableBorrowBalance;
    }
    
    /**
    * @dev gets total variable borrow balance of the specified asset
    * @param _asset the address of the basic asset
    **/
    function getAssetTotalVariableBorrowBalance(address _asset) public view returns (uint256) {
        return totalBorrowBalances[_asset].totalVariableBorrowBalance;
    }
    
    /**
    * @dev gets total stable borrow balance of the specified asset
    * @param _asset the address of the basic asset
    **/
    function getAssetTotalStableBorrowBalance(address _asset) external view returns (uint256) {
        return totalBorrowBalances[_asset].totalStableBorrowBalance;
    }
    
    /**
    * @dev gets scarcity ratio of the specified asset (in percents and with 18 decimals).
    * Scarcity ratio is ratio of asset-specific liabilities relative to asset-specific deposits.
    * @param _asset the address of the basic asset
    **/
    function getAssetScarcityRatio(address _asset) public view returns (uint256) {
        uint256 reserveSize = getAssetTotalLiquidity(_asset) + getAssetTotalBorrowBalance(_asset);
        
        return reserveSize == 0 ? 0 : getAssetTotalBorrowBalance(_asset) * PRBMATH_HUNDRED / reserveSize;
    }
    
    /**
    * @dev gets variable interest rate of the specified asset (in percents and with 18 decimals).
    * The interest rate for a variable-rate loan.
    * Rate is constantly variable in response to conditions of the system.
    * @param _asset the address of the basic asset
    **/
    function getAssetVariableInterestRate(address _asset) public view returns (uint256) {
        uint256 variableInterestRate;
        uint256 scarcityRatio = getAssetScarcityRatio(_asset);
        uint256 scarcityRatioTarget = assets[_asset].scarcityRatioTarget;
        
        if (scarcityRatio <= scarcityRatioTarget) {
            variableInterestRate = assets[_asset].baseInterestRate +
                scarcityRatio * assets[_asset].safeBorrowInterestRateMax / scarcityRatioTarget;
        } else {
            variableInterestRate = assets[_asset].baseInterestRate +
                assets[_asset].safeBorrowInterestRateMax +
                scarcityRatio * assets[_asset].interestRateGrowthFactor / scarcityRatioTarget / (PRBMATH_HUNDRED - scarcityRatioTarget);
        }
        
        return variableInterestRate;
    }
    
    /**
    * @dev gets current stable interest rate of the specified asset (in percents and with 18 decimals).
    * The current interest rate for a stable-rate loan.
    * @param _asset the address of the basic asset
    **/
    function getAssetCurrentStableInterestRate(address _asset) external view returns (uint256) {
        return getAssetVariableInterestRate(_asset) + uint256(4) * PRBMATH_ONE;
    }
    
    /**
    * @dev gets liquidity rate of the specified asset (in percents and with 18 decimals).
    * Ratio of interest for all borrows of the basic asset to reserve size
    * @param _asset the address of the basic asset
    * @return calculated liquidity rate
    **/
    function getAssetLiquidityRate(address _asset) public view returns (uint256) {
        uint256 totalVariableInterestPerYear = getAssetTotalVariableBorrowBalance(_asset) * getAssetVariableInterestRate(_asset);
        
        address user;
        uint256 totalStableInterestPerYear;
        
        for (uint256 j = 0; j < usersList.length; j++) {
            user = usersList[j];

            if (usersDebts[_asset][user].isStableRateBorrow) {
                totalStableInterestPerYear = totalStableInterestPerYear +
                    usersDebts[_asset][user].borrowBalance * usersDebts[_asset][user].averageStableInterestRate;
            }
        }
        
        uint256 reserveSize = getAssetTotalLiquidity(_asset) + getAssetTotalBorrowBalance(_asset);
        
        return reserveSize == 0 ? 0 : (totalVariableInterestPerYear + totalStableInterestPerYear)/reserveSize;
    }
    
    /**
    * @dev gets binary logarithm of calculated cumulated liquidity index of the specified asset (with 18 decimals).
    * @param _asset the address of the basic asset
    * @return binary logarithm of calculated cumulated liquidity index
    **/
    function getAssetLog2CumulatedLiquidityIndex(address _asset) public view returns (uint256) {
        return (block.timestamp - getAssetLog2CumulatedLiquidityIndexLastUpdate(_asset)) *
                  ((getAssetLiquidityRate(_asset) + PRBMATH_HUNDRED)/HUNDRED).log2() / 
                  SECONDS_PER_YEAR +
                getAssetLastStoredLog2CumulatedLiquidityIndex(_asset);
    }
    
    /**
    * @dev gets calculated cumulated liquidity index of the specified asset (in percents and with 18 decimals).
    * @param _asset the address of the basic asset
    * @return calculated cumulated liquidity index
    **/
    function getAssetCumulatedLiquidityIndex(address _asset) public view returns (uint256) {
        return getAssetLog2CumulatedLiquidityIndex(_asset).exp2() * HUNDRED;
    }
    
    /**
    * @dev gets binary logarithm of calculated cumulated variable borrow index of the specified asset (with 18 decimals).
    * @param _asset the address of the basic asset
    * @return binary logarithm of calculated cumulated variable borrow index
    **/
    function getAssetLog2CumulatedVariableBorrowIndex(address _asset) public view returns (uint256) {
        return (block.timestamp - getAssetLog2CumulatedVariableBorrowIndexLastUpdate(_asset)) *
                  ((getAssetVariableInterestRate(_asset) + PRBMATH_HUNDRED)/HUNDRED).log2() / 
                  SECONDS_PER_YEAR +
                getAssetLastStoredLog2CumulatedVariableBorrowIndex(_asset);
    }
    
    /**
    * @dev gets calculated cumulated variable borrow index of the specified asset (in percents and with 18 decimals).
    * @param _asset the address of the basic asset
    * @return calculated cumulated variable borrow index
    **/
    function getAssetCumulatedVariableBorrowIndex(address _asset) public view returns (uint256) {
        return getAssetLog2CumulatedVariableBorrowIndex(_asset).exp2() * HUNDRED;
    }
    
    /**
    * @dev gets last stored timestamp of last update of the cumulated variable borrow index of the specified asset
    * @param _asset the asset address
    * @return last stored timestamp
    **/
    function getAssetLog2CumulatedVariableBorrowIndexLastUpdate(address _asset) public view returns (uint256) {
        return log2CumulatedVariableBorrowIndexes[_asset].lastUpdate;
    }
    
    /**
    * @dev gets last stored binary logarithm of cumulated variable borrow index of the specified asset (with 18 decimals).
    * @param _asset the address of the basic asset
    * @return last stored binary logarithm of cumulated variable borrow index
    **/
    function getAssetLastStoredLog2CumulatedVariableBorrowIndex(address _asset) public view returns (uint256) {
        return log2CumulatedVariableBorrowIndexes[_asset].value;
    }
    
    /**
    * @dev gets last stored binary logarithm of cumulated liquidity index of the specified asset (with 18 decimals).
    * @param _asset the address of the basic asset
    * @return last stored binary logarithm of cumulated liquidity index
    **/
    function getAssetLastStoredLog2CumulatedLiquidityIndex(address _asset) public view returns (uint256) {
        return log2CumulatedLiquidityIndexes[_asset].value;
    }
    
    /**
    * @dev gets last stored timestamp of last update of the cumulated liquidity index of the specified asset
    * @param _asset the asset address
    * @return last stored timestamp
    **/
    function getAssetLog2CumulatedLiquidityIndexLastUpdate(address _asset) public view returns (uint256) {
        return log2CumulatedLiquidityIndexes[_asset].lastUpdate;
    }
    
    /**
    * @dev updates binary logarithm of cumulated liquidity index and variable borrow index of the specified asset
    * @param _asset the address of the basic asset
    **/
    function updateLog2CumulatedIndexes(address _asset) external onlyLendingContract {
        Log2CumulatedIndexes storage log2CumulatedLiquidityIndex = log2CumulatedLiquidityIndexes[_asset];
        log2CumulatedLiquidityIndex.value = getAssetLog2CumulatedLiquidityIndex(_asset);
        log2CumulatedLiquidityIndex.lastUpdate = block.timestamp;
        
        Log2CumulatedIndexes storage log2CumulatedVariableBorrowIndex = log2CumulatedVariableBorrowIndexes[_asset];
        log2CumulatedVariableBorrowIndex.value = getAssetLog2CumulatedVariableBorrowIndex(_asset);
        log2CumulatedVariableBorrowIndex.lastUpdate = block.timestamp;
    }
    
    /**
    * @dev gets the basic asset balance of a user based on the corresponding dToken balance.
    * @param _asset the basic asset address
    * @param _user the user address
    * @return the basic asset balance of the user
    **/
    function getUserAssetBalance(address _asset, address _user) public view returns (uint256) {
        IDToken dToken = IDToken(assets[_asset].dTokenAddress);
        return dToken.balanceOf(_user);
    }
    
    /**
    * @dev gets the borrow balance of a user for the specified asset
    * @param _asset the basic asset address
    * @param _user the user address
    * @return borrow balance of the user
    **/
    function getUserBorrowBalance(address _asset, address _user) public view returns (uint256) {
        UserDebt storage userDebt = usersDebts[_asset][_user];

        if (_user == lendingContract.getLiquidator()) {
            return userDebt.borrowBalance;
        }
        
        if (userDebt.isStableRateBorrow) {
            return userDebt.borrowBalance * 
                (((userDebt.averageStableInterestRate + PRBMATH_HUNDRED) / HUNDRED).
                    pow((block.timestamp - userDebt.lastTimestamp) * PRBMATH_ONE / SECONDS_PER_YEAR)) /
                PRBMATH_ONE;
        } else {
            return userDebt.relativeVariableBorrowBalance * 
                getAssetCumulatedVariableBorrowIndex(_asset) /
                PRBMATH_HUNDRED;
        }
    }
    
    /**
    * @dev gets the user's average stable interest rate for the specified asset
    * @param _asset the basic asset address
    * @param _user the user address
    * @return average stable interest rate
    **/
    function getUserBorrowAverageStableInterestRate(address _asset, address _user) external view returns (uint256) {
        return usersDebts[_asset][_user].averageStableInterestRate;
    }
    
    /**
    * @dev gets the true if the user has a borrow with a stable rate for specified asset
    * @param _asset the asset address
    * @param _user the user address
    * @return the true if it is stable rate borrow. Otherwise returns false
    **/
    function isUserStableRateBorrow(address _asset, address _user) external view returns (bool) {
        return usersDebts[_asset][_user].isStableRateBorrow;
    }
    
    /**
    * @dev gets the timestamp of the last operation of the borrow or repay of user for the specified asset
    * @param _asset the basic asset address
    * @param _user the user address
    * @return the timestamp of the last operation of the borrow or repay of user
    **/
    function getUserBorrowLastTimestamp(address _asset, address _user) external view returns (uint256) {
        return usersDebts[_asset][_user].lastTimestamp;
    }

    /**
    * @dev gets the dToken contract address for the specified asset
    * @param _asset the basic asset address
    * @return the address of the dToken contract
    **/
    function getAssetDTokenAddress(address _asset) public view returns (address) {
        return assets[_asset].dTokenAddress;
    }

    /**
    * @dev gets the asset total liquidity.
    *   The total liquidity is the balance of the asset in the DeepWatersVault contract
    * @param _asset the basic asset address
    * @return the asset total liquidity
    **/
    function getAssetTotalLiquidity(address _asset) public view returns (uint256) {
        uint256 balance;

        if (_asset == ETH_ADDRESS) {
            balance = address(this).balance;
        } else {
            balance = ERC20(_asset).balanceOf(address(this));
        }
        return balance;
    }

    /**
    * @dev gets the decimals of the specified asset
    * @param _asset the basic asset address
    * @return the asset decimals
    **/
    function getAssetDecimals(address _asset) external view returns (uint256) {
        return assets[_asset].decimals;
    }

    /**
    * @dev returns true if the specified asset is active
    * @param _asset the basic asset address
    * @return true if the asset is active, false otherwise
    **/
    function getAssetIsActive(address _asset) external view returns (bool) {
        return assets[_asset].isActive;
    }
    
    /**
    * @dev gets the scarcity ratio target of the specified asset
    * @param _asset the basic asset address
    * @return the scarcity ratio target
    **/
    function getAssetScarcityRatioTarget(address _asset) external view returns (uint256) {
        return assets[_asset].scarcityRatioTarget;
    }
    
    /**
    * @dev gets the base interest rate of the specified asset
    * @param _asset the basic asset address
    * @return the base interest rate
    **/
    function getAssetBaseInterestRate(address _asset) external view returns (uint256) {
        return assets[_asset].baseInterestRate;
    }
    
    /**
    * @dev gets the safe borrow interest rate max of the specified asset
    * @param _asset the basic asset address
    * @return the safe borrow interest rate max
    **/
    function getAssetSafeBorrowInterestRateMax(address _asset) external view returns (uint256) {
        return assets[_asset].safeBorrowInterestRateMax;
    }
    
    /**
    * @dev gets the interest rate growth factor of the specified asset
    * @param _asset the basic asset address
    * @return the interest rate growth factor
    **/
    function getAssetInterestRateGrowthFactor(address _asset) external view returns (uint256) {
        return assets[_asset].interestRateGrowthFactor;
    }

    /**
    * @return the array of basic assets added on the vault
    **/
    function getAssets() external view returns (address[] memory) {
        return addedAssetsList;
    }
    
    /**
    * @dev initializes an asset
    * @param _asset the address of the asset
    * @param _dTokenAddress the address of the corresponding dToken contract
    * @param _decimals the number of decimals of the asset
    * @param _isActive true if the basic asset is activated
    * @param _scarcityRatioTarget the scarcity ratio target of the asset in percents and with 18 decimals. Default is 70e18 (70%)
    * @param _baseInterestRate the minimum interest rate charged to borrowers in percents and with 18 decimals. Default is 5e17 (0.5%)
    * @param _safeBorrowInterestRateMax the safe borrow interest rate max of the asset in percents and with 18 decimals. Default is 4e18 (4%)
    * @param _interestRateGrowthFactor the interest rate growth factor of the asset in percents and with 18 decimals. Default is 100e18 (100%)
    **/
    function initAsset(
        address _asset,
        address _dTokenAddress,
        uint256 _decimals,
        bool _isActive,
        uint256 _scarcityRatioTarget,
        uint256 _baseInterestRate,
        uint256 _safeBorrowInterestRateMax,
        uint256 _interestRateGrowthFactor
    ) public {
        require(
            msg.sender == owner() || msg.sender == previousVaultAddress,
            "The caller must be owner or previous vault contract"
        );
        
        Asset storage asset = assets[_asset];
        require(asset.dTokenAddress == address(0), "Asset has already been initialized");

        asset.dTokenAddress = _dTokenAddress;
        asset.decimals = _decimals;
        asset.isActive = _isActive;
        asset.scarcityRatioTarget = _scarcityRatioTarget;
        asset.baseInterestRate = _baseInterestRate;
        asset.safeBorrowInterestRateMax = _safeBorrowInterestRateMax;
        asset.interestRateGrowthFactor = _interestRateGrowthFactor;
        
        Log2CumulatedIndexes storage log2CumulatedLiquidityIndex = log2CumulatedLiquidityIndexes[_asset];
        log2CumulatedLiquidityIndex.lastUpdate = block.timestamp;
        
        Log2CumulatedIndexes storage log2CumulatedVariableBorrowIndex = log2CumulatedVariableBorrowIndexes[_asset];
        log2CumulatedVariableBorrowIndex.lastUpdate = block.timestamp;
        
        bool currentAssetAdded = false;
        for (uint256 i = 0; i < addedAssetsList.length; i++) {
            if (addedAssetsList[i] == _asset) {
                currentAssetAdded = true;
            }
        }
        
        if (!currentAssetAdded) {
            addedAssetsList.push(_asset);
        }
    }

    /**
    * @dev activates an asset
    * @param _asset the address of the basic asset
    **/
    function activateAsset(address _asset) external onlyOwner {
        Asset storage asset = assets[_asset];

        require(asset.dTokenAddress != address(0), "Asset has not been initialized");
        
        asset.isActive = true;
    }
    
    /**
    * @dev deactivates an asset
    * @param _asset the address of the basic asset
    **/
    function deactivateAsset(address _asset) public {
        require(
            msg.sender == owner() || msg.sender == address(this),
            "The caller must be owner or vault contract"
        );
        
        Asset storage asset = assets[_asset];
        asset.isActive = false;
    }
    
    /**
    * @dev sets the scarcity ratio target of the specified asset
    * @param _asset the address of the basic asset
    * @param newScarcityRatioTarget new value of the scarcity ratio target of the basic asset
    **/
    function setAssetScarcityRatioTarget(address _asset, uint256 newScarcityRatioTarget) external onlyOwner {
        Asset storage asset = assets[_asset];

        require(asset.dTokenAddress != address(0), "Asset has not been initialized");
        
        asset.scarcityRatioTarget = newScarcityRatioTarget;
    }
    
    /**
    * @dev sets the base interest rate of the specified asset
    * @param _asset the address of the basic asset
    * @param newBaseInterestRate new value of the base interest rate of the basic asset
    **/
    function setAssetBaseInterestRate(address _asset, uint256 newBaseInterestRate) external onlyOwner {
        Asset storage asset = assets[_asset];

        require(asset.dTokenAddress != address(0), "Asset has not been initialized");
        
        asset.baseInterestRate = newBaseInterestRate;
    }
    
    /**
    * @dev sets the safe borrow interest rate max of the specified asset
    * @param _asset the address of the basic asset
    * @param newSafeBorrowInterestRateMax new value of the safe borrow interest rate max of the basic asset
    **/
    function setAssetSafeBorrowInterestRateMax(address _asset, uint256 newSafeBorrowInterestRateMax) external onlyOwner {
        Asset storage asset = assets[_asset];

        require(asset.dTokenAddress != address(0), "Asset has not been initialized");
        
        asset.safeBorrowInterestRateMax = newSafeBorrowInterestRateMax;
    }

    /**
    * @dev sets the interest rate growth factor of the specified asset
    * @param _asset the address of the basic asset
    * @param newInterestRateGrowthFactor new value of the interest rate growth factor of the basic asset
    **/
    function setAssetInterestRateGrowthFactor(address _asset, uint256 newInterestRateGrowthFactor) external onlyOwner {
        Asset storage asset = assets[_asset];

        require(asset.dTokenAddress != address(0), "Asset has not been initialized");
        
        asset.interestRateGrowthFactor = newInterestRateGrowthFactor;
    }
    
    /**
    * @dev gets the price in USD of the specified asset
    * @param _asset the address of the basic asset
    **/
    function getAssetPriceUSD(address _asset) external view returns (uint256) {
        IDeepWatersPriceOracle priceOracle = IDeepWatersPriceOracle(priceOracleAddress);
        return priceOracle.getAssetPrice(_asset);
    }
    
    /**
    * @dev sets how to use user's deposit (as collateral or not)
    * @param _asset the address of the deposit asset
    * @param _user the address of the user
    * @param _useDepositAsCollateral true if the user wants to use the deposit as collateral
    **/
    function setDepositUsedAsCollateral(address _asset, address _user, bool _useDepositAsCollateral)
        external
        onlyLendingContract
    {
        depositsNoUsedAsCollateral[_asset][_user] = !_useDepositAsCollateral;
    }
    
    /**
    * @dev gets whether the user's deposit is used as collateral
    * @param _asset the address of the deposit asset
    * @param _user the address of the user
    * @return true if the user's deposit is being used as collateral
    **/
    function getDepositUsedAsCollateral(address _asset, address _user) external view returns (bool) {
        return !depositsNoUsedAsCollateral[_asset][_user];
    }
    
    /**
    * @dev the migration of assets and debt balances between DeepWatersVault contracts
    * This function is only used on the testnet!
    * Migration is prohibited on the mainnet!
    * @param _newLendingContract the address of new DeepWatersLending contract
    * @param _newVault the address of new DeepWatersVault contract
    **/
    function migrationToNewVault(address _newLendingContract, address payable _newVault) external onlyOwner {
        DeepWatersVault newVault = DeepWatersVault(_newVault);
        
        address assetAddress;
        Asset memory asset;
        IDToken dToken;
        address user;
        
        lendingContract.setVault(_newVault);
        
        IDeepWatersDataAggregator dataAggregator = IDeepWatersDataAggregator(lendingContract.getDataAggregator());
        dataAggregator.setVault(_newVault);
        
        for (uint256 i = 0; i < addedAssetsList.length; i++) {
            assetAddress = addedAssetsList[i];
            asset = assets[assetAddress];
           
            newVault.initAsset(
                assetAddress,
                asset.dTokenAddress,
                asset.decimals,
                asset.isActive,
                asset.scarcityRatioTarget,
                asset.baseInterestRate,
                asset.safeBorrowInterestRateMax,
                asset.interestRateGrowthFactor
            );
        
            if (assetAddress == ETH_ADDRESS) {
                _newVault.transfer(address(this).balance);
            } else {
                ERC20(assetAddress).safeTransfer(_newVault, ERC20(assetAddress).balanceOf(address(this)));
            }
            
            dToken = IDToken(asset.dTokenAddress);
            dToken.changeDeepWatersContracts(_newLendingContract, _newVault);
            
            for (uint256 j = 0; j < usersList.length; j++) {
                user = usersList[j];
                
                if (usersDebts[assetAddress][user].borrowBalance > 0) {
                    newVault.migrationUserDebt(
                        assetAddress,
                        user,
                        usersDebts[assetAddress][user].borrowBalance,
                        usersDebts[assetAddress][user].averageStableInterestRate,
                        usersDebts[assetAddress][user].isStableRateBorrow,
                        usersDebts[assetAddress][user].lastTimestamp
                    );
                }
            }
            
            newVault.setLog2CumulatedLiquidityIndex(
                assetAddress,
                getAssetLastStoredLog2CumulatedLiquidityIndex(assetAddress),
                getAssetLog2CumulatedLiquidityIndexLastUpdate(assetAddress)
            );
            
            deactivateAsset(assetAddress);
        }
    }
    
    /**
    * @dev the migration of user debt balance of the asset between DeepWatersVault contracts
    * This function is only used on the testnet!!!
    * Migration is prohibited on the mainnet!!!
    * @param _asset the asset address
    * @param _user the user address
    * @param _newBorrowBalance new value of user borrow balance of the asset
    * @param _newAverageStableInterestRate new value of average stable borrow interest rate of the asset
    * @param _isStableRateBorrow the true for fixed rate loan and the false for variable rate loan
    * @param _lastTimestamp the timestamp of the last user operation of the borrow or repay
    **/
    function migrationUserDebt(
        address _asset,
        address _user,
        uint256 _newBorrowBalance,
        uint256 _newAverageStableInterestRate,
        bool _isStableRateBorrow,
        uint256 _lastTimestamp
    ) external onlyPreviousVault {
        UserDebt storage userDebt = usersDebts[_asset][_user];
        
        userDebt.averageStableInterestRate = _newAverageStableInterestRate;
        userDebt.isStableRateBorrow = _isStableRateBorrow;
        
        updateBorrowBalance(_asset, _user, _newBorrowBalance);
        
        userDebt.lastTimestamp = _lastTimestamp;
    }
    
    /**
    * @dev sets binary logarithm of cumulated liquidity index of the specified asset during migration between DeepWatersVault contracts
    * This function is only used on the testnet!!!
    * Migration is prohibited on the mainnet!!!
    * @param _asset the address of the basic asset
    **/
    function setLog2CumulatedLiquidityIndex(
        address _asset,
        uint256 _log2CumulatedLiquidityIndex,
        uint256 _lastUpdate
    ) external onlyPreviousVault {
        Log2CumulatedIndexes storage log2CumulatedLiquidityIndex = log2CumulatedLiquidityIndexes[_asset];
        log2CumulatedLiquidityIndex.value = _log2CumulatedLiquidityIndex;
        log2CumulatedLiquidityIndex.lastUpdate = _lastUpdate;
    }
    
    function setDataAggregator(address _newDataAggregator) external onlyOwner {
        lendingContract.setDataAggregator(_newDataAggregator);
    }
    
    /**
    * @dev gets the address of the DeepWatersLending contract
    **/
    function getLendingContract() external view returns (address) {
        return lendingContractAddress;
    }
    
    function getPreviousVault() external view returns (address) {
        return previousVaultAddress;
    }
}