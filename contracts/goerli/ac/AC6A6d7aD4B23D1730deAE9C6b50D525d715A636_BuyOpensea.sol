// SPDX-License-Identifier: Apache-2.0.
pragma solidity >=0.7.0 <0.9.0;

interface IStarknetCore {
    /**
      Sends a message to an L2 contract.

      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external payable returns (bytes32);

    /**
      Consumes a message that was sent from an L2 contract.

      Returns the hash of the message.
    */
    function consumeMessageFromL2(
        uint256 fromAddress,
        uint256[] calldata payload
    ) external returns (bytes32);
}

/**
  Demo contract for L1 <-> L2 interaction between an L2 StarkNet contract and this L1 solidity
  contract.
*/
contract BuyOpensea {
    // The StarkNet core contract.
    IStarknetCore starknetCore;

    mapping(uint256 => uint256) public userBalances;

    uint256 constant MESSAGE_BUY = 0;

    // The selector of the "deposit" l1_handler.
    uint256 constant DEPOSIT_SELECTOR =
        352040181584456735608515580760888541466059565068553383579463728554843487745;

    event Received(uint256 _from, uint256 _tokenId, uint256 _price);

    /**
      Initializes the contract state.
    */
    constructor(IStarknetCore starknetCore_) public {
        starknetCore = starknetCore_;
    }

    function buy(
        uint256 l2ContractAddress,
        uint256 tokenId,
        uint256 price
    ) external {
        // Construct the withdrawal message's payload.
        uint256[] memory payload = new uint256[](3);
        payload[0] = MESSAGE_BUY;
        payload[1] = tokenId;
        payload[2] = price;

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);

        // Update the L1 balance.
        emit Received(l2ContractAddress, tokenId, price);
    }
}