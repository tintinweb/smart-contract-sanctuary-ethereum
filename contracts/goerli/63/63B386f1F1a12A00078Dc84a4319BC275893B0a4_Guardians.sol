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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./libraries/GuardianTimeMath.sol";
import "./interfaces/IERC11554K.sol";
import "./interfaces/IFeesManager.sol";
import "./interfaces/IERC11554KController.sol";

/**
 * @dev Guardians management contract.
 * Sets guardians parameters, fees, info
 * by guardians themselves and the protocol.
 */
contract Guardians is Initializable, OwnableUpgradeable {
    /// @dev Guardian Info struct.
    struct GuardianInfo {
        /// @notice Hashed physical address of a guardian.
        bytes32 addressHash;
        /// @notice Logo of a guardian.
        string logo;
        /// @notice Name of a guardian.
        string name;
        /// @notice A guardian's redirect URI for future authentication flows.
        string redirect;
        /// @notice Guardian's policy.
        string policy;
        /// @notice Active status for a guardian
        bool isActive;
        /// @notice Private status for a guardian.
        bool isPrivate;
    }

    enum GuardianFeeRatePeriods {
        SECONDS,
        MINUTES,
        HOURS,
        DAYS
    }

    /// @dev Guardian class struct.
    struct GuardianClass {
        /// @notice Maximum insurance on-chain coverage.
        uint256 maximumCoverage;
        /// @notice Minting fee. Stored scaled by 10^18.
        uint256 mintingFee;
        /// @notice Redemption fee. Stored scaled by 10^18.
        uint256 redemptionFee;
        /// @notice The base unit for the guardian fee rate.
        uint256 guardianFeeRatePeriod;
        /// @notice Guardian fee rate per period. Stored scaled by 10^18.
        uint256 guardianFeeRate;
        /// @notice Guardian fee rate historic minimum.
        uint256 guardianFeeRateMinimum;
        /// @notice Last Guardian fee rate increase update timestamp.
        uint256 lastGuardianFeeRateIncrease;
        /// @notice Is guardian class active.
        bool isActive;
        /// @notice Guardian URI for metadata.
        string uri;
    }

    uint256 public constant SECOND = 1;
    uint256 public constant MINUTE = 60;
    uint256 public constant HOUR = MINUTE * 60;
    uint256 public constant DAY = HOUR * 24;

    /// @notice Fee manager contract.
    IFeesManager public feesManager;

    /// @notice Controller contract.
    IERC11554KController public controller;

    /// @notice Percentage factor with 0.01% precision. For internal float calculations.
    uint256 public constant PERCENTAGE_FACTOR = 10000;

    /// @notice Minimum minting request fee.
    uint256 public minimumRequestFee;
    /// @notice Minimum time window for guardian fee rate increase.
    uint256 public guardianFeeSetWindow;
    /// @notice Maximum guardian fee rate percentage increase during single fee set, 0.01% precision.
    uint256 public maximumGuardianFeeSet;
    /// @notice Minimum storage time an item needs to have for transfers.
    uint256 public minStorageTime;

    /// @notice Is an address a 4K whitelisted guardian.
    mapping(address => bool) public isWhitelisted;

    /// @notice Metadata info about a guardian
    mapping(address => GuardianInfo) public guardianInfo;

    /// @notice Guardians whitelisted users for services.
    mapping(address => mapping(address => bool)) public guardianWhitelist;
    /// @notice To whom (if) guardian delegated functions to execute
    mapping(address => address) public delegated;
    /// @notice  Guardian classes of a particular guardian.
    mapping(address => GuardianClass[]) public guardiansClasses;
    /// @notice How much items with id guardian keeps.
    /// guardian -> collection -> id -> amount
    mapping(address => mapping(IERC11554K => mapping(uint256 => uint256)))
        public stored;
    /// @notice At which guardian is each item stored.
    /// collection address -> item id -> guardian address
    mapping(IERC11554K => mapping(uint256 => address)) public whereItemStored;

    /// @notice In which guardian class is the item? (within the context of the guardian where the item is stored)
    /// collection address -> item id -> guardian class index
    mapping(IERC11554K => mapping(uint256 => uint256)) public itemGuardianClass;

    /// @notice Mapping from a token holder address to a collection to an item id, to the date until storage has been paid.
    mapping(address => mapping(IERC11554K => mapping(uint256 => uint256)))
        public guardianFeePaidUntil;

    /// @notice Mapping from a collection, to item id, to the date until storage has been paid (globally, collectively for all users).
    /// @dev We need this for the movement of all items from one guardian to another.
    mapping(IERC11554K => mapping(uint256 => uint256))
        public globalItemGuardianFeePaidUntil;

    /// @notice user -> collection -> item id -> num items in repossession
    /// @notice Number of items in a collection that a user has in repossession.
    mapping(address => mapping(IERC11554K => mapping(uint256 => uint256)))
        public inRepossession;

    /// @notice guardian => delegatee => true if guardian delegates some functions to delegatee.
    mapping(address => mapping(address => bool)) public delegatedAll;

    /// @notice guardian => collection => delegatee if guardian delegates some functions to delegatee.
    mapping(address => mapping(IERC11554K => address))
        public delegatedCollection;

    /// @dev Guardian has been added.
    event GuardianAdded(address indexed guardian);
    /// @dev Guardian has been removed.
    event GuardianRemoved(address indexed guardian);
    /// @dev Guardian class has been added.
    event GuardianClassAdded(address indexed guardian, uint256 classID);
    /// @dev Guardian class has been modified.
    event GuardianClassModified(address indexed guardian, uint256 classID);

    /// @dev Item has been stored by the guardian
    event ItemStored(
        address indexed guardian,
        uint256 classID,
        uint256 tokenId,
        IERC11554K collection
    );

    /// @dev Item has been moved from one guardian to another
    event ItemMoved(
        address indexed fromGuardian,
        address indexed toGuardian,
        uint256 toGuardianClassId,
        uint256 tokenId,
        IERC11554K collection
    );

    /// @dev Storage time has been purchased for an item.
    event StorageTimeAdded(
        uint256 indexed id,
        address indexed guardian,
        uint256 timeAmount
    );
    /// @dev Item(s) have been set for repossession.
    event SetForRepossession(
        uint256 indexed id,
        IERC11554K indexed collection,
        address indexed guardian,
        uint256 amount
    );
    /// @dev Guardian has been added - with metadata.
    event GuardianRegistered(
        address indexed guardian,
        string name,
        string logo,
        string policy,
        bool privacy,
        string redirect,
        bytes32 addressHash
    );

    /**
     * @dev Only whitelisted guardian modifier.
     */
    modifier onlyWhitelisted(address guardian) {
        require(isWhitelisted[guardian], "Not whitelisted");
        _;
    }

    /**
     * @dev Only controller modifier.
     */
    modifier onlyController() {
        require(_msgSender() == address(controller), "Not controller");
        _;
    }

    /**
     * @dev Only controller modifier.
     */
    modifier ifNotOwnerGuardianIsCaller(address guardian) {
        if (_msgSender() != owner()) {
            require(_msgSender() == guardian, "can only modify own data");
        }
        _;
    }

    /**
     * @notice Initialize Guardians contract.
     * @param minimumRequestFee_ The minimum mint request fee.
     * @param guardianFeeSetWindow_ The window of time in seconds within a guardian is allowed to increase a guardian fee rate.
     * @param maximumGuardianFeeSet_ The max percentage increase that a guardian can increase a guardian fee rate by. Numerator that generates percentage, over the PERCENTAGE_FACTOR.
     * @param feesManager_ Fees manager contract address.
     * @param controller_ Controller contract address.
     */
    function initialize(
        uint256 minimumRequestFee_,
        uint256 guardianFeeSetWindow_,
        uint256 maximumGuardianFeeSet_,
        IFeesManager feesManager_,
        IERC11554KController controller_
    ) external initializer {
        __Ownable_init();
        minimumRequestFee = minimumRequestFee_;
        guardianFeeSetWindow = guardianFeeSetWindow_;
        maximumGuardianFeeSet = maximumGuardianFeeSet_;
        minStorageTime = 7776000; // default 90 days
        feesManager = feesManager_;
        controller = controller_;
    }

    /**
     * @notice Set controller.
     *
     * Requirements:
     *
     * 1) The caller must be a contract admin.
     * @param controller_ New address of controller contract.
     */
    function setController(IERC11554KController controller_)
        external
        virtual
        onlyOwner
    {
        controller = controller_;
    }

    /**
     * @notice Set fees manager.
     *
     * Requirements:
     *
     * 1) The caller must be a contract admin.
     @param feesManager_ New address of fees manager contract.
     */
    function setFeesManager(IFeesManager feesManager_)
        external
        virtual
        onlyOwner
    {
        feesManager = feesManager_;
    }

    /**
     * @notice Sets new min storage time.
     *
     * Requirements:
     *
     * 1) The caller must be a contract admin.
     * @param minStorageTime_ New minimum storage time that items require to have, in seconds.
     */
    function setMinStorageTime(uint256 minStorageTime_)
        external
        virtual
        onlyOwner
    {
        require(minStorageTime_ > 0, "storage time is 0");
        minStorageTime = minStorageTime_;
    }

    /**
     * @notice Sets minimum mining fee.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param minimumRequestFee_ New minumum mint request fee.
     */
    function setMinimumRequestFee(uint256 minimumRequestFee_)
        external
        onlyOwner
    {
        minimumRequestFee = minimumRequestFee_;
    }

    /**
     * @notice Sets maximum Guardian fee rate set percentage.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param maximumGuardianFeeSet_ New max percentage increase that a guardian can increase a guardian fee rate by. Numerator that generates percentage, over the PERCENTAGE_FACTOR
     */
    function setMaximumGuardianFeeSet(uint256 maximumGuardianFeeSet_)
        external
        onlyOwner
    {
        maximumGuardianFeeSet = maximumGuardianFeeSet_;
    }

    /**
     * @notice Sets minimum Guardian fee.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param guardianFeeSetWindow_ New window of time in seconds within a guardian is allowed to increase a guardian fee rate
     */
    function setGuardianFeeSetWindow(uint256 guardianFeeSetWindow_)
        external
        onlyOwner
    {
        guardianFeeSetWindow = guardianFeeSetWindow_;
    }

    /**
     * @notice Does a batch adding of storage for all the items passed.
     * @param collections Array of collections that contain the items for which guardian time will be purchased.
     * @param beneficiaries Array of addresses that will be receiving the purchased guardian time.
     * @param ids Array of item ids for which guardian time will be purchased.
     * @param guardianFeeAmounts Array of guardian fee inputs for purchasing guardian time.
     */
    function batchAddStorageTime(
        IERC11554K[] calldata collections,
        address[] calldata beneficiaries,
        uint256[] calldata ids,
        uint256[] calldata guardianFeeAmounts
    ) external virtual {
        for (uint256 i = 0; i < ids.length; i++) {
            addStorageTime(
                collections[i],
                beneficiaries[i],
                ids[i],
                guardianFeeAmounts[i]
            );
        }
    }

    /**
     * @dev Externally called store item function by controller.
     * @param collection Address of the collection that the item being stored belongs to.
     * @param mintAddress Address of entity receiving the token(s).
     * @param id Item id of the item being stored.
     * @param guardian Address of guardian the item will be stored in.
     * @param guardianClassIndex Index of the guardian class the item will be stored in.
     * @param guardianFeeAmount Amount of fee that is being paid to purchase guardian time.
     * @param numItems Number of items being stored
     * @param feePayer The address of the entity paying the guardian fee.
     */
    function controllerStoreItem(
        IERC11554K collection,
        address mintAddress,
        uint256 id,
        address guardian,
        uint256 guardianClassIndex,
        uint256 guardianFeeAmount,
        uint256 numItems,
        address feePayer,
        IERC20Upgradeable paymentAsset
    ) external virtual onlyController {
        stored[guardian][collection][id] += numItems;
        whereItemStored[collection][id] = guardian;
        itemGuardianClass[collection][id] = guardianClassIndex;

        // Only needs to be done in non-free guardian classes
        if (
            guardiansClasses[guardian][guardianClassIndex].guardianFeeRate > 0
        ) {
            // Initialize paid until timelines on first ever mints
            if (guardianFeePaidUntil[mintAddress][collection][id] == 0) {
                guardianFeePaidUntil[mintAddress][collection][id] = block
                    .timestamp;
            }
            if (globalItemGuardianFeePaidUntil[collection][id] == 0) {
                globalItemGuardianFeePaidUntil[collection][id] = block
                    .timestamp;
            }
            {
                uint256 addedStorageTime = GuardianTimeMath
                    .calculateAddedGuardianTime(
                        guardianFeeAmount,
                        guardiansClasses[guardian][guardianClassIndex]
                            .guardianFeeRate,
                        guardiansClasses[guardian][guardianClassIndex]
                            .guardianFeeRatePeriod,
                        numItems
                    );

                guardianFeePaidUntil[mintAddress][collection][
                    id
                ] += addedStorageTime;
                globalItemGuardianFeePaidUntil[collection][
                    id
                ] += addedStorageTime;

                emit StorageTimeAdded(id, guardian, addedStorageTime);
            }

            feesManager.payGuardianFee(
                guardianFeeAmount,
                (guardiansClasses[guardian][guardianClassIndex]
                    .guardianFeeRate * numItems) /
                    getGuardianFeeRatePeriod(guardian, guardianClassIndex),
                guardian,
                guardianFeePaidUntil[mintAddress][collection][id],
                feePayer,
                paymentAsset
            );

            emit ItemStored(guardian, guardianClassIndex, id, collection);
        }
    }

    /**
     * @dev Externally called take item out function by controller.
     * @param guardian Address of guardian the item is being stored in.
     * @param collection Address of the collection that the item being stored belongs to.
     * @param id Item id of the item being stored.
     * @param numItems Number of items that are being taken out of the guardian.
     * @param from Address of the entity requesting the redemption of the item(s).
     */
    function controllerTakeItemOut(
        address guardian,
        IERC11554K collection,
        uint256 id,
        uint256 numItems,
        address from
    )
        external
        virtual
        //IERC20Upgradeable paymentAsset //no refunds
        onlyController
    {
        require(
            inRepossession[from][collection][id] < numItems,
            "Too many reposession items"
        );
        uint256 guardianClassFeeRate = getGuardianFeeRate(
            guardian,
            itemGuardianClass[collection][id]
        );

        uint256 guardianFeeRatePeriod = getGuardianFeeRatePeriod(
            guardian,
            itemGuardianClass[collection][id]
        );

        // No refunds
        // uint256 previousPaidUntil = guardianFeePaidUntil[from][collection][id];
        // uint256 guardianFeeRefundAmount;

        if (guardianClassFeeRate > 0) {
            // No refunds
            // guardianFeeRefundAmount =
            _shiftGuardianFeesOnTokenRedeem(
                from,
                collection,
                id,
                numItems,
                guardianClassFeeRate,
                guardianFeeRatePeriod
            );
        }

        stored[guardian][collection][id] -= numItems;
        if (stored[guardian][collection][id] == 0) {
            whereItemStored[collection][id] = address(0);
        }

        // No refunds
        /*
        uint256 guardianClassFeeRateMin = getGuardianFeeRateMinimum(guardian, itemGuardianClass[collection][id]);
        if (guardianClassFeeRate > 0) {
            feesManager.refundGuardianFee(
                guardianFeeRefundAmount,
                (guardianClassFeeRateMin * numItems) / guardianFeeRatePeriod,
                guardian,
                previousPaidUntil,
                from,
                paymentAsset
            );
        }
        */
    }

    /**
     * @notice Moves items from inactive guardian to active guardian. Move ALL items,
     * in the case of semi-fungibles. Must pass a guardian classe for each item for the new guardian.
     *
     * Requirements:
     *
     * 1) The caller must be 4K.
     * 2) Old guardian must be inactive.
     * 3) New guardian must be active.
     * 4) Each class passed for each item for the new guardian must be active.
     * 5) Must only be used to move ALL items and have movement of guardian fees after moving ALL items.
     * @param collection Address of the collection that includes the items being moved.
     * @param ids Array of item ids being moved.
     * @param oldGuardian Address of the guardian items are being moved from.
     * @param newGuardian Address of the guardian items are being moved to.
     * @param newGuardianClassIndeces Array of the newGuardian's guardian class indices the items will be moved to.
     */
    function moveItems(
        IERC11554K collection,
        uint256[] calldata ids,
        address oldGuardian,
        address newGuardian,
        uint256[] calldata newGuardianClassIndeces
    ) external virtual onlyOwner {
        require(!isAvailable(oldGuardian), "Old guardian is available");
        require(isAvailable(newGuardian), "New guardian is not available");
        for (uint256 i = 0; i < ids.length; ++i) {
            require(
                isClassActive(newGuardian, newGuardianClassIndeces[i]),
                "Non active class"
            );
            _moveSingleItem(
                collection,
                ids[i],
                oldGuardian,
                newGuardian,
                newGuardianClassIndeces[i]
            );
        }
    }

    /**
     * @notice Copies all guardian classes from one guardian to another.
     * @dev If new guardian has no guardian classes before this, class indeces will be the same. If not, copies classes will have new indeces.
     *
     * @param oldGuardian Address of the guardian whose classes will be moved.
     * @param newGuardian Address of the guardian that will be receiving the classes.
     */
    function copyGuardianClasses(address oldGuardian, address newGuardian)
        external
        virtual
        onlyOwner
    {
        for (uint256 i = 0; i < guardiansClasses[oldGuardian].length; i++) {
            _copyGuardianClass(oldGuardian, newGuardian, i);
        }
    }

    /**
     * @notice Function for the guardian to set item(s) to be flagged for repossession.
     * @param collection Collection that contains the item to be repossessed.
     * @param itemId Id of item(s) being reposessed.
     * @param owner Current owner of the item(s).
     */
    function setItemsToRepossessed(
        IERC11554K collection,
        uint256 itemId,
        address owner
    ) external {
        require(
            whereItemStored[collection][itemId] == _msgSender(),
            "Not guardian of items"
        );
        require(
            getGuardianFeeRateByCollectionItem(collection, itemId) > 0,
            "Items in a free storage class cannot be repossessed"
        );
        require(
            guardianFeePaidUntil[owner][collection][itemId] != 0 &&
                guardianFeePaidUntil[owner][collection][itemId] <
                block.timestamp,
            "Repossession = timepaiduntil is in the past"
        );

        uint256 currAmount = IERC11554K(collection).balanceOf(owner, itemId);
        require(currAmount > 0, "No items to repossess");

        uint256 prevInReposession = inRepossession[owner][collection][itemId];
        inRepossession[owner][collection][itemId] = currAmount;

        emit SetForRepossession(
            itemId,
            collection,
            _msgSender(),
            currAmount - prevInReposession
        );
    }

    /**
     * @notice Sets activity mode for the guardian. Either active or not.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian whose activity mode will be set.
     * @param activity Boolean for guardian activity mode.
     */
    function setActivity(address guardian, bool activity)
        external
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardianInfo[guardian].isActive = activity;
    }

    /**
     * @notice Sets privacy mode for the guardian. Either public false or private true.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian whose privacy mode will be set.
     * @param privacy Boolean for guardian privacy mode.
     */
    function setPrivacy(address guardian, bool privacy)
        external
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardianInfo[guardian].isPrivate = privacy;
    }

    /**
     * @notice Sets logo for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian address of guardian whose logo will be set.
     * @param logo URI of logo for guardian.
     */
    function setLogo(address guardian, string calldata logo)
        external
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardianInfo[guardian].logo = logo;
    }

    /**
     * @notice Sets name for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian whose name will be set.
     * @param name Name of guardian.
     */
    function setName(address guardian, string calldata name)
        external
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardianInfo[guardian].name = name;
    }

    /**
     * @notice Sets physical address hash for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian whose physical address will be set.
     * @param physicalAddressHash Bytes hash of physical address of the guardian.
     */
    function setPhysicalAddressHash(
        address guardian,
        bytes32 physicalAddressHash
    ) external onlyWhitelisted(guardian) ifNotOwnerGuardianIsCaller(guardian) {
        guardianInfo[guardian].addressHash = physicalAddressHash;
    }

    /**
     * @notice Sets policy for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian whose policy will be set.
     * @param policy Guardian policy.
     */
    function setPolicy(address guardian, string calldata policy)
        external
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardianInfo[guardian].policy = policy;
    }

    /**
     * @notice Sets redirects for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian whose redirect URI will be set.
     * @param redirect Redirect URI for guardian.
     */
    function setRedirect(address guardian, string calldata redirect)
        external
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardianInfo[guardian].redirect = redirect;
    }

    /**
     * @notice Adds or removes users addresses to guardian whitelist.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian whose users whitelist status will be modified.
     * @param users Array of user addresses whose whitelist status will be modified.
     * @param whitelistStatus Boolean for the whitelisted status of the users.
     */
    function changeWhitelistUsersStatus(
        address guardian,
        address[] calldata users,
        bool whitelistStatus
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        for (uint256 i = 0; i < users.length; ++i) {
            guardianWhitelist[guardian][users[i]] = whitelistStatus;
        }
    }

    /**
     * @notice Removes guardian from the whitelist.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param guardian address of guardian who will be removed.
     */
    function removeGuardian(address guardian) external virtual onlyOwner {
        isWhitelisted[guardian] = false;
        guardianInfo[guardian].isActive = false;
        emit GuardianRemoved(guardian);
    }

    /**
     * @notice Sets minting fee for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or the owner.
     * @param guardian Address of the guardian whose guardian class minting fee will be modified.
     * @param classID Guardian's guardian class index whose minting fee will be modified.
     * @param mintingFee New minting fee. Minting fee must be passed as already scaled by 10^18 from real life value.
     */
    function setGuardianClassMintingFee(
        address guardian,
        uint256 classID,
        uint256 mintingFee
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        require(mintingFee >= minimumRequestFee, "Lower than mininum");
        guardiansClasses[guardian][classID].mintingFee = mintingFee;
        emit GuardianClassModified(guardian, classID);
    }

    /**
     * @notice Sets redemption fee for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or the owner
     * @param guardian Address of the guardian whose guardian class redemption fee will be modified.
     * @param classID Guardian's guardian class index whose redemption fee will be modified.
     * @param redemptionFee New redemption fee. Redemption fee must be passed as already scaled by 10^18 from real life value.
     */
    function setGuardianClassRedemptionFee(
        address guardian,
        uint256 classID,
        uint256 redemptionFee
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardiansClasses[guardian][classID].redemptionFee = redemptionFee;
        emit GuardianClassModified(guardian, classID);
    }

    /**
     * @notice Sets Guardian fee rate for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or the owner.
     * @param guardian Address of the guardian whose guardian class guardian fee rate will be modified.
     * @param classID Guardian's guardian class index whose guardian fee rate  will be modified.
     * @param guardianFeeRate New guardian fee rate. Guardain fee rate must be passed as already scaled by 10^18 from real life value.
     */
    function setGuardianClassGuardianFeeRate(
        address guardian,
        uint256 classID,
        uint256 guardianFeeRate
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        _setGuardianClassGuardianFeeRate(
            guardian,
            classID,
            guardianFeeRate,
            guardiansClasses[guardian][classID].guardianFeeRatePeriod
        );
    }

    /**
     * @notice Sets Guardian fee rate and guardian fee rate period for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or the owner.
     * @param guardian Address of the guardian whose guardian class guardian fee rate will be modified.
     * @param classID Guardian's guardian class index whose guardian fee rate  will be modified.
     * @param guardianFeeRatePeriod New guardian fee rate period.
     * @param guardianFeeRate New guardian fee rate. Guardain fee rate must be passed as already scaled by 10^18 from real life value.
     */
    function setGuardianClassGuardianFeePeriodAndRate(
        address guardian,
        uint256 classID,
        GuardianFeeRatePeriods guardianFeeRatePeriod,
        uint256 guardianFeeRate
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        uint256 newPeriodMultiple;
        if (guardianFeeRatePeriod == GuardianFeeRatePeriods.SECONDS) {
            newPeriodMultiple = SECOND;
        } else if (guardianFeeRatePeriod == GuardianFeeRatePeriods.MINUTES) {
            newPeriodMultiple = MINUTE;
        } else if (guardianFeeRatePeriod == GuardianFeeRatePeriods.HOURS) {
            newPeriodMultiple = HOUR;
        } else if (guardianFeeRatePeriod == GuardianFeeRatePeriods.DAYS) {
            newPeriodMultiple = DAY;
        }
        require(
            guardiansClasses[guardian][classID].guardianFeeRatePeriod !=
                newPeriodMultiple,
            "Choose a different period"
        );

        _setGuardianClassGuardianFeeRate(
            guardian,
            classID,
            guardianFeeRate,
            newPeriodMultiple
        );

        guardiansClasses[guardian][classID]
            .guardianFeeRatePeriod = newPeriodMultiple;
    }

    /**
     * @notice Sets URI for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or owner.
     * @param guardian Address of the guardian whose guardian class URI will be modified.
     * @param classID Guardian's guardian class index whose class URI will be modified.
     * @param uri New URI.
     */
    function setGuardianClassURI(
        address guardian,
        uint256 classID,
        string calldata uri
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardiansClasses[guardian][classID].uri = uri;
        emit GuardianClassModified(guardian, classID);
    }

    /**
     * @notice Sets guardian class as active or not active by guardian or owner
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or owner.
     * @param guardian Address of the guardian whose guardian class active status will be modified.
     * @param classID Guardian's guardian class index whose guardian class active status will be modified.
     * @param activeStatus New guardian class active status.
     */
    function setGuardianClassActiveStatus(
        address guardian,
        uint256 classID,
        bool activeStatus
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardiansClasses[guardian][classID].isActive = activeStatus;
        emit GuardianClassModified(guardian, classID);
    }

    /**
     * @notice Sets maximum insurance coverage for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian.
     * @param guardian Address of the guardian whose guardian class maximum coverage will be modified.
     * @param classID Guardian's guardian class index whose guardian class maximum coverage will be modified.
     * @param maximumCoverage New guardian class maximum coverage.
     */
    function setGuardianClassMaximumCoverage(
        address guardian,
        uint256 classID,
        uint256 maximumCoverage
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
    {
        guardiansClasses[guardian][classID].maximumCoverage = maximumCoverage;
        emit GuardianClassModified(guardian, classID);
    }

    /**
     * @dev Externally called store item function by controller to update Guardian fees on token transfer. Complex logic needed for semi-fungibles.
     * @param from Address of entity sending token(s).
     * @param to Address of entity receiving token(s).
     * @param id Token id of token(s) being sent.
     * @param amount Amount of tokens being sent.
     */
    function shiftGuardianFeesOnTokenMove(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external virtual {
        require(
            controller.isActiveCollection(_msgSender()) &&
                controller.isLinkedCollection(_msgSender()),
            "Not active 4k collection"
        );
        IERC11554K collection = IERC11554K(_msgSender());

        uint256 guardianClassFeeRate = getGuardianFeeRateByCollectionItem(
            collection,
            id
        );

        uint256 guardianClassFeeRatePeriod = getGuardianFeeRatePeriodByCollectionItem(
                collection,
                id
            );

        uint256 guardianFeeShiftAmount = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[from][collection][id],
                guardianClassFeeRate,
                guardianClassFeeRatePeriod,
                amount
            );

        uint256 remainingFeeAmountFrom = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[from][collection][id],
                guardianClassFeeRate,
                guardianClassFeeRatePeriod,
                collection.balanceOf(from, id)
            );

        uint256 remainingFeeAmountTo = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[to][collection][id],
                guardianClassFeeRate,
                guardianClassFeeRatePeriod,
                collection.balanceOf(to, id)
            );

        // Recalculate the remaining time with new params for FROM
        uint256 newAmountFrom = collection.balanceOf(from, id) - amount;
        if (newAmountFrom == 0) {
            guardianFeePaidUntil[from][collection][id] = 0; //default
        } else {
            guardianFeePaidUntil[from][collection][id] =
                block.timestamp +
                GuardianTimeMath.calculateAddedGuardianTime(
                    remainingFeeAmountFrom - guardianFeeShiftAmount,
                    guardianClassFeeRate,
                    guardianClassFeeRatePeriod,
                    newAmountFrom
                );
        }

        // Recalculate the remaining time with new params for TO
        uint256 newAmountTo = collection.balanceOf(to, id) + amount;
        guardianFeePaidUntil[to][collection][id] =
            block.timestamp +
            GuardianTimeMath.calculateAddedGuardianTime(
                remainingFeeAmountTo + guardianFeeShiftAmount,
                guardianClassFeeRate,
                guardianClassFeeRatePeriod,
                newAmountTo
            );
    }

    /**
     * @notice Adds guardian class to guardian by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a whitelisted guardian or contract owner.
     * @param guardian Address of guardian who is adding a new class.
     * @param maximumCoverage Max coverage of new guardian class.
     * @param mintingFee Minting fee of new guardian class. Minting fee must be passed as already scaled by 10^18 from real life value.
     * @param redemptionFee Redemption fee of new guardian class. Redemption fee must be passed as already scaled by 10^18 from real life value.
     * @param guardianFeeRate Guardian fee rate of new guardian class. Guardian fee rate must be passed as already scaled by 10^18 from real life value.
     * @param guardianFeeRatePeriod The size of the period unit for the guardian fee rate: per second, minute, hour, or day.
     */
    function addGuardianClass(
        address guardian,
        uint256 maximumCoverage,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 guardianFeeRate,
        GuardianFeeRatePeriods guardianFeeRatePeriod,
        string calldata uri
    )
        external
        virtual
        onlyWhitelisted(guardian)
        ifNotOwnerGuardianIsCaller(guardian)
        returns (uint256 classID)
    {
        classID = _addGuardianClass(
            guardian,
            maximumCoverage,
            mintingFee,
            redemptionFee,
            guardianFeeRate,
            guardianFeeRatePeriod,
            uri
        );
    }

    /**
     * @notice Registers guardian.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param guardian Address of the new guardian.
     * @param name Name of new guardian.
     * @param logo URI of new guardian logo.
     * @param policy Policy of new guardian.
     * @param redirect Redirect URI of new guardian.
     * @param physicalAddressHash physical address hash of new guardian.
     * @param privacy Boolean - is the new guardian private or not.
     */
    function registerGuardian(
        address guardian,
        string calldata name,
        string calldata logo,
        string calldata policy,
        string calldata redirect,
        bytes32 physicalAddressHash,
        bool privacy
    ) external virtual {
        guardianInfo[guardian].isActive = true;
        guardianInfo[guardian].name = name;
        guardianInfo[guardian].logo = logo;
        guardianInfo[guardian].policy = policy;
        guardianInfo[guardian].isPrivate = privacy;
        guardianInfo[guardian].redirect = redirect;
        guardianInfo[guardian].addressHash = physicalAddressHash;
        addGuardian(guardian);
        emit GuardianRegistered(
            guardian,
            name,
            logo,
            policy,
            privacy,
            redirect,
            physicalAddressHash
        );
    }

    /**
     * @notice Delegates whole minting/redemption for all or single collection to `delegatee`
     * @param delegatee Address to which the calling guardian will delegate to.
     * @param collection If not zero address, then delegates processes only for this collection.
     */
    function delegate(
        address delegatee,
        IERC11554K collection
    ) external virtual onlyWhitelisted(_msgSender()) {
        if (address(collection) == address(0)) {
            delegatedAll[_msgSender()][delegatee] = true;
        } else {
            delegatedCollection[_msgSender()][collection] = delegatee;
        }
    }

    /**
     * @notice Undelegates whole minting/redemption for all or single collection from `delegatee`
     * @param delegatee Address to which the calling guardian will undelegate from.
     * @param collection If not zero address, then undelegates processes only for this collection.
     */
    function undelegate(
        address delegatee,
        IERC11554K collection
    ) external virtual onlyWhitelisted(_msgSender()) {
        if (address(collection) == address(0)) {
            delegatedAll[_msgSender()][delegatee] = false;
        } else {
            delegatedCollection[_msgSender()][collection] = address(0);
        }
    }

    /**
     * @notice Returns guardian class maximum coverage.
     * @param guardian Address of guardian getting queried.
     * @param classID Guardian's guardian class index being queried.
     * @return maxCoverage Max coverage for guardian's guardian class.
     */
    function getMaximumCoverage(address guardian, uint256 classID)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].maximumCoverage;
    }

    /**
     * @notice Returns guardian class URI.
     * @param guardian Address of guardian getting queried.
     * @param classID Guardian's guardian class index being queried.
     * @return URI URI for guardian's guardian class.
     */
    function getURI(address guardian, uint256 classID)
        external
        view
        virtual
        returns (string memory)
    {
        return guardiansClasses[guardian][classID].uri;
    }

    /**
     * @notice Queries if the amount of guardian fee provided purchases the minimum guardian time for a particular guardian class.
     * @param guardianFeeAmount the amount of guardian fee being queried.
     * @param numItems Number of total items the guardian would be storing.
     * @param guardian Address of the guardian that would be doing the storing.
     * @param guardianClassIndex Index of guardian class that would be doing the storing.
     */
    function isFeeAboveMinimum(
        uint256 guardianFeeAmount,
        uint256 numItems,
        address guardian,
        uint256 guardianClassIndex
    ) external view virtual returns (bool) {
        uint256 guardianClassFeeRate = getGuardianFeeRate(
            guardian,
            guardianClassIndex
        );
        uint256 guardianFeeRatePeriod = getGuardianFeeRatePeriod(
            guardian,
            guardianClassIndex
        );
        require(
            guardianClassFeeRate > 0,
            "guardian class guardian fee rate is 0"
        );
        return
            minStorageTime <=
            GuardianTimeMath.calculateAddedGuardianTime(
                guardianFeeAmount,
                guardianClassFeeRate,
                guardianFeeRatePeriod,
                numItems
            );
    }

    /**
     * @notice Returns guardian class redemption fee.
     * @param guardian Address of guardian whose guardian class is being queried.
     * @param classID Guardian's guardian class index being queried.
     * @return redemptionFee Guardian class's redemption fee. Returns scaled by 10^18 real life value.
     */
    function getRedemptionFee(address guardian, uint256 classID)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].redemptionFee;
    }

    /**
     * @notice Returns guardian class redemption fee of a stored item in collection with itemId.
     * @param collection Address of the collection where the item being queried belongs to.
     * @param itemId Item id of item whose redemption fee is being queried.
     */
    function getRedemptionFeeByCollectionItem(
        IERC11554K collection,
        uint256 itemId
    ) external view virtual returns (uint256) {
        address guardian = whereItemStored[collection][itemId];
        uint256 guardianClassIndex = itemGuardianClass[collection][itemId];
        return guardiansClasses[guardian][guardianClassIndex].redemptionFee;
    }

    /**
     * @notice Returns guardian class minting fee.
     * @param guardian Address of guardian whose guardian class is being queried.
     * @param classID Guardian's guardian class index being queried.
     * @return mintingFee Guardian class's minting fee. Returns scaled by 10^18 real life value.
     */
    function getMintingFee(address guardian, uint256 classID)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].mintingFee;
    }

    /**
     * @notice Returns guardian class last Guardian fee rate update timestamp.
     * @param guardian Address of guardian whose guardian class is being queried.
     * @param classID Guardian's guardian class index being queried.
     * @return lastGuardianFeeRateIncrease Timestamp of the last time the guardian class' fee rate was increased.
     */
    function getLastGuardianFeeRateIncrease(address guardian, uint256 classID)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].lastGuardianFeeRateIncrease;
    }

    /**
     * @notice Returns guardian classes number.
     * @param guardian Address of guardian whose guardian classes are being queried.
     * @return count How many guardian classes the guardian has.
     */
    function guardianClassesCount(address guardian)
        external
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian].length;
    }

    /**
      * @notice Checks if delegator delegated collection handling to delegatee.
      * @param collection Delegator guardian address.
      * @param delegatee Delegatee address.
      * @param collection Collection address.
      * @return true if delegated, false otherwise.
      */
     function isDelegated(
         address delegator,
         address delegatee,
         IERC11554K collection
     ) external view virtual returns (bool) {
         return
             delegatedCollection[delegator][collection] == delegatee ||
             delegatedAll[delegator][delegatee];
     }

    /**
     * @notice Adds guardian to the whitelist.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param guardian Address of the new guardian.
     */
    function addGuardian(address guardian) public virtual onlyOwner {
        isWhitelisted[guardian] = true;
        guardianInfo[guardian].isActive = true;
        emit GuardianAdded(guardian);
    }

    /**
     * @notice Anyone can add Guardian fees to a guardian holding an item.
     * @param collection Address of the collection the item belongs to.
     * @param beneficiary The address of the holder of the item.
     * @param itemId Id of the item.
     * @param guardianFeeAmount The amount of guardian fee being paid.
     */
    function addStorageTime(
        IERC11554K collection,
        address beneficiary,
        uint256 itemId,
        uint256 guardianFeeAmount
    ) public virtual {
        uint256 currAmount = collection.balanceOf(beneficiary, itemId);

        address guardian = whereItemStored[collection][itemId];
        uint256 guardianClassIndex = itemGuardianClass[collection][itemId];

        uint256 guardianClassFeeRate = getGuardianFeeRate(
            guardian,
            guardianClassIndex
        );

        if (guardianClassFeeRate == 0) {
            revert("guardian class guardian fee rate is 0");
        }

        require(guardianFeeAmount > 0, "Guardian fee is 0");
        require(currAmount > 0, "Does not hold item");
        require(guardian != address(0), "Guardian not storing item");
        {
            uint256 addedStorageTime = GuardianTimeMath
                .calculateAddedGuardianTime(
                    guardianFeeAmount,
                    guardianClassFeeRate,
                    getGuardianFeeRatePeriod(guardian, guardianClassIndex),
                    currAmount
                );

            guardianFeePaidUntil[beneficiary][collection][
                itemId
            ] += addedStorageTime;
            globalItemGuardianFeePaidUntil[collection][
                itemId
            ] += addedStorageTime;
            emit StorageTimeAdded(itemId, guardian, addedStorageTime);
        }

        feesManager.payGuardianFee(
            guardianFeeAmount,
            (guardianClassFeeRate * currAmount) /
                getGuardianFeeRatePeriod(guardian, guardianClassIndex),
            guardian,
            guardianFeePaidUntil[beneficiary][collection][itemId],
            _msgSender(),
            controller.paymentToken()
        );
    }

    /**
     * @notice Returns guardian class guardian fee rate of the stored item in collection with  itemId.
     * @param collection Address of the collection where the item being queried belongs to.
     * @param itemId Item id of item whose guardian fee rate is being queried.
     * @return guardianFeeRate Fee rate of the item being queried (of guardian class it's in). Returns scaled by 10^18 real life value.
     */
    function getGuardianFeeRateByCollectionItem(
        IERC11554K collection,
        uint256 itemId
    ) public view virtual returns (uint256) {
        require(collection.totalSupply(itemId) > 0, "Item not yet minted");
        return
            guardiansClasses[whereItemStored[collection][itemId]][
                itemGuardianClass[collection][itemId]
            ].guardianFeeRate;
    }

    /**
     * @notice Returns guardian class guardian fee rate period size of the stored item in collection with  itemId.
     * @param collection Address of the collection where the item being queried belongs to.
     * @param itemId Item id of item whose guardian fee rate is being queried.
     * @return guardianFeeRatePeriod Size of the item being queried (of guardian class it's in).
     */
    function getGuardianFeeRatePeriodByCollectionItem(
        IERC11554K collection,
        uint256 itemId
    ) public view virtual returns (uint256) {
        require(collection.totalSupply(itemId) > 0, "Item not yet minted");
        return
            guardiansClasses[whereItemStored[collection][itemId]][
                itemGuardianClass[collection][itemId]
            ].guardianFeeRatePeriod;
    }

    /**
     * @notice Returns true if the guardian is active and whitelisted.
     * @param guardian Address of guardian whose guardian class is being queried.
     * @return boolean Is the guardian active and whitelisted.
     */
    function isAvailable(address guardian) public view returns (bool) {
        return isWhitelisted[guardian] && guardianInfo[guardian].isActive;
    }

    /**
     * @notice Returns guardian class classID guardian fee rate.
     * @param guardian Address of guardian whose guardian class is being queried.
     * @param classID Guardian's class index for class being queried.
     * @return guardianFeeRate The guardian class guardian fee rate. Returns scaled by 10^18 real life value.
     */
    function getGuardianFeeRate(address guardian, uint256 classID)
        public
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].guardianFeeRate;
    }

    /**
     * @notice Returns guardian class classID guardian fee rate period size.
     * @param guardian Address of guardian whose guardian class is being queried.
     * @param classID Guardian's class index for class being queried.
     * @return guardianFeeRatePeriod The unit of time for the guardian fee rate.
     */
    function getGuardianFeeRatePeriod(address guardian, uint256 classID)
        public
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].guardianFeeRatePeriod;
    }

    /**
     * @notice Returns guardian class classID guardian fee rate historic minimum.
     * @param guardian Address of guardian whose guardian class is being queried
     * @param classID Guardian's class index for class being queried.
     * @return guardianfeeRateMinumum The guardian class guardian fee rate historical minimum
     */
    function getGuardianFeeRateMinimum(address guardian, uint256 classID)
        public
        view
        virtual
        returns (uint256)
    {
        return guardiansClasses[guardian][classID].guardianFeeRateMinimum;
    }

    /**
     * @notice Returns guardian class classID activity true/false.
     * @param guardian Address of guardian whose guardian class is being queried.
     * @param classID Guardian's class index for class being queried.
     * @return activeStatus Boolean - is the class active or not.
     */
    function isClassActive(address guardian, uint256 classID)
        public
        view
        virtual
        returns (bool)
    {
        return guardiansClasses[guardian][classID].isActive;
    }

    /**
     * @dev Internal call, adds guardian class.
     */
    function _addGuardianClass(
        address guardian,
        uint256 maximumCoverage,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 guardianFeeRate,
        GuardianFeeRatePeriods guardianFeeRatePeriod,
        string calldata uri
    ) internal virtual returns (uint256 classID) {
        classID = guardiansClasses[guardian].length;

        uint256 periodMultiple;
        if (guardianFeeRatePeriod == GuardianFeeRatePeriods.SECONDS) {
            periodMultiple = SECOND;
        } else if (guardianFeeRatePeriod == GuardianFeeRatePeriods.MINUTES) {
            periodMultiple = MINUTE;
        } else if (guardianFeeRatePeriod == GuardianFeeRatePeriods.HOURS) {
            periodMultiple = HOUR;
        } else if (guardianFeeRatePeriod == GuardianFeeRatePeriods.DAYS) {
            periodMultiple = DAY;
        }

        guardiansClasses[guardian].push(
            GuardianClass(
                maximumCoverage,
                mintingFee,
                redemptionFee,
                periodMultiple,
                guardianFeeRate,
                guardianFeeRate,
                block.timestamp,
                true,
                uri
            )
        );
        emit GuardianClassAdded(guardian, classID);
    }

    /**
     * @dev Internal call, copies an ENTIRE guardian class from one guardian to another. Note: same data but DIFFERENT index.
     */
    function _copyGuardianClass(
        address oldGuardian,
        address newGuardian,
        uint256 oldGuardianClassIndex
    ) internal returns (uint256 classID) {
        classID = guardiansClasses[newGuardian].length;
        guardiansClasses[newGuardian].push(
            GuardianClass(
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .maximumCoverage,
                guardiansClasses[oldGuardian][oldGuardianClassIndex].mintingFee,
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .redemptionFee,
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .guardianFeeRatePeriod,
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .guardianFeeRate,
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .guardianFeeRateMinimum,
                guardiansClasses[oldGuardian][oldGuardianClassIndex]
                    .lastGuardianFeeRateIncrease,
                guardiansClasses[oldGuardian][oldGuardianClassIndex].isActive,
                guardiansClasses[oldGuardian][oldGuardianClassIndex].uri
            )
        );
        emit GuardianClassAdded(newGuardian, classID);
    }

    /**
     * @dev Internal call, sets a new guardian class guardian fee rate, with several checks. Compensates for a different period multiple
     */
    function _setGuardianClassGuardianFeeRate(
        address guardian,
        uint256 classID,
        uint256 guardianFeeRate,
        uint256 newPeriodMultiple
    ) internal virtual {
        require(guardianFeeRate > 0, "guardian class guardian fee rate is 0");
        require(
            guardiansClasses[guardian][classID].guardianFeeRate > 0,
            "Cannot increase guardian fee rate on free classes"
        );
        uint256 currentPeriodMultiple = guardiansClasses[guardian][classID]
            .guardianFeeRatePeriod;
        if (
            (guardianFeeRate / newPeriodMultiple) >
            (guardiansClasses[guardian][classID].guardianFeeRate /
                currentPeriodMultiple)
        ) {
            require(
                block.timestamp >=
                    guardiansClasses[guardian][classID]
                        .lastGuardianFeeRateIncrease +
                        guardianFeeSetWindow,
                "Guardian fee window hasn't passed"
            );

            require(
                (guardianFeeRate / newPeriodMultiple) <=
                    (guardiansClasses[guardian][classID].guardianFeeRate *
                        maximumGuardianFeeSet) /
                        (currentPeriodMultiple * PERCENTAGE_FACTOR),
                "Exceeds increase limit"
            );

            guardiansClasses[guardian][classID]
                .lastGuardianFeeRateIncrease = block.timestamp;
        }
        guardiansClasses[guardian][classID].guardianFeeRate = guardianFeeRate;
        if (
            (guardianFeeRate / newPeriodMultiple) <
            (guardiansClasses[guardian][classID].guardianFeeRateMinimum /
                currentPeriodMultiple)
        ) {
            guardiansClasses[guardian][classID]
                .guardianFeeRateMinimum = guardianFeeRate;
        }
    }

    /**
     * @dev Internal call that is done on each item token redeem to
     * relaculate paid storage time, guardian fees.
     */
    function _shiftGuardianFeesOnTokenRedeem(
        address from,
        IERC11554K collection,
        uint256 id,
        uint256 redeemAmount,
        uint256 guardianClassFeeRate,
        uint256 guardianFeeRatePeriod
    ) internal virtual returns (uint256) {
        uint256 originalTimeRemaining = guardianFeePaidUntil[from][collection][
            id
        ];

        // Recalculate the remaining time with new params
        uint256 bal = IERC11554K(collection).balanceOf(from, id);

        // Total fee that remains
        uint256 remainingFeeAmount = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[from][collection][id],
                guardianClassFeeRate,
                guardianFeeRatePeriod,
                bal
            );

        // Portion of fee we're giving back, for refund.
        uint256 guardianFeeRefundAmount = GuardianTimeMath
            .calculateRemainingFeeAmount(
                guardianFeePaidUntil[from][collection][id],
                guardianClassFeeRate,
                guardianFeeRatePeriod,
                redeemAmount
            );

        if (bal - redeemAmount == 0) {
            guardianFeePaidUntil[from][collection][id] = 0; //back to default,0
        } else {
            uint256 recalculatedTime = GuardianTimeMath
                .calculateAddedGuardianTime(
                    remainingFeeAmount - guardianFeeRefundAmount,
                    guardianClassFeeRate,
                    guardianFeeRatePeriod,
                    bal - redeemAmount
                );
            guardianFeePaidUntil[from][collection][id] =
                block.timestamp +
                recalculatedTime;
        }

        if (IERC11554K(collection).totalSupply(id) - redeemAmount == 0) {
            globalItemGuardianFeePaidUntil[collection][id] = 0;
        } else {
            uint256 timeDelta;
            if (
                originalTimeRemaining >
                guardianFeePaidUntil[from][collection][id]
            ) {
                timeDelta = (originalTimeRemaining -
                    guardianFeePaidUntil[from][collection][id]);
            } else {
                timeDelta = (guardianFeePaidUntil[from][collection][id] -
                    originalTimeRemaining);
            }
            globalItemGuardianFeePaidUntil[collection][id] -= timeDelta;
        }

        return guardianFeeRefundAmount;
    }

    function _moveSingleItem(
        IERC11554K collection,
        uint256 itemId,
        address oldGuardian,
        address newGuardian,
        uint256 newGuardianClassIndex
    ) internal virtual {
        uint256 amount = stored[oldGuardian][collection][itemId];
        stored[oldGuardian][collection][itemId] = 0;
        stored[newGuardian][collection][itemId] += amount;
        whereItemStored[collection][itemId] = newGuardian;
        itemGuardianClass[collection][itemId] = newGuardianClassIndex;

        emit ItemMoved(
            oldGuardian,
            newGuardian,
            newGuardianClassIndex,
            itemId,
            collection
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev {IERC11554K} interface:
 */
interface IERC11554K {
    function controllerMint(
        address mintAddress,
        uint256 tokenId,
        uint256 amount
    ) external;

    function controllerBurn(
        address burnAddress,
        uint256 tokenId,
        uint256 amount
    ) external;

    function owner() external view returns (address);

    function balanceOf(address user, uint256 item)
        external
        view
        returns (uint256);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256);

    function totalSupply(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IERC11554K.sol";

/**
 * @dev {IERC11554KController} interface:
 */
interface IERC11554KController {
        /// @dev Batch minting request data structure.
    struct BatchRequestMintData {
        /// @dev Collection address.
        IERC11554K collection;
        /// @dev Item id.
        uint256 id;
        /// @dev Guardian address.
        address guardianAddress;
        /// @dev Amount to mint.
        uint256 amount;
        /// @dev Service fee to guardian.
        uint256 serviceFee;
        /// @dev Is item supply expandable.
        bool isExpandable;
        /// @dev Recipient address.
        address mintAddress;
        /// @dev Guardian class index.
        uint256 guardianClassIndex;
        /// @dev Guardian fee amount to pay.
        uint256 guardianFeeAmount;
    }

    function requestMint(
        IERC11554K collection,
        uint256 id,
        address guardian,
        uint256 amount,
        uint256 serviceFee,
        bool expandable,
        address mintAddress,
        uint256 guardianClassIndex,
        uint256 guardianFeeAmount
    ) external returns (uint256);

    function mint(IERC11554K collection, uint256 id) external;

    function owner() external returns (address);

    function originators(address collection, uint256 tokenId)
        external
        returns (address);

    function isActiveCollection(address collection) external returns (bool);

    function isLinkedCollection(address collection) external returns (bool);

    function paymentToken() external returns (IERC20Upgradeable);

    function maxMintPeriod() external returns (uint256);

    function guardians() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IERC11554K.sol";

/**
 * @dev {IFeesManager} interface:
 */
interface IFeesManager {
    function receiveFees(
        IERC11554K erc11554k,
        uint256 id,
        IERC20Upgradeable asset,
        uint256 _salePrice
    ) external;

    function calculateTotalFee(
        IERC11554K erc11554k,
        uint256 id,
        uint256 _salePrice
    ) external returns (uint256);

    function payGuardianFee(
        uint256 guardianFeeAmount,
        uint256 guardianClassFeeRateMultiplied,
        address guardian,
        uint256 storagePaidUntil,
        address payer,
        IERC20Upgradeable paymentAsset
    ) external;

    function refundGuardianFee(
        uint256 guardianFeeAmount,
        uint256 guardianClassFeeRateMultiplied,
        address guardian,
        uint256 storagePaidUntil,
        address recipient,
        IERC20Upgradeable paymentAsset
    ) external;

    function moveFeesBetweenGuardians(
        address guardianFrom,
        address guardianTo,
        IERC20Upgradeable asset
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev GuardianTimeMath library. Provides support for converting between guardian fees and purchased storage time
 */
library GuardianTimeMath {
    /**
     * @dev Calculates the fee amount associated with the items
     * scaledByNumItems based on currGuardianFeePaidUntil guardianClassFeeRate
     * (scaled by the number being moved, for semi-fungibles).
     * @param currGuardianFeePaidUntil a timestamp that describes until when storage has been paid.
     * @param guardianClassFeeRate a guardian's guardian fee rate. Amount per second.
     * @param scaledByNumItems the number of items that are being stored by a guardian at the time of the query.
     * @return the remaining amount of guardian fee that is left within the `currGuardianFeePaidUntil` at the `guardianClassFeeRate` rate for `scaledByNumItems` items
     */
    function calculateRemainingFeeAmount(
        uint256 currGuardianFeePaidUntil,
        uint256 guardianClassFeeRate,
        uint256 guardianFeeRatePeriod,
        uint256 scaledByNumItems
    ) internal view returns (uint256) {
        if (currGuardianFeePaidUntil <= block.timestamp) {
            return 0;
        } else {
            return ((((currGuardianFeePaidUntil - block.timestamp) *
                guardianClassFeeRate) * scaledByNumItems) /
                guardianFeeRatePeriod);
        }
    }

    /**
     * @dev Calculates added guardian storage time based on
     * guardianFeePaid guardianClassFeeRate and numItems
     * (scaled by the number being moved, for semi-fungibles).
     * @param guardianFeePaid the amount of guardian fee that is being paid.
     * @param guardianClassFeeRate a guardian's guardian fee rate. Amount per time period.
     * @param guardianFeeRatePeriod the size of the period used in the guardian fee rate.
     * @param numItems the number of items that are being stored by a guardian at the time of the query.
     * @return the amount of guardian time that can be purchased from `guardianFeePaid` fee amount at the `guardianClassFeeRate` rate for `numItems` items
     */
    function calculateAddedGuardianTime(
        uint256 guardianFeePaid,
        uint256 guardianClassFeeRate,
        uint256 guardianFeeRatePeriod,
        uint256 numItems
    ) internal pure returns (uint256) {
        return
            (guardianFeePaid * guardianFeeRatePeriod) /
            (guardianClassFeeRate * numItems);
    }

    /**
     * @dev Function that allows us to transform an amount from the internal, 18 decimal format, to one that has another decimal precision.
     * @param internalAmount the amount in 18 decimal represenation.
     * @param toDecimals the amount of decimal precision we want the amount to have
     */
    function transformDecimalPrecision(
        uint256 internalAmount,
        uint256 toDecimals
    ) internal pure returns (uint256) {
        return (internalAmount / (10**(18 - toDecimals)));
    }
}