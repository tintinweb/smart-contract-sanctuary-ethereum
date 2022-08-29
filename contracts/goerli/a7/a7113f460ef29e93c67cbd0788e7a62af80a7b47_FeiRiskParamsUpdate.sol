// SPDX-License-Identifier: MIT

/*
   _      ΞΞΞΞ      _
  /_;-.__ / _\  _.-;_\
     `-._`'`_/'`.-'
         `\   /`
          |  /
         /-.(
         \_._\
          \ \`;
           > |/
          / //
          |//
          \(\
           ``
     defijesus.eth
*/

pragma solidity 0.8.11;

interface IProposalGenericExecutor {
    function execute() external;
}

interface ILendingPoolConfigurator {
    function freezeReserve(
        address asset
    ) external;

    function setReserveFactor(
        address asset,
        uint256 reserveFactor
    ) external;
}

// This payload freezes the FEI aave v2 market and sets the reserve factor to 100%
// in preparation for Tribe DAO wind down.
// https://governance.aave.com/t/arc-risk-parameter-updates-for-ethereum-aave-v2-market/9393
// https://snapshot.org/#/aave.eth/proposal/0x19df23070be999efbb7caf6cd35c320eb74dd119bcb15d003dc2e82c2bbd0d94
contract FeiRiskParamsUpdate is IProposalGenericExecutor {
    address public constant FEI = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;
    address public constant LENDING_POOL_CONFIGURATOR = 0x311Bb771e4F8952E6Da169b425E7e92d6Ac45756;

    function execute() external override {
        ILendingPoolConfigurator(LENDING_POOL_CONFIGURATOR).freezeReserve(FEI);
        ILendingPoolConfigurator(LENDING_POOL_CONFIGURATOR).setReserveFactor(FEI, 10_000);
    }
}