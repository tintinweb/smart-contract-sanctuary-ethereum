/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

interface IStarknetMessaging {
    function sendMessageToL2(uint256 toAddress, uint256 selector, uint256[] calldata payload) external;
}

contract Messager {
    IStarknetMessaging messaginContract;

    constructor() {
        messaginContract = IStarknetMessaging(0xde29d060D45901Fb19ED6C6e959EB22d8626708e);
    }

    function sendMessage(uint256 receiver, uint256 selector, uint256[] calldata payload) external {
        messaginContract.sendMessageToL2(receiver, selector, payload);
    }

}