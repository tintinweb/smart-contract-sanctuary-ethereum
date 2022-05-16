// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "./interfaces/IReserveFactorV1.sol";
import "./interfaces/IAddressesProvider.sol";
import {ILendingPoolConfigurator} from "./interfaces/ILendingPoolConfigurator.sol";

/// @title Payload to refactor AAVE Reserve Factor
/// @author Austin Green and Noah Citron
/// @notice Provides an execute function for Aave governance to refactor its reserve factor and enable DPI borrowing.
contract ProposalPayload {
    /*///////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice AAVE's V1 Reserve Factor.
    IReserveFactorV1 private constant reserveFactorV1 = IReserveFactorV1(0xE3d9988F676457123C5fD01297605efdD0Cba1ae);

    /// @notice AAVE's V2 Reserve Factor.
    address private constant reserveFactorV2 = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;

    /// @notice Provides address mapping for AAVE.
    IAddressesProvider private constant addressProvider =
        IAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    /// @notice Token distributor implementation contract.
    address private constant tokenDistributorImpl = 0x55c559730cbCA5deB0bf9B85961957FfDf502603;

    /// @notice DPI token address.
    address private constant dpi = 0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b;

    /// @notice AAVE V2 LendingPoolConfigurator
    ILendingPoolConfigurator private constant configurator =
        ILendingPoolConfigurator(0x311Bb771e4F8952E6Da169b425E7e92d6Ac45756);

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        // Upgrade to new implementation contract and direct all funds to v2
        address[] memory receivers = new address[](1);
        receivers[0] = reserveFactorV2;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100_00;

        reserveFactorV1.upgradeToAndCall(
            tokenDistributorImpl,
            abi.encodeWithSignature("initialize(address[],uint256[])", receivers, amounts)
        );

        // Set token distributor for AAVE v1 to V2 RF
        addressProvider.setTokenDistributor(reserveFactorV2);

        // enable DPI borrow
        configurator.enableBorrowingOnReserve(dpi, false);
    }

    function distributeTokens() external {
        // Distribute all tokens with meaningful balances to v2
        address[] memory tokenAddresses = new address[](16);
        tokenAddresses[0] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599; // WBTC
        tokenAddresses[1] = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
        tokenAddresses[2] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
        tokenAddresses[3] = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT
        tokenAddresses[4] = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200; // KNC
        tokenAddresses[5] = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2; // MKR
        tokenAddresses[6] = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942; // MANA
        tokenAddresses[7] = 0x4Fabb145d64652a948d72533023f6E7A623C7C53; // BUSD
        tokenAddresses[8] = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e; // YFI
        tokenAddresses[9] = 0x514910771AF9Ca656af840dff83E8264EcF986CA; // LINK
        tokenAddresses[10] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // UNI
        tokenAddresses[11] = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9; // AAVE
        tokenAddresses[12] = 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03; // LEND
        tokenAddresses[13] = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF; // BAT
        tokenAddresses[14] = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F; // SNX
        tokenAddresses[15] = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH
        reserveFactorV1.distribute(tokenAddresses);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

interface IReserveFactorV1 {
    function distribute(address[] memory) external;

    function upgradeToAndCall(address, bytes calldata) external payable;

    function getDistribution() external view returns (address[] memory, uint256[] memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

interface IAddressesProvider {
    function setTokenDistributor(address) external;

    function getTokenDistributor() external view returns (address);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.4.22 <0.9.0;

interface ILendingPoolConfigurator {
    function enableBorrowingOnReserve(address asset, bool stableEnabled) external;
}