// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

pragma solidity ^0.8.0;

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

/*
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import {IWETH} from "./interfaces/IWETH.sol";
import {IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "./interfaces/IUniswapV2Factory.sol";
import {IValidator} from "./interfaces/IValidator.sol";

/**
 * @title BridgeBank
 * @dev Bank contract which coordinates asset-related functionality.
 *      EthBank manages the locking and unlocking of ETH/ERC20 token assets
 *      based on eth.
 **/

contract BridgeBank is
    Initializable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;

    address public uniswapV2Router02;
    address public validatorSetter;

    mapping(uint256 => address) public registerChain;
    // mapping()
    uint256 public chainId;
    address public stableToken;
    address public WETH;

    uint256 public lockBurnNonce;

    struct LockData {
        bool isRefunded;
        address sender;
        address tokenSource;
        uint256 amountTokenIn;
        uint256 amountStableToken;
        uint256 _minStableToken;
        uint256 _slipPercentage;
        uint256 toChainId;
    }
    struct UnlockData {
        bool isUnlocked;
        address recipient;
        address tokenDestination;
        uint256 amountStableToken;
        uint256 amountTokenOut;
    }
    // Mapping and check if the refunds transaction is completed
    mapping(uint256 => LockData) public lockCompleted;
    // Mapping and check if the unlock transaction is completed
    mapping(bytes32 => UnlockData) public unlockCompleted;

    // 1% -> 100
    uint256 public PROTOCOL_FEE;

    // avoid Stack too deep, try removing local variables.
    uint256 minReceiveToken;
    uint256 minStableToken;

    event LogLock(
        address _from,
        address _to,
        address _tokenSource,
        address _tokenDestination,
        uint256 _amountTokenIn,
        uint256 _amountStableToken,
        uint256 _nonce,
        uint256 _fromChainId,
        uint256 _toChainId,
        uint256 _minStableToken,
        uint256 _minReceiveToken
    );

    event LogUnlock(
        address _to,
        address _tokenDestination,
        uint256 _value,
        uint256 _stableTokenSwap,
        uint256 _originStableToken,
        bytes32 _interchainTX
    );

    event Refund(
        uint256 _nonce,
        address _sender,
        address _tokenSource,
        uint256 _amountTokenIn,
        uint256 _fromChainId
    );

    event TotalFee(
        bytes32 _interchainTX,
        uint256 _protocolFee,
        uint256 _gasFee
    );

    event LogSubmitRegisterChain(address _addressBank, uint256 _chainId);

    event NewProtocolFee(uint256 protocol_fee);

    event LogEmergencyWithdraw(uint256 amount, address toContract);

    /*
     * @dev: Constructor, sets operator
     */

    function initialize(
        address _WETH,
        uint256 _chainId,
        address _uniswapV2Router02addr,
        address _stableToken,
        address _validatorSetter
    ) public payable initializer {
        WETH = _WETH;
        chainId = _chainId;
        uniswapV2Router02 = _uniswapV2Router02addr;
        stableToken = _stableToken;
        validatorSetter = _validatorSetter;
        lockBurnNonce = 0;
        __ReentrancyGuard_init();
        __Pausable_init();
        __Ownable_init();
    }

    fallback() external payable {}

    receive() external payable {}

    function getLockedFunds() public view returns (uint256) {
        return IERC20(stableToken).balanceOf(address(this));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /*
     * @dev: Locks received ETH/ERC20 funds.
     *
     * @param _recipient: representation of destination address.
     * @param _token: token address in origin chain (0x0 if ethereum)
     * @param _amount: value of deposit
     */
    function lock(
        address _recipient,
        address _tokenSource,
        uint256 _minStableToken,
        uint256 _minReceiveToken,
        address _tokenDestination,
        uint256 _amountTokenIn,
        uint256 _toChainId
    ) public payable nonReentrant whenNotPaused {
        //check destination chainId

        require(
            registerChain[_toChainId] != address(0),
            "not yet register chain"
        );

        uint256 stableTokenBefore = IERC20(stableToken).balanceOf(
            address(this)
        );

        address _tempTokenSource = _tokenSource;

        if (msg.value > 0) {
            IWETH(WETH).deposit{value: msg.value}();
            _tempTokenSource = WETH;
            _amountTokenIn = msg.value;
        }

        if (_tempTokenSource != address(0) && msg.value == 0) {
            IERC20(_tempTokenSource).safeTransferFrom(
                msg.sender,
                address(this),
                _amountTokenIn
            );
        }

        address[] memory paths = new address[](2);
        paths[0] = _tempTokenSource;
        paths[1] = stableToken;

        // swap token -> usdc
        if (_tempTokenSource != stableToken) {
            _checkAndAdjustTokenAllowanceIfRequired(
                _tempTokenSource,
                _amountTokenIn,
                uniswapV2Router02
            );
            IUniswapV2Router02(uniswapV2Router02).swapExactTokensForTokens(
                _amountTokenIn,
                _minStableToken,
                paths,
                address(this),
                block.timestamp + 1000
            );
        } else {
            _minStableToken = _amountTokenIn;
        }

        uint256 stableTokenAfter = IERC20(stableToken).balanceOf(address(this));

        //save data
        lockBurnNonce++;

        lockCompleted[lockBurnNonce] = LockData(
            false,
            msg.sender,
            _tokenSource,
            _amountTokenIn,
            stableTokenAfter - stableTokenBefore,
            _minStableToken,
            _minReceiveToken,
            _toChainId
        );

        minStableToken = _minStableToken;
        minReceiveToken = _minReceiveToken;

        emit LogLock(
            msg.sender,
            _recipient,
            _tokenSource,
            _tokenDestination,
            _amountTokenIn,
            stableTokenAfter - stableTokenBefore,
            lockBurnNonce,
            chainId,
            _toChainId,
            minStableToken,
            minReceiveToken
        );
    }

    function unlock(
        uint8[] memory _sigV,
        bytes32[] memory _sigR,
        bytes32[] memory _sigS,
        address payable _recipient,
        address _tokenDestination,
        uint256 _amountStableToken,
        bytes32 _interchainTX,
        uint256 _chainId,
        uint256 _gasFee,
        uint256 _minReceiveToken
    ) public nonReentrant whenNotPaused {
        require(
            _gasFee < _amountStableToken,
            "gas fee must be less than stable token amount in"
        );
        require(_chainId == chainId, "not correct chainId");
        require(
            IValidator(validatorSetter).checkUnlockSig(
                _sigV,
                _sigR,
                _sigS,
                _recipient,
                _tokenDestination,
                _amountStableToken,
                _interchainTX,
                _chainId
            ),
            "fail to check unlock sig"
        );
        _amountStableToken -= _gasFee;
        require(
            unlockCompleted[_interchainTX].isUnlocked == false,
            "Processed before"
        );
        uint256 fee = (_amountStableToken * PROTOCOL_FEE) / 10000;
        // Check if it is ETH
        require(
            IERC20(stableToken).balanceOf(address(this)) >=
                _amountStableToken - fee,
            "Insufficient ERC20 balance."
        );

        address[] memory paths = new address[](2);
        address _tempTokenDestination = _tokenDestination;
        if (_tokenDestination == address(0)) {
            _tempTokenDestination = WETH;
        }
        paths[0] = stableToken;
        paths[1] = _tempTokenDestination;
        uint256 transferAmount = _amountStableToken - fee;
        uint256 _beforeSwap = IERC20(_tempTokenDestination).balanceOf(
            address(this)
        );
        if (_tempTokenDestination != stableToken) {
            _checkAndAdjustTokenAllowanceIfRequired(
                stableToken,
                _amountStableToken - fee,
                uniswapV2Router02
            );
            IUniswapV2Router02(uniswapV2Router02).swapExactTokensForTokens(
                _amountStableToken - fee,
                _minReceiveToken,
                paths,
                address(this),
                block.timestamp + 1000
            );
            transferAmount =
                IERC20(_tempTokenDestination).balanceOf(address(this)) -
                _beforeSwap;
        }

        if (_tokenDestination == address(0)) {
            IWETH(WETH).withdraw(transferAmount);
            _recipient.transfer(transferAmount);
        } else {
            IERC20(_tokenDestination).safeTransfer(_recipient, transferAmount);
        }

        unlockCompleted[_interchainTX] = UnlockData(
            true,
            _recipient,
            _tokenDestination,
            _amountStableToken - fee,
            transferAmount
        );

        emit TotalFee(_interchainTX, fee, _gasFee);

        emit LogUnlock(
            _recipient,
            _tokenDestination,
            transferAmount,
            _amountStableToken - fee,
            _amountStableToken + _gasFee,
            _interchainTX
        );
    }

    function refund(
        uint8[] memory _sigV,
        bytes32[] memory _sigR,
        bytes32[] memory _sigS,
        uint256 _nonce,
        uint256 _chainId
    ) public nonReentrant whenNotPaused {
        require(_chainId == chainId, "not correct chainId");
        require(
            IValidator(validatorSetter).checkRefundSig(
                _sigV,
                _sigR,
                _sigS,
                _nonce,
                _chainId
            ),
            "fail to check refund sig"
        );
        require(
            lockCompleted[_nonce].isRefunded == false &&
                lockCompleted[_nonce].sender != address(0),
            "Refunded before"
        );
        // Check if it is ETH
        require(
            IERC20(stableToken).balanceOf(address(this)) >=
                lockCompleted[_nonce].amountStableToken,
            "Insufficient ERC20 balance."
        );

        // address[] memory paths = new address[](2);
        // address _tempTokenSource = lockCompleted[_nonce].tokenSource;
        // if (_tempTokenSource == address(0)) {
        //     _tempTokenSource = WETH;
        // }
        // paths[0] = stableToken;
        // paths[1] = _tempTokenSource;

        // uint256 amountStableToRefund;
        // uint256 _beforeSwap = IERC20(_tempTokenSource).balanceOf(address(this));

        // if (_tempTokenSource != stableToken) {
        //     _checkAndAdjustTokenAllowanceIfRequired(
        //         stableToken,
        //         lockCompleted[_nonce].amountStableToken,
        //         uniswapV2Router02
        //     );
        //     IUniswapV2Router02(uniswapV2Router02).swapTokensForExactTokens(
        //         lockCompleted[_nonce].amountTokenIn,
        //         lockCompleted[_nonce].amountStableToken * 2,
        //         paths,
        //         address(this),
        //         block.timestamp + 1000
        //     );
        //     amountStableToRefund =
        //         IERC20(_tempTokenSource).balanceOf(address(this)) -
        //         _beforeSwap;
        // }

        // if (_tempTokenSource == address(0)) {
        //     IWETH(WETH).withdraw(amountStableToRefund);
        //     payable(lockCompleted[_nonce].sender).transfer(
        //         amountStableToRefund
        //     );
        // } else {
        //     IERC20(_tempTokenSource).safeTransfer(
        //         lockCompleted[_nonce].sender,
        //         amountStableToRefund
        //     );
        // }

        IERC20(stableToken).safeTransfer(
            lockCompleted[_nonce].sender,
            lockCompleted[_nonce].amountStableToken
        );

        lockCompleted[_nonce].isRefunded = true;

        emit Refund(
            _nonce,
            lockCompleted[_nonce].sender,
            lockCompleted[_nonce].tokenSource,
            lockCompleted[_nonce].amountTokenIn,
            chainId
        );
    }

    function getValidators() public view returns (address[] memory) {
        return IValidator(validatorSetter).getValidators();
    }

    function submitRegisterChain(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address addressBank,
        uint256 _chainId
    ) public nonReentrant whenPaused {
        lockBurnNonce++;
        require(
            IValidator(validatorSetter).checkSubmitRegisterChain(
                sigV,
                sigR,
                sigS,
                addressBank,
                _chainId,
                lockBurnNonce
            )
        );
        registerChain[_chainId] = addressBank;
        emit LogSubmitRegisterChain(addressBank, _chainId);
    }

    function updateProtocolFee(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        uint256 protocol_fee_
    ) public nonReentrant whenPaused {
        require(protocol_fee_ > 0, "protocol fee must be greater than zero");
        require(protocol_fee_ < 5000, "protocol fee must be less than 50%");

        lockBurnNonce++;
        require(
            IValidator(validatorSetter).checkUpdateProtocolFee(
                sigV,
                sigR,
                sigS,
                protocol_fee_,
                lockBurnNonce
            )
        );

        PROTOCOL_FEE = protocol_fee_;
        emit NewProtocolFee(protocol_fee_);
    }

    function _checkAndAdjustTokenAllowanceIfRequired(
        address _token,
        uint256 _amount,
        address _to
    ) internal {
        if (IERC20(_token).allowance(address(this), _to) < _amount) {
            IERC20(_token).approve(_to, type(uint256).max);
        }
    }

    function _getExactTokenForToken(
        uint256 _amountTokenIn,
        address[] memory path
    ) internal view returns (uint256) {
        return
            IUniswapV2Router02(uniswapV2Router02).getAmountsOut(
                _amountTokenIn,
                path
            )[1];
    }

    function _getTokenForExactToken(
        uint256 _amountTokenOut,
        address[] memory path
    ) internal view returns (uint256) {
        return
            IUniswapV2Router02(uniswapV2Router02).getAmountsIn(
                _amountTokenOut,
                path
            )[0];
    }

    function _getImpactTokenOut(uint256 _amountTokenIn, address[] memory path)
        internal
        view
        returns (uint256, uint256)
    {
        address factory = IUniswapV2Router02(uniswapV2Router02).factory();
        address getSushiToken = IUniswapV2Factory(factory).getPair(
            path[0],
            path[1]
        );

        uint256[2] memory reserve = [
            IERC20(path[0]).balanceOf(getSushiToken) + _amountTokenIn,
            IERC20(path[1]).balanceOf(getSushiToken) -
                _getExactTokenForToken(_amountTokenIn, path)
        ];

        return (
            _getExactTokenForToken(_amountTokenIn, path),
            IUniswapV2Router02(uniswapV2Router02).getAmountOut(
                _amountTokenIn,
                reserve[0],
                reserve[1]
            )
        );
    }

    function _getImpactTokenIn(uint256 _amountTokenOut, address[] memory path)
        internal
        view
        returns (uint256, uint256)
    {
        address factory = IUniswapV2Router02(uniswapV2Router02).factory();
        address getSushiToken = IUniswapV2Factory(factory).getPair(
            path[0],
            path[1]
        );

        uint256[2] memory reserve = [
            IERC20(path[0]).balanceOf(getSushiToken) +
                _getTokenForExactToken(_amountTokenOut, path),
            IERC20(path[1]).balanceOf(getSushiToken) - _amountTokenOut
        ];

        return (
            _getTokenForExactToken(_amountTokenOut, path),
            IUniswapV2Router02(uniswapV2Router02).getAmountIn(
                _amountTokenOut,
                reserve[0],
                reserve[1]
            )
        );
    }

    function getImpactGetExactTokenForStableToken(
        uint256 _amountTokenIn,
        address _tokenInAddr
    ) external view returns (uint256 amountOutCurrent, uint256 amountOutAfter) {
        address[] memory path = new address[](2);
        path[0] = _tokenInAddr == address(0) ? WETH : _tokenInAddr;
        path[1] = stableToken;

        return _getImpactTokenOut(_amountTokenIn, path);
    }

    function getImpactGetExactStableTokenForToken(
        uint256 _amountStableTokenIn,
        address _tokenOutAddr
    )
        external
        view
        returns (
            uint256 amountInCurrent,
            uint256 amountInAfter,
            uint256 _amount_protocol
        )
    {
        address[] memory path = new address[](2);
        path[0] = stableToken;
        path[1] = _tokenOutAddr == address(0) ? WETH : _tokenOutAddr;
        _amount_protocol = (_amountStableTokenIn * PROTOCOL_FEE) / 10000;
        _amountStableTokenIn = _amountStableTokenIn - _amount_protocol;
        (amountInCurrent, amountInAfter) = _getImpactTokenOut(
            _amountStableTokenIn,
            path
        );
    }

    function getImpactGetTokenForExactStableToken(
        uint256 _amountStableTokenOut,
        address _tokenInAddr
    ) external view returns (uint256 amountOutCurrent, uint256 amountOutAfter) {
        address[] memory path = new address[](2);
        path[0] = stableToken;
        path[1] = _tokenInAddr == address(0) ? WETH : _tokenInAddr;

        return _getImpactTokenIn(_amountStableTokenOut, path);
    }

    function getImpactGetStableTokenForExactToken(
        uint256 _amountTokenOut,
        address _tokenOutAddr
    )
        external
        view
        returns (
            uint256 amountInCurrent,
            uint256 amountInAfter,
            uint256 _amount_protocol
        )
    {
        address[] memory path = new address[](2);
        path[0] = stableToken;
        path[1] = _tokenOutAddr == address(0) ? WETH : _tokenOutAddr;

        (amountInCurrent, amountInAfter) = _getImpactTokenIn(
            _amountTokenOut,
            path
        );

        amountInCurrent = amountInCurrent * (10000 / (10000 - PROTOCOL_FEE));
        amountInAfter = amountInAfter * (10000 / (10000 - PROTOCOL_FEE));
        _amount_protocol = (amountInCurrent * PROTOCOL_FEE) / 10000;
    }

    function emergencyWithdraw(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address _toNewContract
    ) public nonReentrant whenPaused {
        lockBurnNonce++;
        require(
            IValidator(validatorSetter).checkEmerGencyWithDraw(
                sigV,
                sigR,
                sigS,
                _toNewContract,
                lockBurnNonce
            ),
            "Invalid signature"
        );

        uint256 amount = IERC20(stableToken).balanceOf(address(this));
        // Check if it is ETH
        IERC20(stableToken).safeTransfer(_toNewContract, amount);

        emit LogEmergencyWithdraw(amount, _toNewContract);
    }
}

// SPDX-License-Identifier: GNU
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: GNU
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IValidator {
    event LogSubmitValidators(address[] validators);

    function getValidators() external view returns (address[] memory);

    function submitValidators(
        address[] memory validators,
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS
    ) external;

    function checkUnlockSig(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address payable _recipient,
        address _tokenDestination,
        uint256 _amountStableToken,
        bytes32 _interchainTX,
        uint256 _chainId
    ) external view returns (bool);

    function checkRefundSig(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        uint256 _nonce,
        uint256 _chainId
    ) external view returns (bool);

    function checkSubmitRegisterChain(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address addressBank,
        uint256 _chainId,
        uint256 nonce
    ) external view returns (bool);

    function checkUpdateProtocolFee(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        uint256 protocol_fee_,
        uint256 nonce
    ) external view returns (bool);

    function checkEmerGencyWithDraw(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address _toNewContract,
        uint256 nonce
    ) external view returns (bool);
}

// SPDX-License-Identifier: GNU
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address spender, uint256 amount) external;
}