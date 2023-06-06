// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {IRootManager} from "../../interfaces/IRootManager.sol";
import {OptimismAmb} from "../../interfaces/ambs/optimism/OptimismAmb.sol";
import {IOptimismPortal} from "../../interfaces/ambs/optimism/IOptimismPortal.sol";

import {HubConnector} from "../HubConnector.sol";
import {Connector} from "../Connector.sol";

import {Types} from "./lib/Types.sol";

import {BaseOptimism} from "./BaseOptimism.sol";

contract OptimismHubConnector is HubConnector, BaseOptimism {
  // ============ Storage ============
  IOptimismPortal public immutable OPTIMISM_PORTAL;

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
    address _optimismPortal,
    uint256 _gasCap
  ) HubConnector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector) BaseOptimism(_gasCap) {
    OPTIMISM_PORTAL = IOptimismPortal(_optimismPortal);
  }

  // ============ Override Fns ============
  function _verifySender(address _expected) internal view override returns (bool) {
    return _verifySender(AMB, _expected);
  }

  /**
   * @dev Sends `aggregateRoot` to messaging on l2
   */
  function _sendMessage(bytes memory _data, bytes memory) internal override {
    // Should always be dispatching the aggregate root
    require(_data.length == 32, "!length");
    // Get the calldata
    bytes memory _calldata = abi.encodeWithSelector(Connector.processMessage.selector, _data);
    // Dispatch message
    OptimismAmb(AMB).sendMessage(mirrorConnector, _calldata, uint32(gasCap));
  }

  /**
   * @dev modified from: OptimismPortal contract
   * https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/contracts/L1/OptimismPortal.sol#L208
   */
  function processMessageFromRoot(
    Types.WithdrawalTransaction memory _tx,
    uint256 _l2OutputIndex,
    Types.OutputRootProof calldata _outputRootProof,
    bytes[] calldata _withdrawalProof
  ) external {
    OPTIMISM_PORTAL.proveWithdrawalTransaction(_tx, _l2OutputIndex, _outputRootProof, _withdrawalProof);

    // Extract the argument from the data
    // uint256 _nonce,
    // address _sender,
    // address _target,
    // uint256 _value,
    // uint256 _minGasLimit,
    // bytes memory _message
    (, address _sender, address _target, , , bytes memory _message) = decodeCrossDomainMessageV1(_tx.data);

    // ensure the l2 connector sent the message
    require(_sender == mirrorConnector, "!mirror connector");
    require(_target == address(this), "!target");

    // get the data
    // _message = abi.encodePacked(bytes32(root))
    require(_message.length == 32, "!length");
    bytes32 root = bytes32(_message);

    require(!processed[root], "processed");
    // set root to processed
    processed[root] = true;

    // update the root on the root manager
    IRootManager(ROOT_MANAGER).aggregate(MIRROR_DOMAIN, root);
    emit MessageProcessed(_message, msg.sender);
  }

  /**
   * @notice Encodes a cross domain message based on the V1 (current) encoding.
   *
   * @param _encodedData cross domain message.
   * @return _nonce    Message nonce.
   * @return _sender   Address of the sender of the message.
   * @return _target   Address of the target of the message.
   * @return _value    ETH value to send to the target.
   * @return _gasLimit Gas limit to use for the message.
   * @return _data     Data to send with the message.
   *
   */
  function decodeCrossDomainMessageV1(
    bytes memory _encodedData
  )
    internal
    pure
    returns (uint256 _nonce, address _sender, address _target, uint256 _value, uint256 _gasLimit, bytes memory _data)
  {
    bytes4 selector = bytes4(0);
    assembly {
      selector := mload(add(_encodedData, 32))
    }

    // Make sure the function selector matches
    require(selector == bytes4(keccak256("relayMessage(uint256,address,address,uint256,uint256,bytes)")), "!selector");

    uint256 start = 4;
    uint256 len = _encodedData.length - start;
    bytes memory sliced = new bytes(len);

    assembly {
      // Get the memory pointer to the start of the original data
      let src := add(_encodedData, add(32, start))
      // Get the memory pointer to the start of the new sliced data
      let dest := add(sliced, 32)

      // Copy the data from src to dest
      for {
        let i := 0
      } lt(i, len) {
        i := add(i, 32)
      } {
        mstore(add(dest, i), mload(add(src, i)))
      }
    }

    // Extract the argument from the data
    (_nonce, _sender, _target, _value, _gasLimit, _data) = abi.decode(
      sliced,
      (uint256, address, address, uint256, uint256, bytes)
    );
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {ProposedOwnable} from "../../shared/ProposedOwnable.sol";
import {IConnector} from "../interfaces/IConnector.sol";

/**
 * @title Connector
 * @author Connext Labs, Inc.
 * @notice This contract has the messaging interface functions used by all connectors.
 *
 * @dev This contract stores information about mirror connectors, but can be used as a
 * base for contracts that do not have a mirror (i.e. the connector handling messaging on
 * mainnet). In this case, the `mirrorConnector` and `MIRROR_DOMAIN`
 * will be empty
 *
 * @dev If ownership is renounced, this contract will be unable to update its `mirrorConnector`
 * or `mirrorGas`
 */
abstract contract Connector is ProposedOwnable, IConnector {
  // ========== Custom Errors ===========

  error Connector__processMessage_notUsed();

  // ============ Events ============

  event NewConnector(
    uint32 indexed domain,
    uint32 indexed mirrorDomain,
    address amb,
    address rootManager,
    address mirrorConnector
  );

  event MirrorConnectorUpdated(address previous, address current);

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
   */
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector
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

    emit NewConnector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector);
  }

  // ============ Receivable ============
  /**
   * @notice Connectors may need to receive native asset to handle fees when sending a
   * message
   */
  receive() external payable {}

  // ============ Admin Functions ============

  /**
   * @notice Sets the address of the l2Connector for this domain
   */
  function setMirrorConnector(address _mirrorConnector) public onlyOwner {
    _setMirrorConnector(_mirrorConnector);
  }

  // ============ Public Functions ============

  /**
   * @notice Processes a message received by an AMB
   * @dev This is called by AMBs to process messages originating from mirror connector
   */
  function processMessage(bytes memory _data) external virtual onlyAMB {
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
   * @param _data The contents of the message
   * @param _encodedData Data used to send the message; specific to connector
   */
  function _sendMessage(bytes memory _data, bytes memory _encodedData) internal virtual;

  /**
   * @notice This function is used by the AMBs to handle incoming messages. Should store the latest
   * root generated on the l2 domain.
   */
  function _processMessage(
    bytes memory /* _data */
  ) internal virtual {
    // By default, reverts. This is to ensure the call path is not used unless this function is
    // overridden by the inheriting class
    revert Connector__processMessage_notUsed();
  }

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
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {ProposedOwnable} from "../../shared/ProposedOwnable.sol";

abstract contract GasCap is ProposedOwnable {
  // ============ Storage ============
  /**
   * @notice The gnosis amb requires destination gas to be specified on the origin.
   * The gas used will be passed in by the relayer to allow for real-time estimates,
   * but will be capped at the admin-set cap.
   */
  uint256 gasCap;

  // ============ Events ============

  /**
   * @notice Emitted when admin updates the gas cap
   * @param _previous The starting value
   * @param _updated The final value
   */
  event GasCapUpdated(uint256 _previous, uint256 _updated);

  // ============ Constructor ============
  constructor(uint256 _gasCap) {
    _setGasCap(_gasCap);
  }

  // ============ Admin Fns ============
  function setGasCap(uint256 _gasCap) public onlyOwner {
    _setGasCap(_gasCap);
  }

  // ============ Internal Fns ============

  /**
   * @notice Used (by admin) to update the gas cap
   * @param _gasCap The new value
   */
  function _setGasCap(uint256 _gasCap) internal {
    emit GasCapUpdated(gasCap, _gasCap);
    gasCap = _gasCap;
  }

  /**
   * @notice Used to get the gas to use. Will be the original value IFF it
   * is less than the cap
   * @param _gas The proposed gas value
   */
  function _getGas(uint256 _gas) internal view returns (uint256) {
    if (_gas > gasCap) {
      _gas = gasCap;
    }
    return _gas;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

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
   */
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector
  ) Connector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector) {}

  // ============ Public fns ============
  /**
   * @notice Sends a message over the amb
   * @dev This is called by the root manager *only* on mainnet to propagate the aggregate root
   */
  function sendMessage(bytes memory _data, bytes memory _encodedData) external payable onlyRootManager {
    _sendMessage(_data, _encodedData);
    emit MessageSent(_data, _encodedData, msg.sender);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {OptimismAmb} from "../../interfaces/ambs/optimism/OptimismAmb.sol";

import {GasCap} from "../GasCap.sol";

abstract contract BaseOptimism is GasCap {
  // ============ Constructor ============
  constructor(uint256 _gasCap) GasCap(_gasCap) {}

  // ============ Override Fns ============
  function _verifySender(address _amb, address _expected) internal view returns (bool) {
    require(msg.sender == _amb, "!bridge");
    return OptimismAmb(_amb).xDomainMessageSender() == _expected;
  }

  /**
   * @notice Using Optimism AMB, the gas is provided to `sendMessage` as an encoded uint
   */
  function _getGasFromEncoded(bytes memory _encodedData) internal view returns (uint256 _gas) {
    // Should include gas info in specialized calldata
    require(_encodedData.length == 32, "!data length");

    // Get the gas, if it is more than the cap use the cap
    _gas = _getGas(abi.decode(_encodedData, (uint256)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Types
 * @notice Contains various types used throughout the Optimism contract system.
 */
library Types {
  /**
   * @notice OutputProposal represents a commitment to the L2 state. The timestamp is the L1
   *         timestamp that the output root is posted. This timestamp is used to verify that the
   *         finalization period has passed since the output root was submitted.
   *
   * @custom:field outputRoot    Hash of the L2 output.
   * @custom:field timestamp     Timestamp of the L1 block that the output root was submitted in.
   * @custom:field l2BlockNumber L2 block number that the output corresponds to.
   */
  struct OutputProposal {
    bytes32 outputRoot;
    uint128 timestamp;
    uint128 l2BlockNumber;
  }

  /**
   * @notice Struct representing the elements that are hashed together to generate an output root
   *         which itself represents a snapshot of the L2 state.
   *
   * @custom:field version                  Version of the output root.
   * @custom:field stateRoot                Root of the state trie at the block of this output.
   * @custom:field messagePasserStorageRoot Root of the message passer storage trie.
   * @custom:field latestBlockhash          Hash of the block this output was generated from.
   */
  struct OutputRootProof {
    bytes32 version;
    bytes32 stateRoot;
    bytes32 messagePasserStorageRoot;
    bytes32 latestBlockhash;
  }

  /**
   * @notice Struct representing a deposit transaction (L1 => L2 transaction) created by an end
   *         user (as opposed to a system deposit transaction generated by the system).
   *
   * @custom:field from        Address of the sender of the transaction.
   * @custom:field to          Address of the recipient of the transaction.
   * @custom:field isCreation  True if the transaction is a contract creation.
   * @custom:field value       Value to send to the recipient.
   * @custom:field mint        Amount of ETH to mint.
   * @custom:field gasLimit    Gas limit of the transaction.
   * @custom:field data        Data of the transaction.
   * @custom:field l1BlockHash Hash of the block the transaction was submitted in.
   * @custom:field logIndex    Index of the log in the block the transaction was submitted in.
   */
  struct UserDepositTransaction {
    address from;
    address to;
    bool isCreation;
    uint256 value;
    uint256 mint;
    uint64 gasLimit;
    bytes data;
    bytes32 l1BlockHash;
    uint256 logIndex;
  }

  /**
   * @notice Struct representing a withdrawal transaction.
   *
   * @custom:field nonce    Nonce of the withdrawal transaction
   * @custom:field sender   Address of the sender of the transaction.
   * @custom:field target   Address of the recipient of the transaction.
   * @custom:field value    Value to send to the recipient.
   * @custom:field gasLimit Gas limit of the transaction.
   * @custom:field data     Data of the transaction.
   */
  struct WithdrawalTransaction {
    uint256 nonce;
    address sender;
    address target;
    uint256 value;
    uint256 gasLimit;
    bytes data;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

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
   * @param encodedData Data used to send the message; specific to connector
   * @param caller Who called the function (sent the message)
   */
  event MessageSent(bytes data, bytes encodedData, address caller);

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
pragma solidity 0.8.17;

interface IRootManager {
  /**
   * @notice This is called by relayers to generate + send the mixed root from mainnet via AMB to
   * spoke domains.
   * @dev This must read information for the root from the registered AMBs.
   */
  function propagate(
    address[] calldata _connectors,
    uint256[] calldata _fees,
    bytes[] memory _encodedData
  ) external payable;

  /**
   * @notice Called by the connectors for various domains on the hub to aggregate their latest
   * inbound root.
   * @dev This must read information for the root from the registered AMBs
   */
  function aggregate(uint32 _domain, bytes32 _outbound) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Types} from "../../../connectors/optimism/lib/Types.sol";

/**
 * @dev An informal interface. Technically not an interface but a contract, since we need to reference
 * a mapping when interfacing with the real thing (and mappings cannot be declared in interfaces in solidity).
 */
interface IOptimismPortal {
  /**
   * @notice Proves a withdrawal transaction.
   *
   * @param _tx              Withdrawal transaction to finalize.
   * @param _l2OutputIndex   L2 output index to prove against.
   * @param _outputRootProof Inclusion proof of the L2ToL1MessagePasser contract's storage root.
   * @param _withdrawalProof Inclusion proof of the withdrawal in L2ToL1MessagePasser contract.
   */
  function proveWithdrawalTransaction(
    Types.WithdrawalTransaction memory _tx,
    uint256 _l2OutputIndex,
    Types.OutputRootProof calldata _outputRootProof,
    bytes[] calldata _withdrawalProof
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

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
pragma solidity 0.8.17;

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
  error ProposedOwnable__ownershipDelayElapsed_delayNotElapsed();
  error ProposedOwnable__proposeNewOwner_invalidProposal();
  error ProposedOwnable__proposeNewOwner_noOwnershipChange();
  error ProposedOwnable__renounceOwnership_noProposal();
  error ProposedOwnable__renounceOwnership_invalidProposal();

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
   * @notice Throws if the ownership delay has not elapsed
   */
  modifier ownershipDelayElapsed() {
    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnable__ownershipDelayElapsed_delayNotElapsed();
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
    if (_proposed == newlyProposed && _proposedOwnershipTimestamp != 0)
      revert ProposedOwnable__proposeNewOwner_invalidProposal();

    // Sanity check: reasonable proposal
    if (_owner == newlyProposed) revert ProposedOwnable__proposeNewOwner_noOwnershipChange();

    _setProposed(newlyProposed);
  }

  /**
   * @notice Renounces ownership of the contract after a delay
   */
  function renounceOwnership() public virtual onlyOwner ownershipDelayElapsed {
    // Ensure there has been a proposal cycle started
    if (_proposedOwnershipTimestamp == 0) revert ProposedOwnable__renounceOwnership_noProposal();

    // Require proposed is set to 0
    if (_proposed != address(0)) revert ProposedOwnable__renounceOwnership_invalidProposal();

    // Emit event, set new owner, reset timestamp
    _setOwner(address(0));
  }

  /**
   * @notice Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function acceptProposedOwner() public virtual onlyProposed ownershipDelayElapsed {
    // NOTE: no need to check if _owner == _proposed, because the _proposed
    // is 0-d out and this check is implicitly enforced by modifier

    // NOTE: no need to check if _proposedOwnershipTimestamp > 0 because
    // the only time this would happen is if the _proposed was never
    // set (will fail from modifier) or if the owner == _proposed (checked
    // above)

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  // ======== Internal =========

  function _setOwner(address newOwner) internal {
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
    delete _proposedOwnershipTimestamp;
    delete _proposed;
  }

  function _setProposed(address newlyProposed) private {
    _proposedOwnershipTimestamp = block.timestamp;
    _proposed = newlyProposed;
    emit OwnershipProposed(newlyProposed);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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