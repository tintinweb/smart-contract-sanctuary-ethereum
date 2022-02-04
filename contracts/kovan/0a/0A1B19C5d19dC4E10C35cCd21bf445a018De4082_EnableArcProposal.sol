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
    0xF4a1F5fEA79C3609514A417425971FadC10eCfBE;

  // SEBA's Address
  address public constant SEBA_ADDRESS = 0xACce6CF9f65BE741caFBA26b880eF8C6c219422B;

  function execute() external override {
    address[] memory admins = new address[](1);
    admins[0] = SEBA_ADDRESS;

    // Add SEBA as PermissionAdmin
    IPermissionManagerAIP(ARC_PERMISSION_MANAGER_ADDRESS).addPermissionAdmins(admins);
  }
}