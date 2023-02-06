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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "./../interfaces/IBridge.sol";
import "./../libraries/ECDSA.sol";

import "./../utils/Cache.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";


/// @title EVM Bridge contract
/// @author https://github.com/broxus
/// @notice Stores relays for each round, implements relay slashing, helps in validating Everscale-EVM events
contract Bridge is OwnableUpgradeable, PausableUpgradeable, Cache, IBridge {
    using ECDSA for bytes32;

    // NOTE: round number -> address -> is relay?
    mapping (uint32 => mapping(address => bool)) public relays;

    // NOTE: is relay banned or not
    mapping (address => bool) public blacklist;

    // NOTE: round meta data
    mapping (uint32 => Round) public rounds;

    // NOTE: signature verifications always fails is emergency is on
    bool public emergencyShutdown;

    // NOTE: The required signatures per round can't be less than this
    uint32 public minimumRequiredSignatures;

    // NOTE: how long round signatures are considered valid after the end of the round
    uint32 public roundTTL;

    // NOTE: initial round number
    uint32 public initialRound;

    // NOTE: last round with known relays
    uint32 public lastRound;

    // NOTE: special address, can set up rounds without relays's signatures
    address public roundSubmitter;

    // NOTE: Broxus Bridge Everscale-ETH configuration address, that emits event with round relays
    EverscaleAddress public roundRelaysConfiguration;

    /**
        @notice Bridge initializer
        @dev `roundRelaysConfiguration` should be specified after deploy, since it's an Everscale contract,
        which needs EVM Bridge address to be deployed.
        @param _owner Bridge owner
        @param _roundSubmitter Round submitter
        @param _minimumRequiredSignatures Minimum required signatures per round.
        @param _roundTTL Round TTL after round end.
        @param _initialRound Initial round number. Useful in case new EVM network is connected to the bridge.
        @param _initialRoundEnd Initial round end timestamp.
        @param _relays Initial (genesis) set of relays. Encode addresses as uint160.
    */
    function initialize(
        address _owner,
        address _roundSubmitter,
        uint32 _minimumRequiredSignatures,
        uint32 _roundTTL,
        uint32 _initialRound,
        uint32 _initialRoundEnd,
        uint160[] calldata _relays
    ) external initializer {
        __Pausable_init();
        __Ownable_init();
        transferOwnership(_owner);

        roundSubmitter = _roundSubmitter;
        emit UpdateRoundSubmitter(_roundSubmitter);

        minimumRequiredSignatures = _minimumRequiredSignatures;
        emit UpdateMinimumRequiredSignatures(minimumRequiredSignatures);

        roundTTL = _roundTTL;
        emit UpdateRoundTTL(roundTTL);

        require(
            _initialRoundEnd >= block.timestamp,
            "Bridge: initial round end should be in the future"
        );

        initialRound = _initialRound;
        _setRound(initialRound, _relays, _initialRoundEnd);

        lastRound = initialRound;
    }

    /**
        @notice Update address of configuration, that emits event with relays for next round.
        @param _roundRelaysConfiguration Everscale address of configuration contract
    */
    function setConfiguration(
        EverscaleAddress calldata _roundRelaysConfiguration
    ) external override onlyOwner {
        emit UpdateRoundRelaysConfiguration(_roundRelaysConfiguration);

        roundRelaysConfiguration = _roundRelaysConfiguration;
    }

    /**
        @notice Pause Bridge contract.
        Can be called only by `owner`.
        @dev When Bridge paused, any signature verification Everscale-EVM event fails.
    */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
        @notice Unpause Bridge contract.
    */
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
        @notice Update minimum amount of required signatures per round
        This parameter limits the minimum amount of signatures to be required for Everscale-EVM event.
        @param _minimumRequiredSignatures New value
    */
    function updateMinimumRequiredSignatures(
        uint32 _minimumRequiredSignatures
    ) external override onlyOwner {
        minimumRequiredSignatures = _minimumRequiredSignatures;

        emit UpdateMinimumRequiredSignatures(_minimumRequiredSignatures);
    }

    /**
        @notice Update round TTL
        @dev This affects only future rounds. Rounds, that were already set, keep their current TTL.
        @param _roundTTL New TTL value
    */
    function updateRoundTTL(
        uint32 _roundTTL
    ) external override onlyOwner {
        roundTTL = _roundTTL;

        emit UpdateRoundTTL(_roundTTL);
    }

    /// @notice Check if relay is banned.
    /// Ban is global. If the relay is banned it means it lost relay power in all rounds, past and future.
    /// @param candidate Address to check
    function isBanned(
        address candidate
    ) override public view returns (bool) {
        return blacklist[candidate];
    }

    /// @notice Check if some address is relay at specific round
    /// @dev Even if relay was banned, this method still returns `true`.
    /// @param round Round id
    /// @param candidate Address to check
    function isRelay(
        uint32 round,
        address candidate
    ) override public view returns (bool) {
        return relays[round][candidate];
    }

    /// @dev Check if round is rotten
    /// @param round Round id
    function isRoundRotten(
        uint32 round
    ) override public view returns (bool) {
        return block.timestamp > rounds[round].ttl;
    }


    /// @notice Verify `EverscaleEvent` signatures.
    /// @dev Signatures should be sorted by the ascending signers.
    /// Error codes:
    /// 0. Verification passed (no error)
    /// 1. Specified round is less than initial round
    /// 2. Specified round is greater than last round
    /// 3. Not enough correct signatures. Possible reasons:
    /// - Some of the signers are not relays at the specified round
    /// - Some of the signers are banned
    /// 4. Round is rotten.
    /// 5. Verification passed, but bridge is in "paused" mode
    /// @param payload Bytes encoded `EverscaleEvent` structure
    /// @param signatures Payload signatures
    /// @return errorCode Error code
    function verifySignedEverscaleEvent(
        bytes memory payload,
        bytes[] memory signatures
    )
        override
        public
        view
    returns (
        uint32 errorCode
    ) {
        (EverscaleEvent memory _event) = abi.decode(payload, (EverscaleEvent));

        uint32 round = _event.round;

        // Check round is greater than initial round
        if (round < initialRound) return 1;

        // Check round is less than last initialized round
        if (round > lastRound) return 2;

        // Check there are enough correct signatures
        uint32 count = _countRelaySignatures(payload, signatures, round);
        if (count < rounds[round].requiredSignatures) return 3;

        // Check round rotten
        if (isRoundRotten(round)) return 4;

        // Check bridge has been paused
        if (paused()) return 5;

        return 0;
    }

    /**
        @notice
            Recover signer from the payload and signature
        @param payload Payload
        @param signature Signature
    */
    function recoverSignature(
        bytes memory payload,
        bytes memory signature
    ) public pure returns (address signer) {
        signer = keccak256(payload)
            .toBytesPrefixed()
            .recover(signature);
    }

    /**
        @notice Forced set of next round relays
        @dev Can be called only by `roundSubmitter`
        @param _relays Next round relays
        @param roundEnd Round end
    */
    function forceRoundRelays(
        uint160[] calldata _relays,
        uint32 roundEnd
    ) override external {
        require(msg.sender == roundSubmitter, "Bridge: sender not round submitter");

        _setRound(lastRound + 1, _relays, roundEnd);

        lastRound++;
    }

    /**
        @notice Set round submitter
        @dev Can be called only by owner
        @param _roundSubmitter New round submitter address
    */
    function setRoundSubmitter(
        address _roundSubmitter
    ) override external onlyOwner {
        roundSubmitter = _roundSubmitter;

        emit UpdateRoundSubmitter(roundSubmitter);
    }

    /**
        @notice Grant relay permission for set of addresses at specific round
        @param payload Bytes encoded EverscaleEvent structure
        @param signatures Payload signatures
    */
    function setRoundRelays(
        bytes calldata payload,
        bytes[] calldata signatures
    ) override external notCached(payload) {
        require(
            verifySignedEverscaleEvent(
                payload,
                signatures
            ) == 0,
            "Bridge: signatures verification failed"
        );

        (EverscaleEvent memory _event) = abi.decode(payload, (EverscaleEvent));

        require(
            _event.configurationWid == roundRelaysConfiguration.wid &&
            _event.configurationAddress == roundRelaysConfiguration.addr,
            "Bridge: wrong event configuration"
        );

        (uint32 round, uint160[] memory _relays, uint32 roundEnd) = decodeRoundRelaysEventData(payload);

        require(round == lastRound + 1, "Bridge: wrong round");

        _setRound(round, _relays, roundEnd);

        lastRound++;
    }

    function decodeRoundRelaysEventData(
        bytes memory payload
    ) public pure returns (
        uint32 round,
        uint160[] memory _relays,
        uint32 roundEnd
    ) {
        (EverscaleEvent memory EverscaleEvent) = abi.decode(payload, (EverscaleEvent));

        (round, _relays, roundEnd) = abi.decode(
            EverscaleEvent.eventData,
            (uint32, uint160[], uint32)
        );
    }

    function decodeEverscaleEvent(
        bytes memory payload
    ) external pure returns (EverscaleEvent memory _event) {
        (_event) = abi.decode(payload, (EverscaleEvent));
    }

    /**
        @notice
            Ban relays
        @param _relays List of relay addresses to ban
    */
    function banRelays(
        address[] calldata _relays
    ) override external onlyOwner {
        for (uint i=0; i<_relays.length; i++) {
            blacklist[_relays[i]] = true;

            emit BanRelay(_relays[i], true);
        }
    }

    /**
        @notice
            Unban relays
        @param _relays List of relay addresses to unban
    */
    function unbanRelays(
        address[] calldata _relays
    ) override external onlyOwner {
        for (uint i=0; i<_relays.length; i++) {
            blacklist[_relays[i]] = false;

            emit BanRelay(_relays[i], false);
        }
    }

    function _setRound(
        uint32 round,
        uint160[] memory _relays,
        uint32 roundEnd
    ) internal {
        uint32 requiredSignatures = uint32(_relays.length * 2 / 3) + 1;

        rounds[round] = Round(
            roundEnd,
            roundEnd + roundTTL,
            uint32(_relays.length),
            requiredSignatures < minimumRequiredSignatures ? minimumRequiredSignatures : requiredSignatures
        );

        emit NewRound(round, rounds[round]);

        for (uint i=0; i<_relays.length; i++) {
            address relay = address(_relays[i]);

            relays[round][relay] = true;

            emit RoundRelay(round, relay);
        }
    }

    function _countRelaySignatures(
        bytes memory payload,
        bytes[] memory signatures,
        uint32 round
    ) internal view returns (uint32) {
        address lastSigner = address(0);
        uint32 count = 0;

        for (uint i=0; i<signatures.length; i++) {
            address signer = recoverSignature(payload, signatures[i]);

            require(signer > lastSigner, "Bridge: signatures sequence wrong");
            lastSigner = signer;

            if (isRelay(round, signer) && !isBanned(signer)) {
                count++;
            }
        }

        return count;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;

import "./IEverscale.sol";
pragma experimental ABIEncoderV2;


interface IBridge is IEverscale {
    struct Round {
        uint32 end;
        uint32 ttl;
        uint32 relays;
        uint32 requiredSignatures;
    }

    function updateMinimumRequiredSignatures(uint32 _minimumRequiredSignatures) external;
    function setConfiguration(EverscaleAddress calldata _roundRelaysConfiguration) external;
    function updateRoundTTL(uint32 _roundTTL) external;

    function isRelay(
        uint32 round,
        address candidate
    ) external view returns (bool);

    function isBanned(
        address candidate
    ) external view returns (bool);

    function isRoundRotten(
        uint32 round
    ) external view returns (bool);

    function verifySignedEverscaleEvent(
        bytes memory payload,
        bytes[] memory signatures
    ) external view returns (uint32);

    function setRoundRelays(
        bytes calldata payload,
        bytes[] calldata signatures
    ) external;

    function forceRoundRelays(
        uint160[] calldata _relays,
        uint32 roundEnd
    ) external;

    function banRelays(
        address[] calldata _relays
    ) external;

    function unbanRelays(
        address[] calldata _relays
    ) external;

    function pause() external;
    function unpause() external;

    function setRoundSubmitter(address _roundSubmitter) external;

    event EmergencyShutdown(bool active);

    event UpdateMinimumRequiredSignatures(uint32 value);
    event UpdateRoundTTL(uint32 value);
    event UpdateRoundRelaysConfiguration(EverscaleAddress configuration);
    event UpdateRoundSubmitter(address _roundSubmitter);

    event NewRound(uint32 indexed round, Round meta);
    event RoundRelay(uint32 indexed round, address indexed relay);
    event BanRelay(address indexed relay, bool status);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;


interface IEverscale {
    struct EverscaleAddress {
        int128 wid;
        uint256 addr;
    }

    struct EverscaleEvent {
        uint64 eventTransactionLt;
        uint32 eventTimestamp;
        bytes eventData;
        int8 configurationWid;
        uint256 configurationAddress;
        int8 eventContractWid;
        uint256 eventContractAddress;
        address proxy;
        uint32 round;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;

library ECDSA {

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param signature bytes signature, the signature is generated using web3.eth.sign()
     */
    function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (signature.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables with inline assembly.
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash, v, r, s);
        }
    }

    /**
      * toBytesPrefixed
      * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
      * and hash the result
      */
    function toBytesPrefixed(bytes32 hash)
    internal
    pure
    returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;


contract Cache {
    mapping (bytes32 => bool) public cache;

    modifier notCached(bytes memory payload) {
        bytes32 hash_ = keccak256(abi.encode(payload));

        require(cache[hash_] == false, "Cache: payload already seen");

        _;

        cache[hash_] = true;
    }
}