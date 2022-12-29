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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal onlyInitializing {
    }

    function __ERC165Storage_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

interface IERC20Modified {
    // IERC20 Methods
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // Custom Methods
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function mint(address _toWhom, uint256 amount) external;
    function burn(address _whose, uint256 amount) external;
    function grantRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

import "./IVolmexProtocol.sol";

interface IVolmexOracle {
    event SymbolIndexUpdated(uint256 indexed _index);
    event BaseVolatilityIndexUpdated(uint256 indexed baseVolatilityIndex);
    event BatchVolatilityTokenPriceUpdated(
        uint256[] _volatilityIndexes,
        uint256[] _volatilityTokenPrices,
        bytes32[] _proofHashes
    );
    event VolatilityIndexAdded(
        uint256 indexed volatilityTokenIndex,
        uint256 volatilityCapRatio,
        string volatilityTokenSymbol,
        uint256 volatilityTokenPrice
    );
    event LeveragedVolatilityIndexAdded(
        uint256 indexed volatilityTokenIndex,
        uint256 volatilityCapRatio,
        string volatilityTokenSymbol,
        uint256 leverage,
        uint256 baseVolatilityIndex
    );

    // Getter  methods
    function volatilityCapRatioByIndex(uint256 _index) external view returns (uint256);
    function volatilityTokenPriceProofHash(uint256 _index) external view returns (bytes32);
    function volatilityIndexBySymbol(string calldata _tokenSymbol) external view returns (uint256);
    function volatilityLastUpdateTimestamp(uint256 _index) external view returns (uint256);
    function volatilityLeverageByIndex(uint256 _index) external view returns (uint256);
    function baseVolatilityIndex(uint256 _index) external view returns (uint256);
    function indexCount() external view returns (uint256);
    function latestRoundData(uint256 _index)
        external
        view
        returns (uint256 answer, uint256 lastUpdateTimestamp);
    function getIndexTwap(uint256 _index)
        external
        view
        returns (
            uint256 volatilityTokenTwap,
            uint256 iVolatilityTokenTwap,
            uint256 lastUpdateTimestamp
        );
    function getVolatilityTokenPriceByIndex(uint256 _index)
        external
        view
        returns (
            uint256 volatilityTokenPrice,
            uint256 iVolatilityTokenPrice,
            uint256 lastUpdateTimestamp
        );
    function getVolatilityPriceBySymbol(string calldata _volatilityTokenSymbol)
        external
        view
        returns (
            uint256 volatilityTokenPrice,
            uint256 iVolatilityTokenPrice,
            uint256 lastUpdateTimestamp
        );

    // Setter methods
    function updateIndexBySymbol(string calldata _tokenSymbol, uint256 _index) external;
    function updateBaseVolatilityIndex(
        uint256 _leverageVolatilityIndex,
        uint256 _newBaseVolatilityIndex
    ) external;
    function updateBatchVolatilityTokenPrice(
        uint256[] memory _volatilityIndexes,
        uint256[] memory _volatilityTokenPrices,
        bytes32[] memory _proofHashes
    ) external;
    function addVolatilityIndex(
        uint256 _volatilityTokenPrice,
        IVolmexProtocol _protocol,
        string calldata _volatilityTokenSymbol,
        uint256 _leverage,
        uint256 _baseVolatilityIndex,
        bytes32 _proofHash
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

import "./IERC20Modified.sol";

interface IVolmexProtocol {
    //getter methods
    function minimumCollateralQty() external view returns (uint256);
    function active() external view returns (bool);
    function isSettled() external view returns (bool);
    function volatilityToken() external view returns (IERC20Modified);
    function inverseVolatilityToken() external view returns (IERC20Modified);
    function collateral() external view returns (IERC20Modified);
    function issuanceFees() external view returns (uint256);
    function redeemFees() external view returns (uint256);
    function accumulatedFees() external view returns (uint256);
    function volatilityCapRatio() external view returns (uint256);
    function settlementPrice() external view returns (uint256);
    function precisionRatio() external view returns (uint256);

    //setter methods
    function toggleActive() external;
    function updateMinimumCollQty(uint256 _newMinimumCollQty) external;
    function updatePositionToken(address _positionToken, bool _isVolatilityIndex) external;
    function collateralize(uint256 _collateralQty) external returns (uint256, uint256);
    function redeem(uint256 _positionTokenQty) external returns (uint256, uint256);
    function redeemSettled(
        uint256 _volatilityIndexTokenQty,
        uint256 _inverseVolatilityIndexTokenQty
    ) external returns (uint256, uint256);
    function settle(uint256 _settlementPrice) external;
    function recoverTokens(
        address _token,
        address _toWhom,
        uint256 _howMuch
    ) external;
    function updateFees(uint256 _issuanceFees, uint256 _redeemFees) external;
    function claimAccumulatedFees() external;
    function togglePause(bool _isPause) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";

import "../interfaces/IVolmexProtocol.sol";
import "../interfaces/IVolmexOracle.sol";
import "./VolmexTWAP.sol";

/**
 * @title Volmex Oracle contract
 * @author volmex.finance [[email protected]]
 */
contract VolmexOracle is OwnableUpgradeable, ERC165StorageUpgradeable, VolmexTWAP, IVolmexOracle {
    // price precision constant upto 6 decimal places
    uint256 private constant _VOLATILITY_PRICE_PRECISION = 1000000;
    // maximum allowed number of index volatility datapoints for calculating twap
    uint256 private constant _MAX_ALLOWED_TWAP_DATAPOINTS = 6;
    // Interface ID of VolmexOracle contract, hashId = 0xf9fffc9f
    bytes4 private constant _IVOLMEX_ORACLE_ID = type(IVolmexOracle).interfaceId;

    // Store the price of volatility by indexes { 0 - ETHV, 1 = BTCV }
    mapping(uint256 => uint256) private _volatilityTokenPriceByIndex;

    // Store the volatilitycapratio by index
    mapping(uint256 => uint256) public volatilityCapRatioByIndex;
    // Store the proof of hash of the current volatility token price
    mapping(uint256 => bytes32) public volatilityTokenPriceProofHash;
    // Store the index of volatility by symbol
    mapping(string => uint256) public volatilityIndexBySymbol;
    // Store the leverage on volatility by index
    mapping(uint256 => uint256) public volatilityLeverageByIndex;
    // Store the base volatility index by leverage volatility index
    mapping(uint256 => uint256) public baseVolatilityIndex;
    // Store the number of indexes
    uint256 public indexCount;
    // Store the timestamp of volatility price update by index
    mapping(uint256 => uint256) public volatilityLastUpdateTimestamp;

    /**
     * @notice Initializes the contract setting the deployer as the initial owner.
     */
    function initialize(address _owner) external initializer {
        _updateTwapMaxDatapoints(_MAX_ALLOWED_TWAP_DATAPOINTS);

        _updateVolatilityMeta(indexCount, 200000000, "");
        volatilityIndexBySymbol["EVIV"] = indexCount;
        volatilityCapRatioByIndex[indexCount] = 400000000;

        indexCount++;

        _updateVolatilityMeta(indexCount, 200000000, "");
        volatilityIndexBySymbol["BVIV"] = indexCount;
        volatilityCapRatioByIndex[indexCount] = 400000000;

        __Ownable_init();
        __ERC165Storage_init();
        _registerInterface(_IVOLMEX_ORACLE_ID);
        _transferOwnership(_owner);
    }

    /**
     * @notice Update the volatility token index by symbol
     * @param _index Number value of the index. { eg. 0 }
     * @param _tokenSymbol Symbol of the adding volatility token
     */
    function updateIndexBySymbol(string calldata _tokenSymbol, uint256 _index) external onlyOwner {
        volatilityIndexBySymbol[_tokenSymbol] = _index;

        emit SymbolIndexUpdated(_index);
    }

    /**
     * @notice Update the baseVolatilityIndex of leverage token
     * @param _leverageVolatilityIndex Index of the leverage volatility token
     * @param _newBaseVolatilityIndex Index of the base volatility token
     */
    function updateBaseVolatilityIndex(
        uint256 _leverageVolatilityIndex,
        uint256 _newBaseVolatilityIndex
    ) external onlyOwner {
        baseVolatilityIndex[_leverageVolatilityIndex] = _newBaseVolatilityIndex;

        emit BaseVolatilityIndexUpdated(_newBaseVolatilityIndex);
    }

    /**
     * @notice Add volatility token price by index
     * @param _volatilityTokenPrice Price of the adding volatility token
     * @param _protocol Address of the VolmexProtocol of which the price is added
     * @param _volatilityTokenSymbol Symbol of the adding volatility token
     * @param _leverage Value of leverage on token {2X: 2, 5X: 5}
     * @param _baseVolatilityIndex Index of the base volatility {0: ETHV, 1: BTCV}
     * @param _proofHash Bytes32 value of token price proof of hash
     */
    function addVolatilityIndex(
        uint256 _volatilityTokenPrice,
        IVolmexProtocol _protocol,
        string calldata _volatilityTokenSymbol,
        uint256 _leverage,
        uint256 _baseVolatilityIndex,
        bytes32 _proofHash
    ) external onlyOwner {
        require(address(_protocol) != address(0), "VolmexOracle: protocol address can't be zero");
        uint256 _volatilityCapRatio = _protocol.volatilityCapRatio() * _VOLATILITY_PRICE_PRECISION;
        require(
            _volatilityCapRatio >= 1000000,
            "VolmexOracle: volatility cap ratio should be greater than 1000000"
        );
        uint256 _index = ++indexCount;
        volatilityCapRatioByIndex[_index] = _volatilityCapRatio;
        volatilityIndexBySymbol[_volatilityTokenSymbol] = _index;

        if (_leverage != 0) {
            // This will also check the base volatilities are present
            if (_leverage > 1) {
                require(
                    volatilityCapRatioByIndex[_baseVolatilityIndex] / _leverage == _volatilityCapRatio,
                    "VolmexOracle: Invalid _baseVolatilityIndex provided"
                );
            }
            volatilityLeverageByIndex[_index] = _leverage;
            baseVolatilityIndex[_index] = _baseVolatilityIndex;
            _addIndexDataPoint(
                _index,
                _volatilityTokenPriceByIndex[_baseVolatilityIndex] / _leverage
            );

            emit LeveragedVolatilityIndexAdded(
                _index,
                _volatilityCapRatio,
                _volatilityTokenSymbol,
                _leverage,
                _baseVolatilityIndex
            );
        } else {
            require(
                _volatilityTokenPrice <= _volatilityCapRatio,
                "VolmexOracle: _volatilityTokenPrice should be smaller than VolatilityCapRatio"
            );
            _updateVolatilityMeta(_index, _volatilityTokenPrice, _proofHash);

            emit VolatilityIndexAdded(
                _index,
                _volatilityCapRatio,
                _volatilityTokenSymbol,
                _volatilityTokenPrice
            );
        }
    }

    /**
     * @notice Updates the volatility token price by index
     *
     * @dev Check if volatility token price is greater than zero (0)
     * @dev Update the volatility token price corresponding to the volatility token symbol
     * @dev Store the volatility token price corresponding to the block number
     * @dev Update the proof of hash for the volatility token price
     *
     * @param _volatilityIndexes Number array of values of the volatility index. { eg. 0 }
     * @param _volatilityTokenPrices array of prices of volatility token, between {0, 250000000}
     * @param _proofHashes arrau of Bytes32 values of token prices proof of hash
     *
     * NOTE: Make sure the volatility token price are with 6 decimals, eg. 125000000
     */
    function updateBatchVolatilityTokenPrice(
        uint256[] memory _volatilityIndexes,
        uint256[] memory _volatilityTokenPrices,
        bytes32[] memory _proofHashes
    ) external onlyOwner {
        require(
            _volatilityIndexes.length == _volatilityTokenPrices.length &&
                _volatilityIndexes.length == _proofHashes.length,
            "VolmexOracle: length of input arrays are not equal"
        );
        for (uint256 i = 0; i < _volatilityIndexes.length; i++) {
            require(
                _volatilityTokenPrices[i] <= volatilityCapRatioByIndex[_volatilityIndexes[i]],
                "VolmexOracle: _volatilityTokenPrice should be smaller than VolatilityCapRatio"
            );

            _updateVolatilityMeta(
                _volatilityIndexes[i],
                _volatilityTokenPrices[i],
                _proofHashes[i]
            );
        }

        emit BatchVolatilityTokenPriceUpdated(
            _volatilityIndexes,
            _volatilityTokenPrices,
            _proofHashes
        );
    }

    /**
     * @notice Adds a new datapoint to the datapoints storage array
     *
     * @param _index Datapoints volatility index id {0}
     * @param _value Datapoint value to add {250000000}
     */
    function addIndexDataPoint(uint256 _index, uint256 _value) external onlyOwner {
        _addIndexDataPoint(_index, _value);
    }

    /**
     * @notice Get the volatility token price by symbol
     * @param _volatilityTokenSymbol Symbol of the volatility token
     */
    function getVolatilityPriceBySymbol(string calldata _volatilityTokenSymbol)
        external
        view
        returns (
            uint256 volatilityTokenPrice,
            uint256 iVolatilityTokenPrice,
            uint256 lastUpdateTimestamp
        )
    {
        uint256 volatilityIndex = volatilityIndexBySymbol[_volatilityTokenSymbol];
        (
            volatilityTokenPrice,
            iVolatilityTokenPrice,
            lastUpdateTimestamp
        ) = _getVolatilityTokenPrice(volatilityIndex);
    }

    /**
     * @notice Get the volatility token price by index
     * @param _index index of the volatility token
     */
    function getVolatilityTokenPriceByIndex(uint256 _index)
        external
        view
        returns (
            uint256 volatilityTokenPrice,
            uint256 iVolatilityTokenPrice,
            uint256 lastUpdateTimestamp
        )
    {
        (
            volatilityTokenPrice,
            iVolatilityTokenPrice,
            lastUpdateTimestamp
        ) = _getVolatilityTokenPrice(_index);
    }

    /**
     * @notice Get the TWAP value from current available datapoints
     * @param _index Datapoints volatility index id {0}
     *
     * @dev This method is a replica of `getVolatilityTokenPriceByIndex(_index)`
     */
    function getIndexTwap(uint256 _index)
        external
        view
        returns (
            uint256 volatilityTokenTwap,
            uint256 iVolatilityTokenTwap,
            uint256 lastUpdateTimestamp
        )
    {
        (
            volatilityTokenTwap,
            iVolatilityTokenTwap,
            lastUpdateTimestamp
        ) = _getVolatilityTokenPrice(_index);
    }

    /**
     * @notice Get all datapoints available for a specific volatility index
     * @param _index Datapoints volatility index id {0}
     */
    function getIndexDataPoints(uint256 _index) external view returns (uint256[] memory dp) {
        dp = _getIndexDataPoints(_index);
    }

    /**
     * @notice Update maximum amount of volatility index datapoints for calculating the TWAP
     *
     * @param _value Max datapoints value {180}
     */
    function updateTwapMaxDatapoints(uint256 _value) external onlyOwner {
        _updateTwapMaxDatapoints(_value);
    }

    /**
     * @notice Emulate the Chainlink Oracle interface for retrieving Volmex TWAP volatility index
     * @param _index Datapoints volatility index id {0}
     * @return answer is the answer for the given round
     */
    function latestRoundData(uint256 _index)
        external
        view
        virtual
        override
        returns (uint256 answer, uint256 lastUpdateTimestamp)
    {
        answer = _getIndexTwap(_index) * 100;
        lastUpdateTimestamp = volatilityLeverageByIndex[_index] > 0
            ? volatilityLastUpdateTimestamp[baseVolatilityIndex[_index]]
            : volatilityLastUpdateTimestamp[_index];
    }

    function _updateVolatilityMeta(
        uint256 _index,
        uint256 _volatilityTokenPrice,
        bytes32 _proofHash
    ) private {
        _addIndexDataPoint(_index, _volatilityTokenPrice);
        _volatilityTokenPriceByIndex[_index] = _getIndexTwap(_index);
        volatilityLastUpdateTimestamp[_index] = block.timestamp;
        volatilityTokenPriceProofHash[_index] = _proofHash;
    }

    function _getVolatilityTokenPrice(uint256 _index)
        private
        view
        returns (
            uint256 volatilityTokenTwap,
            uint256 iVolatilityTokenTwap,
            uint256 lastUpdateTimestamp
        )
    {
        if (volatilityLeverageByIndex[_index] != 0) {
            uint256 baseIndex = baseVolatilityIndex[_index];
            volatilityTokenTwap = (_getIndexTwap(baseIndex)) / volatilityLeverageByIndex[_index];
            lastUpdateTimestamp = volatilityLastUpdateTimestamp[baseIndex];
        } else {
            volatilityTokenTwap = _getIndexTwap(_index);
            lastUpdateTimestamp = volatilityLastUpdateTimestamp[_index];
        }
        iVolatilityTokenTwap = volatilityCapRatioByIndex[_index] - volatilityTokenTwap;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.17;

/**
 * @title Volmex Oracle TWAP library
 * @author volmex.finance [[email protected]]
 */
contract VolmexTWAP {
    // Max datapoints allowed to store in
    uint256 private _MAX_DATAPOINTS;

    // Emit new event when new datapoint is added
    event IndexDataPointAdded(uint256 indexed_index, uint256 _value);

    // Emit an event when max allowed twap datapoints value it's updated
    event MaxTwapDatapointsUpdated(uint256 _value);

    // Store index datapoints into multidimensional arrays
    mapping(uint256 => uint256[]) private _datapoints;

    // In order to maintain low gas fees and storage efficiency we use cursors to store datapoints
    mapping(uint256 => uint256) private _datapointsCursor;

    /**
     * @notice Adds a new datapoint to the datapoints storage array
     *
     * @param _index Datapoints volatility index id {0}
     * @param _value Datapoint value to add {250000000}
     */
    function _addIndexDataPoint(uint256 _index, uint256 _value) internal {
        if (_datapoints[_index].length < _MAX_DATAPOINTS) {
            // initially populate available datapoint storage slots with index data
            _datapoints[_index].push(_value);
        } else {
            if (
                // reset the cursor has reached the maximum allowed storage datapoints 
                // or max allowed datapoints values changed by the owner it's lower than current cursor
                _datapointsCursor[_index] >= _MAX_DATAPOINTS
            ) {
                // reset cursor
                _datapointsCursor[_index] = 0;
            }

            _datapoints[_index][_datapointsCursor[_index]] = _value;
            _datapointsCursor[_index]++;
        }

        emit IndexDataPointAdded(_index, _value);
    }

    /**
     * @notice Get the TWAP value from current available datapoints
     * @param _index Datapoints volatility index id {0}
     */
    function _getIndexTwap(uint256 _index) internal view returns (uint256 twap) {
        uint256 _datapointsSum;

        uint256 _datapointsLen = _datapoints[_index].length;

        for (uint256 i = 0; i < _datapointsLen; i++) {
            _datapointsSum += _datapoints[_index][i];
        }

        twap = _datapointsSum / _datapointsLen;
    }

    /**
     * @notice Get all datapoints available for a specific volatility index
     * @param _index Datapoints volatility index id {0}
     */
    function _getIndexDataPoints(uint256 _index)
        internal
        view
        returns (uint256[] memory datapoints)
    {
        datapoints = _datapoints[_index];
    }

    /**
     * @notice Update maximum amount of volatility index datapoints for calculating the TWAP
     *
     * @param _value Max datapoints value {180}
     */
    function _updateTwapMaxDatapoints(uint256 _value) internal {
        require(_value > 0, "Minimum amount of index datapoints needs to be greater than zero");

        _MAX_DATAPOINTS = _value;

        emit MaxTwapDatapointsUpdated(_value);
    }

    uint256[10] private __gap;
}