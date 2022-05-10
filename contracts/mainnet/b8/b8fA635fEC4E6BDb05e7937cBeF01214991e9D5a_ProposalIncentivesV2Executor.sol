// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

interface IProposalIncentivesV2Executor {
  function execute() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import {ILendingPoolAddressesProvider} from '../interfaces/ILendingPoolAddressesProvider.sol';
import {IProposalIncentivesV2Executor} from '../interfaces/IProposalIncentivesV2Executor.sol';

contract ProposalIncentivesV2Executor is IProposalIncentivesV2Executor {
  bytes32 constant INCENTIVES_CONTROLLER_ID = bytes32(keccak256(bytes('INCENTIVES_CONTROLLER')));
  address constant INCENTIVES_CONTROLLER_IMPL_ADDRESS = 0xD9ED413bCF58c266F95fE6BA63B13cf79299CE31;
  address constant LENDING_POOL_ADDRESS_PROVIDER = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5;

  function execute() external override {
    ILendingPoolAddressesProvider(LENDING_POOL_ADDRESS_PROVIDER).setAddressAsProxy(
      INCENTIVES_CONTROLLER_ID,
      INCENTIVES_CONTROLLER_IMPL_ADDRESS
    );
  }
}