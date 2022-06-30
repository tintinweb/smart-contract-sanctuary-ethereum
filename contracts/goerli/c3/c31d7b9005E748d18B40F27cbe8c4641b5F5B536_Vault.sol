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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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
pragma solidity >=0.5.0;

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
pragma solidity >=0.5.0;
import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

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
pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC3156FlashLender.sol";

interface IXVault is IERC3156FlashLender {
    // ************** //
    // *** EVENTS *** //
    // ************** //

    /// @notice Emitted on deposit
    /// @param token being deposited
    /// @param from address making the depsoit
    /// @param to address to credit the tokens being deposited
    /// @param amount being deposited
    /// @param shares the represent the amount deposited in the vault
    event Deposit(IERC20 indexed token, address indexed from, address indexed to, uint256 amount, uint256 shares);

    /// @notice Emitted on withdraw
    /// @param token being deposited
    /// @param from address making the depsoit
    /// @param to address to credit the tokens being withdrawn
    /// @param amount Amount of underlying being withdrawn
    /// @param shares the represent the amount withdraw from the vault
    event Withdraw(IERC20 indexed token, address indexed from, address indexed to, uint256 shares, uint256 amount);

    event Transfer(IERC20 indexed token, address indexed from, address indexed to, uint256 amount);

    event FlashLoan(address indexed borrower, IERC20 indexed token, uint256 amount, uint256 feeAmount, address indexed receiver);

    event TransferControl(address _newTeam, uint256 timestamp);

    event UpdateFlashLoanRate(uint256 newRate);

    event Approval(address indexed user, address indexed allowed, bool status);

    event OwnershipAccepted(address newOwner, uint256 timestamp);

    event RegisterProtocol(address sender);

    event AllowContract(address whitelist, bool status);

    event RescueFunds(IERC20 token, uint256 amount);

    // ************** //
    // *** FUNCTIONS *** //
    // ************** //

    function initialize(uint256 _flashLoanRate, address _owner) external;

    function approveContract(
        address _user,
        address _contract,
        bool _status,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function deposit(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256, uint256);

    function withdraw(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256);

    function balanceOf(IERC20, address) external view returns (uint256);

    function transfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares,
        uint256 _amount
    ) external;

    function toShare(
        IERC20 token,
        uint256 amount,
        bool ceil
    ) external view returns (uint256);

    function toUnderlying(IERC20 token, uint256 share) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IERC3156FlashBorrower.sol";
import "./VaultBase.sol";

contract Vault is VaultBase {
    using SafeERC20 for IERC20;

    /// @notice modifier to allow only blacksmith team to call a function
    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    /// @notice modifier to check that an address is allowed to deposit, withdraw or transfer
    modifier allowed(address _from) {
        require(msg.sender == _from || userApprovedContracts[_from][msg.sender] == true || _from == address(this), "ONLY_ALLOWED");
        _;
    }

    /// @dev setup a vault
    constructor() VaultBase() {}

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // UUPSProxiable
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function initialize(uint256 _flashLoanRate, address _owner) external override initializer {
        require(_owner != address(0), "INVALID_OWNER");
        require(flashLoanRate < MAX_FLASHLOAN_RATE, "INVALID_RATE");

        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(_EIP712_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        flashLoanRate = _flashLoanRate;
        owner = _owner;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Vault Actions
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// @notice Enables or disables a contract for approval without signed message.
    function allowContract(address _contract, bool _status) external onlyOwner {
        // Checks that _contract address(_contract) is not a zero address
        require(_contract != address(0), "invalid_address");
        // Effects value of _status on the contract address(_contract)
        allowedContracts[_contract] = _status;
        emit AllowContract(_contract, _status);
    }

    /// @notice approve a contract to enable the contract to withdraw
    function approveContract(
        address _user,
        address _contract,
        bool _status,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // ensure that contract address(_contract) is not a zero address
        require(_contract != address(0), "INVALID_CONTRACT");
        // ensure that user address(_contract) is not a zero address
        require(_user != address(0), "INVALID_USER");
        if (v == 0 && r == bytes32(0) && s == bytes32(0)) {
            // ensure that user match
            require(_user == msg.sender, "NOT_SENDER");
            // ensure that it's a contract
            require(msg.sender != tx.origin, "ONLY_CONTRACT");
            // ensure that _user != _contract
            require(_user != _contract, "INVALID_APPROVE");
            // ensure that _contract is allowed
            require(allowedContracts[_contract], "NOT_WHITELISTED");
        } else {
            // Performs EIP712 hashing for address retrieval
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _domainSeparatorV4(),
                    keccak256(
                        abi.encode(
                            _VAULT_APPROVAL_SIGNATURE_TYPE_HASH,
                            _status // solhint-disable-next-line
                                ? keccak256(
                                    "Grant full access to funds in Wura Vault? Read more here https://docs.wuradao.com/developers/vault"
                                )
                                : keccak256("Revoke access to Wura Vault? Read more here https://docs.wuradao.com/developers/vault"),
                            _user,
                            _contract,
                            _status,
                            userApprovalNonce[_user]++
                        )
                    )
                )
            );
            // Recovers the address from the hash
            address recoveredAddress = ecrecover(digest, v, r, s);
            // Compare recovered address with _user address
            require(recoveredAddress == _user, "INVALID_SIGNATURE");
        }
        // Change status of _contract address
        userApprovedContracts[_user][_contract] = _status;
        emit Approval(_user, _contract, _status);
    }

    /// @notice pause vault actions
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpause vault actions
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Deposit an amount of `token`
    /// @param _token The ERC-20 token to deposit.
    /// @param _from which account to pull the tokens.
    /// @param _to which account to push the tokens.
    /// @param _amount Token amount in native representation to deposit.
    /// @return amountOut The deposit amount in vault shares
    /// @return shareOut The deposit amount in vault shares
    function deposit(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external override whenNotPaused allowed(_from) returns (uint256 amountOut, uint256 shareOut) {
        // ensure that receiver address(_to) is not a zero address
        require(_to != address(0), "INVALID_TO_ADDRESS");
        // calculate shares
        shareOut = toShare(_token, _amount, false);
        amountOut = _amount;
        // Checks if _from address is equal to this contract address
        if (address(_from) == address(this)) {
            // Check that there is an untracked amount of the ERC20 token(_token) to be deposited that's equal or more than the amount to be deposited
            require(_token.balanceOf(address(this)) - totals[_token].totalUnderlyingDeposit >= _amount, "INVALID_DEPOSIT");
        } else {
            // transfer appropriate amount of underlying from _from to vault
            _token.safeTransferFrom(_from, address(this), _amount);
        }
        // Updates the share of the reciever address(_to)
        balanceOf[_token][_to] = balanceOf[_token][_to] + shareOut;
        TotalBase storage total = totals[_token];
        // Adds the amount deposited to the total deposit in this vault
        total.totalUnderlyingDeposit += _amount;
        // Adds the share to the total share minted in the vault
        total.totalSharesMinted += shareOut;
        emit Deposit(_token, _from, _to, _amount, shareOut);
    }

    /// @notice Withdraw the underlying share of `token` from a user account.
    /// @param _token The ERC-20 token to withdraw.
    /// @param _from which user to pull the tokens.
    /// @param _to which user to push the tokens.
    /// @param _shares of shares to withdraw
    /// @return amountOut The amount of underlying transferred
    function withdraw(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares
    ) external override whenNotPaused allowed(_from) returns (uint256 amountOut) {
        // ensure that reciever address(_to) is not a zero address
        require(_to != address(0), "INVALID_TO_ADDRESS");
        // Converts the shares to token
        amountOut = toUnderlying(_token, _shares);
        // Deducts shares from withdrawer address(_from)
        balanceOf[_token][_from] = balanceOf[_token][_from] - _shares;
        TotalBase storage total = totals[_token];
        // Deducts the amount withdrawn from the total deposit in the vault
        total.totalUnderlyingDeposit -= amountOut;
        // Deducts the share from the total shares minted in the vault
        total.totalSharesMinted -= _shares;
        // prevents the ratio from being reset
        require(total.totalSharesMinted >= MINIMUM_SHARE_BALANCE || total.totalSharesMinted == 0, "INVALID_RATIO");
        // Transfers token to receiver address(_to)
        _token.safeTransfer(_to, amountOut);
        emit Withdraw(_token, _from, _to, _shares, amountOut);
    }

    /// @notice Transfer share of `token` to another account
    /// @param _token The ERC-20 token to transfer.
    /// @param _from which user to pull the tokens.
    /// @param _to which user to push the tokens.
    /// @param _shares of shares to transfer
    /// @param _amount of token to transfer
    function transfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares,
        uint256 _amount
    ) external override whenNotPaused allowed(_from) {
        uint256 sharesToTransfer = _shares;
        // Uses the amount to get the share if above 0
        if (_amount > 0) {
            // Calculates shares from amount
            sharesToTransfer = toShare(_token, _amount, false);
        }
        _transfer(_token, _from, _to, sharesToTransfer);
    }

    /// @notice Transfer control from current owner address to another
    /// @param _newOwner The new team
    function transferToNewOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "INVALID_NEW_OWNER");
        newOwner = _newOwner;
        emit TransferControl(_newOwner, block.timestamp);
    }

    /// @notice accept transfer of control
    function acceptOwnership() external {
        require(msg.sender == newOwner, "invalid owner");
        owner = newOwner;
        newOwner = address(0);
        emit OwnershipAccepted(newOwner, block.timestamp);
    }

    function _transfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares
    ) internal {
        require(_to != address(0), "INVALID_TO_ADDRESS");
        // Effects
        balanceOf[_token][_from] = balanceOf[_token][_from] - _shares;
        balanceOf[_token][_to] = balanceOf[_token][_to] + _shares;
        emit Transfer(_token, _from, _to, _shares);
    }

    /// @notice The amount of currency available to be lent.
    /// @param _token The loan currency.
    /// @return The amount of `token` that can be borrowed.
    function maxFlashLoan(address _token) external view override returns (uint256) {
        return totals[IERC20(_token)].totalUnderlyingDeposit;
    }

    /// @notice The fee to be charged for a given loan.
    /// @param // _token The loan currency.
    /// @param _amount The amount of tokens lent.
    /// @return The amount of `token` to be charged for the loan, on top of the returned principal.
    function flashFee(address, uint256 _amount) public view override returns (uint256) {
        return (_amount * flashLoanRate) / 1e18;
    }

    /// @notice Initiate a flash loan.
    /// @param _receiver The receiver of the tokens in the loan, and the receiver of the callback.
    /// @param _token The loan currency.
    /// @param _amount The amount of tokens lent.
    /// @param _data Arbitrary data structure, intended to contain user-defined parameters.
    function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external override nonReentrant returns (bool) {
        require(totals[IERC20(_token)].totalUnderlyingDeposit >= _amount, "Not enough balance");
        IERC20 token = IERC20(_token);
        uint256 tokenBalBefore = token.balanceOf(address(this));
        token.safeTransfer(address(_receiver), _amount);
        uint256 fee = flashFee(_token, _amount);
        require(_receiver.onFlashLoan(msg.sender, _token, _amount, fee, _data) == FLASHLOAN_CALLBACK_SUCCESS, "IERC3156: Callback failed");
        // receive loans and fees
        token.safeTransferFrom(address(_receiver), address(this), _amount + fee);
        uint256 receivedFees = token.balanceOf(address(this)) - tokenBalBefore;
        require(receivedFees >= fee, "not enough fees");
        totals[IERC20(_token)].totalUnderlyingDeposit += fee;
        emit FlashLoan(msg.sender, token, _amount, fee, address(_receiver));
        return true;
    }

    /// @dev Update the flashloan rate charged, only owner can call
    /// @param _newRate The ERC-20 token.
    function updateFlashloanRate(uint256 _newRate) external onlyOwner {
        require(_newRate < MAX_FLASHLOAN_RATE, "invalid rate");
        flashLoanRate = _newRate;
        emit UpdateFlashLoanRate(_newRate);
    }

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param _token The ERC-20 token.
    /// @param _amount The `token` amount.
    /// @param _ceil If to ceil the amount or not
    /// @return share The token amount represented in shares.
    function toShare(
        IERC20 _token,
        uint256 _amount,
        bool _ceil
    ) public view override returns (uint256 share) {
        TotalBase storage total = totals[_token];
        uint256 currentTotal = total.totalSharesMinted;
        if (currentTotal > 0) {
            uint256 currentUnderlyingBalance = total.totalUnderlyingDeposit;
            share = (_amount * currentTotal) / currentUnderlyingBalance;
            if (_ceil && ((share * currentUnderlyingBalance) / currentTotal) < _amount) {
                share = share + 1;
            }
        } else {
            share = _amount;
        }
    }

    /// @notice Helper function represent shares back into the `token` amount.
    /// @param _token The ERC-20 token.
    /// @param _share The amount of shares.
    /// @return amount The share amount back into native representation.
    function toUnderlying(IERC20 _token, uint256 _share) public view override returns (uint256 amount) {
        TotalBase storage total = totals[_token];
        amount = (_share * total.totalUnderlyingDeposit) / total.totalSharesMinted;
    }

    /// @notice rescueFunds Enables us to rescue funds that are not tracked
    /// @param _token ERC20 token to rescue funds from
    function rescueFunds(IERC20 _token) external nonReentrant onlyOwner {
        uint256 currentBalance = _token.balanceOf(address(this));
        uint256 amount = currentBalance - totals[_token].totalUnderlyingDeposit;
        _token.safeTransfer(owner, amount);
        emit RescueFunds(_token, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// import {UUPSProxiable} from "../upgradability/UUPSProxiable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/IXVault.sol";

// ReentrancyGuard,
// UUPSProxiable,
/// @title Vault Storage Version 1
/// @notice Declares some variables for the Vault Contract
/// @dev Declares some state variables for the Vault Contract
abstract contract VaultStorageV1 is Pausable, Initializable, ReentrancyGuard, IXVault {
    struct TotalBase {
        uint256 totalUnderlyingDeposit; // total underlying asset deposit
        uint256 totalSharesMinted; // total vault shares minted
    }

    /// @notice the flashloan rate to charge for flash loans
    uint256 public flashLoanRate;

    /// @notice the address that has access to perform `admin` functions
    address public owner;

    /// @dev the new address that would have access to perform `admin` functions after transfer and acceptance
    address public newOwner;

    /// @dev cached domain separator
    bytes32 internal _CACHED_DOMAIN_SEPARATOR;

    /// @notice mapping of token asset to user address and balance(share)
    mapping(IERC20 => mapping(address => uint256)) public override balanceOf;

    /// @notice mapping of user to contract to approval status
    mapping(address => mapping(address => bool)) public userApprovedContracts;

    /// @notice mapping of user to approval nonce
    mapping(address => uint256) public userApprovalNonce;

    /// @notice mapping to contract to whitelist status
    mapping(address => bool) public allowedContracts;

    /// @notice mapping of asset to total deposit and shares minted
    mapping(IERC20 => TotalBase) public totals;
}

abstract contract VaultBase is VaultStorageV1 {
    /// @notice vault name
    string public constant name = "WarpVault v1";

    /// @notice vault version
    string public constant version = "1";

    /// @dev vault approval message digest
    bytes32 internal constant _VAULT_APPROVAL_SIGNATURE_TYPE_HASH =
        keccak256("VaultAccessApproval(bytes32 warning,address user,address contract,bool approved,uint256 nonce)");

    /// @dev EIP712 type hash
    bytes32 internal constant _EIP712_TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /// @dev ERC3156 constant for flashloan callback success
    bytes32 internal constant FLASHLOAN_CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /// @notice max flashlaon rate 10%
    uint256 public constant MAX_FLASHLOAN_RATE = 1e17;

    /// @dev minimum vault share balance
    uint256 internal constant MINIMUM_SHARE_BALANCE = 1000; // To prevent the ratio going off

    bytes32 internal immutable _HASHED_NAME;
    bytes32 internal immutable _HASHED_VERSION;
    uint256 private immutable _CACHED_CHAIN_ID;

    constructor() {
        _HASHED_NAME = keccak256(bytes(name));
        _HASHED_VERSION = keccak256(bytes(version));
        _CACHED_CHAIN_ID = _getChainId();
    }

    function _buildDomainSeparator(
        bytes32 _typeHash,
        bytes32 _name,
        bytes32 _version
    ) internal view returns (bytes32) {
        return keccak256(abi.encode(_typeHash, _name, _version, _getChainId(), address(this)));
    }

    function _domainSeparatorV4() internal view returns (bytes32) {
        if (_getChainId() == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_EIP712_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _getChainId() private view returns (uint256 chainId) {
        // solhint-disable-next-line
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}