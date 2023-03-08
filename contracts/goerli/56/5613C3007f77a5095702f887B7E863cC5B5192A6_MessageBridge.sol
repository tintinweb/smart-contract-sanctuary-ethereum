// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IStarknetCore {
  function sendMessageToL2(
    uint256 to_address,
    uint256 selector,
    uint256[] calldata payload
  ) external returns (bytes32);

  function consumeMessageFromL2(
    uint256 fromAddress,
    uint256[] calldata payload
  ) external returns (bytes32);

  function l2ToL1Messages(bytes32 msgHash) external view returns (uint256);
}

contract MessageBridge {
  IStarknetCore starknetCore;

  constructor(address _starknetCore) {
    starknetCore = IStarknetCore(_starknetCore);
  }

  function setStarknetCore(address starknetCore_) public {
    starknetCore = IStarknetCore(starknetCore_);
  }

  function receiveMessage(uint256 l2ContractAddress, uint256 message) external {
    uint256[] memory payload = new uint256[](1);
    payload[0] = message;

    starknetCore.consumeMessageFromL2(l2ContractAddress, payload);
  }

  function sendMessage(uint256 l2_address, uint256 message, uint256 selector) public {
    uint256[] memory payload = new uint256[](1);
    payload[0] = message;

    starknetCore.sendMessageToL2(l2_address, selector, payload);
  }
}