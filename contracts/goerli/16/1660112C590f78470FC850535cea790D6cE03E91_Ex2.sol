/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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


contract Ex2 {
    IStarknetCore starknetCore;
    uint256 constant public EX2_SELECTOR = 897827374043036985111827446442422621836496526085876968148369565281492581228;
    uint256 constant public EVALUATOR_CONTRACT = 0x02a77bb771fdcb0966639bab6e2b5842e7d0e7dff2f8258e3aee8e38695d98f6;
    address constant public STARKNET_CORE = 0xde29d060D45901Fb19ED6C6e959EB22d8626708e;

    constructor() {
        starknetCore = IStarknetCore(STARKNET_CORE);
    }

    function sendToL2Evaluator(uint256 l2_user) external returns(bytes32) {
        uint256[] memory payload = new uint256[](1);
        payload[0] = l2_user;
        return starknetCore.sendMessageToL2(
            EVALUATOR_CONTRACT,
            EX2_SELECTOR,
            payload
        );
    }
}