// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./CreditLineBase.sol";
import "./library/ExponentMath.sol";

/// @title CreditLineAmortized
/// @author Bluejay Core Team
/// @notice Credit line for loans that have equal payments throughout the period.
/// Each repayment pays towards both interest and principal.
/// @dev Amortized loan is type 1
contract CreditLineAmortized is CreditLineBase {
    /// @notice Adjusts minimum payment in each period to equal payments
    function _afterDrawdown() internal override {
        // Adjust minimum payment according to loan principal
        uint256 periodApr = (interestApr * paymentPeriod) / 365 days;
        uint256 compoundedInterest = ExponentMath.rpow(
            WAD + periodApr,
            loanTenureInPeriods,
            WAD
        );
        uint256 numerator = principalBalance * periodApr * compoundedInterest;
        uint256 denominator = (compoundedInterest - WAD) * WAD;
        uint256 paymentPerPeriod = numerator / denominator;
        minPaymentPerPeriod = paymentPerPeriod;
    }

    /// @notice Returns loan term type 1 for amortized loans
    /// @return termType Type 1 for amortized loans
    function loanTermType() public pure override returns (uint256 termType) {
        termType = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/ICreditLineBase.sol";

/// @title CreditLineBase
/// @author Bluejay Core Team
/// @notice Base contract for credit line to perform bookeeping of the loan.
/// @dev The child contract should implement the logic to calculate `minPaymentPerPeriod` or
/// override `minPaymentAtTimestamp` for determination of late payments.
abstract contract CreditLineBase is
    ICreditLineBase,
    Initializable,
    OwnableUpgradeable
{
    uint256 constant WAD = 10**18;

    /// @notice Max amount that is allowed to be borrowed, in lending asset decimals
    uint256 public override maxLimit;

    /// @notice Annual interest rate of the loan, in WAD
    uint256 public override interestApr;

    /// @notice Annual interest rate when payment is late, in WAD
    /// Late interest is applied on the principal balance
    uint256 public override lateFeeApr;

    /// @notice Length of time between repayment, in seconds
    /// The first repayment will start at the first period after drawdown happens
    uint256 public override paymentPeriod;

    /// @notice Expected number of periods to repay the loan, in wei
    /// @dev All principal plus balance are due on the end of last period
    uint256 public override loanTenureInPeriods;

    /// @notice Time from a payment period where late interest is not charged, in seconds
    uint256 public override gracePeriod;

    /// @notice Amount of principal balance, in lending asset decimals
    uint256 public override principalBalance;

    /// @notice Amount of interest balance, in lending asset decimals
    /// @dev Does not account for additional interest that has been accrued since the last repayment
    uint256 public override interestBalance;

    /// @notice Cumulative sum of repayment towards principal, in lending asset decimals
    uint256 public override totalPrincipalRepaid;

    /// @notice Cumulative sum of repayment towards interest, in lending asset decimals
    uint256 public override totalInterestRepaid;

    /// @notice Additional repayments made on top of all principal and interest, in lending asset decimals
    /// @dev Additional repayments should be refunded to the borrower
    uint256 public override additionalRepayment;

    /// @notice Cumulative sum of late interest, in lending asset decimals
    /// @dev Value is used to adjust the payment schedule so that the expected repayment
    /// increases to ensure borrower can repay on schedule
    uint256 public override lateInterestAccrued;

    /// @notice Timestamp of the last time interest was accrued and updated, in unix epoch time
    /// @dev Value is always incremented as multiples of the `paymentPeriod`
    uint256 public override interestAccruedAsOf;

    /// @notice Timestamp of the last time full payment was made (ie not late), in unix epoch time
    uint256 public override lastFullPaymentTime;

    /// @notice Minimum amount of payment (principal and/or interest) expected each period, in lending asset decimals
    uint256 public override minPaymentPerPeriod;

    /// @notice Timestamp where interest calculation starts, in unix epoch time
    /// @dev This value is set during the drawdown of the loan
    uint256 public override loanStartTime;

    /// @notice State of the loan
    State public override loanState;

    /// @notice Check if the contract is in the correct loan state
    modifier onlyState(State state) {
        if (loanState != state) revert IncorrectState(state, loanState);
        _;
    }

    /// @notice Initialize the contract
    /// @dev Initializing does not immediately start the interest accrual
    /// @param _maxLimit Max amount that is allowed to be borrowed, in lending asset decimals
    /// @param _interestApr Annual interest rate of the loan, in WAD
    /// @param _paymentPeriod Length of time between repayment, in seconds
    /// @param _gracePeriod Time from a payment period where late interest is not charged, in seconds
    /// @param _lateFeeApr Annual interest rate when payment is late, in WAD
    /// @param _minPaymentPerPeriodFullyFunded Maximum amount of payment (principal and/or interest) expected each period, in lending asset decimals
    /// @param _loanTenureInPeriods Expected number of periods to repay the loan, in wei
    function initialize(
        uint256 _maxLimit,
        uint256 _interestApr,
        uint256 _paymentPeriod,
        uint256 _gracePeriod,
        uint256 _lateFeeApr,
        uint256 _minPaymentPerPeriodFullyFunded,
        uint256 _loanTenureInPeriods
    ) public virtual override initializer {
        __Ownable_init();
        maxLimit = _maxLimit;
        interestApr = _interestApr;
        paymentPeriod = _paymentPeriod;
        gracePeriod = _gracePeriod;
        lateFeeApr = _lateFeeApr;
        minPaymentPerPeriod = _minPaymentPerPeriodFullyFunded;
        loanTenureInPeriods = _loanTenureInPeriods;
        loanState = State.Funding;
        emit LoanStateUpdate(State.Funding);
    }

    // =============================== ADMIN FUNCTIONS =================================

    /// @notice Account for funds received from lenders
    /// @param amount Amount of funds received, in lending asset decimals
    function fund(uint256 amount)
        public
        override
        onlyState(State.Funding)
        onlyOwner
    {
        if (principalBalance + amount > maxLimit) revert MaxLimitExceeded();
        principalBalance += amount;
    }

    /// @notice Drawdown the loan and start interest accrual
    /// @return amount Amount of funds drawn down, in lending asset decimals
    function drawdown()
        public
        override
        onlyState(State.Funding)
        onlyOwner
        returns (uint256 amount)
    {
        loanStartTime = block.timestamp;
        interestAccruedAsOf = block.timestamp;
        lastFullPaymentTime = block.timestamp;
        amount = principalBalance;

        loanState = State.Repayment;
        emit LoanStateUpdate(State.Repayment);

        _afterDrawdown();
    }

    /// @notice Mark the loan as refund state
    /// @dev Child contract should implement the logic to refund the loan
    function refund() public override onlyState(State.Funding) onlyOwner {
        loanState = State.Refund;
        emit LoanStateUpdate(State.Refund);
    }

    /// @notice Make repayment towards the loan
    /// @param amount Amount of repayment, in lending asset decimals
    /// @return interestPayment payment toward interest, in lending asset decimals
    /// @return principalPayment payment toward principal, in lending asset decimals
    /// @return additionalBalancePayment excess repayment, in lending asset decimals
    function repay(uint256 amount)
        public
        override
        onlyOwner
        onlyState(State.Repayment)
        returns (
            uint256 interestPayment,
            uint256 principalPayment,
            uint256 additionalBalancePayment
        )
    {
        // Update accounting variables
        _assess();

        // Apply payment to principal, interest, and additional payments
        (
            interestPayment,
            principalPayment,
            additionalBalancePayment
        ) = allocatePayment(amount, interestBalance, principalBalance);
        principalBalance -= principalPayment;
        interestBalance -= interestPayment;
        totalPrincipalRepaid += principalPayment;
        totalInterestRepaid += interestPayment;
        additionalRepayment += additionalBalancePayment;

        // Update lastFullPaymentTime if payment hits payment schedule
        if (
            totalPrincipalRepaid + totalInterestRepaid >=
            minPaymentForSchedule()
        ) {
            lastFullPaymentTime = interestAccruedAsOf;
        }

        // Update state if loan is fully repaid
        if (principalBalance == 0) {
            loanState = State.Repaid;
            emit LoanStateUpdate(State.Repaid);
        }
        emit Repayment(
            block.timestamp,
            amount,
            interestPayment,
            principalPayment,
            additionalBalancePayment
        );
    }

    // =============================== INTERNAL FUNCTIONS =================================

    /// @notice Hook fired after drawdown
    /// @dev To implement logic for adjusting `minPaymentPerPeriod` after drawdown
    /// according to what is actually borrowed vs the max limit in the child contract
    function _afterDrawdown() internal virtual {}

    /// @notice Make adjustments interest and late interest since the last assessment
    function _assess() internal {
        (
            uint256 interestOwed,
            uint256 lateInterestOwed,
            uint256 fullPeriodsElapsed
        ) = interestAccruedSinceLastAssessed();

        // Make accounting adjustments
        interestBalance += interestOwed;
        interestBalance += lateInterestOwed;
        lateInterestAccrued += lateInterestOwed;
        interestAccruedAsOf += fullPeriodsElapsed * paymentPeriod;
    }

    // =============================== VIEW FUNCTIONS =================================

    /// @notice Split a payment into interest, principal, and additional balance
    /// @param amount Amount of payment, in lending asset decimals
    /// @param interestOutstanding Interest balance outstanding, in lending asset decimals
    /// @param principalOutstanding Principal balance outstanding, in lending asset decimals
    /// @return interestPayment payment toward interest, in lending asset decimals
    /// @return principalPayment payment toward principal, in lending asset decimals
    /// @return additionalBalancePayment excess repayment, in lending asset decimals
    function allocatePayment(
        uint256 amount,
        uint256 interestOutstanding,
        uint256 principalOutstanding
    )
        public
        pure
        override
        returns (
            uint256 interestPayment,
            uint256 principalPayment,
            uint256 additionalBalancePayment
        )
    {
        // Allocate to interest first
        interestPayment = amount >= interestOutstanding
            ? interestOutstanding
            : amount;
        amount -= interestPayment;

        // Allocate to principal next
        principalPayment = amount >= principalOutstanding
            ? principalOutstanding
            : amount;
        amount -= principalPayment;

        // Finally apply remaining as additional balance
        additionalBalancePayment = amount;
    }

    /// @notice Calculate the minimum amount of total repayment against the schedule
    /// @return amount Minimum amount, in lending asset decimals
    function minPaymentForSchedule() public view returns (uint256 amount) {
        return minPaymentAtTimestamp(block.timestamp);
    }

    /// @notice Calculate the payment due now to avoid further late payment charges
    /// @return amount Payment due, in lending asset decimals
    function paymentDue()
        public
        view
        virtual
        override
        returns (uint256 amount)
    {
        amount = minPaymentAtTimestamp(block.timestamp);

        uint256 periodsElapsed = (block.timestamp - loanStartTime) /
            paymentPeriod;
        (
            uint256 interestOwed,
            uint256 lateInterestOwed,

        ) = interestAccruedAtTimestamp(block.timestamp);
        amount += lateInterestOwed;
        if (periodsElapsed >= loanTenureInPeriods) {
            // Need to add interest in final payment, since `minPaymentAtTimestamp`
            // assumes the interest has been added
            amount += interestOwed;
        }
        uint256 repaid = totalPrincipalRepaid + totalInterestRepaid;
        if (amount > repaid) {
            amount -= repaid;
        } else {
            amount = 0;
        }
    }

    /// @notice Calculate the minimum amount of total repayment against the schedule
    /// @dev Ensure `interestOwed` and `lateInterestOwed` is already accounted for as a precondition
    /// @param timestamp Timestamp to calculate the minimum payment, in unix epoch time
    /// @return amount Minimum amount, in lending asset decimals
    function minPaymentAtTimestamp(uint256 timestamp)
        public
        view
        virtual
        override
        returns (uint256 amount)
    {
        if (timestamp <= loanStartTime) return 0;
        if (principalBalance == 0) return 0;
        uint256 periodsElapsed = (timestamp - loanStartTime) / paymentPeriod;
        if (periodsElapsed < loanTenureInPeriods) {
            amount = periodsElapsed * minPaymentPerPeriod + lateInterestAccrued;
        } else {
            amount =
                principalBalance +
                interestBalance +
                totalInterestRepaid +
                totalPrincipalRepaid;
        }
    }

    /// @notice Calculate the interest accrued since the last assessment
    /// @return interestOwed Regular interest accrued, in lending asset decimals
    /// @return lateInterestOwed Late interest accrued, in lending asset decimals
    /// @return fullPeriodsElapsed Number of full periods elapsed
    function interestAccruedSinceLastAssessed()
        public
        view
        override
        returns (
            uint256 interestOwed,
            uint256 lateInterestOwed,
            uint256 fullPeriodsElapsed
        )
    {
        return interestAccruedAtTimestamp(block.timestamp);
    }

    /// @notice Calculate the interest accrued at a given timestamp
    /// @return interestOwed Regular interest accrued, in lending asset decimals
    /// @return lateInterestOwed Late interest accrued, in lending asset decimals
    /// @return fullPeriodsElapsed Number of full periods elapsed
    function interestAccruedAtTimestamp(uint256 timestamp)
        public
        view
        override
        returns (
            uint256 interestOwed,
            uint256 lateInterestOwed,
            uint256 fullPeriodsElapsed
        )
    {
        if (principalBalance == 0) {
            return (interestOwed, lateInterestOwed, fullPeriodsElapsed);
        }
        // Calculate regular interest payments
        fullPeriodsElapsed = (timestamp - interestAccruedAsOf) / paymentPeriod;
        if (fullPeriodsElapsed == 0) {
            return (interestOwed, lateInterestOwed, fullPeriodsElapsed);
        }
        interestOwed += interestOnBalance(fullPeriodsElapsed * paymentPeriod);

        // Calculate late interest payments
        if (timestamp > lastFullPaymentTime + gracePeriod) {
            // Do not apply grace period, if last full payment was before period start
            uint256 latePeriodsElapsed = (
                lastFullPaymentTime < interestAccruedAsOf
                    ? (timestamp - interestAccruedAsOf)
                    : (timestamp - interestAccruedAsOf - gracePeriod)
            ) / paymentPeriod;
            lateInterestOwed += lateInterestOnBalance(
                latePeriodsElapsed * paymentPeriod
            );
        }
    }

    /// @notice Calculate the regular interest accrued on the principal balance
    /// @param period Period to calculate interest on, in seconds
    /// @return interestOwed Regular interest accrued, in lending asset decimals
    function interestOnBalance(uint256 period)
        public
        view
        override
        returns (uint256 interestOwed)
    {
        return (principalBalance * interestApr * period) / (365 days * WAD);
    }

    /// @notice Calculate the late interest accrued on the principal balance
    /// @param period Period to calculate interest on, in seconds
    /// @return interestOwed Late interest accrued, in lending asset decimals
    function lateInterestOnBalance(uint256 period)
        public
        view
        override
        returns (uint256 interestOwed)
    {
        return (principalBalance * lateFeeApr * period) / (365 days * WAD);
    }

    /// @notice Type of loan term
    /// @dev Override in child contract to return an unique value for different repayment schedules
    /// @return termType type of loan term
    function loanTermType()
        public
        pure
        virtual
        override
        returns (uint256 termType)
    {
        termType = 0;
    }

    /// @notice Get the sum of all repayments made
    /// @return amount Total repayment, in lending asset decimals
    function totalRepayments() public view override returns (uint256 amount) {
        amount = totalPrincipalRepaid + totalInterestRepaid;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ICreditLineBase {
    /// @notice State of the loan
    /// @param Funding loan is currently fundraising from lenders
    /// @param Refund funding failed, funds to be returned to lenders, terminal state
    /// @param Repayment loan has been drawndown and borrower is repaying the loan
    /// @param Repaid loan has been fully repaid by borrower, terminal state
    enum State {
        Funding,
        Refund,
        Repayment,
        Repaid
    }

    /// @notice When a function is executed under the wrong loan state
    /// @param expectedState State that the loan should be in for the function to execute
    /// @param currentState State that the loan is currently in
    error IncorrectState(State expectedState, State currentState);

    /// @notice Funding exceeds the max limit
    error MaxLimitExceeded();

    /// @notice Loan state of the credit line has been updated
    /// @param newState State of the loan after the update
    event LoanStateUpdate(State indexed newState);

    /// @notice Repayment has been made towards loan
    /// @param timestamp Timestamp of repayment
    /// @param amount Amount of repayment
    /// @param interestRepaid Payment towards interest
    /// @param principalRepaid Payment towards principal
    /// @param additionalRepayment Excess payments
    event Repayment(
        uint256 timestamp,
        uint256 amount,
        uint256 interestRepaid,
        uint256 principalRepaid,
        uint256 additionalRepayment
    );

    function maxLimit() external returns (uint256);

    function interestApr() external returns (uint256);

    function paymentPeriod() external returns (uint256);

    function gracePeriod() external returns (uint256);

    function lateFeeApr() external returns (uint256);

    function principalBalance() external returns (uint256);

    function interestBalance() external returns (uint256);

    function totalPrincipalRepaid() external returns (uint256);

    function totalInterestRepaid() external returns (uint256);

    function additionalRepayment() external returns (uint256);

    function lateInterestAccrued() external returns (uint256);

    function interestAccruedAsOf() external returns (uint256);

    function lastFullPaymentTime() external returns (uint256);

    function minPaymentPerPeriod() external returns (uint256);

    function loanStartTime() external returns (uint256);

    function loanTenureInPeriods() external returns (uint256);

    function loanState() external returns (State);

    function loanTermType() external pure returns (uint256);

    function initialize(
        uint256 _maxLimit,
        uint256 _interestApr,
        uint256 _paymentPeriod,
        uint256 _gracePeriod,
        uint256 _lateFeeApr,
        uint256 _maxPaymentPerPeriod,
        uint256 _loanTenureInPeriods
    ) external;

    function fund(uint256 amount) external;

    function drawdown() external returns (uint256 amount);

    function refund() external;

    function repay(uint256 amount)
        external
        returns (
            uint256 interestPayment,
            uint256 principalPayment,
            uint256 additionalBalancePayment
        );

    function allocatePayment(
        uint256 amount,
        uint256 interestOutstanding,
        uint256 principalOutstanding
    )
        external
        pure
        returns (
            uint256 interestPayment,
            uint256 principalPayment,
            uint256 additionalBalancePayment
        );

    function minPaymentForSchedule() external view returns (uint256 amount);

    function paymentDue() external view returns (uint256 amount);

    function minPaymentAtTimestamp(uint256 timestamp)
        external
        view
        returns (uint256 amount);

    function interestAccruedSinceLastAssessed()
        external
        view
        returns (
            uint256 interestOwed,
            uint256 lateInterestOwed,
            uint256 fullPeriodsElapsed
        );

    function interestAccruedAtTimestamp(uint256 timestamp)
        external
        view
        returns (
            uint256 interestOwed,
            uint256 lateInterestOwed,
            uint256 fullPeriodsElapsed
        );

    function interestOnBalance(uint256 timePeriod)
        external
        view
        returns (uint256 interestOwed);

    function lateInterestOnBalance(uint256 timePeriod)
        external
        view
        returns (uint256 interestOwed);

    function totalRepayments() external view returns (uint256 amount);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// https://github.com/makerdao/dss/blob/master/src/abaci.sol
pragma solidity ^0.8.4;

library ExponentMath {
  function rpow(
    uint256 x,
    uint256 n,
    uint256 b
  ) internal pure returns (uint256 z) {
    assembly {
      switch n
      case 0 {
        z := b
      }
      default {
        switch x
        case 0 {
          z := 0
        }
        default {
          switch mod(n, 2)
          case 0 {
            z := b
          }
          default {
            z := x
          }
          let half := div(b, 2) // for rounding.
          for {
            n := div(n, 2)
          } n {
            n := div(n, 2)
          } {
            let xx := mul(x, x)
            if shr(128, x) {
              revert(0, 0)
            }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) {
              revert(0, 0)
            }
            x := div(xxRound, b)
            if mod(n, 2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                revert(0, 0)
              }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) {
                revert(0, 0)
              }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
  }
}