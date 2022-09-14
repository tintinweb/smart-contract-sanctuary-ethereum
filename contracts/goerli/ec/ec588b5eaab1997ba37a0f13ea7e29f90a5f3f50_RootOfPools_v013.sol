/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// File: @openzeppelin/contracts/proxy/Proxy.sol


// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

// File: contracts/flat.sol

//SPDX-License-Identifier: GNU GPLv3
pragma solidity ^0.8.2;





/// @title The root of the poole tree. Allows you to close control of a large
/// number of pools to 1 address. Simplifies user interaction with a large number of pools.
/// @author Nethny
/// @dev Must be the owner of child contracts, to short-circuit the administrative
/// rights to one address.
contract RootOfPools_v013 is Initializable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using Strings for uint256;

    struct Pool {
        address pool;
        string name;
    }

    mapping(string => address) private _poolsTable;
    mapping(address => bool) private _imageTable;

    address public _usdAddress;
    address public _rankingAddress;

    Pool[] public Pools;

    address[] public Images;

    event PoolCreated(string name, address pool);
    event ImageAdded(address image);

    modifier shouldExist(string calldata name) {
        require(
            _poolsTable[name] != address(0),
            "ROOT: Selected pool does not exist!"
        );
        _;
    }

    /// @notice Replacement of the constructor to implement the proxy
    function initialize(address usdAddress, address rankingAddress)
        external
        initializer
    {
        require(
            usdAddress != address(0),
            "INIT: The usdAddress must not be zero."
        );
        require(
            rankingAddress != address(0),
            "INIT: The rankingAddress must not be zero."
        );

        __Ownable_init();
        _usdAddress = usdAddress;
        _rankingAddress = rankingAddress;
    }

    /// @notice Returns the address of the usd token in which funds are collected
    function getUSDAddress() external view returns (address) {
        return _usdAddress;
    }

    function addImage(address image) external onlyOwner {
        Images.push(image);
        _imageTable[image] = true;

        emit ImageAdded(image);
    }

    /// @notice Returns the linked branch contracts
    function getPools() external view returns (Pool[] memory) {
        return Pools;
    }

    /// @notice Allows you to attach a new pool (branch contract)
    /// @dev Don't forget to run the init function
    function createPool(string calldata name, uint256 imageNumber)
        external
        onlyOwner
    {
        require(
            imageNumber <= Images.length,
            "ROOT: Such an image does not exist"
        );
        require(
            _poolsTable[name] == address(0),
            "ROOT: Pool with this name already exists!"
        );

        TransparentProxy pool = new TransparentProxy(Images[imageNumber]);

        address addrPool = address(pool);

        _poolsTable[name] = addrPool;

        Pool memory poolT = Pool(addrPool, name);
        Pools.push(poolT);

        emit PoolCreated(name, addrPool);
    }

    event Response(address to, bool success, bytes data);

    /*
    // Let's imagine that contract B does not have the source code for
    // contract A, but we do know the address of A and the function to call.
    function testCallFoo(address payable _addr) public payable {
        // You can send ether and specify a custom gas amount
        (bool success, bytes memory data) = _addr.call{value: msg.value, gas: 5000}(
            abi.encodeWithSignature("foo(string,uint256)", "call foo", 123)
        );

        emit Response(success, data);*/

    function Calling(string calldata name, bytes calldata dataIn)
        external
        onlyOwner
        shouldExist(name)
    {
        address dst = _poolsTable[name];
        (bool success, bytes memory data) = dst.call(dataIn);

        emit Response(dst, success, data);
    }

    function claimName(string calldata name) external shouldExist(name) {
        BranchOfPools(_poolsTable[name]).claim();
    }

    function claimAddress(address pool) internal {
        require(pool != address(0), "ROOT: Selected pool does not exist!");

        BranchOfPools(pool).claim();
    }

    function prepClaimAll(address user)
        external
        view
        returns (address[] memory pools)
    {
        address[] memory out;
        for (uint256 i; i < Pools.length; i++) {
            if (BranchOfPools(Pools[i].pool).isClaimable(user)) {
                out[i] = Pools[i].pool;
            }
        }

        return pools;
    }

    ///@dev To find out the list of pools from which a user can mine something,
    ///     use the prepClaimAll function
    function claimAll(address[] calldata pools) external {
        for (uint256 i; i < pools.length; i++) {
            claimAddress(pools[i]);
        }
    }

    function checkAllClaims(address user) external view returns (uint256) {
        uint256 temp;
        for (uint256 i; i < Pools.length; i++) {
            temp += (BranchOfPools(Pools[i].pool).myCurrentAllocation(user));
        }

        return temp;
    }

    function getAllocations(address user, uint256 step)
        external
        view
        returns (uint256[10] memory)
    {
        uint256[10] memory amounts;
        for (
            uint256 i;
            (i + 10 * step < (step + 1) * 10) && (i + 10 * step < Pools.length);
            i++
        ) {
            amounts[i] = (BranchOfPools(Pools[i].pool).myAllocation(user));
        }
        return amounts;
    }

    function getState(string calldata name)
        external
        view
        shouldExist(name)
        returns (BranchOfPools.State)
    {
        return BranchOfPools(_poolsTable[name])._state();
    }

    function getRanks() external view returns (address) {
        return _rankingAddress;
    }
}








/// @title The pool's subsidiary contract for fundraising.
/// This contract collects funds, distributes them, and charges fees
/// @author Nethny
/// @dev This contract pulls commissions and other parameters from the Ranking contract.
/// Important: Agree on the structure of the ranking parameters and this contract!
/// Otherwise the calculations can be wrong!
contract BranchOfPools is Ownable, Initializable {
    using Address for address;
    using Strings for uint256;

    enum State {
        Pause,
        Fundrasing,
        WaitingToken,
        TokenDistribution,
        Emergency
    }
    State public _state = State.Pause;

    //Events
    event Deposit(address user, uint256 amount);
    event Claim(address user);
    event FundraisingOpened();
    event FundraisingClosed();
    event TokenEntrusted(address addrToken, uint256 amount);
    event EmergencyStoped();
    event FundsReturned(address user, uint256 amount);

    address private _root;
    uint256 public _priceToken;

    uint256 public _stepValue;
    uint256 public _VALUE;
    uint256 public _CURRENT_VALUE;
    uint256 public _FUNDS_RAISED;
    uint256 public _CURRENT_COMMISSION;
    uint256 public _CURRENT_VALUE_TOKEN;
    uint256 public _VALUE_TOKEN;
    uint256 private _decimals;

    address public _usd;
    address public _token;
    address public _devUSDAddress;

    address public _fundAddress;
    bool private _fundLock = false;
    uint256 private _fundValue;
    uint256 public _fundCommission;

    mapping(address => uint256) private _valueUSDList;
    mapping(address => uint256) private _usdEmergency;
    mapping(address => uint256) private _openUnlocks;

    uint256[] public _unlocks;

    address[] public _listParticipants;

    /// @notice Assigns the necessary values to the variables
    /// @dev Just a constructor
    /// You need to call init()
    /// @param Root - RootOfPools contract address
    /// @param VALUE - The target amount of funds we collect
    /// @param Step - The step with which we raise funds
    /// @param price - Price of 1 token in usd
    /// @param devUSDAddress - The address of the developers to which they will receive the collected funds
    function init(
        address Root,
        uint256 VALUE,
        uint256 Step,
        uint256 price,
        address devUSDAddress,
        address fundAddress,
        uint256 fundCommission
    ) external onlyOwner initializer returns (uint256) {
        require(Root != address(0), "The root address must not be zero.");
        require(
            devUSDAddress != address(0),
            "The devUSDAddress must not be zero."
        );

        _root = Root;
        _usd = RootOfPools_v013(_root).getUSDAddress();
        _decimals = 10**ERC20(_usd).decimals();
        _VALUE = VALUE * _decimals;
        _stepValue = Step * _decimals;
        _priceToken = price;
        _devUSDAddress = devUSDAddress;
        _fundAddress = fundAddress;
        _fundCommission = fundCommission;
    }

    /// @notice Changes the target amount of funds we collect
    /// @param value - the new target amount of funds raised
    function changeTargetValue(uint256 value)
        external
        onlyOwner
        onlyNotState(State.TokenDistribution)
        onlyNotState(State.WaitingToken)
    {
        uint256 temp = _VALUE;
        _VALUE = value;
    }

    /// @notice Changes the step with which we raise funds
    /// @param step - the new step
    function changeStepValue(uint256 step)
        external
        onlyOwner
        onlyNotState(State.TokenDistribution)
        onlyNotState(State.WaitingToken)
    {
        uint256 temp = _stepValue;
        _stepValue = step;
    }

    modifier onlyState(State state) {
        require(_state == state, "STATE: It's impossible to do it now.");
        _;
    }

    modifier onlyNotState(State state) {
        require(_state != state, "STATE: It's impossible to do it now.");
        _;
    }

    /// @notice Opens fundraising
    function startFundraising() external onlyOwner onlyState(State.Pause) {
        _state = State.Fundrasing;

        emit FundraisingOpened();
    }

    /// @notice Termination of fundraising and opening the possibility of refunds to depositors
    function stopEmergency()
        external
        onlyOwner
        onlyNotState(State.Pause)
        onlyNotState(State.TokenDistribution)
    {
        if (_state == State.WaitingToken) {
            uint256 balance = ERC20(_usd).balanceOf(address(this));
            require(
                balance >= _FUNDS_RAISED + _CURRENT_COMMISSION,
                "It takes money to get a refund"
            );
        }

        _state = State.Emergency;

        emit EmergencyStoped();
    }

    /// @notice Returns the deposited funds to the caller
    /// @dev This is a bad way to write a transaction check,
    /// but in this case we are forced not to use require because of the usdt token implementation,
    /// which does not return a result. And to keep flexibility in terms of using different ERC20,
    /// we have to do it :\
    function paybackEmergency() external onlyState(State.Emergency) {
        uint256 usdT = _usdEmergency[tx.origin];

        _usdEmergency[tx.origin] = 0;

        if (usdT == 0) {
            revert("You have no funds to withdraw!");
        }

        uint256 beforeBalance = ERC20(_usd).balanceOf(tx.origin);

        emit FundsReturned(tx.origin, usdT);

        ERC20(_usd).transfer(tx.origin, usdT);

        uint256 afterBalance = ERC20(_usd).balanceOf(tx.origin);

        require(
            beforeBalance + usdT == afterBalance,
            "PAYBACK: Something went wrong."
        );
    }

    /// @notice The function of the deposit of funds.
    /// @dev The contract attempts to debit the user's funds in the specified amount in the token whose contract is located at _usd
    /// the amount must be approved for THIS address
    /// @param amount - The number of funds the user wants to deposit
    function deposit(uint256 amount) external onlyState(State.Fundrasing) {
        uint256 commission;
        uint256[] memory rank = Ranking(RootOfPools_v013(_root).getRanks())
            .getParRankOfUser(tx.origin);
        if (rank[2] != 0) {
            commission = (amount * rank[2]) / 100; //[Min, Max, Commission]
        }
        uint256 Min = _decimals * rank[0];
        uint256 Max = _decimals * rank[1];

        require(amount >= Min, "DEPOSIT: Too little funding!");
        require(
            amount + _valueUSDList[tx.origin] <= Max,
            "DEPOSIT: Too many funds!"
        );

        require((amount) % _stepValue == 0, "DEPOSIT: Must match the step!");
        require(
            _CURRENT_VALUE + amount - commission <= _VALUE,
            "DEPOSIT: Fundraising goal exceeded!"
        );

        emit Deposit(tx.origin, amount);

        uint256 pre_balance = ERC20(_usd).balanceOf(address(this));

        require(
            ERC20(_usd).allowance(tx.origin, address(this)) >= amount,
            "DEPOSIT: ALLOW ERROR"
        );

        require(
            ERC20(_usd).transferFrom(tx.origin, address(this), amount),
            "DEPOSIT: Transfer error"
        );

        _usdEmergency[tx.origin] += amount;

        _valueUSDList[tx.origin] += amount - commission;
        _CURRENT_COMMISSION += commission;
        _CURRENT_VALUE += amount - commission;

        _listParticipants.push(tx.origin);

        require(
            pre_balance + amount == ERC20(_usd).balanceOf(address(this)),
            "DEPOSIT: Something went wrong"
        );

        if (_CURRENT_VALUE == _VALUE) {
            _state = State.WaitingToken;
            emit FundraisingClosed();
        }
    }

    /// @notice Allows you to distribute the collected funds
    /// @dev This function should be used only in case of automatic closing of the pool
    function collectFunds() external onlyOwner onlyState(State.WaitingToken) {
        require(
            _CURRENT_VALUE == _VALUE,
            "COLLECT: The funds have already been withdrawn."
        );

        _FUNDS_RAISED = _CURRENT_VALUE;
        _CURRENT_VALUE = 0;

        //Send to devs
        require(
            ERC20(_usd).transfer(_devUSDAddress, _FUNDS_RAISED),
            "COLLECT: Transfer error"
        );

        //Send to fund
        uint256 toFund = (_FUNDS_RAISED * _fundCommission) / 100;
        _fundValue = (toFund * 40) / 100;
        require(ERC20(_usd).transfer(_fundAddress, toFund - _fundValue), "");

        //Send to admin
        require(
            ERC20(_usd).transfer(
                RootOfPools_v013(_root).owner(),
                ERC20(_usd).balanceOf(address(this)) - _fundValue
            ),
            "COLLECT: Transfer error"
        );
    }

    /// @notice Closes the fundraiser and distributes the funds raised
    /// Allows you to close the fundraiser before the fundraising amount is reached
    function stopFundraising() external onlyOwner onlyState(State.Fundrasing) {
        _state = State.WaitingToken;
        _FUNDS_RAISED = _CURRENT_VALUE;
        _VALUE = _CURRENT_VALUE;
        _CURRENT_VALUE = 0;

        emit FundraisingClosed();

        //Send to devs
        require(
            ERC20(_usd).transfer(_devUSDAddress, _FUNDS_RAISED),
            "COLLECT: Transfer error"
        );

        //Send to fund
        uint256 toFund = (_FUNDS_RAISED * _fundCommission) / 100;
        _fundValue = (toFund * 40) / 100;
        require(ERC20(_usd).transfer(_fundAddress, toFund - _fundValue), "");

        //Send to admin
        require(
            ERC20(_usd).transfer(
                RootOfPools_v013(_root).owner(),
                ERC20(_usd).balanceOf(address(this)) - _fundValue
            ),
            "COLLECT: Transfer error"
        );
    }

    /// @notice Allows developers to transfer tokens for distribution to contributors
    /// @dev This function is only called from the developers address _devInteractionAddress
    /// @param tokenAddr - Developer token address
    /// @param amount - Number of tokens to distribute
    function entrustToken(address tokenAddr, uint256 amount)
        external
        onlyOwner
        onlyNotState(State.Emergency)
        onlyNotState(State.Fundrasing)
        onlyNotState(State.Pause)
    {
        require(
            tokenAddr != address(0),
            "ENTRUST: The tokenAddr must not be zero."
        );

        if (_token == address(0)) {
            _token = tokenAddr;
        } else {
            require(
                tokenAddr == _token,
                "ENTRUST: The tokens have only one contract"
            );
        }

        require(
            ERC20(tokenAddr).balanceOf(address(this)) >=
                amount + _CURRENT_VALUE_TOKEN,
            "ENTRUST: Don't have enough tokens!"
        );

        uint256 toDistribute = ((((amount *
            (_FUNDS_RAISED + _CURRENT_COMMISSION)) / 2) / _priceToken) /
            (_FUNDS_RAISED / _priceToken));

        emit TokenEntrusted(tokenAddr, amount);

        require(
            ERC20(_token).transfer(
                RootOfPools_v013(_root).owner(),
                amount - toDistribute
            ),
            "ENTRUST: Transfer error"
        );

        _state = State.TokenDistribution;
        _CURRENT_VALUE_TOKEN = ERC20(tokenAddr).balanceOf(address(this));

        _unlocks.push(toDistribute);
        _fundLock = true;
    }

    /// @notice Allows you to transfer data about pool members
    /// This is necessary to perform token distribution in another network
    /// @dev the arrays of participants and their investments must be the same size.
    /// Make sure that the order of both arrays is correct,
    /// if the order is wrong, the resulting investment table will not match reality
    /// @param usersData - Participant array
    /// @param usersAmount - The size of participants' investments
    function importTable(
        address[] calldata usersData,
        uint256[] calldata usersAmount
    ) external onlyState(State.Pause) onlyOwner returns (bool) {
        require(
            usersData.length == usersAmount.length,
            "IMPORT: The number not match!"
        );

        for (uint256 i; i < usersData.length; i++) {
            _valueUSDList[usersData[i]] = usersAmount[i];
        }

        //Not all information is transferred to save gas
        //Implications: It is not possible to fully import data from here
        //To capture all the information you need to replenish this array with the right users
        //_listParticipants = usersData;

        return true;
    }

    /// @notice Allows you to transfer data about pool members
    /// This is necessary to perform token distribution in another network
    /// @param fundsRaised - Number of funds raised
    function importFR(uint256 fundsRaised)
        external
        onlyState(State.Pause)
        onlyOwner
        returns (bool)
    {
        uint256 temp = _FUNDS_RAISED;

        _FUNDS_RAISED = fundsRaised;
        return true;
    }

    /// @notice Allows you to transfer data about pool members
    /// This is necessary to perform token distribution in another network
    /// @param collectedCommission - Number of commissions collected
    function importCC(uint256 collectedCommission)
        external
        onlyState(State.Pause)
        onlyOwner
        returns (bool)
    {
        uint256 temp = _CURRENT_COMMISSION;

        _CURRENT_COMMISSION = collectedCommission;
        return true;
    }

    /// @notice Allows you to transfer data about pool members
    /// This is necessary to perform token distribution in another network
    function closeImport()
        external
        onlyState(State.Pause)
        onlyOwner
        returns (bool)
    {
        _state = State.WaitingToken;

        return true;
    }

    /// @notice Allows users to brand the distributed tokens
    function claim() external onlyState(State.TokenDistribution) {
        require(
            _valueUSDList[tx.origin] > 0,
            "CLAIM: You have no unredeemed tokens!"
        );

        uint256 currentUnlocks = _unlocks.length;
        require(
            _openUnlocks[tx.origin] < currentUnlocks,
            "CLAIM: Additional tokens not yet unlocked"
        );

        uint256 amount;
        for (uint256 i = _openUnlocks[tx.origin]; i < currentUnlocks; i++) {
            amount += _unlocks[i];
        }
        amount = (amount * _valueUSDList[tx.origin]) / _FUNDS_RAISED;

        _openUnlocks[tx.origin] = currentUnlocks;
        _CURRENT_VALUE_TOKEN -= amount;

        uint256 pre_balance = ERC20(_token).balanceOf(address(this));

        emit Claim(tx.origin);

        require(
            ERC20(_token).transfer(tx.origin, amount),
            "CLAIM: Transfer error"
        );

        require(
            ERC20(_token).balanceOf(address(this)) == pre_balance - amount,
            "CLAIM: Something went wrong!"
        );
    }

    //TODO Add comments
    function transferShare(address user)
        external
        onlyNotState(State.Pause)
        onlyNotState(State.Fundrasing)
    {
        require(user != address(0), "SHARE: Zero address");

        require(_valueUSDList[tx.origin] != 0, "SHARE: Your volume 0");
        require(_usdEmergency[tx.origin] != 0);

        require(_valueUSDList[user] == 0, "SHARE: Not another member");
        require(_usdEmergency[user] == 0);

        _valueUSDList[user] = _valueUSDList[tx.origin];
        _usdEmergency[user] = _usdEmergency[tx.origin];

        _valueUSDList[tx.origin] = 0;
        _usdEmergency[tx.origin] = 0;
    }

    //TODO Add comments
    function getCommission() external {
        require(_fundLock, "GET: Not now");
        require(msg.sender == _fundAddress, "GET: Not you");

        uint256 temp = _fundValue;
        _fundValue = 0;

        require(
            ERC20(_usd).transfer(_fundAddress, temp),
            "GET: Something wrong"
        );
    }

    /// @notice Returns the amount of money that the user has deposited excluding the commission
    /// @param user - address user
    function myAllocation(address user) external view returns (uint256) {
        return _valueUSDList[user];
    }

    /// @notice Returns the amount of funds that the user deposited
    /// @param user - address user
    function myAllocationEmergency(address user)
        external
        view
        returns (uint256)
    {
        return _usdEmergency[user];
    }

    /// @notice Returns the number of tokens the user can take at the moment
    /// @param user - address user
    function myCurrentAllocation(address user) public view returns (uint256) {
        if (_FUNDS_RAISED == 0) {
            return 0;
        }

        uint256 amount;
        for (uint256 i = _openUnlocks[user]; i < _unlocks.length; i++) {
            amount += _unlocks[i];
        }
        amount = (amount * _valueUSDList[user]) / _FUNDS_RAISED;

        return amount;
    }

    /// @notice Auxiliary function for RootOfPools claimAll
    /// @param user - address user
    function isClaimable(address user) external view returns (bool) {
        return myCurrentAllocation(user) > 0;
    }
}


/// @title The rank contract allows you to assign a rank to users.
/// @author NotBibop
/// @notice Allows you to assign different parameters to users
/// @dev By default, the first created rank is used for users.
/// This rank can be changed using various parameter change functions.
/// Ranks are 2 arrays (name array, value array), they are extensible
/// and provide flexibility to the rank system.
/// (Don't forget about memory allocation and overuse)
///
/// EXAMPLE ==================
/// "First", ["1 param", "2 param", "3 param", "4 param"],  [1,2,3,4], True
/// "Second", ["A", "B", "C", "D"],  [4,3,2,1], True
/// EXAMPLE ==================
contract Ranking is Ownable {
    struct Rank {
        string Name;
        string[] pNames;
        uint256[] pValues;
        bool isChangeable;
    }

    //List of ranks
    Rank[] public _ranks;
    mapping(string => uint256) public _rankSequence;
    uint256 _ranksHead;

    //Table of ranks assigned to users
    mapping(address => uint256) public _rankTable;

    /// @notice Give a users the rank
    /// @dev To make it easier to change the ranks of a large number of users
    /// For the admin only
    /// @param users - an array of users to assign a rank to, rank - the name of the title to be awarded
    /// @return bool (On successful execution returns true)
    function giveRanks(address[] memory users, string memory rank)
        public
        onlyOwner
        returns (bool)
    {
        uint256 index = searchRank(rank);

        for (uint256 i = 0; i < users.length; i++) {
            _rankTable[users[i]] = index;
        }

        return true;
    }

    /// @notice Give a user the rank
    /// @dev For the admin only
    /// @param user - the address of the user to whom you want to assign a rank, rank - the name of the title to be awarded
    /// @return bool (On successful execution returns true)
    function giveRank(address user, string memory rank)
        public
        onlyOwner
        returns (bool)
    {
        uint256 index = searchRank(rank);

        _rankTable[user] = index;

        return true;
    }

    /// @notice Сreate the rank
    /// @dev For the admin only
    /// @param Name - Unique rank identifier
    /// @param pNames[] - An array of parameter names
    /// @param pValues[] - An array of parameter values
    /// @param isChangeable - Flag of rank variability
    /// @return bool (On successful execution returns true)
    function createRank(
        string memory Name,
        string[] memory pNames,
        uint256[] memory pValues,
        bool isChangeable
    ) public onlyOwner returns (bool) {
        require(
            pNames.length == pValues.length,
            "RANK: Each parameter must have a value!"
        );

        Rank memory rank = Rank(Name, pNames, pValues, isChangeable);

        _rankSequence[Name] = _ranksHead;

        _ranks.push(rank);
        _ranksHead++;
        return true;
    }

    /// @notice Сhange the rank
    /// @dev For the admin only
    /// @param Name - Unique rank identifier
    /// @param pNames[] - An array of parameter names
    /// @param pValues[] - An array of parameter values
    /// @param isChangeable - Flag of rank variability
    /// @return bool (On successful execution returns true)
    function changeRank(
        string memory Name,
        string[] memory pNames,
        uint256[] memory pValues,
        bool isChangeable
    ) public onlyOwner returns (bool) {
        require(_ranks.length > 0, "RANK: There are no ranks.");
        require(
            pNames.length == pValues.length,
            "RANK: Each parameter must have a value!"
        );

        uint256 index = searchRank(Name);
        require(
            _ranks[index].isChangeable,
            "RANK: This rank cannot be changed!"
        );

        _ranks[index] = Rank(Name, pNames, pValues, isChangeable);

        return true;
    }

    /// @notice Сhange only the names of the rank parameters
    /// @dev For the admin only
    /// If the rank is variable
    /// @param Name - Unique rank identifier
    /// @param pNames[] - An array of parameter names
    /// @return bool (On successful execution returns true)
    function changeRankParNames(string memory Name, string[] memory pNames)
        public
        onlyOwner
        returns (bool)
    {
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(
            _ranks[index].isChangeable,
            "RANK: This rank cannot be changed!"
        );
        require(
            pNames.length == _ranks[index].pNames.length,
            "RANK: Each parameter must have a value!"
        );

        _ranks[index].pNames = pNames;
        return true;
    }

    /// @notice Сhange only the values of the rank parameters
    /// @dev For the admin only
    /// If the rank is variable
    /// @param Name - Unique rank identifier
    /// @param pValues[] - An array of parameter values
    /// @return bool (On successful execution returns true)
    function changeRankParValues(string memory Name, uint256[] memory pValues)
        public
        onlyOwner
        returns (bool)
    {
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(
            _ranks[index].isChangeable,
            "RANK: This rank cannot be changed!"
        );
        require(
            pValues.length == _ranks[index].pValues.length,
            "RANK: Each parameter must have a value!"
        );

        _ranks[index].pValues = pValues;
        return true;
    }

    /// @notice Blocks rank variability
    /// @dev For the admin only
    /// If the rank is variable
    /// @param Name - Unique rank identifier
    /// @return bool (On successful execution returns true)
    function lockRank(string memory Name) public onlyOwner returns (bool) {
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(
            _ranks[index].isChangeable,
            "RANK: This rank cannot be changed!"
        );

        _ranks[index].isChangeable = false;
        return true;
    }

    /// @notice Renames the rank parameter
    /// @dev For the admin only
    /// If the rank is variable
    /// @param Name - Unique rank identifier
    /// @param NewParName - New parameter name
    /// @param NumberPar - The number of the parameter you want to change
    /// @return bool (On successful execution returns true)
    function renameRankParam(
        string memory Name,
        string memory NewParName,
        uint256 NumberPar
    ) public onlyOwner returns (bool) {
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(
            _ranks[index].isChangeable,
            "RANK: This rank cannot be changed!"
        );
        require(
            _ranks[index].pNames.length > NumberPar,
            "RANK: There is no such parameter!"
        );

        _ranks[index].pNames[NumberPar] = NewParName;
        return true;
    }

    /// @notice Change the rank parameter
    /// @dev For the admin only
    /// If the rank is variable
    /// @param Name - Unique rank identifier
    /// @param NewValue - New parameter value
    /// @param NumberPar - The number of the parameter you want to change
    /// @return bool (On successful execution returns true)
    function changeRankParam(
        string memory Name,
        uint32 NewValue,
        uint256 NumberPar
    ) public onlyOwner returns (bool) {
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(
            _ranks[index].isChangeable,
            "RANK: This rank cannot be changed!"
        );
        require(
            _ranks[index].pNames.length > NumberPar,
            "RANK: There is no such parameter!"
        );

        _ranks[index].pValues[NumberPar] = NewValue;
        return true;
    }

    /// @notice Renames the rank
    /// @dev For the admin only
    /// If the rank is variable
    /// @param Name - Unique rank identifier
    /// @param NewName - New rank name
    /// @return bool (On successful execution returns true)
    function renameRank(string memory Name, string memory NewName)
        public
        onlyOwner
        returns (bool)
    {
        require(_ranks.length > 0, "RANK: There are no ranks.");

        uint256 index = searchRank(Name);
        require(
            _ranks[index].isChangeable,
            "RANK: This rank cannot be changed!"
        );

        _ranks[index].Name = NewName;

        _rankSequence[Name] = 0;
        _rankSequence[NewName] = index;

        return true;
    }

    /// @notice Searches for a rank by its name
    /// @dev For internal calls only
    /// @param Name - Unique rank identifier
    /// @return uint256 (Returns the number of the title you are looking for, or discards Rank not found)
    function searchRank(string memory Name) internal view returns (uint256) {
        uint256 temp = _rankSequence[Name];
        if (temp < _ranksHead) {
            return temp;
        }

        revert("RANK: There is no such rank!");
    }

    //View Functions

    /// @notice Shows the ranks
    /// @dev Read-only calls
    /// @return Rank[]
    function showRanks() public view returns (Rank[] memory) {
        require(_ranks.length > 0, "RANK: There are no ranks.");
        return _ranks;
    }

    /// @notice Shows the ranks parameters
    /// @dev Read-only calls
    /// @param Name - Rank name
    /// @return string Name
    /// string[] Parameters names
    /// uint32[] Parameters values
    /// bool - is Changeable?
    function showRank(string memory Name)
        public
        view
        returns (
            string memory,
            string[] memory,
            uint256[] memory,
            bool
        )
    {
        return (
            _ranks[searchRank(Name)].Name,
            _ranks[searchRank(Name)].pNames,
            _ranks[searchRank(Name)].pValues,
            _ranks[searchRank(Name)].isChangeable
        );
    }

    /// @notice Shows the ranks parameters
    /// @dev Read-only calls
    /// Saves gas by not using rank names
    /// @param Number - Rank number in the ranks array
    /// @return string Name
    /// string[] Parameters names
    /// uint32[] Parameters values
    /// bool - is Changeable?
    function showRankOfNumber(uint256 Number)
        public
        view
        returns (
            string memory,
            string[] memory,
            uint256[] memory,
            bool
        )
    {
        require(_ranks.length > Number, "RANK: There are no ranks.");
        return (
            _ranks[Number].Name,
            _ranks[Number].pNames,
            _ranks[Number].pValues,
            _ranks[Number].isChangeable
        );
    }

    /// @notice Returns the user's rank
    /// @dev Read-only calls
    /// @param user - User address
    /// @return string Name
    /// string[] Parameters names
    /// uint32[] Parameters values
    /// bool - is Changeable?
    function getRank(address user)
        public
        view
        returns (
            string memory,
            string[] memory,
            uint256[] memory,
            bool
        )
    {
        return (
            _ranks[_rankTable[user]].Name,
            _ranks[_rankTable[user]].pNames,
            _ranks[_rankTable[user]].pValues,
            _ranks[_rankTable[user]].isChangeable
        );
    }

    /// @notice Returns the names of the rank parameters
    /// @dev Read-only calls
    /// @param Name - Rank name
    /// @return string Name
    /// string[] Parameters names
    function getNameParRank(string memory Name)
        public
        view
        returns (string[] memory)
    {
        return _ranks[searchRank(Name)].pNames;
    }

    /// @notice Returns the values of the rank parameters
    /// @dev Read-only calls
    /// @param Name - Rank name
    /// @return string Name
    /// uint23[] Parameters values
    function getParRank(string memory Name)
        public
        view
        returns (uint256[] memory)
    {
        return _ranks[searchRank(Name)].pValues;
    }

    /// @notice Returns the current user parameters
    /// @dev Read-only calls
    /// @param user - User address
    /// @return uint32[] Parameters values
    function getParRankOfUser(address user)
        public
        view
        returns (uint256[] memory)
    {
        return _ranks[_rankTable[user]].pValues;
    }
}


contract TransparentProxy is Proxy {
    address public implementation;

    constructor(address Implementation) {
        implementation = Implementation;
    }

    function _implementation() internal view override returns (address) {
        return implementation;
    }
}