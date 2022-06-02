// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A simple ERC20 contract
contract ERC20Mock is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_
    ) ERC20(name_, symbol_) {
        ERC20._mint(msg.sender, totalSupply_);
    }

    /**
     * @notice Return decimals ERC20 contract
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./ERC20Mock.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Tic-Tac-Toe game with betting
/// @author Starostin Dmitry
/// @notice Creation of a game party. Join the game party. Making a move. Checking combinations. Waiting time for a move player. Betting
/// @dev Contract under testing. v2.
contract TicTacToe is Initializable {
    address private owner; // owner address
    address private testProxy; // test variable for check memory error
    address private wallet; // wallet address
    IERC20 public token; // player money
    uint8 private commission = 10; // commision (percent of winning)
    uint256 private ethPerErc = 10**15; // price of one ERC (in eth)
    uint256 private heldERC = 0; // holding ERC
    uint256 private heldETH = 0; // holding ETH

    // for prevent reentrant calls to a function
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    enum State {
        FindPlayers, // Searching players
        EndFirst, // Move of the first player
        EndSecond, // Move of the second player
        Pause, // Pause searching for players
        Draw, // Draw
        WinFirst, // Win of the first player
        WinSecond, // Win of the second player
        CancelGame // Player canceled the game
    }

    struct Game {
        address player1; // master
        address player2; // slave
        uint8[9] grid; // Playing field
        uint256 timeStart; // Ending time of the move
        uint32 timeWait; // Waiting time of the move
        uint32 betERC; // Bet in the game (in ERC)
        uint256 betETH; // Bet in the game (in ETH)
        State state; // Game status
    }

    Game[] public games; // Games list
    uint8[3][8] private winCombinations = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [6, 4, 2]]; // All of the winning combinations
    mapping(address => uint256) playerGamesCount; // (player address => number of game)

    event EventGame(uint256 indexed _IdGame, State indexed _stateGame, address player1, address player2, uint256 value);
    event IncGameAcc(address indexed player, uint256 indexed amountERC);
    event SetWallet(address indexed newWalet);
    event SetCommission(uint256 indexed newCommission);
    event WithdrawalGameAcc(address indexed player, uint256 indexed amountERC);
    event PlaceBet(address indexed player, uint256 indexed bet);
    event ReturnWinERC(address indexed player, uint256 indexed amount);
    event TakeCommission(uint256 indexed amount);

    // Existence of the game
    modifier outOfRange(uint256 _idGame) {
        require(_idGame >= 0 && games.length > _idGame, "This game is not exist");
        _;
    }

    modifier onlyOwner() {
        //console.log("onlyOwner: %s", msg.sender);
        require(msg.sender == owner, "You are not the owner.");
        _;
    }

    // prevent reentrant calls to a function
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    function initialize(address _ERC20Address) external initializer {
        token = IERC20(_ERC20Address);
        owner = msg.sender;
        commission = 10; // commision (percent of winning)
        ethPerErc = 10**15; // price of one ERC (in eth)
        winCombinations = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [6, 4, 2]];
        heldERC = 0; // holding ERC
        heldETH = 0; // holding ETH
        _status = _NOT_ENTERED;
    }


    /// @notice Player is credit ETH to account
    function incGameAcc() external payable {
        require(msg.value > 0, "Need to ETH > 0");
        uint256 amountERC = msg.value / ethPerErc; // Total ERC
        require(amountERC > 0, "Need to send more ETH");
        uint256 AvailableERC = token.balanceOf(address(this)); // Number of available contract's ERC
        require(AvailableERC - heldERC >= amountERC, "Not enough ERC on contract");
        bool sent = token.transfer(msg.sender, amountERC); // ERC transaction from contract to player's account
        require(sent, "4"); // ERC transaction is not successful
        emit IncGameAcc(msg.sender, amountERC);
    }

    /// @notice Change address of wallet
    /// @param _wallet New wallet's address
    function setWallet(address _wallet) external onlyOwner {
        require(_wallet != address(0), "Address of new wallet is not correct");
        wallet = _wallet;
        emit SetWallet(_wallet);
    }

    /// @notice Change commision
    /// @param _commision New commision
    function setCommission(uint8 _commision) external onlyOwner {
        require(_commision >= 0 && _commision <= 100, "Commision is not correct");
        commission = _commision;
        emit SetCommission(_commision);
    }

    /// @notice Player withdraws ERC from account
    /// @param _amountERC Number of ERC
    function withdrawalGameAcc(uint256 _amountERC) external nonReentrant {
        //token.approve(address(this), _amountERC);
        require(_amountERC > 0, "Need to ERC > 0");
        uint256 playerBalanceERC = token.balanceOf(msg.sender); // Number of available player's ERC
        require(playerBalanceERC >= _amountERC, "Your ERC balance is less then you can sell");
        uint256 amountETH = _amountERC * ethPerErc; // Total ETH
        uint256 AvailableETH = address(this).balance; // Number of available contract's ETH
        require(AvailableETH >= amountETH, "Not enough ETH on contract #1");

        bool sent = token.transferFrom(msg.sender, address(this), _amountERC); // ERC transaction from player's account to contract
        require(sent, "ERC transaction is not successful");
        (sent, ) = msg.sender.call{value: amountETH}(""); // ETH transaction from contract to player's account
        require(sent, "ETH transaction is not successful");
        emit WithdrawalGameAcc(msg.sender, _amountERC);
    }

    /// @notice The player will cancel the game and return the bet
    /// @param _idGame Id game
    function cancelGame(uint256 _idGame) external payable {
        require(games[_idGame].state == State.FindPlayers || games[_idGame].state == State.Pause, "This game has already started");
        require(games[_idGame].player1 == msg.sender, "Only for creator of the game");
        require(games[_idGame].player2 == address(0));

    if (games[_idGame].betERC!=0) {
        uint256 AvailableERC = token.balanceOf(address(this)); // Number of available contract's ERC
        require(heldERC >= games[_idGame].betERC, "Not enough holding ERC on contract");
        require(AvailableERC >= heldERC, "Not enough ERC on contract");
        heldERC = heldERC - games[_idGame].betERC; // Unholding ERC to the player
        games[_idGame].state = State.CancelGame;
        bool sent = token.transfer(msg.sender, games[_idGame].betERC); // ERC transaction from contract to player's account contract
        require(sent, "ERC transaction is not successful");
        emit EventGame(_idGame, State.CancelGame, msg.sender, address(0), games[_idGame].betERC);
    }

    if (games[_idGame].betETH!=0) {
        uint256 AvailableETH = address(this).balance; // Number of available contract's ETH
        require(AvailableETH >= heldETH, "Not enough ETH on contract #2");
        require(heldETH >= games[_idGame].betETH, "Not enough ETH on contract #3");
        heldETH = heldETH - games[_idGame].betETH;
        games[_idGame].state = State.CancelGame;
        (bool sent, ) = (msg.sender).call{value: games[_idGame].betETH}(""); // ETH transaction from contract to player's account
        require(sent, "ETH transaction is not successful");
        emit EventGame(_idGame, State.CancelGame, msg.sender, address(0), games[_idGame].betETH);
    }
    }

    /// @notice Player creates a game and does the bet
    /// @param _timeWait Waiting time of the opponent's move
    /// @param _bet Bet
    function createGame(uint32 _timeWait, uint32 _bet) external payable {
        require(_bet > 0 || msg.value > 0, "Bet must be more than zero!");
        require(_bet <= 1000, "Bet must be less than 1000!");
        require(_timeWait > 0, "TimeWait must be more 0");
        games.push(Game({player1: msg.sender, player2: address(0), grid: [0, 0, 0, 0, 0, 0, 0, 0, 0], timeStart: 0, timeWait: _timeWait, betERC: 0, betETH: 0, state: State.FindPlayers})); // Add a new game to the list
        playerGamesCount[msg.sender]++; // Increasing number of games for player

        emit EventGame(games.length - 1, State.FindPlayers, msg.sender, address(0), _timeWait);

        if (msg.value == 0) {
            games[games.length - 1].betERC = _bet;
            placeBet(msg.sender, _bet); // Player does the bet
            emit PlaceBet(msg.sender, _bet);
        } else {
            heldETH = heldETH + msg.value; // Holding player's ETH
            games[games.length - 1].betETH = msg.value;
            emit PlaceBet(msg.sender, msg.value);
        }
    }

    /// @notice Pause/Continue searching of player for the game
    /// @param _idGame Id game
    function pauseGame(uint256 _idGame) external outOfRange(_idGame) {
        require(games[_idGame].state == State.FindPlayers || games[_idGame].state == State.Pause, "This game has already started");
        require(games[_idGame].player1 == msg.sender, "Only for creator of the game");
        require(games[_idGame].player2 == address(0));
        if (games[_idGame].state == State.FindPlayers) {
            games[_idGame].state = State.Pause; // Pause of searching
            emit EventGame(_idGame, State.Pause, msg.sender, address(0), 1);
        } else if (games[_idGame].state == State.Pause) {
            games[_idGame].state = State.FindPlayers; // Continue of searching
            emit EventGame(_idGame, State.Pause, msg.sender, address(0), 0);
        }
    }

    /// @notice  Player joins the new game and does the bet
    /// @param _idGame Id game
    function joinGame(uint256 _idGame) external payable outOfRange(_idGame) {
        require(games[_idGame].state == State.FindPlayers, "This game is not available to join");
        require(games[_idGame].player1 != msg.sender, "You are the player1");
        require(games[_idGame].player2 == address(0), "The second player has been already exist");
        games[_idGame].player2 = msg.sender;
        games[_idGame].timeStart = block.timestamp; // Saving time of ending the move
        games[_idGame].state = State.EndSecond; // Move of the second player
        playerGamesCount[msg.sender]++; // Increasing number of games of the player
        emit EventGame(_idGame, State.EndSecond, games[_idGame].player1, msg.sender, games[_idGame].timeWait);

        if (msg.value == 0) {
            placeBet(msg.sender, games[_idGame].betERC); // Player does the bet
            emit PlaceBet(msg.sender, games[_idGame].betERC);
        } else {
            require(msg.value == games[_idGame].betETH, "Bet must be the identical");
            heldETH = heldETH + msg.value; // Holding player's ETH
            emit PlaceBet(msg.sender, msg.value);
        }
    }

    /// @notice Player's move
    /// @param _idGame Id game
    /// @param _cell Cell of the playing field
    function movePlayer(uint256 _idGame, uint256 _cell) external outOfRange(_idGame) {
        require(_cell >= 0 && _cell <= 8, "This grid 3x3. Cell from 0 to 8");
        require((games[_idGame].player1 == msg.sender && games[_idGame].state == State.EndSecond) || (games[_idGame].player2 == msg.sender && games[_idGame].state == State.EndFirst), "It's not your turn to move!");
        require(games[_idGame].grid[_cell] == 0, "Cell is not free!");
        require(checkingCombinations(games[_idGame].grid), "Game over. Winning combination is completed");
        require(checkingDraw(games[_idGame].grid), "Game over. Draw combination is completed");
        require(checkingTimeOut(games[_idGame].timeStart + games[_idGame].timeWait), "Game over. Your time to move is over");

        // Move of the firt or the second player
        if (games[_idGame].state == State.EndSecond) {
            games[_idGame].grid[_cell] = 1;
            games[_idGame].state = State.EndFirst;
            games[_idGame].timeStart = block.timestamp;
        } else if (games[_idGame].state == State.EndFirst) {
            games[_idGame].grid[_cell] = 2;
            games[_idGame].state = State.EndSecond;
            games[_idGame].timeStart = block.timestamp;
        }
        emit EventGame(_idGame, games[_idGame].state, games[_idGame].player1, games[_idGame].player2, _cell);
        this.isFinish(_idGame);
    }

    /// @notice Checking status of the game. Paying for winning. Sending commission on wallet.
    /// @param _idGame Id game
    function isFinish(uint256 _idGame) external outOfRange(_idGame) {
        require(games[_idGame].state == State.EndFirst || games[_idGame].state == State.EndSecond, "Game is not active");
        if (checkingCombinations(games[_idGame].grid) == false) {
            // There is the winning combination on the field
            games[_idGame].state = nominationWinner(games[_idGame].state); // Who has won the game
            emit EventGame(_idGame, games[_idGame].state, games[_idGame].player1, games[_idGame].player2, 0);

            if (games[_idGame].betERC != 0) {
                returnWinERC(pickWinner(games[_idGame]), 2 * games[_idGame].betERC);
            } else {
                returnWinETH(pickWinner(games[_idGame]), 2 * games[_idGame].betETH);
            }
            return;
        }

        if (checkingDraw(games[_idGame].grid) == false) {
            // There is the draw combination on the field
            games[_idGame].state = State.Draw;
            emit EventGame(_idGame, games[_idGame].state, games[_idGame].player1, games[_idGame].player2, 1);

            if (games[_idGame].betERC != 0) {
                returnWinERC(games[_idGame].player1, games[_idGame].betERC);
                returnWinERC(games[_idGame].player2, games[_idGame].betERC);
            } else {
                returnWinETH(games[_idGame].player1, games[_idGame].betETH);
                returnWinETH(games[_idGame].player2, games[_idGame].betETH);
            }
            return;
        }

        if (checkingTimeOut(games[_idGame].timeStart + games[_idGame].timeWait) == false) {
            // Waiting time of the opponent's move is over
            games[_idGame].state = nominationWinner(games[_idGame].state); // Who has won the game
            emit EventGame(_idGame, games[_idGame].state, games[_idGame].player1, games[_idGame].player2, 2);

            if (games[_idGame].betERC != 0) {
                returnWinERC(pickWinner(games[_idGame]), 2 * games[_idGame].betERC);
            } else {
                returnWinETH(pickWinner(games[_idGame]), 2 * games[_idGame].betETH);
            }
            return;
        }
        return;
    }

    /// @notice Get the wallet address
    /// @return address Wallet address
    function getWallet() external view onlyOwner returns (address) {
        return wallet;
    }

    /// @notice Get commission
    /// @return uint256 Commission
    function getCommission() public view onlyOwner returns (uint256) {
        return commission;
    }

    /// @notice Get number of the holding ERC
    /// @return uint256 Holding ERC
    function getHeldERC() external view onlyOwner returns (uint256) {
        return heldERC;
    }

    /// @notice Get number of the holding ETH
    /// @return uint256 Holding ETH
    function getHeldETH() external view onlyOwner returns (uint256) {
        return heldETH;
    }

    /// @notice Get player's balance in ERC
    /// @param _player Player's address
    /// @return uint256 Balance in ERC
    function balancePlayer(address _player) external view returns (uint256) {
        uint256 balance = token.balanceOf(_player);
        return balance;
    }

    /// @notice Searching a new game
    /// @param _indexBegin Id game to begin the search
    /// @param _timeMin Minimum of waiting time of the move
    /// @param _timeMax Maximum of waiting time of the move
    /// @param _betMin Minimum bet
    /// @param _betMax Maximum bet
    /// @return index Id of finding
    function findOneGame(
        uint256 _indexBegin,
        uint256 _timeMin,
        uint256 _timeMax,
        uint256 _betMin,
        uint256 _betMax
    ) external view returns (uint256) {
        require(_indexBegin >= 0 && _indexBegin < games.length && _timeMin >= 0 && _timeMax >= _timeMin && _betMin >= 0 && _timeMax >= _betMin, "The input parameters are not correct");
        for (uint256 i = _indexBegin; i < games.length; i++) {
            if (games[i].player1 != msg.sender && games[i].state == State.FindPlayers && games[i].timeWait >= _timeMin && games[i].timeWait <= _timeMax && games[i].betERC >= _betMin && games[i].betERC <= _betMax) return i;
        }
        require(false, "There are no games with such parameters.");
        return 0;
    }

    /// @notice Getting information of the game
    /// @param _idGame Game Id
    /// @return Game Full information of the game
    function getOneGame(uint256 _idGame) external view outOfRange(_idGame) returns (Game memory) {
        return games[_idGame];
    }

    /// @notice Geting all the games of the player
    /// @param _player The address of the player
    /// @return GamesId Ids of games of the player
    function getGamesByPlayer(address _player) external view returns (uint256[] memory) {
        require(playerGamesCount[_player] > 0, "Player hasn't any games");
        uint256[] memory arrayId = new uint256[](playerGamesCount[_player]);
        uint256 index = 0;
        for (uint256 i = 0; i < games.length; i++) {
            if (games[i].player1 == _player || games[i].player2 == _player) {
                arrayId[index] = i;
                index++;
            }
        }
        return arrayId;
    }

    /// @notice Getting statistics of the player
    /// @param _player The address player
    /// @return StatisticPlayer [number of games, % of winning games, % of losing games , % of drawing games, % of active games]
    function statisticsPlayer(address _player) external view returns (uint256[] memory) {
        require(playerGamesCount[_player] > 0, "Player hasn't any games");
        uint256[] memory statistics = new uint256[](5); // [number of games, % of winning games, % of losing games , % of drawing games, % of active games]
        statistics[0] = playerGamesCount[_player];

        for (uint256 i = 0; i < games.length; i++) {
            if (games[i].player1 == _player) {
                if (games[i].state == State.WinFirst) {
                    statistics[1]++;
                } else if (games[i].state == State.WinSecond) {
                    statistics[2]++;
                } else if (games[i].state == State.Draw) {
                    statistics[3]++;
                } else {
                    statistics[4]++;
                }
            } else if (games[i].player2 == _player) {
                if (games[i].state == State.WinFirst) {
                    statistics[2]++;
                } else if (games[i].state == State.WinSecond) {
                    statistics[1]++;
                } else if (games[i].state == State.Draw) {
                    statistics[3]++;
                } else {
                    statistics[4]++;
                }
            }
        }
        for (uint256 i = 1; i < statistics.length; i++) statistics[i] = (statistics[i] * 100) / statistics[0]; // Calculation of percent
        return statistics;
    }

    /// @notice Getting statistics of all games
    /// @return StatisticGames [number of games, % of winning the first player, % of winning the second player, % of drawing games, % of active games]
    function statisticsGames() external view returns (uint256[] memory) {
        require(games.length > 0, "Such games are not exist!");
        uint256[] memory statistics = new uint256[](5); // [number of games, % of winning the first player, % of winning the second player, % of drawing games, % of active games]
        statistics[0] = games.length;

        for (uint256 i = 0; i < games.length; i++) {
            if (games[i].state == State.WinFirst) {
                statistics[1]++;
            } else if (games[i].state == State.WinSecond) {
                statistics[2]++;
            } else if (games[i].state == State.Draw) {
                statistics[3]++;
            } else {
                statistics[4]++;
            }
        }
        for (uint256 i = 1; i < statistics.length; i++) statistics[i] = (statistics[i] * 100) / statistics[0]; // Calculation of percent
        return statistics;
    }

    /// @notice Get function of testing Proxy
    /// @return uint256 const value 10
    function getTest() external pure returns (uint256) {
        return 10;
    }

    /// @notice Pay the winning to the player. Send the commission to the wallet. (In ETH)
    /// @param _winner Player address
    /// @param _doubleBetETH Winning (betx2)
    function returnWinETH(address _winner, uint256 _doubleBetETH) private nonReentrant {
        uint256 amountPlayerWin = (_doubleBetETH * (100 - commission)) / 100; // Calculate the player's winning (in ETH)
        uint256 amountCommission = _doubleBetETH - amountPlayerWin; // Calculate the commission (in ERC)
        require(amountPlayerWin > 0, "The winning > 0");
        require(amountCommission > 0, "The commission > 0");

        uint256 AvailableETH = address(this).balance; // Number of available contract's ETH
        require(AvailableETH >= _doubleBetETH, "Not enough ETH on contract #2");
        require(heldETH >= amountPlayerWin, "Not enough ETH on contract #3");
        heldETH = heldETH - amountPlayerWin;
        (bool sent, ) = (_winner).call{value: amountPlayerWin}(""); // ETH transaction from contract to player's account
        require(sent, "ETH transaction is not successful");

        require(heldETH >= amountCommission, "Not enough ETH on contract #3");
        heldETH = heldETH - amountCommission;
        (sent, ) = wallet.call{value: amountCommission}(""); // ETH transaction from contract to wallet
        require(sent, "ETH transaction is not successful");
    }

    /// @notice Player does the bet
    /// @param _player Player's address
    /// @param _bet Bet
    function placeBet(address _player, uint256 _bet) private {
        require(_bet > 0, "Need to ERC > 0");
        uint256 playerBalanceERC = token.balanceOf(_player); // Number of available player's ERC
        require(playerBalanceERC >= _bet, "Yours ERC balance is less, than you can put a bet");
        heldERC = heldERC + _bet; // Holding player's ERC
        bool sent = token.transferFrom(_player, address(this), _bet); // ERC transaction from player's account to contract
        require(sent, "ERC transaction is not successful");

        emit PlaceBet(_player, _bet);
    }

    /// @notice Pay the winning to the player. Send the commission to the wallet.
    /// @param _player Player address
    /// @param _doubleBet Winning (betx2)
    function returnWinERC(address _player, uint256 _doubleBet) private {
        uint256 amountPlayerWin = (_doubleBet * (100 - commission)) / 100; // Calculate the player's winning
        uint256 amountCommission = _doubleBet - amountPlayerWin; // Calculate the commission
        require(amountPlayerWin > 0, "The winning > 0");
        require(amountCommission > 0, "The commission > 0");
        uint256 AvailableERC = token.balanceOf(address(this)); // Number of available contract's ERC
        require(heldERC >= amountPlayerWin, "Not enough holding ERC on contract");
        require(AvailableERC >= heldERC, "Not enough ERC on contract");
        heldERC = heldERC - _doubleBet; // Unholding ERC to the player
        bool sent = token.transfer(_player, amountPlayerWin); // ERC transaction from contract to player's account contract
        require(sent, "ERC transaction is not successful");

        takeCommission(amountCommission); // Send the commission to the wallet
        require(sent, "ETH transaction is not successful");

        emit ReturnWinERC(_player, _doubleBet);
    }

    /// @notice Send the commission to the wallet
    /// @param _Commission Commission
    function takeCommission(uint256 _Commission) private nonReentrant {
        require(_Commission > 0, "The commission > 0");
        uint256 amountETH = _Commission * ethPerErc; // Total number of ETH
        uint256 AvailableETH = address(this).balance; // Number of available contract's ETH
        require(AvailableETH >= amountETH, "Not enough ETH on contract #8");
        (bool sent, ) = wallet.call{value: amountETH}(""); // ETH transaction from contract to wallet
        require(sent, "ETH transaction is not successful");
        emit TakeCommission(_Commission);
    }

    /// @notice Checking the winning combination on the field
    /// @param _grid Playing field
    /// @return bool Result of checking (inverse)
    function checkingCombinations(uint8[9] storage _grid) private view returns (bool) {
        for (uint256 i = 0; i < winCombinations.length; i++) {
            if ((_grid[winCombinations[i][0]] == uint256(1) && _grid[winCombinations[i][1]] == uint256(1) && _grid[winCombinations[i][2]] == uint256(1)) || (_grid[winCombinations[i][0]] == uint256(2) && _grid[winCombinations[i][1]] == uint256(2) && _grid[winCombinations[i][2]] == uint256(2))) 
                return false;
        }
        return true;
    }

    /// @notice Checking the drawing combination on the field
    /// @param _grid Playing field
    /// @return bool Result of checking (inverse)
    function checkingDraw(uint8[9] storage _grid) private view returns (bool) {
        for (uint256 i = 0; i < _grid.length; i++) {
            if (_grid[i] == 0) return true;
        }
        return false;
    }

    /// @notice Checking the waiting time of the opponent's move is over
    /// @param _timeNow  Time of the beginning move + time of doing move
    /// @return bool Result of checking
    function checkingTimeOut(uint256 _timeNow) private view returns (bool) {
        return (block.timestamp <= _timeNow);
    }

    /// @notice Who has won the game
    /// @param _game Game
    /// @return address Winner's address
    function pickWinner(Game storage _game) private view returns (address) {
        if (_game.state == State.WinFirst) return _game.player1;
        if (_game.state == State.WinSecond) return _game.player2;
        return address(0);
    }

    /// @notice Who has won the game
    /// @param _state Status of the game
    /// @return newState New status of the game
    function nominationWinner(State _state) private pure returns (State) {
        if (_state == State.EndFirst) return State.WinFirst;
        if (_state == State.EndSecond) return State.WinSecond;
        return _state;
    }
}