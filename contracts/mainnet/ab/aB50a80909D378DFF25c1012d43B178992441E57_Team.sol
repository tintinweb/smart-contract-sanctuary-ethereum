/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/proxy/Clones.sol


// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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

// File: @openzeppelin/contracts/utils/math/Math.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Flat.sol

//SPDX-License-Identifier: GNU GPLv3
pragma solidity ^0.8.2;







/// @title The root of the poole tree. Allows you to close control of a large
/// number of pools to 1 address. Simplifies user interaction with a large number of pools.
/// @author Nethny
/// @dev Must be the owner of child contracts, to short-circuit the administrative
/// rights to one address.
contract RootOfPools_v2 is Initializable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using Strings for uint256;

    struct Pool {
        address pool;
        string name;
    }

    Pool[] public Pools;

    mapping(string => address) private _poolsTable;

    address public _usdAddress;
    address public _rankingAddress;

    address[] public Images;

    mapping(address => bool) private _imageTable;

    address public _marketing;
    address public _marketingWallet;

    address public _team;

    function setMarketing(address mark) public onlyOwner {
        _marketing = mark;
    }

    function setTeam(address team) public onlyOwner {
        _team = team;
    }

    function setMarketingWallet(address mark) public onlyOwner {
        _marketingWallet = mark;
    }

    event PoolCreated(string name, address pool);
    event ImageAdded(address image);
    event Response(address to, bool success, bytes data);

    modifier shouldExist(string calldata name) {
        require(
            _poolsTable[name] != address(0),
            "ROOT: Selected pool does not exist!"
        );
        _;
    }

    /// @notice Replacement of the constructor to implement the proxy
    function initialize(
        address usdAddress,
        address rankingAddress
    ) external initializer {
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
        require(_imageTable[image] != true);

        Images.push(image);
        _imageTable[image] = true;

        emit ImageAdded(image);
    }

    /// @notice Returns the linked branch contracts
    function getPools() external view returns (Pool[] memory) {
        return Pools;
    }

    function getPool(string calldata _name) external view returns (address) {
        for (uint256 i = 0; i < Pools.length; i++) {
            if (
                keccak256(abi.encodePacked(Pools[i].name)) ==
                keccak256(abi.encodePacked(_name))
            ) {
                return Pools[i].pool;
            }
        }
        return address(0);
    }

    /// @notice Allows you to attach a new pool (branch contract)
    /// @dev Don't forget to run the init function
    function createPool(
        string calldata name,
        uint256 imageNumber,
        bytes calldata dataIn
    ) external onlyOwner {
        require(
            imageNumber <= Images.length,
            "ROOT: Such an image does not exist"
        );
        require(
            _poolsTable[name] == address(0),
            "ROOT: Pool with this name already exists!"
        );

        address pool = Clones.clone(Images[imageNumber]);

        (bool success, bytes memory data) = pool.call(dataIn);

        emit Response(pool, success, data);

        _poolsTable[name] = pool;

        Pool memory poolT = Pool(pool, name);
        Pools.push(poolT);

        emit PoolCreated(name, pool);
    }

    function Calling(address dst, bytes calldata dataIn) external onlyOwner {
        (bool success, bytes memory data) = dst.call(dataIn);

        emit Response(dst, success, data);
    }

    function deposit(
        string calldata name,
        uint256 amount
    ) external shouldExist(name) {
        BranchOfPools(_poolsTable[name]).deposit(amount);
    }

    function paybackEmergency(string calldata name) external shouldExist(name) {
        BranchOfPools(_poolsTable[name]).paybackEmergency();
    }

    function claimName(string calldata name) external shouldExist(name) {
        BranchOfPools(_poolsTable[name]).claim();
    }

    function claimAddress(address pool) internal {
        require(pool != address(0), "ROOT: Selected pool does not exist!");

        BranchOfPools(pool).claim();
    }

    //TODO
    function prepClaimAll(
        address user
    ) external view returns (address[] memory pools) {
        address[] memory out;
        for (uint256 i; i < Pools.length; i++) {
            if (BranchOfPools(Pools[i].pool).isClaimable(user)) {
                out[i] = Pools[i].pool;
            }
        }

        return pools;
    }

    //TODO
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
}







/// @title The pool's subsidiary contract for fundraising.
/// This contract collects funds, distributes them, and charges fees
/// @author Nethny
/// @dev This contract pulls commissions and other parameters from the Ranking contract.
/// Important: Agree on the structure of the ranking parameters and this contract!
/// Otherwise the calculations can be wrong!
contract BranchOfPools is Initializable {
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

    address public _owner;
    address private _root;

    uint256 public _stepValue;
    uint256 public _VALUE;
    uint256 private _decimals;
    uint256 public _outCommission;
    uint256 public _preSend;

    uint256 public _CURRENT_VALUE;
    uint256 public _FUNDS_RAISED;
    uint256 public _CURRENT_COMMISSION;
    uint256 public _CURRENT_VALUE_TOKEN;
    uint256 public _DISTRIBUTED_TOKEN;
    uint256 public _TOKEN_COMMISSION;

    mapping(address => uint256) public _valueUSDList;
    mapping(address => uint256) public _usdEmergency;
    mapping(address => uint256) public _issuedTokens;
    mapping(address => bool) public _withoutCommission;

    address[] public _listParticipants;

    address public _usd;
    address public _token;
    address public _devUSDAddress;

    address public _fundAddress;
    bool private _fundLock = false;
    uint256 private _fundValue;
    uint256 public _fundCommission;

    bool private _getCommissionFlag;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: Only owner");
        _;
    }

    /*function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _owner = newOwner;
    }*/

    /// @notice Assigns the necessary values to the variables
    /// @dev Just a constructor
    /// You need to call init()
    /// @param Root - RootOfPools contract address
    /// @param VALUE - The target amount of funds we collect
    /// @param Step - The step with which we raise funds
    /// @param devUSDAddress - The address of the developers to which they will receive the collected funds
    function init(
        address Root,
        uint256 VALUE,
        uint256 Step,
        address devUSDAddress,
        address fundAddress,
        uint256 fundCommission,
        uint256 outCommission,
        address tokenUSD
    ) external initializer {
        require(Root != address(0), "The root address must not be zero.");
        require(
            devUSDAddress != address(0),
            "The devUSDAddress must not be zero."
        );

        _owner = msg.sender;
        _root = Root;
        _usd = tokenUSD;
        _decimals = 10 ** ERC20(_usd).decimals();
        _VALUE = VALUE * _decimals;
        _stepValue = Step * _decimals;
        _devUSDAddress = devUSDAddress;
        _fundAddress = fundAddress;
        _fundCommission = fundCommission;
        _outCommission = outCommission;
    }

    /// @notice Changes the target amount of funds we collect
    /// @param value - the new target amount of funds raised
    function changeTargetValue(
        uint256 value
    )
        external
        onlyOwner
        onlyNotState(State.TokenDistribution)
        onlyNotState(State.WaitingToken)
    {
        _VALUE = value;
    }

    /// @notice Changes the step with which we raise funds
    /// @param step - the new step
    function changeStepValue(
        uint256 step
    )
        external
        onlyOwner
        onlyNotState(State.TokenDistribution)
        onlyNotState(State.WaitingToken)
    {
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

    //TODO
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

    //TODO
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
        uint256[] memory rank = Ranking(RootOfPools_v2(_root)._rankingAddress())
            .getParRankOfUser(tx.origin);
        if (rank[2] != 0) {
            commission = (amount * rank[2]) / 100; //[Min, Max, Commission]
        }
        uint256 Min = _decimals * rank[0];
        uint256 Max = _decimals * rank[1];

        if (rank[2] == 0) {
            _withoutCommission[tx.origin] = true;
        }

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

        if (_valueUSDList[tx.origin] == 0) {
            _listParticipants.push(tx.origin);
        }

        _valueUSDList[tx.origin] += amount - commission;
        _CURRENT_COMMISSION += commission;
        _CURRENT_VALUE += amount - commission;

        require(
            pre_balance + amount == ERC20(_usd).balanceOf(address(this)),
            "DEPOSIT: Something went wrong"
        );

        if (_CURRENT_VALUE == _VALUE) {
            _state = State.WaitingToken;
            emit FundraisingClosed();
        }
    }

    function preSend(
        uint256 amount
    ) external onlyOwner onlyState(State.Fundrasing) {
        require(amount < _CURRENT_VALUE - _preSend);

        _preSend += amount;

        require(
            ERC20(_usd).transfer(_devUSDAddress, amount),
            "COLLECT: Transfer error"
        );
    }

    //TODO
    /// @notice Closes the fundraiser and distributes the funds raised
    /// Allows you to close the fundraiser before the fundraising amount is reached
    function stopFundraising()
        external
        onlyOwner
        onlyNotState(State.Pause)
        onlyNotState(State.TokenDistribution)
        onlyNotState(State.Emergency)
    {
        if (_state == State.Fundrasing) {
            _state = State.WaitingToken;
            _FUNDS_RAISED = _CURRENT_VALUE;
            _VALUE = _CURRENT_VALUE;
            _CURRENT_VALUE = 0;

            emit FundraisingClosed();
        } else {
            require(
                _CURRENT_VALUE == _VALUE,
                "COLLECT: The funds have already been withdrawn."
            );

            _FUNDS_RAISED = _CURRENT_VALUE;
            _CURRENT_VALUE = 0;
        }

        //Send to devs
        require(
            ERC20(_usd).transfer(_devUSDAddress, _FUNDS_RAISED - _preSend),
            "COLLECT: Transfer error"
        );
    }

    /// @notice Allows developers to transfer tokens for distribution to contributors
    /// @dev This function is only called from the developers address _devInteractionAddress
    /// @param tokenAddr - Developer token address
    function entrustToken(
        address tokenAddr
    )
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

        _state = State.TokenDistribution;
    }

    //TODO
    /// @notice Allows users to brand the distributed tokens
    function claim() external onlyState(State.TokenDistribution) {
        require(
            _usdEmergency[tx.origin] > 0,
            "CLAIM: You have no unredeemed tokens!"
        );

        uint256 amount;

        uint256 currentTokenBalance = ERC20(_token).balanceOf(address(this));

        if (_CURRENT_VALUE_TOKEN < currentTokenBalance) {
            _CURRENT_VALUE_TOKEN += currentTokenBalance - _CURRENT_VALUE_TOKEN;
        }

        if (_withoutCommission[tx.origin]) {
            amount =
                (
                    ((_usdEmergency[tx.origin] *
                        (_CURRENT_VALUE_TOKEN + _DISTRIBUTED_TOKEN)) /
                        _FUNDS_RAISED)
                ) -
                _issuedTokens[tx.origin];
        } else {
            amount =
                ((((_usdEmergency[tx.origin] *
                    (_CURRENT_VALUE_TOKEN + _DISTRIBUTED_TOKEN)) /
                    _FUNDS_RAISED) * _outCommission) / 100) -
                _issuedTokens[tx.origin];
        }

        _issuedTokens[tx.origin] += amount;
        _DISTRIBUTED_TOKEN += amount;
        _CURRENT_VALUE_TOKEN -= amount;

        if (amount > 0) {
            emit Claim(tx.origin);
            uint256 pre_balance = ERC20(_token).balanceOf(address(this));

            require(
                ERC20(_token).transfer(tx.origin, amount),
                "CLAIM: Transfer error"
            );

            require(
                ERC20(_token).balanceOf(address(this)) == pre_balance - amount,
                "CLAIM: Something went wrong!"
            );
        }

        if (_fundLock == false) {
            _fundLock = true;
            //getCommission();
        }
    }

    //TODO Add comments
    function getCommission()
        public
        onlyNotState(State.Fundrasing)
        onlyNotState(State.Pause)
        onlyNotState(State.Emergency)
    {
        if (
            ((_state == State.WaitingToken) ||
                (_state == State.TokenDistribution)) && (!_getCommissionFlag)
        ) {
            //Send to fund
            uint256 toFund = (_FUNDS_RAISED * _fundCommission) / 100;
            _fundValue = (toFund * 40) / 100;
            require(
                ERC20(_usd).transfer(_fundAddress, toFund - _fundValue),
                "COLLECT: Transfer error"
            );

            //Send to admin
            uint256 amount = ERC20(_usd).balanceOf(address(this)) - _fundValue;
            require(
                ERC20(_usd).transfer(RootOfPools_v2(_root).owner(), amount / 2),
                "COLLECT: Transfer error"
            );

            _getCommissionFlag = true;
        }

        if (_fundLock) {
            if (_fundValue != 0) {
                uint256 balance = ERC20(_usd).balanceOf(address(this));
                if (balance != 0) {
                    uint256 amount = balance - _fundValue;
                    if (amount != 0) {
                        require(
                            ERC20(_usd).transfer(
                                RootOfPools_v2(_root)._marketingWallet(),
                                ERC20(_usd).balanceOf(address(this)) -
                                    _fundValue
                            ),
                            "COLLECT: Transfer error"
                        );
                    }

                    uint256 temp = _fundValue;
                    _fundValue = 0;

                    if (temp != 0) {
                        require(
                            ERC20(_usd).transfer(_fundAddress, temp),
                            "GET: Transfer error"
                        );
                    }
                }
            }

            //========================================================== TOKЕN
            uint256 temp = 0;
            uint256 value = _CURRENT_VALUE_TOKEN + _DISTRIBUTED_TOKEN;
            for (uint256 i = 0; i < _listParticipants.length; i++) {
                address user = _listParticipants[i];
                if (_withoutCommission[user]) {
                    temp += (((_usdEmergency[user] * value) / _FUNDS_RAISED));
                } else {
                    temp += ((((_usdEmergency[user] * value) / _FUNDS_RAISED) *
                        _outCommission) / 100);
                }
            }

            uint256 tmp = ((_FUNDS_RAISED + _CURRENT_COMMISSION) * 15) / 100;

            uint256 toMarketing = ((tmp * value) / _FUNDS_RAISED) -
                _issuedTokens[address(0)];
            _issuedTokens[address(0)] += toMarketing;

            /*//_mamrktingOut == _issuedTokens[address(0)]
            uint256 toMarketing = ((value * 15) / 100) -
                _issuedTokens[address(0)]; //A?
            _issuedTokens[address(0)] += toMarketing;*/

            tmp = ((_FUNDS_RAISED + _CURRENT_COMMISSION) * 2) / 100;
            uint256 toTeam = ((tmp * value) / _FUNDS_RAISED) -
                _issuedTokens[address(1)];

            //uint256 toTeam = ((value * 2) / 100) - _issuedTokens[address(1)]; //B?
            _issuedTokens[address(1)] += toTeam;

            _DISTRIBUTED_TOKEN += toMarketing + toTeam;
            _CURRENT_VALUE_TOKEN -= (toMarketing + toTeam);

            temp =
                value -
                (temp + _issuedTokens[address(0)] + _issuedTokens[address(1)]) -
                _issuedTokens[address(this)];
            _issuedTokens[address(this)] += temp;

            if (toTeam != 0) {
                require(
                    ERC20(_token).transfer(
                        RootOfPools_v2(_root)._team(),
                        toTeam //точно?
                    ),
                    "GET: Transfer error"
                );
            }

            if (toMarketing != 0) {
                require(
                    ERC20(_token).transfer(
                        RootOfPools_v2(_root)._marketing(),
                        toMarketing //точно?
                    ),
                    "GET: Transfer error"
                );
            }
            //temp =
            if (temp != 0) {
                _DISTRIBUTED_TOKEN += temp;
                _CURRENT_VALUE_TOKEN -= temp;
                require(
                    ERC20(_token).transfer(
                        RootOfPools_v2(_root).owner(),
                        temp / 2
                    ),
                    "GET: Transfer error"
                );

                require(
                    ERC20(_token).transfer(
                        RootOfPools_v2(_root)._marketingWallet(),
                        temp / 2
                    ),
                    "GET: Transfer error"
                );
            }
        }
    }

    /// @notice Returns the amount of money that the user has deposited excluding the commission
    /// @param user - address user
    function myAllocation(address user) external view returns (uint256) {
        return _valueUSDList[user];
    }

    /// @notice Returns the amount of funds that the user deposited
    /// @param user - address user
    function myAllocationEmergency(
        address user
    ) external view returns (uint256) {
        return _usdEmergency[user];
    }

    /// @notice Returns the number of tokens the user can take at the moment
    /// @param user - address user
    function myCurrentAllocation(address user) public view returns (uint256) {
        if (_FUNDS_RAISED == 0) {
            return 0;
        }

        uint256 amount;
        if (_withoutCommission[user]) {
            amount =
                (
                    ((_usdEmergency[user] *
                        (_CURRENT_VALUE_TOKEN + _DISTRIBUTED_TOKEN)) /
                        _FUNDS_RAISED)
                ) -
                _issuedTokens[user];
        } else {
            amount =
                ((((_usdEmergency[user] *
                    (_CURRENT_VALUE_TOKEN + _DISTRIBUTED_TOKEN)) /
                    _FUNDS_RAISED) * _outCommission) / 100) -
                _issuedTokens[user];
        }

        return amount;
    }

    /// @notice Auxiliary function for RootOfPools claimAll
    /// @param user - address user
    function isClaimable(address user) external view returns (bool) {
        return myCurrentAllocation(user) > 0;
    }
}







/// @title The pool's subsidiary contract for fundraising.
/// This contract collects funds, distributes them, and charges fees
/// @author Nethny
/// @dev This contract pulls commissions and other parameters from the Ranking contract.
/// Important: Agree on the structure of the ranking parameters and this contract!
/// Otherwise the calculations can be wrong!
contract BranchOfPools_import is Initializable {
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

    address public _owner;
    address private _root;

    uint256 public _stepValue;
    uint256 public _VALUE;
    uint256 private _decimals;
    uint256 public _outCommission;
    uint256 public _preSend;

    uint256 public _CURRENT_COMMISSION;
    uint256 public _CURRENT_VALUE;
    uint256 public _FUNDS_RAISED;
    uint256 public _CURRENT_VALUE_TOKEN;
    uint256 public _DISTRIBUTED_TOKEN;
    uint256 public _TOKEN_COMMISSION;

    mapping(address => uint256) public _valueUSDList;
    mapping(address => uint256) public _usdEmergency;
    mapping(address => uint256) public _issuedTokens;
    mapping(address => bool) public _withoutCommission;

    address[] public _listParticipants;

    address public _usd;
    address public _token;
    address public _devUSDAddress;

    address public _fundAddress;
    bool private _fundLock = false;
    uint256 private _fundValue;
    uint256 public _fundCommission;

    bool private _getCommissionFlag;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: Only owner");
        _;
    }

    /// @notice Assigns the necessary values to the variables
    /// @dev Just a constructor
    /// You need to call init()
    /// @param Root - RootOfPools contract address
    /// @param VALUE - The target amount of funds we collect
    /// @param Step - The step with which we raise funds
    /// @param devUSDAddress - The address of the developers to which they will receive the collected funds
    function init(
        address Root,
        uint256 VALUE,
        uint256 Step,
        address devUSDAddress,
        address fundAddress,
        uint256 fundCommission,
        uint256 outCommission,
        address tokenUSD
    ) external initializer {
        require(Root != address(0), "The root address must not be zero.");
        require(
            devUSDAddress != address(0),
            "The devUSDAddress must not be zero."
        );

        _owner = msg.sender;
        _root = Root;
        _usd = tokenUSD;
        _decimals = 10 ** ERC20(_usd).decimals();
        _VALUE = VALUE * _decimals;
        _stepValue = Step * _decimals;
        _devUSDAddress = devUSDAddress;
        _fundAddress = fundAddress;
        _fundCommission = fundCommission;
        _outCommission = outCommission;
    }

    modifier onlyState(State state) {
        require(_state == state, "STATE: It's impossible to do it now.");
        _;
    }

    modifier onlyNotState(State state) {
        require(_state != state, "STATE: It's impossible to do it now.");
        _;
    }

    //Import

    //TODO
    /// @notice Allows you to transfer data about pool members
    /// This is necessary to perform token distribution in another network
    /// @dev the arrays of participants and their investments must be the same size.
    /// Make sure that the order of both arrays is correct,
    /// if the order is wrong, the resulting investment table will not match reality
    /// @param usersData - Participant array
    /// @param usersAmount - The size of participants' investments
    function importTable(
        address[] calldata usersData,
        uint256[] calldata usersAmount,
        bool[] calldata commissions
    ) external onlyState(State.Pause) onlyOwner returns (bool) {
        require(
            usersData.length == usersAmount.length,
            "IMPORT: The number not match!"
        );

        for (uint256 i; i < usersData.length; i++) {
            _usdEmergency[usersData[i]] += usersAmount[i];
            _withoutCommission[usersData[i]] = commissions[i];
            _listParticipants.push(usersData[i]);
        }

        return true;
    }

    //TODO
    /// @notice Allows you to transfer data about pool members
    /// This is necessary to perform token distribution in another network
    /// @param fundsRaised - Number of funds raised
    function importFR(
        uint256 fundsRaised
    ) external onlyState(State.Pause) onlyOwner returns (bool) {
        _FUNDS_RAISED = fundsRaised;
        return true;
    }

    function importCC(
        uint256 currentCommission
    ) external onlyState(State.Pause) onlyOwner returns (bool) {
        _CURRENT_COMMISSION = currentCommission;
        return true;
    }

    //TODO
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

    //End Import

    /// @notice Allows developers to transfer tokens for distribution to contributors
    /// @dev This function is only called from the developers address _devInteractionAddress
    /// @param tokenAddr - Developer token address
    function entrustToken(
        address tokenAddr
    )
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

        _state = State.TokenDistribution;
    }

    /// @notice Allows users to brand the distributed tokens
    function claim() external onlyState(State.TokenDistribution) {
        require(
            _usdEmergency[tx.origin] > 0,
            "CLAIM: You have no unredeemed tokens!"
        );

        uint256 amount;

        uint256 currentTokenBalance = ERC20(_token).balanceOf(address(this));

        if (_CURRENT_VALUE_TOKEN < currentTokenBalance) {
            _CURRENT_VALUE_TOKEN += currentTokenBalance - _CURRENT_VALUE_TOKEN;
        }

        if (_withoutCommission[tx.origin]) {
            amount =
                (
                    ((_usdEmergency[tx.origin] *
                        (_CURRENT_VALUE_TOKEN + _DISTRIBUTED_TOKEN)) /
                        _FUNDS_RAISED)
                ) -
                _issuedTokens[tx.origin];
        } else {
            amount =
                ((((_usdEmergency[tx.origin] *
                    (_CURRENT_VALUE_TOKEN + _DISTRIBUTED_TOKEN)) /
                    _FUNDS_RAISED) * _outCommission) / 100) -
                _issuedTokens[tx.origin];
        }

        _issuedTokens[tx.origin] += amount;
        _DISTRIBUTED_TOKEN += amount;
        _CURRENT_VALUE_TOKEN -= amount;

        if (amount > 0) {
            emit Claim(tx.origin);
            uint256 pre_balance = ERC20(_token).balanceOf(address(this));

            require(
                ERC20(_token).transfer(tx.origin, amount),
                "CLAIM: Transfer error"
            );

            require(
                ERC20(_token).balanceOf(address(this)) == pre_balance - amount,
                "CLAIM: Something went wrong!"
            );
        }

        if (_fundLock == false) {
            _fundLock = true;
            //getCommission();
        }
    }

    //TODO Add comments
    function getCommission()
        public
        onlyNotState(State.Fundrasing)
        onlyNotState(State.Pause)
        onlyNotState(State.Emergency)
    {
        if (_fundLock) {
            uint256 temp = 0;
            uint256 value = _CURRENT_VALUE_TOKEN + _DISTRIBUTED_TOKEN;
            for (uint256 i = 0; i < _listParticipants.length; i++) {
                address user = _listParticipants[i];
                if (_withoutCommission[user]) {
                    temp += (((_usdEmergency[user] * value) / _FUNDS_RAISED));
                } else {
                    temp += ((((_usdEmergency[user] * value) / _FUNDS_RAISED) *
                        _outCommission) / 100);
                }
            }

            uint256 tmp = ((_FUNDS_RAISED + _CURRENT_COMMISSION) * 15) / 100;

            uint256 toMarketing = ((tmp * value) / _FUNDS_RAISED) -
                _issuedTokens[address(0)];
            _issuedTokens[address(0)] += toMarketing;

            /*//_mamrktingOut == _issuedTokens[address(0)]
            uint256 toMarketing = ((value * 15) / 100) -
                _issuedTokens[address(0)]; //A?
            _issuedTokens[address(0)] += toMarketing;*/

            tmp = ((_FUNDS_RAISED + _CURRENT_COMMISSION) * 2) / 100;
            uint256 toTeam = ((tmp * value) / _FUNDS_RAISED) -
                _issuedTokens[address(1)];

            //uint256 toTeam = ((value * 2) / 100) - _issuedTokens[address(1)]; //B?
            _issuedTokens[address(1)] += toTeam;

            _DISTRIBUTED_TOKEN += toMarketing + toTeam;
            _CURRENT_VALUE_TOKEN -= (toMarketing + toTeam);

            temp =
                value -
                (temp + _issuedTokens[address(0)] + _issuedTokens[address(1)]) -
                _issuedTokens[address(this)];
            _issuedTokens[address(this)] += temp;

            if (toTeam != 0) {
                require(
                    ERC20(_token).transfer(
                        RootOfPools_v2(_root)._team(),
                        toTeam //точно?
                    ),
                    "GET: Transfer error"
                );
            }

            if (toMarketing != 0) {
                require(
                    ERC20(_token).transfer(
                        RootOfPools_v2(_root)._marketing(),
                        toMarketing //точно?
                    ),
                    "GET: Transfer error"
                );
            }
            //temp =
            if (temp != 0) {
                _DISTRIBUTED_TOKEN += temp;
                _CURRENT_VALUE_TOKEN -= temp;
                require(
                    ERC20(_token).transfer(
                        RootOfPools_v2(_root).owner(),
                        temp / 2
                    ),
                    "GET: Transfer error"
                );

                require(
                    ERC20(_token).transfer(
                        RootOfPools_v2(_root)._marketingWallet(),
                        temp / 2
                    ),
                    "GET: Transfer error"
                );
            }
        }
    }

    /// @notice Returns the amount of money that the user has deposited excluding the commission
    /// @param user - address user
    function myAllocation(address user) external view returns (uint256) {
        return _valueUSDList[user];
    }

    /// @notice Returns the amount of funds that the user deposited
    /// @param user - address user
    function myAllocationEmergency(
        address user
    ) external view returns (uint256) {
        return _usdEmergency[user];
    }

    /// @notice Returns the number of tokens the user can take at the moment
    /// @param user - address user
    function myCurrentAllocation(address user) public view returns (uint256) {
        if (_FUNDS_RAISED == 0) {
            return 0;
        }

        uint256 amount;
        if (_withoutCommission[user]) {
            amount =
                (
                    ((_usdEmergency[user] *
                        (_CURRENT_VALUE_TOKEN + _DISTRIBUTED_TOKEN)) /
                        _FUNDS_RAISED)
                ) -
                _issuedTokens[user];
        } else {
            amount =
                ((((_usdEmergency[user] *
                    (_CURRENT_VALUE_TOKEN + _DISTRIBUTED_TOKEN)) /
                    _FUNDS_RAISED) * _outCommission) / 100) -
                _issuedTokens[user];
        }

        return amount;
    }

    /// @notice Auxiliary function for RootOfPools claimAll
    /// @param user - address user
    function isClaimable(address user) external view returns (bool) {
        return myCurrentAllocation(user) > 0;
    }
}


/// @title The rank contract allows you to assign a rank to users.
/// @author Nethny
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




contract Marketing is Ownable {
    struct User {
        address userAdr;
        uint256 amount;
    }

    struct Project {
        User[] users;
        mapping(address => uint256) withdrawn;
        uint256 totalWithdrawn;
        uint256 currentTotalValue;
        uint256 totalValue;
        address token;
        //======================//
        bool isClosed;
        uint256 closingTimeStamp;
    }

    address globalAdmin;

    mapping(string => Project) Projects;
    string[] public listProjects;

    constructor(address _globalAdmin) {
        globalAdmin = _globalAdmin;
    }

    function findUser(
        string calldata _name,
        address _user
    ) internal view returns (User memory) {
        Project storage project = Projects[_name];
        User memory user;

        for (uint256 i = 0; i < project.users.length; i++) {
            if (project.users[i].userAdr == _user) {
                user = project.users[i];
                return user;
            }
        }

        return user;
    }

    function getProject(
        string calldata _name
    )
        public
        view
        returns (
            uint256 totalWithdrawn,
            uint256 currentTotalValue,
            uint256 totalValue,
            address token,
            bool isClosed,
            uint256 closingTimeStamp
        )
    {
        return (
            Projects[_name].totalWithdrawn,
            Projects[_name].currentTotalValue,
            Projects[_name].totalValue,
            Projects[_name].token,
            Projects[_name].isClosed,
            Projects[_name].closingTimeStamp
        );
    }

    function getUserAmount(
        string calldata _name,
        address _user
    ) public view returns (uint256) {
        return findUser(_name, _user).amount;
    }

    function getTotalValue(
        string calldata _name
    ) public view returns (uint256) {
        return Projects[_name].totalValue;
    }

    function getToken(string calldata _name) public view returns (address) {
        return Projects[_name].token;
    }

    function addProject(
        string calldata _name,
        uint256 _totalValue,
        uint256 _closingTimeStamp,
        address _token
    ) public onlyOwner {
        require(Projects[_name].users.length == 0, "Such a project exists");

        Projects[_name].totalValue = _totalValue;
        Projects[_name].closingTimeStamp = _closingTimeStamp;
        Projects[_name].isClosed = false;
        Projects[_name].token = _token;

        listProjects.push(_name);
    }

    function setProjectAmounts(
        string calldata _name,
        address[] calldata _users,
        uint256[] calldata _amounts
    ) public onlyOwner {
        require(!Projects[_name].isClosed, "This project may not be modified");
        require(_users.length == _amounts.length, "Array length violation");

        for (uint256 i = 0; i < _users.length; i++) {
            User memory user;
            user.userAdr = _users[i];
            user.amount = _amounts[i];

            Projects[_name].users.push(user);
        }
    }

    function closeProject(string calldata _name) public onlyOwner {
        Project storage project = Projects[_name];
        uint256 total = 0;
        for (uint256 i = 0; i < project.users.length; i++) {
            total += project.users[i].amount;
        }

        require(
            project.totalValue == total,
            "The import data do not match the specified"
        );

        Projects[_name].isClosed = true;
    }

    function claim(string calldata _name) public {
        Project storage project = Projects[_name];
        require(project.users.length != 0, "Unknown project");
        User memory user = findUser(_name, msg.sender);
        if (user.userAdr == address(0)) {
            return;
        }

        uint256 amount = user.amount;
        require(amount != 0, "You are not a participant");

        uint256 totalValue = project.totalValue;
        uint256 currentValue = ERC20(project.token).balanceOf(address(this));

        if (currentValue + project.totalWithdrawn > project.currentTotalValue) {
            Projects[_name].currentTotalValue +=
                (currentValue + project.totalWithdrawn) -
                project.currentTotalValue;
        }

        uint256 toSend = ((Projects[_name].currentTotalValue * amount) /
            totalValue) - project.withdrawn[user.userAdr];

        Projects[_name].withdrawn[user.userAdr] += toSend;
        Projects[_name].totalWithdrawn += toSend;

        require(
            ERC20(project.token).transfer(msg.sender, toSend),
            "Unknown sending error"
        );
    }

    function withdrawFunds() public onlyOwner {
        for (uint256 i = 0; i < listProjects.length; i++) {
            if (Projects[listProjects[i]].closingTimeStamp < block.timestamp) {
                uint256 balance = ERC20(Projects[listProjects[i]].token)
                    .balanceOf(address(this));

                ERC20(Projects[listProjects[i]].token).transfer(
                    globalAdmin,
                    balance
                );
            }
        }
    }
}




contract Team is Ownable {
    struct Member {
        address[] addresses;
        uint256 usefulness; //Part in %
        bool isLock;
    }

    struct Project {
        mapping(address => uint256) withdrawn;
        uint256 currentTotalValue;
        uint256 currentBalance;
    }

    mapping(string => Member) members;
    mapping(address => Project) projects;
    string[] listMembers;

    function getMember(
        string calldata _name
    ) public view returns (Member memory) {
        return members[_name];
    }

    //Member part
    function addMember(
        string calldata _name,
        address _memb,
        uint256 _usefulness,
        bool _isLock
    ) public onlyOwner {
        require(!members[_name].isLock);
        members[_name].addresses.push(_memb);
        members[_name].usefulness = _usefulness;
        members[_name].isLock = _isLock;

        listMembers.push(_name);
    }

    function changeMember(
        string calldata _name,
        address _memb,
        uint256 _usefulness,
        bool _isLock
    ) public onlyOwner {
        require(members[_name].addresses.length != 0);
        require(!members[_name].isLock);

        members[_name].addresses.push(_memb);
        members[_name].usefulness = _usefulness;
        members[_name].isLock = _isLock;
    }

    function delMember(string memory _name) public onlyOwner {
        require(members[_name].addresses.length != 0);
        require(!members[_name].isLock);

        for (uint256 i = 0; i < members[_name].addresses.length; i++) {
            members[_name].addresses.pop();
        }
        members[_name].usefulness = 0;

        for (uint256 i = 0; i < listMembers.length; i++) {
            if (
                keccak256(abi.encodePacked(listMembers[i])) ==
                keccak256(abi.encodePacked(_name))
            ) {
                listMembers[i] = listMembers[listMembers.length - 1];
                listMembers.pop();
            }
        }
    }

    function addAddress(string calldata _name, address _addr) public {
        for (uint256 j = 0; j < members[_name].addresses.length; j++) {
            if (msg.sender == members[_name].addresses[j]) {
                members[_name].addresses.push(_addr);
            }
        }
    }

    //Team part end

    function claim(string calldata _name, address _token) public {
        for (uint256 j = 0; j < members[_name].addresses.length; j++) {
            if (msg.sender == members[_name].addresses[j]) {
                //claim
                uint256 balance = ERC20(_token).balanceOf(address(this));
                if (balance > 0) {
                    if (balance > projects[_token].currentBalance) {
                        projects[_token].currentTotalValue +=
                            balance -
                            projects[_token].currentBalance;
                        projects[_token].currentBalance = balance;
                    }

                    uint256 toSend = (projects[_token].currentTotalValue *
                        members[_name].usefulness) / 100;

                    //- текyщие выводы
                    for (
                        uint256 i = 0;
                        i < members[_name].addresses.length;
                        i++
                    ) {
                        toSend -= projects[_token].withdrawn[
                            members[_name].addresses[i]
                        ];
                    }

                    if (toSend != 0) {
                        projects[_token].withdrawn[msg.sender] += toSend;
                        projects[_token].currentBalance -= toSend;
                        require(
                            ERC20(_token).transfer(msg.sender, toSend),
                            "Unknown sending error"
                        );
                    }
                }
            }
        }
    }
}