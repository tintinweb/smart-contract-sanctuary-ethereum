// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import { ICrossDomainMessenger } from "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

import { IMessageExecutor } from "../interfaces/IMessageExecutor.sol";
import { IMessageDispatcher, ISingleMessageDispatcher } from "../interfaces/ISingleMessageDispatcher.sol";
import { IBatchedMessageDispatcher } from "../interfaces/IBatchedMessageDispatcher.sol";

import "../libraries/MessageLib.sol";

/**
 * @title MessageDispatcherOptimism contract
 * @notice The MessageDispatcherOptimism contract allows a user or contract to send messages from Ethereum to Optimism.
 *         It lives on the Ethereum chain and communicates with the `MessageExecutorOptimism` contract on the Optimism chain.
 */
contract MessageDispatcherOptimism is ISingleMessageDispatcher, IBatchedMessageDispatcher {
  /* ============ Variables ============ */

  /// @notice Address of the Optimism cross domain messenger on the Ethereum chain.
  ICrossDomainMessenger public immutable crossDomainMessenger;

  /// @notice Address of the executor contract on the Optimism chain.
  IMessageExecutor internal executor;

  /// @notice Nonce used to compute unique `messageId`s.
  uint256 internal nonce;

  /// @notice ID of the chain receiving the dispatched messages. i.e.: 10 for Mainnet, 420 for Goerli.
  uint256 internal immutable toChainId;

  /// @notice Free gas limit on Optimism
  uint32 internal constant GAS_LIMIT = uint32(1920000);

  /* ============ Constructor ============ */

  /**
   * @notice MessageDispatcherOptimism constructor.
   * @param _crossDomainMessenger Address of the Optimism cross domain messenger
   * @param _toChainId ID of the chain receiving the dispatched messages
   */
  constructor(ICrossDomainMessenger _crossDomainMessenger, uint256 _toChainId) {
    require(address(_crossDomainMessenger) != address(0), "Dispatcher/CDM-not-zero-address");
    require(_toChainId != 0, "Dispatcher/chainId-not-zero");

    crossDomainMessenger = _crossDomainMessenger;
    toChainId = _toChainId;
  }

  /* ============ External Functions ============ */

  /// @inheritdoc ISingleMessageDispatcher
  function dispatchMessage(
    uint256 _toChainId,
    address _to,
    bytes calldata _data
  ) external returns (bytes32) {
    address _executorAddress = _getMessageExecutorAddress(_toChainId);
    _checkExecutor(_executorAddress);

    uint256 _nonce = _incrementNonce();
    bytes32 _messageId = MessageLib.computeMessageId(_nonce, msg.sender, _to, _data);

    _sendMessage(
      _executorAddress,
      MessageLib.encodeMessage(_to, _data, _messageId, block.chainid, msg.sender)
    );

    emit MessageDispatched(_messageId, msg.sender, _toChainId, _to, _data);

    return _messageId;
  }

  /// @inheritdoc IBatchedMessageDispatcher
  function dispatchMessageBatch(uint256 _toChainId, MessageLib.Message[] calldata _messages)
    external
    returns (bytes32)
  {
    address _executorAddress = _getMessageExecutorAddress(_toChainId);
    _checkExecutor(_executorAddress);

    uint256 _nonce = _incrementNonce();
    bytes32 _messageId = MessageLib.computeMessageBatchId(_nonce, msg.sender, _messages);

    _sendMessage(
      _executorAddress,
      MessageLib.encodeMessageBatch(_messages, _messageId, block.chainid, msg.sender)
    );

    emit MessageBatchDispatched(_messageId, msg.sender, _toChainId, _messages);

    return _messageId;
  }

  /// @inheritdoc IMessageDispatcher
  function getMessageExecutorAddress(uint256 _toChainId) external view returns (address) {
    return _getMessageExecutorAddress(_toChainId);
  }

  /**
   * @notice Set executor contract address.
   * @dev Will revert if it has already been set.
   * @param _executor Address of the executor contract on the Optimism chain
   */
  function setExecutor(IMessageExecutor _executor) external {
    require(address(executor) == address(0), "Dispatcher/executor-already-set");
    executor = _executor;
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Check toChainId to ensure messages can be dispatched to this chain.
   * @dev Will revert if `_toChainId` is not supported.
   * @param _toChainId ID of the chain receiving the message
   */
  function _checkToChainId(uint256 _toChainId) internal view {
    require(_toChainId == toChainId, "Dispatcher/chainId-not-supported");
  }

  /**
   * @notice Check dispatch parameters to ensure messages can be dispatched.
   * @dev Will revert if `executor` is not set.
   * @param _executor Address of the executor contract on the Optimism chain
   */
  function _checkExecutor(address _executor) internal pure {
    require(_executor != address(0), "Dispatcher/executor-not-set");
  }

  /**
   * @notice Retrieves address of the MessageExecutor contract on the receiving chain.
   * @dev Will revert if `_toChainId` is not supported.
   * @param _toChainId ID of the chain with which MessageDispatcher is communicating
   * @return address MessageExecutor contract address
   */
  function _getMessageExecutorAddress(uint256 _toChainId) internal view returns (address) {
    _checkToChainId(_toChainId);
    return address(executor);
  }

  /**
   * @notice Helper to increment nonce.
   * @return uint256 Incremented nonce
   */
  function _incrementNonce() internal returns (uint256) {
    unchecked {
      nonce++;
    }

    return nonce;
  }

  /**
   * @notice Dispatch message to Optimism chain.
   * @param _executor Address of the executor contract on the Optimism chain
   * @param _message Message dispatched
   */
  function _sendMessage(address _executor, bytes memory _message) internal {
    crossDomainMessenger.sendMessage(_executor, _message, GAS_LIMIT);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "./IMessageDispatcher.sol";

/**
 * @title ERC-5164: Cross-Chain Execution Standard, optional BatchMessageDispatcher extension
 * @dev See https://eips.ethereum.org/EIPS/eip-5164
 */
interface IBatchedMessageDispatcher is IMessageDispatcher {
  /**
   * @notice Dispatch `messages` to the receiving chain.
   * @dev Must compute and return an ID uniquely identifying the `messages`.
   * @dev Must emit the `MessageBatchDispatched` event when successfully dispatched.
   * @param toChainId ID of the receiving chain
   * @param messages Array of Message dispatched
   * @return bytes32 ID uniquely identifying the `messages`
   */
  function dispatchMessageBatch(uint256 toChainId, MessageLib.Message[] calldata messages)
    external
    returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "../libraries/MessageLib.sol";

/**
 * @title ERC-5164: Cross-Chain Execution Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-5164
 */
interface IMessageDispatcher {
  /**
   * @notice Emitted when a message has successfully been dispatched to the executor chain.
   * @param messageId ID uniquely identifying the message
   * @param from Address that dispatched the message
   * @param toChainId ID of the chain receiving the message
   * @param to Address that will receive the message
   * @param data Data that was dispatched
   */
  event MessageDispatched(
    bytes32 indexed messageId,
    address indexed from,
    uint256 indexed toChainId,
    address to,
    bytes data
  );

  /**
   * @notice Emitted when a batch of messages has successfully been dispatched to the executor chain.
   * @param messageId ID uniquely identifying the messages
   * @param from Address that dispatched the messages
   * @param toChainId ID of the chain receiving the messages
   * @param messages Array of Message that was dispatched
   */
  event MessageBatchDispatched(
    bytes32 indexed messageId,
    address indexed from,
    uint256 indexed toChainId,
    MessageLib.Message[] messages
  );

  /**
   * @notice Retrieves address of the MessageExecutor contract on the receiving chain.
   * @dev Must revert if `toChainId` is not supported.
   * @param toChainId ID of the chain with which MessageDispatcher is communicating
   * @return address MessageExecutor contract address
   */
  function getMessageExecutorAddress(uint256 toChainId) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "./IMessageDispatcher.sol";

import "../libraries/MessageLib.sol";

/**
 * @title MessageExecutor interface
 * @notice MessageExecutor interface of the ERC-5164 standard as defined in the EIP.
 */
interface IMessageExecutor {
  /**
   * @notice Emitted when a message has successfully been executed.
   * @param fromChainId ID of the chain that dispatched the message
   * @param messageId ID uniquely identifying the message that was executed
   */
  event MessageIdExecuted(
    uint256 indexed fromChainId,
    bytes32 indexed messageId
  );

  /**
   * @notice Execute message from the origin chain.
   * @dev Should authenticate that the call has been performed by the bridge transport layer.
   * @dev Must revert if the message fails.
   * @dev Must emit the `MessageIdExecuted` event once the message has been executed.
   * @param to Address that will receive `data`
   * @param data Data forwarded to address `to`
   * @param messageId ID uniquely identifying the message
   * @param fromChainId ID of the chain that dispatched the message
   * @param from Address of the sender on the origin chain
   */
  function executeMessage(
    address to,
    bytes calldata data,
    bytes32 messageId,
    uint256 fromChainId,
    address from
  ) external;

  /**
   * @notice Execute a batch messages from the origin chain.
   * @dev Should authenticate that the call has been performed by the bridge transport layer.
   * @dev Must revert if one of the messages fails.
   * @dev Must emit the `MessageIdExecuted` event once messages have been executed.
   * @param messages Array of messages being executed
   * @param messageId ID uniquely identifying the messages
   * @param fromChainId ID of the chain that dispatched the messages
   * @param from Address of the sender on the origin chain
   */
  function executeMessageBatch(
    MessageLib.Message[] calldata messages,
    bytes32 messageId,
    uint256 fromChainId,
    address from
  ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "./IMessageDispatcher.sol";

/**
 * @title ERC-5164: Cross-Chain Execution Standard, optional SingleMessageDispatcher extension
 * @dev See https://eips.ethereum.org/EIPS/eip-5164
 */
interface ISingleMessageDispatcher is IMessageDispatcher {
  /**
   * @notice Dispatch a message to the receiving chain.
   * @dev Must compute and return an ID uniquely identifying the message.
   * @dev Must emit the `MessageDispatched` event when successfully dispatched.
   * @param toChainId ID of the receiving chain
   * @param to Address on the receiving chain that will receive `data`
   * @param data Data dispatched to the receiving chain
   * @return bytes32 ID uniquely identifying the message
   */
  function dispatchMessage(
    uint256 toChainId,
    address to,
    bytes calldata data
  ) external returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import { IMessageExecutor } from "../interfaces/IMessageExecutor.sol";

/**
 * @title MessageLib
 * @notice Library to declare and manipulate Message(s).
 */
library MessageLib {
  /* ============ Structs ============ */

  /**
   * @notice Message data structure
   * @param to Address that will be dispatched on the receiving chain
   * @param data Data that will be sent to the `to` address
   */
  struct Message {
    address to;
    bytes data;
  }

  /* ============ Events ============ */

  /* ============ Custom Errors ============ */

  /**
   * @notice Emitted when a messageId has already been executed.
   * @param messageId ID uniquely identifying the message or message batch that were re-executed
   */
  error MessageIdAlreadyExecuted(bytes32 messageId);

  /**
   * @notice Emitted if a call to a contract fails.
   * @param messageId ID uniquely identifying the message
   * @param errorData Error data returned by the call
   */
  error MessageFailure(bytes32 messageId, bytes errorData);

  /**
   * @notice Emitted if a call to a contract fails inside a batch of messages.
   * @param messageId ID uniquely identifying the batch of messages
   * @param messageIndex Index of the message
   * @param errorData Error data returned by the call
   */
  error MessageBatchFailure(bytes32 messageId, uint256 messageIndex, bytes errorData);

  /* ============ Internal Functions ============ */

  /**
   * @notice Helper to compute messageId.
   * @param nonce Monotonically increased nonce to ensure uniqueness
   * @param from Address that dispatched the message
   * @param to Address that will receive the message
   * @param data Data that was dispatched
   * @return bytes32 ID uniquely identifying the message that was dispatched
   */
  function computeMessageId(
    uint256 nonce,
    address from,
    address to,
    bytes memory data
  ) internal pure returns (bytes32) {
    return keccak256(abi.encode(nonce, from, to, data));
  }

  /**
   * @notice Helper to compute messageId for a batch of messages.
   * @param nonce Monotonically increased nonce to ensure uniqueness
   * @param from Address that dispatched the messages
   * @param messages Array of Message dispatched
   * @return bytes32 ID uniquely identifying the message that was dispatched
   */
  function computeMessageBatchId(
    uint256 nonce,
    address from,
    Message[] memory messages
  ) internal pure returns (bytes32) {
    return keccak256(abi.encode(nonce, from, messages));
  }

  /**
   * @notice Helper to encode message for execution by the MessageExecutor.
   * @param to Address that will receive the message
   * @param data Data that will be dispatched
   * @param messageId ID uniquely identifying the message being dispatched
   * @param fromChainId ID of the chain that dispatched the message
   * @param from Address that dispatched the message
   */
  function encodeMessage(
    address to,
    bytes memory data,
    bytes32 messageId,
    uint256 fromChainId,
    address from
  ) internal pure returns (bytes memory) {
    return
      abi.encodeWithSelector(
        IMessageExecutor.executeMessage.selector,
        to,
        data,
        messageId,
        fromChainId,
        from
      );
  }

  /**
   * @notice Helper to encode a batch of messages for execution by the MessageExecutor.
   * @param messages Array of Message that will be dispatched
   * @param messageId ID uniquely identifying the batch of messages being dispatched
   * @param fromChainId ID of the chain that dispatched the batch of messages
   * @param from Address that dispatched the batch of messages
   */
  function encodeMessageBatch(
    Message[] memory messages,
    bytes32 messageId,
    uint256 fromChainId,
    address from
  ) internal pure returns (bytes memory) {
    return
      abi.encodeWithSelector(
        IMessageExecutor.executeMessageBatch.selector,
        messages,
        messageId,
        fromChainId,
        from
      );
  }

  /**
   * @notice Execute message from the origin chain.
   * @dev Will revert if `message` has already been executed.
   * @param to Address that will receive the message
   * @param data Data that was dispatched
   * @param messageId ID uniquely identifying message
   * @param fromChainId ID of the chain that dispatched the `message`
   * @param from Address of the sender on the origin chain
   * @param executedMessageId Whether `message` has already been executed or not
   */
  function executeMessage(
    address to,
    bytes memory data,
    bytes32 messageId,
    uint256 fromChainId,
    address from,
    bool executedMessageId
  ) internal {
    if (executedMessageId) {
      revert MessageIdAlreadyExecuted(messageId);
    }

    _requireContract(to);

    (bool _success, bytes memory _returnData) = to.call(
      abi.encodePacked(data, messageId, fromChainId, from)
    );

    if (!_success) {
      revert MessageFailure(messageId, _returnData);
    }
  }

  /**
   * @notice Execute messages from the origin chain.
   * @dev Will revert if `messages` have already been executed.
   * @param messages Array of messages being executed
   * @param messageId Nonce to uniquely identify the messages
   * @param from Address of the sender on the origin chain
   * @param fromChainId ID of the chain that dispatched the `messages`
   * @param executedMessageId Whether `messages` have already been executed or not
   */
  function executeMessageBatch(
    Message[] memory messages,
    bytes32 messageId,
    uint256 fromChainId,
    address from,
    bool executedMessageId
  ) internal {
    if (executedMessageId) {
      revert MessageIdAlreadyExecuted(messageId);
    }

    uint256 _messagesLength = messages.length;

    for (uint256 _messageIndex; _messageIndex < _messagesLength; ) {
      Message memory _message = messages[_messageIndex];
      _requireContract(_message.to);

      (bool _success, bytes memory _returnData) = _message.to.call(
        abi.encodePacked(_message.data, messageId, fromChainId, from)
      );

      if (!_success) {
        revert MessageBatchFailure(messageId, _messageIndex, _returnData);
      }

      unchecked {
        _messageIndex++;
      }
    }
  }

  /**
   * @notice Check that the call is being made to a contract.
   * @param to Address to check
   */
  function _requireContract(address to) internal view {
    require(to.code.length > 0, "MessageLib/no-contract-at-to");
  }
}