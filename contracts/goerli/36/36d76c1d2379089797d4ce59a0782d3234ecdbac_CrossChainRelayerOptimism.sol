// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import { ICrossDomainMessenger as IOptimismBridge } from "@eth-optimism/contracts/libraries/bridge/ICrossDomainMessenger.sol";

import "../interfaces/ICrossChainRelayer.sol";

/**
 * @title CrossChainRelayer contract
 * @notice The CrossChainRelayer contract allows a user or contract to send messages to another chain.
 *         It lives on the origin chain and communicates with the `CrossChainReceiver` contract on the receiving chain.
 */
contract CrossChainRelayerOptimism is ICrossChainRelayer {
  /* ============ Custom Errors ============ */

  /**
   * @notice Custom error emitted if the `gasLimit` passed to `relayCalls`
   *         is greater than the one provided for free on Optimism.
   * @param gasLimit Gas limit passed to `relayCalls`
   * @param maxGasLimit Gas limit provided for free on Optimism
   */
  error GasLimitTooHigh(uint256 gasLimit, uint256 maxGasLimit);

  /* ============ Variables ============ */

  /// @notice Address of the Optimism bridge on the origin chain.
  IOptimismBridge public immutable bridge;

  /// @notice Gas limit provided for free on Optimism.
  uint256 public immutable maxGasLimit;

  /// @notice Internal nonce to uniquely idenfity each batch of calls.
  uint256 internal nonce;

  /* ============ Constructor ============ */

  /**
   * @notice CrossChainRelayer constructor.
   * @param _bridge Address of the Optimism bridge
   * @param _maxGasLimit Gas limit provided for free on Optimism
   */
  constructor(IOptimismBridge _bridge, uint256 _maxGasLimit) {
    require(address(_bridge) != address(0), "Relayer/bridge-not-zero-address");
    require(_maxGasLimit > 0, "Relayer/max-gas-limit-gt-zero");

    bridge = _bridge;
    maxGasLimit = _maxGasLimit;
  }

  /* ============ External Functions ============ */

  /// @inheritdoc ICrossChainRelayer
  function relayCalls(
    ICrossChainReceiver _receiver,
    Call[] calldata _calls,
    uint256 _gasLimit
  ) external payable {
    uint256 _maxGasLimit = maxGasLimit;

    if (_gasLimit > _maxGasLimit) {
      revert GasLimitTooHigh(_gasLimit, _maxGasLimit);
    }

    nonce++;

    uint256 _nonce = nonce;
    IOptimismBridge _bridge = bridge;

    _bridge.sendMessage(
      address(_receiver),
      abi.encodeWithSignature(
        "receiveCalls(address,uint256,address,(address,bytes)[])",
        address(this),
        _nonce,
        msg.sender,
        _calls
      ),
      uint32(_gasLimit)
    );

    emit RelayedCalls(_nonce, msg.sender, _receiver, _calls, _gasLimit);
  }
}

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

import "./ICrossChainReceiver.sol";

/**
 * @title CrossChainRelayer interface
 * @notice CrossChainRelayer interface of the ERC5164 standard as defined in the EIP.
 */
interface ICrossChainRelayer {
  /**
   * @notice Call data structure
   * @param target Address that will be called on the receiving chain
   * @param data Data that will be sent to the `target` address
   */
  struct Call {
    address target;
    bytes data;
  }

  /**
   * @notice Emitted when calls have successfully been relayed to the receiver chain.
   * @param nonce Unique identifier
   * @param sender Address of the sender
   * @param receiver Address of the CrossChainReceiver contract on the receiving chain
   * @param calls Array of calls being relayed
   * @param gasLimit Maximum amount of gas required for the `calls` to be executed
   */
  event RelayedCalls(
    uint256 indexed nonce,
    address indexed sender,
    ICrossChainReceiver indexed receiver,
    Call[] calls,
    uint256 gasLimit
  );

  /**
   * @notice Relay the calls to the receiving chain.
   * @dev Must implement `ICrossChainReceiver.receiveCalls` to relay the calls on the receiving chain.
   * @dev Must increment a `nonce` so that each batch of calls can be uniquely identified.
   * @dev Must emit the `RelayedCalls` event when successfully called.
   * @dev May require payment. Some bridges may require payment in the native currency, so the function is payable.
   * @param receiver Address who will receive the calls on the receiving chain
   * @param calls Array of calls being relayed
   * @param gasLimit Maximum amount of gas required for the `calls` to be executed
   */
  function relayCalls(
    ICrossChainReceiver receiver,
    Call[] calldata calls,
    uint256 gasLimit
  ) external payable;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "./ICrossChainRelayer.sol";

/**
 * @title CrossChainReceiver interface
 * @notice CrossChainReceiver interface of the ERC5164 standard as defined in the EIP.
 */
interface ICrossChainReceiver {
  /**
   * @notice Call data structure
   * @param target Address that will be called
   * @param data Data that will be sent to the `target` address
   */
  struct Call {
    address target;
    bytes data;
  }

  /**
   * @notice Emitted when calls have successfully been received.
   * @param relayer Address of the contract that relayed the calls
   * @param nonce Unique identifier
   * @param caller Address of the caller on the origin chain
   * @param calls Array of calls being received
   */
  event ReceivedCalls(
    ICrossChainRelayer indexed relayer,
    uint256 indexed nonce,
    address indexed caller,
    Call[] calls
  );

  /**
   * @notice Receive calls from the origin chain.
   * @dev Should authenticate that the call has been performed by the bridge transport layer.
   * @dev Must emit the `ReceivedCalls` event when calls are received.
   * @param relayer Address who relayed the call on the origin chain
   * @param nonce Unique identifier
   * @param caller Address of the caller on the origin chain
   * @param calls Array of calls being received
   */
  function receiveCalls(
    ICrossChainRelayer relayer,
    uint256 nonce,
    address caller,
    Call[] calldata calls
  ) external;
}