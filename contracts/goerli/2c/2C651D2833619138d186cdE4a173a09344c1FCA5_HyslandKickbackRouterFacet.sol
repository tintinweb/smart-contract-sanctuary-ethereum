// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IHyslandKickbackRouterFacet } from "./../interfaces/facets/IHyslandKickbackRouterFacet.sol";


/**
 * @title HyslandKickbackRouterFacet
 * @author Hysland Finance
 * @notice A diamond facet for crediting integrators and service providers.
 *
 * Hyswap is the first dex to offer kickbacks. The goal is to incentivize decentralization and growth of the protocol.
 *
 * Rewards will not be distributed immediately. Rewards will accrue in the Hysland treasury and be distributed over time.
 *
 * Integrators and service providers can qualify for a portion of the rewards by attaching a call to [`hyslandKickbackCredit()`](#hyslandkickbackcredit) to the end of each trade.
 */
contract HyslandKickbackRouterFacet is IHyslandKickbackRouterFacet {

    /**
     * @notice Registers the service provider for a trade.
     * @param receiver The address to receive the kickback rewards
     */
    function hyslandKickbackCredit(address receiver) external payable override {
        emit HyslandKickbackCredited(receiver);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title IHyslandKickbackRouterFacet
 * @author Hysland Finance
 * @notice A diamond facet for crediting integrators and service providers.
 *
 * Hyswap is the first dex to offer kickbacks. The goal is to incentivize decentralization and growth of the protocol.
 *
 * Rewards will not be distributed immediately. Rewards will accrue in the Hysland treasury and be distributed over time.
 *
 * Integrators and service providers can qualify for a portion of the rewards by attaching a call to [`hyslandKickbackCredit()`](#hyslandkickbackcredit) to the end of each trade.
 */
interface IHyslandKickbackRouterFacet {

    /// @notice Emitted when a trade is registered to a service provider.
    event HyslandKickbackCredited(address indexed receiver);

    /**
     * @notice Registers the service provider for a trade.
     * @param receiver The address to receive the kickback rewards
     */
    function hyslandKickbackCredit(address receiver) external payable;
}