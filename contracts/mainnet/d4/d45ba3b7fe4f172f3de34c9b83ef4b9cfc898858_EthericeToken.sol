/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// Sources flattened with hardhat v2.11.1 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]
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


// File @openzeppelin/contracts/token/ERC20/[email protected]
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

// File @openzeppelin/contracts/security/[email protected]
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/utils/[email protected]
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


// File @openzeppelin/contracts/access/[email protected]
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

// File contracts/EthericeToken.sol
pragma solidity 0.8.16;

interface BiggestBuyInterface {
    function checkForWinner() external;
    function newBuy(uint256 _amount, address _address) external;
}

contract EthericeToken is ERC20, ReentrancyGuard, Ownable {
    event UserEnterAuction(
        address indexed addr,
        uint256 timestamp,
        uint256 entryAmountEth,
        uint256 day
    );
    event UserCollectAuctionTokens(
        address indexed addr,
        uint256 timestamp,
        uint256 day,
        uint256 tokenAmount,
        uint256 referreeBonus
    );
    event RefferrerBonusPaid(
        address indexed referrerAddress,
        address indexed reffereeAddress,
        uint256 timestamp,
        uint256 referrerBonus,
        uint256 referreeBonus
    );
    event DailyAuctionEnd(
        uint256 timestamp,
        uint256 day,
        uint256 ethTotal,
        uint256 tokenTotal
    );
    event AuctionStarted(
        uint256 timestamp
    );

    uint256 constant public FEE_DENOMINATOR = 1000;

    /** Taxes */
    address public dev_addr = 0xCBb49F57A8D21465EA84D27F3BFea21c76760E6f;
    address public marketing_addr = 0x2EC3524dba30771504fb52F45BECA077eA164deC;
    address public buyback_addr = 0xdf1111dcD45074e8BC69e53e653bac2560089261;
    address public rewards_addr = 0xea555834168448b89EEFa16c58034562979587E1;
    uint256 public dev_percentage = 4;
    uint256 public marketing_percentage = 1;
    uint256 public buyback_percentage = 1;
    uint256 public rewards_percentage = 1;
    uint256 public biggestBuy_percent = 1;

    /* last amount of auction pool that are minted daily to be distributed between lobby participants which starts from 3 mil */
    uint256 public lastAuctionTokens = 3000000 * 1e18;

    /* Ref bonuses, referrer is the person who refered referre is person who got referred, includes 1 decimal so 25 = 2.5%  */
    uint256 public referrer_bonus = 50;
    uint256 public referree_bonus = 10;

    /* Record the current day of the programme */
    uint256 public currentDay;

    /* lobby memebrs data */
    struct userAuctionEntry {
        uint256 totalDeposits;
        uint256 day;
        bool hasCollected;
        address referrer;
    }

    /* new map for every entry (users are allowed to enter multiple times a day) */
    mapping(address => mapping(uint256 => userAuctionEntry))
    public mapUserAuctionEntry;

    /** Total ETH deposited for the day */
    mapping(uint256 => uint256) public auctionDeposits;

    /** Total tokens minted for the day */
    mapping(uint256 => uint256) public auctionTokens;

    /** The percent to reduce the total tokens by each day 30 = 3% */
    uint256 public dailyTokenReductionPercent = 30;

    // Record the contract launch time & current day
    uint256 public launchTime;

    /** External Contracts */
    BiggestBuyInterface private _biggestBuyContract;
    address public _stakingContract;

    address public deployer;

    constructor() ERC20("Etherice", "ETR") {
        deployer = msg.sender;
    }

    receive() external payable {}

    /** 
        @dev is called when we're ready to start the auction
        @param _biggestBuyAddr address of the lottery contract
        @param _stakingCa address of the staking contract

    */
    function startAuction(address _biggestBuyAddr, address _stakingCa)
        external {
        require(launchTime == 0, "Launch already started");
        require(_biggestBuyAddr != address(0), "Biggest buy address cannot be zero");
        require(_stakingCa != address(0), "Staking contract address cannot be zero");
        require(msg.sender == deployer, "Only deployer can start the auction");
        require(owner() != deployer, "Ownership must be transferred to timelock before you can start auction");

        _mint(deployer, lastAuctionTokens);
        launchTime = block.timestamp;
        _biggestBuyContract = BiggestBuyInterface(_biggestBuyAddr);
        _stakingContract = _stakingCa;
        currentDay = calcDay();
        emit AuctionStarted(block.timestamp);
    }

    /**
        @dev update the bonus paid out to affiliates. 20 = 2%
        @param _referrer the percent going to the referrer
        @param _referree the percentage going to the referee
    */
    function updateReferrerBonus(uint256 _referrer, uint256 _referree)
        external
        onlyOwner
    {
        require((_referrer <= 50 && _referree <= 50), "Over max values");
        require((_referrer != 0 && _referree != 0), "Cant be zero");
        referrer_bonus = _referrer;
        referree_bonus = _referree;
    }

    /**
        @dev Calculate the current day based off the auction start time 
    */
    function calcDay() public view returns (uint256) {
        if(launchTime == 0) return 0; 
        return (block.timestamp - launchTime) / 1 days;
    }

    /**
        @dev Called daily, can be done manually in etherscan but will be automated with a script
        this prevent the first user transaction of the day having to pay all the gas to run this 
        function. For security all tokens are kept in the token contract, divs are sent to the 
        div contract for div rewards and taxs are sent to the tax contract.
    */
    function doDailyUpdate() public nonReentrant {
        uint256 _nextDay = calcDay();
        uint256 _currentDay = currentDay;

        // this is true once a day
        if (_currentDay != _nextDay) {
            uint256 _taxShare;
            uint256 _divsShare;

            if(_nextDay > 1) {
                _taxShare = (address(this).balance * tax()) / 100;
                _divsShare = address(this).balance - _taxShare;
                (bool success, ) = _stakingContract.call{value: _divsShare}(
                    abi.encodeWithSignature("receiveDivs()")
                );
                require(success, "Div transfer failed");
            }

            if (_taxShare > 0) {
                _flushTaxes(_taxShare);
            }

             (bool success2, ) = _stakingContract.call(
                    abi.encodeWithSignature("flushDevTaxes()")
                );
                require(success2, "Flush dev taxs failed");

            // Only mint new tokens when we have deposits for that day
            if(auctionDeposits[currentDay] > 0){
                _mintDailyAuctionTokens(_currentDay);
            }
        
            if(biggestBuy_percent > 0) {
                _biggestBuyContract.checkForWinner();
            }

            emit DailyAuctionEnd(
                block.timestamp,
                currentDay,
                auctionDeposits[currentDay],
                auctionTokens[currentDay]
            );

            currentDay = _nextDay;

            delete _nextDay;
            delete _currentDay;
            delete _taxShare;
            delete _divsShare;
        }
    }

    /**
        @dev The total of all the taxs
    */
    function tax() public view returns (uint256) {
        return
            biggestBuy_percent +
            dev_percentage +
            marketing_percentage +
            buyback_percentage +
            rewards_percentage;
    }

    /**
        @dev Send all the taxs to the correct wallets
        @param _amount total eth to distro
    */
    function _flushTaxes(uint256 _amount) internal {
        uint256 _totalTax = tax();
        uint256 _marketingTax = _amount * marketing_percentage / _totalTax;
        uint256 _rewardsTax = _amount * rewards_percentage / _totalTax;
        uint256 _buybackTax = _amount * buyback_percentage / _totalTax;
        uint256 _buyCompTax = (biggestBuy_percent > 0) ?  _amount * biggestBuy_percent / _totalTax : 0;
        uint256 _devTax = _amount -
            (_marketingTax + _rewardsTax + _buybackTax + _buyCompTax);
                
        Address.sendValue(payable(dev_addr), _devTax);
        Address.sendValue(payable(marketing_addr), _marketingTax);
        Address.sendValue(payable(rewards_addr), _rewardsTax);
        Address.sendValue(payable(buyback_addr), _buybackTax);

        if (_buyCompTax > 0) {
            Address.sendValue(payable(address(_biggestBuyContract)), _buyCompTax);
        }


        delete _totalTax;
        delete _buyCompTax;
        delete _marketingTax;
        delete _rewardsTax;
        delete _buybackTax;
        delete _devTax;
    }

    /**
        @dev UPdate  the taxs, can't be greater than current taxs
        @param _dev the dev tax
        @param _marketing the marketing tax
        @param _buyback the buyback tax
        @param _rewards the rewards tax
        @param _biggestBuy biggest buy comp tax
    */
    function updateTaxes(
        uint256 _dev,
        uint256 _marketing,
        uint256 _buyback,
        uint256 _rewards,
        uint256 _biggestBuy
    ) external onlyOwner {
        uint256 _newTotal = _dev + _marketing + _buyback + _rewards + _biggestBuy;
        require(_newTotal <= 10, "Max tax is 10%");
        dev_percentage = _dev;
        marketing_percentage = _marketing;
        buyback_percentage = _buyback;
        rewards_percentage = _rewards;
        biggestBuy_percent = _biggestBuy;
    }

    /**
        @dev Update the marketing wallet address
    */
    function updateMarketingAddress(address adr) external onlyOwner {
        require(adr != address(0), "Can't set to 0 address");
        marketing_addr = adr;
    }

    /**
        @dev Update the dev wallet address
    */
    function updateDevAddress(address adr) external onlyOwner {
        require(adr != address(0), "Can't set to 0 address");
        dev_addr = adr;
    }

    /**
        @dev update the buyback wallet address
    */
    function updateBuybackAddress(address adr) external onlyOwner {
        require(adr != address(0), "Can't set to 0 address");
        buyback_addr = adr;
    }

    /**
        @dev update the rewards wallet address
    */
    function updateRewardsAddress(address adr) external onlyOwner {
        require(adr != address(0), "Can't set to 0 address");
        rewards_addr = adr;
    }

    /**
        @dev Mint the auction tokens for the day 
        @param _day the day to mint the tokens for
    */
    function _mintDailyAuctionTokens(uint256 _day) internal {
        uint256 _nextAuctionTokens = todayAuctionTokens(); // decrease by 3%

        // Mint the tokens for the day so they're ready for the users to withdraw when they remove stakes.
        // This saves gas for the users as we cover the mint costs on our end and the user can do a cheaper
        // transfer function
        _mint(address(this), _nextAuctionTokens);

        auctionTokens[_day] = _nextAuctionTokens;
        lastAuctionTokens = _nextAuctionTokens;

        delete _nextAuctionTokens;
    }

    function todayAuctionTokens() public view returns (uint256){
        return lastAuctionTokens -
            ((lastAuctionTokens * dailyTokenReductionPercent) / FEE_DENOMINATOR); 
    }

    /**
     * @dev entering the auction lobby for the current day
     * @param referrerAddr address of referring user (optional; 0x0 for no referrer)
     */
    function enterAuction(address referrerAddr) external payable {
        require((launchTime > 0), "Project not launched");
        require( msg.value > 0, "msg value is 0 ");
        doDailyUpdate();

        uint256 _currentDay = currentDay;
        _biggestBuyContract.newBuy(msg.value, msg.sender);

        auctionDeposits[_currentDay] += msg.value;

        mapUserAuctionEntry[msg.sender][_currentDay] = userAuctionEntry({
            totalDeposits: mapUserAuctionEntry[msg.sender][_currentDay]
                .totalDeposits + msg.value,
            day: _currentDay,
            hasCollected: false,
            referrer: (referrerAddr != msg.sender) ? referrerAddr : address(0)
        });

        emit UserEnterAuction(msg.sender, block.timestamp, msg.value, _currentDay );
     
        if (_currentDay == 0) {
            // Move this staight out on day 0 so we have
            // the marketing funds availabe instantly
            // to promote the project
            Address.sendValue(payable(dev_addr), msg.value);
        }

        delete _currentDay;
    }

    /**
     * @dev External function for leaving the lobby / collecting the tokens
     * @param targetDay Target day of lobby to collect
     */
    function collectAuctionTokens(uint256 targetDay) external nonReentrant {
        require(
            mapUserAuctionEntry[msg.sender][targetDay].hasCollected == false,
            "Tokens already collected for day"
        );
        require(targetDay < currentDay, "cant collect tokens for current active day");

        uint256 _tokensToPay = calcTokenValue(msg.sender, targetDay);

        mapUserAuctionEntry[msg.sender][targetDay].hasCollected = true;
        _transfer(address(this), msg.sender, _tokensToPay);

        address _referrerAddress = mapUserAuctionEntry[msg.sender][targetDay]
            .referrer;
        uint256 _referreeBonus;

        if (_referrerAddress != address(0)) {
            /* there is a referrer, pay their % ref bonus of tokens */
            uint256 _reffererBonus = (_tokensToPay * referrer_bonus) / FEE_DENOMINATOR;
            _referreeBonus = (_tokensToPay * referree_bonus) / FEE_DENOMINATOR;

            _mint(_referrerAddress, _reffererBonus);
            _mint(msg.sender, _referreeBonus);

            emit RefferrerBonusPaid(
                _referrerAddress,
                msg.sender,
                block.timestamp,
                _reffererBonus,
                _referreeBonus
            );

            delete _referrerAddress;
            delete _reffererBonus;
        }

        emit UserCollectAuctionTokens(
            msg.sender,
            block.timestamp,
            targetDay,
            _tokensToPay,
            _referreeBonus
        );

        delete _referreeBonus;
    }

    /**
     * @dev Calculating user's share from lobby based on their & of deposits for the day
     * @param _Day The lobby day
     */
    function calcTokenValue(address _address, uint256 _Day)
        public
        view
        returns (uint256)
    {
        require(_Day < calcDay(), "day must have ended");
        uint256 _tokenValue;
        uint256 _entryDay = mapUserAuctionEntry[_address][_Day].day;

        if(auctionTokens[_entryDay] == 0){
            // No token minted for that day ( this happens when no deposits for the day)
            return 0;
        }

        if (_entryDay < currentDay) {
            _tokenValue =
                (auctionTokens[_entryDay] *
                    mapUserAuctionEntry[_address][_Day].totalDeposits) / auctionDeposits[_entryDay];
        } else {
            _tokenValue = 0;
        }

        return _tokenValue;
    }

    /**
        @dev change the % reduction of the daily tokens minted
        @param _newPercent the new percent val 3% = 30
    */
    function updateDailyReductionPercent(uint256 _newPercent) external onlyOwner {
        // must be >= 1% and <= 6%
        require((_newPercent >= 10 && _newPercent <= 60));
        dailyTokenReductionPercent = _newPercent;
    }
}