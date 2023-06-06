// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "contracts/BaseWaterfall.sol";
import "contracts/Waterfall.sol";
import "contracts/WaterfallUsd.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Throw when Fee Percentage is more than 100%
error InvalidFeePercentage();

// Throw when creationId was already created
error CreationIdAlreadyProcessed();

contract WaterfallFactory is Ownable {
    uint256 public constant BASIS_POINT = 10000000;

    address payable public immutable contractImplementation;
    address payable public immutable contractImplementationUsd;

    uint256 public constant VERSION = 1;
    uint256 public platformFee;
    address payable public platformWallet;

    // creationId unique ID for each contract creation TX, it prevents users to submit tx twice
    mapping(bytes32 => bool) public processedCreationIds;

    struct WaterfallCreateData {
        address controller;
        address[] distributors;
        bool immutableController;
        bool autoNativeTokenDistribution;
        uint256 minAutoDistributeAmount;
        address payable[] initialRecipients;
        uint256[] maxCaps;
        uint256[] priorities;
        address[] supportedErc20addresses;
        address[] erc20PriceFeeds;
        bytes32 creationId;
    }

    struct WaterfallCreateUsdData {
        address controller;
        address[] distributors;
        bool immutableController;
        bool autoNativeTokenDistribution;
        address nativeTokenUsdPriceFeed;
        uint256 minAutoDistributeAmount;
        address payable[] initialRecipients;
        uint256[] maxCaps;
        uint256[] priorities;
        address[] supportedErc20addresses;
        address[] erc20PriceFeeds;
        bytes32 creationId;
    }

    event WaterfallCreated(
        address contractAddress,
        address controller,
        address[] distributors,
        uint256 version,
        bool immutableController,
        bool autoNativeTokenDistribution,
        uint256 minAutoDistributeAmount,
        bytes32 creationId
    );

    event WaterfallUsdCreated(
        address contractAddress,
        address controller,
        address[] distributors,
        uint256 version,
        bool immutableController,
        bool autoNativeTokenDistribution,
        uint256 minAutoDistributeAmount,
        address nativeTokenUsdPriceFeed,
        bytes32 creationId
    );

    event PlatformFeeChanged(uint256 oldFee, uint256 newFee);

    event PlatformWalletChanged(
        address payable oldPlatformWallet,
        address payable newPlatformWallet
    );

    constructor() {
        contractImplementation = payable(new Waterfall());
        contractImplementationUsd = payable(new WaterfallUsd());
    }

    /**
     * @dev Public function for creating clone proxy pointing to Waterfall Waterfall
     * @param _data Initial data for creating new Waterfall Waterfall native token contract
     * @return Address of new contract
     */
    function createWaterfall(WaterfallCreateData memory _data) external returns (address) {
        // check and register creationId
        bytes32 creationId = _data.creationId;
        if (creationId != bytes32(0)) {
            bool processed = processedCreationIds[creationId];
            if (processed) {
                revert CreationIdAlreadyProcessed();
            } else {
                processedCreationIds[creationId] = true;
            }
        }

        address payable clone = payable(Clones.clone(contractImplementation));

        BaseWaterfall.InitContractSetting memory contractSettings = BaseWaterfall
            .InitContractSetting(
                msg.sender,
                _data.distributors,
                _data.controller,
                _data.immutableController,
                _data.autoNativeTokenDistribution,
                _data.minAutoDistributeAmount,
                platformFee,
                _data.supportedErc20addresses,
                _data.erc20PriceFeeds
            );

        Waterfall(clone).initialize(
            contractSettings,
            _data.initialRecipients,
            _data.maxCaps,
            _data.priorities
        );

        emit WaterfallCreated(
            clone,
            _data.controller,
            _data.distributors,
            VERSION,
            _data.immutableController,
            _data.autoNativeTokenDistribution,
            _data.minAutoDistributeAmount,
            creationId
        );

        return clone;
    }

    /**
     * @dev Public function for creating clone proxy pointing to Waterfall Waterfall USD
     * @param _data Initial data for creating new Waterfall Waterfall USD contract
     * @return Address of new contract
     */
    function createWaterfallUsd(
        WaterfallCreateUsdData memory _data
    ) external returns (address) {
        // check and register creationId
        bytes32 creationId = _data.creationId;
        if (creationId != bytes32(0)) {
            bool processed = processedCreationIds[creationId];
            if (processed) {
                revert CreationIdAlreadyProcessed();
            } else {
                processedCreationIds[creationId] = true;
            }
        }

        address payable clone = payable(Clones.clone(contractImplementationUsd));

        BaseWaterfall.InitContractSetting memory contractSettings = BaseWaterfall
            .InitContractSetting(
                msg.sender,
                _data.distributors,
                _data.controller,
                _data.immutableController,
                _data.autoNativeTokenDistribution,
                _data.minAutoDistributeAmount,
                platformFee,
                _data.supportedErc20addresses,
                _data.erc20PriceFeeds
            );

        WaterfallUsd(clone).initialize(
            contractSettings,
            _data.initialRecipients,
            _data.maxCaps,
            _data.priorities,
            _data.nativeTokenUsdPriceFeed
        );

        emit WaterfallUsdCreated(
            clone,
            _data.controller,
            _data.distributors,
            VERSION,
            _data.immutableController,
            _data.autoNativeTokenDistribution,
            _data.minAutoDistributeAmount,
            _data.nativeTokenUsdPriceFeed,
            creationId
        );

        return clone;
    }

    /**
     * @dev Only Owner function for setting platform fee
     * @param _fee Percentage define platform fee 100% == BASIS_POINT
     */
    function setPlatformFee(uint256 _fee) external onlyOwner {
        if (_fee > BASIS_POINT) {
            revert InvalidFeePercentage();
        }
        emit PlatformFeeChanged(platformFee, _fee);
        platformFee = _fee;
    }

    /**
     * @dev Only Owner function for setting platform fee
     * @param _platformWallet New native token wallet which will receive fees
     */
    function setPlatformWallet(address payable _platformWallet) external onlyOwner {
        emit PlatformWalletChanged(platformWallet, _platformWallet);
        platformWallet = _platformWallet;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IFeeFactory.sol";
import "./interfaces/IRecursiveWaterfall.sol";

// Throw when if sender is not distributor
error OnlyDistributorError();

// Throw when sender is not controller
error OnlyControllerError();

// Throw when transaction fails
error TransferFailedError();

// Throw when submitted recipient with address(0)
error NullAddressRecipientError();

// Throw if recipient which is being added is current recipient
error RecipientIsCurrentRecipientError();

// Throw when arrays are submit without same length
error InconsistentDataLengthError();

// Throw when distributor address is same as submit one
error ControllerAlreadyConfiguredError();

// Throw when change is triggered for immutable controller
error ImmutableControllerError();

// Throw if recipient is already in the recipients pool
error RecipientAlreadyAddedError();

abstract contract BaseWaterfall is OwnableUpgradeable {
    uint256 public constant BASIS_POINT = 10000000;

    mapping(address => bool) public distributors;
    address public controller;
    bool public immutableController;
    bool public autoNativeTokenDistribution;
    uint256 public minAutoDistributionAmount;
    uint256 public platformFee;
    IFeeFactory public factory;

    address payable public currentRecipient;

    struct RecipientData {
        uint256 received; // Either USD for WaterfallUsd or native token for Waterfall
        uint256 maxCap;
        uint256 priority;
    }

    mapping(address => RecipientData) public recipientsData;
    address payable[] public recipients;

    struct InitContractSetting {
        address owner;
        address[] _distributors;
        address controller;
        bool immutableController;
        bool autoNativeTokenDistribution;
        uint256 minAutoDistributionAmount;
        uint256 platformFee;
        address[] supportedErc20addresses;
        address[] erc20PriceFeeds;
    }

    event SetRecipients(
        address payable[] recipients,
        uint256[] maxCaps,
        uint256[] priorities
    );
    event DistributeToken(address token, uint256 amount);
    event DistributorChanged(address distributor, bool isDistributor);
    event ControllerChanged(address oldController, address newController);
    event CurrentRecipientChanged(address oldRecipient, address newRecipient);

    /**
     * @dev Throws if sender is not distributor
     */
    modifier onlyDistributor() {
        if (distributors[msg.sender] == false) {
            revert OnlyDistributorError();
        }
        _;
    }

    /**
     * @dev Checks whether sender is controller
     */
    modifier onlyController() {
        if (msg.sender != controller) {
            revert OnlyControllerError();
        }
        _;
    }

    receive() external payable {
        // Check whether automatic native token distribution is enabled
        // and that contractBalance + msg.value is more than automatic distribution trash hold
        uint256 contractBalance = address(this).balance;
        if (autoNativeTokenDistribution && contractBalance >= minAutoDistributionAmount) {
            _redistributeNativeToken(contractBalance, false);
        }
    }

    /**
     * @notice Internal function to redistribute native token based on waterfall rules
     * @param _valueToDistribute native token amount to be distribute
     * @param _recursive When recursive is True we don't charge additional fee
     */
    function _redistributeNativeToken(
        uint256 _valueToDistribute,
        bool _recursive
    ) internal virtual {}

    /**
     * @notice External function to redistribute native token based on waterfall rules
     */
    function redistributeNativeToken() external onlyDistributor {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            // Nothing to distribute
            return;
        }
        _redistributeNativeToken(balance, false);
    }

    /**
     * @notice External function to return number of recipients
     */
    function numberOfRecipients() external view returns (uint256) {
        return recipients.length;
    }

    /**
     * @notice Internal function to redistribute ERC20 token based on waterfall rules
     * @param _token address of token to be distributed
     * @param _recursive When recursive is True we don't charge additional fee
     */
    function _redistributeToken(address _token, bool _recursive) internal virtual {}

    /**
     * @notice External function to redistribute ERC20 token based on waterfall rules
     * @param _token address of token to be distributed
     */
    function redistributeToken(address _token) external onlyDistributor {
        _redistributeToken(_token, false);
    }

    /**
     * @notice Internal function to set current recipient
     * Set currentRecipient to one of the addresses from recipients based on highest priority.
     */
    function _setCurrentRecipient() internal {
        uint256 highestPriority;
        address highestPriorityAddress;

        uint256 recipientsLength = recipients.length;

        // Search for highest priority address
        for (uint256 i = 0; i < recipientsLength; ) {
            address recipient = recipients[i];
            RecipientData memory recipientData = recipientsData[recipient];

            if (recipientData.priority > highestPriority || highestPriority == 0) {
                highestPriority = recipientData.priority;
                highestPriorityAddress = recipient;
            }
            unchecked {
                i++;
            }
        }

        // Remove highestPriorityAddress from the recipients list
        for (uint256 i = 0; i < recipientsLength; ) {
            if (recipients[i] == highestPriorityAddress) {
                recipients[i] = recipients[recipientsLength - 1];
                recipients.pop();
                break;
            }
            unchecked {
                i++;
            }
        }

        // remove currentRecipient data
        delete recipientsData[currentRecipient];
        emit CurrentRecipientChanged(currentRecipient, highestPriorityAddress);
        currentRecipient = payable(highestPriorityAddress);
    }

    /**
     * @notice Internal function enable adding new recipient.
     * @param _recipient New recipient address to be added
     * @param _maxCap max cap of new recipient provided in USD
     * @param _priority Priority of the recipient
     */
    function _addRecipient(
        address payable _recipient,
        uint256 _maxCap,
        uint256 _priority
    ) internal {
        if (_recipient == address(0)) {
            revert NullAddressRecipientError();
        } else if (_recipient == currentRecipient) {
            revert RecipientIsCurrentRecipientError();
        } else if (recipientsData[_recipient].maxCap > 0) {
            revert RecipientAlreadyAddedError();
        }

        recipients.push(_recipient);
        recipientsData[_recipient] = RecipientData(0, _maxCap, _priority);
    }

    /**
     * @notice Internal function for setting recipients
     * @param _newRecipients Recipient addresses to be added
     * @param _maxCaps List of maxCaps for recipients
     * @param _priorities List of recipients priorities
     */
    function _setRecipients(
        address payable[] memory _newRecipients,
        uint256[] memory _maxCaps,
        uint256[] memory _priorities
    ) internal {
        uint256 newRecipientsLength = _newRecipients.length;

        if (
            newRecipientsLength != _maxCaps.length ||
            newRecipientsLength != _priorities.length
        ) {
            revert InconsistentDataLengthError();
        }

        _removeAll();

        for (uint256 i = 0; i < newRecipientsLength; ) {
            _addRecipient(_newRecipients[i], _maxCaps[i], _priorities[i]);
            unchecked {
                i++;
            }
        }

        // If there is not any currentRecipient choose one
        if (currentRecipient == address(0)) {
            _setCurrentRecipient();
        }

        emit SetRecipients(_newRecipients, _maxCaps, _priorities);
    }

    /**
     * @notice External function for setting recipients
     * @param _newRecipients Addresses to be added
     * @param _maxCaps Maximum amount recipient will receive
     * @param _priorities Priority when recipient is going to be current recipient
     */
    function setRecipients(
        address payable[] memory _newRecipients,
        uint256[] memory _maxCaps,
        uint256[] memory _priorities
    ) public onlyController {
        _setRecipients(_newRecipients, _maxCaps, _priorities);
    }

    /**
     * @notice function for removing all recipients
     */
    function _removeAll() internal {
        uint256 recipientsLength = recipients.length;

        if (recipientsLength == 0) {
            return;
        }

        for (uint256 i = 0; i < recipientsLength; ) {
            address recipient = recipients[i];
            delete recipientsData[recipient];
            unchecked {
                i++;
            }
        }
        delete recipients;
    }

    /**
     * @notice External function to set distributor address
     * @param _distributor address of new distributor
     * @param _isDistributor bool indicating whether address is / isn't distributor
     */
    function setDistributor(
        address _distributor,
        bool _isDistributor
    ) external onlyOwner {
        emit DistributorChanged(_distributor, _isDistributor);
        distributors[_distributor] = _isDistributor;
    }

    /**
     * @notice External function to set controller address, if set to address(0), unable to change it
     * @param _controller address of new controller
     */
    function setController(address _controller) external onlyOwner {
        if (controller == address(0) || immutableController) {
            revert ImmutableControllerError();
        }
        if (_controller == controller) {
            revert ControllerAlreadyConfiguredError();
        }
        emit ControllerChanged(controller, _controller);
        controller = _controller;
    }

    /**
     * @notice Internal function to check whether recipient should be recursively distributed
     * @param _recipient Address of recipient to recursively distribute
     * @param _token token to be distributed
     */
    function _recursiveERC20Distribution(address _recipient, address _token) internal {
        // Handle Recursive token distribution
        IRecursiveWaterfall recursiveRecipient = IRecursiveWaterfall(_recipient);

        // Wallets have size 0 and contracts > 0. This way we can distinguish them.
        uint256 recipientSize;
        assembly {
            recipientSize := extcodesize(_recipient)
        }
        if (recipientSize > 0) {
            // Validate this contract is distributor in child recipient
            try recursiveRecipient.distributors(address(this)) returns (
                bool isBranchDistributor
            ) {
                if (isBranchDistributor) {
                    recursiveRecipient.redistributeToken(_token);
                }
            } catch {
                return;
            } // unable to recursively distribute
        }
    }

    /**
     * @notice Internal function to check whether recipient should be recursively distributed
     * @param _recipient Address of recipient to recursively distribute
     */
    function _recursiveNativeTokenDistribution(address _recipient) internal {
        // Handle Recursive token distribution
        IRecursiveWaterfall recursiveRecipient = IRecursiveWaterfall(_recipient);

        // Wallets have size 0 and contracts > 0. This way we can distinguish them.
        uint256 recipientSize;
        assembly {
            recipientSize := extcodesize(_recipient)
        }
        if (recipientSize > 0) {
            // Check whether child recipient have autoNativeTokenDistribution set to true,
            // if yes tokens will be recursively distributed automatically
            try recursiveRecipient.autoNativeTokenDistribution() returns (
                bool childAutoNativeTokenDistribution
            ) {
                if (childAutoNativeTokenDistribution == true) {
                    return;
                }
            } catch {
                return;
            }

            // Validate this contract is distributor in child recipient
            try recursiveRecipient.distributors(address(this)) returns (
                bool isBranchDistributor
            ) {
                if (isBranchDistributor) {
                    recursiveRecipient.redistributeNativeToken();
                }
            } catch {
                return;
            } // unable to recursively distribute
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IFeeFactory {
    function platformWallet() external returns (address payable);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IRecursiveWaterfall {
    function distributors(address _distributor) external returns (bool);

    function redistributeToken(address _token) external;

    function redistributeNativeToken() external;

    function autoNativeTokenDistribution() external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BaseWaterfall.sol";

// Throws when trying to fetch native token price for token without oracle
error TokenMissingNativeTokenPriceOracle();

contract Waterfall is BaseWaterfall {
    using SafeERC20 for IERC20;

    mapping(address => address) tokenNativeTokenPriceFeeds;
    event TokenPriceFeedSet(address token, address priceFeed);

    /**
     * @dev Constructor function, can be called only once
     * @param _settings Contract settings, check InitContractSetting struct
     * @param _initialRecipients Addresses to be added as a initial recipients
     * @param _maxCaps Maximum amount recipient will receive
     * @param _priorities Priority when recipient is going to be current recipient
     */
    function initialize(
        InitContractSetting memory _settings,
        address payable[] memory _initialRecipients,
        uint256[] memory _maxCaps,
        uint256[] memory _priorities
    ) public initializer {
        // Contract settings
        controller = _settings.controller;

        uint256 distributorsLength = _settings._distributors.length;
        for (uint256 i = 0; i < distributorsLength; ) {
            distributors[_settings._distributors[i]] = true;
            unchecked {
                i++;
            }
        }

        immutableController = _settings.immutableController;
        autoNativeTokenDistribution = _settings.autoNativeTokenDistribution;
        minAutoDistributionAmount = _settings.minAutoDistributionAmount;
        factory = IFeeFactory(msg.sender);
        platformFee = _settings.platformFee;
        _transferOwnership(_settings.owner);
        uint256 supportedErc20Length = _settings.supportedErc20addresses.length;
        if (supportedErc20Length != _settings.erc20PriceFeeds.length) {
            revert InconsistentDataLengthError();
        }
        for (uint256 i = 0; i < supportedErc20Length; ) {
            _setTokenNativeTokenPriceFeed(
                _settings.supportedErc20addresses[i],
                _settings.erc20PriceFeeds[i]
            );
            unchecked {
                i++;
            }
        }

        // Recipients settings
        _setRecipients(_initialRecipients, _maxCaps, _priorities);
    }

    /**
     * @notice Internal function to redistribute native token
     * @param _valueToDistribute amount in native token to be distributed
     * @param _recursive When recursive is True we don't charge additional fee
     */
    function _redistributeNativeToken(
        uint256 _valueToDistribute,
        bool _recursive
    ) internal override {
        if (currentRecipient == address(0)) {
            // When there is not currentRecipient _valueToDistribute stays in the Waterfall contract
            return;
        }

        // if any, subtract platform Fee and send it to platformWallet
        if (platformFee > 0 && !_recursive) {
            uint256 fee = (_valueToDistribute / BASIS_POINT) * platformFee;
            _valueToDistribute -= fee;
            address payable platformWallet = factory.platformWallet();
            (bool feeSuccess, ) = platformWallet.call{ value: fee }("");
            if (feeSuccess == false) {
                revert TransferFailedError();
            }
        }

        RecipientData storage recipientData = recipientsData[currentRecipient];
        uint256 remainCap = recipientData.maxCap - recipientData.received;
        uint256 currentBalance = address(this).balance;
        uint256 nativeTokenValueToSent = _valueToDistribute +
            (currentBalance - _valueToDistribute);

        // Check if current recipient was fulfilled
        bool setNewCurrentRecipient = false;
        if (nativeTokenValueToSent >= remainCap) {
            nativeTokenValueToSent = remainCap;
            setNewCurrentRecipient = true;
        }

        // Send native token to current currentRecipient
        recipientData.received += nativeTokenValueToSent;
        (bool success, ) = payable(currentRecipient).call{
            value: nativeTokenValueToSent
        }("");
        if (success == false) {
            revert TransferFailedError();
        }
        _recursiveNativeTokenDistribution(currentRecipient);

        // Set new current recipient if currentRecipient was fulfilled
        if (setNewCurrentRecipient) {
            _setCurrentRecipient();
            uint256 remainingBalance = address(this).balance;
            if (remainingBalance > 0) {
                _redistributeNativeToken(remainingBalance, true);
            }
        }
    }

    /**
     * @notice Internal function to redistribute ERC20 token based waterfall rules
     * @param _token address of token to be distributed
     * @param _recursive When recursive is True we don't charge additional fee
     */
    function _redistributeToken(address _token, bool _recursive) internal override {
        if (currentRecipient == address(0)) {
            // When there is not currentRecipient we cannot distribute token
            return;
        }

        RecipientData storage recipientData = recipientsData[currentRecipient];
        IERC20 erc20Token = IERC20(_token);

        uint256 tokenValueToSent = erc20Token.balanceOf(address(this));
        if (tokenValueToSent == 0) {
            // Nothing to distribute
            return;
        }

        // if any subtract platform Fee and send it to platformWallet
        if (platformFee > 0 && !_recursive) {
            uint256 fee = (tokenValueToSent / BASIS_POINT) * platformFee;
            tokenValueToSent -= fee;
            address payable platformWallet = factory.platformWallet();
            erc20Token.safeTransfer(platformWallet, fee);
        }

        uint256 remainCap = recipientData.maxCap - recipientData.received;
        uint256 nativeTokenValueToSent = _convertTokenToNativeToken(
            _token,
            tokenValueToSent
        );

        // Check if current recipient was fulfilled
        bool setNewCurrentRecipient = false;
        if (nativeTokenValueToSent >= remainCap) {
            nativeTokenValueToSent = remainCap;
            tokenValueToSent = _convertNativeTokenToToken(_token, nativeTokenValueToSent);
            setNewCurrentRecipient = true;
        }
        recipientData.received += nativeTokenValueToSent;
        erc20Token.safeTransfer(currentRecipient, tokenValueToSent);
        _recursiveERC20Distribution(currentRecipient, _token);

        // Set new current recipient if currentRecipient was fulfilled
        if (setNewCurrentRecipient) {
            _setCurrentRecipient();
            uint256 contractBalance = erc20Token.balanceOf(address(this));
            if (contractBalance > 0) {
                _redistributeToken(_token, true);
            }
        }

        emit DistributeToken(_token, tokenValueToSent);
    }

    /**
     * @notice internal function that returns erc20/native token price from external oracle
     * @param _token Address of the token
     */
    function _getTokenNativeTokenPrice(address _token) private view returns (uint256) {
        address tokenOracleAddress = tokenNativeTokenPriceFeeds[_token];
        if (tokenOracleAddress == address(0)) {
            revert TokenMissingNativeTokenPriceOracle();
        }
        AggregatorV3Interface tokenNativeTokenPriceFeed = AggregatorV3Interface(
            tokenOracleAddress
        );
        (, int256 price, , , ) = tokenNativeTokenPriceFeed.latestRoundData();
        return uint256(price);
    }

    /**
     * @notice Internal function to convert token value to native token value
     * @param _token token address
     * @param _tokenValue Token value to be converted to USD
     */
    function _convertTokenToNativeToken(
        address _token,
        uint256 _tokenValue
    ) internal view returns (uint256) {
        return (_getTokenNativeTokenPrice(_token) * _tokenValue) / 1e18;
    }

    /**
     * @notice Internal function to convert native token value to token value
     * @param _token token address
     * @param _nativeTokenValue native token value to be converted
     */
    function _convertNativeTokenToToken(
        address _token,
        uint256 _nativeTokenValue
    ) internal view returns (uint256) {
        return
            (((_nativeTokenValue * 1e25) / _getTokenNativeTokenPrice(_token)) * 1e25) /
            1e32;
    }

    /**
     * @notice External function for setting price feed oracle for token
     * @param _token address of token
     * @param _priceFeed address of Native token price feed for given token
     */
    function setTokenNativeTokenPriceFeed(
        address _token,
        address _priceFeed
    ) external onlyOwner {
        _setTokenNativeTokenPriceFeed(_token, _priceFeed);
    }

    /**
     * @notice internal function for setting price feed oracle for token
     * @param _token address of token
     * @param _priceFeed address of native token price feed for given token
     */
    function _setTokenNativeTokenPriceFeed(address _token, address _priceFeed) internal {
        tokenNativeTokenPriceFeeds[_token] = _priceFeed;
        emit TokenPriceFeedSet(_token, _priceFeed);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BaseWaterfall.sol";

// Throws when trying to fetch USD price for token without oracle
error TokenMissingUsdPriceOracle();

contract WaterfallUsd is BaseWaterfall {
    using SafeERC20 for IERC20;

    AggregatorV3Interface internal nativeTokenUsdPriceFeed;
    mapping(address => address) tokenUsdPriceFeeds;

    event TokenPriceFeedSet(address token, address priceFeed);
    event NativeTokenPriceFeedSet(
        address oldNativeTokenPriceFeed,
        address newNativeTokenPriceFeed
    );

    /**
     * @dev Constructor function, can be called only once
     * @param _settings Contract settings, check InitContractSetting struct
     * @param _initialRecipients Addresses to be added as a initial recipients
     * @param _maxCaps Maximum amount recipient will receive
     * @param _priorities Priority when recipient is going to be current recipient
     * @param _nativeTokenUsdPriceFeed oracle address for native token / USD price
     */
    function initialize(
        InitContractSetting memory _settings,
        address payable[] memory _initialRecipients,
        uint256[] memory _maxCaps,
        uint256[] memory _priorities,
        address _nativeTokenUsdPriceFeed
    ) public initializer {
        // Contract settings
        controller = _settings.controller;

        uint256 distributorsLength = _settings._distributors.length;
        for (uint256 i = 0; i < distributorsLength; ) {
            distributors[_settings._distributors[i]] = true;
            unchecked {
                i++;
            }
        }

        immutableController = _settings.immutableController;
        autoNativeTokenDistribution = _settings.autoNativeTokenDistribution;
        minAutoDistributionAmount = _settings.minAutoDistributionAmount;
        factory = IFeeFactory(msg.sender);
        platformFee = _settings.platformFee;
        nativeTokenUsdPriceFeed = AggregatorV3Interface(_nativeTokenUsdPriceFeed);
        _transferOwnership(_settings.owner);
        uint256 supportedErc20Length = _settings.supportedErc20addresses.length;
        if (supportedErc20Length != _settings.erc20PriceFeeds.length) {
            revert InconsistentDataLengthError();
        }
        for (uint256 i = 0; i < supportedErc20Length; ) {
            _setTokenUsdPriceFeed(
                _settings.supportedErc20addresses[i],
                _settings.erc20PriceFeeds[i]
            );
            unchecked {
                i++;
            }
        }

        // Recipients settings
        _setRecipients(_initialRecipients, _maxCaps, _priorities);
    }

    /**
     * @notice Internal function to redistribute native token
     * @param _valueToDistribute amount in native token to be distributed
     * @param _recursive When recursive is True we don't charge additional fee
     */
    function _redistributeNativeToken(
        uint256 _valueToDistribute,
        bool _recursive
    ) internal override {
        if (currentRecipient == address(0)) {
            // When there is not currentRecipient _valueToDistribute stays in the Waterfall contract
            return;
        }

        // if any, subtract platform Fee and send it to platformWallet
        if (platformFee > 0 && !_recursive) {
            uint256 fee = (_valueToDistribute / BASIS_POINT) * platformFee;
            _valueToDistribute -= fee;
            address payable platformWallet = factory.platformWallet();
            (bool feeSuccess, ) = platformWallet.call{ value: fee }("");
            if (feeSuccess == false) {
                revert TransferFailedError();
            }
        }

        RecipientData storage recipientData = recipientsData[currentRecipient];
        uint256 remainCap = recipientData.maxCap - recipientData.received;
        uint256 nativeTokenValueToSent = _valueToDistribute;
        uint256 usdValueToSent = _convertNativeTokenToUsd(nativeTokenValueToSent);

        // Check if current recipient was fulfilled
        bool setNewCurrentRecipient = false;
        if (usdValueToSent >= remainCap) {
            usdValueToSent = remainCap;
            nativeTokenValueToSent = _convertUsdToNativeToken(usdValueToSent);
            setNewCurrentRecipient = true;
        }

        // Send native token to current currentRecipient
        recipientData.received += usdValueToSent;
        (bool success, ) = payable(currentRecipient).call{
            value: nativeTokenValueToSent
        }("");
        if (success == false) {
            revert TransferFailedError();
        }
        _recursiveNativeTokenDistribution(currentRecipient);

        // Set new current recipient if currentRecipient was fulfilled
        if (setNewCurrentRecipient) {
            _setCurrentRecipient();
            uint256 remainingBalance = address(this).balance;
            if (remainingBalance > 0) {
                _redistributeNativeToken(remainingBalance, true);
            }
        }
    }

    /**
     * @notice Internal function to redistribute ERC20 token based on waterfall rules
     * @param _token address of token to be distributed
     * @param _recursive When recursive is True we don't charge additional fee
     */
    function _redistributeToken(address _token, bool _recursive) internal override {
        if (currentRecipient == address(0)) {
            // When there is not currentRecipient we cannot distribute token
            return;
        }

        RecipientData storage recipientData = recipientsData[currentRecipient];
        IERC20 erc20Token = IERC20(_token);

        uint256 tokenValueToSent = erc20Token.balanceOf(address(this));
        if (tokenValueToSent == 0) {
            // Nothing to distribute
            return;
        }

        // if any subtract platform Fee and send it to platformWallet
        if (platformFee > 0 && !_recursive) {
            uint256 fee = (tokenValueToSent / BASIS_POINT) * platformFee;
            tokenValueToSent -= fee;
            address payable platformWallet = factory.platformWallet();
            erc20Token.safeTransfer(platformWallet, fee);
        }

        uint256 remainCap = recipientData.maxCap - recipientData.received;
        uint256 usdValueToSent = _convertTokenToUsd(_token, tokenValueToSent);

        // Check if current recipient was fulfilled
        bool setNewCurrentRecipient = false;
        if (usdValueToSent >= remainCap) {
            usdValueToSent = remainCap;
            tokenValueToSent = _convertUsdToToken(_token, usdValueToSent);
            setNewCurrentRecipient = true;
        }

        // Transfer token to currentRecipient
        erc20Token.safeTransfer(currentRecipient, tokenValueToSent);
        _recursiveERC20Distribution(currentRecipient, _token);
        recipientData.received += usdValueToSent;

        // Set new current recipient if currentRecipient was fulfilled
        if (setNewCurrentRecipient) {
            _setCurrentRecipient();
            uint256 contractBalance = erc20Token.balanceOf(address(this));
            if (contractBalance > 0) {
                _redistributeToken(_token, true);
            }
        }

        emit DistributeToken(_token, tokenValueToSent);
    }

    /**
     * @notice Internal function to convert native token value to USD value
     * @param _nativeTokenValue value of native token to be converted
     */
    function _convertNativeTokenToUsd(
        uint256 _nativeTokenValue
    ) internal view returns (uint256) {
        return (_getNativeTokenUsdPrice() * _nativeTokenValue) / 1e18;
    }

    /**
     * @notice Internal function to convert USD value to native token value
     * @param _usdValue value of usd to be converted
     */
    function _convertUsdToNativeToken(uint256 _usdValue) internal view returns (uint256) {
        return (((_usdValue * 1e25) / _getNativeTokenUsdPrice()) * 1e25) / 1e32;
    }

    /**
     * @notice Internal function to convert Token value to USD value
     * @param _token address of the token to be converted
     * @param _tokenValue amount of tokens to be converted
     */
    function _convertTokenToUsd(
        address _token,
        uint256 _tokenValue
    ) internal view returns (uint256) {
        return (_getTokenUsdPrice(_token) * _tokenValue) / 1e18;
    }

    /**
     * @notice Internal function to convert USD value to Token value
     * @param _token address of the token to be converted
     * @param _usdValue usd value to be converted
     */
    function _convertUsdToToken(
        address _token,
        uint256 _usdValue
    ) internal view returns (uint256) {
        return (((_usdValue * 1e25) / _getTokenUsdPrice(_token)) * 1e25) / 1e32;
    }

    /**
     * @notice internal function that returns native token/usd price from external oracle
     */
    function _getNativeTokenUsdPrice() private view returns (uint256) {
        (, int256 price, , , ) = nativeTokenUsdPriceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    /**
     * @notice internal function that returns erc20/usd price from external oracle
     * @param _token token address
     */
    function _getTokenUsdPrice(address _token) private view returns (uint256) {
        address tokenOracleAddress = tokenUsdPriceFeeds[_token];
        if (tokenOracleAddress == address(0)) {
            revert TokenMissingUsdPriceOracle();
        }
        AggregatorV3Interface tokenUsdPriceFeed = AggregatorV3Interface(
            tokenOracleAddress
        );
        (, int256 price, , , ) = tokenUsdPriceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    /**
     * @notice Internal function for setting price feed oracle for token
     * @param _token address of token
     * @param _priceFeed address of USD price feed for given token
     */
    function _setTokenUsdPriceFeed(address _token, address _priceFeed) internal {
        tokenUsdPriceFeeds[_token] = _priceFeed;
        emit TokenPriceFeedSet(_token, _priceFeed);
    }

    /**
     * @notice External function for setting price feed oracle for token
     * @param _token address of token
     * @param _priceFeed address of USD price feed for given token
     */
    function setTokenUsdPriceFeed(address _token, address _priceFeed) external onlyOwner {
        _setTokenUsdPriceFeed(_token, _priceFeed);
    }

    /**
     * @notice External function for setting price feed oracle for native token
     * @param _priceFeed address of USD price feed for native token
     */
    function setNativeTokenPriceFeed(address _priceFeed) external onlyOwner {
        emit NativeTokenPriceFeedSet(address(nativeTokenUsdPriceFeed), _priceFeed);
        nativeTokenUsdPriceFeed = AggregatorV3Interface(_priceFeed);
    }
}