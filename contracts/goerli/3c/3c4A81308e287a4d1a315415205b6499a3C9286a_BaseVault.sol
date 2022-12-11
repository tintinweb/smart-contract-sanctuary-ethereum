// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice libraries

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice interfaces
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title BaseVault
 * @author Ghadi Mhawej
 **/

contract BaseVault is Initializable, ReentrancyGuard {
    /// @dev `Payment` is a public structure that describes the details of each payment
    struct Payment {
        string name; // What is the purpose of this payment
        bytes32 ref; // Reference of the payment.
        address spender; // Who is sending the funds
        uint256 earliestPayTime; // The earliest a payment can be made (Unix Time)
        bool canceled; // If True then the payment has been canceled
        bool paid; // If True then the payment has been paid
        address payable recipient; // Who is receiving the funds
        uint256 amount; // The amount of wei sent in the payment
        uint256 securityGuardDelay; // The seconds `securityGuard` can delay payment
    }

    Payment[] public authorizedPayments;

    address public securityGuard;
    uint256 public absoluteMinTimeLock;
    uint256 public timeLock;
    uint256 public maxSecurityGuardDelay;
    address public escapeHatchCaller;
    address payable public escapeHatchDestination;

    /// @notice Contract name and symbol
    string public name;
    string public symbol;

    /// @notice address owner
    address public owner;

    /// @notice defining whether contract is Base or not
    bool public isBase;

    /// @dev The whitelisted addresses allowed to set up && receive payments from this BaseVault
    mapping(address => bool) public allowedSpenders;

    // @dev Events Definition
    event PaymentAuthorized(
        uint256 indexed idPayment,
        address indexed recipient,
        uint256 amount
    );
    event PaymentExecuted(
        uint256 indexed idPayment,
        address indexed recipient,
        uint256 amount
    );

    /// @notice EscapeHatch event definition
    event EscapeHatchCalled(uint256 amount);

    event PaymentCanceled(uint256 indexed idPayment);
    event EtherReceived(address indexed from, uint256 amount);
    event SpenderAuthorization(address indexed spender, bool authorized);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // @dev The address assigned the role of `securityGuard` is the only addresses that can call a function with this modifier
    modifier onlySecurityGuard() {
        require(
            msg.sender == securityGuard,
            "BaseVault: the caller is not the securityGuard"
        );
        _;
    }

    // @dev resticts access to only allowed spenders
    modifier onlyAllowedSpender() {
        require(
            allowedSpenders[msg.sender],
            "BaseVault: the caller is not an allowed spender"
        );
        _;
    }

    /// @dev The addresses preassigned to the `escapeHatchCaller` role or the owner are the only addresses that can call a function with this modifier
    modifier onlyEscapeHatchCallerOrOwner() {
        require(
            msg.sender == owner || msg.sender == escapeHatchCaller,
            "BaseVault: caller is not the owner or escapeHatchCaller"
        );
        _;
    }

    /// @notice only owner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "BaseVault: only owner");
        _;
    }

    /// @notice constructor

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        isBase = true;
    }

    /**
     * @notice initializing the cloned contract
     * @param data data for VaultProxy clone encoded
     * @param owner_ address of VaultProxy owner
     **/
    function initialize(bytes memory data, address owner_)
        external
        initializer
    {
        require(
            isBase == false,
            "BaseVault: this is the base contract,cannot initialize"
        );

        require(owner == address(0), "BaseVault: contract already initialized");

        require(owner_ != address(0), "BaseVault: Owner address cannot be 0");

        (
            string memory name_,
            string memory symbol_,
            address _escapeHatchCaller,
            address payable _escapeHatchDestination,
            uint256 _absoluteMinTimeLock,
            uint256 _timeLock,
            address _securityGuard,
            uint256 _maxSecurityGuardDelay
        ) = abi.decode(
                data,
                (
                    string,
                    string,
                    address,
                    address,
                    uint256,
                    uint256,
                    address,
                    uint256
                )
            );

        name = name_;
        symbol = symbol_;

        owner = owner_;

        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = payable(_escapeHatchDestination);
        absoluteMinTimeLock = _absoluteMinTimeLock;
        timeLock = _timeLock;
        securityGuard = _securityGuard;
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }

    /// @notice Changes the address assigned to call `escapeHatch()`
    /// @param _newEscapeHatchCaller New address to be assigned to escapeHatchCaller
    function changeEscapeCaller(address _newEscapeHatchCaller)
        external
        onlyEscapeHatchCallerOrOwner
    {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    /// @notice Sends all of the eth contained in the contract to the escapeHatchDestination
    /// @notice should only be called as last resort
    function escapeHatch() external onlyEscapeHatchCallerOrOwner nonReentrant {
        uint256 total = address(this).balance;

        escapeHatchDestination.transfer(total);
        emit EscapeHatchCalled(total);
    }

    /// @notice Returns the total number of authorized payments in this contract
    function numberOfAuthorizedPayments() public view returns (uint256) {
        return authorizedPayments.length;
    }

    /// @notice The fall back function is called whenever ether is sent to this
    ///  contract
    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /// @notice `allowedSpenders` create a new `Payment`
    /// @param _name Brief description of the payment that is authorized
    /// @param _reference External reference of the payment
    /// @param _recipient Destination of the payment
    /// @param _amount Amount to be paid in wei
    /// @param _paymentDelay Number of seconds the payment is to be delayed; if this value is below `timeLock` then the `timeLock` determines the delay
    /// @return The Payment ID number for the new authorized payment
    function authorizePayment(
        string memory _name,
        bytes32 _reference,
        address payable _recipient,
        uint256 _amount,
        uint256 _paymentDelay
    ) public onlyAllowedSpender returns (uint256) {
        require(
            _paymentDelay < 10**18,
            "BaseVault: paymentDelay overflow risk"
        );

        uint256 idPayment = authorizedPayments.length;

        Payment memory p = authorizedPayments[idPayment];
        p.spender = msg.sender;

        // Determines the earliest the recipient can receive payment (Unix time)
        p.earliestPayTime = _paymentDelay >= timeLock
            ? block.timestamp + _paymentDelay
            : block.timestamp + timeLock;

        p.recipient = _recipient;
        p.amount = _amount;
        p.name = _name;
        p.ref = _reference;

        authorizedPayments.push(p);

        emit PaymentAuthorized(idPayment, p.recipient, p.amount);
        return idPayment;
    }

    /// @notice  Called by recipient of a payment to receive the ether after the earliestPayTime` has passed
    /// @param _idPayment The payment ID to be executed
    function collectAuthorizedPayment(uint256 _idPayment) public nonReentrant {
        require(
            _idPayment <= authorizedPayments.length,
            "BaseVault: Payment doesn't exist"
        );

        Payment memory p = authorizedPayments[_idPayment];

        require(
            msg.sender == p.recipient,
            "BaseVault: caller is not the recipient"
        );
        require(
            allowedSpenders[p.spender],
            "BaseVault: Spender is not authorized"
        );
        require(
            block.timestamp > p.earliestPayTime,
            "BaseVault: Not allowed to spend yet"
        );
        require(!(p.canceled), "BaseVault: Payment was cancelled");
        require(!(p.paid), "BaseVault: Payment already paid");
        require(
            address(this).balance > p.amount,
            "BaseVault: Not enough balance"
        );

        authorizedPayments[_idPayment].paid = true;

        p.recipient.transfer(p.amount);

        emit PaymentExecuted(_idPayment, p.recipient, p.amount);
    }

    /// @notice Called by Security Guard to delay a payment for a set number of seconds
    /// @param _idPayment ID of the payment to be delayed
    /// @param _delay The number of seconds to delay the payment
    function delayPayment(uint256 _idPayment, uint256 _delay)
        public
        onlySecurityGuard
    {
        require(
            _idPayment <= authorizedPayments.length,
            "BaseVault: Payment doesn't exist"
        );

        require(_delay < 10**18, "BaseVault: paymentDelay overflow risk");

        require(
            !(authorizedPayments[_idPayment].canceled),
            "BaseVault: Payment was cancelled"
        );
        require(
            !(authorizedPayments[_idPayment].paid),
            "BaseVault: Payment already paid"
        );
        require(
            authorizedPayments[_idPayment].securityGuardDelay + _delay <
                maxSecurityGuardDelay,
            "BaseVault: delay time too big"
        );

        authorizedPayments[_idPayment].securityGuardDelay += _delay;
        authorizedPayments[_idPayment].earliestPayTime += _delay;
    }

    /// @notice Called by owner to cancel a payment
    /// @param _idPayment ID of the payment to be canceled.
    function cancelPayment(uint256 _idPayment) public onlyOwner {
        require(
            _idPayment <= authorizedPayments.length,
            "BaseVault: Payment doesn't exist"
        );

        require(
            !(authorizedPayments[_idPayment].canceled),
            "BaseVault: Payment was cancelled"
        );
        require(
            !(authorizedPayments[_idPayment].paid),
            "BaseVault: Payment already paid"
        );
        authorizedPayments[_idPayment].canceled = true;
        emit PaymentCanceled(_idPayment);
    }

    /// @notice Called by owner to add an address to the allowedSpenders whitelist
    /// @param _spender The address of the contract being authorized
    function authorizeSpender(address _spender) public onlyOwner {
        allowedSpenders[_spender] = true;
        emit SpenderAuthorization(_spender, true);
    }

    /// @notice Called by owner to remove an address to the allowedSpenders whitelist
    /// @param _spender The address of the contract being removed
    function removeSpender(address _spender) public onlyOwner {
        allowedSpenders[_spender] = false;
        emit SpenderAuthorization(_spender, false);
    }

    /// @notice Called by owner to set new address of security guard
    /// @param _newSecurityGuard Address of the new security guard
    function setSecurityGuard(address _newSecurityGuard) public onlyOwner {
        securityGuard = _newSecurityGuard;
    }

    /// @notice owner can change timeLock; the new `timeLock` cannot be  lower than `absoluteMinTimeLock`
    /// @param _newTimeLock Sets the new minimum default `timeLock` in seconds; pending payments maintain their `earliestPayTime`
    function setTimelock(uint256 _newTimeLock) public onlyOwner {
        require(
            _newTimeLock > absoluteMinTimeLock,
            "BaseVault: _newTimeLock should be higher than absoluteMinTimeLock"
        );
        timeLock = _newTimeLock;
    }

    /// @notice owner can change the maximum number of seconds`securityGuard` can delay a payment
    /// @param _maxSecurityGuardDelay The new maximum delay in seconds
    function setMaxSecurityGuardDelay(uint256 _maxSecurityGuardDelay)
        public
        onlyOwner
    {
        maxSecurityGuardDelay = _maxSecurityGuardDelay;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
}