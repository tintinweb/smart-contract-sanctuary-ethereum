/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

interface IPermissionManagerAIP {
  function addPermissionAdmins(address[] calldata admins) external;
}

interface IProposalExecutor {
  function execute() external;
}

contract EnableArcProposal is IProposalExecutor {
  address public constant ARC_PERMISSION_MANAGER_ADDRESS =
    0x36B1076a052C1dceB86833A9dF8C1F79f8278DB0;

  // SEBA's Address
  address public constant SEBA_ADDRESS = 0xACce6CF9f65BE741caFBA26b880eF8C6c219422B;

  // ARC Multisig
  address public constant ARC_MARKET_MULTISIG_ADDRESS = 0x23c155C1c1ecB18a86921Da29802292f1d282c68;

  function execute() external override {
    address[] memory admins = new address[](1);
    admins[0] = SEBA_ADDRESS;

    // Add SEBA as PermissionAdmin
    IPermissionManagerAIP(ARC_PERMISSION_MANAGER_ADDRESS).addPermissionAdmins(admins);
  }
}