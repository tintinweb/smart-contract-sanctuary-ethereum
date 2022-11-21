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

import {CrossChainUtils} from '../../CrossChainUtils.sol';

interface ILayerZeroAdapter {
  /// @dev pair of origin address and origin chain
  struct TrustedRemotesConfig {
    address originForwarder;
    CrossChainUtils.Chains originChainId;
  }

  /**
   * @dev emitted when a payload has been received and processed
   * @param originChainId id indicating the origin chain
   * @param nonce unique number of the message
   * @param sender address of the origination contract
   * @param payload message bridged
   */
  event LZPayloadProcessed(
    CrossChainUtils.Chains indexed originChainId,
    uint64 nonce,
    address indexed sender,
    bytes payload
  );

  /**
   * @dev method to get infrastructure chain id from bridge native chain id
   * @param bridgeChainId bridge native chain id
   */
  function nativeToInfraChainId(uint16 bridgeChainId)
    external
    returns (CrossChainUtils.Chains);

  /**
   * @dev method to get bridge native chain id from native bridge chain id
   * @param infraChainId infrastructure chain id
   */
  function infraToNativeChainId(CrossChainUtils.Chains infraChainId)
    external
    returns (uint16);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {BaseAdapter, CrossChainUtils} from '../BaseAdapter.sol';
import {NonblockingLzApp} from './lzApp/NonblockingLzApp.sol';
import {ILayerZeroAdapter} from './ILayerZeroAdapter.sol';

// to test https://layerzero.gitbook.io/docs/guides/code-examples/lzendpointmock.sol
//https://github.com/LayerZero-Labs/solidity-examples/blob/main/constants/chainIds.json

//https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
//https://github.com/LayerZero-Labs/solidity-examples/blob/main/constants/layerzeroEndpoints.json
//0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675
contract LayerZeroAdapter is BaseAdapter, NonblockingLzApp, ILayerZeroAdapter {
  /**
   * @dev constructor for the Layer Zero adapter
   * @param _lzEndpoint address of the layer zero endpoint on the current chain where adapter is deployed
   * @param originConfig object with chain id and origin address.
   * @param crossChainManager address of the contract that manages cross chain infrastructure
   */
  constructor(
    address _lzEndpoint,
    address crossChainManager,
    TrustedRemotesConfig[] memory originConfig
  ) NonblockingLzApp(_lzEndpoint) BaseAdapter(crossChainManager) {
    _updateTrustedRemotes(originConfig);
  }

  /// @dev implements forwardMessage from IBaseAdapter
  function forwardMessage(
    address receiver,
    uint256, // TODO: can estimation gas be used instead of manual gasLimit?
    CrossChainUtils.Chains destinationChainId,
    bytes memory message
  ) external {
    uint16 nativeChainId = infraToNativeChainId(destinationChainId);
    require(nativeChainId != uint16(0), 'BRIDGE_CHAIN_ID_NOT_SET');
    require(receiver != address(0), 'RECEIVER_NOT_SET');

    // get gas estimation
    (uint256 nativeFee, ) = lzEndpoint.estimateFees(
      nativeChainId,
      receiver,
      message,
      false,
      bytes('')
    );

    require(
      nativeFee <= address(this).balance,
      'NOT_ENOUGH_VALUE_TO_PAY_BRIDGE_FEES'
    );

    uint64 nonce = lzEndpoint.getOutboundNonce(nativeChainId, address(this));

    // remote address concatenated with local address packed into 40 bytes
    bytes memory remoteAndLocalAddresses = abi.encodePacked(
      receiver,
      address(this)
    );

    lzEndpoint.send{value: nativeFee}(
      nativeChainId,
      remoteAndLocalAddresses, //abi.encode(receiver),
      message,
      payable(address(this)),
      address(0x0), // for now we will not use zro to pay, but native currency: ETH
      bytes('')
    );

    emit MessageForwarded(receiver, nativeChainId, message, nonce);
  }

  /// @inheritdoc ILayerZeroAdapter
  function nativeToInfraChainId(
    uint16 nativeChainId
  ) public pure returns (CrossChainUtils.Chains) {
    if (nativeChainId == uint16(101)) {
      return CrossChainUtils.Chains.EthMainnet;
    } else if (nativeChainId == uint16(106)) {
      return CrossChainUtils.Chains.Avalanche;
    } else if (nativeChainId == uint16(109)) {
      return CrossChainUtils.Chains.Polygon;
    } else if (nativeChainId == uint16(110)) {
      return CrossChainUtils.Chains.Arbitrum;
    } else if (nativeChainId == uint16(111)) {
      return CrossChainUtils.Chains.Optimism;
    } else if (nativeChainId == uint16(112)) {
      return CrossChainUtils.Chains.Fantom;
    } else if (nativeChainId == uint16(116)) {
      return CrossChainUtils.Chains.Harmony;
    } else if (nativeChainId == 10121) {
      return CrossChainUtils.Chains.Goerli;
    } else if (nativeChainId == 10106) {
      return CrossChainUtils.Chains.AvalancheFuji;
    } else if (nativeChainId == 10132) {
      return CrossChainUtils.Chains.OptimismGoerli;
    } else if (nativeChainId == 10109) {
      return CrossChainUtils.Chains.PolygonMumbai;
    } else if (nativeChainId == 10143) {
      return CrossChainUtils.Chains.ArbitrumGoerli;
    } else if (nativeChainId == 10112) {
      return CrossChainUtils.Chains.FantomTestnet;
    } else if (nativeChainId == 10133) {
      return CrossChainUtils.Chains.HarmonyTestnet;
    } else {
      return CrossChainUtils.Chains.Null_network;
    }
  }

  /// @inheritdoc ILayerZeroAdapter
  function infraToNativeChainId(
    CrossChainUtils.Chains infraChainId
  ) public pure returns (uint16) {
    if (infraChainId == CrossChainUtils.Chains.EthMainnet) {
      return uint16(101);
    } else if (infraChainId == CrossChainUtils.Chains.Avalanche) {
      return uint16(106);
    } else if (infraChainId == CrossChainUtils.Chains.Polygon) {
      return uint16(109);
    } else if (infraChainId == CrossChainUtils.Chains.Arbitrum) {
      return uint16(110);
    } else if (infraChainId == CrossChainUtils.Chains.Optimism) {
      return uint16(111);
    } else if (infraChainId == CrossChainUtils.Chains.Fantom) {
      return uint16(112);
    } else if (infraChainId == CrossChainUtils.Chains.Harmony) {
      return uint16(116);
    } else if (infraChainId == CrossChainUtils.Chains.Goerli) {
      return 10121;
    } else if (infraChainId == CrossChainUtils.Chains.AvalancheFuji) {
      return 10106;
    } else if (infraChainId == CrossChainUtils.Chains.OptimismGoerli) {
      return 10132;
    } else if (infraChainId == CrossChainUtils.Chains.PolygonMumbai) {
      return 10109;
    } else if (infraChainId == CrossChainUtils.Chains.ArbitrumGoerli) {
      return 10143;
    } else if (infraChainId == CrossChainUtils.Chains.FantomTestnet) {
      return 10112;
    } else if (infraChainId == CrossChainUtils.Chains.HarmonyTestnet) {
      return 10133;
    } else {
      return uint16(0);
    }
  }

  /// @dev method called when receiving a message by layerZero Bridge infra
  function _nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal override {
    CrossChainUtils.Chains originChainId = nativeToInfraChainId(_srcChainId);
    // use assembly to extract the address from the bytes memory parameter
    address fromAddress = abi.decode(_srcAddress, (address));

    _registerReceivedMessage(_payload, originChainId);
    emit LZPayloadProcessed(originChainId, _nonce, fromAddress, _payload);
  }

  /**
   * @dev method that updates from where a message can be received
   * @param originConfigs array of configurations with origin address and chainId
   */
  function _updateTrustedRemotes(
    TrustedRemotesConfig[] memory originConfigs
  ) internal {
    for (uint256 i = 0; i < originConfigs.length; i++) {
      TrustedRemotesConfig memory originConfig = originConfigs[i];
      uint16 nativeOriginChain = infraToNativeChainId(
        originConfig.originChainId
      );
      bytes memory srcBytes = abi.encode(originConfig.originForwarder);
      trustedRemoteLookup[nativeOriginChain] = srcBytes;
      emit SetTrustedRemote(nativeOriginChain, srcBytes);
    }
  }
}

// SPDX-License-Identifier: MIT
// modified from https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/lzApp/LzApp.sol
// commit https://github.com/LayerZero-Labs/solidity-examples/commit/e46a95ce93347aa65680bef288e206af0e5a8917

pragma solidity ^0.8.0;

import './interfaces/ILayerZeroReceiver.sol';
import './interfaces/ILayerZeroEndpoint.sol';

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is ILayerZeroReceiver {
  ILayerZeroEndpoint public immutable lzEndpoint;

  mapping(uint16 => bytes) public trustedRemoteLookup;

  event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);

  constructor(address _endpoint) {
    lzEndpoint = ILayerZeroEndpoint(_endpoint);
  }

  function lzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) public virtual override {
    // lzReceive must be called by the endpoint for security
    require(
      msg.sender == address(lzEndpoint),
      'LzApp: invalid endpoint caller'
    );

    bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
    // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
    require(
      _srcAddress.length == trustedRemote.length &&
        keccak256(_srcAddress) == keccak256(trustedRemote),
      'LzApp: invalid source sending contract'
    );

    _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
  }

  // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
  function _blockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal virtual;

  //---------------------------UserApplication config----------------------------------------
  function getConfig(
    uint16 _version,
    uint16 _chainId,
    address,
    uint256 _configType
  ) external view returns (bytes memory) {
    return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
  }

  //--------------------------- VIEW FUNCTION ----------------------------------------

  function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress)
    external
    view
    returns (bool)
  {
    bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
    return keccak256(trustedSource) == keccak256(_srcAddress);
  }
}

// SPDX-License-Identifier: MIT
// from https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/lzApp/NonblockingLzApp.sol
// commit https://github.com/LayerZero-Labs/solidity-examples/commit/48a3ecd9ef4b3c4855230119c928a58af536e809

pragma solidity ^0.8.0;

import './LzApp.sol';

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
  constructor(address _endpoint) LzApp(_endpoint) {}

  mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32)))
    public failedMessages;

  event MessageFailed(
    uint16 _srcChainId,
    bytes _srcAddress,
    uint64 _nonce,
    bytes _payload
  );

  // overriding the virtual function in LzReceiver
  function _blockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal virtual override {
    // try-catch all errors/exceptions
    try this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
      // do nothing
    } catch {
      // error / exception
      failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
      emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
    }
  }

  function nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) public virtual {
    // only internal transaction
    require(
      msg.sender == address(this),
      'NonblockingLzApp: caller must be LzApp'
    );
    _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
  }

  //@notice override this function
  function _nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal virtual;

  function retryMessage(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) public payable virtual {
    // assert there is message to retry
    bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
    require(payloadHash != bytes32(0), 'NonblockingLzApp: no stored message');
    require(
      keccak256(_payload) == payloadHash,
      'NonblockingLzApp: invalid payload'
    );
    // clear the stored message
    failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
    // execute the message. revert if it fails again
    _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
  }
}

// SPDX-License-Identifier: MIT
// modified from https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/interfaces/ILayerZeroEndpoint.sol
// commit https://github.com/LayerZero-Labs/solidity-examples/commit/1422b0fd913e16cb1c79e33a9ddef0eb8cf6d9ae

pragma solidity >=0.5.0;

interface ILayerZeroEndpoint {
  // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
  // @param _dstChainId - the destination chain identifier
  // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
  // @param _payload - a custom bytes payload to send to the destination contract
  // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
  // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
  // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
  function send(
    uint16 _dstChainId,
    bytes calldata _destination,
    bytes calldata _payload,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes calldata _adapterParams
  ) external payable;

  // @notice used by the messaging library to publish verified payload
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source contract (as bytes) at the source chain
  // @param _dstAddress - the address on destination chain
  // @param _nonce - the unbound message ordering nonce
  // @param _gasLimit - the gas limit for external contract execution
  // @param _payload - verified payload to send to the destination contract
  function receivePayload(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    address _dstAddress,
    uint64 _nonce,
    uint256 _gasLimit,
    bytes calldata _payload
  ) external;

  // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source chain contract address
  function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress)
    external
    view
    returns (uint64);

  // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
  // @param _srcAddress - the source chain contract address
  function getOutboundNonce(uint16 _dstChainId, address _srcAddress)
    external
    view
    returns (uint64);

  // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
  // @param _dstChainId - the destination chain identifier
  // @param _userApplication - the user app address on this EVM chain
  // @param _payload - the custom message to send over LayerZero
  // @param _payInZRO - if false, user app pays the protocol fee in native token
  // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
  function estimateFees(
    uint16 _dstChainId,
    address _userApplication,
    bytes calldata _payload,
    bool _payInZRO,
    bytes calldata _adapterParam
  ) external view returns (uint256 nativeFee, uint256 zroFee);

  // @notice get this Endpoint's immutable source identifier
  function getChainId() external view returns (uint16);

  // @notice the interface to retry failed message on this Endpoint destination
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source chain contract address
  // @param _payload - the payload to be retried
  function retryPayload(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    bytes calldata _payload
  ) external;

  // @notice query if any STORED payload (message blocking) at the endpoint.
  // @param _srcChainId - the source chain identifier
  // @param _srcAddress - the source chain contract address
  function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress)
    external
    view
    returns (bool);

  // @notice query if the _libraryAddress is valid for sending msgs.
  // @param _userApplication - the user app address on this EVM chain
  function getSendLibraryAddress(address _userApplication)
    external
    view
    returns (address);

  // @notice query if the _libraryAddress is valid for receiving msgs.
  // @param _userApplication - the user app address on this EVM chain
  function getReceiveLibraryAddress(address _userApplication)
    external
    view
    returns (address);

  // @notice query if the non-reentrancy guard for send() is on
  // @return true if the guard is on. false otherwise
  function isSendingPayload() external view returns (bool);

  // @notice query if the non-reentrancy guard for receive() is on
  // @return true if the guard is on. false otherwise
  function isReceivingPayload() external view returns (bool);

  // @notice get the configuration of the LayerZero messaging library of the specified version
  // @param _version - messaging library version
  // @param _chainId - the chainId for the pending config change
  // @param _userApplication - the contract address of the user application
  // @param _configType - type of configuration. every messaging library has its own convention.
  function getConfig(
    uint16 _version,
    uint16 _chainId,
    address _userApplication,
    uint256 _configType
  ) external view returns (bytes memory);

  // @notice get the send() LayerZero messaging library version
  // @param _userApplication - the contract address of the user application
  function getSendVersion(address _userApplication)
    external
    view
    returns (uint16);

  // @notice get the lzReceive() LayerZero messaging library version
  // @param _userApplication - the contract address of the user application
  function getReceiveVersion(address _userApplication)
    external
    view
    returns (uint16);
}

// SPDX-License-Identifier: MIT
// from https://github.com/LayerZero-Labs/solidity-examples/blob/main/contracts/interfaces/ILayerZeroReceiver.sol
// commit https://github.com/LayerZero-Labs/solidity-examples/commit/1422b0fd913e16cb1c79e33a9ddef0eb8cf6d9ae

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
  // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
  // @param _srcChainId - the source endpoint identifier
  // @param _srcAddress - the source sending contract address from the source chain
  // @param _nonce - the ordered message nonce
  // @param _payload - the signed payload is the UA bytes has encoded to be sent
  function lzReceive(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    uint64 _nonce,
    bytes calldata _payload
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