/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

/** 
 * contracts\KRUExchangeForwarder.sol
*/
            

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 * contracts\KRUExchangeForwarder.sol
*/
            
// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

////import "../../utils/AddressUpgradeable.sol";

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




/** 
 * contracts\KRUExchangeForwarder.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
////import "../proxy/utils/Initializable.sol";

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




/** 
 * contracts\KRUExchangeForwarder.sol
*/
            

pragma solidity 0.8.11;

//uint256 constant DECIMALS = 10**18;
uint256 constant DECIMALS = 18;
uint256 constant DECIMALS18 = 1e18;

uint256 constant MAX_UINT256 = type(uint256).max;
uint256 constant PERCENTAGE_100 = 100 * DECIMALS18;
uint256 constant PERCENTAGE_1 = DECIMALS18;
uint256 constant MAX_FEE_PERCENTAGE = 99 * DECIMALS18;

uint256 constant YEAR_IN_SECONDS = 31556952;

string constant ERROR_ACCESS_DENIED = "0x1";
string constant ERROR_NO_CONTRACT = "0x2";
string constant ERROR_NOT_AVAILABLE = "0x3";
string constant ERROR_KYC_MISSING = "0x4";
string constant ERROR_INVALID_ADDRESS = "0x5";
string constant ERROR_INCORRECT_CALL_METHOD = "0x6";
string constant ERROR_AMOUNT_IS_ZERO = "0x7";
string constant ERROR_HAVENT_ALLOCATION = "0x8";
string constant ERROR_AMOUNT_IS_MORE_TS = "0x9";
string constant ERROR_ERC20_CALL_ERROR = "0xa";
string constant ERROR_DIFF_ARR_LENGTH = "0xb";
string constant ERROR_METHOD_DISABLE = "0xc";
string constant ERROR_SEND_VALUE = "0xd";
string constant ERROR_NOT_ENOUGH_NFT_IDS = "0xe";
string constant ERROR_INCORRECT_FEE = "0xf";
string constant ERROR_WRONG_IMPLEMENT_ADDRESS = "0x10";
string constant ERROR_INVALID_SIGNER = "0x11";
string constant ERROR_NOT_FOUND = "0x12";
string constant ERROR_IS_EXISTS = "0x13";
string constant ERROR_IS_NOT_EXISTS = "0x14";
string constant ERROR_TIME_OUT = "0x15";
string constant ERROR_NFT_NOT_EXISTS = "0x16";
string constant ERROR_MINTING_COMPLETED = "0x17";
string constant ERROR_TOKEN_NOT_SUPPORTED = "0x18";
string constant ERROR_NOT_ENOUGH_NFT_FOR_SALE = "0x19";
string constant ERROR_NOT_ENOUGH_PREVIOUS_NFT = "0x1a";
string constant ERROR_FAIL = "0x1b";
string constant ERROR_MORE_THEN_MAX = "0x1c";
string constant ERROR_VESTING_NOT_START = "0x1d";
string constant ERROR_VESTING_IS_STARTED = "0x1e";
string constant ERROR_IS_SET = "0x1f";
string constant ERROR_ALREADY_CALL_METHOD = "0x20";
string constant ERROR_INCORRECT_DATE = "0x21";
string constant ERROR_IS_NOT_SALE = "0x22";
string constant ERROR_UNPREDICTABLE_MEMBER_ACTION = "0x23";
string constant ERROR_ALREADY_PAID = "0x24";
string constant ERROR_COOLDOWN_IS_NOT_OVER = "0x25";
string constant ERROR_INSUFFICIENT_AMOUNT = "0x26";
string constant ERROR_RESERVES_IS_ZERO = "0x27";
string constant ERROR_TREE_EXISTS = "0x28";
string constant ERROR_TREE_DOESNT_EXIST = "0x29";
string constant ERROR_NOT_DIFFERENT_MEMBERS = "0x2a";
string constant ERROR_NOT_ENOUGH_BALANCE = "0x2b";
string constant ERROR_ALREADY_DISTRIBUTED = "0x2c";
string constant ERROR_INDEX_OUT = "0x2d";
string constant ERROR_NOT_START = "0x2e";
string constant ERROR_ALREADY_CLAIMED = "0x2f";
string constant ERROR_LENGTH_IS_ZERO = "0x30";
string constant ERROR_WRONG_AMOUNT = "0x31";
string constant ERROR_SIGNERS_CANNOT_BE_EMPTY = "0x41";
string constant ERROR_LOCKED_PERIOD = "0x42";
string constant ERROR_INVALID_NONCE = "0x43";
string constant ERROR_CHAIN_NOT_SUPPORTED = "0x44";
string constant ERROR_INCORRECT_DATA = "0x45";
string constant ERROR_TWO_AMOUNTS_ENTERED = "0x46";

bytes32 constant KYC_CONTAINER_TYPEHASH = keccak256("Container(address sender,uint256 deadline)");

uint256 constant ROLE_ADMIN = 1;
uint256 constant CAN_WITHDRAW_NATIVE = 10;

// Managemenet
uint256 constant MANAGEMENT_CAN_SET_KYC_WHITELISTED = 3;
uint256 constant MANAGEMENT_KYC_SIGNER = 4;
uint256 constant MANAGEMENT_WHITELISTED_KYC = 5;

// Payment Gateway
uint256 constant SHOPS_PAYMENT_PAY_SIGNER = 21;
uint256 constant SHOPS_POOL_CAN_WITHDRAW_FOR = 31;
uint256 constant SHOPS_MANAGER_BLACK_LIST_PERM = 41;
uint256 constant SHOPS_MAGANER_FREEZ_LIST_PERM = 42;
uint256 constant SHOPS_MANAGER_CAN_SET_SHOP_ACCESS = 43;
uint256 constant SHOPS_MANAGER_CAN_REGISTER_REMOVE_SHOP = 44;
uint256 constant SHOPS_MANAGER_CAN_SET_COMMISION = 45;

// Public Sale
uint256 constant CAN_MINT_TOKENS_TOKEN_PLAN = 100;
uint256 constant CAN_BURN_TOKENS_TOKEN_PLAN = 101;

uint256 constant CAN_UPDATE_REWARD_REFERRAL_TREE = 120;
uint256 constant CAN_CREATE_TREE_REFERRAL_TREE = 121;
uint256 constant CAN_UPDATE_CALCULATE_REWARDS_REFERRAL_TREE = 122;

uint256 constant CAN_STAKE_FOR_APR_STAKE = 123;

uint256 constant CAN_FORWARD_FORWARDER = 124;

uint256 constant CAN_DISTRIBUT_BONUS_KRU_DISTRIBUTOR = 140;
uint256 constant CAN_CHANGE_BONUS_KRU_BONUS_DISTRIBUTOR = 143;

uint256 constant CAN_CHANGE_PURCHASE_INFO = 141;
uint256 constant CAN_SET_PLANS_INFO = 142;

//KRUExchangeForwarder
uint256 constant EXCHANGE_FORWARDER_SIGNER = 151;
uint256 constant EXCHANGE_FORWARDER_CAN_SET_ADDRESSES = 152;

//KRUDiscountExcange
uint256 constant DISCOUNT_EXCHANGE_CAN_SET_VESTING_TYPE = 161;
uint256 constant DISCOUNT_EXCHANGE_CAN_SET_SIGNER = 162;
uint256 constant DISCOUNT_EXCHANGE_CAN_CLAIM_FOR = 163;
uint256 constant DISCOUNT_EXCHANGE_CAN_ISSUE_PURCHASE = 164;

//All contracts by all part

uint256 constant CONTRACT_MANAGEMENT = 0;

uint256 constant CONTRACT_KRU_SHOPS_PAYMENT_PROCCESOR = 2;
uint256 constant CONTRACT_KRU_SHOPS_POOL = 3;
uint256 constant CONTRACT_KRU_SHOPS_MANAGER = 4;

uint256 constant CONTRACT_APR_STAKE = 11;
uint256 constant CONTRACT_FUND_FORWARDER = 15;
uint256 constant CONTRACT_REFERRAL_TREE = 16;
uint256 constant CONTRACT_BONUS_DISTRIBUTOR = 20;

uint256 constant CONTRACT_UNISWAP_V2_PAIR = 23;
uint256 constant CONTRACT_UNISWAP_V2_ROUTER = 24;
uint256 constant CONTRACT_UNISWAP_V2_FACTORY = 25;

uint256 constant CONTRACT_WRAPPED_KRU = 26;

uint256 constant CONTRACT_KRU_SHOPS_TRESUARY = 100;




/** 
 * contracts\KRUExchangeForwarder.sol
*/
            

pragma solidity 0.8.11;

/// @title Management
/// @author Applicature
/// @notice This contract allows set permission or permissions for sender,
/// set owner of the pool, set kyc whitelist, register contract etc
/// @dev This contract allows set permission or permissions for sender,
/// set owner of the pool, set kyc whitelist, register contract etc
interface IManagement {
    /// @notice Generated when admin set limit set permissions for user
    /// @dev Generated when admin set limit set permissions for user
    /// @param subject address which recive limit set permissions
    /// @param permissions id of permissions which was limit set permissions
    /// @param value Bool state of permission (true - enable, false - disable for subject)
    event LimitSetPermission(address indexed subject, uint256 indexed permissions, bool value);

    /// @notice Generated when admin set new permissions for user
    /// @dev Generated when admin/or user with limit set permissions set new permissions for user
    /// @param subject address which recive permissions
    /// @param permissions id's of permissions which was set
    /// @param value Bool state of permission (true - enable, false - disable for subject)
    event PermissionsSet(address indexed subject, uint256[] indexed permissions, bool value);

    /// @notice Generated when admin set new permissions for user
    /// @dev Generated when admin/or user with limit set permissions set new permissions for user
    /// @param subject array with addresses which permissions was update
    /// @param permissions id of permission which was set
    /// @param value Bool state of permission (true - enable, false - disable for subject)
    event UsersPermissionsSet(address[] indexed subject, uint256 indexed permissions, bool value);

    /// @notice Generated when admin set new permissions for user
    /// @dev Generated when admin/or user with limit set permissions set new permissions for user
    /// @param subject address which recive permissions
    /// @param permission id of permission which was set
    /// @param value Bool state of permission (true - enable, false - disable for subject)
    event PermissionSet(address indexed subject, uint256 indexed permission, bool value);

    /// @notice Generated when admin register new contract
    /// @dev Generated when admin register new contract by key
    /// @param key id on which the contract is registered
    /// @param target address contract which was registered
    event ContractRegistered(uint256 indexed key, address target);

    /// @notice Sets the permission for sender
    /// @dev  Sets the permission for sender by owner or address with limit set permissions
    /// @param address_ the address of sender
    /// @param permission_ the permission for sender
    /// @param value_ true or false for sender's permission
    function setPermission(
        address address_,
        uint256 permission_,
        bool value_
    ) external;

    /// @notice Sets the permissions for sender
    /// @dev Sets the permissions for sender by owner
    /// @param address_ the address of sender
    /// @param permissions_ the permissions for sender
    /// @param value_ true or false for sender's permissions
    function setPermissions(
        address address_,
        uint256[] calldata permissions_,
        bool value_
    ) external;

    /// @notice Sets the limit grant access to gran permissions
    /// @dev  Sets the limit grant access to gran permissions
    /// @param address_ the address of sender
    /// @param permission_ the permission which address_ can grant
    /// @param value_ true or false for address_ permission
    function setLimitSetPermission(
        address address_,
        uint256 permission_,
        bool value_
    ) external;

    /// @notice Registrates contract
    /// @dev Registrates contract by owner
    /// @param key_ the number that corresponds to the registered address
    /// @param target_ the address that must to be registered
    function registerContract(uint256 key_, address payable target_) external;

    /// @notice Sets the kyc whitelist
    /// @dev Sets the kyc whitelist
    /// @param address_ the addresses that need to whitelist
    /// @param value_ the true or false for kyc whitelist
    function setKycWhitelists(address[] calldata address_, bool value_) external;

    /// @notice Checks whether the sender has passed kyc
    /// @dev Checks whether the sender has passed kyc
    /// @param address_ the address of sender
    /// @param deadline_ deadline in Unix timestamp
    /// @param v_ one of the signature parameters
    /// @param r_ one of the signature parameters
    /// @param s_ one of the signature parameters
    /// @return Returns whether the sender has passed kyc
    function isKYCPassed(
        address address_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external view returns (bool);

    /// @notice Gets the registered contract by key
    /// @dev Gets the registered contract by key
    /// @param key_ the number that corresponds to the registered address
    /// @return Returns the registered contract by key
    function contractRegistry(uint256 key_) external view returns (address payable);

    /// @notice Gets whether the sender has permission
    /// @dev Gets whether the sender has permission
    /// @param address_ the address of sender
    /// @param permission_ the permission for sender
    /// @return Returns whether the sender has permission
    function permissions(address address_, uint256 permission_) external view returns (bool);

    /// @notice Returns whether the user can grant right to someone
    /// @dev Returns whether the user can grant right to someone
    /// @param address_ the address of sender
    /// @param permission_ the permission for sender
    /// @return Returns whether the user can grant right to someone
    function limitSetPermissions(address address_, uint256 permission_) external view returns (bool);
}




/** 
 * contracts\KRUExchangeForwarder.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/ContextUpgradeable.sol";
////import "../proxy/utils/Initializable.sol";

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




/** 
 * contracts\KRUExchangeForwarder.sol
*/
            

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 * contracts\KRUExchangeForwarder.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}




/** 
 * contracts\KRUExchangeForwarder.sol
*/
            

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

////import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * ////IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * ////IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}




/** 
 * contracts\KRUExchangeForwarder.sol
*/
            


pragma solidity 0.8.11;

////import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
////import "../interfaces/IManagement.sol";
////import "./Constants.sol";

/// @title Managed
/// @author Applicature
/// @notice This contract allows initialize the address of management, set permission for sender etc
/// @dev This contract allows initialize the address of management, set permission for sender etc
abstract contract ManagedUpgradeable is OwnableUpgradeable {
    /// @notice The state variable of IManagement interface
    /// @dev The state variable of IManagement interface
    IManagement public management;

    /// @notice Checks whether the sender has permission prior to executing the function
    /// @dev Checks whether the sender has permission prior to executing the function
    /// @param permission_ the permission for sender
    modifier requirePermission(uint256 permission_) {
        require(_hasPermission(_msgSender(), permission_), ERROR_ACCESS_DENIED);
        _;
    }

    /// @notice Checks whether the sender is a registered contract
    /// @dev Checks whether the sender is a registered contract
    /// @param key_ the number that corresponds to the registered address
    modifier canCallOnlyRegisteredContract(uint256 key_) {
        require(_msgSender() == management.contractRegistry(key_), ERROR_ACCESS_DENIED);
        _;
    }

    /// @notice Initializes the address of management after deployment
    /// @dev Initializes the address of management after deployment by owner of smart contract
    /// @param managementAddress_ the address of management
    function setManagementContract(address managementAddress_) external virtual onlyOwner {
        require(address(0) != managementAddress_, ERROR_NO_CONTRACT);
        management = IManagement(managementAddress_);
    }

    /// @notice Initializes the address of management and initial owner
    /// @dev Initializes the address of management, initial owner and protect from being invoked twice
    /// @param managementAddress_ the address of management
    /* solhint-disable */
    function __Managed_init(address managementAddress_) internal virtual onlyInitializing {
        require(address(0) != managementAddress_, ERROR_NO_CONTRACT);
        management = IManagement(managementAddress_);
        __Ownable_init();
    }

    /// @notice Checks whether the sender has permission
    /// @dev Checks whether the sender has permission
    /// @param subject_ the address of sender
    /// @param permission_ the permission for sender
    /// @return Returns whether the sender has permission
    function _hasPermission(address subject_, uint256 permission_) internal view virtual returns (bool) {
        return management.permissions(subject_, permission_);
    }
}




/** 
 * contracts\KRUExchangeForwarder.sol
*/
            

pragma solidity 0.8.11;

/// @title IKRUExchangeForwarder
/// @author Applicature
/// @notice There is an interface to KRUExchangeForwarder contract
/// @dev There is an interface to KRUExchangeForwarder contract
interface IKRUExchangeForwarder {
    /// @notice Generated when admin set destination address
    /// @dev Generated when admin set destination address
    /// @param destination_ the address to which any funds sent to this contract will be forwarded
    event DestinationSet(address indexed destination_);

    /// @notice Generated when admin set tokens which be available for transfer to destination address
    /// @dev Generated when admin set tokens which be available for transfer to destination address
    /// @param tokens_ the array of addresses of tokens
    /// @param value_ whether tokens available or not (true or false)
    event AvailableTokensSet(address[] indexed tokens_, bool value_);

    /// @notice Generated when signer forward amount of tokens or native coin to destination address
    /// @dev Generated when signer forward amount of tokens or native coin to destination address
    /// @param sender_ the address of sender
    /// @param recipient_ the destination address
    /// @param token_ the address of token
    /// @param amount_ the amount of tokens or native coin
    /// @param data_ data to bytes to emit transaction
    event Forward(
        address indexed sender_,
        address indexed recipient_,
        address indexed token_,
        uint256 amount_,
        string data_
    );

    /// @notice Set destination address by admin
    /// @dev Emit {DestinationSet} event
    /// @param destination_ the address to which any funds sent to this contract will be forwarded
    function setDestinationAddress(address destination_) external;

    /// @notice Set addresses of tokens which be available for transfer to destination address
    /// @dev Zero address is used to forward native coin
    /// @param tokens_ the array of addresses of tokens
    /// @param value_ whether tokens available or not (true or false)
    function setAvailableTokens(address[] calldata tokens_, bool value_) external;

    /// @notice Forward amount of tokens or native coin to destination address
    /// @dev Expire date, signature, nonce will be checked by EIP712
    /// @param token_ the address of token
    /// @param amount_ the amount of tokens
    /// @param deadline_ expire date of signature
    /// @param nonce_ the counter that keeps track of the number of transactions sent by an account
    /// @param data_ data to bytes to emit transaction
    /// @param v_ signature parameter
    /// @param r_ signature parameter
    /// @param s_ signature parameter
    function forward(
        address token_,
        uint256 amount_,
        uint256 deadline_,
        uint256 nonce_,
        string memory data_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external payable;

    /// @notice Get the address to which any funds sent to this contract will be forwarded
    /// @dev Get the address to which any funds sent to this contract will be forwarded
    function destinationAddress() external view returns (address);

    /// @notice Get whether the token is available
    /// @dev Zero address is used to forward native coin
    /// @param token_ the address of token
    /// @return Return whether the token is available (true or false)
    function availableTokens(address token_) external view returns (bool);
}




/** 
 * contracts\KRUExchangeForwarder.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

////import "../IERC20Upgradeable.sol";
////import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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




/** 
 * contracts\KRUExchangeForwarder.sol
*/
            

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

////import "./ECDSAUpgradeable.sol";
////import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


/** 
 * contracts\KRUExchangeForwarder.sol
*/


pragma solidity 0.8.11;

////import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
////import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
////import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
////import "./interfaces/IKRUExchangeForwarder.sol";
////import "./management/ManagedUpgradeable.sol";

/// @title KRUExchangeForwarder
/// @author Applicature
/// @notice There is a Smart Contract that is used to forward ERC20 tokens or native coin to destination address
/// @dev There is a Smart Contract that is used to forward ERC20 tokens or native coin to destination address
contract KRUExchangeForwarder is IKRUExchangeForwarder, ManagedUpgradeable, EIP712Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Store the address to which any funds sent to this contract will be forwarded
    address public override destinationAddress;

    /// @notice Store the addresses of tokens which be available for transfer to destination address
    /// @dev Zero address is used to forward native coin
    /// @return Bool whether token is available
    mapping(address => bool) public override availableTokens;

    /// @notice Store nonces of signers
    /// @dev Store nonces of signers
    mapping(address => mapping(uint256 => bool)) internal _nonces;

    /// @notice Store hash to sign forward transaction
    /// @dev Store computed 256 bit keccak hash
    bytes32 private constant _CONTAINER_TYPEHASH =
        keccak256("Container(address sender,address token,uint256 amount,uint256 deadline,uint256 nonce,string data)");

    /// @notice Initializes the address of management
    /// @dev Initializes the address of management
    /// @param management_ the address of management
    /// @param destination_ the address to which any funds sent to this contract will be forwarded
    function initialize(address management_, address destination_) external virtual initializer {
        __Managed_init(management_);
        __EIP712_init("KRUExchangeForwarder", "v1");
        _setDestinationAddress(destination_);
    }

    /// @notice Set destination address by admin
    /// @dev Emit {DestinationSet} event
    /// @param destination_ the address to which any funds sent to this contract will be forwarded
    function setDestinationAddress(address destination_)
        external
        virtual
        override
        requirePermission(EXCHANGE_FORWARDER_CAN_SET_ADDRESSES)
    {
        _setDestinationAddress(destination_);
    }

    /// @notice Set addresses of tokens which be available for transfer to destination address
    /// @dev Zero address is used to forward native coin
    /// @param tokens_ the array of addresses of tokens
    /// @param value_ whether tokens available or not (true or false)
    function setAvailableTokens(address[] calldata tokens_, bool value_)
        external
        virtual
        override
        requirePermission(EXCHANGE_FORWARDER_CAN_SET_ADDRESSES)
    {
        for (uint256 i; i < tokens_.length; i++) {
            availableTokens[tokens_[i]] = value_;
        }
        emit AvailableTokensSet(tokens_, value_);
    }

    /// @notice Forward amount of tokens or native coin to destination address
    /// @dev Expire date, signature, nonce will be checked by EIP712
    /// @param token_ the address of token
    /// @param amount_ the amount of tokens
    /// @param deadline_ expire date of signature
    /// @param nonce_ the counter that keeps track of the number of transactions sent by an account
    /// @param data_ data to bytes to emit transaction
    /// @param v_ signature parameter
    /// @param r_ signature parameter
    /// @param s_ signature parameter
    function forward(
        address token_,
        uint256 amount_,
        uint256 deadline_,
        uint256 nonce_,
        string memory data_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external payable virtual override {
        require(availableTokens[token_], ERROR_ACCESS_DENIED);
        uint256 amount = token_ == address(0) ? msg.value : amount_;
        _forward(_msgSender(), token_, amount, deadline_, nonce_, data_, v_, r_, s_);
    }

    /// @notice Forward amount of native coin or tokens to destination address
    /// @dev Expire date, signature, nonce will be checked by EIP712
    /// @param sender_ the address of sender
    /// @param token_ the address of token
    /// @param amount_ the amount of tokens or native coin
    /// @param deadline_ expire date of signature
    /// @param nonce_ the counter that keeps track of the number of transactions sent by an account
    /// @param data_ data to bytes to emit transaction
    /// @param v_ signature parameter
    /// @param r_ signature parameter
    /// @param s_ signature parameter
    function _forward(
        address sender_,
        address token_,
        uint256 amount_,
        uint256 deadline_,
        uint256 nonce_,
        string memory data_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal virtual {
        require(!_nonces[sender_][nonce_], ERROR_ACCESS_DENIED);
        require(amount_ != 0, ERROR_AMOUNT_IS_ZERO);
        require(_isValidSigner(sender_, token_, amount_, deadline_, nonce_, data_, v_, r_, s_), ERROR_INVALID_SIGNER);
        _nonces[sender_][nonce_] = true;
        if (token_ != address(0)) {
            IERC20Upgradeable(token_).safeTransferFrom(sender_, destinationAddress, amount_);
        } else {
            (bool success, ) = payable(destinationAddress).call{value: amount_}("");
            require(success, ERROR_SEND_VALUE);
        }
        emit Forward(sender_, destinationAddress, token_, amount_, data_);
    }

    /// @notice Set destination address by admin
    /// @dev Emit {DestinationSet} event
    /// @param destination_ the address to which any funds sent to this contract will be forwarded
    function _setDestinationAddress(address destination_) internal virtual {
        require(destination_ != address(0), ERROR_INVALID_ADDRESS);
        destinationAddress = destination_;
        emit DestinationSet(destination_);
    }

    /// @notice Check whether signer is valid
    /// @dev Expire date, signature, nonce will be checked by EIP712
    /// @param sender_ the address of sender
    /// @param token_ the address of token
    /// @param amount_ the amount of tokens or native coin
    /// @param deadline_ expire date of signature
    /// @param nonce_ the counter that keeps track of the number of transactions sent by an account
    /// @param data_ data to bytes to emit transaction
    /// @param v_ signature parameter
    /// @param r_ signature parameter
    /// @param s_ signature parameter
    function _isValidSigner(
        address sender_,
        address token_,
        uint256 amount_,
        uint256 deadline_,
        uint256 nonce_,
        string memory data_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) internal view virtual returns (bool) {
        require(deadline_ > block.timestamp, ERROR_TIME_OUT);
        bytes32 structHash = keccak256(
            abi.encode(_CONTAINER_TYPEHASH, sender_, token_, amount_, deadline_, nonce_, keccak256(bytes(data_)))
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address messageSigner = ECDSAUpgradeable.recover(hash, v_, r_, s_);
        return _hasPermission(messageSigner, EXCHANGE_FORWARDER_SIGNER);
    }
}