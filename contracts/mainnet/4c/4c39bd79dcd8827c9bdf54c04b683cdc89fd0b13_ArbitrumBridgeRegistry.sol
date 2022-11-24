/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.17;

contract ArbitrumBridgeRegistry {
    event ArbitrumSignalEmitted(
        address indexed sender,
        address indexed l1Token,
        address indexed l2Token,
        address l2OwnerAddress,
        address l1Gateway,
        address l2Gateway
    );

    /**
     * @notice Signal an Arbitrum bridge registration from the token owner, subject to manual verification
     *         If the token can be upgraded, it can call L1GatewayRouter.setGateway to register trustlessly instead
     * @param l1Token L1 address of token
     * @param l2Token L2 address of token
     * @param l2OwnerAddress L2 address of the token owner
     * @param l1Gateway L1 address of gateway, use address(0) for standard custom gateway
     * @param l2Gateway L2 address of gateway, use address(0) for standard custom gateway
     */
    function signalArbitrumBridgeRegistration(
        address l1Token,
        address l2Token,
        address l2OwnerAddress,
        address l1Gateway,
        address l2Gateway
    ) external {
        emit ArbitrumSignalEmitted(
            msg.sender,
            l1Token,
            l2Token,
            l2OwnerAddress,
            l1Gateway,
            l2Gateway
        );
    }
}