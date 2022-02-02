// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface ILendingPoolConfiguratorAIP {
  function setPoolPause(bool pause) external;
}

interface ILendingPoolAddressesProviderAIP {
  function setEmergencyAdmin(address admin) external;

  function transferOwnership(address newOwner) external;
}

interface IPermissionManagerAIP {
  function addPermissionAdmins(address[] calldata admins) external;
}

interface IProposalExecutor {
  function execute() external;
}

contract EnableArcProposal is IProposalExecutor {
  address public constant ARC_POOL_ADDRESSES_PROVIDER_ADDRESS =
    0x96866c156730D472Be2aFeFa8f26891519c6aafB;
  address public constant ARC_POOL_CONFIGURATOR_ADDRESS =
    0xb350E7E96bc173339f08fCb1ceba0Bd878CCcf14;
  address public constant ARC_PERMISSION_MANAGER_ADDRESS =
    0x36B1076a052C1dceB86833A9dF8C1F79f8278DB0;

  // SEBA's Address
  address public constant SEBA_ADDRESS = 0x1b2Da87Bf469651f142BBdc928EEA9F4bf284031;

  // ARC Timelock Veto DAO
  address public constant ARC_TIMELOCK_VETO_DAO_ADDRESS =
    0xA084aB304Db64C17a37dFfb283762ec52B4e5F75;

  // ARC Multisig
  address public constant ARC_MARKET_MULTISIG_ADDRESS = 0xA084aB304Db64C17a37dFfb283762ec52B4e5F75;

  function execute() external override {
    address[] memory admins = new address[](1);
    admins[0] = SEBA_ADDRESS;

    // Add SEBA as PermissionAdmin
    IPermissionManagerAIP(ARC_PERMISSION_MANAGER_ADDRESS).addPermissionAdmins(admins);

    // Enable Arc market
    ILendingPoolConfiguratorAIP(ARC_POOL_CONFIGURATOR_ADDRESS).setPoolPause(false);

    // Transfer Emergency Admin and Market Owner
    ILendingPoolAddressesProviderAIP provider = ILendingPoolAddressesProviderAIP(
      ARC_POOL_ADDRESSES_PROVIDER_ADDRESS
    );
    provider.setEmergencyAdmin(ARC_TIMELOCK_VETO_DAO_ADDRESS);
    provider.transferOwnership(ARC_MARKET_MULTISIG_ADDRESS);
  }
}