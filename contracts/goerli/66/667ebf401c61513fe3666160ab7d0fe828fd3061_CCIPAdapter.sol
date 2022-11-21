// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CrossChainUtils {
  enum Chains {
    Null_network, // to not use 0
    EthMainnet,
    Polygon,
    Avalanche,
    Harmony,
    Arbitrum,
    Fantom,
    Optimism,
    Goerli,
    AvalancheFuji,
    OptimismGoerli,
    PolygonMumbai,
    ArbitrumGoerli,
    FantomTestnet,
    HarmonyTestnet
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IBaseAdapter, CrossChainUtils} from './IBaseAdapter.sol';
import {ICrossChainManager} from '../interfaces/ICrossChainManager.sol';

abstract contract BaseAdapter is IBaseAdapter {
  ICrossChainManager public immutable CROSS_CHAIN_MANAGER;

  constructor(address crossChainManager) {
    CROSS_CHAIN_MANAGER = ICrossChainManager(crossChainManager);
  }

  /// @dev calls bridge aggregator to register the bridged payload
  function _registerReceivedMessage(
    bytes memory _payload,
    CrossChainUtils.Chains originChainId
  ) internal {
    CROSS_CHAIN_MANAGER.receiveCrossChainMessage(_payload, originChainId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrossChainUtils} from '../CrossChainUtils.sol';

interface IBaseAdapter {
  /**
   * @dev emitted when a payload is forwarded
   * @param receiver address that will receive the payload
   * @param destinationChainId id of the chain to bridge the payload
   * @param message object to be bridged
   * @param nonce outbound nonce
   */
  event MessageForwarded(
    address indexed receiver,
    uint16 indexed destinationChainId,
    bytes message,
    uint256 nonce
  );

  /**
   * @dev method that will bridge the payload to the chain specified
   * @param receiver address of the receiver contract on destination chain
   * @param gasLimit amount of the gas limit in wei to use for bridging on receiver side. Each adapter will manage this
            as needed
   * @param destinationChainId id of the destination chain in the bridge notation
   * @param message to send to the specified chain
   */
  function forwardMessage(
    address receiver, // TODO: this should be renamed as is the bridge adapter on receiving side
    uint256 gasLimit,
    CrossChainUtils.Chains destinationChainId,
    bytes memory message
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICLSubscription} from './interfaces/ICLSubscription.sol';
import {IEVM2AnySubscriptionOnRampRouter} from './interfaces/IEVM2AnySubscriptionOnRampRouter.sol';
import {IAny2EVMMessageReceiver} from './interfaces/IAny2EVMMessageReceiver.sol';
import {BaseAdapter, CrossChainUtils} from '../BaseAdapter.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {ICCIPAdapter, CrossChainUtils} from './interfaces/ICCIPAdapter.sol';

contract CCIPAdapter is ICCIPAdapter, BaseAdapter, IAny2EVMMessageReceiver {
  address public immutable CCIP_OFF_RAMP_ROUTER;
  address public immutable CCIP_ON_RAMP_ROUTER;
  //  address public immutable SUBSCRIPTION_MANAGER;

  mapping(CrossChainUtils.Chains => address) _trustedRemotes;

  constructor(
    address crossChainManager,
    address ccipOffRampRouter,
    address ccipOnRampRouter,
    //    address subscriptionManager,
    TrustedRemotesConfig[] memory trustedRemotes
  ) BaseAdapter(crossChainManager) {
    CCIP_OFF_RAMP_ROUTER = ccipOffRampRouter;
    CCIP_ON_RAMP_ROUTER = ccipOnRampRouter;
    _updateTrustedRemotes(trustedRemotes);
    //    _createrReceiverSubscription(subscriptionManager, trustedRemotes);
  }

  /// @dev implements forwardMessage from IBaseAdapter
  function forwardMessage(
    address receiver,
    uint256 gasLimit,
    CrossChainUtils.Chains destinationChainId,
    bytes memory message //    uint256 gasLimit
  ) external {
    IEVM2AnySubscriptionOnRampRouter.EVM2AnySubscriptionMessage memory payload = IEVM2AnySubscriptionOnRampRouter
      .EVM2AnySubscriptionMessage({
        receiver: abi.encode(receiver),
        data: message,
        tokens: new IERC20[](0),
        amounts: new uint256[](0),
        gasLimit: gasLimit
      });

    uint256 nativeDestinationChainId = infraToNativeChainId(destinationChainId);

    IEVM2AnySubscriptionOnRampRouter(CCIP_ON_RAMP_ROUTER).ccipSend(
      nativeDestinationChainId,
      payload
    );
  }

  /// @inheritdoc IAny2EVMMessageReceiver
  function ccipReceive(Any2EVMMessage calldata message) external {
    require(msg.sender == CCIP_OFF_RAMP_ROUTER, 'CALLER_NOT_OFF_RAMP_ROUTER');
    address srcAddress = abi.decode(message.sender, (address));

    CrossChainUtils.Chains originChainId = nativeToInfraChainId(
      message.srcChainId
    );

    require(_trustedRemotes[originChainId] == srcAddress, 'REMOTE_NOT_TRUSTED');

    _registerReceivedMessage(message.data, originChainId);
    emit CCIPPayloadProcessed(originChainId, srcAddress, message.data);
  }

  function nativeToInfraChainId(uint256 nativeChainId)
    public
    pure
    returns (CrossChainUtils.Chains)
  {
    if (nativeChainId == 1) {
      return CrossChainUtils.Chains.EthMainnet;
    } else if (nativeChainId == 43114) {
      return CrossChainUtils.Chains.Avalanche;
    } else if (nativeChainId == 137) {
      return CrossChainUtils.Chains.Polygon;
    } else if (nativeChainId == 42161) {
      return CrossChainUtils.Chains.Arbitrum;
    } else if (nativeChainId == 10) {
      return CrossChainUtils.Chains.Optimism;
    } else if (nativeChainId == 250) {
      return CrossChainUtils.Chains.Fantom;
    } else if (nativeChainId == 1666600000) {
      return CrossChainUtils.Chains.Harmony;
    } else if (nativeChainId == 5) {
      return CrossChainUtils.Chains.Goerli;
    } else if (nativeChainId == 43113) {
      return CrossChainUtils.Chains.AvalancheFuji;
    } else if (nativeChainId == 420) {
      return CrossChainUtils.Chains.OptimismGoerli;
    } else if (nativeChainId == 80001) {
      return CrossChainUtils.Chains.PolygonMumbai;
    } else {
      return CrossChainUtils.Chains.Null_network;
    }
  }

  function infraToNativeChainId(CrossChainUtils.Chains infraChainId)
    public
    pure
    returns (uint256)
  {
    if (infraChainId == CrossChainUtils.Chains.EthMainnet) {
      return 1;
    } else if (infraChainId == CrossChainUtils.Chains.Avalanche) {
      return 43114;
    } else if (infraChainId == CrossChainUtils.Chains.Polygon) {
      return 137;
    } else if (infraChainId == CrossChainUtils.Chains.Arbitrum) {
      return 42161;
    } else if (infraChainId == CrossChainUtils.Chains.Optimism) {
      return 10;
    } else if (infraChainId == CrossChainUtils.Chains.Fantom) {
      return 250;
    } else if (infraChainId == CrossChainUtils.Chains.Harmony) {
      return 1666600000;
    } else if (infraChainId == CrossChainUtils.Chains.Goerli) {
      return 5;
    } else if (infraChainId == CrossChainUtils.Chains.AvalancheFuji) {
      return 43113;
    } else if (infraChainId == CrossChainUtils.Chains.OptimismGoerli) {
      return 420;
    } else if (infraChainId == CrossChainUtils.Chains.PolygonMumbai) {
      return 80001;
    } else {
      return 0;
    }
  }

  //  function _createReceiverSubscription(
  //    address subscriptionManager,
  //    TrustedRemotes[] memory trustedRemotes
  //  ) internal {
  //    require(IERC20().balanceOf(address(this)));
  //    SUBSCRIPTION_MANAGER = subscriptionManager;
  //
  //    address[] memory messageSenders = new address[](trustedRemotes.length);
  //
  //    for (uint256 i = 0; i < trustedRemotes.length; i++) {
  //      messageSenders[i] = trustedRemotes[i].originForwarder;
  //    }
  //
  //    // TODO: subscription should provably be owned by cross chain manager, and used by the adapter. this way
  //    // if we need to substitute the adapter the owner of the subscription will be the manager and we will only have to whitelist a new user
  //    // no idea if we can do it though, or set it up from here, so its transparent for cross chain manager
  //    ICLSubscription.OffRampSubscription memory subscription = ICLSubscription
  //      .OffRampSubscription({
  //        senders: messageSenders,
  //        receiver: subscriptionManager, // TODO: who is the receiver?
  //        strictSequencing: true,
  //        balance: 0 // TODO: what is the balance that we must put here?
  //      });
  //    ICLSubscription().createSubscription();
  //  }

  function _updateTrustedRemotes(TrustedRemotesConfig[] memory trustedRemotes)
    internal
  {
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

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

/**
 * @notice Application contracts that intend to receive CCIP messages from
 * the OffRampRouter should implement this interface.
 */
interface IAny2EVMMessageReceiver {
  struct Any2EVMMessage {
    uint256 srcChainId;
    bytes sender;
    bytes data;
    IERC20[] destTokens;
    uint256[] amounts;
  }

  /**
   * @notice Called by the OffRampRouter to deliver a message
   * @param message CCIP Message
   * @dev Note ensure you check the msg.sender is the OffRampRouter
   */
  function ccipReceive(Any2EVMMessage calldata message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrossChainUtils} from '../../../CrossChainUtils.sol';

interface ICCIPAdapter {
  /// @dev pair of origin address and origin chain
  struct TrustedRemotesConfig {
    address originForwarder;
    CrossChainUtils.Chains originChainId;
  }

  event CCIPPayloadProcessed(
    CrossChainUtils.Chains indexed srcChainId,
    address indexed srcAddress,
    bytes data
  );

  event SetTrustedRemote(
    CrossChainUtils.Chains indexed originChainId,
    address indexed originForwarder
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISubscriptionManager} from './ISubscriptionManager.sol';

interface ICLSubscription {
  error SubscriptionAlreadyExists();
  error DelayNotPassedYet(uint256 allowedBy);
  error AddressMismatch(address expected, address got);
  error AmountMismatch(uint256 expected, uint256 got);
  error BalanceTooLow();
  error SubscriptionNotFound(address receiver);
  error InvalidManager();
  error FundingAmountNotPositive();

  struct OffRampSubscription {
    address[] senders;
    ISubscriptionManager receiver;
    bool strictSequencing;
    uint256 balance;
  }

  /**
   * @notice Gets the subscription corresponding to the given receiver
   * @param receiver The receiver for which to get the subscription
   * @return The subscription belonging to the receiver
   */
  function getSubscription(address receiver)
    external
    view
    returns (OffRampSubscription memory);

  /**
   * @notice Creates a new subscription if one doesn't already exist for the
   *          given receiver
   * @param subscription The OffRampSubscription to be created
   */
  function createSubscription(OffRampSubscription memory subscription) external;

  /**
   * @notice Increases the balance of an existing subscription. The tokens
   *          need to be approved before making this call.
   * @param receiver Indicated which subscription to fund
   * @param amount The amount to fund the subscription
   */
  function fundSubscription(address receiver, uint256 amount) external;

  /**
   * @notice Indicates the desire to change the senders property on an
   *          existing subscription. This process can be completed after
   *          a set delay by calling `setSubscriptionSenders`. Calling
   *          this function again overwrites any existing prepared senders.
   * @param receiver Indicated which subscription to modify
   * @param newSenders The new sender addresses
   */
  function prepareSetSubscriptionSenders(
    address receiver,
    address[] memory newSenders
  ) external;

  /**
   * @notice Finalizes a call to prepareSetSubscriptionSenders and actually
   *          modify the subscription.
   * @param receiver Indicated which subscription to modify
   * @param newSenders The new sender addresses, these are checked against the
   *          addresses previously given in the prepare step.
   */
  function setSubscriptionSenders(address receiver, address[] memory newSenders)
    external;

  /**
   * @notice Indicates the desire to withdrawal funds from a subscription
   *        This process can be completed after a set delay by calling
   *        `withdrawal`. Calling this function again overwrites any existing
   *        prepared withdrawal.
   * @param receiver Indicated which subscription to withdrawal from
   * @param amount The amount to withdrawal
   */
  function prepareWithdrawal(address receiver, uint256 amount) external;

  /**
   * @notice Completes the withdrawal previously initiated by calling
   *          `prepareWithdrawal`. This will send the token to the
   *          sender of this transaction.
   * @param receiver Indicated which subscription to withdrawal from
   * @param amount The amount to withdrawal
   */
  function withdrawal(address receiver, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';

/**
 * @notice Application contracts that intend to send messages via CCIP
 * will interact with this interface.
 */
interface IEVM2AnySubscriptionOnRampRouter {
  struct EVM2AnySubscriptionMessage {
    bytes receiver; // Address of the receiver on the destination chain for EVM chains use abi.encode(destAddress).
    bytes data; // Bytes that we wish to send to the receiver
    IERC20[] tokens; // The ERC20 tokens we wish to send for EVM source chains
    uint256[] amounts; // The amount of ERC20 tokens we wish to send for EVM source chains
    uint256 gasLimit; // the gas limit for the call to the receiver for destination chains
  }

  /**
   * @notice Request a message to be sent to the destination chain
   * @param destChainId The destination chain ID
   * @param message The message payload
   */
  function ccipSend(
    uint256 destChainId,
    EVM2AnySubscriptionMessage calldata message
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISubscriptionManager {
  /**
   * @notice Gets the subscription manager who is allowed to create/update
   * the subscription for this receiver contract.
   * @return the current subscription manager.
   */
  function getSubscriptionManager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {CrossChainUtils} from '../CrossChainUtils.sol';

interface ICrossChainForwarder {
  /**
   * @dev object storing the connected pair of bridge adapters, on current and destination chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current network
   */
  struct ChainIdBridgeConfig {
    address destinationBridgeAdapter;
    address currentChainBridgeAdapter;
  }

  /**
   * @dev object with the necessary information to remove bridge adapters
   * @param bridgeAdapter address of the bridge adapter to remove
   * @param chainIds array of chain ids where the bridge adapter connects
   */
  struct BridgeAdapterToDisable {
    address bridgeAdapter;
    CrossChainUtils.Chains[] chainIds;
  }

  /**
   * @dev object storing the pair bridgeAdapter (current deployed chain) destination chain bridge adapter configuration
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param dstChainId id of the destination chain using our own nomenclature
   */
  struct BridgeAdapterConfigInput {
    address currentChainBridgeAdapter;
    address destinationBridgeAdapter;
    CrossChainUtils.Chains destinationChainId;
  }

  /**
   * @dev emitted when a bridge adapter failed to send a message
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter that failed (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param destinationChainId id of destination chain
   * @param message bytes intended to be bridged
   * @param returndata bytes with error information
   */
  event AdapterFailed(
    CrossChainUtils.Chains indexed destinationChainId,
    address indexed bridgeAdapter,
    address indexed destinationBridgeAdapter,
    bytes message,
    bytes returndata
  );

  /**
   * @dev emitted when a message is successfully forwarded through a bridge adapter
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter that failed (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param destinationChainId id of destination chain
   * @param message bytes intended to be bridged
   */
  event MessageForwarded(
    CrossChainUtils.Chains indexed destinationChainId,
    address indexed bridgeAdapter,
    address indexed destinationBridgeAdapter,
    bytes message
  );

  /**
   * @dev emitted when a bridge adapter has been added to the allowed list
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter added (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param allowed boolean indicating if the bridge adapter is allowed or disallowed
   */
  event BridgeAdapterUpdated(
    CrossChainUtils.Chains indexed destinationChainId,
    address indexed bridgeAdapter,
    address destinationBridgeAdapter,
    bool indexed allowed
  );

  /**
   * @dev emitted when a sender has been updated
   * @param sender address of the updated sender
   * @param isApproved boolean that indicates if the sender has been approved or removed
   */
  event SenderUpdated(address indexed sender, bool indexed isApproved);

  /// @dev method to get the current sent message nonce
  function currentNonce() external view returns (uint256);

  /**
   * @dev method to check if a message has been previously forwarded.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param origin address where the message originates from
   * @param destination address where the message is intended for
   * @param message bytes that need to be bridged
   */
  function isMessageForwarded(
    CrossChainUtils.Chains destinationChainId,
    address origin,
    address destination,
    bytes memory message
  ) external view returns (bool);

  /**
   * @dev method called to initiate message forwarding to other networks.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param destination address where the message is intended for
   * @param gasLimit gas cost on receiving side of the message
   * @param message bytes that need to be bridged
   */
  function forwardMessage(
    CrossChainUtils.Chains destinationChainId,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) external;

  /**
   * @dev method called to re forward a previously sent message.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param origin address where the message originates from
   * @param destination address where the message is intended for
   * @param gasLimit gas cost on receiving side of the message
   * @param message bytes that need to be bridged
   */
  function retryMessage(
    CrossChainUtils.Chains destinationChainId,
    address origin,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) external;

  /**
   * @dev method to enable bridge adapters
   * @param bridgeAdapters array of new bridge adapter configurations
   */
  function enableBridgeAdapters(
    BridgeAdapterConfigInput[] memory bridgeAdapters
  ) external;

  /**
   * @dev method to disable bridge adapters
   * @param bridgeAdapters array of bridge adapter addresses to disable
   */
  function disableBridgeAdapters(
    BridgeAdapterToDisable[] memory bridgeAdapters
  ) external;

  /**
   * @dev method to remove sender addresses
   * @param senders list of addresses to remove
   */
  function removeSenders(address[] memory senders) external;

  /**
   * @dev method to approve new sender addresses
   * @param senders list of addresses to approve
   */
  function approveSenders(address[] memory senders) external;

  /**
   * @dev method to get all the bridge adapters of a chain
   * @param chainId id of the chain we want to get the adateprs from
   * @return an array of chain configurations where the bridge adapter can communicate
   */
  function getBridgeAdaptersByChain(
    CrossChainUtils.Chains chainId
  ) external view returns (ChainIdBridgeConfig[] memory);

  /**
   * @dev method to get if a sender is approved
   * @param sender address that we want to check if approved
   */
  function isSenderApproved(address sender) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICrossChainForwarder.sol';
import './ICrossChainReceiver.sol';

interface ICrossChainManager is ICrossChainForwarder, ICrossChainReceiver {
  /**
   * @dev method called to initialize the proxy
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
   * @dev method called to rescue tokens sent erroneously to the contract. Only callable by owner
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
   * @dev method called to rescue ether sent erroneously to the contract. Only callable by owner
   * @param to address to send the eth
   * @param amount of eth to rescue
   */
  function emergencyEtherTransfer(address to, uint256 amount) external;

  /**
  * @dev method to check if there is a new emergency state, indicated by chainlink emergency oracle.
         This method is callable by anyone as a new emergency will be determined by the oracle, and this way
         it will be easier / faster to enter into emergency.
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

import {CrossChainUtils} from '../CrossChainUtils.sol';

interface ICrossChainReceiver {
  /**
   * @dev object that stores the internal information of the message
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
   * @dev object that stores the internal information of the message
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
   * @dev emitted when a message has reached the necessary number of confirmations
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
   * @dev emitted when a message has been received successfully
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
   * @dev emitted when a bridge adapter gets disallowed
   * @param brigeAdapter address of the disallowed bridge adapter
   * @param allowed boolean indicating if the bridge adapter has been allowed or disallowed
   */
  event ReceiverBridgeAdaptersUpdated(
    address indexed brigeAdapter,
    bool indexed allowed
  );

  /**
   * @dev emitted when number of confirmations needed to validate a message changes
   * @param newConfirmations number of new confirmations needed for a message to be valid
   */
  event ConfirmationsUpdated(uint256 newConfirmations);

  /**
   * @dev emitted when a new timestamp for invalidations gets set
   * @param invalidTimestamp timestamp to invalidate previous messages
   */
  event NewInvalidation(uint256 invalidTimestamp);

  /// @dev method to get the needed confirmations for a message to be accepted as valid
  function requiredConfirmations() external view returns (uint256);

  /// @dev method to get the timestamp from where the messages will be valid
  function validityTimestamp() external view returns (uint120);

  /**
   * @dev method to get if a bridge adapter is allowed
   * @param bridgeAdapter address of the brige adapter to check
   * @return boolean indicating if brige adapter is allowed
   */
  function isReceiverBridgeAdapterAllowed(address bridgeAdapter)
    external
    view
    returns (bool);

  /**
   * @dev  method to get the internal message information
   * @param internalId hash(originChain + payload) identifying the message internally
   * @return number of confirmations of internal message identified by internalId and the updated timestamp
   */
  function getInternalMessageState(bytes32 internalId)
    external
    view
    returns (InternalBridgedMessageStateWithoutAdapters memory);

  /**
   * @dev method to get if message has been received by bridge adapter
   * @param internalId id of the message as stored internally
   * @param bridgeAdapter address of the bridge adapter to check if it has bridged the message
   * return array of addresses
   */
  function isInternalMessageReceivedByAdapter(
    bytes32 internalId,
    address bridgeAdapter
  ) external view returns (bool);

  /**
   * @dev method to set a new timestamp from where the messages will be valid.
   * @param newValidityTimestamp timestamp where all the previous unconfirmed messages must be invalidated.
   */
  function updateMessagesValidityTimestamp(uint120 newValidityTimestamp)
    external;

  /**
   * @dev method to update the number of confirmations necessary for the messages to be accepted as valid
   * @param newConfirmations new number of needed confirmations
   */
  function updateConfirmations(uint256 newConfirmations) external;

  /**
   * @dev method that registers a received message, updates the confirmations, and sets it as valid if number
   of confirmations has been reached.
   * @param payload bytes of the payload, containing the information to operate with it
   */
  function receiveCrossChainMessage(
    bytes memory payload,
    CrossChainUtils.Chains originChainId
  ) external;

  /**
   * @dev method to add bridge adapters to the allowed list
   * @param bridgeAdapters array of new bridge adapter configurations
   */
  function allowReceiverBridgeAdapters(address[] memory bridgeAdapters)
    external;

  /**
   * @dev method to remove bridge adapters from the allowed list
   * @param bridgeAdapters array of bridge adapter addresses to remove from the allow list
   */
  function disallowReceiverBridgeAdapters(address[] memory bridgeAdapters)
    external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/a035b235b4f2c9af4ba88edc4447f02e37f8d124

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