// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IStarknetCore.sol";

contract Ex2Minter {
    IStarknetCore starknetCore;

    constructor() {
        starknetCore = IStarknetCore(
            0xde29d060D45901Fb19ED6C6e959EB22d8626708e
        );
    }

    function l2Mint() external {
        uint256 l2ContractAddress = 0x02a77bb771fdcb0966639bab6e2b5842e7d0e7dff2f8258e3aee8e38695d98f6;
        // python
        // from starkware.starknet.compiler.compile import get_selector_from_name
        // get_selector_from_name('ex2')
        uint256 selector = 897827374043036985111827446442422621836496526085876968148369565281492581228;
        uint256[] memory payload = new uint256[](1);
        payload[0] = 0x067F63af0ccd588cb3b858E1CAC746544420aF97e15DA4711c6547173625018a;

        // Send the message to the StarkNet core contract.
        starknetCore.sendMessageToL2(l2ContractAddress, selector, payload);
    }
}