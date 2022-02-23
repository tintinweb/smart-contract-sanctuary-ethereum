// SPDX-License-Identifier: Unlicensed

pragma solidity >= 0.8.0;

import "../interfaces/ILayerZeroEndpoint.sol";

contract TWAPSender {
  ILayerZeroEndpoint public endpoint;

  event TWAPSent(uint16 _destinationChainId, uint _twap);

  error ZeroBalance();
  error NotEnoughBalance();

  constructor(address _layerZeroEndpoint){
    endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
  }

  // TODO: onlyGovernance
  function sendTWAP(uint16 _destinationChainId, address _receiverAddress, uint _twap) public {
    if(address(this).balance == 0) revert ZeroBalance();

    bytes memory _payload = abi.encode(_twap);
    uint _messageFee = endpoint.estimateNativeFees(_destinationChainId, address(this), _payload, false, bytes(""));

    if(_messageFee > address(this).balance) revert NotEnoughBalance();

    endpoint.send{value: _messageFee}(_destinationChainId, abi.encodePacked(_receiverAddress), _payload, payable(msg.sender), address(0x0), bytes(""));

    emit TWAPSent(_destinationChainId, _twap);
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
  // the starting point of LayerZero message protocol
  function send(uint16 _chainId, bytes calldata _destination, bytes calldata _payload, address payable refundAddress, address _zroPaymentAddress,  bytes calldata txParameters ) external payable;

  // estimate the fee requirement for message passing
  function estimateNativeFees(uint16 _chainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _txParameters)  view external returns(uint totalFee);

  // LayerZero uses nonce to enforce message ordering.
  function getInboundNonce(uint16 _chainID, bytes calldata _srcAddress) external view returns (uint64);

  function getOutboundNonce(uint16 _chainID, address _srcAddress) external view returns (uint64);

  // endpoint has a unique ID that never change. User application may need this to identity the blockchain they are on
  function getEndpointId() view external returns(uint16);

  // LayerZero catch all error/exception from the receiver contract and store them for retry.
  function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint _gasLimit) external returns(bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.0;

// a contract that implements this interface must have access
// to a LayerZero endpoint
interface ILayerZeroUserApplicationConfig {
    // generic config for user Application
    function setConfig(uint16 _version, uint _configType, bytes calldata _config) external;
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) view external returns(bytes memory);

    // LayerZero versions. Send/Receive can be different versions during migration
    function setSendVersion(uint16 version) external;
    function setReceiveVersion(uint16 version) external;
    function getSendVersion() external view returns (uint16);
    function getReceiveVersion() external view returns (uint16);

    //---------------------------------------------------------------------------
    // Only in extreme cases where the UA needs to resume the message flow
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}