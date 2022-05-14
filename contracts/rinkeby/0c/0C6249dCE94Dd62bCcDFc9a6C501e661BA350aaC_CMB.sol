// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CMB is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    /*
     *  @notice Payment struct is information of payment includes: address of business owner and client, encrypt sensitive data, amount and status of payment
     */
    struct Payment {
        uint256 paymentId;
        address bo;
        address client;
        bytes32 data;
        uint256 amount;
        Status status;
    }

    /**
     *  Status enum is status of a payment
     *
     *          Suit                                Value
     *           |                                    |
     *  After Business Owner requests payment       REQUESTING
     *  After Client escrows money                  PAID
     *  After Client confirms to release money      CONFIRMED
     *  After Business Owner claims payment         CLAIMED
     */
    enum Status { REQUESTING, PAID, CONFIRMED, CLAIMED }

    /**
     *  @notice Mapping payment ID to a payment detail
     */
    mapping(uint256 => Payment) public payments;

    /**
     *  @notice serviceFeeTotal unit256 is total of service fee
     */
    uint256 public serviceFeeTotal;

    /**
     *  @notice serviceFee uint256 is service fee of each payment
     */
    uint256 public serviceFeePercent;

    /**
     *  @notice lastPaymentId uint256 is the latest requested payment ID started by 1
     */
    uint256 public lastPaymentId;

    /**
     *  @notice WEIGHT_DECIMAL uint256 constant is the weight decimal to avoid float number when calculating service fee by percentage
     */
    uint256 private constant WEIGHT_DECIMAL = 1e6;

    event RequestedPayment(
        uint256 indexed paymentId, 
        address indexed bo, 
        address indexed client, 
        bytes32 data, 
        uint256 amount
    );
    event Paid(uint256 indexed paymentId);
    event ConfirmedToRelease(uint256 indexed paymentId);
    event Claimed(uint256 indexed paymentId);
    event WithdrawnServiceFee(uint256 amount, address indexed fundingReceiver);

    event SetClient(address oldClient, address newClient);
    event SetData(bytes32 oldData, bytes32 newData);
    event SetAmount(uint256 oldAmount, uint256 newAmount);
    event ServiceFeePercent(uint256 oldAmount, uint256 newAmount);

    modifier onlyValidAddress(address _address) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        require((size <= 0) && _address != address(0), "Invalid address");
        _;
    }

    modifier onlyBusinessOwner(uint256 paymentId) {
        require(_msgSender() == payments[paymentId].bo, "Only Business Owner can do it");
        _;
    }

    modifier onlyClient(uint256 paymentId) { 
        require(_msgSender() == payments[paymentId].client, "Only Client can do it");
        _;
    }

    modifier onlyValidPayment(uint256 paymentId) {
        require(paymentId > 0 && paymentId <= lastPaymentId, "This payment is invalid");
        _;
    }

    modifier onlyRequestingPayment(uint256 paymentId) {
        require(payments[paymentId].status == Status.REQUESTING, "This payment needs to be requested");
        _;
    }

    /**
     *  @notice Initialize new logic contract.
     */
    function initialize(address _owner) public initializer {
        OwnableUpgradeable.__Ownable_init();
        transferOwnership(_owner);
        serviceFeePercent = 15 * WEIGHT_DECIMAL / 10;
    }

    /** 
     *  @notice Get amount of payment by payment ID
     * 
     *  @dev    Anyone can call this function. 
     * 
     *          Name        Meaning 
     *  @param  paymentId   ID of payment that needs to get fee 
     *
     *          Type        Meaning
     *  @return uint256     Amount of payment by payment ID 
     */ 
    function getPaymentAmount(uint256 paymentId) external view returns (uint256) {
        return payments[paymentId].amount;
    }

    /** 
     *  @notice Set service fee
     * 
     *  @dev    Only owner can call this function. 
     * 
     *          Name                    Meaning 
     *  @param  newSeriveFeePercent     New service fee percent that want to be updated
     *  
     *  Emit event {ServiceFeePercent}
     */ 
    function setServiceFeePercent(uint256 newSeriveFeePercent) external onlyOwner {
        require(newSeriveFeePercent > 0, "Service fee percentage must be greather than 0");
        uint256 oldAmount = serviceFeePercent;
        serviceFeePercent = newSeriveFeePercent * WEIGHT_DECIMAL;
        emit ServiceFeePercent(oldAmount, newSeriveFeePercent);
    }

    /** 
     *  @notice Set Client of payment by payment ID
     * 
     *  @dev    Only Business Owner can call this function and payment needs to be initialized. 
     * 
     *          Name        Meaning 
     *  @param  paymentId   ID of payment that needs to be updated 
     *  
     *  Emit event {SetClient}
     */ 
    function setClient(uint256 paymentId, address newClient) 
        external 
        onlyValidPayment(paymentId) 
        onlyBusinessOwner(paymentId) 
        onlyRequestingPayment(paymentId) 
        onlyValidAddress(newClient) 
    {
        address oldClient = payments[paymentId].client;
        payments[paymentId].client = newClient;
        emit SetClient(oldClient, newClient);
    }

    /** 
     *  @notice Set encrypt data of payment by payment ID
     * 
     *  @dev    Only Business Owner can call this function and payment needs to be initialized. 
     * 
     *          Name        Meaning 
     *  @param  paymentId   ID of payment that needs to be updated 
     *
     *  Emit event {SetData}
     */ 
    function setData(uint256 paymentId, bytes32 newData) 
        external 
        onlyValidPayment(paymentId) 
        onlyBusinessOwner(paymentId) 
        onlyRequestingPayment(paymentId) 
    {
        bytes32 oldData = payments[paymentId].data;
        payments[paymentId].data = newData;
        emit SetData(oldData, newData);
    }

    /** 
     *  @notice Set amount of payment by payment ID
     * 
     *  @dev    Only Business Owner can call this function and payment needs to be initialized. 
     * 
     *          Name        Meaning 
     *  @param  paymentId   ID of payment that needs to be updated 
     *
     *  Emit event {SetAmount}
     */ 
    function setAmount(uint256 paymentId, uint256 newAmount) 
        external 
        onlyValidPayment(paymentId) 
        onlyBusinessOwner(paymentId) 
        onlyRequestingPayment(paymentId) 
    {
        require(newAmount > 0, "Amount must be greater than 0");
        uint256 oldAmount = payments[paymentId].amount;
        payments[paymentId].amount = newAmount;
        emit SetAmount(oldAmount, newAmount);
    }

    /** 
     *  @notice Create a payment
     * 
     *  @dev    Anyone can call this function. 
     * 
     *          Name        Meaning 
     *  @param  client      Address of client 
     *  @param  data        Encrypt sensitive data
     *  @param  amount      Payment fee
     *
     *  Emit event {RequestedPayment}
     */
    function requestPayment(address client, bytes32 data, uint256 amount) external onlyValidAddress(client) {
        require(
            _msgSender() != client, 
            "Business Owner and Client can not be same"
        );
        lastPaymentId++;
        payments[lastPaymentId] = Payment(lastPaymentId, _msgSender(), client, data, amount, Status.REQUESTING);
        emit RequestedPayment(lastPaymentId, _msgSender(), client, data, amount);
    }

    /** 
     *  @notice Client make payment by payment ID
     * 
     *  @dev    Only Client can call this function. 
     * 
     *          Name        Meaning 
     *  @param  paymentId   ID of payment that needs to be updated
     *
     *  Emit event {Paid}
     */
    function pay(uint256 paymentId) 
        external 
        payable 
        onlyValidPayment(paymentId) 
        onlyClient(paymentId) 
        nonReentrant 
    {
        require(
            msg.value == payments[paymentId].amount, 
            "Not enough fee according to payment"
        );

        payments[paymentId].status = Status.PAID;
        emit Paid(paymentId);
    }

    /** 
     *  @notice Client confirm to release money by payment ID
     * 
     *  @dev    Only Client can call this function. 
     * 
     *          Name        Meaning 
     *  @param  paymentId   ID of payment that needs to be updated
     *
     *  Emit event {ConfirmedToRelease}
     */
    function confirmToRelease(uint256 paymentId) 
        external 
        onlyValidPayment(paymentId) 
        onlyClient(paymentId) 
    {
        require(payments[paymentId].status == Status.PAID, "This payment needs to paid by client");
        
        payments[paymentId].status = Status.CONFIRMED;
        emit ConfirmedToRelease(paymentId);
    }

    /** 
     *  @notice Business Owner claim payment by payment ID
     * 
     *  @dev    Only Business Owner can call this function. 
     * 
     *          Name        Meaning 
     *  @param  paymentId   ID of payment that needs to be updated
     *
     *  Emit event {Claimed}
     */
    function claim(uint256 paymentId) 
        external 
        payable 
        onlyValidPayment(paymentId) 
        onlyBusinessOwner(paymentId) 
        nonReentrant 
    {
        require(payments[paymentId].status == Status.CONFIRMED, "This payment needs to confirmed by client");

        uint256 amount = payments[paymentId].amount;
        uint256 serviceFee = calculateServiceFee(amount);
        payments[paymentId].status = Status.CLAIMED;
        serviceFeeTotal += serviceFee;
        payable(_msgSender()).transfer(amount - serviceFee);
        emit Claimed(paymentId);
    }

    /** 
     *  @notice Withdraw `_amount` of service fee to `_fundingReceiver` address
     * 
     *  @dev    Only Owner can call this function. 
     * 
     *          Name                Meaning 
     *  @param  _amount             Amount of service fee that want to withdraw
     *  @param  _fundingReceiver    Address that want to transfer
     *
     *  Emit event {WithdrawnServiceFee}
     */
    function withdrawServiceFee(uint256 _amount, address _fundingReceiver) 
        external 
        payable 
        onlyOwner 
        onlyValidAddress(_fundingReceiver) 
        nonReentrant
    {
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= serviceFeeTotal, "Not enough to withdraw");

        serviceFeeTotal -= _amount;
        payable(_fundingReceiver).transfer(_amount);
        emit WithdrawnServiceFee(_amount, _fundingReceiver);
    }

    /** 
     *  @notice Calculate service fee by amount payment
     * 
     *  @dev    Service fee equal amount of payment mutiply serviceFeePercent. The actual service fee will be divided by WEIGHT_DECIMAL and 100
     * 
     *          Name                Meaning 
     *  @param  amount              Amount of service fee that want to withdraw
     */
    function calculateServiceFee(uint256 amount) public view returns(uint256) {
        uint256 serviceFee = (amount * serviceFeePercent) / (WEIGHT_DECIMAL * 100);

        return serviceFee;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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