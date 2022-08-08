// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStarknetCore {
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);
}

/**
 * Responsible for deploying new ERC20 contracts via CREATE2
 */
contract MessageSender {
    IStarknetCore starknetCore;

    uint256 private RECEIVE_MESSAGE_SELECOTR =
        553425568686160303360369235733045232832184867091326150059710842684492237157;

    constructor() {
        starknetCore = IStarknetCore(0xde29d060D45901Fb19ED6C6e959EB22d8626708e);
    }

    function sendMessageToL2(uint256 l2Address, uint256 value) public {
        uint256[] memory payload = new uint256[](2);
        payload[0] = l2Address;
        payload[1] = value;

        starknetCore.sendMessageToL2(l2Address, RECEIVE_MESSAGE_SELECOTR, payload);
    }
}