// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

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
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "@solmate/utils/SafeTransferLib.sol";
import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import { Owned } from "@solmate/auth/Owned.sol";
import { UniswapV3Pool } from "src/interfaces/uniswapV3/UniswapV3Pool.sol";
import { NonfungiblePositionManager } from "src/interfaces/uniswapV3/NonfungiblePositionManager.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import { IKeeperRegistrar, RegistrationParams } from "src/interfaces/chainlink/IKeeperRegistrar.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { IChainlinkAggregator } from "src/interfaces/chainlink/IChainlinkAggregator.sol";

/**
 * @title Limit Order Registry
 * @notice Allows users to create decentralized limit orders.
 * @dev DO NOT PLACE LIMIT ORDERS FOR STRONGLY CORRELATED ASSETS.
 *      - If a stable coin pair were to temporarily depeg, and a user places a limit order
 *        whose tick range encompasses the normal trading tick, there is NO way to cancel the order
 *        because the order is mixed. The user would have to wait for another depeg event to happen
 *        so that the order can be fulfilled, or the order can be cancelled.
 * @author crispymangoes
 */
contract LimitOrderRegistry is Owned, AutomationCompatibleInterface, ERC721Holder, Context {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                             STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Stores linked list center values, and frequently used pool values.
     * @param centerHead Linked list center value closer to head of the list
     * @param centerTail Linked list center value closer to tail of the list
     * @param token0 ERC20 token0 of the pool
     * @param token1 ERC20 token1 of the pool
     * @param fee Uniswap V3 pool fee
     */
    struct PoolData {
        uint256 centerHead;
        uint256 centerTail;
        ERC20 token0;
        ERC20 token1;
        uint24 fee;
    }

    /**
     * @notice Stores information about batches of orders.
     * @dev User orders can be batched together if they share the same target price.
     * @param direction Determines what direction the tick must move in order for the order to be filled
     *        - true, pool tick must INCREASE to fill this order
     *        - false, pool tick must DECREASE to fill this order
     * @param tickUpper The upper tick of the underlying LP position
     * @param tickLower The lower tick of the underlying LP position
     * @param userCount The number of users in this batch order
     * @param batchId Unique id used to distinguish this batch order from another batch order in the past that used the same LP position
     * @param token0Amount The amount of token0 in this order
     * @param token1Amount The amount of token1 in this order
     * @param head The next node in the linked list when moving toward the head
     * @param tail The next node in the linked list when moving toward the tail
     */
    struct BatchOrder {
        bool direction;
        int24 tickUpper;
        int24 tickLower;
        uint64 userCount;
        uint128 batchId;
        uint128 token0Amount;
        uint128 token1Amount;
        uint256 head;
        uint256 tail;
    }

    /**
     * @notice Stores information needed for users to make claims.
     * @param pool The Uniswap V3 pool the batch order was in
     * @param token0Amount The amount of token0 in the order
     * @param token1Amount The amount of token1 in the order
     * @param feePerUser The native token fee that must be paid on order claiming
     * @param direction The underlying order direction, used to determine input/output token of the order
     * @param isReadyForClaim Explicit bool indicating whether or not this order is ready to be claimed
     */
    struct Claim {
        UniswapV3Pool pool;
        uint128 token0Amount; //Can either be the deposit amount or the amount got out of liquidity changing to the other token
        uint128 token1Amount;
        uint128 feePerUser; // Fee in terms of network native asset.
        bool direction; //Determines the token out
        bool isReadyForClaim;
    }

    /**
     * @notice Struct used to store variables needed during order creation.
     * @param tick The target tick of the order
     * @param upper The upper tick of the underlying LP position
     * @param lower The lower tick of the underlying LP position
     * @param userTotal The total amount of assets the user has in the order
     * @param positionId The underling LP position token id this order is adding liquidity to
     * @param amount0 Can be the amount of assets user added to the order, based off orders direction
     * @param amount1 Can be the amount of assets user added to the order, based off orders direction
     */
    struct OrderDetails {
        int24 tick;
        int24 upper;
        int24 lower;
        uint128 userTotal;
        uint256 positionId;
        uint128 amount0;
        uint128 amount1;
    }

    /*//////////////////////////////////////////////////////////////
                             GLOBAL STATE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Stores swap fees earned from limit order where the input token earns swap fees.
     */
    mapping(address => uint256) public tokenToSwapFees;

    /**
     * @notice Used to store claim information needed when users are claiming their orders.
     */
    mapping(uint128 => Claim) public claim;

    /**
     * @notice Stores the pools center head/tail, as well as frequently read values.
     */
    mapping(UniswapV3Pool => PoolData) public poolToData;

    /**
     * @notice Maps tick ranges to LP positions owned by this contract.
     */
    mapping(int24 => mapping(int24 => uint256)) public getPositionFromTicks; // maps lower -> upper -> positionId

    /**
     * @notice The minimum amount of assets required to create a `newOrder`.
     * @dev Changeable by owner.
     */
    mapping(ERC20 => uint256) public minimumAssets;

    /**
     * @notice Approximated amount of gas needed to fulfill 1 BatchOrder.
     * @dev Changeable by owner.
     */
    uint32 public upkeepGasLimit = 300_000;

    /**
     * @notice Approximated gas price used to fulfill orders.
     * @dev Changeable by owner.
     */
    uint32 public upkeepGasPrice = 30;

    /**
     * @notice Max number of orders that can be filled in 1 upkeep call.
     * @dev Changeable by owner.
     */
    uint16 public maxFillsPerUpkeep = 10;

    /**
     * @notice Value is incremented whenever a new BatchOrder is added to the `orderBook`.
     * @dev Zero is reserved.
     */
    uint128 public batchCount = 1;

    /**
     * @notice Mapping is used to store user deposit amounts in each BatchOrder.
     */
    mapping(uint128 => mapping(address => uint128)) private batchIdToUserDepositAmount;

    /**
     * @notice The `orderBook` maps Uniswap V3 token ids to BatchOrder information.
     * @dev Each BatchOrder contains a head and tail value which effectively,
     *      which means BatchOrders are connected using a doubley linked list.
     */
    mapping(uint256 => BatchOrder) public orderBook;

    /**
     * @notice Chainlink Automation Registrar contract.
     */
    IKeeperRegistrar public registrar; // Mainnet 0xDb8e8e2ccb5C033938736aa89Fe4fa1eDfD15a1d

    /**
     * @notice Whether or not the contract is shutdown in case of an emergency.
     */
    bool public isShutdown;

    /**
     * @notice Chainlink Fast Gas Feed for ETH Mainnet.
     */
    address public fastGasFeed = 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C;

    /**
     * @notice The max possible gas the owner can set for the gas limit.
     */
    uint32 public constant MAX_GAS_LIMIT = 500_000;

    /**
     * @notice The max possible gas price the owner can set for the gas price.
     * @dev In units of gwei.
     */
    uint32 public constant MAX_GAS_PRICE = 1_000;

    /**
     * @notice The max number of orders that can be fulfilled in a single upkeep TX.
     */
    uint16 public constant MAX_FILLS_PER_UPKEEP = 20;

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Prevent a function from being called during a shutdown.
     */
    modifier whenNotShutdown() {
        if (isShutdown) revert LimitOrderRegistry__ContractShutdown();

        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event NewOrder(address user, address pool, uint128 amount, uint128 userTotal, BatchOrder effectedOrder);
    event ClaimOrder(address user, uint128 batchId, uint256 amount);
    event CancelOrder(address user, uint128 amount0, uint128 amount1, BatchOrder effectedOrder);
    event OrderFilled(uint256 batchId, address pool);
    event ShutdownChanged(bool isShutdown);
    event LimitOrderSetup(address pool);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error LimitOrderRegistry__OrderITM(int24 currentTick, int24 targetTick, bool direction);
    error LimitOrderRegistry__PoolAlreadySetup(address pool);
    error LimitOrderRegistry__PoolNotSetup(address pool);
    error LimitOrderRegistry__InvalidTargetTick(int24 targetTick, int24 tickSpacing);
    error LimitOrderRegistry__UserNotFound(address user, uint256 batchId);
    error LimitOrderRegistry__InvalidPositionId();
    error LimitOrderRegistry__NoLiquidityInOrder();
    error LimitOrderRegistry__NoOrdersToFulfill();
    error LimitOrderRegistry__CenterITM();
    error LimitOrderRegistry__OrderNotInList(uint256 tokenId);
    error LimitOrderRegistry__MinimumNotSet(address asset);
    error LimitOrderRegistry__MinimumNotMet(address asset, uint256 minimum, uint256 amount);
    error LimitOrderRegistry__InvalidTickRange(int24 upper, int24 lower);
    error LimitOrderRegistry__ZeroFeesToWithdraw(address token);
    error LimitOrderRegistry__ZeroNativeBalance();
    error LimitOrderRegistry__InvalidBatchId();
    error LimitOrderRegistry__OrderNotReadyToClaim(uint128 batchId);
    error LimitOrderRegistry__ContractShutdown();
    error LimitOrderRegistry__ContractNotShutdown();
    error LimitOrderRegistry__InvalidGasLimit();
    error LimitOrderRegistry__InvalidGasPrice();
    error LimitOrderRegistry__InvalidFillsPerUpkeep();

    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/

    enum OrderStatus {
        ITM,
        OTM,
        MIXED
    }

    /*//////////////////////////////////////////////////////////////
                              IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable WRAPPED_NATIVE; // Mainnet 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

    NonfungiblePositionManager public immutable POSITION_MANAGER; // Mainnet 0xC36442b4a4522E871399CD717aBDD847Ab11FE88

    LinkTokenInterface public immutable LINK; // Mainnet 0x514910771AF9Ca656af840dff83E8264EcF986CA

    constructor(
        address _owner,
        NonfungiblePositionManager _positionManager,
        ERC20 wrappedNative,
        LinkTokenInterface link,
        IKeeperRegistrar _registrar,
        address _fastGasFeed
    ) Owned(_owner) {
        POSITION_MANAGER = _positionManager;
        WRAPPED_NATIVE = wrappedNative;
        LINK = link;
        registrar = _registrar;
        fastGasFeed = _fastGasFeed;
    }

    /*//////////////////////////////////////////////////////////////
                              OWNER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice No input validation is done because it is in the owners best interest to choose a valid registrar.
     */
    function setRegistrar(IKeeperRegistrar _registrar) external onlyOwner {
        registrar = _registrar;
    }

    /**
     * @notice Allows owner to set the fills per upkeep.
     */
    function setMaxFillsPerUpkeep(uint16 newVal) external onlyOwner {
        if (newVal == 0 || newVal > MAX_FILLS_PER_UPKEEP) revert LimitOrderRegistry__InvalidFillsPerUpkeep();
        maxFillsPerUpkeep = newVal;
    }

    /**
     * @notice Allows owner to setup a new limit order for a new pool.
     * @dev New Limit orders, should have a keeper to fulfill orders.
     * @dev If `initialUpkeepFunds` is zero, upkeep creation is skipped.
     */
    function setupLimitOrder(UniswapV3Pool pool, uint256 initialUpkeepFunds) external onlyOwner {
        // Check if Limit Order is already setup for `pool`.
        if (address(poolToData[pool].token0) != address(0)) revert LimitOrderRegistry__PoolAlreadySetup(address(pool));

        // Create Upkeep.
        if (initialUpkeepFunds > 0) {
            // Owner wants to automatically create an upkeep for new pool.
            // SafeTransferLib.safeTransferFrom(ERC20(address(LINK)), owner, address(this), initialUpkeepFunds);
            ERC20(address(LINK)).safeTransferFrom(owner, address(this), initialUpkeepFunds);
            ERC20(address(LINK)).safeApprove(address(registrar), initialUpkeepFunds);
            RegistrationParams memory params = RegistrationParams({
                name: "Limit Order Registry",
                encryptedEmail: abi.encode(0),
                upkeepContract: address(this),
                gasLimit: uint32(maxFillsPerUpkeep * upkeepGasLimit),
                adminAddress: owner,
                checkData: abi.encode(pool),
                offchainConfig: abi.encode(0),
                amount: uint96(initialUpkeepFunds)
            });
            registrar.registerUpkeep(params);
        }

        // poolToData
        poolToData[pool] = PoolData({
            centerHead: 0,
            centerTail: 0,
            token0: ERC20(pool.token0()),
            token1: ERC20(pool.token1()),
            fee: pool.fee()
        });

        emit LimitOrderSetup(address(pool));
    }

    /**
     * @notice Allows owner to set the minimum assets used to create `newOrder`s.
     * @dev This value can be zero, but then this contract can be griefed by an attacker spamming low liquidity orders.
     */
    function setMinimumAssets(uint256 amount, ERC20 asset) external onlyOwner {
        minimumAssets[asset] = amount;
    }

    /**
     * @notice Allows owner to change the gas limit value used to determine the Native asset fee needed to claim orders.
     * @dev premium should be factored into this value.
     */
    function setUpkeepGasLimit(uint32 gasLimit) external onlyOwner {
        if (gasLimit > MAX_GAS_LIMIT) revert LimitOrderRegistry__InvalidGasLimit();
        upkeepGasLimit = gasLimit;
    }

    /**
     * @notice Allows owner to change the gas price used to determine the Native asset fee needed to claim orders.
     * @dev `gasPrice` uses units of gwei.
     */
    function setUpkeepGasPrice(uint32 gasPrice) external onlyOwner {
        if (gasPrice > MAX_GAS_PRICE) revert LimitOrderRegistry__InvalidGasPrice();
        upkeepGasPrice = gasPrice;
    }

    /**
     * @notice Allows owner to set the fast gas feed.
     */
    function setFastGasFeed(address feed) external onlyOwner {
        fastGasFeed = feed;
    }

    /**
     * @notice Allows owner to withdraw swap fees earned from the input token of orders.
     */
    function withdrawSwapFees(address tokenFeeIsIn) external onlyOwner {
        uint256 fee = tokenToSwapFees[tokenFeeIsIn];

        // Make sure there are actually fees to withdraw.
        if (fee == 0) revert LimitOrderRegistry__ZeroFeesToWithdraw(tokenFeeIsIn);

        tokenToSwapFees[tokenFeeIsIn] = 0;
        ERC20(tokenFeeIsIn).safeTransfer(owner, fee);
    }

    /**
     * @notice Allows owner to withdraw wrapped native and native assets from this contract.
     */
    function withdrawNative() external onlyOwner {
        uint256 wrappedNativeBalance = WRAPPED_NATIVE.balanceOf(address(this));
        uint256 nativeBalance = address(this).balance;
        // Make sure there is something to withdraw.
        if (wrappedNativeBalance == 0 && nativeBalance == 0) revert LimitOrderRegistry__ZeroNativeBalance();
        WRAPPED_NATIVE.safeTransfer(owner, WRAPPED_NATIVE.balanceOf(address(this)));
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @notice Shutdown the cellar. Used in an emergency or if the cellar has been deprecated.
     */
    function initiateShutdown() external whenNotShutdown onlyOwner {
        isShutdown = true;

        emit ShutdownChanged(true);
    }

    /**
     * @notice Restart the cellar.
     */
    function liftShutdown() external onlyOwner {
        if (!isShutdown) revert LimitOrderRegistry__ContractNotShutdown();
        isShutdown = false;

        emit ShutdownChanged(false);
    }

    /*//////////////////////////////////////////////////////////////
                        USER ORDER MANAGEMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new limit order for a specific pool.
     * @dev Limit orders can be created to buy either token0, or token1 of the pool.
     * @param pool the Uniswap V3 pool to create a limit order on.
     * @param targetTick the tick, that when `pool`'s tick passes, the order will be completely fulfilled
     * @param amount the amount of the input token to sell for the desired token out
     * @param direction bool indicating what the desired token out is
     *                  - true  token in = token0 ; token out = token1
     *                  - false token in = token1 ; token out = token0
     * @param startingNode an NFT position id indicating where this contract should start searching for a spot in the list
     *                     - can be zero which defaults to starting the search at center of list
     * @dev reverts if
     *      - pool is not setup
     *      - targetTick is not divisible by the pools tick spacing
     *      - the new order would be ITM
     *      - the new order does not meet minimum liquidity requirements
     *      - transferFrom fails

     * @dev Emits a `NewOrder` event which contains meta data about the order including the orders `batchId`(which is used for claiming/cancelling).
     */
    function newOrder(
        UniswapV3Pool pool,
        int24 targetTick,
        uint128 amount,
        bool direction,
        uint256 startingNode
    ) external whenNotShutdown returns (uint128) {
        if (address(poolToData[pool].token0) == address(0)) revert LimitOrderRegistry__PoolNotSetup(address(pool));

        OrderDetails memory details;
        address sender = _msgSender();

        (, details.tick, , , , , ) = pool.slot0();

        // Determine upper and lower ticks.
        {
            int24 tickSpacing = pool.tickSpacing();
            // Make sure targetTick is divisible by spacing.
            if (targetTick % tickSpacing != 0) revert LimitOrderRegistry__InvalidTargetTick(targetTick, tickSpacing);
            if (direction) {
                details.upper = targetTick;
                details.lower = targetTick - tickSpacing;
            } else {
                details.upper = targetTick + tickSpacing;
                details.lower = targetTick;
            }
        }
        // Validate lower, upper,and direction.
        {
            OrderStatus status = _getOrderStatus(details.tick, details.lower, details.upper, direction);
            if (status != OrderStatus.OTM) revert LimitOrderRegistry__OrderITM(details.tick, targetTick, direction);
        }

        // Transfer assets into contract before setting any state.
        {
            ERC20 assetIn;
            if (direction) assetIn = poolToData[pool].token0;
            else assetIn = poolToData[pool].token1;
            _enforceMinimumLiquidity(amount, assetIn);
            assetIn.safeTransferFrom(sender, address(this), amount);
        }

        // Get the position id.
        details.positionId = getPositionFromTicks[details.lower][details.upper];

        if (direction) details.amount0 = amount;
        else details.amount1 = amount;
        if (details.positionId == 0) {
            // Create new LP position(which adds liquidity)
            PoolData memory data = poolToData[pool];
            details.positionId = _mintPosition(
                data,
                details.upper,
                details.lower,
                details.amount0,
                details.amount1,
                direction
            );

            // Add it to the list.
            _addPositionToList(data, startingNode, targetTick, details.positionId);

            // Set new orders upper and lower tick.
            orderBook[details.positionId].tickLower = details.lower;
            orderBook[details.positionId].tickUpper = details.upper;

            // Setup BatchOrder, setting batchId, direction.
            _setupOrder(direction, details.positionId);

            // Update token0Amount, token1Amount, batchIdToUserDepositAmount mapping.
            details.userTotal = _updateOrder(details.positionId, sender, amount);

            // Update the center values if need be.
            _updateCenter(pool, details.positionId, details.tick, details.upper, details.lower);

            // Update getPositionFromTicks since we have a new LP position.
            getPositionFromTicks[details.lower][details.upper] = details.positionId;
        } else {
            // Check if the position id is already being used in List.
            BatchOrder memory order = orderBook[details.positionId];
            if (order.token0Amount > 0 || order.token1Amount > 0) {
                // Need to add liquidity.
                PoolData memory data = poolToData[pool];
                _addToPosition(data, details.positionId, details.amount0, details.amount1, direction);

                // Update token0Amount, token1Amount, batchIdToUserDepositAmount mapping.
                details.userTotal = _updateOrder(details.positionId, sender, amount);
            } else {
                // We already have an LP position with given tick ranges, but it is not in linked list.
                PoolData memory data = poolToData[pool];

                // Add it to the list.
                _addPositionToList(data, startingNode, targetTick, details.positionId);

                // Setup BatchOrder, setting batchId, direction.
                _setupOrder(direction, details.positionId);

                // Need to add liquidity.
                _addToPosition(data, details.positionId, details.amount0, details.amount1, direction);

                // Update token0Amount, token1Amount, batchIdToUserDepositAmount mapping.
                details.userTotal = _updateOrder(details.positionId, sender, amount);

                // Update the center values if need be.
                _updateCenter(pool, details.positionId, details.tick, details.upper, details.lower);
            }
        }
        uint128 batchId = orderBook[details.positionId].batchId;
        emit NewOrder(sender, address(pool), amount, details.userTotal, orderBook[details.positionId]);
        return batchId;
    }

    /**
     * @notice Users can claim fulfilled orders by passing in the `batchId` corresponding to the order they want to claim.
     * @param batchId the batchId corresponding to a fulfilled order to claim
     * @param user the address of the user in the order to claim for
     * @dev Caller must either approve this contract to spend their Wrapped Native token, and have at least `getFeePerUser` tokens in their wallet.
     *      Or caller must send `getFeePerUser` value with this call.
     */
    function claimOrder(uint128 batchId, address user) external payable returns (ERC20, uint256) {
        Claim storage userClaim = claim[batchId];
        if (!userClaim.isReadyForClaim) revert LimitOrderRegistry__OrderNotReadyToClaim(batchId);
        uint256 depositAmount = batchIdToUserDepositAmount[batchId][user];
        if (depositAmount == 0) revert LimitOrderRegistry__UserNotFound(user, batchId);

        // Zero out user balance.
        delete batchIdToUserDepositAmount[batchId][user];

        // Calculate owed amount.
        uint256 totalTokenDeposited;
        uint256 totalTokenOut;
        ERC20 tokenOut;
        if (userClaim.direction) {
            totalTokenDeposited = userClaim.token0Amount;
            totalTokenOut = userClaim.token1Amount;
            tokenOut = poolToData[userClaim.pool].token1;
        } else {
            totalTokenDeposited = userClaim.token1Amount;
            totalTokenOut = userClaim.token0Amount;
            tokenOut = poolToData[userClaim.pool].token0;
        }

        uint256 owed = (totalTokenOut * depositAmount) / totalTokenDeposited;

        // Transfer tokens owed to user.
        tokenOut.safeTransfer(user, owed);

        // Transfer fee in.
        address sender = _msgSender();
        if (msg.value >= userClaim.feePerUser) {
            // refund if necessary.
            uint256 refund = msg.value - userClaim.feePerUser;
            if (refund > 0) payable(sender).transfer(refund);
        } else {
            WRAPPED_NATIVE.safeTransferFrom(sender, address(this), userClaim.feePerUser);
            // If value is non zero send it back to caller.
            if (msg.value > 0) payable(sender).transfer(msg.value);
        }
        emit ClaimOrder(user, batchId, owed);
        return (tokenOut, owed);
    }

    /**
     * @notice Allows users to cancel orders as long as they are completely OTM.
     * @param pool the Uniswap V3 pool that contains the limit order to cancel
     * @param targetTick the targetTick of the order you want to cancel
     * @param direction bool indication the direction of the order
     * @dev This logic will send ALL the swap fees from a position to the last person that cancels the order.
     */
    function cancelOrder(
        UniswapV3Pool pool,
        int24 targetTick,
        bool direction
    ) external returns (uint128 amount0, uint128 amount1, uint128 batchId) {
        uint256 positionId;
        {
            // Make sure order is OTM.
            (, int24 tick, , , , , ) = pool.slot0();

            // Determine upper and lower ticks.
            int24 upper;
            int24 lower;
            {
                int24 tickSpacing = pool.tickSpacing();
                // Make sure targetTick is divisible by spacing.
                if (targetTick % tickSpacing != 0)
                    revert LimitOrderRegistry__InvalidTargetTick(targetTick, tickSpacing);
                if (direction) {
                    upper = targetTick;
                    lower = targetTick - tickSpacing;
                } else {
                    upper = targetTick + tickSpacing;
                    lower = targetTick;
                }
            }
            // Validate lower, upper,and direction.
            {
                OrderStatus status = _getOrderStatus(tick, lower, upper, direction);
                if (status != OrderStatus.OTM) revert LimitOrderRegistry__OrderITM(tick, targetTick, direction);
            }

            // Get the position id.
            positionId = getPositionFromTicks[lower][upper];

            if (positionId == 0) revert LimitOrderRegistry__InvalidPositionId();
        }

        uint256 liquidityPercentToTake;

        // Get the users deposit amount in the order.
        BatchOrder storage order = orderBook[positionId];
        if (order.batchId == 0) revert LimitOrderRegistry__InvalidBatchId();
        address sender = _msgSender();
        {
            batchId = order.batchId;
            uint128 depositAmount = batchIdToUserDepositAmount[batchId][sender];
            if (depositAmount == 0) revert LimitOrderRegistry__UserNotFound(sender, batchId);

            // Remove one from the userCount.
            order.userCount--;

            // Zero out user balance.
            delete batchIdToUserDepositAmount[batchId][sender];

            uint128 orderAmount;
            if (order.direction) {
                orderAmount = order.token0Amount;
                if (orderAmount == depositAmount) {
                    liquidityPercentToTake = 1e18;
                    // Update order tokenAmount.
                    order.token0Amount = 0;
                } else {
                    liquidityPercentToTake = (1e18 * depositAmount) / orderAmount;
                    // Update order tokenAmount.
                    order.token0Amount = orderAmount - depositAmount;
                }
            } else {
                orderAmount = order.token1Amount;
                if (orderAmount == depositAmount) {
                    liquidityPercentToTake = 1e18;
                    // Update order tokenAmount.
                    order.token1Amount = 0;
                } else {
                    liquidityPercentToTake = (1e18 * depositAmount) / orderAmount;
                    // Update order tokenAmount.
                    order.token1Amount = orderAmount - depositAmount;
                }
            }

            (amount0, amount1) = _takeFromPosition(positionId, pool, liquidityPercentToTake);
            if (liquidityPercentToTake == 1e18) {
                _removeOrderFromList(positionId, pool, order);
                // Zero out balances for cancelled order.
                order.token0Amount = 0;
                order.token1Amount = 0;
                order.batchId = 0;
            }
        }
        if (order.direction) {
            if (amount0 > 0) poolToData[pool].token0.safeTransfer(sender, amount0);
            else revert LimitOrderRegistry__NoLiquidityInOrder();
            // Save any swap fees.
            if (amount1 > 0) tokenToSwapFees[address(poolToData[pool].token1)] += amount1;
        } else {
            if (amount1 > 0) poolToData[pool].token1.safeTransfer(sender, amount1);
            else revert LimitOrderRegistry__NoLiquidityInOrder();
            // Save any swap fees.
            if (amount0 > 0) tokenToSwapFees[address(poolToData[pool].token0)] += amount0;
        }
        emit CancelOrder(sender, amount0, amount1, order);
    }

    /*//////////////////////////////////////////////////////////////
                     CHAINLINK AUTOMATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returned `performData` simply contains a bool indicating which direction in the `orderBook` has orders that need to be fulfilled.
     */
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData) {
        UniswapV3Pool pool = abi.decode(checkData, (UniswapV3Pool));
        (, int24 currentTick, , , , , ) = pool.slot0();
        PoolData memory data = poolToData[pool];
        BatchOrder memory order;
        OrderStatus status;
        bool walkDirection;

        if (data.centerHead != 0) {
            // centerHead is set, check if it is ITM.
            order = orderBook[data.centerHead];
            status = _getOrderStatus(currentTick, order.tickLower, order.tickUpper, order.direction);
            if (status == OrderStatus.ITM) {
                walkDirection = true; // Walk towards head of list.
                upkeepNeeded = true;
                performData = abi.encode(pool, walkDirection);
                return (upkeepNeeded, performData);
            }
        }
        if (data.centerTail != 0) {
            // If walk direction has not been set, then we know, no head orders are ITM.
            // So check tail orders.
            order = orderBook[data.centerTail];
            status = _getOrderStatus(currentTick, order.tickLower, order.tickUpper, order.direction);
            if (status == OrderStatus.ITM) {
                walkDirection = false; // Walk towards tail of list.
                upkeepNeeded = true;
                performData = abi.encode(pool, walkDirection);
                return (upkeepNeeded, performData);
            }
        }
        return (false, abi.encode(0));
    }

    /**
     * @notice Callable by anyone, as long as there are orders ITM, that need to be fulfilled.
     * @dev Does not use _removeOrderFromList, so that the center head/tail
     *      value is not updated every single time and order is fulfilled, instead we just update it once at the end.
     */
    function performUpkeep(bytes calldata performData) external {
        (UniswapV3Pool pool, bool walkDirection) = abi.decode(performData, (UniswapV3Pool, bool));

        if (address(poolToData[pool].token0) == address(0)) revert LimitOrderRegistry__PoolNotSetup(address(pool));

        PoolData storage data = poolToData[pool];

        // Estimate gas cost.
        uint256 estimatedFee = uint256(upkeepGasLimit * getGasPrice());

        (, int24 currentTick, , , , , ) = pool.slot0();
        bool orderFilled;
        uint128 totalToken0Fees;
        uint128 totalToken1Fees;

        // Fulfill orders.
        uint256 target = walkDirection ? data.centerHead : data.centerTail;
        for (uint256 i; i < maxFillsPerUpkeep; ++i) {
            if (target == 0) break;
            BatchOrder storage order = orderBook[target];
            OrderStatus status = _getOrderStatus(currentTick, order.tickLower, order.tickUpper, order.direction);
            if (status == OrderStatus.ITM) {
                (uint128 token0Fees, uint128 token1Fees) = _fulfillOrder(target, pool, order, estimatedFee);
                totalToken0Fees += token0Fees;
                totalToken1Fees += token1Fees;
                target = walkDirection ? order.head : order.tail;
                // Zero out orders head and tail values removing order from the list.
                order.head = 0;
                order.tail = 0;
                // Update bool to indicate batch order is ready to handle claims.
                claim[order.batchId].isReadyForClaim = true;
                // Zero out orders batch id.
                order.batchId = 0;
                // Reset user count.
                order.userCount = 0;
                orderFilled = true;
                emit OrderFilled(order.batchId, address(pool));
            } else break;
        }

        if (!orderFilled) revert LimitOrderRegistry__NoOrdersToFulfill();

        // Save fees.
        if (totalToken0Fees > 0) tokenToSwapFees[address(poolToData[pool].token0)] += totalToken0Fees;
        if (totalToken1Fees > 0) tokenToSwapFees[address(poolToData[pool].token1)] += totalToken1Fees;

        // Update center.
        if (walkDirection) {
            data.centerHead = target;
            // Need to reconnect list.
            orderBook[data.centerTail].head = target;
            if (target != 0) orderBook[target].tail = data.centerTail;
        } else {
            data.centerTail = target;
            // Need to reconnect list.
            orderBook[data.centerHead].tail = target;
            if (target != 0) orderBook[target].head = data.centerHead;
        }
    }

    /*//////////////////////////////////////////////////////////////
                     INTERNAL ORDER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if a given Uniswap V3 position is already in the `orderBook`.
     * @dev Looks at Nodes head and tail, and checks for edge case of node being the only node in the `orderBook`
     */
    function _checkThatNodeIsInList(uint256 node, BatchOrder memory order, PoolData memory data) internal pure {
        if (order.head == 0 && order.tail == 0) {
            // Possible but the order may be centerTail or centerHead.
            if (data.centerHead != node && data.centerTail != node) revert LimitOrderRegistry__OrderNotInList(node);
        }
    }

    /**
     * @notice Finds appropriate spot in `orderBook` for an order.
     */
    function _findSpot(
        PoolData memory data,
        uint256 startingNode,
        int24 targetTick
    ) internal view returns (uint256 proposedHead, uint256 proposedTail) {
        BatchOrder memory node;
        if (startingNode == 0) {
            if (data.centerHead != 0) {
                startingNode = data.centerHead;
                node = orderBook[startingNode];
            } else if (data.centerTail != 0) {
                startingNode = data.centerTail;
                node = orderBook[startingNode];
            } else return (0, 0);
        } else {
            node = orderBook[startingNode];
            _checkThatNodeIsInList(startingNode, node, data);
        }
        uint256 nodeId = startingNode;
        bool direction = targetTick > node.tickUpper ? true : false;
        while (true) {
            if (direction) {
                // Go until we find an order with a tick lower GREATER or equal to targetTick, then set proposedTail equal to the tail, and proposed head to the current node.
                if (node.tickLower >= targetTick) {
                    return (nodeId, node.tail);
                } else if (node.head == 0) {
                    // Made it to head of list.
                    return (0, nodeId);
                } else {
                    nodeId = node.head;
                    node = orderBook[nodeId];
                }
            } else {
                // Go until we find tick upper that is LESS than or equal to targetTick
                if (node.tickUpper <= targetTick) {
                    return (node.head, nodeId);
                } else if (node.tail == 0) {
                    // Made it to the tail of the list.
                    return (nodeId, 0);
                } else {
                    nodeId = node.tail;
                    node = orderBook[nodeId];
                }
            }
        }
    }

    /**
     * @notice Checks if newly added order should be made the new center head/tail.
     */
    function _updateCenter(
        UniswapV3Pool pool,
        uint256 positionId,
        int24 currentTick,
        int24 upper,
        int24 lower
    ) internal {
        PoolData memory data = poolToData[pool];
        if (currentTick > upper) {
            // Check if centerTail needs to be updated.
            if (data.centerTail == 0) {
                // Currently no centerTail, so this order must become it.
                poolToData[pool].centerTail = positionId;
            } else {
                BatchOrder memory centerTail = orderBook[data.centerTail];
                if (upper > centerTail.tickUpper) {
                    // New position is closer to the current pool tick, so it becomes new centerTail.
                    poolToData[pool].centerTail = positionId;
                }
                // else nothing to do.
            }
        } else if (currentTick < lower) {
            // Check if centerHead needs to be updated.
            if (data.centerHead == 0) {
                // Currently no centerHead, so this order must become it.
                poolToData[pool].centerHead = positionId;
            } else {
                BatchOrder memory centerHead = orderBook[data.centerHead];
                if (lower < centerHead.tickLower) {
                    // New position is closer to the current pool tick, so it becomes new centerHead.
                    poolToData[pool].centerHead = positionId;
                }
                // else nothing to do.
            }
        }
    }

    /**
     * @notice Add a Uniswap V3 LP position to the `orderBook`.
     */
    function _addPositionToList(
        PoolData memory data,
        uint256 startingNode,
        int24 targetTick,
        uint256 position
    ) internal {
        (uint256 head, uint256 tail) = _findSpot(data, startingNode, targetTick);
        if (tail != 0) {
            orderBook[tail].head = position;
            orderBook[position].tail = tail;
        }
        if (head != 0) {
            orderBook[head].tail = position;
            orderBook[position].head = head;
        }
    }

    /**
     * @notice Setup a newly minted LP position, or one being reused.
     * @dev Sets batchId, and direction.
     */
    function _setupOrder(bool direction, uint256 position) internal {
        BatchOrder storage order = orderBook[position];
        order.batchId = batchCount;
        order.direction = direction;
        batchCount++;
    }

    /**
     * @notice Updates a BatchOrder's token0/token1 amount, as well as associated
     *         `batchIdToUserDepositAmount` mapping value.
     * @dev If user is new to the order, increment userCount.
     */
    function _updateOrder(uint256 positionId, address user, uint128 amount) internal returns (uint128 userTotal) {
        BatchOrder storage order = orderBook[positionId];
        if (order.direction) {
            // token1
            order.token0Amount += amount;
        } else {
            // token0
            order.token1Amount += amount;
        }

        // Check if user is already in the order.
        uint128 batchId = order.batchId;
        uint128 originalDepositAmount = batchIdToUserDepositAmount[batchId][user];
        // If this is a new user in the order, add 1 to userCount.
        if (originalDepositAmount == 0) order.userCount++;
        batchIdToUserDepositAmount[batchId][user] = originalDepositAmount + amount;
        return (originalDepositAmount + amount);
    }

    /**
     * @notice Mints a new Uniswap V3 LP position.
     */
    function _mintPosition(
        PoolData memory data,
        int24 upper,
        int24 lower,
        uint128 amount0,
        uint128 amount1,
        bool direction
    ) internal returns (uint256) {
        if (direction) data.token0.safeApprove(address(POSITION_MANAGER), amount0);
        else data.token1.safeApprove(address(POSITION_MANAGER), amount1);

        // 0.9999e18 accounts for rounding errors in the Uniswap V3 protocol.
        uint128 amount0Min = amount0 == 0 ? 0 : (amount0 * 0.9999e18) / 1e18;
        uint128 amount1Min = amount1 == 0 ? 0 : (amount1 * 0.9999e18) / 1e18;

        // Create mint params.
        NonfungiblePositionManager.MintParams memory params = NonfungiblePositionManager.MintParams({
            token0: address(data.token0),
            token1: address(data.token1),
            fee: data.fee,
            tickLower: lower,
            tickUpper: upper,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            recipient: address(this),
            deadline: block.timestamp
        });

        // Supply liquidity to pool.
        (uint256 tokenId, , , ) = POSITION_MANAGER.mint(params);

        // Revert if tokenId received is 0 id.
        // Zero token id is reserved for NULL values in linked list.
        if (tokenId == 0) revert LimitOrderRegistry__InvalidPositionId();

        // If position manager still has allowance, zero it out.
        if (direction && data.token0.allowance(address(this), address(POSITION_MANAGER)) > 0)
            data.token0.safeApprove(address(POSITION_MANAGER), 0);
        if (!direction && data.token1.allowance(address(this), address(POSITION_MANAGER)) > 0)
            data.token1.safeApprove(address(POSITION_MANAGER), 0);

        return tokenId;
    }

    /**
     * @notice Adds liquidity to a given `positionId`.
     */
    function _addToPosition(
        PoolData memory data,
        uint256 positionId,
        uint128 amount0,
        uint128 amount1,
        bool direction
    ) internal {
        if (direction) data.token0.safeApprove(address(POSITION_MANAGER), amount0);
        else data.token1.safeApprove(address(POSITION_MANAGER), amount1);

        uint128 amount0Min = amount0 == 0 ? 0 : (amount0 * 0.9999e18) / 1e18;
        uint128 amount1Min = amount1 == 0 ? 0 : (amount1 * 0.9999e18) / 1e18;

        // Create increase liquidity params.
        NonfungiblePositionManager.IncreaseLiquidityParams memory params = NonfungiblePositionManager
            .IncreaseLiquidityParams({
                tokenId: positionId,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: amount0Min,
                amount1Min: amount1Min,
                deadline: block.timestamp
            });

        // Increase liquidity in pool.
        POSITION_MANAGER.increaseLiquidity(params);

        // If position manager still has allowance, zero it out.
        if (direction && data.token0.allowance(address(this), address(POSITION_MANAGER)) > 0)
            data.token0.safeApprove(address(POSITION_MANAGER), 0);
        if (!direction && data.token1.allowance(address(this), address(POSITION_MANAGER)) > 0)
            data.token1.safeApprove(address(POSITION_MANAGER), 0);
    }

    /**
     * @notice Enforces minimum liquidity requirements for orders.
     */
    function _enforceMinimumLiquidity(uint256 amount, ERC20 asset) internal view {
        uint256 minimum = minimumAssets[asset];
        if (minimum == 0) revert LimitOrderRegistry__MinimumNotSet(address(asset));
        if (amount < minimum) revert LimitOrderRegistry__MinimumNotMet(address(asset), minimum, amount);
    }

    /**
     * @notice Helper function to determine an orders status.
     * @dev Returns
     *      - ITM if order is ready to be filled, and is composed of wanted asset
     *      - OTM if order is not ready to be filled, but order can still be cancelled, because order is composed of asset to sell
     *      - MIXED order is composed of both wanted asset, and asset to sell, can not be fulfilled or cancelled.
     */
    function _getOrderStatus(
        int24 currentTick,
        int24 lower,
        int24 upper,
        bool direction
    ) internal pure returns (OrderStatus status) {
        if (upper == lower) revert LimitOrderRegistry__InvalidTickRange(upper, lower);
        if (direction) {
            // Indicates we want to go lower -> upper.
            if (currentTick > upper) return OrderStatus.ITM;
            if (currentTick >= lower) return OrderStatus.MIXED;
            else return OrderStatus.OTM;
        } else {
            // Indicates we want to go upper -> lower.
            if (currentTick < lower) return OrderStatus.ITM;
            if (currentTick <= upper) return OrderStatus.MIXED;
            else return OrderStatus.OTM;
        }
    }

    /**
     * @notice Called during `performUpkeep` to fulfill an ITM order.
     * @dev Sets Claim info, removes all liquidity from position, and zeroes out BatchOrder amount0 and amount1 values.
     */
    function _fulfillOrder(
        uint256 target,
        UniswapV3Pool pool,
        BatchOrder storage order,
        uint256 estimatedFee
    ) internal returns (uint128 token0Fees, uint128 token1Fees) {
        // Save fee per user in Claim Struct.
        uint256 totalUsers = order.userCount;
        Claim storage newClaim = claim[order.batchId];
        newClaim.feePerUser = uint128(estimatedFee / totalUsers);
        newClaim.pool = pool;

        // Take all liquidity from the order.
        (uint128 amount0, uint128 amount1) = _takeFromPosition(target, pool, 1e18);
        if (order.direction) {
            // Copy the tokenIn amount from the order, this is the total user deposit.
            newClaim.token0Amount = order.token0Amount;
            // Total amount received is the difference in balance.
            newClaim.token1Amount = amount1;

            // Record any extra swap fees pool earned.
            token0Fees = amount0;
        } else {
            // Copy the tokenIn amount from the order, this is the total user deposit.
            newClaim.token1Amount = order.token1Amount;
            // Total amount received is the difference in balance.
            newClaim.token0Amount = amount0;

            // Record any extra swap fees pool earned.
            token1Fees = amount1;
        }
        newClaim.direction = order.direction;

        // Zero out order balances.
        order.token0Amount = 0;
        order.token1Amount = 0;
    }

    /**
     * @notice Removes liquidity from `target` Uniswap V3 LP position.
     * @dev Collects fees from `target` position.
     */
    function _takeFromPosition(
        uint256 target,
        UniswapV3Pool pool,
        uint256 liquidityPercent
    ) internal returns (uint128, uint128) {
        (, , , , , , , uint128 liquidity, , , , ) = POSITION_MANAGER.positions(target);
        liquidity = uint128(uint256(liquidity * liquidityPercent) / 1e18);

        // Create decrease liquidity params.
        NonfungiblePositionManager.DecreaseLiquidityParams memory params = NonfungiblePositionManager
            .DecreaseLiquidityParams({
                tokenId: target,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        // Decrease liquidity in pool.
        uint128 amount0;
        uint128 amount1;
        {
            (uint256 a0, uint256 a1) = POSITION_MANAGER.decreaseLiquidity(params);
            amount0 = uint128(a0);
            amount1 = uint128(a1);
        }

        // If completely closing position, then collect fees as well.
        uint128 amount0Max;
        uint128 amount1Max;
        if (liquidityPercent == 1e18) {
            amount0Max = type(uint128).max;
            amount1Max = type(uint128).max;
        } else {
            // Otherwise only collect principal.
            amount0Max = amount0;
            amount1Max = amount1;
        }
        // Create fee collection params.
        NonfungiblePositionManager.CollectParams memory collectParams = NonfungiblePositionManager.CollectParams({
            tokenId: target,
            recipient: address(this),
            amount0Max: amount0Max,
            amount1Max: amount1Max
        });

        // Save token balances.
        ERC20 token0 = poolToData[pool].token0;
        ERC20 token1 = poolToData[pool].token1;
        uint256 token0Balance = token0.balanceOf(address(this));
        uint256 token1Balance = token1.balanceOf(address(this));

        // Collect fees.
        POSITION_MANAGER.collect(collectParams);

        amount0 = uint128(token0.balanceOf(address(this)) - token0Balance);
        amount1 = uint128(token1.balanceOf(address(this)) - token1Balance);

        return (amount0, amount1);
    }

    /**
     * @notice Removes an order from the `orderBook`.
     * @dev Checks if order is one of the center values, and updates the head if need be.
     */
    function _removeOrderFromList(uint256 target, UniswapV3Pool pool, BatchOrder storage order) internal {
        // Checks if order is the center, if so then it will set it to the the center orders head(which is okay if it is zero).
        uint256 centerHead = poolToData[pool].centerHead;
        uint256 centerTail = poolToData[pool].centerTail;

        if (target == centerHead) {
            uint256 newHead = orderBook[centerHead].head;
            poolToData[pool].centerHead = newHead;
        } else if (target == centerTail) {
            uint256 newTail = orderBook[centerTail].tail;
            poolToData[pool].centerTail = newTail;
        }

        // Remove order from linked list.
        orderBook[order.tail].head = order.head;
        orderBook[order.head].tail = order.tail;
        order.head = 0;
        order.tail = 0;
    }

    /**
     * @notice Helper function to get the gas price used for fee calculation.
     */
    function getGasPrice() public view returns (uint256) {
        // If gas feed is set use it.
        if (fastGasFeed != address(0)) return uint256(IChainlinkAggregator(fastGasFeed).latestAnswer());
        // Else use owner set value.
        return uint256(upkeepGasPrice) * 1e9; // Multiply by 1e9 to convert gas price to gwei
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Helper function that finds the appropriate spot in the linked list for a new order.
     * @param pool the Uniswap V3 pool you want to create an order in
     * @param startingNode the UniV3 position Id to start looking
     * @param targetTick the targetTick of the order you want to place
     * @return proposedHead , proposedTail pr the correct head and tail for the new order
     * @dev if both head and tail are zero, just pass in zero for the `startingNode`
     *      otherwise pass in either the nonzero head or nonzero tail for the `startingNode`
     */
    function findSpot(
        UniswapV3Pool pool,
        uint256 startingNode,
        int24 targetTick
    ) external view returns (uint256 proposedHead, uint256 proposedTail) {
        PoolData memory data = poolToData[pool];

        int24 tickSpacing = pool.tickSpacing();
        // Make sure targetTick is divisible by spacing.
        if (targetTick % tickSpacing != 0) revert LimitOrderRegistry__InvalidTargetTick(targetTick, tickSpacing);

        (proposedHead, proposedTail) = _findSpot(data, startingNode, targetTick);
    }

    /**
     * @notice Helper function to get the fee per user for a specific order.
     */
    function getFeePerUser(uint128 batchId) external view returns (uint128) {
        return claim[batchId].feePerUser;
    }

    /**
     * @notice Helper function to view if a BatchOrder is ready to claim.
     */
    function isOrderReadyForClaim(uint128 batchId) external view returns (bool) {
        return claim[batchId].isReadyForClaim;
    }

    function getOrderBook(uint256 id) external view returns (BatchOrder memory) {
        return orderBook[id];
    }

    function getClaim(uint128 batchId) external view returns (Claim memory) {
        return claim[batchId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "@solmate/utils/SafeTransferLib.sol";
import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import { Owned } from "@solmate/auth/Owned.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import { IKeeperRegistrar, RegistrationParams } from "src/interfaces/chainlink/IKeeperRegistrar.sol";
import { LimitOrderRegistry } from "src/LimitOrderRegistry.sol";
import { UniswapV3Pool } from "src/interfaces/uniswapV3/UniswapV3Pool.sol";

/**
 * @title Trade Manager
 * @notice Automates claiming limit orders for the LimitOrderRegistry.
 * @author crispymangoes
 * @dev Future improvements.
 *      - could add logic into the LOR that checks if the caller is a users TradeManager, and if so that allows the caller to
 *        create/edit orders on behalf of the user.
 *      - add some bool that dictates where assets go, like on claim should assets be returned here, or to the owner
 *      - Could allow users to funds their upkeep through this contract, which would interact with pegswap if needed.
 */
contract TradeManager is Initializable, AutomationCompatibleInterface, Owned {
    using SafeTransferLib for ERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    /*//////////////////////////////////////////////////////////////
                             STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Stores information used to claim orders in `performUpkeep`.
     * @param batchId The order batch id to claim
     * @param fee The Native fee required to claim the order
     */
    struct ClaimInfo {
        uint128 batchId;
        uint128 fee;
    }

    /*//////////////////////////////////////////////////////////////
                             GLOBAL STATE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set of batch IDs that the owner currently has orders in.
     */
    EnumerableSet.UintSet private ownerOrders;

    /**
     * @notice The limit order registry contract this trade manager interacts with.
     */
    LimitOrderRegistry public limitOrderRegistry;

    /**
     * @notice The gas limit used when the Trade Managers upkeep is created.
     */
    uint32 public constant UPKEEP_GAS_LIMIT = 500_000;

    /**
     * @notice The max amount of claims that can happen in a single upkeep.
     */
    uint256 public constant MAX_CLAIMS = 10;

    /**
     * @notice Allows owner to specify whether they want claimed tokens to be left
     *         in the TradeManager, or sent to their address.
     *         -true send tokens to their address
     *         -false leave tokens in the trade manager
     */
    bool public claimToOwner;

    constructor() Owned(address(0)) {}

    /*//////////////////////////////////////////////////////////////
                            INITIALIZE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initialize function to setup this contract.
     * @param user The owner of this contract
     * @param _limitOrderRegistry The limit order registry this contract interacts with
     * @param LINK The Chainlink token needed to create an upkeep
     * @param registrar The Chainlink Automation Registrar contract
     * @param initialUpkeepFunds Amount of link to fund the upkeep with
     */
    function initialize(
        address user,
        LimitOrderRegistry _limitOrderRegistry,
        LinkTokenInterface LINK,
        IKeeperRegistrar registrar,
        uint256 initialUpkeepFunds
    ) external initializer {
        owner = user;
        limitOrderRegistry = _limitOrderRegistry;

        // Create a new upkeep.
        if (initialUpkeepFunds > 0) {
            ERC20(address(LINK)).safeTransferFrom(msg.sender, address(this), initialUpkeepFunds);
            ERC20(address(LINK)).safeApprove(address(registrar), initialUpkeepFunds);
            RegistrationParams memory params = RegistrationParams({
                name: "Trade Manager",
                encryptedEmail: abi.encode(0),
                upkeepContract: address(this),
                gasLimit: UPKEEP_GAS_LIMIT,
                adminAddress: user,
                checkData: abi.encode(0),
                offchainConfig: abi.encode(0),
                amount: uint96(initialUpkeepFunds)
            });
            registrar.registerUpkeep(params);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              OWNER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows owner to adjust `claimToOwner`.
     */
    function setClaimToOwner(bool state) external onlyOwner {
        claimToOwner = state;
    }

    /**
     * @notice See `LimitOrderRegistry.sol:newOrder`.
     */
    function newOrder(
        UniswapV3Pool pool,
        ERC20 assetIn,
        int24 targetTick,
        uint128 amount,
        bool direction,
        uint256 startingNode
    ) external onlyOwner {
        uint256 managerBalance = assetIn.balanceOf(address(this));
        // If manager lacks funds, transfer delta into manager.
        if (managerBalance < amount) assetIn.safeTransferFrom(msg.sender, address(this), amount - managerBalance);

        assetIn.safeApprove(address(limitOrderRegistry), amount);
        uint128 batchId = limitOrderRegistry.newOrder(pool, targetTick, amount, direction, startingNode);
        ownerOrders.add(batchId);
    }

    /**
     * @notice See `LimitOrderRegistry.sol:cancelOrder`.
     */
    function cancelOrder(UniswapV3Pool pool, int24 targetTick, bool direction) external onlyOwner {
        (uint128 amount0, uint128 amount1, uint128 batchId) = limitOrderRegistry.cancelOrder(
            pool,
            targetTick,
            direction
        );
        if (amount0 > 0) ERC20(pool.token0()).safeTransfer(owner, amount0);
        if (amount1 > 0) ERC20(pool.token1()).safeTransfer(owner, amount1);

        ownerOrders.remove(batchId);
    }

    /**
     * @notice See `LimitOrderRegistry.sol:claimOrder`.
     */
    function claimOrder(uint128 batchId) external onlyOwner {
        uint256 value = limitOrderRegistry.getFeePerUser(batchId);
        limitOrderRegistry.claimOrder{ value: value }(batchId, address(this));

        ownerOrders.remove(batchId);
    }

    /**
     @notice Allows owner to withdraw Native asset from this contract.
     */
    function withdrawNative(uint256 amount) external onlyOwner {
        payable(owner).transfer(amount);
    }

    /**
     * @notice Allows owner to withdraw any ERC20 from this contract.
     */
    function withdrawERC20(ERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(owner, amount);
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                     CHAINLINK AUTOMATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Iterates through `ownerOrders` and stops early if total fee is greater than this contract native balance, or if max claims is met.
     */
    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory performData) {
        uint256 nativeBalance = address(this).balance;
        // Iterate through owner orders, and build a claim array.

        uint256 count = ownerOrders.length();
        ClaimInfo[MAX_CLAIMS] memory claimInfo;
        uint256 claimCount;
        for (uint256 i; i < count; ++i) {
            uint128 batchId = uint128(ownerOrders.at(i));
            // Current order is not fulfilled.
            if (!limitOrderRegistry.isOrderReadyForClaim(batchId)) continue;
            uint128 fee = limitOrderRegistry.getFeePerUser(batchId);
            // Break if manager does not have enough native to pay for claim.
            if (fee > nativeBalance) break;
            // Subtract fee from balance.
            nativeBalance -= fee;
            claimInfo[claimCount].batchId = batchId;
            claimInfo[claimCount].fee = fee;
            claimCount++;
            // Break if max claims is reached.
            if (claimCount == MAX_CLAIMS) break;
        }

        if (claimCount > 0) {
            upkeepNeeded = true;
            performData = abi.encode(claimInfo);
        }
        // else nothing to do.
    }

    /**
     * @notice Accepts array of ClaimInfo.
     * @dev Passing in incorrect fee values will at worst cost the caller excess gas.
     *      If fee is too large, excess is returned, or LimitOrderRegistry reverts when it tries to transfer Wrapped Native.
     *      If fee is too small LimitOrderRegistry reverts when it tries to transfer Wrapped Native.
     */
    function performUpkeep(bytes calldata performData) external {
        // Accept claim array and claim all orders
        ClaimInfo[MAX_CLAIMS] memory claimInfo = abi.decode(performData, (ClaimInfo[10]));
        for (uint256 i; i < 10; ++i) {
            if (limitOrderRegistry.isOrderReadyForClaim(claimInfo[i].batchId)) {
                (ERC20 asset, uint256 assets) = limitOrderRegistry.claimOrder{ value: claimInfo[i].fee }(
                    claimInfo[i].batchId,
                    address(this)
                );
                ownerOrders.remove(claimInfo[i].batchId);
                if (claimToOwner) asset.safeTransfer(owner, assets);
            }
        }
    }

    function getOwnerBatchIds() external view returns (uint256[] memory ids) {
        ids = new uint256[](ownerOrders.length());
        for (uint256 i; i < ids.length; ++i) ids[i] = ownerOrders.at(i);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { ERC20 } from "@solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "@solmate/utils/SafeTransferLib.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import { IKeeperRegistrar } from "src/interfaces/chainlink/IKeeperRegistrar.sol";
import { LimitOrderRegistry } from "src/LimitOrderRegistry.sol";
import { TradeManager } from "src/TradeManager.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title Trade Manager Factory
 * @notice Factory to deploy Trade Managers using Open Zeppelin Clones.
 * @author crispymangoes
 */
contract TradeManagerFactory {
    using SafeTransferLib for ERC20;
    using Clones for address;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ManagerCreated(address manager);

    /*//////////////////////////////////////////////////////////////
                              IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Trade Manager Implementation contract.
     */
    address public immutable implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    /*//////////////////////////////////////////////////////////////
                        MANAGER CREATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows caller to create a new trade manager for themselves.
     * @dev Requires caller has approved this contract to spend their LINK.
     */
    function createTradeManager(
        LimitOrderRegistry _limitOrderRegistry,
        LinkTokenInterface LINK,
        IKeeperRegistrar registrar,
        uint256 initialUpkeepFunds
    ) external returns (TradeManager manager) {
        address payable clone = payable(implementation.clone());
        if (initialUpkeepFunds > 0) {
            ERC20(address(LINK)).safeTransferFrom(msg.sender, address(this), initialUpkeepFunds);
            ERC20(address(LINK)).safeApprove(clone, initialUpkeepFunds);
        }
        manager = TradeManager(clone);
        manager.initialize(msg.sender, _limitOrderRegistry, LINK, registrar, initialUpkeepFunds);
        emit ManagerCreated(address(manager));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

interface IChainlinkAggregator is AggregatorV2V3Interface {
    function maxAnswer() external view returns (int192);

    function minAnswer() external view returns (int192);

    function aggregator() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
}

/**
 * @notice Contract to accept requests for upkeep registrations
 * @dev There are 2 registration workflows in this contract
 * Flow 1. auto approve OFF / manual registration - UI calls `register` function on this contract, this contract owner at a later time then manually
 *  calls `approve` to register upkeep and emit events to inform UI and others interested.
 * Flow 2. auto approve ON / real time registration - UI calls `register` function as before, which calls the `registerUpkeep` function directly on
 *  keeper registry and then emits approved event to finish the flow automatically without manual intervention.
 * The idea is to have same interface(functions,events) for UI or anyone using this contract irrespective of auto approve being enabled or not.
 * they can just listen to `RegistrationRequested` & `RegistrationApproved` events and know the status on registrations.
 */
interface IKeeperRegistrar {
    /**
     * @notice register can only be called through transferAndCall on LINK contract
     * @param name string of the upkeep to be registered
     * @param encryptedEmail email address of upkeep contact
     * @param upkeepContract address to perform upkeep on
     * @param gasLimit amount of gas to provide the target contract when performing upkeep
     * @param adminAddress address to cancel upkeep and withdraw remaining funds
     * @param checkData data passed to the contract when checking for upkeep
     * @param amount quantity of LINK upkeep is funded with (specified in Juels)
     * @param source application sending this request
     * @param sender address of the sender making the request
     */
    function register(
        string memory name,
        bytes calldata encryptedEmail,
        address upkeepContract,
        uint32 gasLimit,
        address adminAddress,
        bytes calldata checkData,
        uint96 amount,
        uint8 source,
        address sender
    ) external;

    function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface NonfungiblePositionManager {
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function WETH9() external view returns (address);

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function baseURI() external pure returns (string memory);

    function burn(uint256 tokenId) external payable;

    function collect(CollectParams memory params) external payable returns (uint256 amount0, uint256 amount1);

    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);

    function decreaseLiquidity(
        DecreaseLiquidityParams memory params
    ) external payable returns (uint256 amount0, uint256 amount1);

    function factory() external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);

    function increaseLiquidity(
        IncreaseLiquidityParams memory params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function mint(
        MintParams memory params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    function multicall(bytes[] memory data) external payable returns (bytes[] memory results);

    function name() external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function permit(address spender, uint256 tokenId, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external payable;

    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function refundETH() external payable;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;

    function selfPermit(address token, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external payable;

    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function setApprovalForAll(address operator, bool approved) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function sweepToken(address token, uint256 amountMinimum, address recipient) external payable;

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function uniswapV3MintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes memory data) external;

    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;
}

pragma solidity ^0.8.10;

interface UniswapV3Pool {
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld, uint16 observationCardinalityNextNew
    );
    event Initialize(uint160 sqrtPriceX96, int24 tick);
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    function burn(int24 tickLower, int24 tickUpper, uint128 amount)
        external
        returns (uint256 amount0, uint256 amount1);
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
    function collectProtocol(address recipient, uint128 amount0Requested, uint128 amount1Requested)
        external
        returns (uint128 amount0, uint128 amount1);
    function factory() external view returns (address);
    function fee() external view returns (uint24);
    function feeGrowthGlobal0X128() external view returns (uint256);
    function feeGrowthGlobal1X128() external view returns (uint256);
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes memory data) external;
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
    function initialize(uint160 sqrtPriceX96) external;
    function liquidity() external view returns (uint128);
    function maxLiquidityPerTick() external view returns (uint128);
    function mint(address recipient, int24 tickLower, int24 tickUpper, uint128 amount, bytes memory data)
        external
        returns (uint256 amount0, uint256 amount1);
    function observations(uint256)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
    function observe(uint32[] memory secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);
    function positions(bytes32)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
    function protocolFees() external view returns (uint128 token0, uint128 token1);
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (int56 tickCumulativeInside, uint160 secondsPerLiquidityInsideX128, uint32 secondsInside);
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes memory data
    ) external returns (int256 amount0, int256 amount1);
    function tickBitmap(int16) external view returns (uint256);
    function tickSpacing() external view returns (int24);
    function ticks(int24)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );
    function token0() external view returns (address);
    function token1() external view returns (address);
}