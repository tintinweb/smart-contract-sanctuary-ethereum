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

import {BaseAdapter, CrossChainUtils, IBaseAdapter} from '../BaseAdapter.sol';
import {IHyperLaneAdapter, IMailbox, IInterchainGasPaymaster} from './IHyperLaneAdapter.sol';
import {IMessageRecipient} from 'hyperlane-monorepo/interfaces/IMessageRecipient.sol';
import {TypeCasts} from 'hyperlane-monorepo/contracts/libs/TypeCasts.sol';

// contracts https://docs.hyperlane.xyz/docs/resources/addresses

contract HyperLaneAdapter is BaseAdapter, IHyperLaneAdapter, IMessageRecipient {
  IMailbox public immutable HL_MAIL_BOX;

  IInterchainGasPaymaster public immutable IGP;

  mapping(CrossChainUtils.Chains => address) internal _trustedRemotes;

  modifier onlyMailbox() {
    require(msg.sender == address(HL_MAIL_BOX), 'CALLER_NOT_HL_MAILBOX');
    _;
  }

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

  /// @inheritdoc IBaseAdapter
  function forwardMessage(
    address receiver,
    uint256 destinationGasLimit,
    CrossChainUtils.Chains destinationChainId,
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

    // Pay from the contract's balance
    IGP.payForGas{value: quotedPayment}(
      messageId, // The ID of the message that was just dispatched
      nativeChainId, // The destination domain of the message
      destinationGasLimit,
      address(this) // refunds go to msg.sender, who paid the msg.value
    );
  }

  /// @inheritdoc IMessageRecipient
  function handle(
    uint32 _origin,
    bytes32 _sender,
    bytes calldata _messageBody
  ) external onlyMailbox {
    address srcAddress = TypeCasts.bytes32ToAddress(_sender);

    CrossChainUtils.Chains originChainId = nativeToInfraChainId(_origin);

    require(
      originChainId != CrossChainUtils.Chains.Null_network,
      'INCORRECT_ORIGIN_CHAIN_ID'
    );

    require(_trustedRemotes[originChainId] == srcAddress, 'REMOTE_NOT_TRUSTED');
    _registerReceivedMessage(_messageBody, originChainId);
    emit HLPayloadProcessed(originChainId, srcAddress, _messageBody);
  }

  /// @inheritdoc IHyperLaneAdapter
  function nativeToInfraChainId(
    uint32 nativeChainId
  ) public pure returns (CrossChainUtils.Chains) {
    if (nativeChainId == uint32(1)) {
      return CrossChainUtils.Chains.EthMainnet;
    } else if (nativeChainId == uint32(43114)) {
      return CrossChainUtils.Chains.Avalanche;
    } else if (nativeChainId == uint32(137)) {
      return CrossChainUtils.Chains.Polygon;
    } else if (nativeChainId == uint32(42161)) {
      return CrossChainUtils.Chains.Arbitrum;
    } else if (nativeChainId == uint32(10)) {
      return CrossChainUtils.Chains.Optimism;
    } else if (nativeChainId == uint32(5)) {
      return CrossChainUtils.Chains.Goerli;
    } else if (nativeChainId == uint32(43113)) {
      return CrossChainUtils.Chains.AvalancheFuji;
    } else if (nativeChainId == uint32(420)) {
      return CrossChainUtils.Chains.OptimismGoerli;
    } else if (nativeChainId == uint32(80001)) {
      return CrossChainUtils.Chains.PolygonMumbai;
    } else if (nativeChainId == uint32(421613)) {
      return CrossChainUtils.Chains.ArbitrumGoerli;
    } else {
      return CrossChainUtils.Chains.Null_network;
    }
  }

  /// @inheritdoc IHyperLaneAdapter
  function infraToNativeChainId(
    CrossChainUtils.Chains infraChainId
  ) public pure returns (uint32) {
    if (infraChainId == CrossChainUtils.Chains.EthMainnet) {
      return uint32(1);
    } else if (infraChainId == CrossChainUtils.Chains.Avalanche) {
      return uint32(43114);
    } else if (infraChainId == CrossChainUtils.Chains.Polygon) {
      return uint32(137);
    } else if (infraChainId == CrossChainUtils.Chains.Arbitrum) {
      return uint32(42161);
    } else if (infraChainId == CrossChainUtils.Chains.Optimism) {
      return uint32(10);
    } else if (infraChainId == CrossChainUtils.Chains.Goerli) {
      return uint32(5);
    } else if (infraChainId == CrossChainUtils.Chains.AvalancheFuji) {
      return uint32(43113);
    } else if (infraChainId == CrossChainUtils.Chains.OptimismGoerli) {
      return uint32(420);
    } else if (infraChainId == CrossChainUtils.Chains.PolygonMumbai) {
      return uint32(80001);
    } else if (infraChainId == CrossChainUtils.Chains.ArbitrumGoerli) {
      return uint32(421613);
    } else {
      return uint32(0);
    }
  }

  /**
   * @notice method to
   * @param trustedRemotes
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

import {CrossChainUtils} from '../../CrossChainUtils.sol';
import {IMailbox} from 'hyperlane-monorepo/interfaces/IMailbox.sol';
import {IInterchainGasPaymaster} from 'hyperlane-monorepo/interfaces/IInterchainGasPaymaster.sol';

interface IHyperLaneAdapter {
  /// @notice pair of origin address and origin chain
  struct TrustedRemotesConfig {
    address originForwarder;
    CrossChainUtils.Chains originChainId;
  }

  event SetTrustedRemote(
    CrossChainUtils.Chains indexed originChainId,
    address indexed originForwarder
  );

  event HLPayloadProcessed(
    CrossChainUtils.Chains indexed originChainId,
    address indexed srcAddress,
    bytes _messageBody
  );

  function HL_MAIL_BOX() external view returns (IMailbox);

  function IGP() external view returns (IInterchainGasPaymaster);

  /**
   * @dev method to get infrastructure chain id from bridge native chain id
   * @param bridgeChainId bridge native chain id
   */
  function nativeToInfraChainId(
    uint32 bridgeChainId
  ) external returns (CrossChainUtils.Chains);

  /**
   * @dev method to get bridge native chain id from native bridge chain id
   * @param infraChainId infrastructure chain id
   */
  function infraToNativeChainId(
    CrossChainUtils.Chains infraChainId
  ) external returns (uint32);
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