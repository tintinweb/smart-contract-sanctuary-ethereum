// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IStarknetCore.sol";

contract sendl2_ex2 {
    address constant starknetCore_ = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;
    // The StarkNet core contract.
    IStarknetCore starknetCore;

    constructor(
        
    )  {
        starknetCore = IStarknetCore(starknetCore_);
    }

function sendl2_ex2_func(uint256 l2_user) external  {

        // The selector of the "deposit" l1_handler.
        uint256 l2ContractAddress = 0x02a77bb771fdcb0966639bab6e2b5842e7d0e7dff2f8258e3aee8e38695d98f6;
        uint256 ex2_selector = 897827374043036985111827446442422621836496526085876968148369565281492581228;

        // Construct the deposit message's payload.
        uint256[] memory payload = new uint256[](1);
        payload[0] = l2_user;

        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(
            l2ContractAddress,
            ex2_selector,
            payload
        );
        
      }
      }