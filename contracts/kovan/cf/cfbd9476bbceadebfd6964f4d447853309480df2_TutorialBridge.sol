//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./console.sol";
import {IGatewayRegistry} from "./IGatewayRegistry.sol";

contract TutorialBridge {
    IGatewayRegistry public gatewayRegistry;

    constructor(IGatewayRegistry gatewayRegistry_) {
        console.log("Deploying a TutorialBridge.");
        gatewayRegistry = gatewayRegistry_;
    }

    function deposit(
        // Parameters from users
        string calldata symbol,
        string calldata message,
        // Parameters from RenVM
        uint256 amount,
        bytes32 nHash,
        bytes calldata signature
    ) external {
        bytes32 pHash = keccak256(abi.encode(symbol, message));
        gatewayRegistry.getMintGatewayBySymbol(symbol).mint(
            pHash,
            amount,
            nHash,
            signature
        );
        console.log("Deposit message: ", message);
    }

    function withdraw(
        // Parameters from users
        string calldata symbol,
        string calldata message,
        string calldata to,
        uint256 amount
    ) external {
        gatewayRegistry.getMintGatewayBySymbol(symbol).burn(bytes(to), amount);
        console.log("Withdraw message: ", message);
    }
}