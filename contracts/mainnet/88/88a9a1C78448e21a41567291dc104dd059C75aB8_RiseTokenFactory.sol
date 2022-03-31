/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/RiseTokenFactory.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-or-later
pragma solidity =0.8.11 >=0.8.0 <0.9.0 >=0.8.1 <0.9.0;
pragma experimental ABIEncoderV2;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/* pragma solidity ^0.8.0; */

/* import "../IERC20.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

/* pragma solidity ^0.8.0; */

/* import "./IERC20.sol"; */
/* import "./extensions/IERC20Metadata.sol"; */
/* import "../../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/utils/Address.sol
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

/* pragma solidity ^0.8.1; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

/* pragma solidity ^0.8.0; */

/* import "../IERC20.sol"; */
/* import "../../../utils/Address.sol"; */

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

////// src/interfaces/IRariFusePriceOracle.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/**
 * @title Rari Fuse Price Oracle Interface
 * @author bayu <[email protected]> <https://github.com/pyk>
 */
interface IRariFusePriceOracle {
    /**
     * @notice Gets the price in ETH of `_token`
     * @param _token ERC20 token address
     * @return _price Price in 1e18 precision
     */
    function price(address _token) external view returns (uint256 _price);
}

////// src/interfaces/IRariFusePriceOracleAdapter.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/* import { IRariFusePriceOracle } from "./IRariFusePriceOracle.sol"; */

/**
 * @title Rari Fuse Price Oracle Adapter
 * @author bayu <[email protected]> <https://github.com/pyk>
 * @notice Adapter for Rari Fuse Price Oracle
 */
interface IRariFusePriceOracleAdapter {
    /// ███ Types ██████████████████████████████████████████████████████████████

    /**
     * @notice Oracle metadata
     * @param oracle The Rari Fuse oracle
     * @param decimals The token decimals
     */
    struct OracleMetadata {
        IRariFusePriceOracle oracle;
        uint8 decimals;
    }


    /// ███ Events █████████████████████████████████████████████████████████████

    /**
     * @notice Event emitted when oracle data is updated
     * @param token The ERC20 address
     * @param metadata The oracle metadata
     */
    event OracleConfigured(
        address token,
        OracleMetadata metadata
    );


    /// ███ Errors █████████████████████████████████████████████████████████████

    /// @notice Error is raised when base or quote token oracle is not exists
    error OracleNotExists(address token);


    /// ███ Owner actions ██████████████████████████████████████████████████████

    /**
     * @notice Configure oracle for token
     * @param _token The ERC20 token
     * @param _rariFusePriceOracle Contract that conform IRariFusePriceOracle interface
     */
    function configure(
        address _token,
        address _rariFusePriceOracle
    ) external;


    /// ███ Read-only functions ████████████████████████████████████████████████

    /**
     * @notice Returns true if oracle for the `_token` is configured
     * @param _token The token address
     */
    function isConfigured(address _token) external view returns (bool);


    /// ███ Adapters ███████████████████████████████████████████████████████████

    /**
     * @notice Gets the price of `_token` in terms of ETH (1e18 precision)
     * @param _token Token address (e.g. gOHM)
     * @return _price Price in ETH (1e18 precision)
     */
    function price(address _token) external view returns (uint256 _price);

    /**
     * @notice Gets the price of `_base` in terms of `_quote`.
     *         For example gOHM/USDC will return current price of gOHM in USDC.
     *         (1e6 precision)
     * @param _base Base token address (e.g. gOHM/XXX)
     * @param _quote Quote token address (e.g. XXX/USDC)
     * @return _price Price in quote decimals precision (e.g. USDC is 1e6)
     */
    function price(
        address _base,
        address _quote
    ) external view returns (uint256 _price);

}

////// src/adapters/RariFusePriceOracleAdapter.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/* import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol"; */
/* import { IERC20Metadata } from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol"; */

/* import { IRariFusePriceOracleAdapter } from "../interfaces/IRariFusePriceOracleAdapter.sol"; */
/* import { IRariFusePriceOracle } from "../interfaces/IRariFusePriceOracle.sol"; */

/**
 * @title Rari Fuse Price Oracle Adapter
 * @author bayu <[email protected]> <https://github.com/pyk>
 * @notice Adapter for Rari Fuse Price Oracle
 */
contract RariFusePriceOracleAdapter is IRariFusePriceOracleAdapter, Ownable {
    /// ███ Storages ███████████████████████████████████████████████████████████

    /// @notice Map token to Rari Fuse Price oracle contract
    mapping(address => OracleMetadata) public oracles;


    /// ███ Owner actions ██████████████████████████████████████████████████████

    /// @inheritdoc IRariFusePriceOracleAdapter
    function configure(address _token, address _rariFusePriceOracle) external onlyOwner {
        oracles[_token] = OracleMetadata({
            oracle: IRariFusePriceOracle(_rariFusePriceOracle),
            decimals: IERC20Metadata(_token).decimals()
        });
        emit OracleConfigured(_token, oracles[_token]);
    }


    /// ███ Read-only functions ████████████████████████████████████████████████

    /// @inheritdoc IRariFusePriceOracleAdapter
    function isConfigured(address _token) external view returns (bool) {
        if (oracles[_token].decimals == 0) return false;
        return true;
    }


    /// ███ Adapters ███████████████████████████████████████████████████████████

    /// @inheritdoc IRariFusePriceOracleAdapter
    function price(address _token) public view returns (uint256 _price) {
        if (oracles[_token].decimals == 0) revert OracleNotExists(_token);
        _price = oracles[_token].oracle.price(_token);
    }

    /// @inheritdoc IRariFusePriceOracleAdapter
    function price(address _base, address _quote) external view returns (uint256 _price) {
        uint256 basePriceInETH = price(_base);
        uint256 quotePriceInETH = price(_quote);
        uint256 priceInETH = (basePriceInETH * 1e18) / quotePriceInETH;
        _price = (priceInETH * (10**oracles[_quote].decimals)) / 1e18;
    }
}

////// src/interfaces/IUniswapAdapterCaller.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/**
 * @title Uniswap Adapter Caller Interface
 * @author bayu (github.com/pyk)
 * @notice Contract that interact with Uniswap Adapter should implement this interface.
 */
interface IUniswapAdapterCaller {
    /**
     * @notice Function that will be executed by Uniswap Adapter to finish the flash swap.
     *         The caller will receive _amountOut of the specified tokenOut.
     * @param _wethAmount The amount of WETH that the caller need to send back to the Uniswap Adapter
     * @param _amountOut The amount of of tokenOut transfered to the caller.
     * @param _data Data passed by the caller.
     */
    function onFlashSwapWETHForExactTokens(uint256 _wethAmount, uint256 _amountOut, bytes calldata _data) external;
}

////// src/interfaces/IUniswapV2Pair.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/**
 * @title Uniswap V2 Pair Interface
 * @author bayu (github.com/pyk)
 */
interface IUniswapV2Pair {
    function token1() external view returns (address);
    function token0() external view returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

////// src/interfaces/IUniswapV3Pool.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/**
 * @title Uniswap V3 Pool Interface
 * @author bayu <[email protected]> <https://github.com/pyk>
 */
interface IUniswapV3Pool {
    /// @notice Docs: https://docs.uniswap.org/protocol/reference/core/UniswapV3Pool#swap
    function swap(address _recipient, bool _zeroForOne, int256 _amountSpecified, uint160 _sqrtPriceLimitX96, bytes memory _data) external returns (int256 amount0, int256 amount1);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
}

////// src/interfaces/IUniswapAdapter.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/* import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */

/* import { IUniswapV2Pair } from "../interfaces/IUniswapV2Pair.sol"; */
/* import { IUniswapV3Pool } from "../interfaces/IUniswapV3Pool.sol"; */
/* import { IUniswapAdapterCaller } from "../interfaces/IUniswapAdapterCaller.sol"; */

/**
 * @title Uniswap Adapter
 * @author bayu <[email protected]> <https://github.com/pyk>
 * @notice Utility contract to interact with Uniswap V2 & V3
 */
interface IUniswapAdapter {
    /// ███ Types ██████████████████████████████████████████████████████████████

    /**
     * @notice The supported Uniswap version
     */
    enum UniswapVersion {
        UniswapV2,
        UniswapV3
    }

    /**
     * @notice Liquidity data for specified token
     * @param version The address of Rise Token
     * @param pair The Uniswap V2 pair address
     * @param pool The Uniswap V3 pool address
     * @param router The Uniswap router address
     */
    struct LiquidityData {
        UniswapVersion version;
        IUniswapV2Pair pair;
        IUniswapV3Pool pool;
        address router;
    }

    /**
     * @notice Parameters to do flash swap WETH->tokenOut
     * @param tokenOut The output token
     * @param caller The flash swap caller
     * @param liquidityData Liquidi
     * @param amountOut The amount of tokenOut that will be received by
     *        this contract
     * @param wethAmount The amount of WETH required to finish the flash swap
     */
    struct FlashSwapWETHForExactTokensParams {
        IERC20 tokenOut;
        IUniswapAdapterCaller caller;
        LiquidityData liquidityData;
        uint256 amountOut;
        uint256 wethAmount;
    }

    /// @notice Flash swap types
    enum FlashSwapType {
        FlashSwapWETHForExactTokens
    }


    /// ███ Events █████████████████████████████████████████████████████████████

    /**
     * @notice Event emitted when token is configured
     * @param liquidityData The liquidity data of the token
     */
    event TokenConfigured(LiquidityData liquidityData);

    /**
     * @notice Event emitted when flash swap succeeded
     * @param params The flash swap params
     */
    event FlashSwapped(FlashSwapWETHForExactTokensParams params);


    /// ███ Errors █████████████████████████████████████████████████████████████

    /// @notice Error is raised when owner use invalid uniswap version
    error InvalidUniswapVersion(uint8 version);

    /// @notice Error is raised when invalid amount
    error InvalidAmount(uint256 amount);

    /// @notice Error is raised when token is not configured
    error TokenNotConfigured(address token);

    /// @notice Error is raised when the callback is called by unkown pair/pool
    error CallerNotAuthorized();

    /// @notice Error is raised when the caller not repay the token
    error CallerNotRepay();

    /// @notice Error is raised when this contract receive invalid amount when flashswap
    error FlashSwapReceivedAmountInvalid(uint256 expected, uint256 got);


    /// ███ Owner actions ██████████████████████████████████████████████████████

    /**
     * @notice Configure the token
     * @param _token The ERC20 token
     * @param _version The Uniswap version (2 or 3)
     * @param _pairOrPool The contract address of the TOKEN/ETH pair or pool
     * @param _router The Uniswap V2 or V3 router address
     */
    function configure(
        address _token,
        UniswapVersion _version,
        address _pairOrPool,
        address _router
    ) external;


    /// ███ Read-only functions ████████████████████████████████████████████████

    /**
     * @notice Returns true if token is configured
     * @param _token The token address
     */
    function isConfigured(address _token) external view returns (bool);

    /// ███ Adapters ███████████████████████████████████████████████████████████

    /**
     * @notice Borrow exact amount of tokenOut and repay it with WETH.
     *         The Uniswap Adapter will call msg.sender#onFlashSwapWETHForExactTokens.
     * @param _tokenOut The address of ERC20 that swapped
     * @param _amountOut The exact amount of tokenOut that will be received by the caller
     */
    function flashSwapWETHForExactTokens(
        address _tokenOut,
        uint256 _amountOut,
        bytes memory _data
    ) external;

    /**
     * @notice Swaps an exact amount of input tokenIn for as many WETH as possible
     * @param _tokenIn tokenIn address
     * @param _amountIn The amount of tokenIn
     * @param _amountOutMin The minimum amount of WETH to be received
     * @return _amountOut The WETH amount received
     */
    function swapExactTokensForWETH(
        address _tokenIn,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external returns (uint256 _amountOut);

    /**
     * @notice Swaps an exact amount of WETH for as few tokenIn as possible.
     * @param _tokenIn tokenIn address
     * @param _wethAmount The amount of tokenIn
     * @param _amountInMax The minimum amount of WETH to be received
     * @return _amountIn The WETH amount received
     */
    function swapTokensForExactWETH(
        address _tokenIn,
        uint256 _wethAmount,
        uint256 _amountInMax
    ) external returns (uint256 _amountIn);

    /**
     * @notice Swaps an exact amount of WETH for tokenOut
     * @param _tokenOut tokenOut address
     * @param _wethAmount The amount of WETH
     * @param _amountOutMin The minimum amount of WETH to be received
     * @return _amountOut The WETH amount received
     */
    function swapExactWETHForTokens(
        address _tokenOut,
        uint256 _wethAmount,
        uint256 _amountOutMin
    ) external returns (uint256 _amountOut);

}

////// src/interfaces/IUniswapV2Router02.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/**
 * @title Uniswap V2 Router Interface
 * @author bayu <[email protected]> <https://github.com/pyk>
 */
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

////// src/interfaces/IUniswapV3SwapRouter.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/**
 * @title Uniswap V3 Swap Router Interface
 * @author bayu <[email protected]> <https://github.com/pyk>
 */

interface IUniswapV3SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams memory params) external returns (uint256 amountOut);
    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
    function exactOutputSingle(ExactOutputSingleParams memory params) external returns (uint256 amountIn);
}

////// src/interfaces/IWETH9.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/* import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */

/**
 * @title WETH Interface
 * @author bayu <[email protected]> <https://github.com/pyk>
 */
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

////// src/adapters/UniswapAdapter.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/* import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol"; */
/* import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */
/* import { SafeERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol"; */

/* import { IUniswapAdapter } from "../interfaces/IUniswapAdapter.sol"; */
/* import { IUniswapV2Router02 } from "../interfaces/IUniswapV2Router02.sol"; */
/* import { IUniswapV2Pair } from "../interfaces/IUniswapV2Pair.sol"; */
/* import { IUniswapV3Pool } from "../interfaces/IUniswapV3Pool.sol"; */
/* import { IUniswapV3SwapRouter } from "../interfaces/IUniswapV3SwapRouter.sol"; */
/* import { IUniswapAdapterCaller } from "../interfaces/IUniswapAdapterCaller.sol"; */

/* import { IWETH9 } from "../interfaces/IWETH9.sol"; */

/**
 * @title Uniswap Adapter
 * @author bayu <[email protected]> <https://github.com/pyk>
 * @notice Utility contract to interact with Uniswap V2 & V3
 */
contract UniswapAdapter is IUniswapAdapter, Ownable {
    /// ███ Libraries ██████████████████████████████████████████████████████████

    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH9;

    /// ███ Storages ███████████████████████████████████████████████████████████

    /// @notice WETH address
    IWETH9 public weth;

    /// @notice Mapping token to their liquidity metadata
    mapping(address => LiquidityData) public liquidities;

    /// @notice Whitelisted pair/pool that can call the callback
    mapping(address => bool) private isValidCallbackCaller;


    /// ███ Constuctors ████████████████████████████████████████████████████████

    constructor(address _weth) {
        weth = IWETH9(_weth);
    }


    /// ███ Owner actions ██████████████████████████████████████████████████████

    /// @inheritdoc IUniswapAdapter
    function configure(address _token, UniswapVersion _version, address _pairOrPool, address _router) external onlyOwner {
        isValidCallbackCaller[_pairOrPool] = true;
        liquidities[_token] = LiquidityData({
            version: _version,
            pool: IUniswapV3Pool(_pairOrPool),
            pair: IUniswapV2Pair(_pairOrPool),
            router: _router
        });
        emit TokenConfigured(liquidities[_token]);
    }


    /// ███ Internal functions █████████████████████████████████████████████████

    /// @notice Executed when flashSwapWETHForExactTokens is triggered
    function onFlashSwapWETHForExactTokens(FlashSwapWETHForExactTokensParams memory _params, bytes memory _data) internal {
        // Transfer the tokenOut to caller
        _params.tokenOut.safeTransfer(address(_params.caller), _params.amountOut);

        // Execute the callback
        uint256 prevBalance = weth.balanceOf(address(this));
        _params.caller.onFlashSwapWETHForExactTokens(_params.wethAmount, _params.amountOut, _data);
        uint256 balance = weth.balanceOf(address(this));

        // Check the balance
        if (balance < prevBalance + _params.wethAmount) revert CallerNotRepay();

        // Transfer the WETH to the Uniswap V2 pair or pool
        if (_params.liquidityData.version == UniswapVersion.UniswapV2) {
            weth.safeTransfer(address(_params.liquidityData.pair), _params.wethAmount);
        } else {
            weth.safeTransfer(address(_params.liquidityData.pool), _params.wethAmount);
        }

        emit FlashSwapped(_params);
    }


    /// ███ Callbacks ██████████████████████████████████████████████████████████

    function uniswapV2Call(address _sender, uint256 _amount0, uint256 _amount1, bytes memory _data) external {
        /// ███ Checks

        // Check caller
        if (!isValidCallbackCaller[msg.sender]) revert CallerNotAuthorized();
        if (_sender != address(this)) revert CallerNotAuthorized();

        /// ███ Interactions

        // Get the data
        (FlashSwapType flashSwapType, bytes memory data) = abi.decode(_data, (FlashSwapType, bytes));

        // Continue execute the function based on the flash swap type
        if (flashSwapType == FlashSwapType.FlashSwapWETHForExactTokens) {
            (FlashSwapWETHForExactTokensParams memory params, bytes memory callData) = abi.decode(data, (FlashSwapWETHForExactTokensParams,bytes));
            // Check the amount out
            uint256 amountOut = _amount0 == 0 ? _amount1 : _amount0;
            if (params.amountOut != amountOut) revert FlashSwapReceivedAmountInvalid(params.amountOut, amountOut);

            // Calculate the WETH amount
            address[] memory path = new address[](2);
            path[0] = address(weth);
            path[1] = address(params.tokenOut);
            params.wethAmount = IUniswapV2Router02(params.liquidityData.router).getAmountsIn(params.amountOut, path)[0];

            onFlashSwapWETHForExactTokens(params, callData);
            return;
        }
    }

    function uniswapV3SwapCallback(int256 _amount0Delta, int256 _amount1Delta, bytes memory _data) external {
        /// ███ Checks

        // Check caller
        if (!isValidCallbackCaller[msg.sender]) revert CallerNotAuthorized();

        /// ███ Interactions

        // Get the data
        (FlashSwapType flashSwapType, bytes memory data) = abi.decode(_data, (FlashSwapType, bytes));

        // Continue execute the function based on the flash swap type
        if (flashSwapType == FlashSwapType.FlashSwapWETHForExactTokens) {
            (FlashSwapWETHForExactTokensParams memory params, bytes memory callData) = abi.decode(data, (FlashSwapWETHForExactTokensParams,bytes));

            // if amount negative then it must be the amountOut, otherwise it's weth amount
            uint256 amountOut = _amount0Delta < 0 ?  uint256(-1 * _amount0Delta) : uint256(-1 * _amount1Delta);
            params.wethAmount = _amount0Delta > 0 ? uint256(_amount0Delta) : uint256(_amount1Delta);

            // Check the amount out
            if (params.amountOut != amountOut) revert FlashSwapReceivedAmountInvalid(params.amountOut, amountOut);

            onFlashSwapWETHForExactTokens(params, callData);
            return;
        }
    }


    /// ███ Read-only functions ████████████████████████████████████████████████

    /// @inheritdoc IUniswapAdapter
    function isConfigured(address _token) public view returns (bool) {
        if (liquidities[_token].router == address(0)) return false;
        return true;
    }

    /// ███ Adapters ███████████████████████████████████████████████████████████

    /// @inheritdoc IUniswapAdapter
    function flashSwapWETHForExactTokens(address _tokenOut, uint256 _amountOut, bytes memory _data) external {
        /// ███ Checks
        if (_amountOut == 0) revert InvalidAmount(0);
        if (!isConfigured(_tokenOut)) revert TokenNotConfigured(_tokenOut);

        // Check the metadata
        LiquidityData memory metadata = liquidities[_tokenOut];

        /// ███ Interactions

        // Initialize the params
        FlashSwapWETHForExactTokensParams memory params = FlashSwapWETHForExactTokensParams({
            tokenOut: IERC20(_tokenOut),
            amountOut: _amountOut,
            caller: IUniswapAdapterCaller(msg.sender),
            liquidityData: metadata,
            wethAmount: 0 // Initialize as zero; It will be updated in the callback
        });
        bytes memory data = abi.encode(FlashSwapType.FlashSwapWETHForExactTokens, abi.encode(params, _data));

        // Flash swap Uniswap V2; The pair address will call uniswapV2Callback function
        if (metadata.version == UniswapVersion.UniswapV2) {
            // Get amountOut for token and weth
            uint256 amount0Out = _tokenOut == metadata.pair.token0() ? _amountOut : 0;
            uint256 amount1Out = _tokenOut == metadata.pair.token1() ? _amountOut : 0;

            // Do the flash swap
            metadata.pair.swap(amount0Out, amount1Out, address(this), data);
            return;
        }

        if (metadata.version == UniswapVersion.UniswapV3) {
            // zeroForOne (true: token0 -> token1) (false: token1 -> token0)
            bool zeroForOne = _tokenOut == metadata.pool.token1() ? true : false;

            // amountSpecified (Exact input: positive) (Exact output: negative)
            int256 amountSpecified = -1 * int256(_amountOut);
            uint160 sqrtPriceLimitX96 = (zeroForOne ? 4295128740 : 1461446703485210103287273052203988822378723970341);

            // Perform swap
            metadata.pool.swap(address(this), zeroForOne, amountSpecified, sqrtPriceLimitX96, data);
            return;
        }
    }

    /// @inheritdoc IUniswapAdapter
    function swapExactTokensForWETH(address _tokenIn, uint256 _amountIn, uint256 _amountOutMin) external returns (uint256 _amountOut) {
        /// ███ Checks
        if (!isConfigured(_tokenIn)) revert TokenNotConfigured(_tokenIn);

        /// ███ Interactions
        LiquidityData memory metadata = liquidities[_tokenIn];
        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        IERC20(_tokenIn).safeIncreaseAllowance(metadata.router, _amountIn);

        if (metadata.version == UniswapVersion.UniswapV2) {
            // Do the swap
            address[] memory path = new address[](2);
            path[0] = _tokenIn;
            path[1] = address(weth);
            _amountOut = IUniswapV2Router02(metadata.router).swapExactTokensForTokens(_amountIn, _amountOutMin, path, msg.sender, block.timestamp)[1];
        }

        if (metadata.version == UniswapVersion.UniswapV3) {
            // Do the swap
            IUniswapV3SwapRouter.ExactInputSingleParams memory params = IUniswapV3SwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: address(weth),
                fee: metadata.pool.fee(),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMin,
                sqrtPriceLimitX96: 0
            });
            _amountOut = IUniswapV3SwapRouter(metadata.router).exactInputSingle(params);
        }

        return _amountOut;
    }

    /// @inheritdoc IUniswapAdapter
    function swapTokensForExactWETH(address _tokenIn, uint256 _wethAmount, uint256 _amountInMax) external returns (uint256 _amountIn) {
        /// ███ Checks
        if (!isConfigured(_tokenIn)) revert TokenNotConfigured(_tokenIn);

        /// ███ Interactions
        LiquidityData memory metadata = liquidities[_tokenIn];
        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountInMax);
        IERC20(_tokenIn).safeIncreaseAllowance(metadata.router, _amountInMax);

        if (metadata.version == UniswapVersion.UniswapV2) {
            // Do the swap
            address[] memory path = new address[](2);
            path[0] = _tokenIn;
            path[1] = address(weth);
            _amountIn = IUniswapV2Router02(metadata.router).swapTokensForExactTokens(_wethAmount, _amountInMax, path, msg.sender, block.timestamp)[1];
        }

        if (metadata.version == UniswapVersion.UniswapV3) {
            // Do the swap
            IUniswapV3SwapRouter.ExactOutputSingleParams memory params = IUniswapV3SwapRouter.ExactOutputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: address(weth),
                fee: metadata.pool.fee(),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: _wethAmount,
                amountInMaximum: _amountInMax,
                sqrtPriceLimitX96: 0
            });
            _amountIn = IUniswapV3SwapRouter(metadata.router).exactOutputSingle(params);
        }

        if (_amountInMax > _amountIn) {
            // Transfer back excess token
            IERC20(_tokenIn).safeTransfer(msg.sender, _amountInMax - _amountIn);
        }
        return _amountIn;
    }

    /// @inheritdoc IUniswapAdapter
    function swapExactWETHForTokens(address _tokenOut, uint256 _wethAmount, uint256 _amountOutMin) external returns (uint256 _amountOut) {
        /// ███ Checks
        if (!isConfigured(_tokenOut)) revert TokenNotConfigured(_tokenOut);

        /// ███ Interactions
        LiquidityData memory metadata = liquidities[_tokenOut];
        IERC20(address(weth)).safeTransferFrom(msg.sender, address(this), _wethAmount);
        weth.safeIncreaseAllowance(metadata.router, _wethAmount);

        if (metadata.version == UniswapVersion.UniswapV2) {
            // Do the swap
            address[] memory path = new address[](2);
            path[0] = address(weth);
            path[1] = _tokenOut;
            _amountOut = IUniswapV2Router02(metadata.router).swapExactTokensForTokens(_wethAmount, _amountOutMin, path, msg.sender, block.timestamp)[1];
        }

        if (metadata.version == UniswapVersion.UniswapV3) {
            // Do the swap
            IUniswapV3SwapRouter.ExactInputSingleParams memory params = IUniswapV3SwapRouter.ExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: _tokenOut,
                fee: metadata.pool.fee(),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: _wethAmount,
                amountOutMinimum: _amountOutMin,
                sqrtPriceLimitX96: 0
            });
            _amountOut = IUniswapV3SwapRouter(metadata.router).exactInputSingle(params);
        }

        return _amountOut;
    }
}

////// src/interfaces/IRiseTokenFactory.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/* import { UniswapAdapter } from "../adapters/UniswapAdapter.sol"; */
/* import { RariFusePriceOracleAdapter } from "../adapters/RariFusePriceOracleAdapter.sol"; */

/**
 * @title Rise Token Factory Interface
 * @author bayu <[email protected]> <https://github.com/pyk>
 * @notice Factory contract for creating Rise Token
 */
interface IRiseTokenFactory {
    /// ███ Events █████████████████████████████████████████████████████████████

    /**
     * @notice Event emitted when new Rise Token is created
     * @param token The address of Rise Token
     * @param fCollateral The address of Rari Fuse token that used as collateral
     * @param fDebt The address of Rari Fuse token that used as debt
     * @param totalTokens The total tokens created by this factory
     */
    event TokenCreated(
        address token,
        address fCollateral,
        address fDebt,
        uint256 totalTokens
    );

    /**
     * @notice Event emitted when feeRecipient is updated
     * @param newRecipient The new fee recipient address
     */
    event FeeRecipientUpdated(address newRecipient);


    /// ███ Errors █████████████████████████████████████████████████████████████

    /**
     * @notice Error is raised when Rise Token already exists
     * @param token The Rise Token that already exists with the same collateral
     *               and debt pair
     */
    error TokenExists(address token);


    /// ███ Owner actions ██████████████████████████████████████████████████████

    /**
     * @notice Sets fee recipient
     * @param _newRecipient New fee recipient
     */
    function setFeeRecipient(address _newRecipient) external;

    /**
     * @notice Creates new Rise Token
     * @param _fCollateral fToken from Rari Fuse that used as collateral asset
     * @param _fDebt fToken from Rari Fuse that used as debt asset
     * @return _token The Rise Token address
     */
    function create(
        address _fCollateral,
        address _fDebt,
        address _uniswapAdapter,
        address _oracleAdapter
    ) external returns (address _token);

}

////// src/interfaces/IfERC20.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/**
 * @title Rari Fuse ERC20 Interface
 * @author bayu (github.com/pyk)
 * @dev docs: https://docs.rari.capital/fuse/#ftoken-s
 */
interface IfERC20 {
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint redeemAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
    function repayBorrow(uint256 repayAmount) external returns (uint256);
    function accrualBlockNumber() external returns (uint256);
    function borrowBalanceCurrent(address account) external returns (uint256);
    function comptroller() external returns (address);
    function underlying() external returns (address);
    function balanceOfUnderlying(address account) external returns (uint256);
    function totalBorrowsCurrent() external returns (uint256);
}

////// src/RiseTokenFactory.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/* import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol"; */
/* import { IERC20Metadata } from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol"; */

/* import { IfERC20 } from "./interfaces/IfERC20.sol"; */
/* import { IRiseTokenFactory } from "./interfaces/IRiseTokenFactory.sol"; */

/* import { RiseToken } from "./RiseToken.sol"; */
/* import { UniswapAdapter } from "./adapters/UniswapAdapter.sol"; */
/* import { RariFusePriceOracleAdapter } from "./adapters/RariFusePriceOracleAdapter.sol"; */

/**
 * @title Rise Token Factory
 * @author bayu <[email protected]> <https://github.com/pyk>
 * @notice Factory contract to create new Rise Token
 */
contract RiseTokenFactory is IRiseTokenFactory, Ownable {
    /// ███ Storages ███████████████████████████████████████████████████████████

    address[] public tokens;
    mapping(address => mapping(address => address)) public getToken;
    address public feeRecipient;


    /// ███ Constructors ███████████████████████████████████████████████████████

    constructor(address _feeRecipient) {
        feeRecipient = _feeRecipient;
    }


    /// ███ Owner actions ██████████████████████████████████████████████████████

    /// @inheritdoc IRiseTokenFactory
    function setFeeRecipient(address _newRecipient) external onlyOwner {
        feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(_newRecipient);
    }

    /// @inheritdoc IRiseTokenFactory
    function create(address _fCollateral, address _fDebt, address _uniswapAdapter, address _oracleAdapter) external onlyOwner returns (address _token) {
        address collateral = IfERC20(_fCollateral).underlying();
        address debt = IfERC20(_fDebt).underlying();
        if (getToken[collateral][debt] != address(0)) revert TokenExists(getToken[collateral][debt]);

        /// ███ Contract deployment
        bytes memory creationCode = type(RiseToken).creationCode;
        string memory tokenName = string(abi.encodePacked(IERC20Metadata(collateral).symbol(), " 2x Long Risedle"));
        string memory tokenSymbol = string(abi.encodePacked(IERC20Metadata(collateral).symbol(), "RISE"));
        bytes memory constructorArgs = abi.encode(tokenName, tokenSymbol, address(this), _fCollateral, _fDebt, _uniswapAdapter, _oracleAdapter);
        bytes memory bytecode = abi.encodePacked(creationCode, constructorArgs);
        bytes32 salt = keccak256(abi.encodePacked(_fCollateral, _fDebt));
        assembly {
            _token := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        getToken[_fCollateral][_fDebt] = _token;
        getToken[_fDebt][_fCollateral] = _token; // populate mapping in the reverse direction
        tokens.push(_token);

        emit TokenCreated(_token, _fCollateral, _fDebt, tokens.length);
    }
}

////// src/interfaces/IFuseComptroller.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/**
 * @title Rari Fuse Comptroller Interface
 * @author bayu (github.com/pyk)
 * @dev docs: https://docs.rari.capital/fuse/#comptroller
 */
interface IFuseComptroller {
    function getAccountLiquidity(address account) external returns (uint256 error, uint256 liquidity, uint256 shortfall);
    function enterMarkets(address[] calldata fTokens) external returns (uint256[] memory);
}

////// src/interfaces/IRiseToken.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/* import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */
/* import { ERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol"; */

/**
 * @title Rise Token
 * @author bayu <[email protected]> <https://github.com/pyk>
 * @notice 2x Long Token powered by Rari Fuse
 */
interface IRiseToken is IERC20 {

    /// ███ Types █████████████████████████████████████████████████████████████

    /// @notice Flashswap types
    enum FlashSwapType {
        Initialize,
        Buy,
        Sell
    }

    /**
     * @notice Parameters that used to initialize the Rise Token
     * @param borrowAmount The target borrow amount
     * @param collateralAmount The target collateral amount
     * @param shares The target initial supply of the Rise Token
     * @param leverageRatio The target leverage ratio of the Rise Token
     * @param nav The net-asset value of the Rise Token
     * @param ethAmount The maximum amount of ETH that used to initialize the
     *                  total collateral and total debt
     * @param initialize The initialize() executor
     */
    struct InitializeParams {
        uint256 borrowAmount;
        uint256 collateralAmount;
        uint256 shares;
        uint256 leverageRatio;
        uint256 nav;
        uint256 ethAmount;
        address initializer;
    }

    /**
     * @notice Parameters that used to buy the Rise Token
     * @param buyer The msg.sender
     * @param recipient The address that will receive the Rise Token
     * @param tokenIn The ERC20 that used to buy the Rise Token
     * @param collateralAmount The amount of token that will supplied to Rari Fuse
     * @param debtAmount The amount of token that will borrowed from Rari Fuse
     * @param shares The amount of Rise Token to be minted
     * @param fee The amount of Rise Token as fee
     * @param amountInMax The maximum amount of tokenIn, useful for setting the
     *                    slippage tolerance.
     * @param nav The net-asset value of the Rise Token
     */
    struct BuyParams {
        address buyer;
        address recipient;
        ERC20 tokenIn;
        uint256 collateralAmount;
        uint256 debtAmount;
        uint256 shares;
        uint256 fee;
        uint256 amountInMax;
        uint256 nav;
    }

    /**
     * @notice Parameters that used to buy the Rise Token
     * @param seller The msg.sender
     * @param recipient The address that will receive the tokenOut
     * @param tokenOut The ERC20 that will received by recipient
     * @param collateralAmount The amount of token that will redeemed from Rari Fuse
     * @param debtAmount The amount of token that will repay to Rari Fuse
     * @param shares The amount of Rise Token to be burned
     * @param fee The amount of Rise Token as fee
     * @param amountOutMin The minimum amount of tokenOut, useful for setting the
     *                    slippage tolerance.
     * @param nav The net-asset value of the Rise Token
     */
    struct SellParams {
        address seller;
        address recipient;
        ERC20 tokenOut;
        uint256 collateralAmount;
        uint256 debtAmount;
        uint256 shares;
        uint256 fee;
        uint256 amountOutMin;
        uint256 nav;
    }


    /// ███ Events █████████████████████████████████████████████████████████████

    /**
     * @notice Event emitted when the Rise Token is initialized
     * @param params The initialization parameters
     */
    event Initialized(InitializeParams params);

    /// @notice Event emitted when user buy the token
    event Buy(BuyParams params);

    /// @notice Event emitted when user sell the token
    event Sell(SellParams params);

    /**
     * @notice Event emitted when params updated
     * @param maxLeverageRatio The maximum leverage ratio
     * @param minLeverageRatio The minimum leverage ratio
     * @param step The rebalancing step
     * @param discount The incentives for the market makers
     * @param maxBuy The maximum amount to buy in one transaction
     */
    event ParamsUpdated(
        uint256 maxLeverageRatio,
        uint256 minLeverageRatio,
        uint256 step,
        uint256 discount,
        uint256 maxBuy
    );

    /// ███ Errors █████████████████████████████████████████████████████████████

    /// @notice Error is raised if the caller of onFlashSwapWETHForExactTokens is
    ///         not Uniswap Adapter contract
    error NotUniswapAdapter();

    /// @notice Error is raised if mint amount is invalid
    error InputAmountInvalid();

    /// @notice Error is raised if the owner run the initialize() twice
    error AlreadyInitialized();

    /// @notice Error is raised if buy & sell is executed before the FLT is initialized
    error NotInitialized();

    /// @notice Error is raised if slippage too high
    error SlippageTooHigh();

    /// @notice Error is raised if contract failed to send ETH
    error FailedToSendETH(address to, uint256 amount);

    /// @notice Error is raised if rebalance is executed but leverage ratio is invalid
    // error NoNeedToRebalance(uint256 leverageRatio);
    error NoNeedToRebalance();

    /// @notice Error is raised if liqudity to buy or sell collateral is not enough
    error LiquidityIsNotEnough();

    /// @notice Error is raised if something happen when interacting with Rari Fuse
    error FuseError(uint256 code);


    /// ███ Owner actions ██████████████████████████████████████████████████████

    /**
     * @notice Update the Rise Token parameters
     * @param _minLeverageRatio Minimum leverage ratio
     * @param _maxLeverageRatio Maximum leverage ratio
     * @param _step Rebalancing step
     * @param _discount Discount for market makers to incentivize the rebalance
     */
    function setParams(
        uint256 _minLeverageRatio,
        uint256 _maxLeverageRatio,
        uint256 _step,
        uint256 _discount,
        uint256 _maxBuy
    ) external;

    /**
     * @notice Initialize the Rise Token using ETH
     * @param _params The initialization parameters
     */
    function initialize(InitializeParams memory _params) external payable;


    /// ███ Read-only functions ████████████████████████████████████████████████

    /**
     * @notice Gets the total collateral per share
     * @return _cps Collateral per share in collateral token decimals precision
     *         (ex: gOHM is 1e18 precision)
     */
    function collateralPerShare() external view returns (uint256 _cps);

    /**
     * @notice Gets the total debt per share
     * @return _dps Debt per share in debt token decimals precision
     *         (ex: USDC is 1e6 precision)
     */
    function debtPerShare() external view returns (uint256 _dps);

    /**
     * @notice Gets the value of the Rise Token in ETH
     * @param _shares The amount of Rise Token
     * @return _value The value of the Rise Token in 1e18 precision
     */
    function value(uint256 _shares) external view returns (uint256 _value);

    /**
     * @notice Gets the net-asset value of the Rise Token in specified token
     * @dev This function may revert if _quote token is not configured in Rari
     *      Fuse Price Oracle
     * @param _shares The amount of Rise Token
     * @param _quote The token address used as quote
     * @return _value The net-asset value of the Rise Token in token decimals
     *                precision (ex: USDC is 1e6)
     */
    function value(
        uint256 _shares,
        address _quote
    ) external view returns (uint256 _value);

    /**
     * @notice Gets the net-asset value of the Rise Token in ETH
     * @return _nav The net-asset value of the Rise Token in 1e18 precision
     */
    function nav() external view returns (uint256 _nav);

    /**
     * @notice Gets the leverage ratio of the Rise Token
     * @return _lr Leverage ratio in 1e18 precision
     */
    function leverageRatio() external view returns (uint256 _lr);


    /// ███ User actions ███████████████████████████████████████████████████████

    /**
     * @notice Buy Rise Token with tokenIn. New Rise Token supply will be minted.
     * @param _shares The amount of Rise Token to buy
     * @param _recipient The recipient of the transaction.
     * @param _tokenIn ERC20 used to buy the Rise Token
     */
    function buy(
        uint256 _shares,
        address _recipient,
        address _tokenIn,
        uint256 _amountInMax
    ) external payable;

    /**
     * @notice Sell Rise Token for tokenOut. The _shares amount of Rise Token will be burned.
     * @param _shares The amount of Rise Token to sell
     * @param _recipient The recipient of the transaction
     * @param _tokenOut The output token
     * @param _amountOutMin The minimum amount of output token
     */
    function sell(
        uint256 _shares,
        address _recipient,
        address _tokenOut,
        uint256 _amountOutMin
    ) external;


    /// ███ Market makers ██████████████████████████████████████████████████████

    /**
     * Rise Token is designed in such way that users get protection against
     * liquidation, while market makers are well-incentivized to execute the
     * rebalancing process.
     *
     * ===== Leveraging Up
     * When collateral (ex: gOHM) price is going up, the net-asset value of
     * Rise Token (ex: gOHMRISE) will going up and the leverage ratio of
     * the Rise Token will going down.
     *
     * If leverage ratio is below specified minimum leverage ratio (ex: 1.7x),
     * Rise Token need to borrow more asset from Rari Fuse (ex: USDC), in order
     * to buy more collateral then supply the collateral to Rari Fuse.
     *
     * If leverageRatio < minLeverageRatio:
     *     Rise Token want collateral (ex: gOHM)
     *     Rise Token have liquid asset (ex: USDC)
     *
     * Market makers can swap collateral to ETH if leverage ratio below minimal
     * Leverage ratio.
     *
     * ===== Leveraging Down
     * When collateral (ex: gOHM) price is going down, the net-asset value of
     * Rise Token (ex: gOHMRISE) will going down and the leverage ratio of
     * the Rise Token will going up.
     *
     * If leverage ratio is above specified maximum leverage ratio (ex: 2.3x),
     * Rise Token need to sell collateral in order to repay debt to Rari Fuse.
     *
     * If leverageRatio > maxLeverageRatio:
     *     Rise Token want liquid asset (ex: USDC)
     *     Rise Token have collateral (ex: gOHM)
     *
     * Market makers can swap ETH to collateral if leverage ratio above maximum
     * Leverage ratio.
     *
     * -----------
     *
     * In order to incentives the swap process, Rise Token will give specified
     * discount price 0.6%.
     *
     * swapColleteralForETH -> Market Makers can sell collateral +0.6% above the
     *                         market price
     *
     * swapETHForCollateral -> Market Makers can buy collateral -0.6% below the
     *                         market price
     *
     * In this case, market price is determined using Rari Fuse Oracle Adapter.
     *
     */

     /**
      * @notice Swaps collateral for ETH
      * @dev Anyone can execute this if leverage ratio is below minimum.
      * @param _amountIn The amount of collateral
      * @param _amountOutMin The minimum amount of ETH to be received
      * @return _amountOut The amount of ETH that received by msg.sender
      */
    function swapExactCollateralForETH(
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external returns (uint256 _amountOut);

     /**
      * @notice Swaps ETH for collateral
      * @dev Anyone can execute this if leverage ratio is below minimum.
      * @param _amountOutMin The minimum amount of collateral
      * @return _amountOut The amount of collateral
      */
    function swapExactETHForCollateral(
        uint256 _amountOutMin
    ) external payable returns (uint256 _amountOut);

}

////// src/RiseToken.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/* import { ERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol"; */
/* import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol"; */
/* import { SafeERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol"; */

/* import { IRiseToken } from "./interfaces/IRiseToken.sol"; */
/* import { IfERC20 } from "./interfaces/IfERC20.sol"; */
/* import { IFuseComptroller } from "./interfaces/IFuseComptroller.sol"; */
/* import { IWETH9 } from "./interfaces/IWETH9.sol"; */

/* import { RiseTokenFactory } from "./RiseTokenFactory.sol"; */
/* import { UniswapAdapter } from "./adapters/UniswapAdapter.sol"; */
/* import { RariFusePriceOracleAdapter } from "./adapters/RariFusePriceOracleAdapter.sol"; */

/**
 * @title Rise Token (2x Long Token)
 * @author bayu <[email protected]> <https://github.com/pyk>
 * @notice 2x Long Token powered by Rari Fuse
 */
contract RiseToken is IRiseToken, ERC20, Ownable {
    /// ███ Libraries ██████████████████████████████████████████████████████████

    using SafeERC20 for ERC20;
    using SafeERC20 for IWETH9;

    /// ███ Storages ███████████████████████████████████████████████████████████

    IWETH9                     public weth;
    RiseTokenFactory           public factory;
    UniswapAdapter             public uniswapAdapter;
    RariFusePriceOracleAdapter public oracleAdapter;

    ERC20   public collateral;
    ERC20   public debt;
    IfERC20 public fCollateral;
    IfERC20 public fDebt;

    uint256 public totalCollateral;
    uint256 public totalDebt;
    uint256 public maxBuy = type(uint256).max;
    uint256 public fees = 0.001 ether;
    uint256 public minLeverageRatio = 1.7 ether;
    uint256 public maxLeverageRatio = 2.3 ether;
    uint256 public step = 0.2 ether;
    uint256 public discount = 0.006 ether; // 0.6%
    bool    public isInitialized;

    uint8 private cdecimals;
    uint8 private ddecimals;


    /// ███ Constructors ███████████████████████████████████████████████████████

    constructor(
        string memory _name,
        string memory _symbol,
        address _factory,
        address _fCollateral,
        address _fDebt,
        address _uniswapAdapter,
        address _oracleAdapter
    ) ERC20(_name, _symbol) {
        factory = RiseTokenFactory(_factory);
        uniswapAdapter = UniswapAdapter(_uniswapAdapter);
        oracleAdapter = RariFusePriceOracleAdapter(_oracleAdapter);
        fCollateral = IfERC20(_fCollateral);
        fDebt = IfERC20(_fDebt);
        collateral = ERC20(fCollateral.underlying());
        debt = ERC20(fDebt.underlying());
        weth = IWETH9(uniswapAdapter.weth());

        cdecimals = collateral.decimals();
        ddecimals = debt.decimals();

        transferOwnership(factory.owner());
    }


    /// ███ Internal functions █████████████████████████████████████████████████

    function supplyThenBorrow(uint256 _collateralAmount, uint256 _borrowAmount) internal {
        // Deposit to Rari Fuse
        collateral.safeIncreaseAllowance(address(fCollateral), _collateralAmount);
        uint256 fuseResponse;
        fuseResponse = fCollateral.mint(_collateralAmount);
        if (fuseResponse != 0) revert FuseError(fuseResponse);

        // Borrow from Rari Fuse
        fuseResponse = fDebt.borrow(_borrowAmount);
        if (fuseResponse != 0) revert FuseError(fuseResponse);

        // Cache the value
        totalCollateral = fCollateral.balanceOfUnderlying(address(this));
        totalDebt = fDebt.borrowBalanceCurrent(address(this));
    }

    function repayThenRedeem(uint256 _repayAmount, uint256 _collateralAmount) internal {
        // Repay debt to Rari Fuse
        debt.safeIncreaseAllowance(address(fDebt), _repayAmount);
        uint256 repayResponse = fDebt.repayBorrow(_repayAmount);
        if (repayResponse != 0) revert FuseError(repayResponse);

        // Redeem from Rari Fuse
        uint256 redeemResponse = fCollateral.redeemUnderlying(_collateralAmount);
        if (redeemResponse != 0) revert FuseError(redeemResponse);

        // Cache the value
        totalCollateral = fCollateral.balanceOfUnderlying(address(this));
        totalDebt = fDebt.borrowBalanceCurrent(address(this));
    }

    function onInitialize(uint256 _wethAmount, uint256 _collateralAmount, bytes memory _data) internal {
        isInitialized = true;
        (InitializeParams memory params) = abi.decode(_data, (InitializeParams));

        // Enter Rari Fuse Markets
        address[] memory markets = new address[](2);
        markets[0] = address(fCollateral);
        markets[1] = address(fDebt);
        uint256[] memory marketStatus = IFuseComptroller(fCollateral.comptroller()).enterMarkets(markets);
        if (marketStatus[0] != 0 && marketStatus[1] != 0) revert FuseError(marketStatus[0]);

        supplyThenBorrow(_collateralAmount, params.borrowAmount);

        // Swap debt asset to WETH
        debt.safeIncreaseAllowance(address(uniswapAdapter), params.borrowAmount);
        uint256 wethAmountFromBorrow = uniswapAdapter.swapExactTokensForWETH(address(debt)  , params.borrowAmount, 0);

        // Get owed WETH
        uint256 owedWETH = _wethAmount - wethAmountFromBorrow;
        if (owedWETH > params.ethAmount) revert SlippageTooHigh();

        // Transfer excess ETH back to the initializer
        uint256 excessETH = params.ethAmount - owedWETH;
        (bool sent, ) = params.initializer.call{value: excessETH}("");
        if (!sent) revert FailedToSendETH(params.initializer, excessETH);

        // Send back WETH to uniswap adapter
        weth.deposit{ value: owedWETH }(); // Wrap the ETH to WETH
        weth.safeTransfer(address(uniswapAdapter), _wethAmount);

        // Mint the Rise Token to the initializer
        _mint(params.initializer, params.shares);

        emit Initialized(params);
    }

    function onBuy(uint256 _wethAmount, uint256 _collateralAmount, bytes memory _data) internal {
        // Parse the data from buy function
        (BuyParams memory params) = abi.decode(_data, (BuyParams));

        // Supply then borrow in Rari Fuse
        supplyThenBorrow(_collateralAmount, params.debtAmount);

        // Swap debt asset to WETH
        debt.safeIncreaseAllowance(address(uniswapAdapter), params.debtAmount);
        uint256 wethAmountFromBorrow = uniswapAdapter.swapExactTokensForWETH(address(debt), params.debtAmount, 0);

        // Get owed WETH
        uint256 owedWETH = _wethAmount - wethAmountFromBorrow;

        if (address(params.tokenIn) == address(0)) {
            if (owedWETH > params.amountInMax) revert SlippageTooHigh();
            // Transfer excess ETH back to the buyer
            uint256 excessETH = params.amountInMax - owedWETH;
            (bool sent, ) = params.buyer.call{value: excessETH}("");
            if (!sent) revert FailedToSendETH(params.buyer, excessETH);
            weth.deposit{ value: owedWETH }();
        } else {
            params.tokenIn.safeTransferFrom(params.buyer, address(this), params.amountInMax);
            params.tokenIn.safeIncreaseAllowance(address(uniswapAdapter), params.amountInMax);
            uint256 amountIn = uniswapAdapter.swapTokensForExactWETH(address(params.tokenIn), owedWETH, params.amountInMax);
            if (amountIn < params.amountInMax) {
                params.tokenIn.safeTransfer(params.buyer, params.amountInMax - amountIn);
            }
        }

        // Transfer WETH to Uniswap Adapter to repay the flash swap
        weth.safeTransfer(address(uniswapAdapter), _wethAmount);

        // Mint the Rise Token to the buyer
        _mint(params.recipient, params.shares);
        _mint(factory.feeRecipient(), params.fee);

        emit Buy(params);
    }

    // Need this to handle debt token as output token; We can't re-enter the pool
    uint256 private wethLeftFromFlashSwap;

    function onSell(uint256 _wethAmount, uint256 _debtAmount, bytes memory _data) internal {
        // Parse the data from sell function
        (SellParams memory params) = abi.decode(_data, (SellParams));

        // Repay then redeem
        repayThenRedeem(_debtAmount, params.collateralAmount);

        // If tokenOut is collateral then don't swap all collateral to WETH
        if (address(params.tokenOut) == address(collateral)) {
            // Swap collateral to repay WETH
            collateral.safeIncreaseAllowance(address(uniswapAdapter), params.collateralAmount);
            uint256 collateralToBuyWETH = uniswapAdapter.swapTokensForExactWETH(address(collateral), _wethAmount, params.collateralAmount);
            uint256 collateralLeft = params.collateralAmount - collateralToBuyWETH;
            if (collateralLeft < params.amountOutMin) revert SlippageTooHigh();
            collateral.safeTransfer(params.recipient, collateralLeft);
        } else {
            // Swap all collateral to WETH
            collateral.safeIncreaseAllowance(address(uniswapAdapter), params.collateralAmount);
            uint256 wethAmountFromCollateral = uniswapAdapter.swapExactTokensForWETH(address(collateral), params.collateralAmount, 0);
            uint256 wethLeft = wethAmountFromCollateral - _wethAmount;

            if (address(params.tokenOut) == address(0)) {
                if (wethLeft < params.amountOutMin) revert SlippageTooHigh();
                weth.safeIncreaseAllowance(address(weth), wethLeft);
                weth.withdraw(wethLeft);
                (bool sent, ) = params.recipient.call{value: wethLeft}("");
                if (!sent) revert FailedToSendETH(params.recipient, wethLeft);
            }

            // Cannot enter the pool again
            if (address(params.tokenOut) == address(debt)) {
                wethLeftFromFlashSwap = wethLeft;
            }

            if (address(params.tokenOut) != address(0) && (address(params.tokenOut) != address(debt))) {
                weth.safeIncreaseAllowance(address(uniswapAdapter), wethLeft);
                uint256 amountOut = uniswapAdapter.swapExactWETHForTokens(address(params.tokenOut), wethLeft, params.amountOutMin);
                params.tokenOut.safeTransfer(params.recipient, amountOut);
            }
        }

        // Transfer WETH to uniswap adapter
        weth.safeTransfer(address(uniswapAdapter), _wethAmount);

        // Burn the Rise Token
        ERC20(address(this)).safeTransferFrom(params.seller, factory.feeRecipient(), params.fee);
        _burn(params.seller, params.shares - params.fee);
        emit Sell(params);
    }


    /// ███ Owner actions ██████████████████████████████████████████████████████

    /// @inheritdoc IRiseToken
    function setParams(uint256 _minLeverageRatio, uint256 _maxLeverageRatio, uint256 _step, uint256 _discount, uint256 _newMaxBuy) external onlyOwner {
        minLeverageRatio = _minLeverageRatio;
        maxLeverageRatio = _maxLeverageRatio;
        step = _step;
        discount = _discount;
        maxBuy = _newMaxBuy;
        emit ParamsUpdated(minLeverageRatio, maxLeverageRatio, step, discount, maxBuy);
    }

    /// @inheritdoc IRiseToken
    function initialize(InitializeParams memory _params) external payable onlyOwner {
        if (isInitialized == true) revert AlreadyInitialized();
        if (msg.value == 0) revert InputAmountInvalid();
        _params.ethAmount = msg.value;
        bytes memory data = abi.encode(FlashSwapType.Initialize, abi.encode(_params));
        uniswapAdapter.flashSwapWETHForExactTokens(address(collateral), _params.collateralAmount, data);
    }


    /// ███ External functions █████████████████████████████████████████████████

    function onFlashSwapWETHForExactTokens(uint256 _wethAmount, uint256 _amountOut, bytes calldata _data) external {
        if (msg.sender != address(uniswapAdapter)) revert NotUniswapAdapter();

        // Continue execution based on the type
        (FlashSwapType flashSwapType, bytes memory data) = abi.decode(_data, (FlashSwapType,bytes));
        if (flashSwapType == FlashSwapType.Initialize) {
            onInitialize(_wethAmount, _amountOut, data);
            return;
        }

        if (flashSwapType == FlashSwapType.Buy) {
            onBuy(_wethAmount, _amountOut, data);
            return;
        }

        if (flashSwapType == FlashSwapType.Sell) {
            onSell(_wethAmount, _amountOut, data);
            return;
        }
    }

    /// ███ Read-only functions ████████████████████████████████████████████████

    function decimals() public view virtual override returns (uint8) {
        return cdecimals;
    }

    /// @inheritdoc IRiseToken
    function collateralPerShare() public view returns (uint256 _cps) {
        if (!isInitialized) return 0;
        _cps = (totalCollateral * (10**cdecimals)) / totalSupply();
    }

    /// @inheritdoc IRiseToken
    function debtPerShare() public view returns (uint256 _dps) {
        if (!isInitialized) return 0;
        _dps = (totalDebt * (10**cdecimals)) / totalSupply();
    }

    /// @inheritdoc IRiseToken
    function value(uint256 _shares) public view returns (uint256 _value) {
        if (!isInitialized) return 0;
        if (_shares == 0) return 0;
        // Get the collateral & debt amount
        uint256 collateralAmount = (_shares * collateralPerShare()) / (10**cdecimals);
        uint256 debtAmount = (_shares * debtPerShare()) / (10**cdecimals);

        // Get the price in ETH
        uint256 cPrice = oracleAdapter.price(address(collateral));
        uint256 dPrice = oracleAdapter.price(address(debt));

        // Get total value in ETH
        uint256 collateralValue = (collateralAmount * cPrice) / (10**cdecimals);
        uint256 debtValue = (debtAmount * dPrice) / (10**ddecimals);

        // Get Rise Token value in ETH
        _value = collateralValue - debtValue;
    }

    /// @inheritdoc IRiseToken
    function value(uint256 _shares, address _quote) public view returns (uint256 _value) {
        uint256 valueInETH = value(_shares);
        if (valueInETH == 0) return 0;
        uint256 quoteDecimals = ERC20(_quote).decimals();
        uint256 quotePrice = oracleAdapter.price(_quote);
        uint256 amountInETH = (valueInETH * 1e18) / quotePrice;

        // Get Rise Token value in _quote token
        _value = (amountInETH * (10**quoteDecimals)) / 1e18;
    }

    /// @inheritdoc IRiseToken
    function nav() public view returns (uint256 _nav) {
        if (!isInitialized) return 0;
        _nav = value(10**cdecimals);
    }

    /// @inheritdoc IRiseToken
    function leverageRatio() public view returns (uint256 _lr) {
        if (!isInitialized) return 0;
        uint256 collateralPrice = oracleAdapter.price(address(collateral));
        uint256 collateralValue = (collateralPerShare() * collateralPrice) / (10**cdecimals);
        _lr = (collateralValue * 1e18) / nav();
    }


    /// ███ User actions ███████████████████████████████████████████████████████

    /// @inheritdoc IRiseToken
    function buy(uint256 _shares, address _recipient, address _tokenIn, uint256 _amountInMax) external payable {
        if (!isInitialized) revert NotInitialized();
        if (_shares > maxBuy) revert InputAmountInvalid();

        uint256 fee = ((fees * _shares) / 1e18);
        uint256 newShares = _shares + fee;
        BuyParams memory params = BuyParams({
            buyer: msg.sender,
            recipient: _recipient,
            tokenIn: ERC20(_tokenIn),
            amountInMax: _tokenIn == address(0) ? msg.value : _amountInMax,
            shares: _shares,
            collateralAmount: (newShares * collateralPerShare()) / (10**cdecimals),
            debtAmount: (newShares * debtPerShare()) / (10**cdecimals),
            fee: fee,
            nav: nav()
        });

        // Perform the flash swap
        bytes memory data = abi.encode(FlashSwapType.Buy, abi.encode(params));
        uniswapAdapter.flashSwapWETHForExactTokens(address(collateral), params.collateralAmount, data);
    }

    /// @inheritdoc IRiseToken
    function sell(uint256 _shares, address _recipient, address _tokenOut, uint256 _amountOutMin) external {
        if (!isInitialized) revert NotInitialized();

        uint256 fee = ((fees * _shares) / 1e18);
        uint256 newShares = _shares - fee;
        SellParams memory params = SellParams({
            seller: msg.sender,
            recipient: _recipient,
            tokenOut: ERC20(_tokenOut),
            amountOutMin: _amountOutMin,
            shares: _shares,
            collateralAmount: (newShares * collateralPerShare()) / (10**cdecimals),
            debtAmount: (newShares * debtPerShare()) / (10**cdecimals),
            fee: fee,
            nav: nav()
        });

        // Perform the flash swap
        bytes memory data = abi.encode(FlashSwapType.Sell, abi.encode(params));
        uniswapAdapter.flashSwapWETHForExactTokens(address(debt), params.debtAmount, data);

        if (address(params.tokenOut) == address(debt)) {
            weth.safeIncreaseAllowance(address(uniswapAdapter), wethLeftFromFlashSwap);
            uint256 amountOut = uniswapAdapter.swapExactWETHForTokens(address(params.tokenOut), wethLeftFromFlashSwap, params.amountOutMin);
            params.tokenOut.safeTransfer(params.recipient, amountOut);
            wethLeftFromFlashSwap = 0;
        }
    }


    /// ███ Market makers ██████████████████████████████████████████████████████

    /// @inheritdoc IRiseToken
    function swapExactCollateralForETH(uint256 _amountIn, uint256 _amountOutMin) external returns (uint256 _amountOut) {
        /// ███ Checks
        if (leverageRatio() > minLeverageRatio) revert NoNeedToRebalance();
        if (_amountIn == 0) return 0;

        // Discount the price
        uint256 price = oracleAdapter.price(address(collateral));
        price += (discount * price) / 1e18;
        _amountOut = (_amountIn * price) / (1e18);
        if (_amountOut < _amountOutMin) revert SlippageTooHigh();

        /// ███ Effects

        // Transfer collateral to the contract
        collateral.safeTransferFrom(msg.sender, address(this), _amountIn);

        // This is our buying power; can't buy collateral more than this
        uint256 borrowAmount = ((step * value((10**cdecimals), address(debt)) / 1e18) * totalSupply()) / (10**cdecimals);
        supplyThenBorrow(_amountIn, borrowAmount);

        // This will revert if _amountOut is too large; we can't buy the _amountIn
        debt.safeIncreaseAllowance(address(uniswapAdapter), borrowAmount);
        uint256 amountIn = uniswapAdapter.swapTokensForExactWETH(address(debt), _amountOut, borrowAmount);

        // If amountIn < borrow; then send back debt token to Rari Fuse
        if (amountIn < borrowAmount) {
            uint256 repayAmount = borrowAmount - amountIn;
            debt.safeIncreaseAllowance(address(fDebt), repayAmount);
            uint256 repayResponse = fDebt.repayBorrow(repayAmount);
            if (repayResponse != 0) revert FuseError(repayResponse);
            totalDebt = fDebt.borrowBalanceCurrent(address(this));
        }

        // Convert WETH to ETH
        weth.safeIncreaseAllowance(address(weth), _amountOut);
        weth.withdraw(_amountOut);

        /// ███ Interactions
        (bool sent, ) = msg.sender.call{value: _amountOut}("");
        if (!sent) revert FailedToSendETH(msg.sender, _amountOut);
    }

    /// @inheritdoc IRiseToken
    function swapExactETHForCollateral(uint256 _amountOutMin) external payable returns (uint256 _amountOut) {
        /// ███ Checks
        if (leverageRatio() < maxLeverageRatio) revert NoNeedToRebalance();
        if (msg.value == 0) return 0;

        // Discount the price
        uint256 price = oracleAdapter.price(address(collateral));
        price -= (discount * price) / 1e18;
        _amountOut = (msg.value * (10**cdecimals)) / price;
        if (_amountOut < _amountOutMin) revert SlippageTooHigh();

        // Convert ETH to WETH
        weth.deposit{value: msg.value}();

        // This is our selling power, can't sell more than this
        uint256 repayAmount = ((step * value((10**cdecimals), address(debt)) / 1e18) * totalSupply()) / (10**cdecimals);
        weth.safeIncreaseAllowance(address(uniswapAdapter), msg.value);
        uint256 repayAmountFromETH = uniswapAdapter.swapExactWETHForTokens(address(debt), msg.value, 0);
        if (repayAmountFromETH > repayAmount) revert LiquidityIsNotEnough();

        /// ███ Effects
        repayThenRedeem(repayAmountFromETH, _amountOut);

        /// ███ Interactions
        collateral.safeTransfer(msg.sender, _amountOut);
    }

    receive() external payable {}
}