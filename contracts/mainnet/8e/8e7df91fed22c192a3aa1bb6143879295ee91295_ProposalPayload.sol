// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.12;

import {IEcosystemReserveController} from "./external/aave/IEcosystemReserveController.sol";

/// @title Renew AAVE Grants DAO
/// @author Austin Green @AustinGreen
/// @notice Renew AGD by transferring $3M AAVE and approving $3M USDC
contract ProposalPayload {
    /*///////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice AaveEcosystemReserveController address.
    IEcosystemReserveController private constant reserveController =
        IEcosystemReserveController(0x3d569673dAa0575c936c7c67c4E6AedA69CC630C);

    /// @notice aUSDC token.
    address private constant aUsdc = 0xBcca60bB61934080951369a648Fb03DF4F96263C;

    /// @notice AAVE token.
    address private constant aave = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    /// @notice Aave Grants DAO multisig address.
    address private constant aaveGrantsDaoMultisig = 0x89C51828427F70D77875C6747759fB17Ba10Ceb0;

    /// @notice Aave Ecosystem Reserve address.
    address private constant aaveEcosystemReserve = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;

    /// @notice Aave Collector V2 address.
    address private constant aaveCollector = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    // $3,000,000 / 134.28 (coingecko avg opening price from 5/4-5/10)
    uint256 private constant aaveAmount = 22341380000000000000000;
    uint256 private constant aUsdcAmount = 3000000000000;

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        reserveController.transfer(aaveEcosystemReserve, aave, aaveGrantsDaoMultisig, aaveAmount);
        reserveController.approve(aaveCollector, aUsdc, aaveGrantsDaoMultisig, aUsdcAmount);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

interface IEcosystemReserveController {
    /**
     * @notice Proxy function for ERC20's approve(), pointing to a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param token The asset address
     * @param recipient Allowance's recipient
     * @param amount Allowance to approve
     **/
    function approve(
        address collector,
        address token,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Proxy function for ERC20's transfer(), pointing to a specific collector contract
     * @param collector The collector contract with funds (Aave ecosystem reserve)
     * @param token The asset address
     * @param recipient Transfer's recipient
     * @param amount Amount to transfer
     **/
    function transfer(
        address collector,
        address token,
        address recipient,
        uint256 amount
    ) external;
}