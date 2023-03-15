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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {IRootManager} from "../../interfaces/IRootManager.sol";
import {OptimismAmb} from "../../interfaces/ambs/optimism/OptimismAmb.sol";
import {IOptimismPortal, ProvenWithdrawal} from "../../interfaces/ambs/optimism/IOptimismPortal.sol";
import {IL2OutputOracle} from "../../interfaces/ambs/optimism/IL2OutputOracle.sol";

import {TypedMemView} from "../../../shared/libraries/TypedMemView.sol";

import {HubConnector} from "../HubConnector.sol";
import {Connector} from "../Connector.sol";

import {PredeployAddresses} from "./lib/PredeployAddresses.sol";
import {Encoding} from "./lib/Encoding.sol";
import {Hashing} from "./lib/Hashing.sol";
import {Types} from "./lib/Types.sol";
import {SafeCall} from "./lib/SafeCall.sol";

import {BaseOptimism} from "./BaseOptimism.sol";

contract OptimismHubConnector is HubConnector, BaseOptimism {
  // ============ Libraries ============
  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // ============ Storage ============
  IOptimismPortal public immutable OPTIMISM_PORTAL;

  IL2OutputOracle public immutable L2_ORACLE;

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
    address _l2OutputOracle,
    uint256 _gasCap
  ) HubConnector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector) BaseOptimism(_gasCap) {
    OPTIMISM_PORTAL = IOptimismPortal(_optimismPortal);
    L2_ORACLE = IL2OutputOracle(_l2OutputOracle);
  }

  // ============ Override Fns ============
  function _verifySender(address _expected) internal view override returns (bool) {
    return _verifySender(AMB, _expected);
  }

  /**
   * @dev Sends `aggregateRoot` to messaging on l2
   */
  function _sendMessage(bytes memory _data, bytes memory _encodedData) internal override {
    // Should always be dispatching the aggregate root
    require(_data.length == 32, "!length");
    // Get the calldata
    bytes memory _calldata = abi.encodeWithSelector(Connector.processMessage.selector, _data);
    // Dispatch message
    OptimismAmb(AMB).sendMessage(mirrorConnector, _calldata, uint32(gasCap));
  }

  /**
   * @dev modified from: OptimismPortal contract
   * https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/contracts/L1/OptimismPortal.sol#L291
   */
  function processMessageFromRoot(Types.WithdrawalTransaction memory _tx) external {
    // verify the sender is the l2 contract
    require(_tx.sender == PredeployAddresses.L2_CROSS_DOMAIN_MESSENGER, "!l2sender");

    // verify the target is this contract
    require(_tx.target == address(this), "!this");

    require(_verifyXDomainMessage(_tx), "!proof");

    // Extract the argument from the data
    (
      uint256 _nonce,
      address _sender,
      address _target,
      uint256 _value,
      uint256 _minGasLimit,
      bytes memory _message
    ) = Encoding.decodeCrossDomainMessageV1(_tx.data);

    // ensure the l2 connector sent the message
    require(_sender == mirrorConnector, "!mirror connector");
    require(_target == address(this), "!target");

    // get the data (should be the outbound root)
    require(_message.length == 36, "!length");

    // NOTE: TypedMemView only loads 32-byte chunks onto stack, which is fine in this case
    bytes29 _view = _message.ref(0);
    bytes32 root = _view.index(_view.len() - 32, 32);

    require(!processed[root], "processed");
    // set root to processed
    processed[root] = true;

    // update the root on the root manager
    IRootManager(ROOT_MANAGER).aggregate(MIRROR_DOMAIN, root);
  }

  /**
   * Verifies that the given message is valid.
   * @param _tx The WithdrawalTransaction to verify.
   * @return bool Whether or not the provided message is valid.
   */
  function _verifyXDomainMessage(Types.WithdrawalTransaction memory _tx) internal view returns (bool) {
    // Get the proven withdrawal record from the OptimismOracle.
    bytes32 withdrawalHash = Hashing.hashWithdrawal(_tx);
    ProvenWithdrawal memory provenWithdrawal = OPTIMISM_PORTAL.provenWithdrawals(withdrawalHash);

    // Ensure withdrawal was proven.
    require(provenWithdrawal.timestamp != 0, "!proven");

    // Ensure this is a message that has happened after the fork.
    require(provenWithdrawal.timestamp >= L2_ORACLE.startingTimestamp(), "pre-bedrock");

    // Grab the OutputProposal from the L2OutputOracle, will revert if the output that
    // corresponds to the given index has not been proposed yet.
    Types.OutputProposal memory proposal = L2_ORACLE.getL2Output(provenWithdrawal.l2OutputIndex);

    // Check that the output root that was used to prove the withdrawal is the same as the
    // current output root for the given output index. An output root may change if it is
    // deleted by the challenger address and then re-proposed.
    require(proposal.outputRoot == provenWithdrawal.outputRoot, "!outputRoot");

    // Now the message is proven within the L2 root for bedrock. The merkle
    // proof of inclusion is completed via `OptimismPortal.prove`.
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Types} from "./Types.sol";
import {Hashing} from "./Hashing.sol";
import {RLPWriter} from "./RLPWriter.sol";

/**
 * @title Encoding
 * @notice Encoding handles Optimism's various different encoding schemes.
 * @dev from Optimism Bedrock libraries
 */
library Encoding {
  /**
   * @notice RLP encodes the L2 transaction that would be generated when a given deposit is sent
   *         to the L2 system. Useful for searching for a deposit in the L2 system. The
   *         transaction is prefixed with 0x7e to identify its EIP-2718 type.
   *
   * @param _tx User deposit transaction to encode.
   *
   * @return RLP encoded L2 deposit transaction.
   */
  function encodeDepositTransaction(Types.UserDepositTransaction memory _tx) internal pure returns (bytes memory) {
    bytes32 source = Hashing.hashDepositSource(_tx.l1BlockHash, _tx.logIndex);
    bytes[] memory raw = new bytes[](8);
    raw[0] = RLPWriter.writeBytes(abi.encodePacked(source));
    raw[1] = RLPWriter.writeAddress(_tx.from);
    raw[2] = _tx.isCreation ? RLPWriter.writeBytes("") : RLPWriter.writeAddress(_tx.to);
    raw[3] = RLPWriter.writeUint(_tx.mint);
    raw[4] = RLPWriter.writeUint(_tx.value);
    raw[5] = RLPWriter.writeUint(uint256(_tx.gasLimit));
    raw[6] = RLPWriter.writeBool(false);
    raw[7] = RLPWriter.writeBytes(_tx.data);
    return abi.encodePacked(uint8(0x7e), RLPWriter.writeList(raw));
  }

  /**
   * @notice Encodes the cross domain message based on the version that is encoded into the
   *         message nonce.
   *
   * @param _nonce    Message nonce with version encoded into the first two bytes.
   * @param _sender   Address of the sender of the message.
   * @param _target   Address of the target of the message.
   * @param _value    ETH value to send to the target.
   * @param _gasLimit Gas limit to use for the message.
   * @param _data     Data to send with the message.
   *
   * @return Encoded cross domain message.
   */
  function encodeCrossDomainMessage(
    uint256 _nonce,
    address _sender,
    address _target,
    uint256 _value,
    uint256 _gasLimit,
    bytes memory _data
  ) internal pure returns (bytes memory) {
    (, uint16 version) = decodeVersionedNonce(_nonce);
    if (version == 0) {
      return encodeCrossDomainMessageV0(_target, _sender, _data, _nonce);
    } else if (version == 1) {
      return encodeCrossDomainMessageV1(_nonce, _sender, _target, _value, _gasLimit, _data);
    } else {
      revert("Encoding: unknown cross domain message version");
    }
  }

  /**
   * @notice Encodes a cross domain message based on the V0 (legacy) encoding.
   *
   * @param _target Address of the target of the message.
   * @param _sender Address of the sender of the message.
   * @param _data   Data to send with the message.
   * @param _nonce  Message nonce.
   *
   * @return Encoded cross domain message.
   */
  function encodeCrossDomainMessageV0(
    address _target,
    address _sender,
    bytes memory _data,
    uint256 _nonce
  ) internal pure returns (bytes memory) {
    return abi.encodeWithSignature("relayMessage(address,address,bytes,uint256)", _target, _sender, _data, _nonce);
  }

  /**
   * @notice Encodes a cross domain message based on the V1 (current) encoding.
   *
   * @param _nonce    Message nonce.
   * @param _sender   Address of the sender of the message.
   * @param _target   Address of the target of the message.
   * @param _value    ETH value to send to the target.
   * @param _gasLimit Gas limit to use for the message.
   * @param _data     Data to send with the message.
   *
   * @return Encoded cross domain message.
   */
  function encodeCrossDomainMessageV1(
    uint256 _nonce,
    address _sender,
    address _target,
    uint256 _value,
    uint256 _gasLimit,
    bytes memory _data
  ) internal pure returns (bytes memory) {
    return
      abi.encodeWithSignature(
        "relayMessage(uint256,address,address,uint256,uint256,bytes)",
        _nonce,
        _sender,
        _target,
        _value,
        _gasLimit,
        _data
      );
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
      abi.encodePacked(sliced),
      (uint256, address, address, uint256, uint256, bytes)
    );
  }

  /**
   * @notice Adds a version number into the first two bytes of a message nonce.
   *
   * @param _nonce   Message nonce to encode into.
   * @param _version Version number to encode into the message nonce.
   *
   * @return Message nonce with version encoded into the first two bytes.
   */
  function encodeVersionedNonce(uint240 _nonce, uint16 _version) internal pure returns (uint256) {
    uint256 nonce;
    assembly {
      nonce := or(shl(240, _version), _nonce)
    }
    return nonce;
  }

  /**
   * @notice Pulls the version out of a version-encoded nonce.
   *
   * @param _nonce Message nonce with version encoded into the first two bytes.
   *
   * @return Nonce without encoded version.
   * @return Version of the message.
   */
  function decodeVersionedNonce(uint256 _nonce) internal pure returns (uint240, uint16) {
    uint240 nonce;
    uint16 version;
    assembly {
      nonce := and(_nonce, 0x0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
      version := shr(240, _nonce)
    }
    return (nonce, version);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Types} from "./Types.sol";
import {Encoding} from "./Encoding.sol";

/**
 * @title Hashing
 * @notice Hashing handles Optimism's various different hashing schemes.
 * @dev from Optimism Bedrock libraries
 */
library Hashing {
  /**
   * @notice Computes the hash of the RLP encoded L2 transaction that would be generated when a
   *         given deposit is sent to the L2 system. Useful for searching for a deposit in the L2
   *         system.
   *
   * @param _tx User deposit transaction to hash.
   *
   * @return Hash of the RLP encoded L2 deposit transaction.
   */
  function hashDepositTransaction(Types.UserDepositTransaction memory _tx) internal pure returns (bytes32) {
    return keccak256(Encoding.encodeDepositTransaction(_tx));
  }

  /**
   * @notice Computes the deposit transaction's "source hash", a value that guarantees the hash
   *         of the L2 transaction that corresponds to a deposit is unique and is
   *         deterministically generated from L1 transaction data.
   *
   * @param _l1BlockHash Hash of the L1 block where the deposit was included.
   * @param _logIndex    The index of the log that created the deposit transaction.
   *
   * @return Hash of the deposit transaction's "source hash".
   */
  function hashDepositSource(bytes32 _l1BlockHash, uint256 _logIndex) internal pure returns (bytes32) {
    bytes32 depositId = keccak256(abi.encode(_l1BlockHash, _logIndex));
    return keccak256(abi.encode(bytes32(0), depositId));
  }

  /**
   * @notice Hashes the cross domain message based on the version that is encoded into the
   *         message nonce.
   *
   * @param _nonce    Message nonce with version encoded into the first two bytes.
   * @param _sender   Address of the sender of the message.
   * @param _target   Address of the target of the message.
   * @param _value    ETH value to send to the target.
   * @param _gasLimit Gas limit to use for the message.
   * @param _data     Data to send with the message.
   *
   * @return Hashed cross domain message.
   */
  function hashCrossDomainMessage(
    uint256 _nonce,
    address _sender,
    address _target,
    uint256 _value,
    uint256 _gasLimit,
    bytes memory _data
  ) internal pure returns (bytes32) {
    (, uint16 version) = Encoding.decodeVersionedNonce(_nonce);
    if (version == 0) {
      return hashCrossDomainMessageV0(_target, _sender, _data, _nonce);
    } else if (version == 1) {
      return hashCrossDomainMessageV1(_nonce, _sender, _target, _value, _gasLimit, _data);
    } else {
      revert("Hashing: unknown cross domain message version");
    }
  }

  /**
   * @notice Hashes a cross domain message based on the V0 (legacy) encoding.
   *
   * @param _target Address of the target of the message.
   * @param _sender Address of the sender of the message.
   * @param _data   Data to send with the message.
   * @param _nonce  Message nonce.
   *
   * @return Hashed cross domain message.
   */
  function hashCrossDomainMessageV0(
    address _target,
    address _sender,
    bytes memory _data,
    uint256 _nonce
  ) internal pure returns (bytes32) {
    return keccak256(Encoding.encodeCrossDomainMessageV0(_target, _sender, _data, _nonce));
  }

  /**
   * @notice Hashes a cross domain message based on the V1 (current) encoding.
   *
   * @param _nonce    Message nonce.
   * @param _sender   Address of the sender of the message.
   * @param _target   Address of the target of the message.
   * @param _value    ETH value to send to the target.
   * @param _gasLimit Gas limit to use for the message.
   * @param _data     Data to send with the message.
   *
   * @return Hashed cross domain message.
   */
  function hashCrossDomainMessageV1(
    uint256 _nonce,
    address _sender,
    address _target,
    uint256 _value,
    uint256 _gasLimit,
    bytes memory _data
  ) internal pure returns (bytes32) {
    return keccak256(Encoding.encodeCrossDomainMessageV1(_nonce, _sender, _target, _value, _gasLimit, _data));
  }

  /**
   * @notice Derives the withdrawal hash according to the encoding in the L2 Withdrawer contract
   *
   * @param _tx Withdrawal transaction to hash.
   *
   * @return Hashed withdrawal transaction.
   */
  function hashWithdrawal(Types.WithdrawalTransaction memory _tx) internal pure returns (bytes32) {
    return keccak256(abi.encode(_tx.nonce, _tx.sender, _tx.target, _tx.value, _tx.gasLimit, _tx.data));
  }

  /**
   * @notice Hashes the various elements of an output root proof into an output root hash which
   *         can be used to check if the proof is valid.
   *
   * @param _outputRootProof Output root proof which should hash to an output root.
   *
   * @return Hashed output root proof.
   */
  function hashOutputRootProof(Types.OutputRootProof memory _outputRootProof) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encode(
          _outputRootProof.version,
          _outputRootProof.stateRoot,
          _outputRootProof.messagePasserStorageRoot,
          _outputRootProof.latestBlockhash
        )
      );
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Lib_RLPWriter
 * @author Bakaoh (with modifications)
 * @dev from Optimism Bedrock libraries
 */
library RLPWriter {
  /**********************
   * Internal Functions *
   **********************/

  /**
   * RLP encodes a byte string.
   * @param _in The byte string to encode.
   * @return The RLP encoded string in bytes.
   */
  function writeBytes(bytes memory _in) internal pure returns (bytes memory) {
    bytes memory encoded;

    if (_in.length == 1 && uint8(_in[0]) < 128) {
      encoded = _in;
    } else {
      encoded = abi.encodePacked(_writeLength(_in.length, 128), _in);
    }

    return encoded;
  }

  /**
   * RLP encodes a list of RLP encoded byte byte strings.
   * @param _in The list of RLP encoded byte strings.
   * @return The RLP encoded list of items in bytes.
   */
  function writeList(bytes[] memory _in) internal pure returns (bytes memory) {
    bytes memory list = _flatten(_in);
    return abi.encodePacked(_writeLength(list.length, 192), list);
  }

  /**
   * RLP encodes a string.
   * @param _in The string to encode.
   * @return The RLP encoded string in bytes.
   */
  function writeString(string memory _in) internal pure returns (bytes memory) {
    return writeBytes(bytes(_in));
  }

  /**
   * RLP encodes an address.
   * @param _in The address to encode.
   * @return The RLP encoded address in bytes.
   */
  function writeAddress(address _in) internal pure returns (bytes memory) {
    return writeBytes(abi.encodePacked(_in));
  }

  /**
   * RLP encodes a uint.
   * @param _in The uint256 to encode.
   * @return The RLP encoded uint256 in bytes.
   */
  function writeUint(uint256 _in) internal pure returns (bytes memory) {
    return writeBytes(_toBinary(_in));
  }

  /**
   * RLP encodes a bool.
   * @param _in The bool to encode.
   * @return The RLP encoded bool in bytes.
   */
  function writeBool(bool _in) internal pure returns (bytes memory) {
    bytes memory encoded = new bytes(1);
    encoded[0] = (_in ? bytes1(0x01) : bytes1(0x80));
    return encoded;
  }

  /*********************
   * Private Functions *
   *********************/

  /**
   * Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
   * @param _len The length of the string or the payload.
   * @param _offset 128 if item is string, 192 if item is list.
   * @return RLP encoded bytes.
   */
  function _writeLength(uint256 _len, uint256 _offset) private pure returns (bytes memory) {
    bytes memory encoded;

    if (_len < 56) {
      encoded = new bytes(1);
      encoded[0] = bytes1(uint8(_len) + uint8(_offset));
    } else {
      uint256 lenLen;
      uint256 i = 1;
      while (_len / i != 0) {
        lenLen++;
        i *= 256;
      }

      encoded = new bytes(lenLen + 1);
      encoded[0] = bytes1(uint8(lenLen) + uint8(_offset) + 55);
      for (i = 1; i <= lenLen; i++) {
        encoded[i] = bytes1(uint8((_len / (256**(lenLen - i))) % 256));
      }
    }

    return encoded;
  }

  /**
   * Encode integer in big endian binary form with no leading zeroes.
   * @notice TODO: This should be optimized with assembly to save gas costs.
   * @param _x The integer to encode.
   * @return RLP encoded bytes.
   */
  function _toBinary(uint256 _x) private pure returns (bytes memory) {
    bytes memory b = abi.encodePacked(_x);

    uint256 i = 0;
    for (; i < 32; i++) {
      if (b[i] != 0) {
        break;
      }
    }

    bytes memory res = new bytes(32 - i);
    for (uint256 j = 0; j < res.length; j++) {
      res[j] = b[i++];
    }

    return res;
  }

  /**
   * Copies a piece of memory to another location.
   * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
   * @param _dest Destination location.
   * @param _src Source location.
   * @param _len Length of memory to copy.
   */
  function _memcpy(
    uint256 _dest,
    uint256 _src,
    uint256 _len
  ) private pure {
    uint256 dest = _dest;
    uint256 src = _src;
    uint256 len = _len;

    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    uint256 mask;
    unchecked {
      mask = 256**(32 - len) - 1;
    }
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }
  }

  /**
   * Flattens a list of byte strings into one byte string.
   * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
   * @param _list List of byte strings to flatten.
   * @return The flattened byte string.
   */
  function _flatten(bytes[] memory _list) private pure returns (bytes memory) {
    if (_list.length == 0) {
      return new bytes(0);
    }

    uint256 len;
    uint256 i = 0;
    for (; i < _list.length; i++) {
      len += _list[i].length;
    }

    bytes memory flattened = new bytes(len);
    uint256 flattenedPtr;
    assembly {
      flattenedPtr := add(flattened, 0x20)
    }

    for (i = 0; i < _list.length; i++) {
      bytes memory item = _list[i];

      uint256 listPtr;
      assembly {
        listPtr := add(item, 0x20)
      }

      _memcpy(flattenedPtr, listPtr, item.length);
      flattenedPtr += _list[i].length;
    }

    return flattened;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title SafeCall
 * @notice Perform low level safe calls
 */
library SafeCall {
  /**
   * @notice Perform a low level call without copying any returndata
   *
   * @param _target   Address to call
   * @param _gas      Amount of gas to pass to the call
   * @param _value    Amount of value to pass to the call
   * @param _calldata Calldata to pass to the call
   */
  function call(address _target, uint256 _gas, uint256 _value, bytes memory _calldata) internal returns (bool) {
    bool _success;
    assembly {
      _success := call(
        _gas, // gas
        _target, // recipient
        _value, // ether value
        add(_calldata, 32), // inloc
        mload(_calldata), // inlen
        0, // outloc
        0 // outlen
      )
    }
    return _success;
  }

  /**
   * @notice Perform a low level call without copying any returndata. This function
   *         will revert if the call cannot be performed with the specified minimum
   *         gas.
   *
   * @param _target   Address to call
   * @param _minGas   The minimum amount of gas that may be passed to the call
   * @param _value    Amount of value to pass to the call
   * @param _calldata Calldata to pass to the call
   */
  function callWithMinGas(
    address _target,
    uint256 _minGas,
    uint256 _value,
    bytes memory _calldata
  ) internal returns (bool) {
    bool _success;
    assembly {
      // Assertion: gasleft() >= ((_minGas + 200) * 64) / 63
      //
      // Because EIP-150 ensures that, a maximum of 63/64ths of the remaining gas in the call
      // frame may be passed to a subcontext, we need to ensure that the gas will not be
      // truncated to hold this function's invariant: "If a call is performed by
      // `callWithMinGas`, it must receive at least the specified minimum gas limit." In
      // addition, exactly 51 gas is consumed between the below `GAS` opcode and the `CALL`
      // opcode, so it is factored in with some extra room for error.
      if lt(gas(), div(mul(64, add(_minGas, 200)), 63)) {
        // Store the "Error(string)" selector in scratch space.
        mstore(0, 0x08c379a0)
        // Store the pointer to the string length in scratch space.
        mstore(32, 32)
        // Store the string.
        //
        // SAFETY:
        // - We pad the beginning of the string with two zero bytes as well as the
        // length (24) to ensure that we override the free memory pointer at offset
        // 0x40. This is necessary because the free memory pointer is likely to
        // be greater than 1 byte when this function is called, but it is incredibly
        // unlikely that it will be greater than 3 bytes. As for the data within
        // 0x60, it is ensured that it is 0 due to 0x60 being the zero offset.
        // - It's fine to clobber the free memory pointer, we're reverting.
        mstore(88, 0x0000185361666543616c6c3a204e6f7420656e6f75676820676173)

        // Revert with 'Error("SafeCall: Not enough gas")'
        revert(28, 100)
      }

      // The call will be supplied at least (((_minGas + 200) * 64) / 63) - 49 gas due to the
      // above assertion. This ensures that, in all circumstances, the call will
      // receive at least the minimum amount of gas specified.
      // We can prove this property by solving the inequalities:
      // ((((_minGas + 200) * 64) / 63) - 49) >= _minGas
      // ((((_minGas + 200) * 64) / 63) - 51) * (63 / 64) >= _minGas
      // Both inequalities hold true for all possible values of `_minGas`.
      _success := call(
        gas(), // gas
        _target, // recipient
        _value, // ether value
        add(_calldata, 32), // inloc
        mload(_calldata), // inlen
        0x00, // outloc
        0x00 // outlen
      )
    }
    return _success;
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
 * @dev modified interface for L2OutputOracle. Source:
 * https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/contracts/L1/L2OutputOracle.sol
 * @dev An informal interface. Technically not an interface but a contract, since we need to reference state
 * variables when interfacing with the real thing (and variables cannot be declared in interfaces in solidity).
 */
contract IL2OutputOracle {
  /**
   * @notice The timestamp of the first L2 block recorded in this contract.
   */
  uint256 public startingTimestamp;

  /**
   * @notice Returns an output by index. Exists because Solidity's array access will return a
   *         tuple instead of a struct.
   *
   * @param _l2OutputIndex Index of the output to return.
   *
   * @return The output at the given index.
   */
  function getL2Output(uint256 _l2OutputIndex) external view returns (Types.OutputProposal memory) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @notice Represents a proven withdrawal.
 * @dev Source:
 * https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts-bedrock/contracts/L1/OptimismPortal.sol
 *
 * @custom:field outputRoot    Root of the L2 output this was proven against.
 * @custom:field timestamp     Timestamp at whcih the withdrawal was proven.
 * @custom:field l2OutputIndex Index of the output this was proven against.
 */
struct ProvenWithdrawal {
  bytes32 outputRoot;
  uint128 timestamp;
  uint128 l2OutputIndex;
}

/**
 * @dev An informal interface. Technically not an interface but a contract, since we need to reference
 * a mapping when interfacing with the real thing (and mappings cannot be declared in interfaces in solidity).
 */
interface IOptimismPortal {
  /**
   * @notice A mapping of withdrawal hashes to `ProvenWithdrawal` data.
   */
  function provenWithdrawals(bytes32 _hash) external view returns (ProvenWithdrawal memory);
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

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
  uint256 constant TWENTY_SEVEN_BYTES = 8 * 27;
  uint256 private constant _27_BYTES_IN_BITS = 8 * 27; // <--- also used this named constant where ever 216 is used.
  uint256 private constant LOW_27_BYTES_MASK = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffff; // (1 << _27_BYTES_IN_BITS) - 1;

  // ========== Custom Errors ===========

  error TypedMemView__assertType_typeAssertionFailed(uint256 actual, uint256 expected);
  error TypedMemView__index_overrun(uint256 loc, uint256 len, uint256 index, uint256 slice);
  error TypedMemView__index_indexMoreThan32Bytes();
  error TypedMemView__unsafeCopyTo_nullPointer();
  error TypedMemView__unsafeCopyTo_invalidPointer();
  error TypedMemView__unsafeCopyTo_identityOOG();
  error TypedMemView__assertValid_validityAssertionFailed();

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
   * @notice          Check if the view is of a invalid type and points to a valid location
   *                  in memory.
   * @dev             We perform this check by examining solidity's unallocated memory
   *                  pointer and ensuring that the view's upper bound is less than that.
   * @param memView   The view
   * @return          ret - True if the view is invalid
   */
  function isNotValid(bytes29 memView) internal pure returns (bool ret) {
    if (typeOf(memView) == 0xffffffffff) {
      return true;
    }
    uint256 _end = end(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ret := gt(_end, mload(0x40))
    }
  }

  /**
   * @notice          Require that a typed memory view be valid.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @return          bytes29 - The validated view
   */
  function assertValid(bytes29 memView) internal pure returns (bytes29) {
    if (isNotValid(memView)) revert TypedMemView__assertValid_validityAssertionFailed();
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
      revert TypedMemView__assertType_typeAssertionFailed(uint256(typeOf(memView)), uint256(_expected));
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
      newView := or(and(memView, LOW_27_BYTES_MASK), shl(_27_BYTES_IN_BITS, _newType))
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
    uint256 _uint96Bits = 96;
    uint256 _emptyBits = 24;

    // Cast params to ensure input is of correct length
    uint96 len_ = uint96(_len);
    uint96 loc_ = uint96(_loc);
    require(len_ == _len && loc_ == _loc, "!truncated");

    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      newView := shl(_uint96Bits, _type) // insert type
      newView := shl(_uint96Bits, or(newView, loc_)) // insert loc
      newView := shl(_emptyBits, or(newView, len_)) // empty bottom 3 bytes
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
      _type := shr(_27_BYTES_IN_BITS, memView) // shift out lower 24 bytes
    }
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
      // "TypedMemView/index - Overran the view. Slice is at {loc} with length {len}. Attempted to index at offset {index} with length {slice},
      revert TypedMemView__index_overrun(loc(memView), len(memView), _index, uint256(_bytes));
    }
    if (_bytes > 32) revert TypedMemView__index_indexMoreThan32Bytes();

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
    if (isNull(memView)) revert TypedMemView__unsafeCopyTo_nullPointer();
    if (isNotValid(memView)) revert TypedMemView__unsafeCopyTo_invalidPointer();

    uint256 _len = len(memView);
    uint256 _oldLoc = loc(memView);

    uint256 ptr;
    bool res;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _newLoc) {
        revert(0x60, 0x20) // empty revert message
      }

      // use the identity precompile to copy
      // guaranteed not to fail, so pop the success
      res := staticcall(gas(), 4, _oldLoc, _len, _newLoc, _len)
    }
    if (!res) revert TypedMemView__unsafeCopyTo_identityOOG();
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
    uint256 _len = memViews.length;
    for (uint256 i = 0; i < _len; ) {
      bytes29 memView = memViews[i];
      unchecked {
        unsafeCopyTo(memView, _location + _offset);
        _offset += len(memView);
        ++i;
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