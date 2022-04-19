// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IStarknetCore.sol";

contract ex3 {
    address constant starknetCore_ = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
    // The StarkNet core contract.
    IStarknetCore starknetCore;

    constructor(
        
    )  {
        starknetCore = IStarknetCore(starknetCore_);
    }

    function consumeMessage(uint256 l2ContractAddress, uint256 l2Address) external {
        
        // Construct the deposit message's payload.
        uint256[] memory payload = new uint256[](1);
        payload[0] = l2Address;

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);
    }

    
}