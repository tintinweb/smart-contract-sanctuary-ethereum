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
contract ArraySender {
    IStarknetCore starknetCore;

    uint256 private RECEIVE_MESSAGE_SELECOTR =
        553425568686160303360369235733045232832184867091326150059710842684492237157;

    uint256 private RECEIVE_ARRAY_SELECOTR =
        570099863067115611332813595357874139658630400547114864749913229678025829590;

    constructor() {
        starknetCore = IStarknetCore(0xde29d060D45901Fb19ED6C6e959EB22d8626708e);
    }

    function sendMessageToL2(uint256 l2Address, uint256 value) external {
        uint256[] memory payload = new uint256[](2);
        payload[0] = l2Address;
        payload[1] = value;

        starknetCore.sendMessageToL2(l2Address, RECEIVE_MESSAGE_SELECOTR, payload);
    }

    function sendArrayToL2(uint256 l2Address, uint256[] memory values) external {
        uint256 length = values.length;
        uint256[] memory payload = new uint256[](length);
        uint256 i;
        for (i = 0; i < length; i++) {
            payload[i] = values[i];
        }

        starknetCore.sendMessageToL2(l2Address, RECEIVE_ARRAY_SELECOTR, payload);
    }
}