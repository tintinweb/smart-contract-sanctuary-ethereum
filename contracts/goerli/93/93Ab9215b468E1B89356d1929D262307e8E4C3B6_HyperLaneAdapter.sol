// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

library TypeCasts {
    // treat it as a null-terminated string of max 32 bytes
    function coerceString(bytes32 _buf)
        internal
        pure
        returns (string memory _newStr)
    {
        uint8 _slen = 0;
        while (_slen < 32 && _buf[_slen] != 0) {
            _slen++;
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            _newStr := mload(0x40)
            mstore(0x40, add(_newStr, 0x40)) // may end up with extra
            mstore(_newStr, _slen)
            mstore(add(_newStr, 0x20), _buf)
        }
    }

    // alignment preserving cast
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title IInterchainGasPaymaster
 * @notice Manages payments on a source chain to cover gas costs of relaying
 * messages to destination chains.
 */
interface IInterchainGasPaymaster {
    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasAmount,
        address _refundAddress
    ) external payable;

    function quoteGasPayment(uint32 _destinationDomain, uint256 _gasAmount)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IInterchainSecurityModule {
    /**
     * @notice Returns an enum that represents the type of security model
     * encoded by this ISM.
     * @dev Relayers infer how to fetch and format metadata.
     */
    function moduleType() external view returns (uint8);

    /**
     * @notice Defines a security model responsible for verifying interchain
     * messages based on the provided metadata.
     * @param _metadata Off-chain metadata provided by a relayer, specific to
     * the security model encoded by the module (e.g. validator signatures)
     * @param _message Hyperlane encoded interchain message
     * @return True if the message was verified
     */
    function verify(bytes calldata _metadata, bytes calldata _message)
        external
        returns (bool);
}

interface ISpecifiesInterchainSecurityModule {
    function interchainSecurityModule()
        external
        view
        returns (IInterchainSecurityModule);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "./IInterchainSecurityModule.sol";

interface IMailbox {
    function localDomain() external view returns (uint32);

    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (bytes32);

    function process(bytes calldata _metadata, bytes calldata _message)
        external;

    function count() external view returns (uint32);

    function root() external view returns (bytes32);

    function latestCheckpoint() external view returns (bytes32, uint32);

    function recipientIsm(address _recipient)
        external
        view
        returns (IInterchainSecurityModule);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IBaseAdapter} from './IBaseAdapter.sol';
import {ICrossChainManager} from '../interfaces/ICrossChainManager.sol';

/**
 * @title BaseAdapter
 * @author BGD Labs
 * @notice base contract implementing the method to route a bridged message to the CrossChainManager contract.
 * @dev All bridge adapters must implement this contract
 */
abstract contract BaseAdapter is IBaseAdapter {
  ICrossChainManager public immutable CROSS_CHAIN_MANAGER;

  /**
   * @param crossChainManager address of the crossChainManager the bridged messages will be routed to
   */
  constructor(address crossChainManager) {
    CROSS_CHAIN_MANAGER = ICrossChainManager(crossChainManager);
  }

  /**
   * @notice calls CrossChainManager to register the bridged payload
   * @param _payload bytes containing the bridged message
   * @param originChainId id of the chain where the message originated
   */
  function _registerReceivedMessage(
    bytes memory _payload,
    uint256 originChainId
  ) internal {
    CROSS_CHAIN_MANAGER.receiveCrossChainMessage(_payload, originChainId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IBaseAdapter
 * @author BGD Labs
 * @notice interface containing the event and method used in all bridge adapters
 */
interface IBaseAdapter {
  /**
   * @notice method that will bridge the payload to the chain specified
   * @param receiver address of the receiver contract on destination chain
   * @param gasLimit amount of the gas limit in wei to use for bridging on receiver side. Each adapter will manage this
            as needed
   * @param destinationChainId id of the destination chain in the bridge notation
   * @param message to send to the specified chain
   */
  function forwardMessage(
    address receiver, // TODO: this should be renamed as is the bridge adapter on receiving side
    uint256 gasLimit,
    uint256 destinationChainId,
    bytes memory message
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseAdapter, IBaseAdapter} from '../BaseAdapter.sol';
import {IHyperLaneAdapter, IMailbox, IInterchainGasPaymaster} from './IHyperLaneAdapter.sol';
import {IMessageRecipient} from 'hyperlane-monorepo/interfaces/IMessageRecipient.sol';
import {TypeCasts} from 'hyperlane-monorepo/contracts/libs/TypeCasts.sol';
import {MainnetChainIds, TestnetChainIds} from '../../libs/ChainIds.sol';

/**
 * @title HyperLaneAdapter
 * @author BGD Labs
 * @notice HyperLane bridge adapter. Used to send and receive messages cross chain
 * @dev it uses the eth balance of CrossChainManager contract to pay for message bridging as the method to bridge
        is called via delegate call
 */
contract HyperLaneAdapter is BaseAdapter, IHyperLaneAdapter, IMessageRecipient {
  /// @inheritdoc IHyperLaneAdapter
  IMailbox public immutable HL_MAIL_BOX;

  /// @inheritdoc IHyperLaneAdapter
  IInterchainGasPaymaster public immutable IGP;

  // (standard chain id -> origin forwarder address) saves for every chain the address that can forward messages to this adapter
  mapping(uint256 => address) internal _trustedRemotes;

  /// @notice modifier to check that caller is hyper lane mailBox
  modifier onlyMailbox() {
    require(msg.sender == address(HL_MAIL_BOX), 'CALLER_NOT_HL_MAILBOX');
    _;
  }

  /**
   * @param crossChainManager address of the cross chain manager that will use this bridge adapter
   * @param mailBox HyperLane router contract address to send / receive cross chain messages
   * @param igp HyperLane contract to get the gas estimation to pay for sending messages
   * @param trustedRemotes list of remote configurations to set as trusted
   */
  constructor(
    address crossChainManager,
    address mailBox,
    address igp,
    TrustedRemotesConfig[] memory trustedRemotes
  ) BaseAdapter(crossChainManager) {
    HL_MAIL_BOX = IMailbox(mailBox);
    IGP = IInterchainGasPaymaster(igp);
    _updateTrustedRemotes(trustedRemotes);
  }

  /// @inheritdoc IHyperLaneAdapter
  function getTrustedRemoteByChainId(
    uint256 chainId
  ) external view returns (address) {
    return _trustedRemotes[chainId];
  }

  /// @inheritdoc IBaseAdapter
  function forwardMessage(
    address receiver,
    uint256 destinationGasLimit,
    uint256 destinationChainId,
    bytes memory message
  ) external {
    uint32 nativeChainId = infraToNativeChainId(destinationChainId);
    require(nativeChainId != uint32(0), 'BRIDGE_CHAIN_ID_NOT_SET');
    require(receiver != address(0), 'RECEIVER_NOT_SET');

    bytes32 messageId = HL_MAIL_BOX.dispatch(
      nativeChainId,
      TypeCasts.addressToBytes32(receiver),
      message
    );

    // Get the required payment from the IGP.
    uint256 quotedPayment = IGP.quoteGasPayment(
      nativeChainId,
      destinationGasLimit
    );

    require(
      quotedPayment <= address(this).balance,
      'NOT_ENOUGH_VALUE_TO_PAY_BRIDGE_FEES'
    );

    // Pay from the contract's balance
    IGP.payForGas{value: quotedPayment}(
      messageId, // The ID of the message that was just dispatched
      nativeChainId, // The destination domain of the message
      destinationGasLimit,
      address(this) // refunds go to msg.sender, who paid the msg.value
    );

    emit MessageForwarded(receiver, nativeChainId, message);
  }

  /// @inheritdoc IMessageRecipient
  function handle(
    uint32 _origin,
    bytes32 _sender,
    bytes calldata _messageBody
  ) external onlyMailbox {
    address srcAddress = TypeCasts.bytes32ToAddress(_sender);

    uint256 originChainId = nativeToInfraChainId(_origin);

    require(originChainId != 0, 'INCORRECT_ORIGIN_CHAIN_ID');

    require(_trustedRemotes[originChainId] == srcAddress, 'REMOTE_NOT_TRUSTED');
    _registerReceivedMessage(_messageBody, originChainId);
    emit HLPayloadProcessed(originChainId, srcAddress, _messageBody);
  }

  /// @inheritdoc IHyperLaneAdapter
  function nativeToInfraChainId(
    uint32 nativeChainId
  ) public pure returns (uint256) {
    if (nativeChainId == uint32(MainnetChainIds.ETHEREUM)) {
      return MainnetChainIds.ETHEREUM;
    } else if (nativeChainId == uint32(MainnetChainIds.AVALANCHE)) {
      return MainnetChainIds.AVALANCHE;
    } else if (nativeChainId == uint32(MainnetChainIds.POLYGON)) {
      return MainnetChainIds.POLYGON;
    } else if (nativeChainId == uint32(MainnetChainIds.ARBITRUM)) {
      return MainnetChainIds.ARBITRUM;
    } else if (nativeChainId == uint32(MainnetChainIds.OPTIMISM)) {
      return MainnetChainIds.OPTIMISM;
    } else if (nativeChainId == uint32(TestnetChainIds.ETHEREUM_GOERLI)) {
      return TestnetChainIds.ETHEREUM_GOERLI;
    } else if (nativeChainId == uint32(TestnetChainIds.AVALANCHE_FUJI)) {
      return TestnetChainIds.AVALANCHE_FUJI;
    } else if (nativeChainId == uint32(TestnetChainIds.OPTIMISM_GOERLI)) {
      return TestnetChainIds.OPTIMISM_GOERLI;
    } else if (nativeChainId == uint32(TestnetChainIds.POLYGON_MUMBAI)) {
      return TestnetChainIds.POLYGON_MUMBAI;
    } else if (nativeChainId == uint32(TestnetChainIds.ARBITRUM_GOERLI)) {
      return TestnetChainIds.ARBITRUM_GOERLI;
    } else {
      return 0;
    }
  }

  /// @inheritdoc IHyperLaneAdapter
  function infraToNativeChainId(
    uint256 infraChainId
  ) public pure returns (uint32) {
    if (infraChainId == MainnetChainIds.ETHEREUM) {
      return uint32(MainnetChainIds.ETHEREUM);
    } else if (infraChainId == MainnetChainIds.AVALANCHE) {
      return uint32(MainnetChainIds.AVALANCHE);
    } else if (infraChainId == MainnetChainIds.POLYGON) {
      return uint32(MainnetChainIds.POLYGON);
    } else if (infraChainId == MainnetChainIds.ARBITRUM) {
      return uint32(MainnetChainIds.ARBITRUM);
    } else if (infraChainId == MainnetChainIds.OPTIMISM) {
      return uint32(MainnetChainIds.OPTIMISM);
    } else if (infraChainId == TestnetChainIds.ETHEREUM_GOERLI) {
      return uint32(TestnetChainIds.ETHEREUM_GOERLI);
    } else if (infraChainId == TestnetChainIds.AVALANCHE_FUJI) {
      return uint32(TestnetChainIds.AVALANCHE_FUJI);
    } else if (infraChainId == TestnetChainIds.OPTIMISM_GOERLI) {
      return uint32(TestnetChainIds.OPTIMISM_GOERLI);
    } else if (infraChainId == TestnetChainIds.POLYGON_MUMBAI) {
      return uint32(TestnetChainIds.POLYGON_MUMBAI);
    } else if (infraChainId == TestnetChainIds.ARBITRUM_GOERLI) {
      return uint32(TestnetChainIds.ARBITRUM_GOERLI);
    } else {
      return uint32(0);
    }
  }

  /**
   * @notice method to set trusted remotes. These are addresses that are allowed to receive messages from
   * @param trustedRemotes list of objects with the trusted remotes configurations
   **/
  function _updateTrustedRemotes(
    TrustedRemotesConfig[] memory trustedRemotes
  ) internal {
    for (uint256 i = 0; i < trustedRemotes.length; i++) {
      _trustedRemotes[trustedRemotes[i].originChainId] = trustedRemotes[i]
        .originForwarder;
      emit SetTrustedRemote(
        trustedRemotes[i].originChainId,
        trustedRemotes[i].originForwarder
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMailbox} from 'hyperlane-monorepo/interfaces/IMailbox.sol';
import {IInterchainGasPaymaster} from 'hyperlane-monorepo/interfaces/IInterchainGasPaymaster.sol';

/**
 * @title IHyperLaneAdapter
 * @author BGD Labs
 * @notice interface containing the events, objects and method definitions used in the HyperLane bridge adapter
 */
interface IHyperLaneAdapter {
  /**
   * @notice pair of origin address and origin chain
   * @param originForwarder address of the contract that will send the messages
   * @param originChainId id of the chain where the trusted remote is from
   */
  struct TrustedRemotesConfig {
    address originForwarder;
    uint256 originChainId;
  }

  /**
   * @notice emitted when a payload is forwarded
   * @param receiver address that will receive the payload
   * @param destinationChainId id of the chain to bridge the payload
   * @param message object to be bridged
   */
  event MessageForwarded(
    address indexed receiver,
    uint32 indexed destinationChainId,
    bytes message
  );

  /**
   * @notice emitted when a trusted remote is set
   * @param originChainId id of the chain where the trusted remote is from
   * @param originForwarder address of the contract that will send the messages
   */
  event SetTrustedRemote(
    uint256 indexed originChainId,
    address indexed originForwarder
  );

  /**
   * @notice emitted when a message is received and has been correctly processed
   * @param originChainId id of the chain where the message originated from
   * @param srcAddress address that sent the message (origin CrossChainContract)
   * @param _messageBody bridged message
   */
  event HLPayloadProcessed(
    uint256 indexed originChainId,
    address indexed srcAddress,
    bytes _messageBody
  );

  /**
   * @notice method to get the current Mail Box address
   * @return the address of the HyperLane Mail Box
   */
  function HL_MAIL_BOX() external view returns (IMailbox);

  /**
   * @notice method to get the current IGP address
   * @return the address of the HyperLane IGP
   */
  function IGP() external view returns (IInterchainGasPaymaster);

  /**
   * @notice method to get the trusted remote for a chain
   * @param chainId id of the chain to get the trusted remote address from
   * @return address of the trusted remote
   */
  function getTrustedRemoteByChainId(
    uint256 chainId
  ) external view returns (address);

  /**
   * @notice method to get infrastructure chain id from bridge native chain id
   * @param bridgeChainId bridge native chain id
   */
  function nativeToInfraChainId(
    uint32 bridgeChainId
  ) external returns (uint256);

  /**
   * @notice method to get bridge native chain id from native bridge chain id
   * @param infraChainId infrastructure chain id
   */
  function infraToNativeChainId(uint256 infraChainId) external returns (uint32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/**
 * @title ICrossChainForwarder
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the CrossChainForwarder contract
 */
interface ICrossChainForwarder {
  /**
   * @notice object storing the connected pair of bridge adapters, on current and destination chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current network
   */
  struct ChainIdBridgeConfig {
    address destinationBridgeAdapter;
    address currentChainBridgeAdapter;
  }

  /**
   * @notice object with the necessary information to remove bridge adapters
   * @param bridgeAdapter address of the bridge adapter to remove
   * @param chainIds array of chain ids where the bridge adapter connects
   */
  struct BridgeAdapterToDisable {
    address bridgeAdapter;
    uint256[] chainIds;
  }

  /**
   * @notice object storing the pair bridgeAdapter (current deployed chain) destination chain bridge adapter configuration
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param dstChainId id of the destination chain using our own nomenclature
   */
  struct BridgeAdapterConfigInput {
    address currentChainBridgeAdapter;
    address destinationBridgeAdapter;
    uint256 destinationChainId;
  }

  /**
   * @notice emitted when a bridge adapter failed to send a message
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter that failed (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param destinationChainId id of destination chain
   * @param message bytes intended to be bridged
   * @param returndata bytes with error information
   */
  event AdapterFailed(
    uint256 indexed destinationChainId,
    address indexed bridgeAdapter,
    address indexed destinationBridgeAdapter,
    bytes message,
    bytes returndata
  );

  /**
   * @notice emitted when a message is successfully forwarded through a bridge adapter
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter that failed (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param destinationChainId id of destination chain
   * @param message bytes intended to be bridged
   */
  event MessageForwarded(
    uint256 indexed destinationChainId,
    address indexed bridgeAdapter,
    address indexed destinationBridgeAdapter,
    bytes message
  );

  /**
   * @notice emitted when a bridge adapter has been added to the allowed list
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter added (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param allowed boolean indicating if the bridge adapter is allowed or disallowed
   */
  event BridgeAdapterUpdated(
    uint256 indexed destinationChainId,
    address indexed bridgeAdapter,
    address destinationBridgeAdapter,
    bool indexed allowed
  );

  /**
   * @notice emitted when a sender has been updated
   * @param sender address of the updated sender
   * @param isApproved boolean that indicates if the sender has been approved or removed
   */
  event SenderUpdated(address indexed sender, bool indexed isApproved);

  /**
   * @notice method to get the current sent message nonce
   * @return the current nonce
   */
  function getCurrentNonce() external view returns (uint256);

  /**
   * @notice method to check if a message has been previously forwarded.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param origin address where the message originates from
   * @param destination address where the message is intended for
   * @param message bytes that need to be bridged
   * @return boolean indicating if the message has been forwarded
   */
  function isMessageForwarded(
    uint256 destinationChainId,
    address origin,
    address destination,
    bytes memory message
  ) external view returns (bool);

  /**
   * @notice method called to initiate message forwarding to other networks.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param destination address where the message is intended for
   * @param gasLimit gas cost on receiving side of the message
   * @param message bytes that need to be bridged
   */
  function forwardMessage(
    uint256 destinationChainId,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) external;

  /**
   * @notice method called to re forward a previously sent message.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param origin address where the message originates from
   * @param destination address where the message is intended for
   * @param gasLimit gas cost on receiving side of the message
   * @param message bytes that need to be bridged
   */
  function retryMessage(
    uint256 destinationChainId,
    address origin,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) external;

  /**
   * @notice method to enable bridge adapters
   * @param bridgeAdapters array of new bridge adapter configurations
   */
  function enableBridgeAdapters(
    BridgeAdapterConfigInput[] memory bridgeAdapters
  ) external;

  /**
   * @notice method to disable bridge adapters
   * @param bridgeAdapters array of bridge adapter addresses to disable
   */
  function disableBridgeAdapters(
    BridgeAdapterToDisable[] memory bridgeAdapters
  ) external;

  /**
   * @notice method to remove sender addresses
   * @param senders list of addresses to remove
   */
  function removeSenders(address[] memory senders) external;

  /**
   * @notice method to approve new sender addresses
   * @param senders list of addresses to approve
   */
  function approveSenders(address[] memory senders) external;

  /**
   * @notice method to get all the bridge adapters of a chain
   * @param chainId id of the chain we want to get the adateprs from
   * @return an array of chain configurations where the bridge adapter can communicate
   */
  function getBridgeAdaptersByChain(
    uint256 chainId
  ) external view returns (ChainIdBridgeConfig[] memory);

  /**
   * @notice method to get if a sender is approved
   * @param sender address that we want to check if approved
   * @return boolean indicating if the address has been approved as sender
   */
  function isSenderApproved(address sender) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICrossChainForwarder.sol';
import './ICrossChainReceiver.sol';

/**
 * @title ICrossChainManager
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the CrossChainManager contract
 */
interface ICrossChainManager is ICrossChainForwarder, ICrossChainReceiver {
  /**
   * @notice method called to initialize the proxy
   * @param owner address of the owner of the cross chain manager
   * @param guardian address of the guardian of the cross chain manager
   * @param clEmergencyOracle address of the chainlink emergency oracle
   * @param initialRequiredConfirmations number of confirmations the messages need to be accepted as valid
   * @param receiverBridgeAdaptersToAllow array of addresses of the bridge adapters that can receive messages
   * @param forwarderBridgeAdaptersToEnable array specifying for every bridgeAdapter, the destinations it can have
   * @param sendersToApprove array of addresses to allow as forwarders
   */
  function initialize(
    address owner,
    address guardian,
    address clEmergencyOracle,
    uint256 initialRequiredConfirmations,
    address[] memory receiverBridgeAdaptersToAllow,
    BridgeAdapterConfigInput[] memory forwarderBridgeAdaptersToEnable,
    address[] memory sendersToApprove
  ) external;

  /**
   * @notice method called to rescue tokens sent erroneously to the contract. Only callable by owner
   * @param erc20Token address of the token to rescue
   * @param to address to send the tokens
   * @param amount of tokens to rescue
   */
  function emergencyTokenTransfer(
    address erc20Token,
    address to,
    uint256 amount
  ) external;

  /**
   * @notice method called to rescue ether sent erroneously to the contract. Only callable by owner
   * @param to address to send the eth
   * @param amount of eth to rescue
   */
  function emergencyEtherTransfer(address to, uint256 amount) external;

  /**
  * @notice method to check if there is a new emergency state, indicated by chainlink emergency oracle.
         This method is callable by anyone as a new emergency will be determined by the oracle, and this way
         it will be easier / faster to enter into emergency.
  * @param newConfirmations number of confirmations necessary for a message to be routed to destination
  * @param newValidityTimestamp timestamp in seconds indicating the point to where not confirmed messages will be
  *        invalidated.
  * @param receiverBridgeAdaptersToAllow list of bridge adapter addresses to be allowed to receive messages
  * @param receiverBridgeAdaptersToDisallow list of bridge adapter addresses to be disallowed
  * @param sendersToApprove list of addresses to be approved as senders
  * @param sendersToRemove list of sender addresses to be removed
  * @param forwarderBridgeAdaptersToEnable list of bridge adapters to be enabled to send messages
  * @param forwarderBridgeAdaptersToDisable list of bridge adapters to be disabled
  */
  function solveEmergency(
    uint256 newConfirmations,
    uint120 newValidityTimestamp,
    address[] memory receiverBridgeAdaptersToAllow,
    address[] memory receiverBridgeAdaptersToDisallow,
    address[] memory sendersToApprove,
    address[] memory sendersToRemove,
    BridgeAdapterConfigInput[] memory forwarderBridgeAdaptersToEnable,
    BridgeAdapterToDisable[] memory forwarderBridgeAdaptersToDisable
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/**
 * @title ICrossChainReceiver
 * @author BGD Labs
 * @notice interface containing the objects, events and methods definitions of the CrossChainReceiver contract
 */
interface ICrossChainReceiver {
  /**
   * @notice object that stores the internal information of the message
   * @param confirmations number of times that this message has been bridged
   * @param bridgedByAdapterNonce stores the nonce of when the message has been bridged by a determined bridge adapter
   * @param delivered boolean indicating if the bridged message has been delivered to the destination
   */
  struct InternalBridgedMessageStateWithoutAdapters {
    uint120 confirmations;
    uint120 firstBridgedAt;
    bool delivered;
  }
  /**
   * @notice object that stores the internal information of the message
   * @param confirmations number of times that this message has been bridged
   * @param bridgedByAdapterNonce stores the nonce of when the message has been bridged by a determined bridge adapter
   * @param delivered boolean indicating if the bridged message has been delivered to the destination
   * @param bridgedByAdapter list of bridge adapters that have bridged the message
   */
  struct InternalBridgedMessage {
    uint120 confirmations;
    uint120 firstBridgedAt;
    bool delivered;
    mapping(address => bool) bridgedByAdapter;
  }

  /**
   * @notice emitted when a message has reached the necessary number of confirmations
   * @param msgDestination address of consumer of the message
   * @param msgOrigin address where the message originated
   * @param message bytes confirmed
   */
  event MessageConfirmed(
    address indexed msgDestination,
    address indexed msgOrigin,
    bytes message
  );

  /**
   * @notice emitted when a message has been received successfully
   * @param internalId message id assigned on the manager, used for internal purposes: hash(to, from, message)
   * @param bridgeAdapter address of the bridge adapter who received the message (deployed on current network)
   * @param msgDestination address of consumer of the message
   * @param msgOrigin address where the message originated (CrossChainManager on origin chain)
   * @param message bytes bridged
   * @param confirmations number of current confirmations for this message
   */
  event MessageReceived(
    bytes32 internalId,
    address indexed bridgeAdapter,
    address indexed msgDestination,
    address indexed msgOrigin,
    bytes message,
    uint256 confirmations
  );

  /**
   * @notice emitted when a bridge adapter gets disallowed
   * @param brigeAdapter address of the disallowed bridge adapter
   * @param allowed boolean indicating if the bridge adapter has been allowed or disallowed
   */
  event ReceiverBridgeAdaptersUpdated(
    address indexed brigeAdapter,
    bool indexed allowed
  );

  /**
   * @notice emitted when number of confirmations needed to validate a message changes
   * @param newConfirmations number of new confirmations needed for a message to be valid
   */
  event ConfirmationsUpdated(uint256 newConfirmations);

  /**
   * @notice emitted when a new timestamp for invalidations gets set
   * @param invalidTimestamp timestamp to invalidate previous messages
   */
  event NewInvalidation(uint256 invalidTimestamp);

  /**
   * @notice method to get the needed confirmations for a message to be accepted as valid
   * @return the number of required bridged message confirmations (how many bridges have bridged the message correctly)
   *         for a message to be sent to destination
   */
  function getRequiredConfirmations() external view returns (uint256);

  /**
   * @notice method to get the timestamp from where the messages will be valid
   * @return timestamp indicating the point from where the messages are valid.
   */
  function getValidityTimestamp() external view returns (uint120);

  /**
   * @notice method to get if a bridge adapter is allowed
   * @param bridgeAdapter address of the brige adapter to check
   * @return boolean indicating if brige adapter is allowed
   */
  function isReceiverBridgeAdapterAllowed(
    address bridgeAdapter
  ) external view returns (bool);

  /**
   * @notice  method to get the internal message information
   * @param internalId hash(originChain + payload) identifying the message internally
   * @return number of confirmations of internal message identified by internalId and the updated timestamp
   */
  function getInternalMessageState(
    bytes32 internalId
  ) external view returns (InternalBridgedMessageStateWithoutAdapters memory);

  /**
   * @notice method to get if message has been received by bridge adapter
   * @param internalId id of the message as stored internally
   * @param bridgeAdapter address of the bridge adapter to check if it has bridged the message
   * @return boolean indicating if the message has been received
   */
  function isInternalMessageReceivedByAdapter(
    bytes32 internalId,
    address bridgeAdapter
  ) external view returns (bool);

  /**
   * @notice method to set a new timestamp from where the messages will be valid.
   * @param newValidityTimestamp timestamp where all the previous unconfirmed messages must be invalidated.
   */
  function updateMessagesValidityTimestamp(
    uint120 newValidityTimestamp
  ) external;

  /**
   * @notice method to update the number of confirmations necessary for the messages to be accepted as valid
   * @param newConfirmations new number of needed confirmations
   */
  function updateConfirmations(uint256 newConfirmations) external;

  /**
   * @notice method that registers a received message, updates the confirmations, and sets it as valid if number
   of confirmations has been reached.
   * @param payload bytes of the payload, containing the information to operate with it
   */
  function receiveCrossChainMessage(
    bytes memory payload,
    uint256 originChainId
  ) external;

  /**
   * @notice method to add bridge adapters to the allowed list
   * @param bridgeAdapters array of new bridge adapter configurations
   */
  function allowReceiverBridgeAdapters(
    address[] memory bridgeAdapters
  ) external;

  /**
   * @notice method to remove bridge adapters from the allowed list
   * @param bridgeAdapters array of bridge adapter addresses to remove from the allow list
   */
  function disallowReceiverBridgeAdapters(
    address[] memory bridgeAdapters
  ) external;
}

library MainnetChainIds {
  uint256 constant ETHEREUM = 1;
  uint256 constant POLYGON = 137;
  uint256 constant AVALANCHE = 43114;
  uint256 constant ARBITRUM = 42161;
  uint256 constant OPTIMISM = 10;
  uint256 constant FANTOM = 250;
  uint256 constant HARMONY = 1666600000;
}

library TestnetChainIds {
  uint256 constant ETHEREUM_GOERLI = 5;
  uint256 constant POLYGON_MUMBAI = 80001;
  uint256 constant AVALANCHE_FUJI = 43113;
  uint256 constant ARBITRUM_GOERLI = 421613;
  uint256 constant OPTIMISM_GOERLI = 420;
  uint256 constant FANTOM_TESTNET = 4002;
  uint256 constant HARMONY_TESTNET = 1666700000;
}