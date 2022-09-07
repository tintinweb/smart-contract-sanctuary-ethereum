// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title The Escrow Implementation Contract
 * @author [email protected]
 * @notice Contract that has all the Escrow logic, which shall be used by the Escrow Factory
 */
contract Escrow is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    constructor() {
        //
    }

    bool public isFreezed;
    bool public blockNewParticipants;
    address public judge;

    address[] public participants;
    mapping(address => bool) public participantExists;

    mapping(address => uint256) public getEscrowRemainingInput; // amount of money an address has deposited in the contract
    mapping(address => uint256) public getWithdrawableBalance; // amount of money an address can withdraw from the contract
    mapping(address => uint256) public getRefundableBalance; // amount of money an address can refund to a particular participant in the contract

    /// @notice Constructor function for the Escrow Contract Instances
    function initialize(
        address[] memory _participants,
        address _judge,
        bool _blockNewParticipants
    ) public payable initializer {
        require(
            _participants.length >= 2,
            "At least two participants required"
        );

        // no signatory should be a judge & make them participants
        for (uint256 i = 0; i < _participants.length; i++) {
            address _participant = _participants[i];
            require(
                _participants[i] != _judge,
                "Judge cannot be a participant"
            );
            _addParticipant(_participant);
        }

        judge = _judge;
        isFreezed = false;
        blockNewParticipants = _blockNewParticipants;

        transferOwnership(judge);
    }

    /// @notice Get Wallet Balance of the Escrow Contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Events
    event ReceivedFunds(
        address indexed depositor,
        address indexed recipient,
        uint256 fundsInwei,
        uint32 timestamp
    );
    event EscrowFreezed(uint32 timestamp);
    event EscrowUnfreezed(uint32 timestamp);
    event NewParticipantsBlocked(uint32 timestamp);
    event NewParticipantsUnblocked(uint32 timestamp);
    event NewParticipant(address indexed participant, uint32 timestamp);
    event ApprovedFunds(
        address indexed from,
        address indexed by,
        address indexed to,
        uint256 amount,
        uint32 timestamp
    );
    event Refunded(
        address indexed from,
        address indexed by,
        address indexed to,
        uint256 amount,
        uint32 timestamp
    );
    event Withdrew(address indexed by, uint256 amount, uint32 timestamp);

    // Fallbacks
    fallback() external payable virtual {
        depositFunds(address(0));
    }

    receive() external payable virtual {
        depositFunds(address(0));
    }

    // Modifiers
    modifier freezeCheck() {
        require(isFreezed == false, "Escrow freezed");
        _;
    }
    modifier participantCheck() {
        require(blockNewParticipants == false, "New participants blocked");
        _;
    }
    modifier judgeCheck() {
        require(msg.sender == judge, "you arent a judge");
        _;
    }

    // Private Functions
    function _addParticipant(address _participant) internal {
        if (participantExists[_participant] != true && _participant != judge) {
            participants.push(_participant);
            participantExists[_participant] = true;
            emit NewParticipant(_participant, uint32(block.timestamp));
        }
    }

    /// @notice Deposit Funds into the Escrow Contract
    function depositFunds(address _to)
        public
        payable
        freezeCheck
        participantCheck
        nonReentrant
    {
        // sender becomes a participant and their input gets recorded
        _addParticipant(msg.sender);
        getEscrowRemainingInput[msg.sender] =
            getEscrowRemainingInput[msg.sender] +
            msg.value;

        // get beneficiary
        address beneficiary = _to != address(0)
            ? _to
            : (
                participants[0] == msg.sender
                    ? participants[1]
                    : participants[0]
            );

        // if there are only 2 participants, then the other participant is the intended beneficiary unless specified
        if (participants.length == 2) {
            getRefundableBalance[beneficiary] =
                getRefundableBalance[beneficiary] +
                msg.value;
        } else {
            // if there are more than 2 participants, then the beneficiary must be specified
            require(_to != address(0), "Beneficiary not specified");

            // if the beneficiary is not a participant, then add them as a participant
            _addParticipant(_to);
        }

        emit ReceivedFunds(
            msg.sender,
            beneficiary,
            msg.value,
            uint32(block.timestamp)
        );
    }

    /// @notice For the buyer to approve the funds they sent into the contract, for the other party to withdraw.
    function approve(
        address _from,
        address _to,
        uint256 _amount,
        bool attemptPayment
    )
        external
        nonReentrant
        freezeCheck
        returns (
            address amountFrom,
            address amountBeneficiary,
            uint256 amountApproved,
            bool isPaymentAttempted
        )
    {
        require(
            msg.sender == _from || msg.sender == judge,
            "unauthorized approve"
        );
        require(
            _amount <= getEscrowRemainingInput[_from],
            "Insufficient Balance"
        );

        // delete from remaining input
        getEscrowRemainingInput[_from] =
            getEscrowRemainingInput[_from] -
            _amount;

        _addParticipant(_from);
        _addParticipant(_to);

        if (attemptPayment) {
            (bool success, ) = payable(_to).call{value: _amount}("");
            require(success, "Payment failed");
        } else {
            // add to beneficiary's withdrawable balance
            getWithdrawableBalance[_to] = getWithdrawableBalance[_to] + _amount;
        }

        emit ApprovedFunds(
            _from,
            msg.sender,
            _to,
            _amount,
            uint32(block.timestamp)
        );

        return (_from, _to, _amount, attemptPayment);
    }

    /// @notice Withdraw your balance from the Escrow Contract
    function withdraw(uint256 _amount)
        external
        nonReentrant
        freezeCheck
        returns (address by, uint256 amount)
    {
        require(
            _amount <= getWithdrawableBalance[msg.sender],
            "Insufficient Balance"
        );

        getWithdrawableBalance[msg.sender] =
            getWithdrawableBalance[msg.sender] -
            _amount;

        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdraw failed");

        emit Withdrew(msg.sender, _amount, uint32(block.timestamp));

        return (msg.sender, _amount);
    }

    /// @notice Seller can refund the money to the buyer if they choose to.
    function refund(
        address _from,
        address _to,
        uint256 _amount,
        bool attemptPayment
    )
        external
        nonReentrant
        freezeCheck
        returns (
            address amountBeneficiary,
            uint256 amountApproved,
            bool isPaymentAttempted
        )
    {
        require(
            msg.sender != _to && (msg.sender == _from || msg.sender == judge),
            "Unauthorized refund"
        );

        require(
            _amount <= getEscrowRemainingInput[_to],
            "Insufficient Balance"
        );

        // delete from remaining input
        getEscrowRemainingInput[_to] = getEscrowRemainingInput[_to] - _amount;

        // delete from refundable balance of msg,sender
        getRefundableBalance[_from] = getRefundableBalance[_from] - _amount;

        if (attemptPayment) {
            (bool success, ) = payable(_to).call{value: _amount}("");
            require(success, "Refund failed");
        } else {
            getWithdrawableBalance[_to] = getWithdrawableBalance[_to] + _amount;
        }

        emit Refunded(_from, msg.sender, _to, _amount, uint32(block.timestamp));

        return (_to, _amount, attemptPayment);
    }

    /// @notice This function can be called by the judge to freeze the contract deposits, withdrawals, approvals and refunds.
    function toggleFreeze()
        external
        nonReentrant
        judgeCheck
        returns (bool _isFreezed)
    {
        if (isFreezed) {
            isFreezed = false;
            emit EscrowUnfreezed(uint32(block.timestamp));
        } else {
            isFreezed = true;
            emit EscrowFreezed(uint32(block.timestamp));
        }

        return isFreezed;
    }

    /// @notice This function can be called by the judge to block new participants from joining the escrow.
    function toggleParticipantBlock()
        external
        nonReentrant
        judgeCheck
        returns (bool _blockNewParticipants)
    {
        if (blockNewParticipants) {
            blockNewParticipants = false;
            emit NewParticipantsUnblocked(uint32(block.timestamp));
        } else {
            blockNewParticipants = true;
            emit NewParticipantsBlocked(uint32(block.timestamp));
        }

        return blockNewParticipants;
    }

    // TODO: Allow change of judge if both payer & beneficiary agree
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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