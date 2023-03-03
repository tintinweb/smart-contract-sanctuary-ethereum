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
import {ICCIPAdapter, IRouterClient} from './ICCIPAdapter.sol';
import {IAny2EVMMessageReceiver, Client} from './interfaces/IAny2EVMMessageReceiver.sol';
import {IERC165} from './interfaces/IERC165.sol';
import {MainnetChainIds, TestnetChainIds} from '../../libs/ChainIds.sol';

/**
 * @title CCIPAdapter
 * @author BGD Labs
 * @notice CCIP bridge adapter. Used to send and receive messages cross chain
 * @dev it uses the eth balance of CrossChainManager contract to pay for message bridging as the method to bridge
        is called via delegate call
 */
contract CCIPAdapter is
  ICCIPAdapter,
  BaseAdapter,
  IAny2EVMMessageReceiver,
  IERC165
{
  /// @inheritdoc ICCIPAdapter
  IRouterClient public immutable CCIP_ROUTER;

  // (chain -> origin forwarder address) saves for every chain the address that can forward messages to this adapter
  mapping(uint256 => address) internal _trustedRemotes;

  /**
   * @notice only calls from the set router are accepted.
   */
  modifier onlyRouter() {
    require(msg.sender == address(CCIP_ROUTER), 'CALLER_NOT_ROUTER');
    _;
  }

  /**
   * @param crossChainManager address of the cross chain manager that will use this bridge adapter
   * @param ccipRouter ccip entry point address
   * @param trustedRemotes list of remote configurations to set as trusted
   */
  constructor(
    address crossChainManager,
    address ccipRouter,
    TrustedRemotesConfig[] memory trustedRemotes
  ) BaseAdapter(crossChainManager) {
    require(ccipRouter != address(0), 'ROUTER_CANT_BE_ADDRESS_0');
    CCIP_ROUTER = IRouterClient(ccipRouter);

    _updateTrustedRemotes(trustedRemotes);
  }

  /// @inheritdoc ICCIPAdapter
  function getTrustedRemoteByChainId(
    uint256 chainId
  ) external view returns (address) {
    return _trustedRemotes[chainId];
  }

  /// @inheritdoc IERC165
  function supportsInterface(
    bytes4 interfaceId
  ) public pure override returns (bool) {
    return
      interfaceId == type(IAny2EVMMessageReceiver).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  /// @inheritdoc IBaseAdapter
  function forwardMessage(
    address receiver,
    uint256 gasLimit,
    uint256 destinationChainId,
    bytes memory message
  ) external {
    uint64 nativeDestinationChainId = infraToNativeChainId(destinationChainId);

    require(
      CCIP_ROUTER.isChainSupported(nativeDestinationChainId),
      'DESTINATION_CHAIN_ID_NOT_SUPPORTED'
    );
    require(receiver != address(0), 'RECEIVER_NOT_SET');

    Client.EVMExtraArgsV1 memory evmExtraArgs = Client.EVMExtraArgsV1({
      gasLimit: gasLimit,
      strict: false
    });

    bytes memory extraArgs = Client._argsToBytes(evmExtraArgs);

    Client.EVM2AnyMessage memory payload = Client.EVM2AnyMessage({
      receiver: abi.encode(receiver),
      data: message,
      tokenAmounts: new Client.EVMTokenAmount[](0),
      feeToken: address(0), // We leave the feeToken empty indicating we'll pay with native gas tokens.,
      extraArgs: extraArgs
    });

    uint256 clFee = CCIP_ROUTER.getFee(nativeDestinationChainId, payload);

    require(
      address(this).balance >= clFee,
      'NOT_ENOUGH_VALUE_TO_PAY_BRIDGE_FEES'
    );

    bytes32 messageId = CCIP_ROUTER.ccipSend{value: clFee}(
      nativeDestinationChainId,
      payload
    );

    emit MessageForwarded(
      receiver,
      nativeDestinationChainId,
      messageId,
      message
    );
  }

  /// @inheritdoc IAny2EVMMessageReceiver
  function ccipReceive(
    Client.Any2EVMMessage calldata message
  ) external onlyRouter {
    address srcAddress = abi.decode(message.sender, (address));

    uint256 originChainId = nativeToInfraChainId(message.sourceChainId);

    require(originChainId != 0, 'INCORRECT_ORIGIN_CHAIN_ID');

    require(_trustedRemotes[originChainId] == srcAddress, 'REMOTE_NOT_TRUSTED');

    _registerReceivedMessage(message.data, originChainId);
    emit CCIPPayloadProcessed(originChainId, srcAddress, message.data);
  }

  /// @inheritdoc ICCIPAdapter
  function nativeToInfraChainId(
    uint64 nativeChainId
  ) public pure returns (uint256) {
    if (nativeChainId == uint64(MainnetChainIds.ETHEREUM)) {
      return MainnetChainIds.ETHEREUM;
    } else if (nativeChainId == uint64(MainnetChainIds.AVALANCHE)) {
      return MainnetChainIds.AVALANCHE;
    } else if (nativeChainId == uint64(MainnetChainIds.POLYGON)) {
      return MainnetChainIds.POLYGON;
    } else if (nativeChainId == uint64(MainnetChainIds.ARBITRUM)) {
      return MainnetChainIds.ARBITRUM;
    } else if (nativeChainId == uint64(MainnetChainIds.OPTIMISM)) {
      return MainnetChainIds.OPTIMISM;
    } else if (nativeChainId == uint64(MainnetChainIds.FANTOM)) {
      return MainnetChainIds.FANTOM;
    } else if (nativeChainId == uint64(MainnetChainIds.HARMONY)) {
      return MainnetChainIds.HARMONY;
    } else if (nativeChainId == uint64(TestnetChainIds.ETHEREUM_GOERLI)) {
      return TestnetChainIds.ETHEREUM_GOERLI;
    } else if (nativeChainId == uint64(TestnetChainIds.AVALANCHE_FUJI)) {
      return TestnetChainIds.AVALANCHE_FUJI;
    } else if (nativeChainId == uint64(TestnetChainIds.OPTIMISM_GOERLI)) {
      return TestnetChainIds.OPTIMISM_GOERLI;
    } else if (nativeChainId == uint64(TestnetChainIds.POLYGON_MUMBAI)) {
      return TestnetChainIds.POLYGON_MUMBAI;
    } else {
      return 0;
    }
  }

  /// @inheritdoc ICCIPAdapter
  function infraToNativeChainId(
    uint256 infraChainId
  ) public pure returns (uint64) {
    if (infraChainId == MainnetChainIds.ETHEREUM) {
      return uint64(MainnetChainIds.ETHEREUM);
    } else if (infraChainId == MainnetChainIds.AVALANCHE) {
      return uint64(MainnetChainIds.AVALANCHE);
    } else if (infraChainId == MainnetChainIds.POLYGON) {
      return uint64(MainnetChainIds.POLYGON);
    } else if (infraChainId == MainnetChainIds.ARBITRUM) {
      return uint64(MainnetChainIds.ARBITRUM);
    } else if (infraChainId == MainnetChainIds.OPTIMISM) {
      return uint64(MainnetChainIds.OPTIMISM);
    } else if (infraChainId == MainnetChainIds.FANTOM) {
      return uint64(MainnetChainIds.FANTOM);
    } else if (infraChainId == MainnetChainIds.HARMONY) {
      return uint64(MainnetChainIds.HARMONY);
    } else if (infraChainId == TestnetChainIds.ETHEREUM_GOERLI) {
      return uint64(TestnetChainIds.ETHEREUM_GOERLI);
    } else if (infraChainId == TestnetChainIds.AVALANCHE_FUJI) {
      return uint64(TestnetChainIds.AVALANCHE_FUJI);
    } else if (infraChainId == TestnetChainIds.OPTIMISM_GOERLI) {
      return uint64(TestnetChainIds.OPTIMISM_GOERLI);
    } else if (infraChainId == TestnetChainIds.POLYGON_MUMBAI) {
      return uint64(TestnetChainIds.POLYGON_MUMBAI);
    } else {
      return uint64(0);
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

import {IRouterClient} from './interfaces/IRouterClient.sol';

/**
 * @title ICCIPAdapter
 * @author BGD Labs
 * @notice interface containing the events, objects and method definitions used in the CCIP bridge adapter
 */
interface ICCIPAdapter {
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
   * @param messageId CCIP id of the message forwarded
   * @param message object to be bridged
   */
  event MessageForwarded(
    address indexed receiver,
    uint64 indexed destinationChainId,
    bytes32 indexed messageId,
    bytes message
  );

  /**
   * @notice emitted when a message is received and has been correctly processed
   * @param srcChainId id of the chain where the message originated from
   * @param srcAddress address that sent the message (origin CrossChainContract)
   * @param data bridged message
   */
  event CCIPPayloadProcessed(
    uint256 indexed srcChainId,
    address indexed srcAddress,
    bytes data
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
   * @notice method to get the CCIP router address
   * @return adddress of the CCIP router
   */
  function CCIP_ROUTER() external view returns (IRouterClient);

  /**
   * @notice method to get the trusted remote address from a specified chain id
   * @param chainId id of the chain from where to get the trusted remote
   * @return address of the trusted remote
   */
  function getTrustedRemoteByChainId(
    uint256 chainId
  ) external view returns (address);

  /**
   * @notice method to get infrastructure chain id from bridge native chain id
   * @param nativeChainId bridge native chain id
   */
  function nativeToInfraChainId(
    uint64 nativeChainId
  ) external pure returns (uint256);

  /**
   * @notice method to get bridge native chain id from native bridge chain id
   * @param infraChainId infrastructure chain id
   */
  function infraToNativeChainId(
    uint256 infraChainId
  ) external pure returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from '../lib/Client.sol';

/// @notice Application contracts that intend to receive messages from
/// the router should implement this interface.
interface IAny2EVMMessageReceiver {
  /// @notice Router calls this to deliver a message.
  /// If this reverts, any token transfers also revert. The message
  /// will move to a FAILED state and become available for manual execution
  /// as a retry. Fees already paid are NOT currently refunded (may change).
  /// @param message CCIP Message
  /// @dev Note ensure you check the msg.sender is the router
  function ccipReceive(Client.Any2EVMMessage calldata message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
  // @dev Should indicate whether the contract implements IAny2EVMMessageReceiver
  // e.g. return interfaceId == type(IAny2EVMMessageReceiver).interfaceId
  // This allows CCIP to check if ccipReceive is available before calling it.
  // If this returns false, only tokens are transferred to the receiver.
  // If this returns true, tokens are transferred and ccipReceive is called atomically.
  // Additionally, if the receiver address does not have code associated with
  // it at the time of execution (EXTCODESIZE returns 0), only tokens will be transferred.
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Client library above
import {Client} from '../lib/Client.sol';

interface IRouterClient {
  error UnsupportedDestinationChain(uint64 destinationChainId);
  /// @dev Sender is not whitelisted
  error SenderNotAllowed(address sender);
  error InsufficientFeeTokenAmount();
  /// @dev Sent msg.value with a non-empty feeToken
  error InvalidMsgValue();

  /// @notice Checks if the given chain ID is supported for sending/receiving.
  /// @param chainId The chain to check
  /// @return supported is true if it is supported, false if not
  function isChainSupported(
    uint64 chainId
  ) external view returns (bool supported);

  /// @notice Gets a list of all supported tokens which can be sent or received
  /// to/from a given chain id.
  /// @param chainId The chainId.
  /// @return tokens The addresses of all tokens that are supported.
  function getSupportedTokens(
    uint64 chainId
  ) external view returns (address[] memory tokens);

  /// @param destinationChainId The destination chain ID
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return fee returns guaranteed execution fee for the specified message
  /// delivery to destination chain
  /// @dev returns 0 fee on invalid message.
  function getFee(
    uint64 destinationChainId,
    Client.EVM2AnyMessage memory message
  ) external view returns (uint256 fee);

  /// @notice Request a message to be sent to the destination chain
  /// @param destinationChainId The destination chain ID
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return messageId The message ID
  /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
  /// the overpayment with no refund.
  function ccipSend(
    uint64 destinationChainId,
    Client.EVM2AnyMessage calldata message
  ) external payable returns (bytes32 messageId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Client {
  struct EVMTokenAmount {
    address token; // token address on the local chain
    uint256 amount;
  }

  struct Any2EVMMessage {
    bytes32 messageId; // MessageId corresponding to ccipSend on source
    uint64 sourceChainId;
    bytes sender; // abi.decode(sender) if coming from an EVM chain
    bytes data; // payload sent in original message
    EVMTokenAmount[] tokenAmounts;
  }

  struct EVM2AnyMessage {
    bytes receiver; // abi.encode(receiver address) for dest EVM chains
    bytes data; // Data payload
    EVMTokenAmount[] tokenAmounts; // Token transfers
    address feeToken; // Address of feeToken. address(0) means you will send msg.value.
    bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
  }

  // extraArgs will evolve to support new features
  // bytes4(keccak256("CCIP EVMExtraArgsV1"));
  bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
  struct EVMExtraArgsV1 {
    uint256 gasLimit; // ATTENTION!!! MAX GAS LIMIT 4M FOR ALPHA TESTING
    bool strict; // See strict sequencing details below.
  }
  function _argsToBytes(EVMExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
  }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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