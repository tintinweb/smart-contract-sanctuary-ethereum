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

    function ex3_func() external {

        uint256 l2ContractAddress = 0x02a77bb771fdcb0966639bab6e2b5842e7d0e7dff2f8258e3aee8e38695d98f6;
        uint256 l2Address = 0x055c52294ccf1a6e1943060461ba3be621fec8d00fd12c15f6f7376fc40348cf;

        // Construct the deposit message's payload.
        uint256[] memory payload = new uint256[](1);
        payload[0] = l2Address;

        // Consume the message from the StarkNet core contract.
        // This will revert the (Ethereum) transaction if the message does not exist.
        starknetCore.consumeMessageFromL2(l2ContractAddress, payload);
    }

    
}