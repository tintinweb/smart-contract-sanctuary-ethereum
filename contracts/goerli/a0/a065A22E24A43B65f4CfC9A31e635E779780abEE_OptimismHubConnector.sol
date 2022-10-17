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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

import {ProposedOwnable} from "../../shared/ProposedOwnable.sol";
import {IConnector} from "../interfaces/IConnector.sol";

/**
 * @title Connector
 * @author Connext Labs, Inc.
 * @notice This contract has the messaging interface functions used by all connectors.
 *
 * @dev This contract stores information about mirror connectors, but can be used as a
 * base for contracts that do not have a mirror (i.e. the connector handling messaging on
 * mainnet). In this case, the `mirrorConnector`, `MIRROR_DOMAIN`, and `mirrorGas`
 * will be empty
 */
abstract contract Connector is ProposedOwnable, IConnector {
  // ============ Events ============

  event NewConnector(
    uint32 indexed domain,
    uint32 indexed mirrorDomain,
    address amb,
    address rootManager,
    address mirrorConnector
  );

  event MirrorConnectorUpdated(address previous, address current);

  event MirrorGasUpdated(uint256 previous, uint256 current);

  // ============ Public Storage ============

  /**
   * @notice The domain of this Messaging (i.e. Connector) contract.
   */
  uint32 public immutable DOMAIN;

  /**
   * @notice Address of the AMB on this domain.
   */
  address public immutable AMB;

  /**
   * @notice RootManager contract address.
   */
  address public immutable ROOT_MANAGER;

  /**
   * @notice The domain of the corresponding messaging (i.e. Connector) contract.
   */
  uint32 public immutable MIRROR_DOMAIN;

  /**
   * @notice Connector on L2 for L1 connectors, and vice versa.
   */
  address public mirrorConnector;

  /**
   * @notice Gas costs forwarded to the `processMessage` call on the mirror domain
   */
  uint256 public mirrorGas;

  // ============ Modifiers ============

  /**
   * @notice Errors if the msg.sender is not the registered AMB
   */
  modifier onlyAMB() {
    require(msg.sender == AMB, "!AMB");
    _;
  }

  /**
   * @notice Errors if the msg.sender is not the registered ROOT_MANAGER
   */
  modifier onlyRootManager() {
    // NOTE: RootManager will be zero address for spoke connectors.
    // Only root manager can dispatch a message to spokes/L2s via the hub connector.
    require(msg.sender == ROOT_MANAGER, "!rootManager");
    _;
  }

  // ============ Constructor ============

  /**
   * @notice Creates a new HubConnector instance
   * @dev The connectors are deployed such that there is one on each side of an AMB (i.e.
   * for optimism, there is one connector on optimism and one connector on mainnet)
   * @param _domain The domain this connector lives on
   * @param _mirrorDomain The spoke domain
   * @param _amb The address of the amb on the domain this connector lives on
   * @param _rootManager The address of the RootManager on mainnet
   * @param _mirrorConnector The address of the spoke connector
   * @param _mirrorGas The gas costs required to process a message on mirror
   */
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector,
    uint256 _mirrorGas
  ) ProposedOwnable() {
    // set the owner
    _setOwner(msg.sender);

    // sanity checks on values
    require(_domain != 0, "empty domain");
    require(_rootManager != address(0), "empty rootManager");
    // see note at top of contract on why the mirror values are not sanity checked

    // set immutables
    DOMAIN = _domain;
    AMB = _amb;
    ROOT_MANAGER = _rootManager;
    MIRROR_DOMAIN = _mirrorDomain;
    // set mutables if defined
    if (_mirrorConnector != address(0)) {
      _setMirrorConnector(_mirrorConnector);
    }

    if (_mirrorGas != 0) {
      _setMirrorGas(_mirrorGas);
    }

    emit NewConnector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector);
  }

  // ============ Admin Functions ============

  /**
   * @notice Sets the address of the l2Connector for this domain
   */
  function setMirrorConnector(address _mirrorConnector) public onlyOwner {
    _setMirrorConnector(_mirrorConnector);
  }

  /**
   * @notice Sets the address of the l2Connector for this domain
   */
  function setMirrorGas(uint256 _mirrorGas) public onlyOwner {
    _setMirrorGas(_mirrorGas);
  }

  // ============ Public Functions ============

  /**
   * @notice Processes a message received by an AMB
   * @dev This is called by AMBs to process messages originating from mirror connector
   */
  function processMessage(bytes memory _data) external onlyAMB {
    _processMessage(_data);
    emit MessageProcessed(_data, msg.sender);
  }

  /**
   * @notice Checks the cross domain sender for a given address
   */
  function verifySender(address _expected) external returns (bool) {
    return _verifySender(_expected);
  }

  // ============ Virtual Functions ============

  /**
   * @notice This function is used by the Connext contract on the l2 domain to send a message to the
   * l1 domain (i.e. called by Connext on optimism to send a message to mainnet with roots)
   */
  function _sendMessage(bytes memory _data) internal virtual;

  /**
   * @notice This function is used by the AMBs to handle incoming messages. Should store the latest
   * root generated on the l2 domain.
   */
  function _processMessage(bytes memory _data) internal virtual;

  /**
   * @notice Verify that the msg.sender is the correct AMB contract, and that the message's origin sender
   * is the expected address.
   * @dev Should be overridden by the implementing Connector contract.
   */
  function _verifySender(address _expected) internal virtual returns (bool);

  // ============ Private Functions ============

  function _setMirrorConnector(address _mirrorConnector) internal virtual {
    emit MirrorConnectorUpdated(mirrorConnector, _mirrorConnector);
    mirrorConnector = _mirrorConnector;
  }

  function _setMirrorGas(uint256 _mirrorGas) internal {
    emit MirrorGasUpdated(mirrorGas, _mirrorGas);
    mirrorGas = _mirrorGas;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

import {Connector} from "./Connector.sol";

/**
 * @title HubConnector
 * @author Connext Labs, Inc.
 * @notice This contract implements the messaging functions needed on the hub-side of a given AMB.
 * The HubConnector has a limited set of functionality compared to the SpokeConnector, namely that
 * it contains no logic to store or prove messages.
 *
 * @dev This contract should be deployed on the hub-side of an AMB (i.e. on L1), and contracts
 * which extend this should implement the virtual functions defined in the BaseConnector class
 */
abstract contract HubConnector is Connector {
  /**
   * @notice Creates a new HubConnector instance
   * @dev The connectors are deployed such that there is one on each side of an AMB (i.e.
   * for optimism, there is one connector on optimism and one connector on mainnet)
   * @param _domain The domain this connector lives on
   * @param _mirrorDomain The spoke domain
   * @param _amb The address of the amb on the domain this connector lives on
   * @param _rootManager The address of the RootManager on mainnet
   * @param _mirrorConnector The address of the spoke connector
   * @param _mirrorGas The gas costs required to process a message on mirror
   */
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector,
    uint256 _mirrorGas
  ) Connector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector, _mirrorGas) {}

  // ============ Public fns ============
  /**
   * @notice Sends a message over the amb
   * @dev This is called by the root manager *only* on mainnet to propagate the aggregate root
   */
  function sendMessage(bytes memory _data) external onlyRootManager {
    _sendMessage(_data);
    emit MessageSent(_data, msg.sender);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

import {OptimismAmb} from "../../interfaces/ambs/optimism/OptimismAmb.sol";

abstract contract BaseOptimism {
  // ============ Constructor ============
  constructor() {}

  // ============ Override Fns ============
  function _verifySender(address _amb, address _expected) internal view returns (bool) {
    require(msg.sender == _amb, "!bridge");
    return OptimismAmb(_amb).xDomainMessageSender() == _expected;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

import {IRootManager} from "../../interfaces/IRootManager.sol";
import {OptimismAmb} from "../../interfaces/ambs/optimism/OptimismAmb.sol";
import {IStateCommitmentChain, ChainBatchHeader, ChainInclusionProof, L2MessageInclusionProof} from "../../interfaces/ambs/optimism/IStateCommitmentChain.sol";

import {TypedMemView} from "../../../shared/libraries/TypedMemView.sol";

import {HubConnector} from "../HubConnector.sol";
import {Connector} from "../Connector.sol";

import {PredeployAddresses} from "./lib/PredeployAddresses.sol";
import {OVMCodec} from "./lib/OVMCodec.sol";
import {SecureMerkleTrie} from "./lib/SecureMerkleTrie.sol";

import {BaseOptimism} from "./BaseOptimism.sol";

contract OptimismHubConnector is HubConnector, BaseOptimism {
  // ============ Libraries ============
  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // ============ Storage ============
  IStateCommitmentChain public stateCommitmentChain;

  // NOTE: This is needed because we need to track the roots we've
  // already sent across chains. When sending an optimism message, we send calldata
  // for Connector.processMessage. At any point these messages could be processed
  // before the timeout using `processFromRoot` or after the timeout using `process`
  // we track the roots sent here to ensure we process each root once
  mapping(bytes32 => bool) public processed;

  // ============ Constructor ============
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector,
    uint256 _mirrorGas,
    address _stateCommitmentChain
  ) HubConnector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector, _mirrorGas) BaseOptimism() {
    stateCommitmentChain = IStateCommitmentChain(_stateCommitmentChain);
  }

  // ============ Override Fns ============
  function _verifySender(address _expected) internal view override returns (bool) {
    return _verifySender(AMB, _expected);
  }

  /**
   * @dev Sends `aggregateRoot` to messaging on l2
   */
  function _sendMessage(bytes memory _data) internal override {
    // Should always be dispatching the aggregate root
    require(_data.length == 32, "!length");
    // Get the calldata
    bytes memory _calldata = abi.encodeWithSelector(Connector.processMessage.selector, _data);
    // Dispatch message
    OptimismAmb(AMB).sendMessage(mirrorConnector, _calldata, uint32(mirrorGas));
  }

  /**
   * @notice Processes messages
   * @param _data The message to process (should be an outbound root originating on
   * spoke)
   */
  function _processMessage(bytes memory _data) internal override {
    // sanity check root length
    require(_data.length == 32, "!length");

    // get root from data
    bytes32 root = bytes32(_data);

    if (!processed[root]) {
      // set root to processed
      processed[root] = true;
      // update the root on the root manager
      IRootManager(ROOT_MANAGER).aggregate(MIRROR_DOMAIN, root);
    } // otherwise root was already sent to root manager
  }

  /**
   * @dev modified from: https://github.com/ethereum-optimism/optimism/blob/9973c1da3211e094a180a8a96ba9f8bb1ab1b389/packages/contracts/contracts/L1/messaging/L1CrossDomainMessenger.sol#L165
   */
  function processMessageFromRoot(
    address _target,
    address _sender,
    bytes memory _message,
    uint256 _messageNonce,
    L2MessageInclusionProof memory _proof
  ) external {
    // verify the sender is the l2 contract
    require(_sender == mirrorConnector, "!mirrorConnector");

    // verify the target is this contract
    require(_target == address(this), "!this");

    // Get the encoded data
    bytes memory xDomainData = _encodeXDomainCalldata(_target, _sender, _message, _messageNonce);

    require(_verifyXDomainMessage(xDomainData, _proof), "!proof");

    // NOTE: optimism seems to pad the calldata sent in to include more than the expected
    // 36 bytes, i.e. in this transaction:
    // https://blockscout.com/optimism/goerli/tx/0x440fda036d28eb547394a8689af90c5342a00a8ca2ab5117f2b85f54d1416ddd/logs
    // the corresponding _message is:
    // 0x4ff746f60000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000002027ae5ba08d7291c96c8cbddcc148bf48a6d68c7974b94356f53754ef6171d757
    //
    // this means the length check and byte parsing used in the `ArbitrumHubConnector` would
    // not work here. Instead, take the back 32 bytes of the string, regardless of the length. The length
    // can be validated in _processMessage

    // NOTE: TypedMemView only loads 32-byte chunks onto stack, which is fine in this case
    bytes29 _view = _message.ref(0);
    bytes32 _data = _view.index(_view.len() - 32, 32);

    _processMessage(abi.encode(_data));
    emit MessageProcessed(abi.encode(_data), msg.sender);
  }

  /**
   * Verifies that the given message is valid.
   * @dev modified from: https://github.com/ethereum-optimism/optimism/blob/9973c1da3211e094a180a8a96ba9f8bb1ab1b389/packages/contracts/contracts/L1/messaging/L1CrossDomainMessenger.sol#L283-L288
   * @param _xDomainCalldata Calldata to verify.
   * @param _proof Inclusion proof for the message.
   * @return Whether or not the provided message is valid.
   */
  function _verifyXDomainMessage(bytes memory _xDomainCalldata, L2MessageInclusionProof memory _proof)
    internal
    view
    returns (bool)
  {
    return (_verifyStateRootProof(_proof) && _verifyStorageProof(_xDomainCalldata, _proof));
  }

  /**
   * Verifies that the state root within an inclusion proof is valid.
   * @dev modified from: https://github.com/ethereum-optimism/optimism/blob/9973c1da3211e094a180a8a96ba9f8bb1ab1b389/packages/contracts/contracts/L1/messaging/L1CrossDomainMessenger.sol#L295-L311
   * @param _proof Message inclusion proof.
   * @return Whether or not the provided proof is valid.
   */
  function _verifyStateRootProof(L2MessageInclusionProof memory _proof) internal view returns (bool) {
    return
      stateCommitmentChain.verifyStateCommitment(_proof.stateRoot, _proof.stateRootBatchHeader, _proof.stateRootProof);
  }

  /**
   * Verifies that the storage proof within an inclusion proof is valid.
   * @dev modified from: https://github.com/ethereum-optimism/optimism/blob/9973c1da3211e094a180a8a96ba9f8bb1ab1b389/packages/contracts/contracts/L1/messaging/L1CrossDomainMessenger.sol#L313-L357
   * @param _xDomainCalldata Encoded message calldata.
   * @param _proof Message inclusion proof.
   * @return Whether or not the provided proof is valid.
   */
  function _verifyStorageProof(bytes memory _xDomainCalldata, L2MessageInclusionProof memory _proof)
    internal
    pure
    returns (bool)
  {
    bytes32 storageKey = keccak256(
      abi.encodePacked(
        keccak256(abi.encodePacked(_xDomainCalldata, PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER)),
        uint256(0)
      )
    );

    (bool exists, bytes memory encodedMessagePassingAccount) = SecureMerkleTrie.get(
      abi.encodePacked(PredeployAddresses.L2_TO_L1_MESSAGE_PASSER),
      _proof.stateTrieWitness,
      _proof.stateRoot
    );

    require(exists == true, "Message passing predeploy has not been initialized or invalid proof provided.");

    OVMCodec.EVMAccount memory account = OVMCodec.decodeEVMAccount(encodedMessagePassingAccount);

    return
      SecureMerkleTrie.verifyInclusionProof(
        abi.encodePacked(storageKey),
        abi.encodePacked(uint8(1)),
        _proof.storageTrieWitness,
        account.storageRoot
      );
  }

  /**
   * Generates the correct cross domain calldata for a message.
   * @dev taken from: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/libraries/bridge/Lib_CrossDomainUtils.sol
   * @param _target Target contract address.
   * @param _sender Message sender address.
   * @param _message Message to send to the target.
   * @param _messageNonce Nonce for the provided message.
   * @return ABI encoded cross domain calldata.
   */
  function _encodeXDomainCalldata(
    address _target,
    address _sender,
    bytes memory _message,
    uint256 _messageNonce
  ) internal pure returns (bytes memory) {
    return
      abi.encodeWithSignature("relayMessage(address,address,bytes,uint256)", _target, _sender, _message, _messageNonce);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

/**
 * @title BytesUtils
 *
 * @dev modified from: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/libraries/utils/Lib_BytesUtils.sol
 */
library BytesUtils {
  /**********************
   * Internal Functions *
   **********************/

  function slice(
    bytes memory _bytes,
    uint256 _start,
    uint256 _length
  ) internal pure returns (bytes memory) {
    require(_length + 31 >= _length, "slice_overflow");
    require(_start + _length >= _start, "slice_overflow");
    require(_bytes.length >= _start + _length, "slice_outOfBounds");

    bytes memory tempBytes;

    assembly {
      switch iszero(_length)
      case 0 {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
        tempBytes := mload(0x40)

        // The first word of the slice result is potentially a partial
        // word read from the original array. To read it, we calculate
        // the length of that partial word and start copying that many
        // bytes into the array. The first word we copy will start with
        // data we don't care about, but the last `lengthmod` bytes will
        // land at the beginning of the contents of the new array. When
        // we're done copying, we overwrite the full first word with
        // the actual length of the slice.
        let lengthmod := and(_length, 31)

        // The multiplication in the next line is necessary
        // because when slicing multiples of 32 bytes (lengthmod == 0)
        // the following copy loop was copying the origin's length
        // and then ending prematurely not copying everything it should.
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)

        for {
          // The multiplication in the next line has the same exact purpose
          // as the one above.
          let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          mstore(mc, mload(cc))
        }

        mstore(tempBytes, _length)

        //update free-memory pointer
        //allocating the array padded to 32 bytes like the compiler does now
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      //if we want a zero-length slice let's just return a zero-length array
      default {
        tempBytes := mload(0x40)

        //zero out the 32 bytes slice we are about to return
        //we need to do it because Solidity does not garbage collect
        mstore(tempBytes, 0)

        mstore(0x40, add(tempBytes, 0x20))
      }
    }

    return tempBytes;
  }

  function slice(bytes memory _bytes, uint256 _start) internal pure returns (bytes memory) {
    if (_start >= _bytes.length) {
      return bytes("");
    }

    return slice(_bytes, _start, _bytes.length - _start);
  }

  function toBytes32(bytes memory _bytes) internal pure returns (bytes32) {
    if (_bytes.length < 32) {
      bytes32 ret;
      assembly {
        ret := mload(add(_bytes, 32))
      }
      return ret;
    }

    return abi.decode(_bytes, (bytes32)); // will truncate if input length > 32 bytes
  }

  function toUint256(bytes memory _bytes) internal pure returns (uint256) {
    return uint256(toBytes32(_bytes));
  }

  function toNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
    bytes memory nibbles = new bytes(_bytes.length * 2);

    for (uint256 i = 0; i < _bytes.length; i++) {
      nibbles[i * 2] = _bytes[i] >> 4;
      nibbles[i * 2 + 1] = bytes1(uint8(_bytes[i]) % 16);
    }

    return nibbles;
  }

  function fromNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
    bytes memory ret = new bytes(_bytes.length / 2);

    for (uint256 i = 0; i < ret.length; i++) {
      ret[i] = (_bytes[i * 2] << 4) | (_bytes[i * 2 + 1]);
    }

    return ret;
  }

  function equal(bytes memory _bytes, bytes memory _other) internal pure returns (bool) {
    return keccak256(_bytes) == keccak256(_other);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

/* Library Imports */
import {BytesUtils} from "./BytesUtils.sol";
import {RLPReader} from "./RLPReader.sol";

/**
 * @title MerkleTrie
 *
 * @dev modified from: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/libraries/trie/Lib_MerkleTrie.sol
 */
library MerkleTrie {
  /*******************
   * Data Structures *
   *******************/

  enum NodeType {
    BranchNode,
    ExtensionNode,
    LeafNode
  }

  struct TrieNode {
    bytes encoded;
    RLPReader.RLPItem[] decoded;
  }

  /**********************
   * Contract Constants *
   **********************/

  // TREE_RADIX determines the number of elements per branch node.
  uint256 constant TREE_RADIX = 16;
  // Branch nodes have TREE_RADIX elements plus an additional `value` slot.
  uint256 constant BRANCH_NODE_LENGTH = TREE_RADIX + 1;
  // Leaf nodes and extension nodes always have two elements, a `path` and a `value`.
  uint256 constant LEAF_OR_EXTENSION_NODE_LENGTH = 2;

  // Prefixes are prepended to the `path` within a leaf or extension node and
  // allow us to differentiate between the two node types. `ODD` or `EVEN` is
  // determined by the number of nibbles within the unprefixed `path`. If the
  // number of nibbles if even, we need to insert an extra padding nibble so
  // the resulting prefixed `path` has an even number of nibbles.
  uint8 constant PREFIX_EXTENSION_EVEN = 0;
  uint8 constant PREFIX_EXTENSION_ODD = 1;
  uint8 constant PREFIX_LEAF_EVEN = 2;
  uint8 constant PREFIX_LEAF_ODD = 3;

  // Just a utility constant. RLP represents `NULL` as 0x80.
  bytes1 constant RLP_NULL = bytes1(0x80);

  /**********************
   * Internal Functions *
   **********************/

  /**
   * @notice Verifies a proof that a given key/value pair is present in the
   * Merkle trie.
   * @param _key Key of the node to search for, as a hex string.
   * @param _value Value of the node to search for, as a hex string.
   * @param _proof Merkle trie inclusion proof for the desired node. Unlike
   * traditional Merkle trees, this proof is executed top-down and consists
   * of a list of RLP-encoded nodes that make a path down to the target node.
   * @param _root Known root of the Merkle trie. Used to verify that the
   * included proof is correctly constructed.
   * @return _verified `true` if the k/v pair exists in the trie, `false` otherwise.
   */
  function verifyInclusionProof(
    bytes memory _key,
    bytes memory _value,
    bytes memory _proof,
    bytes32 _root
  ) internal pure returns (bool _verified) {
    (bool exists, bytes memory value) = get(_key, _proof, _root);

    return (exists && BytesUtils.equal(_value, value));
  }

  /**
   * @notice Retrieves the value associated with a given key.
   * @param _key Key to search for, as hex bytes.
   * @param _proof Merkle trie inclusion proof for the key.
   * @param _root Known root of the Merkle trie.
   * @return _exists Whether or not the key exists.
   * @return _value Value of the key if it exists.
   */
  function get(
    bytes memory _key,
    bytes memory _proof,
    bytes32 _root
  ) internal pure returns (bool _exists, bytes memory _value) {
    TrieNode[] memory proof = _parseProof(_proof);
    (uint256 pathLength, bytes memory keyRemainder, bool isFinalNode) = _walkNodePath(proof, _key, _root);

    bool exists = keyRemainder.length == 0;

    require(exists || isFinalNode, "Provided proof is invalid.");

    bytes memory value = exists ? _getNodeValue(proof[pathLength - 1]) : bytes("");

    return (exists, value);
  }

  /*********************
   * Private Functions *
   *********************/

  /**
   * @notice Walks through a proof using a provided key.
   * @param _proof Inclusion proof to walk through.
   * @param _key Key to use for the walk.
   * @param _root Known root of the trie.
   * @return _pathLength Length of the final path
   * @return _keyRemainder Portion of the key remaining after the walk.
   * @return _isFinalNode Whether or not we've hit a dead end.
   */
  function _walkNodePath(
    TrieNode[] memory _proof,
    bytes memory _key,
    bytes32 _root
  )
    private
    pure
    returns (
      uint256 _pathLength,
      bytes memory _keyRemainder,
      bool _isFinalNode
    )
  {
    uint256 pathLength = 0;
    bytes memory key = BytesUtils.toNibbles(_key);

    bytes32 currentNodeID = _root;
    uint256 currentKeyIndex = 0;
    uint256 currentKeyIncrement = 0;
    TrieNode memory currentNode;

    // Proof is top-down, so we start at the first element (root).
    for (uint256 i = 0; i < _proof.length; i++) {
      currentNode = _proof[i];
      currentKeyIndex += currentKeyIncrement;

      // Keep track of the proof elements we actually need.
      // It's expensive to resize arrays, so this simply reduces gas costs.
      pathLength += 1;

      if (currentKeyIndex == 0) {
        // First proof element is always the root node.
        require(keccak256(currentNode.encoded) == currentNodeID, "Invalid root hash");
      } else if (currentNode.encoded.length >= 32) {
        // Nodes 32 bytes or larger are hashed inside branch nodes.
        require(keccak256(currentNode.encoded) == currentNodeID, "Invalid large internal hash");
      } else {
        // Nodes smaller than 31 bytes aren't hashed.
        require(BytesUtils.toBytes32(currentNode.encoded) == currentNodeID, "Invalid internal node hash");
      }

      if (currentNode.decoded.length == BRANCH_NODE_LENGTH) {
        if (currentKeyIndex == key.length) {
          // We've hit the end of the key
          // meaning the value should be within this branch node.
          break;
        } else {
          // We're not at the end of the key yet.
          // Figure out what the next node ID should be and continue.
          uint8 branchKey = uint8(key[currentKeyIndex]);
          RLPReader.RLPItem memory nextNode = currentNode.decoded[branchKey];
          currentNodeID = _getNodeID(nextNode);
          currentKeyIncrement = 1;
          continue;
        }
      } else if (currentNode.decoded.length == LEAF_OR_EXTENSION_NODE_LENGTH) {
        bytes memory path = _getNodePath(currentNode);
        uint8 prefix = uint8(path[0]);
        uint8 offset = 2 - (prefix % 2);
        bytes memory pathRemainder = BytesUtils.slice(path, offset);
        bytes memory keyRemainder = BytesUtils.slice(key, currentKeyIndex);
        uint256 sharedNibbleLength = _getSharedNibbleLength(pathRemainder, keyRemainder);

        if (prefix == PREFIX_LEAF_EVEN || prefix == PREFIX_LEAF_ODD) {
          if (pathRemainder.length == sharedNibbleLength && keyRemainder.length == sharedNibbleLength) {
            // The key within this leaf matches our key exactly.
            // Increment the key index to reflect that we have no remainder.
            currentKeyIndex += sharedNibbleLength;
          }

          // We've hit a leaf node, so our next node should be NULL.
          currentNodeID = bytes32(RLP_NULL);
          break;
        } else if (prefix == PREFIX_EXTENSION_EVEN || prefix == PREFIX_EXTENSION_ODD) {
          if (sharedNibbleLength != pathRemainder.length) {
            // Our extension node is not identical to the remainder.
            // We've hit the end of this path
            // updates will need to modify this extension.
            currentNodeID = bytes32(RLP_NULL);
            break;
          } else {
            // Our extension shares some nibbles.
            // Carry on to the next node.
            currentNodeID = _getNodeID(currentNode.decoded[1]);
            currentKeyIncrement = sharedNibbleLength;
            continue;
          }
        } else {
          revert("Received a node with an unknown prefix");
        }
      } else {
        revert("Received an unparseable node.");
      }
    }

    // If our node ID is NULL, then we're at a dead end.
    bool isFinalNode = currentNodeID == bytes32(RLP_NULL);
    return (pathLength, BytesUtils.slice(key, currentKeyIndex), isFinalNode);
  }

  /**
   * @notice Parses an RLP-encoded proof into something more useful.
   * @param _proof RLP-encoded proof to parse.
   * @return _parsed Proof parsed into easily accessible structs.
   */
  function _parseProof(bytes memory _proof) private pure returns (TrieNode[] memory _parsed) {
    RLPReader.RLPItem[] memory nodes = RLPReader.readList(_proof);
    TrieNode[] memory proof = new TrieNode[](nodes.length);

    for (uint256 i = 0; i < nodes.length; i++) {
      bytes memory encoded = RLPReader.readBytes(nodes[i]);
      proof[i] = TrieNode({encoded: encoded, decoded: RLPReader.readList(encoded)});
    }

    return proof;
  }

  /**
   * @notice Picks out the ID for a node. Node ID is referred to as the
   * "hash" within the specification, but nodes < 32 bytes are not actually
   * hashed.
   * @param _node Node to pull an ID for.
   * @return _nodeID ID for the node, depending on the size of its contents.
   */
  function _getNodeID(RLPReader.RLPItem memory _node) private pure returns (bytes32 _nodeID) {
    bytes memory nodeID;

    if (_node.length < 32) {
      // Nodes smaller than 32 bytes are RLP encoded.
      nodeID = RLPReader.readRawBytes(_node);
    } else {
      // Nodes 32 bytes or larger are hashed.
      nodeID = RLPReader.readBytes(_node);
    }

    return BytesUtils.toBytes32(nodeID);
  }

  /**
   * @notice Gets the path for a leaf or extension node.
   * @param _node Node to get a path for.
   * @return _path Node path, converted to an array of nibbles.
   */
  function _getNodePath(TrieNode memory _node) private pure returns (bytes memory _path) {
    return BytesUtils.toNibbles(RLPReader.readBytes(_node.decoded[0]));
  }

  /**
   * @notice Gets the path for a node.
   * @param _node Node to get a value for.
   * @return _value Node value, as hex bytes.
   */
  function _getNodeValue(TrieNode memory _node) private pure returns (bytes memory _value) {
    return RLPReader.readBytes(_node.decoded[_node.decoded.length - 1]);
  }

  /**
   * @notice Utility; determines the number of nibbles shared between two
   * nibble arrays.
   * @param _a First nibble array.
   * @param _b Second nibble array.
   * @return _shared Number of shared nibbles.
   */
  function _getSharedNibbleLength(bytes memory _a, bytes memory _b) private pure returns (uint256 _shared) {
    uint256 i = 0;
    while (_a.length > i && _b.length > i && _a[i] == _b[i]) {
      i++;
    }
    return i;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

/* Library Imports */
import {RLPReader} from "./RLPReader.sol";

/**
 * @title OVMCodec
 *
 * @dev modified from: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/libraries/codec/Lib_OVMCodec.sol
 */
library OVMCodec {
  /***********
   * Structs *
   ***********/

  struct EVMAccount {
    uint256 nonce;
    uint256 balance;
    bytes32 storageRoot;
    bytes32 codeHash;
  }

  /**
   * @notice Decodes an RLP-encoded account state into a useful struct.
   * @param _encoded RLP-encoded account state.
   * @return Account state struct.
   */
  function decodeEVMAccount(bytes memory _encoded) internal pure returns (EVMAccount memory) {
    RLPReader.RLPItem[] memory accountState = RLPReader.readList(_encoded);

    return
      EVMAccount({
        nonce: RLPReader.readUint256(accountState[0]),
        balance: RLPReader.readUint256(accountState[1]),
        storageRoot: RLPReader.readBytes32(accountState[2]),
        codeHash: RLPReader.readBytes32(accountState[3])
      });
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

/**
 * @title PredeployAddresses
 *
 * @dev modified from: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/libraries/constants/Lib_PredeployAddresses.sol
 */
library PredeployAddresses {
  address internal constant L2_TO_L1_MESSAGE_PASSER = 0x4200000000000000000000000000000000000000;
  address internal constant L1_MESSAGE_SENDER = 0x4200000000000000000000000000000000000001;
  address internal constant DEPLOYER_WHITELIST = 0x4200000000000000000000000000000000000002;
  address payable internal constant OVM_ETH = payable(0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000);
  address internal constant L2_CROSS_DOMAIN_MESSENGER = 0x4200000000000000000000000000000000000007;
  address internal constant LIB_ADDRESS_MANAGER = 0x4200000000000000000000000000000000000008;
  address internal constant PROXY_EOA = 0x4200000000000000000000000000000000000009;
  address internal constant L2_STANDARD_BRIDGE = 0x4200000000000000000000000000000000000010;
  address internal constant SEQUENCER_FEE_WALLET = 0x4200000000000000000000000000000000000011;
  address internal constant L2_STANDARD_TOKEN_FACTORY = 0x4200000000000000000000000000000000000012;
  address internal constant L1_BLOCK_NUMBER = 0x4200000000000000000000000000000000000013;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

/**
 * @title RLPReader
 * @dev modified from: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/libraries/rlp/Lib_RLPReader.sol
 */
library RLPReader {
  /*************
   * Constants *
   *************/

  uint256 internal constant MAX_LIST_LENGTH = 32;

  /*********
   * Enums *
   *********/

  enum RLPItemType {
    DATA_ITEM,
    LIST_ITEM
  }

  /***********
   * Structs *
   ***********/

  struct RLPItem {
    uint256 length;
    uint256 ptr;
  }

  /**********************
   * Internal Functions *
   **********************/

  /**
   * Converts bytes to a reference to memory position and length.
   * @param _in Input bytes to convert.
   * @return Output memory reference.
   */
  function toRLPItem(bytes memory _in) internal pure returns (RLPItem memory) {
    uint256 ptr;
    assembly {
      ptr := add(_in, 32)
    }

    return RLPItem({length: _in.length, ptr: ptr});
  }

  /**
   * Reads an RLP list value into a list of RLP items.
   * @param _in RLP list value.
   * @return Decoded RLP list items.
   */
  function readList(RLPItem memory _in) internal pure returns (RLPItem[] memory) {
    (uint256 listOffset, , RLPItemType itemType) = _decodeLength(_in);

    require(itemType == RLPItemType.LIST_ITEM, "Invalid RLP list value.");

    // Solidity in-memory arrays can't be increased in size, but *can* be decreased in size by
    // writing to the length. Since we can't know the number of RLP items without looping over
    // the entire input, we'd have to loop twice to accurately size this array. It's easier to
    // simply set a reasonable maximum list length and decrease the size before we finish.
    RLPItem[] memory out = new RLPItem[](MAX_LIST_LENGTH);

    uint256 itemCount = 0;
    uint256 offset = listOffset;
    while (offset < _in.length) {
      require(itemCount < MAX_LIST_LENGTH, "Provided RLP list exceeds max list length.");

      (uint256 itemOffset, uint256 itemLength, ) = _decodeLength(
        RLPItem({length: _in.length - offset, ptr: _in.ptr + offset})
      );

      out[itemCount] = RLPItem({length: itemLength + itemOffset, ptr: _in.ptr + offset});

      itemCount += 1;
      offset += itemOffset + itemLength;
    }

    // Decrease the array size to match the actual item count.
    assembly {
      mstore(out, itemCount)
    }

    return out;
  }

  /**
   * Reads an RLP list value into a list of RLP items.
   * @param _in RLP list value.
   * @return Decoded RLP list items.
   */
  function readList(bytes memory _in) internal pure returns (RLPItem[] memory) {
    return readList(toRLPItem(_in));
  }

  /**
   * Reads an RLP bytes value into bytes.
   * @param _in RLP bytes value.
   * @return Decoded bytes.
   */
  function readBytes(RLPItem memory _in) internal pure returns (bytes memory) {
    (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

    require(itemType == RLPItemType.DATA_ITEM, "Invalid RLP bytes value.");

    return _copy(_in.ptr, itemOffset, itemLength);
  }

  /**
   * Reads an RLP bytes value into bytes.
   * @param _in RLP bytes value.
   * @return Decoded bytes.
   */
  function readBytes(bytes memory _in) internal pure returns (bytes memory) {
    return readBytes(toRLPItem(_in));
  }

  /**
   * Reads an RLP string value into a string.
   * @param _in RLP string value.
   * @return Decoded string.
   */
  function readString(RLPItem memory _in) internal pure returns (string memory) {
    return string(readBytes(_in));
  }

  /**
   * Reads an RLP string value into a string.
   * @param _in RLP string value.
   * @return Decoded string.
   */
  function readString(bytes memory _in) internal pure returns (string memory) {
    return readString(toRLPItem(_in));
  }

  /**
   * Reads an RLP bytes32 value into a bytes32.
   * @param _in RLP bytes32 value.
   * @return Decoded bytes32.
   */
  function readBytes32(RLPItem memory _in) internal pure returns (bytes32) {
    require(_in.length <= 33, "Invalid RLP bytes32 value.");

    (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

    require(itemType == RLPItemType.DATA_ITEM, "Invalid RLP bytes32 value.");

    uint256 ptr = _in.ptr + itemOffset;
    bytes32 out;
    assembly {
      out := mload(ptr)

      // Shift the bytes over to match the item size.
      if lt(itemLength, 32) {
        out := div(out, exp(256, sub(32, itemLength)))
      }
    }

    return out;
  }

  /**
   * Reads an RLP bytes32 value into a bytes32.
   * @param _in RLP bytes32 value.
   * @return Decoded bytes32.
   */
  function readBytes32(bytes memory _in) internal pure returns (bytes32) {
    return readBytes32(toRLPItem(_in));
  }

  /**
   * Reads an RLP uint256 value into a uint256.
   * @param _in RLP uint256 value.
   * @return Decoded uint256.
   */
  function readUint256(RLPItem memory _in) internal pure returns (uint256) {
    return uint256(readBytes32(_in));
  }

  /**
   * Reads an RLP uint256 value into a uint256.
   * @param _in RLP uint256 value.
   * @return Decoded uint256.
   */
  function readUint256(bytes memory _in) internal pure returns (uint256) {
    return readUint256(toRLPItem(_in));
  }

  /**
   * Reads an RLP bool value into a bool.
   * @param _in RLP bool value.
   * @return Decoded bool.
   */
  function readBool(RLPItem memory _in) internal pure returns (bool) {
    require(_in.length == 1, "Invalid RLP boolean value.");

    uint256 ptr = _in.ptr;
    uint256 out;
    assembly {
      out := byte(0, mload(ptr))
    }

    require(out == 0 || out == 1, "Lib_RLPReader: Invalid RLP boolean value, must be 0 or 1");

    return out != 0;
  }

  /**
   * Reads an RLP bool value into a bool.
   * @param _in RLP bool value.
   * @return Decoded bool.
   */
  function readBool(bytes memory _in) internal pure returns (bool) {
    return readBool(toRLPItem(_in));
  }

  /**
   * Reads an RLP address value into a address.
   * @param _in RLP address value.
   * @return Decoded address.
   */
  function readAddress(RLPItem memory _in) internal pure returns (address) {
    if (_in.length == 1) {
      return address(0);
    }

    require(_in.length == 21, "Invalid RLP address value.");

    return address(uint160(readUint256(_in)));
  }

  /**
   * Reads an RLP address value into a address.
   * @param _in RLP address value.
   * @return Decoded address.
   */
  function readAddress(bytes memory _in) internal pure returns (address) {
    return readAddress(toRLPItem(_in));
  }

  /**
   * Reads the raw bytes of an RLP item.
   * @param _in RLP item to read.
   * @return Raw RLP bytes.
   */
  function readRawBytes(RLPItem memory _in) internal pure returns (bytes memory) {
    return _copy(_in);
  }

  /*********************
   * Private Functions *
   *********************/

  /**
   * Decodes the length of an RLP item.
   * @param _in RLP item to decode.
   * @return Offset of the encoded data.
   * @return Length of the encoded data.
   * @return RLP item type (LIST_ITEM or DATA_ITEM).
   */
  function _decodeLength(RLPItem memory _in)
    private
    pure
    returns (
      uint256,
      uint256,
      RLPItemType
    )
  {
    require(_in.length > 0, "RLP item cannot be null.");

    uint256 ptr = _in.ptr;
    uint256 prefix;
    assembly {
      prefix := byte(0, mload(ptr))
    }

    if (prefix <= 0x7f) {
      // Single byte.

      return (0, 1, RLPItemType.DATA_ITEM);
    } else if (prefix <= 0xb7) {
      // Short string.

      // slither-disable-next-line variable-scope
      uint256 strLen = prefix - 0x80;

      require(_in.length > strLen, "Invalid RLP short string.");

      return (1, strLen, RLPItemType.DATA_ITEM);
    } else if (prefix <= 0xbf) {
      // Long string.
      uint256 lenOfStrLen = prefix - 0xb7;

      require(_in.length > lenOfStrLen, "Invalid RLP long string length.");

      uint256 strLen;
      assembly {
        // Pick out the string length.
        strLen := div(mload(add(ptr, 1)), exp(256, sub(32, lenOfStrLen)))
      }

      require(_in.length > lenOfStrLen + strLen, "Invalid RLP long string.");

      return (1 + lenOfStrLen, strLen, RLPItemType.DATA_ITEM);
    } else if (prefix <= 0xf7) {
      // Short list.
      // slither-disable-next-line variable-scope
      uint256 listLen = prefix - 0xc0;

      require(_in.length > listLen, "Invalid RLP short list.");

      return (1, listLen, RLPItemType.LIST_ITEM);
    } else {
      // Long list.
      uint256 lenOfListLen = prefix - 0xf7;

      require(_in.length > lenOfListLen, "Invalid RLP long list length.");

      uint256 listLen;
      assembly {
        // Pick out the list length.
        listLen := div(mload(add(ptr, 1)), exp(256, sub(32, lenOfListLen)))
      }

      require(_in.length > lenOfListLen + listLen, "Invalid RLP long list.");

      return (1 + lenOfListLen, listLen, RLPItemType.LIST_ITEM);
    }
  }

  /**
   * Copies the bytes from a memory location.
   * @param _src Pointer to the location to read from.
   * @param _offset Offset to start reading from.
   * @param _length Number of bytes to read.
   * @return Copied bytes.
   */
  function _copy(
    uint256 _src,
    uint256 _offset,
    uint256 _length
  ) private pure returns (bytes memory) {
    bytes memory out = new bytes(_length);
    if (out.length == 0) {
      return out;
    }

    uint256 src = _src + _offset;
    uint256 dest;
    assembly {
      dest := add(out, 32)
    }

    // Copy over as many complete words as we can.
    for (uint256 i = 0; i < _length / 32; i++) {
      assembly {
        mstore(dest, mload(src))
      }

      src += 32;
      dest += 32;
    }

    // Pick out the remaining bytes.
    uint256 mask;
    unchecked {
      mask = 256**(32 - (_length % 32)) - 1;
    }

    assembly {
      mstore(dest, or(and(mload(src), not(mask)), and(mload(dest), mask)))
    }
    return out;
  }

  /**
   * Copies an RLP item into bytes.
   * @param _in RLP item to copy.
   * @return Copied bytes.
   */
  function _copy(RLPItem memory _in) private pure returns (bytes memory) {
    return _copy(_in.ptr, 0, _in.length);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

/* Library Imports */
import {MerkleTrie} from "./MerkleTrie.sol";

/**
 * @title SecureMerkleTrie
 *
 * @dev modified from: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/libraries/trie/Lib_SecureMerkleTrie.sol
 */
library SecureMerkleTrie {
  /**********************
   * Internal Functions *
   **********************/

  /**
   * @notice Verifies a proof that a given key/value pair is present in the
   * Merkle trie.
   * @param _key Key of the node to search for, as a hex string.
   * @param _value Value of the node to search for, as a hex string.
   * @param _proof Merkle trie inclusion proof for the desired node. Unlike
   * traditional Merkle trees, this proof is executed top-down and consists
   * of a list of RLP-encoded nodes that make a path down to the target node.
   * @param _root Known root of the Merkle trie. Used to verify that the
   * included proof is correctly constructed.
   * @return _verified `true` if the k/v pair exists in the trie, `false` otherwise.
   */
  function verifyInclusionProof(
    bytes memory _key,
    bytes memory _value,
    bytes memory _proof,
    bytes32 _root
  ) internal pure returns (bool _verified) {
    bytes memory key = _getSecureKey(_key);
    return MerkleTrie.verifyInclusionProof(key, _value, _proof, _root);
  }

  /**
   * @notice Retrieves the value associated with a given key.
   * @param _key Key to search for, as hex bytes.
   * @param _proof Merkle trie inclusion proof for the key.
   * @param _root Known root of the Merkle trie.
   * @return _exists Whether or not the key exists.
   * @return _value Value of the key if it exists.
   */
  function get(
    bytes memory _key,
    bytes memory _proof,
    bytes32 _root
  ) internal pure returns (bool _exists, bytes memory _value) {
    bytes memory key = _getSecureKey(_key);
    return MerkleTrie.get(key, _proof, _root);
  }

  /*********************
   * Private Functions *
   *********************/

  /**
   * Computes the secure counterpart to a key.
   * @param _key Key to get a secure key from.
   * @return _secureKey Secure version of the key.
   */
  function _getSecureKey(bytes memory _key) private pure returns (bytes memory _secureKey) {
    return abi.encodePacked(keccak256(_key));
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

import {IProposedOwnable} from "../../shared/interfaces/IProposedOwnable.sol";

/**
 * @notice This interface is what the Connext contract will send and receive messages through.
 * The messaging layer should conform to this interface, and should be interchangeable (i.e.
 * could be Nomad or a generic AMB under the hood).
 *
 * @dev This uses the nomad format to ensure nomad can be added in as it comes back online.
 *
 * Flow from transfer from polygon to optimism:
 * 1. User calls `xcall` with destination specified
 * 2. This will swap in to the bridge assets
 * 3. The swapped assets will get burned
 * 4. The Connext contract will call `dispatch` on the messaging contract to add the transfer
 *    to the root
 * 5. [At some time interval] Relayers call `send` to send the current root from polygon to
 *    mainnet. This is done on all "spoke" domains.
 * 6. [At some time interval] Relayers call `propagate` [better name] on mainnet, this generates a new merkle
 *    root from all of the AMBs
 *    - This function must be able to read root data from all AMBs and aggregate them into a single merkle
 *      tree root
 *    - Will send the mixed root from all chains back through the respective AMBs to all other chains
 * 7. AMB will call `update` to update the latest root on the messaging contract on spoke domains
 * 8. [At any point] Relayers can call `proveAndProcess` to prove inclusion of dispatched message, and call
 *    process on the `Connext` contract
 * 9. Takes minted bridge tokens and credits the LP
 *
 * AMB requirements:
 * - Access `msg.sender` both from mainnet -> spoke and vice versa
 * - Ability to read *our root* from the AMB
 *
 * AMBs:
 * - PoS bridge from polygon
 * - arbitrum bridge
 * - optimism bridge
 * - gnosis chain
 * - bsc (use multichain for messaging)
 */
interface IConnector is IProposedOwnable {
  // ============ Events ============
  /**
   * @notice Emitted whenever a message is successfully sent over an AMB
   * @param data The contents of the message
   * @param caller Who called the function (sent the message)
   */
  event MessageSent(bytes data, address caller);

  /**
   * @notice Emitted whenever a message is successfully received over an AMB
   * @param data The contents of the message
   * @param caller Who called the function
   */
  event MessageProcessed(bytes data, address caller);

  // ============ Public fns ============

  function processMessage(bytes memory _data) external;

  function verifySender(address _expected) external returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

interface IRootManager {
  /**
   * @notice This is called by relayers to generate + send the mixed root from mainnet via AMB to
   * spoke domains.
   * @dev This must read information for the root from the registered AMBs.
   */
  function propagate(uint32[] calldata _domains, address[] calldata _connectors) external;

  /**
   * @notice Called by the connectors for various domains on the hub to aggregate their latest
   * inbound root.
   * @dev This must read information for the root from the registered AMBs
   */
  function aggregate(uint32 _domain, bytes32 _outbound) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

// modified from: https://github.com/ethereum-optimism/optimism/blob/fcfcf6e7e69801e63904ec53815db01a8d45dcac/packages/contracts/contracts/libraries/codec/Lib_OVMCodec.sol#L34-L40
struct ChainBatchHeader {
  uint256 batchIndex;
  bytes32 batchRoot;
  uint256 batchSize;
  uint256 prevTotalElements;
  bytes extraData;
}

// modified from: https://github.com/ethereum-optimism/optimism/blob/fcfcf6e7e69801e63904ec53815db01a8d45dcac/packages/contracts/contracts/libraries/codec/Lib_OVMCodec.sol#L42-L45
struct ChainInclusionProof {
  uint256 index;
  bytes32[] siblings;
}

// modified from: https://github.com/ethereum-optimism/optimism/blob/fcfcf6e7e69801e63904ec53815db01a8d45dcac/packages/contracts/contracts/L1/messaging/IL1CrossDomainMessenger.sol#L18-L24
struct L2MessageInclusionProof {
  bytes32 stateRoot;
  ChainBatchHeader stateRootBatchHeader;
  ChainInclusionProof stateRootProof;
  bytes stateTrieWitness;
  bytes storageTrieWitness;
}

/**
 * @title IStateCommitmentChain
 *
 * @dev modified from: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/L1/rollup/IStateCommitmentChain.sol
 */
interface IStateCommitmentChain {
  /**********
   * Events *
   **********/

  event StateBatchAppended(
    uint256 indexed _batchIndex,
    bytes32 _batchRoot,
    uint256 _batchSize,
    uint256 _prevTotalElements,
    bytes _extraData
  );

  event StateBatchDeleted(uint256 indexed _batchIndex, bytes32 _batchRoot);

  /********************
   * Public Functions *
   ********************/

  /**
   * Retrieves the total number of elements submitted.
   * @return _totalElements Total submitted elements.
   */
  function getTotalElements() external view returns (uint256 _totalElements);

  /**
   * Retrieves the total number of batches submitted.
   * @return _totalBatches Total submitted batches.
   */
  function getTotalBatches() external view returns (uint256 _totalBatches);

  /**
   * Retrieves the timestamp of the last batch submitted by the sequencer.
   * @return _lastSequencerTimestamp Last sequencer batch timestamp.
   */
  function getLastSequencerTimestamp() external view returns (uint256 _lastSequencerTimestamp);

  /**
   * Appends a batch of state roots to the chain.
   * @param _batch Batch of state roots.
   * @param _shouldStartAtElement Index of the element at which this batch should start.
   */
  function appendStateBatch(bytes32[] calldata _batch, uint256 _shouldStartAtElement) external;

  /**
   * Deletes all state roots after (and including) a given batch.
   * @param _batchHeader Header of the batch to start deleting from.
   */
  function deleteStateBatch(ChainBatchHeader memory _batchHeader) external;

  /**
   * Verifies a batch inclusion proof.
   * @param _element Hash of the element to verify a proof for.
   * @param _batchHeader Header of the batch in which the element was included.
   * @param _proof Merkle inclusion proof for the element.
   */
  function verifyStateCommitment(
    bytes32 _element,
    ChainBatchHeader memory _batchHeader,
    ChainInclusionProof memory _proof
  ) external view returns (bool _verified);

  /**
   * Checks whether a given batch is still inside its fraud proof window.
   * @param _batchHeader Header of the batch to check.
   * @return _inside Whether or not the batch is inside the fraud proof window.
   */
  function insideFraudProofWindow(ChainBatchHeader memory _batchHeader) external view returns (bool _inside);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

/**
 * @dev The optimism bridge shares both of these functions, but it is important
 * to note that when going from L2 -> L1, the message cannot be processed by the
 * AMB until the challenge period elapses.
 *
 * HOWEVER, before the challenge elapses, you can read the state of the L2 as it is
 * placed on mainnet. By processing data from the L2 state, we are able to "circumvent"
 * this delay to a reasonable degree.
 *
 * This means that for messages going L1 -> L2, you can call "processMessage" and expect
 * the call to be executed to pass up the aggregate root. When going from L2 -> L1, you
 * must read the root from the L2 state
 *
 * L2 messenger: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/L2/messaging/L2CrossDomainMessenger.sol
 * L1 messenger: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/L1/messaging/L1CrossDomainMessenger.sol
 */
interface OptimismAmb {
  function sendMessage(
    address _target,
    bytes memory _message,
    uint32 _gasLimit
  ) external;

  function xDomainMessageSender() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IProposedOwnable} from "./interfaces/IProposedOwnable.sol";

/**
 * @title ProposedOwnable
 * @notice Contract module which provides a basic access control mechanism,
 * where there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed via a two step process:
 * 1. Call `proposeOwner`
 * 2. Wait out the delay period
 * 3. Call `acceptOwner`
 *
 * @dev This module is used through inheritance. It will make available the
 * modifier `onlyOwner`, which can be applied to your functions to restrict
 * their use to the owner.
 *
 * @dev The majority of this code was taken from the openzeppelin Ownable
 * contract
 *
 */
abstract contract ProposedOwnable is IProposedOwnable {
  // ========== Custom Errors ===========

  error ProposedOwnable__onlyOwner_notOwner();
  error ProposedOwnable__onlyProposed_notProposedOwner();
  error ProposedOwnable__proposeNewOwner_invalidProposal();
  error ProposedOwnable__proposeNewOwner_noOwnershipChange();
  error ProposedOwnable__renounceOwnership_noProposal();
  error ProposedOwnable__renounceOwnership_delayNotElapsed();
  error ProposedOwnable__renounceOwnership_invalidProposal();
  error ProposedOwnable__acceptProposedOwner_delayNotElapsed();

  // ============ Properties ============

  address private _owner;

  address private _proposed;
  uint256 private _proposedOwnershipTimestamp;

  uint256 private constant _delay = 7 days;

  // ======== Getters =========

  /**
   * @notice Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposed() public view virtual returns (address) {
    return _proposed;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposedTimestamp() public view virtual returns (uint256) {
    return _proposedOwnershipTimestamp;
  }

  /**
   * @notice Returns the delay period before a new owner can be accepted.
   */
  function delay() public view virtual returns (uint256) {
    return _delay;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (_owner != msg.sender) revert ProposedOwnable__onlyOwner_notOwner();
    _;
  }

  /**
   * @notice Throws if called by any account other than the proposed owner.
   */
  modifier onlyProposed() {
    if (_proposed != msg.sender) revert ProposedOwnable__onlyProposed_notProposedOwner();
    _;
  }

  /**
   * @notice Indicates if the ownership has been renounced() by
   * checking if current owner is address(0)
   */
  function renounced() public view returns (bool) {
    return _owner == address(0);
  }

  // ======== External =========

  /**
   * @notice Sets the timestamp for an owner to be proposed, and sets the
   * newly proposed owner as step 1 in a 2-step process
   */
  function proposeNewOwner(address newlyProposed) public virtual onlyOwner {
    // Contract as source of truth
    if (_proposed == newlyProposed && newlyProposed != address(0))
      revert ProposedOwnable__proposeNewOwner_invalidProposal();

    // Sanity check: reasonable proposal
    if (_owner == newlyProposed) revert ProposedOwnable__proposeNewOwner_noOwnershipChange();

    _setProposed(newlyProposed);
  }

  /**
   * @notice Renounces ownership of the contract after a delay
   */
  function renounceOwnership() public virtual onlyOwner {
    // Ensure there has been a proposal cycle started
    if (_proposedOwnershipTimestamp == 0) revert ProposedOwnable__renounceOwnership_noProposal();

    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnable__renounceOwnership_delayNotElapsed();

    // Require proposed is set to 0
    if (_proposed != address(0)) revert ProposedOwnable__renounceOwnership_invalidProposal();

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  /**
   * @notice Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function acceptProposedOwner() public virtual onlyProposed {
    // NOTE: no need to check if _owner == _proposed, because the _proposed
    // is 0-d out and this check is implicitly enforced by modifier

    // NOTE: no need to check if _proposedOwnershipTimestamp > 0 because
    // the only time this would happen is if the _proposed was never
    // set (will fail from modifier) or if the owner == _proposed (checked
    // above)

    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnable__acceptProposedOwner_delayNotElapsed();

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  // ======== Internal =========

  function _setOwner(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;
    _proposedOwnershipTimestamp = 0;
    _proposed = address(0);
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function _setProposed(address newlyProposed) private {
    _proposedOwnershipTimestamp = block.timestamp;
    _proposed = newlyProposed;
    emit OwnershipProposed(newlyProposed);
  }
}

abstract contract ProposedOwnableUpgradeable is Initializable, ProposedOwnable {
  /**
   * @dev Initializes the contract setting the deployer as the initial
   */
  function __ProposedOwnable_init() internal onlyInitializing {
    __ProposedOwnable_init_unchained();
  }

  function __ProposedOwnable_init_unchained() internal onlyInitializing {
    _setOwner(msg.sender);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __GAP;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @title IProposedOwnable
 * @notice Defines a minimal interface for ownership with a two step proposal and acceptance
 * process
 */
interface IProposedOwnable {
  /**
   * @dev This emits when change in ownership of a contract is proposed.
   */
  event OwnershipProposed(address indexed proposedOwner);

  /**
   * @dev This emits when ownership of a contract changes.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @notice Get the address of the owner
   * @return owner_ The address of the owner.
   */
  function owner() external view returns (address owner_);

  /**
   * @notice Get the address of the proposed owner
   * @return proposed_ The address of the proposed.
   */
  function proposed() external view returns (address proposed_);

  /**
   * @notice Set the address of the proposed owner of the contract
   * @param newlyProposed The proposed new owner of the contract
   */
  function proposeNewOwner(address newlyProposed) external;

  /**
   * @notice Set the address of the proposed owner of the contract
   */
  function acceptProposedOwner() external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

library TypedMemView {
  // Why does this exist?
  // the solidity `bytes memory` type has a few weaknesses.
  // 1. You can't index ranges effectively
  // 2. You can't slice without copying
  // 3. The underlying data may represent any type
  // 4. Solidity never deallocates memory, and memory costs grow
  //    superlinearly

  // By using a memory view instead of a `bytes memory` we get the following
  // advantages:
  // 1. Slices are done on the stack, by manipulating the pointer
  // 2. We can index arbitrary ranges and quickly convert them to stack types
  // 3. We can insert type info into the pointer, and typecheck at runtime

  // This makes `TypedMemView` a useful tool for efficient zero-copy
  // algorithms.

  // Why bytes29?
  // We want to avoid confusion between views, digests, and other common
  // types so we chose a large and uncommonly used odd number of bytes
  //
  // Note that while bytes are left-aligned in a word, integers and addresses
  // are right-aligned. This means when working in assembly we have to
  // account for the 3 unused bytes on the righthand side
  //
  // First 5 bytes are a type flag.
  // - ff_ffff_fffe is reserved for unknown type.
  // - ff_ffff_ffff is reserved for invalid types/errors.
  // next 12 are memory address
  // next 12 are len
  // bottom 3 bytes are empty

  // Assumptions:
  // - non-modification of memory.
  // - No Solidity updates
  // - - wrt free mem point
  // - - wrt bytes representation in memory
  // - - wrt memory addressing in general

  // Usage:
  // - create type constants
  // - use `assertType` for runtime type assertions
  // - - unfortunately we can't do this at compile time yet :(
  // - recommended: implement modifiers that perform type checking
  // - - e.g.
  // - - `uint40 constant MY_TYPE = 3;`
  // - - ` modifer onlyMyType(bytes29 myView) { myView.assertType(MY_TYPE); }`
  // - instantiate a typed view from a bytearray using `ref`
  // - use `index` to inspect the contents of the view
  // - use `slice` to create smaller views into the same memory
  // - - `slice` can increase the offset
  // - - `slice can decrease the length`
  // - - must specify the output type of `slice`
  // - - `slice` will return a null view if you try to overrun
  // - - make sure to explicitly check for this with `notNull` or `assertType`
  // - use `equal` for typed comparisons.

  // The null view
  bytes29 public constant NULL = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  uint256 constant LOW_12_MASK = 0xffffffffffffffffffffffff;
  uint8 constant TWELVE_BYTES = 96;

  /**
   * @notice      Returns the encoded hex character that represents the lower 4 bits of the argument.
   * @param _b    The byte
   * @return      char - The encoded hex character
   */
  function nibbleHex(uint8 _b) internal pure returns (uint8 char) {
    // This can probably be done more efficiently, but it's only in error
    // paths, so we don't really care :)
    uint8 _nibble = _b | 0xf0; // set top 4, keep bottom 4
    if (_nibble == 0xf0) {
      return 0x30;
    } // 0
    if (_nibble == 0xf1) {
      return 0x31;
    } // 1
    if (_nibble == 0xf2) {
      return 0x32;
    } // 2
    if (_nibble == 0xf3) {
      return 0x33;
    } // 3
    if (_nibble == 0xf4) {
      return 0x34;
    } // 4
    if (_nibble == 0xf5) {
      return 0x35;
    } // 5
    if (_nibble == 0xf6) {
      return 0x36;
    } // 6
    if (_nibble == 0xf7) {
      return 0x37;
    } // 7
    if (_nibble == 0xf8) {
      return 0x38;
    } // 8
    if (_nibble == 0xf9) {
      return 0x39;
    } // 9
    if (_nibble == 0xfa) {
      return 0x61;
    } // a
    if (_nibble == 0xfb) {
      return 0x62;
    } // b
    if (_nibble == 0xfc) {
      return 0x63;
    } // c
    if (_nibble == 0xfd) {
      return 0x64;
    } // d
    if (_nibble == 0xfe) {
      return 0x65;
    } // e
    if (_nibble == 0xff) {
      return 0x66;
    } // f
  }

  /**
   * @notice      Returns a uint16 containing the hex-encoded byte.
   * @param _b    The byte
   * @return      encoded - The hex-encoded byte
   */
  function byteHex(uint8 _b) internal pure returns (uint16 encoded) {
    encoded |= nibbleHex(_b >> 4); // top 4 bits
    encoded <<= 8;
    encoded |= nibbleHex(_b); // lower 4 bits
  }

  /**
   * @notice      Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
   *              `second` contains the encoded lower 16 bytes.
   *
   * @param _b    The 32 bytes as uint256
   * @return      first - The top 16 bytes
   * @return      second - The bottom 16 bytes
   */
  function encodeHex(uint256 _b) internal pure returns (uint256 first, uint256 second) {
    for (uint8 i = 31; i > 15; ) {
      uint8 _byte = uint8(_b >> (i * 8));
      first |= byteHex(_byte);
      if (i != 16) {
        first <<= 16;
      }
      unchecked {
        i -= 1;
      }
    }

    // abusing underflow here =_=
    for (uint8 i = 15; i < 255; ) {
      uint8 _byte = uint8(_b >> (i * 8));
      second |= byteHex(_byte);
      if (i != 0) {
        second <<= 16;
      }
      unchecked {
        i -= 1;
      }
    }
  }

  /**
   * @notice          Changes the endianness of a uint256.
   * @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
   * @param _b        The unsigned integer to reverse
   * @return          v - The reversed value
   */
  function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
    v = _b;

    // swap bytes
    v =
      ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
      ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
    // swap 2-byte long pairs
    v =
      ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
      ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
    // swap 4-byte long pairs
    v =
      ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
      ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
    // swap 8-byte long pairs
    v =
      ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
      ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
    // swap 16-byte long pairs
    v = (v >> 128) | (v << 128);
  }

  /**
   * @notice      Create a mask with the highest `_len` bits set.
   * @param _len  The length
   * @return      mask - The mask
   */
  function leftMask(uint8 _len) private pure returns (uint256 mask) {
    // ugly. redo without assembly?
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      mask := sar(sub(_len, 1), 0x8000000000000000000000000000000000000000000000000000000000000000)
    }
  }

  /**
   * @notice      Return the null view.
   * @return      bytes29 - The null view
   */
  function nullView() internal pure returns (bytes29) {
    return NULL;
  }

  /**
   * @notice      Check if the view is null.
   * @return      bool - True if the view is null
   */
  function isNull(bytes29 memView) internal pure returns (bool) {
    return memView == NULL;
  }

  /**
   * @notice      Check if the view is not null.
   * @return      bool - True if the view is not null
   */
  function notNull(bytes29 memView) internal pure returns (bool) {
    return !isNull(memView);
  }

  /**
   * @notice          Check if the view is of a valid type and points to a valid location
   *                  in memory.
   * @dev             We perform this check by examining solidity's unallocated memory
   *                  pointer and ensuring that the view's upper bound is less than that.
   * @param memView   The view
   * @return          ret - True if the view is valid
   */
  function isValid(bytes29 memView) internal pure returns (bool ret) {
    if (typeOf(memView) == 0xffffffffff) {
      return false;
    }
    uint256 _end = end(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ret := not(gt(_end, mload(0x40)))
    }
  }

  /**
   * @notice          Require that a typed memory view be valid.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @return          bytes29 - The validated view
   */
  function assertValid(bytes29 memView) internal pure returns (bytes29) {
    require(isValid(memView), "Validity assertion failed");
    return memView;
  }

  /**
   * @notice          Return true if the memview is of the expected type. Otherwise false.
   * @param memView   The view
   * @param _expected The expected type
   * @return          bool - True if the memview is of the expected type
   */
  function isType(bytes29 memView, uint40 _expected) internal pure returns (bool) {
    return typeOf(memView) == _expected;
  }

  /**
   * @notice          Require that a typed memory view has a specific type.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @param _expected The expected type
   * @return          bytes29 - The view with validated type
   */
  function assertType(bytes29 memView, uint40 _expected) internal pure returns (bytes29) {
    if (!isType(memView, _expected)) {
      (, uint256 g) = encodeHex(uint256(typeOf(memView)));
      (, uint256 e) = encodeHex(uint256(_expected));
      string memory err = string(
        abi.encodePacked("Type assertion failed. Got 0x", uint80(g), ". Expected 0x", uint80(e))
      );
      revert(err);
    }
    return memView;
  }

  /**
   * @notice          Return an identical view with a different type.
   * @param memView   The view
   * @param _newType  The new type
   * @return          newView - The new view with the specified type
   */
  function castTo(bytes29 memView, uint40 _newType) internal pure returns (bytes29 newView) {
    // then | in the new type
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // shift off the top 5 bytes
      newView := or(newView, shr(40, shl(40, memView)))
      newView := or(newView, shl(216, _newType))
    }
  }

  /**
   * @notice          Unsafe raw pointer construction. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @dev             Unsafe raw pointer construction. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @param _type     The type
   * @param _loc      The memory address
   * @param _len      The length
   * @return          newView - The new view with the specified type, location and length
   */
  function unsafeBuildUnchecked(
    uint256 _type,
    uint256 _loc,
    uint256 _len
  ) private pure returns (bytes29 newView) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      newView := shl(96, or(newView, _type)) // insert type
      newView := shl(96, or(newView, _loc)) // insert loc
      newView := shl(24, or(newView, _len)) // empty bottom 3 bytes
    }
  }

  /**
   * @notice          Instantiate a new memory view. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @dev             Instantiate a new memory view. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @param _type     The type
   * @param _loc      The memory address
   * @param _len      The length
   * @return          newView - The new view with the specified type, location and length
   */
  function build(
    uint256 _type,
    uint256 _loc,
    uint256 _len
  ) internal pure returns (bytes29 newView) {
    uint256 _end = _loc + _len;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      if gt(_end, mload(0x40)) {
        _end := 0
      }
    }
    if (_end == 0) {
      return NULL;
    }
    newView = unsafeBuildUnchecked(_type, _loc, _len);
  }

  /**
   * @notice          Instantiate a memory view from a byte array.
   * @dev             Note that due to Solidity memory representation, it is not possible to
   *                  implement a deref, as the `bytes` type stores its len in memory.
   * @param arr       The byte array
   * @param newType   The type
   * @return          bytes29 - The memory view
   */
  function ref(bytes memory arr, uint40 newType) internal pure returns (bytes29) {
    uint256 _len = arr.length;

    uint256 _loc;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      _loc := add(arr, 0x20) // our view is of the data, not the struct
    }

    return build(newType, _loc, _len);
  }

  /**
   * @notice          Return the associated type information.
   * @param memView   The memory view
   * @return          _type - The type associated with the view
   */
  function typeOf(bytes29 memView) internal pure returns (uint40 _type) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // 216 == 256 - 40
      _type := shr(216, memView) // shift out lower 24 bytes
    }
  }

  /**
   * @notice          Optimized type comparison. Checks that the 5-byte type flag is equal.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the 5-byte type flag is equal
   */
  function sameType(bytes29 left, bytes29 right) internal pure returns (bool) {
    return (left ^ right) >> (2 * TWELVE_BYTES) == 0;
  }

  /**
   * @notice          Return the memory address of the underlying bytes.
   * @param memView   The view
   * @return          _loc - The memory address
   */
  function loc(bytes29 memView) internal pure returns (uint96 _loc) {
    uint256 _mask = LOW_12_MASK; // assembly can't use globals
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // 120 bits = 12 bytes (the encoded loc) + 3 bytes (empty low space)
      _loc := and(shr(120, memView), _mask)
    }
  }

  /**
   * @notice          The number of memory words this memory view occupies, rounded up.
   * @param memView   The view
   * @return          uint256 - The number of memory words
   */
  function words(bytes29 memView) internal pure returns (uint256) {
    return (uint256(len(memView)) + 31) / 32;
  }

  /**
   * @notice          The in-memory footprint of a fresh copy of the view.
   * @param memView   The view
   * @return          uint256 - The in-memory footprint of a fresh copy of the view.
   */
  function footprint(bytes29 memView) internal pure returns (uint256) {
    return words(memView) * 32;
  }

  /**
   * @notice          The number of bytes of the view.
   * @param memView   The view
   * @return          _len - The length of the view
   */
  function len(bytes29 memView) internal pure returns (uint96 _len) {
    uint256 _mask = LOW_12_MASK; // assembly can't use globals
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      _len := and(shr(24, memView), _mask)
    }
  }

  /**
   * @notice          Returns the endpoint of `memView`.
   * @param memView   The view
   * @return          uint256 - The endpoint of `memView`
   */
  function end(bytes29 memView) internal pure returns (uint256) {
    unchecked {
      return loc(memView) + len(memView);
    }
  }

  /**
   * @notice          Safe slicing without memory modification.
   * @param memView   The view
   * @param _index    The start index
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function slice(
    bytes29 memView,
    uint256 _index,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    uint256 _loc = loc(memView);

    // Ensure it doesn't overrun the view
    if (_loc + _index + _len > end(memView)) {
      return NULL;
    }

    _loc = _loc + _index;
    return build(newType, _loc, _len);
  }

  /**
   * @notice          Shortcut to `slice`. Gets a view representing the first `_len` bytes.
   * @param memView   The view
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function prefix(
    bytes29 memView,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    return slice(memView, 0, _len, newType);
  }

  /**
   * @notice          Shortcut to `slice`. Gets a view representing the last `_len` byte.
   * @param memView   The view
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function postfix(
    bytes29 memView,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    return slice(memView, uint256(len(memView)) - _len, _len, newType);
  }

  /**
   * @notice          Construct an error message for an indexing overrun.
   * @param _loc      The memory address
   * @param _len      The length
   * @param _index    The index
   * @param _slice    The slice where the overrun occurred
   * @return          err - The err
   */
  function indexErrOverrun(
    uint256 _loc,
    uint256 _len,
    uint256 _index,
    uint256 _slice
  ) internal pure returns (string memory err) {
    (, uint256 a) = encodeHex(_loc);
    (, uint256 b) = encodeHex(_len);
    (, uint256 c) = encodeHex(_index);
    (, uint256 d) = encodeHex(_slice);
    err = string(
      abi.encodePacked(
        "TypedMemView/index - Overran the view. Slice is at 0x",
        uint48(a),
        " with length 0x",
        uint48(b),
        ". Attempted to index at offset 0x",
        uint48(c),
        " with length 0x",
        uint48(d),
        "."
      )
    );
  }

  /**
   * @notice          Load up to 32 bytes from the view onto the stack.
   * @dev             Returns a bytes32 with only the `_bytes` highest bytes set.
   *                  This can be immediately cast to a smaller fixed-length byte array.
   *                  To automatically cast to an integer, use `indexUint`.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The 32 byte result
   */
  function index(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (bytes32 result) {
    if (_bytes == 0) {
      return bytes32(0);
    }
    if (_index + _bytes > len(memView)) {
      revert(indexErrOverrun(loc(memView), len(memView), _index, uint256(_bytes)));
    }
    require(_bytes <= 32, "TypedMemView/index - Attempted to index more than 32 bytes");

    uint8 bitLength;
    unchecked {
      bitLength = _bytes * 8;
    }
    uint256 _loc = loc(memView);
    uint256 _mask = leftMask(bitLength);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      result := and(mload(add(_loc, _index)), _mask)
    }
  }

  /**
   * @notice          Parse an unsigned integer from the view at `_index`.
   * @dev             Requires that the view have >= `_bytes` bytes following that index.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The unsigned integer
   */
  function indexUint(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (uint256 result) {
    return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
  }

  /**
   * @notice          Parse an unsigned integer from LE bytes.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The unsigned integer
   */
  function indexLEUint(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (uint256 result) {
    return reverseUint256(uint256(index(memView, _index, _bytes)));
  }

  /**
   * @notice          Parse an address from the view at `_index`. Requires that the view have >= 20 bytes
   *                  following that index.
   * @param memView   The view
   * @param _index    The index
   * @return          address - The address
   */
  function indexAddress(bytes29 memView, uint256 _index) internal pure returns (address) {
    return address(uint160(indexUint(memView, _index, 20)));
  }

  /**
   * @notice          Return the keccak256 hash of the underlying memory
   * @param memView   The view
   * @return          digest - The keccak256 hash of the underlying memory
   */
  function keccak(bytes29 memView) internal pure returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      digest := keccak256(_loc, _len)
    }
  }

  /**
   * @notice          Return the sha2 digest of the underlying memory.
   * @dev             We explicitly deallocate memory afterwards.
   * @param memView   The view
   * @return          digest - The sha2 hash of the underlying memory
   */
  function sha2(bytes29 memView) internal view returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
      digest := mload(ptr)
    }
  }

  /**
   * @notice          Implements bitcoin's hash160 (rmd160(sha2()))
   * @param memView   The pre-image
   * @return          digest - the Digest
   */
  function hash160(bytes29 memView) internal view returns (bytes20 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2
      pop(staticcall(gas(), 3, ptr, 0x20, ptr, 0x20)) // rmd160
      digest := mload(add(ptr, 0xc)) // return value is 0-prefixed.
    }
  }

  /**
   * @notice          Implements bitcoin's hash256 (double sha2)
   * @param memView   A view of the preimage
   * @return          digest - the Digest
   */
  function hash256(bytes29 memView) internal view returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
      pop(staticcall(gas(), 2, ptr, 0x20, ptr, 0x20)) // sha2 #2
      digest := mload(ptr)
    }
  }

  /**
   * @notice          Return true if the underlying memory is equal. Else false.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the underlying memory is equal
   */
  function untypedEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return (loc(left) == loc(right) && len(left) == len(right)) || keccak(left) == keccak(right);
  }

  /**
   * @notice          Return false if the underlying memory is equal. Else true.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - False if the underlying memory is equal
   */
  function untypedNotEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return !untypedEqual(left, right);
  }

  /**
   * @notice          Compares type equality.
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the types are the same
   */
  function equal(bytes29 left, bytes29 right) internal pure returns (bool) {
    return left == right || (typeOf(left) == typeOf(right) && keccak(left) == keccak(right));
  }

  /**
   * @notice          Compares type inequality.
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the types are not the same
   */
  function notEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return !equal(left, right);
  }

  /**
   * @notice          Copy the view to a location, return an unsafe memory reference
   * @dev             Super Dangerous direct memory access.
   *
   *                  This reference can be overwritten if anything else modifies memory (!!!).
   *                  As such it MUST be consumed IMMEDIATELY.
   *                  This function is private to prevent unsafe usage by callers.
   * @param memView   The view
   * @param _newLoc   The new location
   * @return          written - the unsafe memory reference
   */
  function unsafeCopyTo(bytes29 memView, uint256 _newLoc) private view returns (bytes29 written) {
    require(notNull(memView), "TypedMemView/copyTo - Null pointer deref");
    require(isValid(memView), "TypedMemView/copyTo - Invalid pointer deref");
    uint256 _len = len(memView);
    uint256 _oldLoc = loc(memView);

    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _newLoc) {
        revert(0x60, 0x20) // empty revert message
      }

      // use the identity precompile to copy
      // guaranteed not to fail, so pop the success
      pop(staticcall(gas(), 4, _oldLoc, _len, _newLoc, _len))
    }

    written = unsafeBuildUnchecked(typeOf(memView), _newLoc, _len);
  }

  /**
   * @notice          Copies the referenced memory to a new loc in memory, returning a `bytes` pointing to
   *                  the new memory
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param memView   The view
   * @return          ret - The view pointing to the new memory
   */
  function clone(bytes29 memView) internal view returns (bytes memory ret) {
    uint256 ptr;
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
      ret := ptr
    }
    unchecked {
      unsafeCopyTo(memView, ptr + 0x20);
    }
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      mstore(0x40, add(add(ptr, _len), 0x20)) // write new unused pointer
      mstore(ptr, _len) // write len of new array (in bytes)
    }
  }

  /**
   * @notice          Join the views in memory, return an unsafe reference to the memory.
   * @dev             Super Dangerous direct memory access.
   *
   *                  This reference can be overwritten if anything else modifies memory (!!!).
   *                  As such it MUST be consumed IMMEDIATELY.
   *                  This function is private to prevent unsafe usage by callers.
   * @param memViews  The views
   * @return          unsafeView - The conjoined view pointing to the new memory
   */
  function unsafeJoin(bytes29[] memory memViews, uint256 _location) private view returns (bytes29 unsafeView) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _location) {
        revert(0x60, 0x20) // empty revert message
      }
    }

    uint256 _offset = 0;
    for (uint256 i = 0; i < memViews.length; i++) {
      bytes29 memView = memViews[i];
      unchecked {
        unsafeCopyTo(memView, _location + _offset);
        _offset += len(memView);
      }
    }
    unsafeView = unsafeBuildUnchecked(0, _location, _offset);
  }

  /**
   * @notice          Produce the keccak256 digest of the concatenated contents of multiple views.
   * @param memViews  The views
   * @return          bytes32 - The keccak256 digest
   */
  function joinKeccak(bytes29[] memory memViews) internal view returns (bytes32) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }
    return keccak(unsafeJoin(memViews, ptr));
  }

  /**
   * @notice          Produce the sha256 digest of the concatenated contents of multiple views.
   * @param memViews  The views
   * @return          bytes32 - The sha256 digest
   */
  function joinSha2(bytes29[] memory memViews) internal view returns (bytes32) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }
    return sha2(unsafeJoin(memViews, ptr));
  }

  /**
   * @notice          copies all views, joins them into a new bytearray.
   * @param memViews  The views
   * @return          ret - The new byte array
   */
  function join(bytes29[] memory memViews) internal view returns (bytes memory ret) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }

    bytes29 _newView;
    unchecked {
      _newView = unsafeJoin(memViews, ptr + 0x20);
    }
    uint256 _written = len(_newView);
    uint256 _footprint = footprint(_newView);

    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // store the legnth
      mstore(ptr, _written)
      // new pointer is old + 0x20 + the footprint of the body
      mstore(0x40, add(add(ptr, _footprint), 0x20))
      ret := ptr
    }
  }
}