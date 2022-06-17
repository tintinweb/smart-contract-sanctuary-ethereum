// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IStarknetCore.sol";

contract l1l2 {
    uint256 private EX2_SELECTOR;
    // The StarkNet core contract.
    IStarknetCore starknetCore;

    constructor(
        uint256 ex2Selector_,
        address starknetCore_
    ) public {
        starknetCore = IStarknetCore(starknetCore_);
        EX2_SELECTOR = ex2Selector_;
    }

    event messageReceivedFromStarkNet();
    event messageSentToStarkNet();
 
  function consumeMessage(uint256 l2ContractAddress, uint256 l2User) external{
          uint256[] memory payload = new uint256[](1);
          payload[0] = l2User;
          // Consume the message from the StarkNet core contract.
          // This will revert the (Ethereum) transaction if the message does not exist.
          starknetCore.consumeMessageFromL2(l2ContractAddress, payload);
          emit messageReceivedFromStarkNet();
      }

  function l2mint(uint256 l2ContractAddress, uint256 l2_user) external {

      // Construct the deposit message's payload.
      uint256[] memory payload = new uint256[](1);
      payload[0] = l2_user;

      // Send the message to the StarkNet core contract.
      starknetCore.sendMessageToL2(
          l2ContractAddress,
          EX2_SELECTOR,
          payload
      );
      emit messageSentToStarkNet();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external returns (bytes32);

    function l2ToL1Messages(bytes32 msgHash) external view returns (uint256);
}