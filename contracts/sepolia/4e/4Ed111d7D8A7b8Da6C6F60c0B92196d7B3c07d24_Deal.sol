// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

struct Milestone {
    bytes32 hashA;
    bytes32 hashB;
    uint256 timeA;
    uint256 timeB;
}

struct Revenue {
    bytes32 revenueHash;
    uint256 revenueTime;
}

interface RainInterface {
    function isAccountFrozen(address account) external view returns (bool);

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);
}

contract Deal is Initializable, PausableUpgradeable {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant USER_ROLE = keccak256("USER_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    event UpdatedRainTokenAddress(address newRainTokenAddress);
    event AddedDealHash(bytes32 dealHash);
    event RemovedDealHash(uint256 index);
    event UpdatedDealHash(uint256 index, bytes32 dealHash);
    event AddedMilestone(
        bytes32 hashA,
        bytes32 hashB,
        uint256 timeA,
        uint256 timeB
    );
    event RemovedMilestone(uint256 index);

    event UpdatedMilestone(
        uint256 index,
        bytes32 hashA,
        bytes32 hashB,
        uint256 timeA,
        uint256 timeB
    );

    event AddedRevenue(bytes32 revenueHash, uint256 revenueTime);
    event RemovedRevenue(uint256 index);
    event UpdatedRevenue(
        uint256 index,
        bytes32 revenueHash,
        uint256 revenueTime
    );

    modifier onlyRainUser() {
        require(
            RainInterface(rainTokenAddress).hasRole(USER_ROLE, msg.sender),
            "Address doesn't have the USER_ROLE"
        );
        _;
    }

    modifier onlyRainCompliance() {
        require(
            RainInterface(rainTokenAddress).hasRole(
                COMPLIANCE_ROLE,
                msg.sender
            ),
            "Address doesn't have the COMPLIANCE_ROLE"
        );
        _;
    }

    modifier onlyRainAdmin() {
        require(
            RainInterface(rainTokenAddress).hasRole(
                DEFAULT_ADMIN_ROLE,
                msg.sender
            ),
            "Address doesn't have the DEFAULT_ADMIN_ROLE"
        );
        _;
    }

    modifier addressNotFrozen() {
        require(
            !RainInterface(rainTokenAddress).isAccountFrozen(msg.sender),
            "Address is frozen"
        );
        _;
    }

    address public rainTokenAddress;
    bytes32[] public dealHashes;
    Milestone[] private milestones;
    Revenue[] private revenues;

    function initialize(
        address _rainTokenAddress
    ) external initializer {
        __Context_init();
        __Pausable_init();
        rainTokenAddress = _rainTokenAddress;
    }

    // @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function getRevenue(
        uint256 _index
    ) external view returns (bytes32 hash, uint256 time) {
        require(_index < revenues.length, "Index out of bounds");
        return (revenues[_index].revenueHash, revenues[_index].revenueTime);
    }

    function getMilestone(
        uint256 _index
    )
        external
        view
        returns (bytes32 hashA, bytes32 hashB, uint256 timeA, uint256 timeB)
    {
        require(_index < milestones.length, "Index out of bounds");
        Milestone storage m = milestones[_index];
        return (m.hashA, m.hashB, m.timeA, m.timeB);
    }

    /// @notice Admin function to update Rain token address
    /// @param _rainTokenAddress New rain token address
    function updateRainTokenAddress(
        address _rainTokenAddress
    ) external onlyRainAdmin addressNotFrozen whenNotPaused {
        rainTokenAddress = _rainTokenAddress;
        emit UpdatedRainTokenAddress(_rainTokenAddress);
    }

    /// @notice User function to add new hash to deal hash array
    /// @param _dealHash New deal hash
    function addDealHash(
        bytes32 _dealHash
    ) external onlyRainUser addressNotFrozen whenNotPaused {
        dealHashes.push(_dealHash);
        emit AddedDealHash(_dealHash);
    }

    /// @notice Admin function to remove hash from deal hash array
    /// @param _index Index of hash to remove
    function removeDealHash(
        uint256 _index
    ) external onlyRainAdmin addressNotFrozen whenNotPaused {
        require(_index < dealHashes.length, "Index out of bounds");

        for (uint256 i = _index; i < dealHashes.length - 1; i++)
            dealHashes[i] = dealHashes[i + 1];
        dealHashes.pop();
        emit RemovedDealHash(_index);
    }

    /// @notice Admin function to update hash in deal hash array
    /// @param _index Index of hash to update
    /// @param _dealHash New deal hash
    function updateDealHash(
        uint256 _index,
        bytes32 _dealHash
    ) external onlyRainAdmin addressNotFrozen whenNotPaused {
        require(_index < dealHashes.length, "Index out of bounds");
        dealHashes[_index] = _dealHash;
        emit UpdatedDealHash(_index, _dealHash);
    }

    /// @notice User function to add new milestone to milestone array
    /// @param _hashA First hash of milestone
    /// @param _hashB Second hash of milestone
    /// @param _timeA First time of milestone
    /// @param _timeB Second time of milestone
    function addMilestone(
        bytes32 _hashA,
        bytes32 _hashB,
        uint256 _timeA,
        uint256 _timeB
    ) external onlyRainUser addressNotFrozen whenNotPaused {
        milestones.push(
            Milestone({
                hashA: _hashA,
                hashB: _hashB,
                timeA: _timeA,
                timeB: _timeB
            })
        );
        emit AddedMilestone(_hashA, _hashB, _timeA, _timeB);
    }

    /// @notice Admin function to remove a milestone from the milestone array
    /// @param _index Index of milestone to remove
    function removeMilestone(
        uint256 _index
    ) external onlyRainAdmin addressNotFrozen whenNotPaused {
        require(_index < milestones.length, "Index out of bounds");

        for (uint256 i = _index; i < milestones.length - 1; i++)
            milestones[i] = milestones[i + 1];
        milestones.pop();
        emit RemovedMilestone(_index);
    }

    /// @notice Admin function to update milestone in milestone array
    /// @param _index Index of milestone to update
    /// @param _hashA First hash of milestone
    /// @param _hashB Second hash of milestone
    /// @param _timeA First time of milestone
    /// @param _timeB Second time of milestone
    function updateMilestone(
        uint256 _index,
        bytes32 _hashA,
        bytes32 _hashB,
        uint256 _timeA,
        uint256 _timeB
    ) external onlyRainAdmin addressNotFrozen whenNotPaused {
        require(_index < milestones.length, "Index out of bounds");
        milestones[_index] = Milestone({
            hashA: _hashA,
            hashB: _hashB,
            timeA: _timeA,
            timeB: _timeB
        });
        emit UpdatedMilestone(_index, _hashA, _hashB, _timeA, _timeB);
    }

    /// @notice User function to add new revenue to revenue array
    /// @param _revenueHash New revenue hash
    /// @param _revenueTime New revenue time
    function addRevenue(
        bytes32 _revenueHash,
        uint256 _revenueTime
    ) external onlyRainUser addressNotFrozen whenNotPaused {
        revenues.push(
            Revenue({revenueHash: _revenueHash, revenueTime: _revenueTime})
        );
        emit AddedRevenue(_revenueHash, _revenueTime);
    }

    /// @notice Admin function to remove revenue from revenue array
    /// @param _index Index of revenue to remove
    function removeRevenue(
        uint256 _index
    ) external onlyRainAdmin addressNotFrozen whenNotPaused {
        require(_index < revenues.length, "Index out of bounds");

        for (uint256 i = _index; i < revenues.length - 1; i++)
            revenues[i] = revenues[i + 1];
        revenues.pop();
        emit RemovedRevenue(_index);
    }

    /// @notice Admin function to update revenue in revenue array
    /// @param _index Index of revenue to update
    /// @param _revenueHash New revenue hash
    /// @param _revenueTime New revenue time
    function updateRevenue(
        uint256 _index,
        bytes32 _revenueHash,
        uint256 _revenueTime
    ) external onlyRainAdmin addressNotFrozen whenNotPaused {
        require(_index < revenues.length, "Index out of bounds");
        revenues[_index] = Revenue({
            revenueHash: _revenueHash,
            revenueTime: _revenueTime
        });
        emit UpdatedRevenue(_index, _revenueHash, _revenueTime);
    }

    /// @notice Pause function, only for Rain compliance
    function pause() external onlyRainCompliance {
        _pause();
    }

    /// @notice Unpause function, only for Rain compliance 
    function unpause() external onlyRainCompliance {
        _unpause();
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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