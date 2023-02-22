// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {ICrossChainForwarder, CrossChainUtils} from './interfaces/ICrossChainForwarder.sol';
import {IBaseAdapter} from './adapters/IBaseAdapter.sol';

contract CrossChainForwarder is OwnableWithGuardian, ICrossChainForwarder {
  // specifies if an address is approved to forward messages
  mapping(address => bool) internal _approvedSenders;

  // for every message we attach a nonce, that will be unique for the message. It increments by one
  uint256 public currentNonce;

  // Stores messages sent. hash(chainId, msgId, origin, dest, message) . This is used to check if a message can be retried
  mapping(bytes32 => bool) internal _forwardedMessages;

  // list of bridge adapter configurations for a chain
  mapping(CrossChainUtils.Chains => ChainIdBridgeConfig[])
    internal _bridgeAdaptersByChain;

  /// @dev checks if caller is an approved sender
  modifier onlyApprovedSenders() {
    require(isSenderApproved(msg.sender), 'CALLER_IS_NOT_APPROVED_SENDER');
    _;
  }

  /**
   * @param bridgeAdaptersToEnable list of bridge adapter configurations to enable
   * @param sendersToApprove list of addresses to approve to forward messages
   */
  constructor(
    BridgeAdapterConfigInput[] memory bridgeAdaptersToEnable,
    address[] memory sendersToApprove
  ) {
    _enableBridgeAdapters(bridgeAdaptersToEnable);
    _updateSenders(sendersToApprove, true);
  }

  /// @inheritdoc ICrossChainForwarder
  function isSenderApproved(address sender) public view returns (bool) {
    return _approvedSenders[sender];
  }

  /// @inheritdoc ICrossChainForwarder
  function isMessageForwarded(
    CrossChainUtils.Chains destinationChainId,
    address origin,
    address destination,
    bytes memory message
  ) public view returns (bool) {
    bytes32 hashedMsgId = keccak256(
      abi.encode(destinationChainId, origin, destination, message)
    );

    return _forwardedMessages[hashedMsgId];
  }

  /// @inheritdoc ICrossChainForwarder
  function forwardMessage(
    CrossChainUtils.Chains destinationChainId,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) external onlyApprovedSenders {
    _forwardMessage(
      destinationChainId,
      msg.sender,
      destination,
      gasLimit,
      message
    );
  }

  /// @inheritdoc ICrossChainForwarder
  function retryMessage(
    CrossChainUtils.Chains destinationChainId,
    address origin,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) external onlyOwnerOrGuardian {
    // If message not bridged before means that something in the message params has changed
    // and it can not be directly resent.
    require(
      isMessageForwarded(destinationChainId, origin, destination, message) ==
        true,
      'MESSAGE_REQUIRED_TO_HAVE_BEEN_PREVIOUSLY_FORWARDED'
    );
    _forwardMessage(destinationChainId, origin, destination, gasLimit, message);
  }

  /// @inheritdoc ICrossChainForwarder
  function getBridgeAdaptersByChain(
    CrossChainUtils.Chains chainId
  ) external view returns (ChainIdBridgeConfig[] memory) {
    return _bridgeAdaptersByChain[chainId];
  }

  /**
   * @dev method called to initiate message forwarding to other networks.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param origin address where the message originates from
   * @param destination address where the message is intended for
   * @param message bytes that need to be bridged
   */
  function _forwardMessage(
    CrossChainUtils.Chains destinationChainId,
    address origin,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) internal {
    bytes memory encodedMessage = abi.encode(
      currentNonce++,
      origin,
      destination,
      message
    );

    ChainIdBridgeConfig[] memory bridgeAdapters = _bridgeAdaptersByChain[
      destinationChainId
    ];

    bool someMessageForwarded;
    for (uint256 i = 0; i < bridgeAdapters.length; i++) {
      ChainIdBridgeConfig memory bridgeAdapterConfig = bridgeAdapters[i];

      (bool success, bytes memory returnData) = bridgeAdapterConfig
        .currentChainBridgeAdapter
        .delegatecall(
          abi.encodeWithSelector(
            IBaseAdapter.forwardMessage.selector,
            bridgeAdapterConfig.destinationBridgeAdapter,
            gasLimit,
            destinationChainId,
            encodedMessage
          )
        );

      if (!success) {
        // it doesnt revert as sending to other bridges might succeed
        emit AdapterFailed(
          destinationChainId,
          bridgeAdapterConfig.currentChainBridgeAdapter,
          bridgeAdapterConfig.destinationBridgeAdapter,
          encodedMessage,
          returnData
        );
      } else {
        someMessageForwarded = true;

        emit MessageForwarded(
          destinationChainId,
          bridgeAdapterConfig.currentChainBridgeAdapter,
          bridgeAdapterConfig.destinationBridgeAdapter,
          encodedMessage
        );
      }
    }

    require(someMessageForwarded, 'NO_MESSAGE_FORWARDED_SUCCESSFULLY');

    // save sent message for future retries. We save even if one bridge was able to send
    // so this way, if other bridges failed, we can retry.
    bytes32 fullMessageId = keccak256(
      abi.encode(destinationChainId, origin, destination, message)
    );
    _forwardedMessages[fullMessageId] = true;
  }

  /// @inheritdoc ICrossChainForwarder
  function approveSenders(address[] memory senders) external onlyOwner {
    _updateSenders(senders, true);
  }

  /// @inheritdoc ICrossChainForwarder
  function removeSenders(address[] memory senders) external onlyOwner {
    _updateSenders(senders, false);
  }

  /// @inheritdoc ICrossChainForwarder
  function enableBridgeAdapters(
    BridgeAdapterConfigInput[] memory bridgeAdapters
  ) external onlyOwner {
    _enableBridgeAdapters(bridgeAdapters);
  }

  /// @inheritdoc ICrossChainForwarder
  function disableBridgeAdapters(
    BridgeAdapterToDisable[] memory bridgeAdapters
  ) external onlyOwner {
    _disableBridgeAdapters(bridgeAdapters);
  }

  function _enableBridgeAdapters(
    BridgeAdapterConfigInput[] memory bridgeAdapters
  ) internal {
    for (uint256 i = 0; i < bridgeAdapters.length; i++) {
      BridgeAdapterConfigInput memory bridgeAdapterConfigInput = bridgeAdapters[
        i
      ];

      require(
        bridgeAdapterConfigInput.destinationBridgeAdapter != address(0) &&
          bridgeAdapterConfigInput.currentChainBridgeAdapter != address(0),
        'CURRENT_OR_DESTINATION_CHAIN_ADAPTER_NOT_SET'
      );
      ChainIdBridgeConfig[]
        storage bridgeAdapterConfigs = _bridgeAdaptersByChain[
          bridgeAdapterConfigInput.destinationChainId
        ];
      bool configFound;
      // check that we dont push same config twice.
      for (uint256 j = 0; j < bridgeAdapterConfigs.length; j++) {
        ChainIdBridgeConfig storage bridgeAdapterConfig = bridgeAdapterConfigs[
          j
        ];

        if (
          bridgeAdapterConfig.currentChainBridgeAdapter ==
          bridgeAdapterConfigInput.currentChainBridgeAdapter
        ) {
          if (
            bridgeAdapterConfig.destinationBridgeAdapter !=
            bridgeAdapterConfigInput.destinationBridgeAdapter
          ) {
            bridgeAdapterConfig
              .destinationBridgeAdapter = bridgeAdapterConfigInput
              .destinationBridgeAdapter;
          }
          configFound = true;
          break;
        }
      }

      if (!configFound) {
        bridgeAdapterConfigs.push(
          ChainIdBridgeConfig({
            destinationBridgeAdapter: bridgeAdapterConfigInput
              .destinationBridgeAdapter,
            currentChainBridgeAdapter: bridgeAdapterConfigInput
              .currentChainBridgeAdapter
          })
        );
      }

      emit BridgeAdapterUpdated(
        bridgeAdapterConfigInput.destinationChainId,
        bridgeAdapterConfigInput.currentChainBridgeAdapter,
        bridgeAdapterConfigInput.destinationBridgeAdapter,
        true
      );
    }
  }

  function _disableBridgeAdapters(
    BridgeAdapterToDisable[] memory bridgeAdaptersToDisable
  ) internal {
    for (uint256 i = 0; i < bridgeAdaptersToDisable.length; i++) {
      for (uint256 j = 0; j < bridgeAdaptersToDisable[i].chainIds.length; j++) {
        ChainIdBridgeConfig[]
          storage bridgeAdapterConfigs = _bridgeAdaptersByChain[
            bridgeAdaptersToDisable[i].chainIds[j]
          ];

        for (uint256 k = 0; k < bridgeAdapterConfigs.length; k++) {
          if (
            bridgeAdapterConfigs[k].currentChainBridgeAdapter ==
            bridgeAdaptersToDisable[i].bridgeAdapter
          ) {
            address destinationBridgeAdapter = bridgeAdapterConfigs[k]
              .destinationBridgeAdapter;

            if (k != bridgeAdapterConfigs.length) {
              bridgeAdapterConfigs[k] = bridgeAdapterConfigs[
                bridgeAdapterConfigs.length - 1
              ];
            }

            bridgeAdapterConfigs.pop();

            emit BridgeAdapterUpdated(
              bridgeAdaptersToDisable[i].chainIds[j],
              bridgeAdaptersToDisable[i].bridgeAdapter,
              destinationBridgeAdapter,
              false
            );
            break;
          }
        }
      }
    }
  }

  function _updateSenders(address[] memory senders, bool newState) internal {
    for (uint256 i = 0; i < senders.length; i++) {
      _approvedSenders[senders[i]] = newState;
      emit SenderUpdated(senders[i], newState);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {EmergencyConsumer, IEmergencyConsumer} from 'solidity-utils/contracts/emergency/EmergencyConsumer.sol';

import {ICrossChainManager, CrossChainUtils, ICrossChainForwarder} from './interfaces/ICrossChainManager.sol';
import {CrossChainReceiver} from './CrossChainReceiver.sol';
import {CrossChainForwarder} from './CrossChainForwarder.sol';

/**
 * @title CrossChainManager
 * @author BGD Labs
 * @dev Contract with the logic to manage sending and receiving messages cross chain.
 */
contract CrossChainManager is
  ICrossChainManager,
  CrossChainForwarder,
  CrossChainReceiver,
  EmergencyConsumer,
  Initializable
{
  using SafeERC20 for IERC20;

  /**
   * @param clEmergencyOracle chainlink emergency oracle address
   * @param initialRequiredConfirmations number of confirmations the messages need to be accepted as valid
   * @param receiverBridgeAdaptersToAllow array of addresses of the bridge adapters that can receive messages
   * @param forwarderBridgeAdaptersToEnable array specifying for every bridgeAdapter, the destinations it can have
   * @param sendersToApprove array of addresses to allow as forwarders
   */
  constructor(
    address clEmergencyOracle,
    uint256 initialRequiredConfirmations,
    address[] memory receiverBridgeAdaptersToAllow,
    BridgeAdapterConfigInput[] memory forwarderBridgeAdaptersToEnable,
    address[] memory sendersToApprove
  )
    CrossChainReceiver(
      initialRequiredConfirmations,
      receiverBridgeAdaptersToAllow
    )
    CrossChainForwarder(forwarderBridgeAdaptersToEnable, sendersToApprove)
    EmergencyConsumer(clEmergencyOracle)
  {}

  /// @inheritdoc ICrossChainManager
  function initialize(
    address owner,
    address guardian,
    address clEmergencyOracle,
    uint256 initialRequiredConfirmations,
    address[] memory receiverBridgeAdaptersToAllow,
    BridgeAdapterConfigInput[] memory forwarderBridgeAdaptersToEnable,
    address[] memory sendersToApprove
  ) external initializer {
    _transferOwnership(owner);
    _updateGuardian(guardian);
    _updateCLEmergencyOracle(clEmergencyOracle);

    _updateConfirmations(initialRequiredConfirmations);
    _updateReceiverBridgeAdapters(receiverBridgeAdaptersToAllow, true);

    _enableBridgeAdapters(forwarderBridgeAdaptersToEnable);
    _updateSenders(sendersToApprove, true);
  }

  /// @inheritdoc ICrossChainManager
  function solveEmergency(
    uint256 newConfirmations,
    uint120 newValidityTimestamp,
    address[] memory receiverBridgeAdaptersToAllow,
    address[] memory receiverBridgeAdaptersToDisallow,
    address[] memory sendersToApprove,
    address[] memory sendersToRemove,
    BridgeAdapterConfigInput[] memory forwarderBridgeAdaptersToEnable,
    BridgeAdapterToDisable[] memory forwarderBridgeAdaptersToDisable
  ) external onlyGuardian onlyInEmergency {
    // receiver side
    _updateReceiverBridgeAdapters(receiverBridgeAdaptersToAllow, true);
    _updateReceiverBridgeAdapters(receiverBridgeAdaptersToDisallow, false);
    _updateConfirmations(newConfirmations);
    _updateMessagesValidityTimestamp(newValidityTimestamp);

    // forwarder side
    _updateSenders(sendersToApprove, true);
    _updateSenders(sendersToRemove, false);
    _enableBridgeAdapters(forwarderBridgeAdaptersToEnable);
    _disableBridgeAdapters(forwarderBridgeAdaptersToDisable);
  }

  /// @inheritdoc ICrossChainManager
  function emergencyTokenTransfer(
    address erc20Token,
    address to,
    uint256 amount
  ) external onlyOwner {
    IERC20(erc20Token).safeTransfer(to, amount);
  }

  /// @inheritdoc ICrossChainManager
  function emergencyEtherTransfer(address to, uint256 amount)
    external
    onlyOwner
  {
    _safeTransferETH(to, amount);
  }

  /// @dev enable contract to receive eth
  receive() external payable {}

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'ETH_TRANSFER_FAILED');
  }

  /// @dev method that ensures access control validation
  function _validateEmergencyAdmin() internal override onlyOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {ICrossChainReceiver, CrossChainUtils} from './interfaces/ICrossChainReceiver.sol';
import {IBaseReceiverPortal} from './interfaces/IBaseReceiverPortal.sol';

contract CrossChainReceiver is OwnableWithGuardian, ICrossChainReceiver {
  // stores hash(nonce + originChainId + origin + dest + message) => bridged message information and state
  mapping(bytes32 => InternalBridgedMessage) internal _internalReceivedMessages;

  // number of bridges that are needed to make a bridged message valid.
  // Depending on the deployment chain, this needs to change, to account for the existing number of bridges
  uint256 public requiredConfirmations;

  // all messages originated but not finally confirmed before this timestamp, are invalid
  uint120 public validityTimestamp;

  // specifies if an address is allowed to forward messages
  mapping(address => bool) internal _allowedBridgeAdapters;

  /// @dev checks if caller is one of the approved bridge adapters
  modifier onlyApprovedBridges() {
    require(
      isReceiverBridgeAdapterAllowed(msg.sender),
      'CALLER_NOT_APPROVED_BRIDGE'
    );
    _;
  }

  /**
   * @param initialRequiredConfirmations number of confirmations the messages need to be accepted as valid
   * @param bridgeAdaptersToAllow array of addresses of the bridge adapters that can receive messages
   */
  constructor(
    uint256 initialRequiredConfirmations,
    address[] memory bridgeAdaptersToAllow
  ) {
    _updateConfirmations(initialRequiredConfirmations);
    _updateReceiverBridgeAdapters(bridgeAdaptersToAllow, true);
  }

  /// @inheritdoc ICrossChainReceiver
  function isReceiverBridgeAdapterAllowed(address bridgeAdapter)
    public
    view
    returns (bool)
  {
    return _allowedBridgeAdapters[bridgeAdapter];
  }

  /// @inheritdoc ICrossChainReceiver
  function getInternalMessageState(bytes32 internalId)
    external
    view
    returns (InternalBridgedMessageStateWithoutAdapters memory)
  {
    return
      InternalBridgedMessageStateWithoutAdapters({
        confirmations: _internalReceivedMessages[internalId].confirmations,
        firstBridgedAt: _internalReceivedMessages[internalId].firstBridgedAt,
        delivered: _internalReceivedMessages[internalId].delivered
      });
  }

  /// @inheritdoc ICrossChainReceiver
  function isInternalMessageReceivedByAdapter(
    bytes32 internalId,
    address bridgeAdapter
  ) external view returns (bool) {
    return
      _internalReceivedMessages[internalId].bridgedByAdapter[bridgeAdapter];
  }

  /// @inheritdoc ICrossChainReceiver
  function updateConfirmations(uint256 newConfirmations) external onlyOwner {
    _updateConfirmations(newConfirmations);
  }

  /// @inheritdoc ICrossChainReceiver
  function updateMessagesValidityTimestamp(uint120 newValidityTimestamp)
    external
    onlyOwner
  {
    _updateMessagesValidityTimestamp(newValidityTimestamp);
  }

  /// @inheritdoc ICrossChainReceiver
  function allowReceiverBridgeAdapters(address[] memory bridgeAdapters)
    external
    onlyOwner
  {
    _updateReceiverBridgeAdapters(bridgeAdapters, true);
  }

  /// @inheritdoc ICrossChainReceiver
  function disallowReceiverBridgeAdapters(address[] memory bridgeAdapters)
    external
    onlyOwner
  {
    _updateReceiverBridgeAdapters(bridgeAdapters, false);
  }

  /// @inheritdoc ICrossChainReceiver
  function receiveCrossChainMessage(
    bytes memory payload,
    CrossChainUtils.Chains originChainId
  ) external onlyApprovedBridges {
    (, address msgOrigin, address msgDestination, bytes memory message) = abi
      .decode(payload, (uint256, address, address, bytes));

    bytes32 internalId = keccak256(abi.encode(originChainId, payload));

    InternalBridgedMessage storage internalMessage = _internalReceivedMessages[
      internalId
    ];

    // if bridged at is > invalidation means that the first message bridged happened after invalidation
    // which means that invalidation doesnt affect as invalid bridge has already been removed.
    // as nonce is packed in the payload. If message arrives after invalidation from resending, it will pass.
    // if its 0 means that is the first bridge received, meaning that invalidation does not matter for this message
    // checks that bridge adapter has not already bridged this message
    uint120 messageFirstBridgedAt = internalMessage.firstBridgedAt;
    if (
      (messageFirstBridgedAt > validityTimestamp &&
        !internalMessage.bridgedByAdapter[msg.sender]) ||
      messageFirstBridgedAt == 0
    ) {
      if (messageFirstBridgedAt == 0) {
        internalMessage.firstBridgedAt = uint120(block.timestamp);
      }

      uint256 newConfirmations = ++internalMessage.confirmations;
      internalMessage.bridgedByAdapter[msg.sender] = true;

      emit MessageReceived(
        internalId,
        msg.sender,
        msgDestination,
        msgOrigin,
        message,
        newConfirmations
      );

      // it checks if it has been delivered, so it doesnt deliver again when message arrives from extra bridges
      // (when already reached confirmations) and reverts (because of destination logic)
      // and it saves that these bridges have also correctly bridged the message
      if (
        newConfirmations == requiredConfirmations && !internalMessage.delivered
      ) {
        IBaseReceiverPortal(msgDestination).receiveCrossChainMessage(
          msgOrigin,
          originChainId,
          message
        );

        internalMessage.delivered = true;

        emit MessageConfirmed(msgDestination, msgOrigin, message);
      }
    }
  }

  /**
   * @dev method to invalidate messages previous to certain timestamp.
   * @param newValidityTimestamp timestamp where all the previous unconfirmed messages must be invalidated.
   */
  function _updateMessagesValidityTimestamp(uint120 newValidityTimestamp)
    internal
  {
    require(
      newValidityTimestamp > validityTimestamp,
      'TIMESTAMP_ALREADY_PASSED'
    );
    validityTimestamp = newValidityTimestamp;

    emit NewInvalidation(newValidityTimestamp);
  }

  /**
   * @dev updates confirmations needed for a message to be accepted as valid
   * @param newConfirmations number of confirmations
   */
  function _updateConfirmations(uint256 newConfirmations) internal {
    requiredConfirmations = newConfirmations;
    emit ConfirmationsUpdated(newConfirmations);
  }

  /**
   * @dev method to remove bridge adapters from the allowed list
   * @param bridgeAdapters array of bridge adapter addresses to update
   * @param newState new state, will they be allowed or not
   */
  function _updateReceiverBridgeAdapters(
    address[] memory bridgeAdapters,
    bool newState
  ) internal {
    for (uint256 i = 0; i < bridgeAdapters.length; i++) {
      _allowedBridgeAdapters[bridgeAdapters[i]] = newState;

      emit ReceiverBridgeAdaptersUpdated(bridgeAdapters[i], newState);
    }
  }
}

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

pragma solidity ^0.8.0;

import '../CrossChainUtils.sol';

/// @dev interface needed by the portals on the receiving side to be able to receive bridged messages
interface IBaseReceiverPortal {
  /**
   * @dev method called by CrossChainManager when a message has been confirmed
   * @param originSender address of the sender of the bridged message
   * @param originChainId id of the chain where the message originated
   * @param message bytes bridged containing the desired information
   */
  function receiveCrossChainMessage(
    address originSender,
    CrossChainUtils.Chains originChainId,
    bytes memory message
  ) external;
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
pragma solidity >=0.7.0;

import {IWithGuardian} from './interfaces/IWithGuardian.sol';
import {Ownable} from '../oz-common/Ownable.sol';

abstract contract OwnableWithGuardian is Ownable, IWithGuardian {
  address private _guardian;

  constructor() {
    _updateGuardian(_msgSender());
  }

  modifier onlyGuardian() {
    _checkGuardian();
    _;
  }

  modifier onlyOwnerOrGuardian() {
    _checkOwnerOrGuardian();
    _;
  }

  function guardian() public view override returns (address) {
    return _guardian;
  }

  /// @inheritdoc IWithGuardian
  function updateGuardian(address newGuardian) external override onlyGuardian {
    _updateGuardian(newGuardian);
  }

  /**
   * @dev method to update the guardian
   * @param newGuardian the new guardian address
   */
  function _updateGuardian(address newGuardian) internal {
    address oldGuardian = _guardian;
    _guardian = newGuardian;
    emit GuardianUpdated(oldGuardian, newGuardian);
  }

  function _checkGuardian() internal view {
    require(guardian() == _msgSender(), 'ONLY_BY_GUARDIAN');
  }

  function _checkOwnerOrGuardian() internal view {
    require(_msgSender() == owner() || _msgSender() == guardian(), 'ONLY_BY_OWNER_OR_GUARDIAN');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IWithGuardian {
  /**
   * @dev Event emitted when guardian gets updated
   * @param oldGuardian address of previous guardian
   * @param newGuardian address of the new guardian
   */
  event GuardianUpdated(address oldGuardian, address newGuardian);

  /**
   * @dev get guardian address;
   */
  function guardian() external view returns (address);

  /**
   * @dev method to update the guardian
   * @param newGuardian the new guardian address
   */
  function updateGuardian(address newGuardian) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEmergencyConsumer} from './interfaces/IEmergencyConsumer.sol';
import {ICLEmergencyOracle} from './interfaces/ICLEmergencyOracle.sol';

abstract contract EmergencyConsumer is IEmergencyConsumer {
  address internal _chainlinkEmergencyOracle;

  uint256 internal _emergencyCount;

  /// @dev modifier that checks if the oracle emergency is greater than the last resolved one, and if so
  ///      lets execution pass
  modifier onlyInEmergency() {
    require(address(_chainlinkEmergencyOracle) != address(0), 'CL_EMERGENCY_ORACLE_NOT_SET');

    (, int256 answer, , , ) = ICLEmergencyOracle(_chainlinkEmergencyOracle).latestRoundData();

    uint256 nextEmergencyCount = ++_emergencyCount;
    require(answer == int256(nextEmergencyCount), 'NOT_IN_EMERGENCY');
    _;

    emit EmergencySolved(nextEmergencyCount);
  }

  /**
   * @param newChainlinkEmergencyOracle address of the new chainlink emergency mode oracle
   */
  constructor(address newChainlinkEmergencyOracle) {
    _updateCLEmergencyOracle(newChainlinkEmergencyOracle);
  }

  /// @dev This method is made virtual as it is expected to have access control, but this way it is delegated to implementation.
  function _validateEmergencyAdmin() internal virtual;

  /// @inheritdoc IEmergencyConsumer
  function updateCLEmergencyOracle(address newChainlinkEmergencyOracle) external {
    _validateEmergencyAdmin();
    _updateCLEmergencyOracle(newChainlinkEmergencyOracle);
  }

  /// @inheritdoc IEmergencyConsumer
  function getChainlinkEmergencyOracle() public view returns (address) {
    return _chainlinkEmergencyOracle;
  }

  /// @inheritdoc IEmergencyConsumer
  function getEmergencyCount() public view returns (uint256) {
    return _emergencyCount;
  }

  /**
   * @dev method to update the chainlink emergency oracle
   * @param newChainlinkEmergencyOracle address of the new oracle
   */
  function _updateCLEmergencyOracle(address newChainlinkEmergencyOracle) internal {
    _chainlinkEmergencyOracle = newChainlinkEmergencyOracle;

    emit CLEmergencyOracleUpdated(newChainlinkEmergencyOracle);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICLEmergencyOracle {
  /**
   * @notice get data about the latest round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * Note that different underlying implementations of AggregatorV3Interface
   * have slightly different semantics for some of the return values. Consumers
   * should determine what implementations they expect to receive
   * data from and validate that they can properly handle return data from all
   * of them.
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with an phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
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

interface IEmergencyConsumer {
  /**
   * @dev emitted when chainlink emergency oracle gets updated
   * @param newChainlinkEmergencyOracle address of the new oracle
   */
  event CLEmergencyOracleUpdated(address indexed newChainlinkEmergencyOracle);

  /**
   * @dev emitted when the emergency is solved
   * @param emergencyCount number of emergencies solved. Used to check if a new emergency is active.
   */
  event EmergencySolved(uint256 emergencyCount);

  /// @dev method that returns the last emergency solved
  function getEmergencyCount() external view returns (uint256);

  /// @dev method that returns the address of the current chainlink emergency oracle
  function getChainlinkEmergencyOracle() external view returns (address);

  /**
   * @dev method to update the chainlink emergency mode address.
   *      This method is made virtual as it is expected to have access control, but this way it is delegated to implementation.
   *      It should call _updateCLEmergencyOracle when implemented
   * @param newChainlinkEmergencyOracle address of the new chainlink emergency mode oracle
   */
  function updateCLEmergencyOracle(address newChainlinkEmergencyOracle) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
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
    return functionCallWithValue(target, data, 0, 'Address: low-level call failed');
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
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data
  ) internal view returns (bytes memory) {
    return functionStaticCall(target, data, 'Address: low-level static call failed');
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
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
        require(isContract(target), 'Address: call to non-contract');
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
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

pragma solidity ^0.8.0;

import './Context.sol';

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
abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/3dac7bbed7b4c0dbf504180c33e8ed8e350b93eb

pragma solidity ^0.8.0;

import './interfaces/IERC20.sol';
import './interfaces/draft-IERC20Permit.sol';
import './Address.sol';

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using Address for address;

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(
      token,
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    unchecked {
      uint256 oldAllowance = token.allowance(address(this), spender);
      require(oldAllowance >= value, 'SafeERC20: decreased allowance below zero');
      uint256 newAllowance = oldAllowance - value;
      _callOptionalReturn(
        token,
        abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
      );
    }
  }

  function safePermit(
    IERC20Permit token,
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal {
    uint256 nonceBefore = token.nonces(owner);
    token.permit(owner, spender, value, deadline, v, r, s);
    uint256 nonceAfter = token.nonces(owner);
    require(nonceAfter == nonceBefore + 1, 'SafeERC20: permit did not succeed');
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   * @param token The token targeted by the call.
   * @param data The call data (encoded using abi.encode or one of its variants).
   */
  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
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
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/6bd6b76d1156e20e45d1016f355d154141c7e5b9

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
  /**
   * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
   * given ``owner``'s signed approval.
   *
   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
   * ordering also apply here.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `deadline` must be a timestamp in the future.
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``owner``'s current nonce (see {nonces}).
   *
   * For more information on the signature format, see the
   * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
   * section].
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Returns the current nonce for `owner`. This value must be
   * included whenever a signature is generated for {permit}.
   *
   * Every successful call to {permit} increases ``owner``'s nonce by one. This
   * prevents a signature from being used multiple times.
   */
  function nonces(address owner) external view returns (uint256);

  /**
   * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

/**
 * @dev OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)
 * From https://github.com/OpenZeppelin/openzeppelin-contracts/tree/8b778fa20d6d76340c5fac1ed66c80273f05b95a
 *
 * BGD Labs adaptations:
 * - Added a constructor disabling initialization for implementation contracts
 * - Linting
 */

pragma solidity ^0.8.2;

import '../oz-common/Address.sol';

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
   * @dev OPINIONATED. Generally is not a good practise to allow initialization of implementations
   */
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
   * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
   */
  modifier initializer() {
    bool isTopLevelCall = !_initializing;
    require(
      (isTopLevelCall && _initialized < 1) ||
        (!Address.isContract(address(this)) && _initialized == 1),
      'Initializable: contract is already initialized'
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
    require(
      !_initializing && _initialized < version,
      'Initializable: contract is already initialized'
    );
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
    require(_initializing, 'Initializable: contract is not initializing');
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
   * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
   * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
   * through proxies.
   */
  function _disableInitializers() internal virtual {
    require(!_initializing, 'Initializable: contract is initializing');
    if (_initialized < type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }
}