/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

/*SPDX-License-Identifier: UNLICENSED" for non-open-source code. Please see https://spdx.org for more information.*/
pragma solidity ^0.8.7;

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
    function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
        external
        returns (bytes32);
}

/**
  Demo contract for L1 <-> L2 interaction between an L2 StarkNet contract and this L1 solidity
  contract.
*/
contract L1L2Example {
    // The StarkNet core contract.
    IStarknetCore starknetCore;
    // The selector of the "receive" l1_handler.
    uint256 constant DEPOSIT_SELECTOR = 947007765874916242425550287593172441347876881688900563420978990671380206971;
    uint256 constant UINT256_PART_SIZE_BITS = 128;
    uint256 constant UINT256_PART_SIZE = 2**UINT256_PART_SIZE_BITS;


    /**
      Initializes the contract state.
    */
    constructor(IStarknetCore starknetCore_) {
        starknetCore = starknetCore_;
    }


    function deposit(
        uint256 l2ContractAddress,
        uint256 amount
    ) external {
        // Construct the deposit message's payload.        
        uint256[] memory payload = new uint256[](3);                                                                
        payload[0] = l2ContractAddress;
        payload[1] = amount & (UINT256_PART_SIZE - 1);
        payload[2] = amount >> UINT256_PART_SIZE_BITS;

        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(l2ContractAddress, DEPOSIT_SELECTOR, payload);
    }
}