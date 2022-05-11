// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {LendPoolAddressesProvider} from "../protocol/LendPoolAddressesProvider.sol";
import {LendPoolConfigurator} from "../protocol/LendPoolConfigurator.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BTokensAndBNFTsHelper is Ownable {
  LendPoolAddressesProvider public addressesProvider;

  struct ConfigureReserveInput {
    address asset;
    uint256 reserveFactor;
    bool borrowingEnabled;
  }

  struct ConfigureNftInput {
    address asset;
    uint256 baseLTV;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 redeemDuration;
    uint256 auctionDuration;
    uint256 redeemFine;
    uint256 redeemThreshold;
  }

  constructor(address _addressesProvider) {
    addressesProvider = LendPoolAddressesProvider(_addressesProvider);
  }

  function configureReserves(ConfigureReserveInput[] calldata inputParams) external onlyOwner {
    LendPoolConfigurator configurator = LendPoolConfigurator(addressesProvider.getLendPoolConfigurator());
    for (uint256 i = 0; i < inputParams.length; i++) {
      if (inputParams[i].borrowingEnabled) {
        configurator.enableBorrowingOnReserve(inputParams[i].asset);
      }
      configurator.setReserveFactor(inputParams[i].asset, inputParams[i].reserveFactor);
    }
  }

  function configureNfts(ConfigureNftInput[] calldata inputParams) external onlyOwner {
    LendPoolConfigurator configurator = LendPoolConfigurator(addressesProvider.getLendPoolConfigurator());
    for (uint256 i = 0; i < inputParams.length; i++) {
      configurator.configureNftAsCollateral(
        inputParams[i].asset,
        inputParams[i].baseLTV,
        inputParams[i].liquidationThreshold,
        inputParams[i].liquidationBonus
      );
      configurator.configureNftAsAuction(
        inputParams[i].asset,
        inputParams[i].redeemDuration,
        inputParams[i].auctionDuration,
        inputParams[i].redeemFine
      );
      configurator.setNftRedeemThreshold(inputParams[i].asset, inputParams[i].redeemThreshold);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

// Prettier ignore to prevent buidler flatter bug
// prettier-ignore
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {BendUpgradeableProxy} from "../libraries/proxy/BendUpgradeableProxy.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title LendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Bend Governance
 * @author Bend
 **/
contract LendPoolAddressesProvider is Ownable, ILendPoolAddressesProvider {
  string private _marketId;
  mapping(bytes32 => address) private _addresses;

  bytes32 private constant LEND_POOL = "LEND_POOL";
  bytes32 private constant LEND_POOL_CONFIGURATOR = "LEND_POOL_CONFIGURATOR";
  bytes32 private constant POOL_ADMIN = "POOL_ADMIN";
  bytes32 private constant EMERGENCY_ADMIN = "EMERGENCY_ADMIN";
  bytes32 private constant RESERVE_ORACLE = "RESERVE_ORACLE";
  bytes32 private constant NFT_ORACLE = "NFT_ORACLE";
  bytes32 private constant BEND_ORACLE = "BEND_ORACLE";
  bytes32 private constant LEND_POOL_LOAN = "LEND_POOL_LOAN";
  bytes32 private constant BNFT_REGISTRY = "BNFT_REGISTRY";
  bytes32 private constant LEND_POOL_LIQUIDATOR = "LEND_POOL_LIQUIDATOR";
  bytes32 private constant INCENTIVES_CONTROLLER = "INCENTIVES_CONTROLLER";
  bytes32 private constant BEND_DATA_PROVIDER = "BEND_DATA_PROVIDER";
  bytes32 private constant UI_DATA_PROVIDER = "UI_DATA_PROVIDER";
  bytes32 private constant WALLET_BALANCE_PROVIDER = "WALLET_BALANCE_PROVIDER";

  constructor(string memory marketId) {
    _setMarketId(marketId);
  }

  /**
   * @dev Returns the id of the Bend market to which this contracts points to
   * @return The market id
   **/
  function getMarketId() external view override returns (string memory) {
    return _marketId;
  }

  /**
   * @dev Allows to set the market which this LendPoolAddressesProvider represents
   * @param marketId The market id
   */
  function setMarketId(string memory marketId) external override onlyOwner {
    _setMarketId(marketId);
  }

  /**
   * @dev General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `implementationAddress`
   * IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param implementationAddress The address of the new implementation
   */
  function setAddressAsProxy(
    bytes32 id,
    address implementationAddress,
    bytes memory encodedCallData
  ) external override onlyOwner {
    _updateImpl(id, implementationAddress);
    emit AddressSet(id, implementationAddress, true, encodedCallData);

    if (encodedCallData.length > 0) {
      Address.functionCall(_addresses[id], encodedCallData);
    }
  }

  /**
   * @dev Sets an address for an id replacing the address saved in the addresses map
   * IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external override onlyOwner {
    _addresses[id] = newAddress;
    emit AddressSet(id, newAddress, false, new bytes(0));
  }

  /**
   * @dev Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) public view override returns (address) {
    return _addresses[id];
  }

  /**
   * @dev Returns the address of the LendPool proxy
   * @return The LendPool proxy address
   **/
  function getLendPool() external view override returns (address) {
    return getAddress(LEND_POOL);
  }

  /**
   * @dev Updates the implementation of the LendPool, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * @param pool The new LendPool implementation
   **/
  function setLendPoolImpl(address pool, bytes memory encodedCallData) external override onlyOwner {
    _updateImpl(LEND_POOL, pool);
    emit LendPoolUpdated(pool, encodedCallData);

    if (encodedCallData.length > 0) {
      Address.functionCall(_addresses[LEND_POOL], encodedCallData);
    }
  }

  /**
   * @dev Returns the address of the LendPoolConfigurator proxy
   * @return The LendPoolConfigurator proxy address
   **/
  function getLendPoolConfigurator() external view override returns (address) {
    return getAddress(LEND_POOL_CONFIGURATOR);
  }

  /**
   * @dev Updates the implementation of the LendPoolConfigurator, or creates the proxy
   * setting the new `configurator` implementation on the first time calling it
   * @param configurator The new LendPoolConfigurator implementation
   **/
  function setLendPoolConfiguratorImpl(address configurator, bytes memory encodedCallData) external override onlyOwner {
    _updateImpl(LEND_POOL_CONFIGURATOR, configurator);
    emit LendPoolConfiguratorUpdated(configurator, encodedCallData);

    if (encodedCallData.length > 0) {
      Address.functionCall(_addresses[LEND_POOL_CONFIGURATOR], encodedCallData);
    }
  }

  /**
   * @dev The functions below are getters/setters of addresses that are outside the context
   * of the protocol hence the upgradable proxy pattern is not used
   **/

  function getPoolAdmin() external view override returns (address) {
    return getAddress(POOL_ADMIN);
  }

  function setPoolAdmin(address admin) external override onlyOwner {
    _addresses[POOL_ADMIN] = admin;
    emit ConfigurationAdminUpdated(admin);
  }

  function getEmergencyAdmin() external view override returns (address) {
    return getAddress(EMERGENCY_ADMIN);
  }

  function setEmergencyAdmin(address emergencyAdmin) external override onlyOwner {
    _addresses[EMERGENCY_ADMIN] = emergencyAdmin;
    emit EmergencyAdminUpdated(emergencyAdmin);
  }

  function getReserveOracle() external view override returns (address) {
    return getAddress(RESERVE_ORACLE);
  }

  function setReserveOracle(address reserveOracle) external override onlyOwner {
    _addresses[RESERVE_ORACLE] = reserveOracle;
    emit ReserveOracleUpdated(reserveOracle);
  }

  function getNFTOracle() external view override returns (address) {
    return getAddress(NFT_ORACLE);
  }

  function setNFTOracle(address nftOracle) external override onlyOwner {
    _addresses[NFT_ORACLE] = nftOracle;
    emit NftOracleUpdated(nftOracle);
  }

  function getLendPoolLoan() external view override returns (address) {
    return getAddress(LEND_POOL_LOAN);
  }

  function setLendPoolLoanImpl(address loanAddress, bytes memory encodedCallData) external override onlyOwner {
    _updateImpl(LEND_POOL_LOAN, loanAddress);
    emit LendPoolLoanUpdated(loanAddress, encodedCallData);

    if (encodedCallData.length > 0) {
      Address.functionCall(_addresses[LEND_POOL_LOAN], encodedCallData);
    }
  }

  function getBNFTRegistry() external view override returns (address) {
    return getAddress(BNFT_REGISTRY);
  }

  function setBNFTRegistry(address factory) external override onlyOwner {
    _addresses[BNFT_REGISTRY] = factory;
    emit BNFTRegistryUpdated(factory);
  }

  function getLendPoolLiquidator() external view override returns (address) {
    return getAddress(LEND_POOL_LIQUIDATOR);
  }

  function setLendPoolLiquidator(address liquidator) external override onlyOwner {
    _addresses[LEND_POOL_LIQUIDATOR] = liquidator;
    emit LendPoolLiquidatorUpdated(liquidator);
  }

  function getIncentivesController() external view override returns (address) {
    return getAddress(INCENTIVES_CONTROLLER);
  }

  function setIncentivesController(address controller) external override onlyOwner {
    _addresses[INCENTIVES_CONTROLLER] = controller;
    emit IncentivesControllerUpdated(controller);
  }

  function getUIDataProvider() external view override returns (address) {
    return getAddress(UI_DATA_PROVIDER);
  }

  function setUIDataProvider(address provider) external override onlyOwner {
    _addresses[UI_DATA_PROVIDER] = provider;
    emit UIDataProviderUpdated(provider);
  }

  function getBendDataProvider() external view override returns (address) {
    return getAddress(BEND_DATA_PROVIDER);
  }

  function setBendDataProvider(address provider) external override onlyOwner {
    _addresses[BEND_DATA_PROVIDER] = provider;
    emit BendDataProviderUpdated(provider);
  }

  function getWalletBalanceProvider() external view override returns (address) {
    return getAddress(WALLET_BALANCE_PROVIDER);
  }

  function setWalletBalanceProvider(address provider) external override onlyOwner {
    _addresses[WALLET_BALANCE_PROVIDER] = provider;
    emit WalletBalanceProviderUpdated(provider);
  }

  function getImplementation(address proxyAddress) external view onlyOwner returns (address) {
    BendUpgradeableProxy proxy = BendUpgradeableProxy(payable(proxyAddress));
    return proxy.getImplementation();
  }

  /**
   * @dev Internal function to update the implementation of a specific proxied component of the protocol
   * - If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
   *   as implementation and calls the initialize() function on the proxy
   * - If there is already a proxy registered, it just updates the implementation to `newAddress` and
   *   calls the encoded method function via upgradeToAndCall() in the proxy
   * @param id The id of the proxy to be updated
   * @param newAddress The address of the new implementation
   **/
  function _updateImpl(bytes32 id, address newAddress) internal {
    address payable proxyAddress = payable(_addresses[id]);

    if (proxyAddress == address(0)) {
      bytes memory params = abi.encodeWithSignature("initialize(address)", address(this));

      // create proxy, then init proxy & implementation
      BendUpgradeableProxy proxy = new BendUpgradeableProxy(newAddress, address(this), params);

      _addresses[id] = address(proxy);
      emit ProxyCreated(id, address(proxy));
    } else {
      // upgrade implementation
      BendUpgradeableProxy proxy = BendUpgradeableProxy(proxyAddress);

      proxy.upgradeTo(newAddress);
    }
  }

  function _setMarketId(string memory marketId) internal {
    _marketId = marketId;
    emit MarketIdSet(marketId);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolLoan} from "../interfaces/ILendPoolLoan.sol";
import {IBToken} from "../interfaces/IBToken.sol";
import {IDebtToken} from "../interfaces/IDebtToken.sol";
import {IBNFT} from "../interfaces/IBNFT.sol";
import {IBNFTRegistry} from "../interfaces/IBNFTRegistry.sol";
import {IIncentivesController} from "../interfaces/IIncentivesController.sol";
import {ILendPoolConfigurator} from "../interfaces/ILendPoolConfigurator.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {BendUpgradeableProxy} from "../libraries/proxy/BendUpgradeableProxy.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../libraries/configuration/NftConfiguration.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title LendPoolConfigurator contract
 * @author Bend
 * @dev Implements the configuration methods for the Bend protocol
 **/

contract LendPoolConfigurator is Initializable, ILendPoolConfigurator {
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  ILendPoolAddressesProvider internal _addressesProvider;

  modifier onlyPoolAdmin() {
    require(_addressesProvider.getPoolAdmin() == msg.sender, Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  modifier onlyEmergencyAdmin() {
    require(_addressesProvider.getEmergencyAdmin() == msg.sender, Errors.LPC_CALLER_NOT_EMERGENCY_ADMIN);
    _;
  }

  function initialize(ILendPoolAddressesProvider provider) public initializer {
    _addressesProvider = provider;
  }

  /**
   * @dev Initializes reserves in batch
   **/
  function batchInitReserve(InitReserveInput[] calldata input) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < input.length; i++) {
      _initReserve(cachedPool, input[i]);
    }
  }

  function _initReserve(ILendPool pool_, InitReserveInput calldata input) internal {
    address bTokenProxyAddress = _initTokenWithProxy(
      input.bTokenImpl,
      abi.encodeWithSelector(
        IBToken.initialize.selector,
        _addressesProvider,
        input.treasury,
        input.underlyingAsset,
        input.underlyingAssetDecimals,
        input.bTokenName,
        input.bTokenSymbol
      )
    );

    address debtTokenProxyAddress = _initTokenWithProxy(
      input.debtTokenImpl,
      abi.encodeWithSelector(
        IDebtToken.initialize.selector,
        _addressesProvider,
        input.underlyingAsset,
        input.underlyingAssetDecimals,
        input.debtTokenName,
        input.debtTokenSymbol
      )
    );

    pool_.initReserve(input.underlyingAsset, bTokenProxyAddress, debtTokenProxyAddress, input.interestRateAddress);

    DataTypes.ReserveConfigurationMap memory currentConfig = pool_.getReserveConfiguration(input.underlyingAsset);

    currentConfig.setDecimals(input.underlyingAssetDecimals);

    currentConfig.setActive(true);
    currentConfig.setFrozen(false);

    pool_.setReserveConfiguration(input.underlyingAsset, currentConfig.data);

    emit ReserveInitialized(
      input.underlyingAsset,
      bTokenProxyAddress,
      debtTokenProxyAddress,
      input.interestRateAddress
    );
  }

  function batchInitNft(InitNftInput[] calldata input) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    IBNFTRegistry cachedRegistry = _getBNFTRegistry();

    for (uint256 i = 0; i < input.length; i++) {
      _initNft(cachedPool, cachedRegistry, input[i]);
    }
  }

  function _initNft(
    ILendPool pool_,
    IBNFTRegistry registry_,
    InitNftInput calldata input
  ) internal {
    // BNFT proxy and implementation are created in BNFTRegistry
    (address bNftProxy, ) = registry_.getBNFTAddresses(input.underlyingAsset);
    require(bNftProxy != address(0), Errors.LPC_INVALIED_BNFT_ADDRESS);

    pool_.initNft(input.underlyingAsset, bNftProxy);

    DataTypes.NftConfigurationMap memory currentConfig = pool_.getNftConfiguration(input.underlyingAsset);

    currentConfig.setActive(true);
    currentConfig.setFrozen(false);

    pool_.setNftConfiguration(input.underlyingAsset, currentConfig.data);

    emit NftInitialized(input.underlyingAsset, bNftProxy);
  }

  /**
   * @dev Updates the bToken implementation for the reserve
   **/
  function updateBToken(UpdateBTokenInput calldata input) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();

    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    _upgradeTokenImplementation(reserveData.bTokenAddress, input.implementation, input.encodedCallData);

    emit BTokenUpgraded(input.asset, reserveData.bTokenAddress, input.implementation);
  }

  /**
   * @dev Updates the debt token implementation for the asset
   **/
  function updateDebtToken(UpdateDebtTokenInput calldata input) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();

    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    _upgradeTokenImplementation(reserveData.debtTokenAddress, input.implementation, input.encodedCallData);

    emit DebtTokenUpgraded(input.asset, reserveData.debtTokenAddress, input.implementation);
  }

  /**
   * @dev Enables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function enableBorrowingOnReserve(address asset) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(asset);

    currentConfig.setBorrowingEnabled(true);

    cachedPool.setReserveConfiguration(asset, currentConfig.data);

    emit BorrowingEnabledOnReserve(asset);
  }

  /**
   * @dev Disables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function disableBorrowingOnReserve(address asset) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(asset);

    currentConfig.setBorrowingEnabled(false);

    cachedPool.setReserveConfiguration(asset, currentConfig.data);
    emit BorrowingDisabledOnReserve(asset);
  }

  /**
   * @dev Activates a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function activateReserve(address asset) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(asset);

    currentConfig.setActive(true);

    cachedPool.setReserveConfiguration(asset, currentConfig.data);

    emit ReserveActivated(asset);
  }

  /**
   * @dev Deactivates a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function deactivateReserve(address asset) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    _checkReserveNoLiquidity(asset);

    DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(asset);

    currentConfig.setActive(false);

    cachedPool.setReserveConfiguration(asset, currentConfig.data);

    emit ReserveDeactivated(asset);
  }

  /**
   * @dev Freezes a reserve. A frozen reserve doesn't allow any new deposit, borrow or rate swap
   *  but allows repayments, liquidations, rate rebalances and withdrawals
   * @param asset The address of the underlying asset of the reserve
   **/
  function freezeReserve(address asset) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(asset);

    currentConfig.setFrozen(true);

    cachedPool.setReserveConfiguration(asset, currentConfig.data);

    emit ReserveFrozen(asset);
  }

  /**
   * @dev Unfreezes a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function unfreezeReserve(address asset) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(asset);

    currentConfig.setFrozen(false);

    cachedPool.setReserveConfiguration(asset, currentConfig.data);

    emit ReserveUnfrozen(asset);
  }

  /**
   * @dev Updates the reserve factor of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param reserveFactor The new reserve factor of the reserve
   **/
  function setReserveFactor(address asset, uint256 reserveFactor) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(asset);

    currentConfig.setReserveFactor(reserveFactor);

    cachedPool.setReserveConfiguration(asset, currentConfig.data);

    emit ReserveFactorChanged(asset, reserveFactor);
  }

  /**
   * @dev Sets the interest rate strategy of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param rateAddress The new address of the interest strategy contract
   **/
  function setReserveInterestRateAddress(address asset, address rateAddress) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    cachedPool.setReserveInterestRateAddress(asset, rateAddress);
    emit ReserveInterestRateChanged(asset, rateAddress);
  }

  /**
   * @dev Configures the NFT collateralization parameters
   * all the values are expressed in percentages with two decimals of precision. A valid value is 10000, which means 100.00%
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as NFT
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset. The values is always below 100%. A value of 5%
   * means the liquidator will receive a 5% bonus
   **/
  function configureNftAsCollateral(
    address asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(asset);

    //validation of the parameters: the LTV can
    //only be lower or equal than the liquidation threshold
    //(otherwise a loan against the asset would cause instantaneous liquidation)
    require(ltv <= liquidationThreshold, Errors.LPC_INVALID_CONFIGURATION);

    if (liquidationThreshold != 0) {
      //liquidation bonus must be smaller than 100.00%
      require(liquidationBonus < PercentageMath.PERCENTAGE_FACTOR, Errors.LPC_INVALID_CONFIGURATION);
    } else {
      require(liquidationBonus == 0, Errors.LPC_INVALID_CONFIGURATION);
    }

    currentConfig.setLtv(ltv);
    currentConfig.setLiquidationThreshold(liquidationThreshold);
    currentConfig.setLiquidationBonus(liquidationBonus);

    cachedPool.setNftConfiguration(asset, currentConfig.data);

    emit NftConfigurationChanged(asset, ltv, liquidationThreshold, liquidationBonus);
  }

  /**
   * @dev Activates a NFT
   * @param asset The address of the underlying asset of the NFT
   **/
  function activateNft(address asset) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(asset);

    currentConfig.setActive(true);

    cachedPool.setNftConfiguration(asset, currentConfig.data);

    emit NftActivated(asset);
  }

  /**
   * @dev Deactivates a NFT
   * @param asset The address of the underlying asset of the NFT
   **/
  function deactivateNft(address asset) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    _checkNftNoLiquidity(asset);

    DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(asset);

    currentConfig.setActive(false);

    cachedPool.setNftConfiguration(asset, currentConfig.data);

    emit NftDeactivated(asset);
  }

  /**
   * @dev Freezes a NFT. A frozen NFT doesn't allow any new borrow
   *  but allows repayments, liquidations
   * @param asset The address of the underlying asset of the NFT
   **/
  function freezeNft(address asset) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(asset);

    currentConfig.setFrozen(true);

    cachedPool.setNftConfiguration(asset, currentConfig.data);

    emit NftFrozen(asset);
  }

  /**
   * @dev Unfreezes a NFT
   * @param asset The address of the underlying asset of the NFT
   **/
  function unfreezeNft(address asset) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(asset);

    currentConfig.setFrozen(false);

    cachedPool.setNftConfiguration(asset, currentConfig.data);

    emit NftUnfrozen(asset);
  }

  /**
   * @dev Configures the NFT auction parameters
   * @param asset The address of the underlying asset of the reserve
   * @param redeemDuration The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param auctionDuration The bonus liquidators receive to liquidate this asset.
   **/
  function configureNftAsAuction(
    address asset,
    uint256 redeemDuration,
    uint256 auctionDuration,
    uint256 redeemFine
  ) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(asset);

    //validation of the parameters: the redeem duration can
    //only be lower or equal than the auction duration
    require(redeemDuration <= auctionDuration, Errors.LPC_INVALID_CONFIGURATION);

    currentConfig.setRedeemDuration(redeemDuration);
    currentConfig.setAuctionDuration(auctionDuration);
    currentConfig.setRedeemFine(redeemFine);

    cachedPool.setNftConfiguration(asset, currentConfig.data);

    emit NftAuctionChanged(asset, redeemDuration, auctionDuration, redeemFine);
  }

  function setNftRedeemThreshold(address asset, uint256 redeemThreshold) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(asset);

    currentConfig.setRedeemThreshold(redeemThreshold);

    cachedPool.setNftConfiguration(asset, currentConfig.data);

    emit NftRedeemThresholdChanged(asset, redeemThreshold);
  }

  function setMaxNumberOfReserves(uint256 newVal) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    //default value is 32
    uint256 curVal = cachedPool.getMaxNumberOfReserves();
    require(newVal > curVal, Errors.LPC_INVALID_CONFIGURATION);
    cachedPool.setMaxNumberOfReserves(newVal);
  }

  function setMaxNumberOfNfts(uint256 newVal) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    //default value is 256
    uint256 curVal = cachedPool.getMaxNumberOfNfts();
    require(newVal > curVal, Errors.LPC_INVALID_CONFIGURATION);
    cachedPool.setMaxNumberOfNfts(newVal);
  }

  /**
   * @dev pauses or unpauses all the actions of the protocol, including bToken transfers
   * @param val true if protocol needs to be paused, false otherwise
   **/
  function setPoolPause(bool val) external onlyEmergencyAdmin {
    ILendPool cachedPool = _getLendPool();
    cachedPool.setPause(val);
  }

  function getTokenImplementation(address proxyAddress) external view onlyPoolAdmin returns (address) {
    BendUpgradeableProxy proxy = BendUpgradeableProxy(payable(proxyAddress));
    return proxy.getImplementation();
  }

  function _initTokenWithProxy(address implementation, bytes memory initParams) internal returns (address) {
    BendUpgradeableProxy proxy = new BendUpgradeableProxy(implementation, address(this), initParams);

    return address(proxy);
  }

  function _upgradeTokenImplementation(
    address proxyAddress,
    address implementation,
    bytes memory encodedCallData
  ) internal {
    BendUpgradeableProxy proxy = BendUpgradeableProxy(payable(proxyAddress));

    if (encodedCallData.length > 0) {
      proxy.upgradeToAndCall(implementation, encodedCallData);
    } else {
      proxy.upgradeTo(implementation);
    }
  }

  function _checkReserveNoLiquidity(address asset) internal view {
    DataTypes.ReserveData memory reserveData = _getLendPool().getReserveData(asset);

    uint256 availableLiquidity = IERC20Upgradeable(asset).balanceOf(reserveData.bTokenAddress);

    require(availableLiquidity == 0 && reserveData.currentLiquidityRate == 0, Errors.LPC_RESERVE_LIQUIDITY_NOT_0);
  }

  function _checkNftNoLiquidity(address asset) internal view {
    uint256 collateralAmount = _getLendPoolLoan().getNftCollateralAmount(asset);

    require(collateralAmount == 0, Errors.LPC_NFT_LIQUIDITY_NOT_0);
  }

  function _getLendPool() internal view returns (ILendPool) {
    return ILendPool(_addressesProvider.getLendPool());
  }

  function _getLendPoolLoan() internal view returns (ILendPoolLoan) {
    return ILendPoolLoan(_addressesProvider.getLendPoolLoan());
  }

  function _getIncentivesController() internal view returns (IIncentivesController) {
    return IIncentivesController(_addressesProvider.getIncentivesController());
  }

  function _getBNFTRegistry() internal view returns (IBNFTRegistry) {
    return IBNFTRegistry(_addressesProvider.getBNFTRegistry());
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title LendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Bend Governance
 * @author Bend
 **/
interface ILendPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendPoolUpdated(address indexed newAddress, bytes encodedCallData);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendPoolConfiguratorUpdated(address indexed newAddress, bytes encodedCallData);
  event ReserveOracleUpdated(address indexed newAddress);
  event NftOracleUpdated(address indexed newAddress);
  event LendPoolLoanUpdated(address indexed newAddress, bytes encodedCallData);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy, bytes encodedCallData);
  event BNFTRegistryUpdated(address indexed newAddress);
  event LendPoolLiquidatorUpdated(address indexed newAddress);
  event IncentivesControllerUpdated(address indexed newAddress);
  event UIDataProviderUpdated(address indexed newAddress);
  event BendDataProviderUpdated(address indexed newAddress);
  event WalletBalanceProviderUpdated(address indexed newAddress);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(
    bytes32 id,
    address impl,
    bytes memory encodedCallData
  ) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendPool() external view returns (address);

  function setLendPoolImpl(address pool, bytes memory encodedCallData) external;

  function getLendPoolConfigurator() external view returns (address);

  function setLendPoolConfiguratorImpl(address configurator, bytes memory encodedCallData) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getReserveOracle() external view returns (address);

  function setReserveOracle(address reserveOracle) external;

  function getNFTOracle() external view returns (address);

  function setNFTOracle(address nftOracle) external;

  function getLendPoolLoan() external view returns (address);

  function setLendPoolLoanImpl(address loan, bytes memory encodedCallData) external;

  function getBNFTRegistry() external view returns (address);

  function setBNFTRegistry(address factory) external;

  function getLendPoolLiquidator() external view returns (address);

  function setLendPoolLiquidator(address liquidator) external;

  function getIncentivesController() external view returns (address);

  function setIncentivesController(address controller) external;

  function getUIDataProvider() external view returns (address);

  function setUIDataProvider(address provider) external;

  function getBendDataProvider() external view returns (address);

  function setBendDataProvider(address provider) external;

  function getWalletBalanceProvider() external view returns (address);

  function setWalletBalanceProvider(address provider) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../helpers/Errors.sol";

contract BendUpgradeableProxy is TransparentUpgradeableProxy {
  constructor(
    address _logic,
    address admin_,
    bytes memory _data
  ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}

  modifier OnlyAdmin() {
    require(msg.sender == _getAdmin(), Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  function getImplementation() external view OnlyAdmin returns (address) {
    return _getImplementation();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title Errors library
 * @author Bend
 * @notice Defines the error messages emitted by the different contracts of the Bend protocol
 */
library Errors {
  enum ReturnCode {
    SUCCESS,
    FAILED
  }

  string public constant SUCCESS = "0";

  //common errors
  string public constant CALLER_NOT_POOL_ADMIN = "100"; // 'The caller must be the pool admin'
  string public constant CALLER_NOT_ADDRESS_PROVIDER = "101";
  string public constant INVALID_FROM_BALANCE_AFTER_TRANSFER = "102";
  string public constant INVALID_TO_BALANCE_AFTER_TRANSFER = "103";
  string public constant CALLER_NOT_ONBEHALFOF_OR_IN_WHITELIST = "104";

  //math library erros
  string public constant MATH_MULTIPLICATION_OVERFLOW = "200";
  string public constant MATH_ADDITION_OVERFLOW = "201";
  string public constant MATH_DIVISION_BY_ZERO = "202";

  //validation & check errors
  string public constant VL_INVALID_AMOUNT = "301"; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = "302"; // 'Action requires an active reserve'
  string public constant VL_RESERVE_FROZEN = "303"; // 'Action cannot be performed because the reserve is frozen'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "304"; // 'User cannot withdraw more than the available balance'
  string public constant VL_BORROWING_NOT_ENABLED = "305"; // 'Borrowing is not enabled'
  string public constant VL_COLLATERAL_BALANCE_IS_0 = "306"; // 'The collateral balance is 0'
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "307"; // 'Health factor is lesser than the liquidation threshold'
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "308"; // 'There is not enough collateral to cover a new borrow'
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "309"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string public constant VL_NO_ACTIVE_NFT = "310";
  string public constant VL_NFT_FROZEN = "311";
  string public constant VL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "312"; // 'User did not borrow the specified currency'
  string public constant VL_INVALID_HEALTH_FACTOR = "313";
  string public constant VL_INVALID_ONBEHALFOF_ADDRESS = "314";
  string public constant VL_INVALID_TARGET_ADDRESS = "315";
  string public constant VL_INVALID_RESERVE_ADDRESS = "316";
  string public constant VL_SPECIFIED_LOAN_NOT_BORROWED_BY_USER = "317";
  string public constant VL_SPECIFIED_RESERVE_NOT_BORROWED_BY_USER = "318";
  string public constant VL_HEALTH_FACTOR_HIGHER_THAN_LIQUIDATION_THRESHOLD = "319";

  //lend pool errors
  string public constant LP_CALLER_NOT_LEND_POOL_CONFIGURATOR = "400"; // 'The caller of the function is not the lending pool configurator'
  string public constant LP_IS_PAUSED = "401"; // 'Pool is paused'
  string public constant LP_NO_MORE_RESERVES_ALLOWED = "402";
  string public constant LP_NOT_CONTRACT = "403";
  string public constant LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD = "404";
  string public constant LP_BORROW_IS_EXCEED_LIQUIDATION_PRICE = "405";
  string public constant LP_NO_MORE_NFTS_ALLOWED = "406";
  string public constant LP_INVALIED_USER_NFT_AMOUNT = "407";
  string public constant LP_INCONSISTENT_PARAMS = "408";
  string public constant LP_NFT_IS_NOT_USED_AS_COLLATERAL = "409";
  string public constant LP_CALLER_MUST_BE_AN_BTOKEN = "410";
  string public constant LP_INVALIED_NFT_AMOUNT = "411";
  string public constant LP_NFT_HAS_USED_AS_COLLATERAL = "412";
  string public constant LP_DELEGATE_CALL_FAILED = "413";
  string public constant LP_AMOUNT_LESS_THAN_EXTRA_DEBT = "414";
  string public constant LP_AMOUNT_LESS_THAN_REDEEM_THRESHOLD = "415";
  string public constant LP_AMOUNT_GREATER_THAN_MAX_REPAY = "416";

  //lend pool loan errors
  string public constant LPL_INVALID_LOAN_STATE = "480";
  string public constant LPL_INVALID_LOAN_AMOUNT = "481";
  string public constant LPL_INVALID_TAKEN_AMOUNT = "482";
  string public constant LPL_AMOUNT_OVERFLOW = "483";
  string public constant LPL_BID_PRICE_LESS_THAN_LIQUIDATION_PRICE = "484";
  string public constant LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE = "485";
  string public constant LPL_BID_REDEEM_DURATION_HAS_END = "486";
  string public constant LPL_BID_USER_NOT_SAME = "487";
  string public constant LPL_BID_REPAY_AMOUNT_NOT_ENOUGH = "488";
  string public constant LPL_BID_AUCTION_DURATION_HAS_END = "489";
  string public constant LPL_BID_AUCTION_DURATION_NOT_END = "490";
  string public constant LPL_BID_PRICE_LESS_THAN_BORROW = "491";
  string public constant LPL_INVALID_BIDDER_ADDRESS = "492";
  string public constant LPL_AMOUNT_LESS_THAN_BID_FINE = "493";
  string public constant LPL_BID_INVALID_BID_FINE = "494";

  //common token errors
  string public constant CT_CALLER_MUST_BE_LEND_POOL = "500"; // 'The caller of this function must be a lending pool'
  string public constant CT_INVALID_MINT_AMOUNT = "501"; //invalid amount to mint
  string public constant CT_INVALID_BURN_AMOUNT = "502"; //invalid amount to burn
  string public constant CT_BORROW_ALLOWANCE_NOT_ENOUGH = "503";

  //reserve logic errors
  string public constant RL_RESERVE_ALREADY_INITIALIZED = "601"; // 'Reserve has already been initialized'
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "602"; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "603"; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = "604"; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "605"; //  Variable borrow rate overflows uint128

  //configure errors
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "700"; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_CONFIGURATION = "701"; // 'Invalid risk parameters for the reserve'
  string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "702"; // 'The caller must be the emergency admin'
  string public constant LPC_INVALIED_BNFT_ADDRESS = "703";
  string public constant LPC_INVALIED_LOAN_ADDRESS = "704";
  string public constant LPC_NFT_LIQUIDITY_NOT_0 = "705";

  //reserve config errors
  string public constant RC_INVALID_LTV = "730";
  string public constant RC_INVALID_LIQ_THRESHOLD = "731";
  string public constant RC_INVALID_LIQ_BONUS = "732";
  string public constant RC_INVALID_DECIMALS = "733";
  string public constant RC_INVALID_RESERVE_FACTOR = "734";
  string public constant RC_INVALID_REDEEM_DURATION = "735";
  string public constant RC_INVALID_AUCTION_DURATION = "736";
  string public constant RC_INVALID_REDEEM_FINE = "737";
  string public constant RC_INVALID_REDEEM_THRESHOLD = "738";

  //address provider erros
  string public constant LPAPR_PROVIDER_NOT_REGISTERED = "760"; // 'Provider is not registered'
  string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "761";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface ILendPoolLoan {
  /**
   * @dev Emitted on initialization to share location of dependent notes
   * @param pool The address of the associated lend pool
   */
  event Initialized(address indexed pool);

  /**
   * @dev Emitted when a loan is created
   * @param user The address initiating the action
   */
  event LoanCreated(
    address indexed user,
    address indexed onBehalfOf,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is updated
   * @param user The address initiating the action
   */
  event LoanUpdated(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is repaid by the borrower
   * @param user The address initiating the action
   */
  event LoanRepaid(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is auction by the liquidator
   * @param user The address initiating the action
   */
  event LoanAuctioned(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 borrowIndex,
    address bidder,
    uint256 price,
    address previousBidder,
    uint256 previousPrice
  );

  /**
   * @dev Emitted when a loan is redeemed
   * @param user The address initiating the action
   */
  event LoanRedeemed(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amountTaken,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is liquidate by the liquidator
   * @param user The address initiating the action
   */
  event LoanLiquidated(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  function initNft(address nftAsset, address bNftAddress) external;

  /**
   * @dev Create store a loan object with some params
   * @param initiator The address of the user initiating the borrow
   * @param onBehalfOf The address receiving the loan
   */
  function createLoan(
    address initiator,
    address onBehalfOf,
    address nftAsset,
    uint256 nftTokenId,
    address bNftAddress,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  ) external returns (uint256);

  /**
   * @dev Update the given loan with some params
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The loan must be in state Active
   * @param initiator The address of the user initiating the borrow
   */
  function updateLoan(
    address initiator,
    uint256 loanId,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Repay the given loan
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The caller must send in principal + interest
   *  - The loan must be in state Active
   *
   * @param initiator The address of the user initiating the repay
   * @param loanId The loan getting burned
   * @param bNftAddress The address of bNFT
   */
  function repayLoan(
    address initiator,
    uint256 loanId,
    address bNftAddress,
    uint256 amount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Auction the given loan
   *
   * Requirements:
   *  - The price must be greater than current highest price
   *  - The loan must be in state Active or Auction
   *
   * @param initiator The address of the user initiating the auction
   * @param loanId The loan getting auctioned
   * @param bidPrice The bid price of this auction
   */
  function auctionLoan(
    address initiator,
    uint256 loanId,
    address onBehalfOf,
    uint256 bidPrice,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Redeem the given loan with some params
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The loan must be in state Auction
   * @param initiator The address of the user initiating the borrow
   */
  function redeemLoan(
    address initiator,
    uint256 loanId,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Liquidate the given loan
   *
   * Requirements:
   *  - The caller must send in principal + interest
   *  - The loan must be in state Active
   *
   * @param initiator The address of the user initiating the auction
   * @param loanId The loan getting burned
   * @param bNftAddress The address of bNFT
   */
  function liquidateLoan(
    address initiator,
    uint256 loanId,
    address bNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external;

  function borrowerOf(uint256 loanId) external view returns (address);

  function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns (uint256);

  function getLoan(uint256 loanId) external view returns (DataTypes.LoanData memory loanData);

  function getLoanCollateralAndReserve(uint256 loanId)
    external
    view
    returns (
      address nftAsset,
      uint256 nftTokenId,
      address reserveAsset,
      uint256 scaledAmount
    );

  function getLoanReserveBorrowScaledAmount(uint256 loanId) external view returns (address, uint256);

  function getLoanReserveBorrowAmount(uint256 loanId) external view returns (address, uint256);

  function getLoanHighestBid(uint256 loanId) external view returns (address, uint256);

  function getNftCollateralAmount(address nftAsset) external view returns (uint256);

  function getUserNftCollateralAmount(address user, address nftAsset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "./ILendPoolAddressesProvider.sol";
import {IIncentivesController} from "./IIncentivesController.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IBToken is IScaledBalanceToken, IERC20Upgradeable, IERC20MetadataUpgradeable {
  /**
   * @dev Emitted when an bToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this bToken
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController
  );

  /**
   * @dev Initializes the bToken
   * @param addressProvider The address of the address provider where this bToken will be used
   * @param treasury The address of the Bend treasury, receiving the fees on this bToken
   * @param underlyingAsset The address of the underlying asset of this bToken
   */
  function initialize(
    ILendPoolAddressesProvider addressProvider,
    address treasury,
    address underlyingAsset,
    uint8 bTokenDecimals,
    string calldata bTokenName,
    string calldata bTokenSymbol
  ) external;

  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   * @param index The new liquidity index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints `amount` bTokens to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted after bTokens are burned
   * @param from The owner of the bTokens, getting them burned
   * @param target The address that will receive the underlying
   * @param value The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The amount being transferred
   * @param index The new liquidity index of the reserve
   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @dev Burns bTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the bTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external;

  /**
   * @dev Mints bTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param user The recipient of the underlying
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view returns (IIncentivesController);

  /**
   * @dev Returns the address of the underlying asset of this bToken
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {IIncentivesController} from "./IIncentivesController.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @title IDebtToken
 * @author Bend
 * @notice Defines the basic interface for a debt token.
 **/
interface IDebtToken is IScaledBalanceToken, IERC20Upgradeable, IERC20MetadataUpgradeable {
  /**
   * @dev Emitted when a debt token is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lend pool
   * @param incentivesController The address of the incentives controller
   * @param debtTokenDecimals the decimals of the debt token
   * @param debtTokenName the name of the debt token
   * @param debtTokenSymbol the symbol of the debt token
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address incentivesController,
    uint8 debtTokenDecimals,
    string debtTokenName,
    string debtTokenSymbol
  );

  /**
   * @dev Initializes the debt token.
   * @param addressProvider The address of the lend pool
   * @param underlyingAsset The address of the underlying asset
   * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
   * @param debtTokenName The name of the token
   * @param debtTokenSymbol The symbol of the token
   */
  function initialize(
    ILendPoolAddressesProvider addressProvider,
    address underlyingAsset,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol
  ) external;

  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount to be minted
   * @param index The last index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints debt token to the `user` address
   * @param user The address receiving the borrowed underlying
   * @param amount The amount of debt being minted
   * @param index The variable debt index of the reserve
   * @return `true` if the the previous balance of the user is 0
   **/
  function mint(
    address user,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @dev Emitted when variable debt is burnt
   * @param user The user which debt has been burned
   * @param amount The amount of debt being burned
   * @param index The index of the user
   **/
  event Burn(address indexed user, uint256 amount, uint256 index);

  /**
   * @dev Burns user variable debt
   * @param user The user which debt is burnt
   * @param index The variable debt index of the reserve
   **/
  function burn(
    address user,
    uint256 amount,
    uint256 index
  ) external;

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view returns (IIncentivesController);

  /**
   * @dev delegates borrowing power to a user on the specific debt token
   * @param delegatee the address receiving the delegated borrowing power
   * @param amount the maximum amount being delegated. Delegation will still
   * respect the liquidation constraints (even if delegated, a delegatee cannot
   * force a delegator HF to go below 1)
   **/
  function approveDelegation(address delegatee, uint256 amount) external;

  /**
   * @dev returns the borrow allowance of the user
   * @param fromUser The user to giving allowance
   * @param toUser The user to give allowance to
   * @return the current allowance of toUser
   **/
  function borrowAllowance(address fromUser, address toUser) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

interface IBNFT is IERC721MetadataUpgradeable, IERC721ReceiverUpgradeable, IERC721EnumerableUpgradeable {
  /**
   * @dev Emitted when an bNFT is initialized
   * @param underlyingAsset The address of the underlying asset
   **/
  event Initialized(address indexed underlyingAsset);

  /**
   * @dev Emitted on mint
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address receive the bNFT token
   **/
  event Mint(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on burn
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address of the burned bNFT token
   **/
  event Burn(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on flashLoan
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param nftAsset address of the underlying asset of NFT
   * @param tokenId The token id of the asset being flash borrowed
   **/
  event FlashLoan(address indexed target, address indexed initiator, address indexed nftAsset, uint256 tokenId);

  /**
   * @dev Initializes the bNFT
   * @param underlyingAsset The address of the underlying asset of this bNFT (E.g. PUNK for bPUNK)
   */
  function initialize(
    address underlyingAsset,
    string calldata bNftName,
    string calldata bNftSymbol
  ) external;

  /**
   * @dev Mints bNFT token to the user address
   *
   * Requirements:
   *  - The caller must be contract address.
   *  - `nftTokenId` must not exist.
   *
   * @param to The owner address receive the bNFT token
   * @param tokenId token id of the underlying asset of NFT
   **/
  function mint(address to, uint256 tokenId) external;

  /**
   * @dev Burns user bNFT token
   *
   * Requirements:
   *  - The caller must be contract address.
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   **/
  function burn(uint256 tokenId) external;

  /**
   * @dev Allows smartcontracts to access the tokens within one transaction, as long as the tokens taken is returned.
   *
   * Requirements:
   *  - `nftTokenIds` must exist.
   *
   * @param receiverAddress The address of the contract receiving the tokens, implementing the IFlashLoanReceiver interface
   * @param nftTokenIds token ids of the underlying asset
   * @param params Variadic packed params to pass to the receiver as extra information
   */
  function flashLoan(
    address receiverAddress,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) external;

  /**
   * @dev Returns the owner of the `nftTokenId` token.
   *
   * Requirements:
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   */
  function minterOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IBNFTRegistry {
  event Initialized(address genericImpl, string namePrefix, string symbolPrefix);
  event GenericImplementationUpdated(address genericImpl);
  event BNFTCreated(address indexed nftAsset, address bNftImpl, address bNftProxy, uint256 totals);
  event BNFTUpgraded(address indexed nftAsset, address bNftImpl, address bNftProxy, uint256 totals);

  function getBNFTAddresses(address nftAsset) external view returns (address bNftProxy, address bNftImpl);

  function getBNFTAddressesByIndex(uint16 index) external view returns (address bNftProxy, address bNftImpl);

  function getBNFTAssetList() external view returns (address[] memory);

  function allBNFTAssetLength() external view returns (uint256);

  function initialize(
    address genericImpl,
    string memory namePrefix_,
    string memory symbolPrefix_
  ) external;

  function setBNFTGenericImpl(address genericImpl) external;

  /**
   * @dev Create bNFT proxy and implement, then initialize it
   * @param nftAsset The address of the underlying asset of the BNFT
   **/
  function createBNFT(address nftAsset) external returns (address bNftProxy);

  /**
   * @dev Create bNFT proxy with already deployed implement, then initialize it
   * @param nftAsset The address of the underlying asset of the BNFT
   * @param bNftImpl The address of the deployed implement of the BNFT
   **/
  function createBNFTWithImpl(address nftAsset, address bNftImpl) external returns (address bNftProxy);

  /**
   * @dev Update bNFT proxy to an new deployed implement, then initialize it
   * @param nftAsset The address of the underlying asset of the BNFT
   * @param bNftImpl The address of the deployed implement of the BNFT
   * @param encodedCallData The encoded function call.
   **/
  function upgradeBNFTWithImpl(
    address nftAsset,
    address bNftImpl,
    bytes memory encodedCallData
  ) external;

  /**
   * @dev Adding custom symbol for some special NFTs like CryptoPunks
   * @param nftAssets_ The addresses of the NFTs
   * @param symbols_ The custom symbols of the NFTs
   **/
  function addCustomeSymbols(address[] memory nftAssets_, string[] memory symbols_) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IIncentivesController {
  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param asset The address of the user
   * @param totalSupply The total supply of the asset in the lending pool
   * @param userBalance The balance of the user of the asset in the lending pool
   **/
  function handleAction(
    address asset,
    uint256 totalSupply,
    uint256 userBalance
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface ILendPoolConfigurator {
  struct InitReserveInput {
    address bTokenImpl;
    address debtTokenImpl;
    uint8 underlyingAssetDecimals;
    address interestRateAddress;
    address underlyingAsset;
    address treasury;
    string underlyingAssetName;
    string bTokenName;
    string bTokenSymbol;
    string debtTokenName;
    string debtTokenSymbol;
  }

  struct InitNftInput {
    address underlyingAsset;
  }

  struct UpdateBTokenInput {
    address asset;
    address implementation;
    bytes encodedCallData;
  }

  struct UpdateDebtTokenInput {
    address asset;
    address implementation;
    bytes encodedCallData;
  }

  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param bToken The address of the associated bToken contract
   * @param debtToken The address of the associated debtToken contract
   * @param interestRateAddress The address of the interest rate strategy for the reserve
   **/
  event ReserveInitialized(
    address indexed asset,
    address indexed bToken,
    address debtToken,
    address interestRateAddress
  );

  /**
   * @dev Emitted when borrowing is enabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event BorrowingEnabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when borrowing is disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event BorrowingDisabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when a reserve is activated
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveActivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is deactivated
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveDeactivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is frozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveFrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve is unfrozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event ReserveUnfrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve factor is updated
   * @param asset The address of the underlying asset of the reserve
   * @param factor The new reserve factor
   **/
  event ReserveFactorChanged(address indexed asset, uint256 factor);

  /**
   * @dev Emitted when the reserve decimals are updated
   * @param asset The address of the underlying asset of the reserve
   * @param decimals The new decimals
   **/
  event ReserveDecimalsChanged(address indexed asset, uint256 decimals);

  /**
   * @dev Emitted when a reserve interest strategy contract is updated
   * @param asset The address of the underlying asset of the reserve
   * @param strategy The new address of the interest strategy contract
   **/
  event ReserveInterestRateChanged(address indexed asset, address strategy);

  /**
   * @dev Emitted when a nft is initialized.
   * @param asset The address of the underlying asset of the nft
   * @param bNft The address of the associated bNFT contract
   **/
  event NftInitialized(address indexed asset, address indexed bNft);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified NFT are updated.
   * @param asset The address of the underlying asset of the NFT
   * @param ltv The loan to value of the asset when used as NFT
   * @param liquidationThreshold The threshold at which loans using this asset as NFT will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   **/
  event NftConfigurationChanged(
    address indexed asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  /**
   * @dev Emitted when a NFT is activated
   * @param asset The address of the underlying asset of the NFT
   **/
  event NftActivated(address indexed asset);

  /**
   * @dev Emitted when a NFT is deactivated
   * @param asset The address of the underlying asset of the NFT
   **/
  event NftDeactivated(address indexed asset);

  /**
   * @dev Emitted when a NFT is frozen
   * @param asset The address of the underlying asset of the NFT
   **/
  event NftFrozen(address indexed asset);

  /**
   * @dev Emitted when a NFT is unfrozen
   * @param asset The address of the underlying asset of the NFT
   **/
  event NftUnfrozen(address indexed asset);

  /**
   * @dev Emitted when a redeem duration is updated
   * @param asset The address of the underlying asset of the NFT
   * @param redeemDuration The new redeem duration
   * @param auctionDuration The new redeem duration
   * @param redeemFine The new redeem fine
   **/
  event NftAuctionChanged(address indexed asset, uint256 redeemDuration, uint256 auctionDuration, uint256 redeemFine);

  event NftRedeemThresholdChanged(address indexed asset, uint256 redeemThreshold);

  /**
   * @dev Emitted when an bToken implementation is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The bToken proxy address
   * @param implementation The new bToken implementation
   **/
  event BTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

  /**
   * @dev Emitted when the implementation of a debt token is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The debt token proxy address
   * @param implementation The new debtToken implementation
   **/
  event DebtTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "./ILendPoolAddressesProvider.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

interface ILendPool {
  /**
   * @dev Emitted on deposit()
   * @param user The address initiating the deposit
   * @param amount The amount deposited
   * @param reserve The address of the underlying asset of the reserve
   * @param onBehalfOf The beneficiary of the deposit, receiving the bTokens
   * @param referral The referral code used
   **/
  event Deposit(
    address user,
    address indexed reserve,
    uint256 amount,
    address indexed onBehalfOf,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param user The address initiating the withdrawal, owner of bTokens
   * @param reserve The address of the underlyng asset being withdrawn
   * @param amount The amount to be withdrawn
   * @param to Address that will receive the underlying
   **/
  event Withdraw(address indexed user, address indexed reserve, uint256 amount, address indexed to);

  /**
   * @dev Emitted on borrow() when loan needs to be opened
   * @param user The address of the user initiating the borrow(), receiving the funds
   * @param reserve The address of the underlying asset being borrowed
   * @param amount The amount borrowed out
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the loan
   * @param referral The referral code used
   **/
  event Borrow(
    address user,
    address indexed reserve,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address indexed onBehalfOf,
    uint256 borrowRate,
    uint256 loanId,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param user The address of the user initiating the repay(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param amount The amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param borrower The beneficiary of the repayment, getting his debt reduced
   * @param loanId The loan ID of the NFT loans
   **/
  event Repay(
    address user,
    address indexed reserve,
    uint256 amount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is auctioned.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param bidPrice The price of the underlying reserve given by the bidder
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the NFT
   * @param loanId The loan ID of the NFT loans
   **/
  event Auction(
    address user,
    address indexed reserve,
    uint256 bidPrice,
    address indexed nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted on redeem()
   * @param user The address of the user initiating the redeem(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param borrowAmount The borrow amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param loanId The loan ID of the NFT loans
   **/
  event Redeem(
    address user,
    address indexed reserve,
    uint256 borrowAmount,
    uint256 fineAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is liquidated.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param repayAmount The amount of reserve repaid by the liquidator
   * @param remainAmount The amount of reserve received by the borrower
   * @param loanId The loan ID of the NFT loans
   **/
  event Liquidate(
    address user,
    address indexed reserve,
    uint256 repayAmount,
    uint256 remainAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendPool contract. The event is therefore replicated here so it
   * gets added to the LendPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying bTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 bUSDC
   * @param reserve The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the bTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of bTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address reserve,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent bTokens owned
   * E.g. User has 100 bUSDC, calls withdraw() and receives 100 USDC, burning the 100 bUSDC
   * @param reserve The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole bToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address reserve,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral
   * - E.g. User borrows 100 USDC, receiving the 100 USDC in his wallet
   *   and lock collateral asset in contract
   * @param reserveAsset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param onBehalfOf Address of the user who will receive the loan. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function borrow(
    address reserveAsset,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function batchBorrow(
    address[] calldata assets,
    uint256[] calldata amounts,
    address[] calldata nftAssets,
    uint256[] calldata nftTokenIds,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent loan owned
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay
   * @return The final amount repaid, loan is burned or not
   **/
  function repay(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) external returns (uint256, bool);

  function batchRepay(
    address[] calldata nftAssets,
    uint256[] calldata nftTokenIds,
    uint256[] calldata amounts
  ) external returns (uint256[] memory, bool[] memory);

  /**
   * @dev Function to auction a non-healthy position collateral-wise
   * - The caller (liquidator) want to buy collateral asset of the user getting liquidated
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param bidPrice The bid price of the liquidator want to buy the underlying NFT
   * @param onBehalfOf Address of the user who will get the underlying NFT, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of NFT
   *   is a different wallet
   **/
  function auction(
    address nftAsset,
    uint256 nftTokenId,
    uint256 bidPrice,
    address onBehalfOf
  ) external;

  /**
   * @notice Redeem a NFT loan which state is in Auction
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   **/
  function redeem(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 bidFine
  ) external returns (uint256);

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The caller (liquidator) buy collateral asset of the user getting liquidated, and receives
   *   the collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidate(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) external returns (uint256);

  /**
   * @dev Validates and finalizes an bToken transfer
   * - Only callable by the overlying bToken of the `asset`
   * @param asset The address of the underlying asset of the bToken
   * @param from The user from which the bTokens are transferred
   * @param to The user receiving the bTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The bToken balance of the `from` user before the transfer
   * @param balanceToBefore The bToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external view;

  function getReserveConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

  function getNftConfiguration(address asset) external view returns (DataTypes.NftConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function getReservesList() external view returns (address[] memory);

  function getNftData(address asset) external view returns (DataTypes.NftData memory);

  /**
   * @dev Returns the loan data of the NFT
   * @param nftAsset The address of the NFT
   * @param reserveAsset The address of the Reserve
   * @return totalCollateralInETH the total collateral in ETH of the NFT
   * @return totalCollateralInReserve the total collateral in Reserve of the NFT
   * @return availableBorrowsInETH the borrowing power in ETH of the NFT
   * @return availableBorrowsInReserve the borrowing power in Reserve of the NFT
   * @return ltv the loan to value of the user
   * @return liquidationThreshold the liquidation threshold of the NFT
   * @return liquidationBonus the liquidation bonus of the NFT
   **/
  function getNftCollateralData(address nftAsset, address reserveAsset)
    external
    view
    returns (
      uint256 totalCollateralInETH,
      uint256 totalCollateralInReserve,
      uint256 availableBorrowsInETH,
      uint256 availableBorrowsInReserve,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus
    );

  /**
   * @dev Returns the debt data of the NFT
   * @param nftAsset The address of the NFT
   * @param nftTokenId The token id of the NFT
   * @return loanId the loan id of the NFT
   * @return reserveAsset the address of the Reserve
   * @return totalCollateral the total power of the NFT
   * @return totalDebt the total debt of the NFT
   * @return availableBorrows the borrowing power left of the NFT
   * @return healthFactor the current health factor of the NFT
   **/
  function getNftDebtData(address nftAsset, uint256 nftTokenId)
    external
    view
    returns (
      uint256 loanId,
      address reserveAsset,
      uint256 totalCollateral,
      uint256 totalDebt,
      uint256 availableBorrows,
      uint256 healthFactor
    );

  /**
   * @dev Returns the auction data of the NFT
   * @param nftAsset The address of the NFT
   * @param nftTokenId The token id of the NFT
   * @return loanId the loan id of the NFT
   * @return bidderAddress the highest bidder address of the loan
   * @return bidPrice the highest bid price in Reserve of the loan
   * @return bidBorrowAmount the borrow amount in Reserve of the loan
   * @return bidFine the penalty fine of the loan
   **/
  function getNftAuctionData(address nftAsset, uint256 nftTokenId)
    external
    view
    returns (
      uint256 loanId,
      address bidderAddress,
      uint256 bidPrice,
      uint256 bidBorrowAmount,
      uint256 bidFine
    );

  function getNftLiquidatePrice(address nftAsset, uint256 nftTokenId)
    external
    view
    returns (uint256 liquidatePrice, uint256 paybackAmount);

  function getNftsList() external view returns (address[] memory);

  /**
   * @dev Set the _pause state of a reserve
   * - Only callable by the LendPool contract
   * @param val `true` to pause the reserve, `false` to un-pause it
   */
  function setPause(bool val) external;

  /**
   * @dev Returns if the LendPool is paused
   */
  function paused() external view returns (bool);

  function getAddressesProvider() external view returns (ILendPoolAddressesProvider);

  function initReserve(
    address asset,
    address bTokenAddress,
    address debtTokenAddress,
    address interestRateAddress
  ) external;

  function initNft(address asset, address bNftAddress) external;

  function setReserveInterestRateAddress(address asset, address rateAddress) external;

  function setReserveConfiguration(address asset, uint256 configuration) external;

  function setNftConfiguration(address asset, uint256 configuration) external;

  function setMaxNumberOfReserves(uint256 val) external;

  function setMaxNumberOfNfts(uint256 val) external;

  function getMaxNumberOfReserves() external view returns (uint256);

  function getMaxNumberOfNfts() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title ReserveConfiguration library
 * @author Bend
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
  uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 constant DECIMALS_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
  uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant RESERVE_FACTOR_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
  uint256 constant RESERVE_FACTOR_START_BIT_POSITION = 64;

  uint256 constant MAX_VALID_LTV = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  uint256 constant MAX_VALID_DECIMALS = 255;
  uint256 constant MAX_VALID_RESERVE_FACTOR = 65535;

  /**
   * @dev Sets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @param ltv the new ltv
   **/
  function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
    require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

    self.data = (self.data & LTV_MASK) | ltv;
  }

  /**
   * @dev Gets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @return The loan to value
   **/
  function getLtv(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return self.data & ~LTV_MASK;
  }

  /**
   * @dev Sets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @param threshold The new liquidation threshold
   **/
  function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold) internal pure {
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.RC_INVALID_LIQ_THRESHOLD);

    self.data = (self.data & LIQUIDATION_THRESHOLD_MASK) | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @return The liquidation threshold
   **/
  function getLiquidationThreshold(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @dev Sets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @param bonus The new liquidation bonus
   **/
  function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus) internal pure {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.RC_INVALID_LIQ_BONUS);

    self.data = (self.data & LIQUIDATION_BONUS_MASK) | (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @return The liquidation bonus
   **/
  function getLiquidationBonus(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @dev Sets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @param decimals The decimals
   **/
  function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals) internal pure {
    require(decimals <= MAX_VALID_DECIMALS, Errors.RC_INVALID_DECIMALS);

    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
  }

  /**
   * @dev Gets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @return The decimals of the asset
   **/
  function getDecimals(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
  }

  /**
   * @dev Sets the active state of the reserve
   * @param self The reserve configuration
   * @param active The active state
   **/
  function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
    self.data = (self.data & ACTIVE_MASK) | (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the active state of the reserve
   * @param self The reserve configuration
   * @return The active state
   **/
  function getActive(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~ACTIVE_MASK) != 0;
  }

  /**
   * @dev Sets the frozen state of the reserve
   * @param self The reserve configuration
   * @param frozen The frozen state
   **/
  function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
    self.data = (self.data & FROZEN_MASK) | (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  /**
   * @dev Gets the frozen state of the reserve
   * @param self The reserve configuration
   * @return The frozen state
   **/
  function getFrozen(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  /**
   * @dev Enables or disables borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the borrowing needs to be enabled, false otherwise
   **/
  function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
    self.data = (self.data & BORROWING_MASK) | (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @dev Gets the borrowing state of the reserve
   * @param self The reserve configuration
   * @return The borrowing state
   **/
  function getBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~BORROWING_MASK) != 0;
  }

  /**
   * @dev Enables or disables stable rate borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
   **/
  function setStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
    self.data =
      (self.data & STABLE_BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @dev Gets the stable rate borrowing state of the reserve
   * @param self The reserve configuration
   * @return The stable rate borrowing state
   **/
  function getStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~STABLE_BORROWING_MASK) != 0;
  }

  /**
   * @dev Sets the reserve factor of the reserve
   * @param self The reserve configuration
   * @param reserveFactor The reserve factor
   **/
  function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor) internal pure {
    require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.RC_INVALID_RESERVE_FACTOR);

    self.data = (self.data & RESERVE_FACTOR_MASK) | (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
  }

  /**
   * @dev Gets the reserve factor of the reserve
   * @param self The reserve configuration
   * @return The reserve factor
   **/
  function getReserveFactor(DataTypes.ReserveConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

  /**
   * @dev Gets the configuration flags of the reserve
   * @param self The reserve configuration
   * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
   **/
  function getFlags(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (
      bool,
      bool,
      bool,
      bool
    )
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~ACTIVE_MASK) != 0,
      (dataLocal & ~FROZEN_MASK) != 0,
      (dataLocal & ~BORROWING_MASK) != 0,
      (dataLocal & ~STABLE_BORROWING_MASK) != 0
    );
  }

  /**
   * @dev Gets the configuration paramters of the reserve
   * @param self The reserve configuration
   * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
   **/
  function getParams(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 dataLocal = self.data;

    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
      (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the configuration paramters of the reserve from a memory object
   * @param self The reserve configuration
   * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
   **/
  function getParamsMemory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (
      self.data & ~LTV_MASK,
      (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
      (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the configuration flags of the reserve from a memory object
   * @param self The reserve configuration
   * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
   **/
  function getFlagsMemory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      bool,
      bool,
      bool,
      bool
    )
  {
    return (
      (self.data & ~ACTIVE_MASK) != 0,
      (self.data & ~FROZEN_MASK) != 0,
      (self.data & ~BORROWING_MASK) != 0,
      (self.data & ~STABLE_BORROWING_MASK) != 0
    );
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title NftConfiguration library
 * @author Bend
 * @notice Implements the bitmap logic to handle the NFT configuration
 */
library NftConfiguration {
  uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant REDEEM_DURATION_MASK =       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant AUCTION_DURATION_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant REDEEM_FINE_MASK =           0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant REDEEM_THRESHOLD_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 constant REDEEM_DURATION_START_BIT_POSITION = 64;
  uint256 constant AUCTION_DURATION_START_BIT_POSITION = 72;
  uint256 constant REDEEM_FINE_START_BIT_POSITION = 80;
  uint256 constant REDEEM_THRESHOLD_START_BIT_POSITION = 96;

  uint256 constant MAX_VALID_LTV = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  uint256 constant MAX_VALID_REDEEM_DURATION = 255;
  uint256 constant MAX_VALID_AUCTION_DURATION = 255;
  uint256 constant MAX_VALID_REDEEM_FINE = 65535;
  uint256 constant MAX_VALID_REDEEM_THRESHOLD = 65535;

  /**
   * @dev Sets the Loan to Value of the NFT
   * @param self The NFT configuration
   * @param ltv the new ltv
   **/
  function setLtv(DataTypes.NftConfigurationMap memory self, uint256 ltv) internal pure {
    require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

    self.data = (self.data & LTV_MASK) | ltv;
  }

  /**
   * @dev Gets the Loan to Value of the NFT
   * @param self The NFT configuration
   * @return The loan to value
   **/
  function getLtv(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return self.data & ~LTV_MASK;
  }

  /**
   * @dev Sets the liquidation threshold of the NFT
   * @param self The NFT configuration
   * @param threshold The new liquidation threshold
   **/
  function setLiquidationThreshold(DataTypes.NftConfigurationMap memory self, uint256 threshold) internal pure {
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.RC_INVALID_LIQ_THRESHOLD);

    self.data = (self.data & LIQUIDATION_THRESHOLD_MASK) | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation threshold of the NFT
   * @param self The NFT configuration
   * @return The liquidation threshold
   **/
  function getLiquidationThreshold(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @dev Sets the liquidation bonus of the NFT
   * @param self The NFT configuration
   * @param bonus The new liquidation bonus
   **/
  function setLiquidationBonus(DataTypes.NftConfigurationMap memory self, uint256 bonus) internal pure {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.RC_INVALID_LIQ_BONUS);

    self.data = (self.data & LIQUIDATION_BONUS_MASK) | (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation bonus of the NFT
   * @param self The NFT configuration
   * @return The liquidation bonus
   **/
  function getLiquidationBonus(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @dev Sets the active state of the NFT
   * @param self The NFT configuration
   * @param active The active state
   **/
  function setActive(DataTypes.NftConfigurationMap memory self, bool active) internal pure {
    self.data = (self.data & ACTIVE_MASK) | (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the active state of the NFT
   * @param self The NFT configuration
   * @return The active state
   **/
  function getActive(DataTypes.NftConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~ACTIVE_MASK) != 0;
  }

  /**
   * @dev Sets the frozen state of the NFT
   * @param self The NFT configuration
   * @param frozen The frozen state
   **/
  function setFrozen(DataTypes.NftConfigurationMap memory self, bool frozen) internal pure {
    self.data = (self.data & FROZEN_MASK) | (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  /**
   * @dev Gets the frozen state of the NFT
   * @param self The NFT configuration
   * @return The frozen state
   **/
  function getFrozen(DataTypes.NftConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  /**
   * @dev Sets the redeem duration of the NFT
   * @param self The NFT configuration
   * @param redeemDuration The redeem duration
   **/
  function setRedeemDuration(DataTypes.NftConfigurationMap memory self, uint256 redeemDuration) internal pure {
    require(redeemDuration <= MAX_VALID_REDEEM_DURATION, Errors.RC_INVALID_REDEEM_DURATION);

    self.data = (self.data & REDEEM_DURATION_MASK) | (redeemDuration << REDEEM_DURATION_START_BIT_POSITION);
  }

  /**
   * @dev Gets the redeem duration of the NFT
   * @param self The NFT configuration
   * @return The redeem duration
   **/
  function getRedeemDuration(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~REDEEM_DURATION_MASK) >> REDEEM_DURATION_START_BIT_POSITION;
  }

  /**
   * @dev Sets the auction duration of the NFT
   * @param self The NFT configuration
   * @param auctionDuration The auction duration
   **/
  function setAuctionDuration(DataTypes.NftConfigurationMap memory self, uint256 auctionDuration) internal pure {
    require(auctionDuration <= MAX_VALID_AUCTION_DURATION, Errors.RC_INVALID_AUCTION_DURATION);

    self.data = (self.data & AUCTION_DURATION_MASK) | (auctionDuration << AUCTION_DURATION_START_BIT_POSITION);
  }

  /**
   * @dev Gets the auction duration of the NFT
   * @param self The NFT configuration
   * @return The auction duration
   **/
  function getAuctionDuration(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~AUCTION_DURATION_MASK) >> AUCTION_DURATION_START_BIT_POSITION;
  }

  /**
   * @dev Sets the redeem fine of the NFT
   * @param self The NFT configuration
   * @param redeemFine The redeem duration
   **/
  function setRedeemFine(DataTypes.NftConfigurationMap memory self, uint256 redeemFine) internal pure {
    require(redeemFine <= MAX_VALID_REDEEM_FINE, Errors.RC_INVALID_REDEEM_FINE);

    self.data = (self.data & REDEEM_FINE_MASK) | (redeemFine << REDEEM_FINE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the redeem fine of the NFT
   * @param self The NFT configuration
   * @return The redeem fine
   **/
  function getRedeemFine(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~REDEEM_FINE_MASK) >> REDEEM_FINE_START_BIT_POSITION;
  }

  /**
   * @dev Sets the redeem threshold of the NFT
   * @param self The NFT configuration
   * @param redeemThreshold The redeem duration
   **/
  function setRedeemThreshold(DataTypes.NftConfigurationMap memory self, uint256 redeemThreshold) internal pure {
    require(redeemThreshold <= MAX_VALID_REDEEM_THRESHOLD, Errors.RC_INVALID_REDEEM_THRESHOLD);

    self.data = (self.data & REDEEM_THRESHOLD_MASK) | (redeemThreshold << REDEEM_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @dev Gets the redeem threshold of the NFT
   * @param self The NFT configuration
   * @return The redeem threshold
   **/
  function getRedeemThreshold(DataTypes.NftConfigurationMap storage self) internal view returns (uint256) {
    return (self.data & ~REDEEM_THRESHOLD_MASK) >> REDEEM_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @dev Gets the configuration flags of the NFT
   * @param self The NFT configuration
   * @return The state flags representing active, frozen
   **/
  function getFlags(DataTypes.NftConfigurationMap storage self) internal view returns (bool, bool) {
    uint256 dataLocal = self.data;

    return ((dataLocal & ~ACTIVE_MASK) != 0, (dataLocal & ~FROZEN_MASK) != 0);
  }

  /**
   * @dev Gets the configuration flags of the NFT from a memory object
   * @param self The NFT configuration
   * @return The state flags representing active, frozen
   **/
  function getFlagsMemory(DataTypes.NftConfigurationMap memory self) internal pure returns (bool, bool) {
    return ((self.data & ~ACTIVE_MASK) != 0, (self.data & ~FROZEN_MASK) != 0);
  }

  /**
   * @dev Gets the collateral configuration paramters of the NFT
   * @param self The NFT configuration
   * @return The state params representing ltv, liquidation threshold, liquidation bonus
   **/
  function getCollateralParams(DataTypes.NftConfigurationMap storage self)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 dataLocal = self.data;

    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the auction configuration paramters of the NFT
   * @param self The NFT configuration
   * @return The state params representing redeem duration, auction duration, redeem fine
   **/
  function getAuctionParams(DataTypes.NftConfigurationMap storage self)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~REDEEM_DURATION_MASK) >> REDEEM_DURATION_START_BIT_POSITION,
      (dataLocal & ~AUCTION_DURATION_MASK) >> AUCTION_DURATION_START_BIT_POSITION,
      (dataLocal & ~REDEEM_FINE_MASK) >> REDEEM_FINE_START_BIT_POSITION,
      (dataLocal & ~REDEEM_THRESHOLD_MASK) >> REDEEM_THRESHOLD_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the collateral configuration paramters of the NFT from a memory object
   * @param self The NFT configuration
   * @return The state params representing ltv, liquidation threshold, liquidation bonus
   **/
  function getCollateralParamsMemory(DataTypes.NftConfigurationMap memory self)
    internal
    pure
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (
      self.data & ~LTV_MASK,
      (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION
    );
  }

  /**
   * @dev Gets the auction configuration paramters of the NFT from a memory object
   * @param self The NFT configuration
   * @return The state params representing redeem duration, auction duration, redeem fine
   **/
  function getAuctionParamsMemory(DataTypes.NftConfigurationMap memory self)
    internal
    pure
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    return (
      (self.data & ~REDEEM_DURATION_MASK) >> REDEEM_DURATION_START_BIT_POSITION,
      (self.data & ~AUCTION_DURATION_MASK) >> AUCTION_DURATION_START_BIT_POSITION,
      (self.data & ~REDEEM_FINE_MASK) >> REDEEM_FINE_START_BIT_POSITION,
      (self.data & ~REDEEM_THRESHOLD_MASK) >> REDEEM_THRESHOLD_START_BIT_POSITION
    );
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title PercentageMath library
 * @author Bend
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;
  uint256 constant ONE_PERCENT = 1e2; //100, 1%
  uint256 constant TEN_PERCENT = 1e3; //1000, 10%
  uint256 constant ONE_THOUSANDTH_PERCENT = 1e1; //10, 0.1%
  uint256 constant ONE_TEN_THOUSANDTH_PERCENT = 1; //1, 0.01%

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    require(value <= (type(uint256).max - HALF_PERCENT) / percentage, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
    require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfPercentage = percentage / 2;

    require(value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address bTokenAddress;
    address debtTokenAddress;
    //address of the interest rate strategy
    address interestRateAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct NftData {
    //stores the nft configuration
    NftConfigurationMap configuration;
    //address of the bNFT contract
    address bNftAddress;
    //the id of the nft. Represents the position in the list of the active nfts
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct NftConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 56: NFT is active
    //bit 57: NFT is frozen
    uint256 data;
  }

  /**
   * @dev Enum describing the current state of a loan
   * State change flow:
   *  Created -> Active -> Repaid
   *                    -> Auction -> Defaulted
   */
  enum LoanState {
    // We need a default that is not 'Created' - this is the zero value
    None,
    // The loan data is stored, but not initiated yet.
    Created,
    // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
    Active,
    // The loan is in auction, higest price liquidator will got chance to claim it.
    Auction,
    // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
    Repaid,
    // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
    Defaulted
  }

  struct LoanData {
    //the id of the nft loan
    uint256 loanId;
    //the current state of the loan
    LoanState state;
    //address of borrower
    address borrower;
    //address of nft asset token
    address nftAsset;
    //the id of nft token
    uint256 nftTokenId;
    //address of reserve asset token
    address reserveAsset;
    //scaled borrow amount. Expressed in ray
    uint256 scaledAmount;
    //start time of first bid time
    uint256 bidStartTimestamp;
    //bidder address of higest bid
    address bidderAddress;
    //price of higest bid
    uint256 bidPrice;
    //borrow amount of loan
    uint256 bidBorrowAmount;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IScaledBalanceToken {
  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return The scaled total supply
   **/
  function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {ILendPoolAddressesProviderRegistry} from "../interfaces/ILendPoolAddressesProviderRegistry.sol";

/**
 * @title LendPoolAddressesProviderRegistry contract
 * @dev Main registry of LendPoolAddressesProvider of multiple Bend protocol's markets
 * - Used for indexing purposes of Bend protocol's markets
 * - The id assigned to a LendPoolAddressesProvider refers to the market it is connected with,
 *   for example with `1` for the Bend main market and `2` for the next created
 * @author Bend
 **/
contract LendPoolAddressesProviderRegistry is Ownable, ILendPoolAddressesProviderRegistry {
  mapping(address => uint256) private _addressesProviders;
  address[] private _addressesProvidersList;

  /**
   * @dev Returns the list of registered addresses provider
   * @return The list of addresses provider, potentially containing address(0) elements
   **/
  function getAddressesProvidersList() external view override returns (address[] memory) {
    address[] memory addressesProvidersList = _addressesProvidersList;

    uint256 maxLength = addressesProvidersList.length;

    address[] memory activeProviders = new address[](maxLength);

    for (uint256 i = 0; i < maxLength; i++) {
      if (_addressesProviders[addressesProvidersList[i]] > 0) {
        activeProviders[i] = addressesProvidersList[i];
      }
    }

    return activeProviders;
  }

  /**
   * @dev Registers an addresses provider
   * @param provider The address of the new LendPoolAddressesProvider
   * @param id The id for the new LendPoolAddressesProvider, referring to the market it belongs to
   **/
  function registerAddressesProvider(address provider, uint256 id) external override onlyOwner {
    require(id != 0, Errors.LPAPR_INVALID_ADDRESSES_PROVIDER_ID);

    _addressesProviders[provider] = id;
    _addToAddressesProvidersList(provider);
    emit AddressesProviderRegistered(provider);
  }

  /**
   * @dev Removes a LendPoolAddressesProvider from the list of registered addresses provider
   * @param provider The LendPoolAddressesProvider address
   **/
  function unregisterAddressesProvider(address provider) external override onlyOwner {
    require(_addressesProviders[provider] > 0, Errors.LPAPR_PROVIDER_NOT_REGISTERED);
    _addressesProviders[provider] = 0;
    emit AddressesProviderUnregistered(provider);
  }

  /**
   * @dev Returns the id on a registered LendPoolAddressesProvider
   * @return The id or 0 if the LendPoolAddressesProvider is not registered
   */
  function getAddressesProviderIdByAddress(address addressesProvider) external view override returns (uint256) {
    return _addressesProviders[addressesProvider];
  }

  function _addToAddressesProvidersList(address provider) internal {
    uint256 providersCount = _addressesProvidersList.length;

    for (uint256 i = 0; i < providersCount; i++) {
      if (_addressesProvidersList[i] == provider) {
        return;
      }
    }

    _addressesProvidersList.push(provider);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title ILendPoolAddressesProviderRegistry contract
 * @dev Main registry of LendPoolAddressesProvider of multiple Bend protocol's markets
 * - Used for indexing purposes of Bend protocol's markets
 * - The id assigned to a LendPoolAddressesProvider refers to the market it is connected with,
 *   for example with `1` for the Bend main market and `2` for the next created
 * @author Bend
 **/
interface ILendPoolAddressesProviderRegistry {
  event AddressesProviderRegistered(address indexed newAddress);
  event AddressesProviderUnregistered(address indexed newAddress);

  function getAddressesProvidersList() external view returns (address[] memory);

  function getAddressesProviderIdByAddress(address addressesProvider) external view returns (uint256);

  function registerAddressesProvider(address provider, uint256 id) external;

  function unregisterAddressesProvider(address provider) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ERC721HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import {Errors} from "../libraries/helpers/Errors.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {ILendPoolLoan} from "../interfaces/ILendPoolLoan.sol";
import {IBToken} from "../interfaces/IBToken.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

import {EmergencyTokenRecoveryUpgradeable} from "./EmergencyTokenRecoveryUpgradeable.sol";

contract WETHGateway is IWETHGateway, ERC721HolderUpgradeable, EmergencyTokenRecoveryUpgradeable {
  ILendPoolAddressesProvider internal _addressProvider;

  IWETH internal WETH;

  mapping(address => bool) internal _callerWhitelists;

  uint256 private constant _NOT_ENTERED = 0;
  uint256 private constant _ENTERED = 1;
  uint256 private _status;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and making it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }

  /**
   * @dev Sets the WETH address and the LendPoolAddressesProvider address. Infinite approves lend pool.
   * @param weth Address of the Wrapped Ether contract
   **/
  function initialize(address addressProvider, address weth) public initializer {
    __ERC721Holder_init();
    __EmergencyTokenRecovery_init();

    _addressProvider = ILendPoolAddressesProvider(addressProvider);

    WETH = IWETH(weth);

    WETH.approve(address(_getLendPool()), type(uint256).max);
  }

  function _getLendPool() internal view returns (ILendPool) {
    return ILendPool(_addressProvider.getLendPool());
  }

  function _getLendPoolLoan() internal view returns (ILendPoolLoan) {
    return ILendPoolLoan(_addressProvider.getLendPoolLoan());
  }

  function authorizeLendPoolNFT(address[] calldata nftAssets) external nonReentrant onlyOwner {
    for (uint256 i = 0; i < nftAssets.length; i++) {
      IERC721Upgradeable(nftAssets[i]).setApprovalForAll(address(_getLendPool()), true);
    }
  }

  function authorizeCallerWhitelist(address[] calldata callers, bool flag) external nonReentrant onlyOwner {
    for (uint256 i = 0; i < callers.length; i++) {
      _callerWhitelists[callers[i]] = flag;
    }
  }

  function isCallerInWhitelist(address caller) external view returns (bool) {
    return _callerWhitelists[caller];
  }

  function _checkValidCallerAndOnBehalfOf(address onBehalfOf) internal view {
    require(
      (onBehalfOf == _msgSender()) || (_callerWhitelists[_msgSender()] == true),
      Errors.CALLER_NOT_ONBEHALFOF_OR_IN_WHITELIST
    );
  }

  function depositETH(address onBehalfOf, uint16 referralCode) external payable override nonReentrant {
    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    ILendPool cachedPool = _getLendPool();

    WETH.deposit{value: msg.value}();
    cachedPool.deposit(address(WETH), msg.value, onBehalfOf, referralCode);
  }

  function withdrawETH(uint256 amount, address to) external override nonReentrant {
    _checkValidCallerAndOnBehalfOf(to);

    ILendPool cachedPool = _getLendPool();
    IBToken bWETH = IBToken(cachedPool.getReserveData(address(WETH)).bTokenAddress);

    uint256 userBalance = bWETH.balanceOf(msg.sender);
    uint256 amountToWithdraw = amount;

    // if amount is equal to uint(-1), the user wants to redeem everything
    if (amount == type(uint256).max) {
      amountToWithdraw = userBalance;
    }

    bWETH.transferFrom(msg.sender, address(this), amountToWithdraw);
    cachedPool.withdraw(address(WETH), amountToWithdraw, address(this));
    WETH.withdraw(amountToWithdraw);
    _safeTransferETH(to, amountToWithdraw);
  }

  function borrowETH(
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    uint16 referralCode
  ) external override nonReentrant {
    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(nftAsset, nftTokenId);
    if (loanId == 0) {
      IERC721Upgradeable(nftAsset).safeTransferFrom(msg.sender, address(this), nftTokenId);
    }
    cachedPool.borrow(address(WETH), amount, nftAsset, nftTokenId, onBehalfOf, referralCode);
    WETH.withdraw(amount);
    _safeTransferETH(onBehalfOf, amount);
  }

  function batchBorrowETH(
    uint256[] calldata amounts,
    address[] calldata nftAssets,
    uint256[] calldata nftTokenIds,
    address onBehalfOf,
    uint16 referralCode
  ) external override nonReentrant {
    require(nftAssets.length == nftTokenIds.length, "inconsistent tokenIds length");
    require(nftAssets.length == amounts.length, "inconsistent amounts length");

    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    for (uint256 i = 0; i < nftAssets.length; i++) {
      uint256 loanId = cachedPoolLoan.getCollateralLoanId(nftAssets[i], nftTokenIds[i]);
      if (loanId == 0) {
        IERC721Upgradeable(nftAssets[i]).safeTransferFrom(msg.sender, address(this), nftTokenIds[i]);
      }
      cachedPool.borrow(address(WETH), amounts[i], nftAssets[i], nftTokenIds[i], onBehalfOf, referralCode);

      WETH.withdraw(amounts[i]);
      _safeTransferETH(onBehalfOf, amounts[i]);
    }
  }

  function repayETH(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) external payable override nonReentrant returns (uint256, bool) {
    (uint256 repayAmount, bool repayAll) = _repayETH(nftAsset, nftTokenId, amount, 0);

    // refund remaining dust eth
    if (msg.value > repayAmount) {
      _safeTransferETH(msg.sender, msg.value - repayAmount);
    }

    return (repayAmount, repayAll);
  }

  function batchRepayETH(
    address[] calldata nftAssets,
    uint256[] calldata nftTokenIds,
    uint256[] calldata amounts
  ) external payable override nonReentrant returns (uint256[] memory, bool[] memory) {
    require(nftAssets.length == amounts.length, "inconsistent amounts length");
    require(nftAssets.length == nftTokenIds.length, "inconsistent tokenIds length");

    uint256[] memory repayAmounts = new uint256[](nftAssets.length);
    bool[] memory repayAlls = new bool[](nftAssets.length);
    uint256 allRepayDebtAmount = 0;

    for (uint256 i = 0; i < nftAssets.length; i++) {
      (repayAmounts[i], repayAlls[i]) = _repayETH(nftAssets[i], nftTokenIds[i], amounts[i], allRepayDebtAmount);

      allRepayDebtAmount += repayAmounts[i];
    }

    // refund remaining dust eth
    if (msg.value > allRepayDebtAmount) {
      _safeTransferETH(msg.sender, msg.value - allRepayDebtAmount);
    }

    return (repayAmounts, repayAlls);
  }

  function _repayETH(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 accAmount
  ) internal returns (uint256, bool) {
    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(nftAsset, nftTokenId);
    require(loanId > 0, "collateral loan id not exist");

    (address reserveAsset, uint256 repayDebtAmount) = cachedPoolLoan.getLoanReserveBorrowAmount(loanId);
    require(reserveAsset == address(WETH), "loan reserve not WETH");

    if (amount < repayDebtAmount) {
      repayDebtAmount = amount;
    }

    require(msg.value >= (accAmount + repayDebtAmount), "msg.value is less than repay amount");

    WETH.deposit{value: repayDebtAmount}();
    (uint256 paybackAmount, bool burn) = cachedPool.repay(nftAsset, nftTokenId, amount);

    return (paybackAmount, burn);
  }

  function auctionETH(
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf
  ) external payable override nonReentrant {
    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(nftAsset, nftTokenId);
    require(loanId > 0, "collateral loan id not exist");

    DataTypes.LoanData memory loan = cachedPoolLoan.getLoan(loanId);
    require(loan.reserveAsset == address(WETH), "loan reserve not WETH");

    WETH.deposit{value: msg.value}();
    cachedPool.auction(nftAsset, nftTokenId, msg.value, onBehalfOf);
  }

  function redeemETH(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 bidFine
  ) external payable override nonReentrant returns (uint256) {
    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(nftAsset, nftTokenId);
    require(loanId > 0, "collateral loan id not exist");

    DataTypes.LoanData memory loan = cachedPoolLoan.getLoan(loanId);
    require(loan.reserveAsset == address(WETH), "loan reserve not WETH");

    require(msg.value >= (amount + bidFine), "msg.value is less than redeem amount");

    WETH.deposit{value: msg.value}();

    uint256 paybackAmount = cachedPool.redeem(nftAsset, nftTokenId, amount, bidFine);

    // refund remaining dust eth
    if (msg.value > paybackAmount) {
      WETH.withdraw(msg.value - paybackAmount);
      _safeTransferETH(msg.sender, msg.value - paybackAmount);
    }

    return paybackAmount;
  }

  function liquidateETH(address nftAsset, uint256 nftTokenId) external payable override nonReentrant returns (uint256) {
    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(nftAsset, nftTokenId);
    require(loanId > 0, "collateral loan id not exist");

    DataTypes.LoanData memory loan = cachedPoolLoan.getLoan(loanId);
    require(loan.reserveAsset == address(WETH), "loan reserve not WETH");

    if (msg.value > 0) {
      WETH.deposit{value: msg.value}();
    }

    uint256 extraAmount = cachedPool.liquidate(nftAsset, nftTokenId, msg.value);

    if (msg.value > extraAmount) {
      WETH.withdraw(msg.value - extraAmount);
      _safeTransferETH(msg.sender, msg.value - extraAmount);
    }

    return (extraAmount);
  }

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "ETH_TRANSFER_FAILED");
  }

  /**
   * @dev Get WETH address used by WETHGateway
   */
  function getWETHAddress() external view returns (address) {
    return address(WETH);
  }

  /**
   * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
   */
  receive() external payable {
    require(msg.sender == address(WETH), "Receive not allowed");
  }

  /**
   * @dev Revert fallback calls
   */
  fallback() external payable {
    revert("Fallback not allowed");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IWETHGateway {
  /**
   * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (bTokens)
   * is minted.
   * @param onBehalfOf address of the user who will receive the bTokens representing the deposit
   * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
   **/
  function depositETH(address onBehalfOf, uint16 referralCode) external payable;

  /**
   * @dev withdraws the WETH _reserves of msg.sender.
   * @param amount amount of bWETH to withdraw and receive native ETH
   * @param to address of the user who will receive native ETH
   */
  function withdrawETH(uint256 amount, address to) external;

  /**
   * @dev borrow WETH, unwraps to ETH and send both the ETH and DebtTokens to msg.sender, via `approveDelegation` and onBehalf argument in `LendPool.borrow`.
   * @param amount the amount of ETH to borrow
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param onBehalfOf Address of the user who will receive the loan. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   * @param referralCode integrators are assigned a referral code and can potentially receive rewards
   */
  function borrowETH(
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function batchBorrowETH(
    uint256[] calldata amounts,
    address[] calldata nftAssets,
    uint256[] calldata nftTokenIds,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev repays a borrow on the WETH reserve, for the specified amount (or for the whole amount, if uint256(-1) is specified).
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount the amount to repay, or uint256(-1) if the user wants to repay everything
   */
  function repayETH(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) external payable returns (uint256, bool);

  function batchRepayETH(
    address[] calldata nftAssets,
    uint256[] calldata nftTokenIds,
    uint256[] calldata amounts
  ) external payable returns (uint256[] memory, bool[] memory);

  /**
   * @dev auction a borrow on the WETH reserve
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param onBehalfOf Address of the user who will receive the underlying NFT used as collateral.
   * Should be the address of the borrower itself calling the function if he wants to borrow against his own collateral.
   */
  function auctionETH(
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf
  ) external payable;

  /**
   * @dev redeems a borrow on the WETH reserve
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   */
  function redeemETH(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 bidFine
  ) external payable returns (uint256);

  /**
   * @dev liquidates a borrow on the WETH reserve
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   */
  function liquidateETH(address nftAsset, uint256 nftTokenId) external payable returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import {IPunks} from "../interfaces/IPunks.sol";

/**
 * @title EmergencyTokenRecovery
 * @notice Add Emergency Recovery Logic to contract implementation
 * @author Bend
 **/
abstract contract EmergencyTokenRecoveryUpgradeable is OwnableUpgradeable {
  event EmergencyEtherTransfer(address indexed to, uint256 amount);

  function __EmergencyTokenRecovery_init() internal onlyInitializing {
    __Ownable_init();
  }

  /**
   * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
   * direct transfers to the contract address.
   * @param token token to transfer
   * @param to recipient of the transfer
   * @param amount amount to send
   */
  function emergencyERC20Transfer(
    address token,
    address to,
    uint256 amount
  ) external onlyOwner {
    IERC20Upgradeable(token).transfer(to, amount);
  }

  /**
   * @dev transfer ERC721 from the utility contract, for ERC721 recovery in case of stuck tokens due
   * direct transfers to the contract address.
   * @param token token to transfer
   * @param to recipient of the transfer
   * @param id token id to send
   */
  function emergencyERC721Transfer(
    address token,
    address to,
    uint256 id
  ) external onlyOwner {
    IERC721Upgradeable(token).safeTransferFrom(address(this), to, id);
  }

  /**
   * @dev transfer CryptoPunks from the utility contract, for punks recovery in case of stuck punks
   * due direct transfers to the contract address.
   * @param to recipient of the transfer
   * @param index punk index to send
   */
  function emergencyPunksTransfer(
    address punks,
    address to,
    uint256 index
  ) external onlyOwner {
    IPunks(punks).transferPunk(to, index);
  }

  /**
   * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
   * due selfdestructs or transfer ether to pre-computated contract address before deployment.
   * @param to recipient of the transfer
   * @param amount amount to send
   */
  function emergencyEtherTransfer(address to, uint256 amount) external onlyOwner {
    (bool success, ) = to.call{value: amount}(new bytes(0));
    require(success, "ETH_TRANSFER_FAILED");
    emit EmergencyEtherTransfer(to, amount);
  }

  uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @dev Interface for a permittable ERC721 contract
 * See https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC72 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC721-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IPunks {
  function balanceOf(address account) external view returns (uint256);

  function punkIndexToAddress(uint256 punkIndex) external view returns (address owner);

  function buyPunk(uint256 punkIndex) external;

  function transferPunk(address to, uint256 punkIndex) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ERC721HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import {Errors} from "../libraries/helpers/Errors.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {ILendPoolLoan} from "../interfaces/ILendPoolLoan.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {IPunks} from "../interfaces/IPunks.sol";
import {IWrappedPunks} from "../interfaces/IWrappedPunks.sol";
import {IPunkGateway} from "../interfaces/IPunkGateway.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IWETHGateway} from "../interfaces/IWETHGateway.sol";

import {EmergencyTokenRecoveryUpgradeable} from "./EmergencyTokenRecoveryUpgradeable.sol";

contract PunkGateway is IPunkGateway, ERC721HolderUpgradeable, EmergencyTokenRecoveryUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  ILendPoolAddressesProvider internal _addressProvider;
  IWETHGateway internal _wethGateway;

  IPunks public punks;
  IWrappedPunks public wrappedPunks;
  address public proxy;

  mapping(address => bool) internal _callerWhitelists;

  uint256 private constant _NOT_ENTERED = 0;
  uint256 private constant _ENTERED = 1;
  uint256 private _status;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and making it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }

  function initialize(
    address addressProvider,
    address wethGateway,
    address _punks,
    address _wrappedPunks
  ) public initializer {
    __ERC721Holder_init();
    __EmergencyTokenRecovery_init();

    _addressProvider = ILendPoolAddressesProvider(addressProvider);
    _wethGateway = IWETHGateway(wethGateway);

    punks = IPunks(_punks);
    wrappedPunks = IWrappedPunks(_wrappedPunks);
    wrappedPunks.registerProxy();
    proxy = wrappedPunks.proxyInfo(address(this));

    IERC721Upgradeable(address(wrappedPunks)).setApprovalForAll(address(_getLendPool()), true);
    IERC721Upgradeable(address(wrappedPunks)).setApprovalForAll(address(_wethGateway), true);
  }

  function _getLendPool() internal view returns (ILendPool) {
    return ILendPool(_addressProvider.getLendPool());
  }

  function _getLendPoolLoan() internal view returns (ILendPoolLoan) {
    return ILendPoolLoan(_addressProvider.getLendPoolLoan());
  }

  function authorizeLendPoolERC20(address[] calldata tokens) external nonReentrant onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20Upgradeable(tokens[i]).approve(address(_getLendPool()), type(uint256).max);
    }
  }

  function authorizeCallerWhitelist(address[] calldata callers, bool flag) external nonReentrant onlyOwner {
    for (uint256 i = 0; i < callers.length; i++) {
      _callerWhitelists[callers[i]] = flag;
    }
  }

  function isCallerInWhitelist(address caller) external view returns (bool) {
    return _callerWhitelists[caller];
  }

  function _checkValidCallerAndOnBehalfOf(address onBehalfOf) internal view {
    require(
      (onBehalfOf == _msgSender()) || (_callerWhitelists[_msgSender()] == true),
      Errors.CALLER_NOT_ONBEHALFOF_OR_IN_WHITELIST
    );
  }

  function _depositPunk(uint256 punkIndex) internal {
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    if (loanId != 0) {
      return;
    }

    address owner = punks.punkIndexToAddress(punkIndex);
    require(owner == _msgSender(), "PunkGateway: not owner of punkIndex");

    punks.buyPunk(punkIndex);
    punks.transferPunk(proxy, punkIndex);

    wrappedPunks.mint(punkIndex);
  }

  function borrow(
    address reserveAsset,
    uint256 amount,
    uint256 punkIndex,
    address onBehalfOf,
    uint16 referralCode
  ) external override nonReentrant {
    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    ILendPool cachedPool = _getLendPool();

    _depositPunk(punkIndex);

    cachedPool.borrow(reserveAsset, amount, address(wrappedPunks), punkIndex, onBehalfOf, referralCode);
    IERC20Upgradeable(reserveAsset).transfer(onBehalfOf, amount);
  }

  function batchBorrow(
    address[] calldata reserveAssets,
    uint256[] calldata amounts,
    uint256[] calldata punkIndexs,
    address onBehalfOf,
    uint16 referralCode
  ) external override nonReentrant {
    require(punkIndexs.length == reserveAssets.length, "inconsistent reserveAssets length");
    require(punkIndexs.length == amounts.length, "inconsistent amounts length");

    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    ILendPool cachedPool = _getLendPool();

    for (uint256 i = 0; i < punkIndexs.length; i++) {
      _depositPunk(punkIndexs[i]);

      cachedPool.borrow(reserveAssets[i], amounts[i], address(wrappedPunks), punkIndexs[i], onBehalfOf, referralCode);

      IERC20Upgradeable(reserveAssets[i]).transfer(onBehalfOf, amounts[i]);
    }
  }

  function _withdrawPunk(uint256 punkIndex, address onBehalfOf) internal {
    address owner = wrappedPunks.ownerOf(punkIndex);
    require(owner == _msgSender(), "PunkGateway: caller is not owner");
    require(owner == onBehalfOf, "PunkGateway: onBehalfOf is not owner");

    wrappedPunks.safeTransferFrom(onBehalfOf, address(this), punkIndex);
    wrappedPunks.burn(punkIndex);
    punks.transferPunk(onBehalfOf, punkIndex);
  }

  function repay(uint256 punkIndex, uint256 amount) external override nonReentrant returns (uint256, bool) {
    return _repay(punkIndex, amount);
  }

  function batchRepay(uint256[] calldata punkIndexs, uint256[] calldata amounts)
    external
    override
    nonReentrant
    returns (uint256[] memory, bool[] memory)
  {
    require(punkIndexs.length == amounts.length, "inconsistent amounts length");

    uint256[] memory repayAmounts = new uint256[](punkIndexs.length);
    bool[] memory repayAlls = new bool[](punkIndexs.length);

    for (uint256 i = 0; i < punkIndexs.length; i++) {
      (repayAmounts[i], repayAlls[i]) = _repay(punkIndexs[i], amounts[i]);
    }

    return (repayAmounts, repayAlls);
  }

  function _repay(uint256 punkIndex, uint256 amount) internal returns (uint256, bool) {
    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");
    (, , address reserve, ) = cachedPoolLoan.getLoanCollateralAndReserve(loanId);
    (, uint256 debt) = cachedPoolLoan.getLoanReserveBorrowAmount(loanId);
    address borrower = cachedPoolLoan.borrowerOf(loanId);

    if (amount > debt) {
      amount = debt;
    }

    IERC20Upgradeable(reserve).transferFrom(msg.sender, address(this), amount);

    (uint256 paybackAmount, bool burn) = cachedPool.repay(address(wrappedPunks), punkIndex, amount);

    if (burn) {
      require(borrower == _msgSender(), "PunkGateway: caller is not borrower");
      _withdrawPunk(punkIndex, borrower);
    }

    return (paybackAmount, burn);
  }

  function auction(
    uint256 punkIndex,
    uint256 bidPrice,
    address onBehalfOf
  ) external override nonReentrant {
    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    (, , address reserve, ) = cachedPoolLoan.getLoanCollateralAndReserve(loanId);

    IERC20Upgradeable(reserve).transferFrom(msg.sender, address(this), bidPrice);

    cachedPool.auction(address(wrappedPunks), punkIndex, bidPrice, onBehalfOf);
  }

  function redeem(
    uint256 punkIndex,
    uint256 amount,
    uint256 bidFine
  ) external override nonReentrant returns (uint256) {
    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    DataTypes.LoanData memory loan = cachedPoolLoan.getLoan(loanId);

    IERC20Upgradeable(loan.reserveAsset).transferFrom(msg.sender, address(this), (amount + bidFine));

    uint256 paybackAmount = cachedPool.redeem(address(wrappedPunks), punkIndex, amount, bidFine);

    if ((amount + bidFine) > paybackAmount) {
      IERC20Upgradeable(loan.reserveAsset).safeTransfer(msg.sender, ((amount + bidFine) - paybackAmount));
    }

    return paybackAmount;
  }

  function liquidate(uint256 punkIndex, uint256 amount) external override nonReentrant returns (uint256) {
    ILendPool cachedPool = _getLendPool();
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    DataTypes.LoanData memory loan = cachedPoolLoan.getLoan(loanId);
    require(loan.bidderAddress == _msgSender(), "PunkGateway: caller is not bidder");

    if (amount > 0) {
      IERC20Upgradeable(loan.reserveAsset).transferFrom(msg.sender, address(this), amount);
    }

    uint256 extraRetAmount = cachedPool.liquidate(address(wrappedPunks), punkIndex, amount);

    _withdrawPunk(punkIndex, loan.bidderAddress);

    if (amount > extraRetAmount) {
      IERC20Upgradeable(loan.reserveAsset).safeTransfer(msg.sender, (amount - extraRetAmount));
    }

    return (extraRetAmount);
  }

  function borrowETH(
    uint256 amount,
    uint256 punkIndex,
    address onBehalfOf,
    uint16 referralCode
  ) external override nonReentrant {
    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    _depositPunk(punkIndex);
    _wethGateway.borrowETH(amount, address(wrappedPunks), punkIndex, onBehalfOf, referralCode);
  }

  function batchBorrowETH(
    uint256[] calldata amounts,
    uint256[] calldata punkIndexs,
    address onBehalfOf,
    uint16 referralCode
  ) external override nonReentrant {
    require(punkIndexs.length == amounts.length, "inconsistent amounts length");

    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    address[] memory nftAssets = new address[](punkIndexs.length);
    for (uint256 i = 0; i < punkIndexs.length; i++) {
      nftAssets[i] = address(wrappedPunks);
      _depositPunk(punkIndexs[i]);
    }

    _wethGateway.batchBorrowETH(amounts, nftAssets, punkIndexs, onBehalfOf, referralCode);
  }

  function repayETH(uint256 punkIndex, uint256 amount) external payable override nonReentrant returns (uint256, bool) {
    (uint256 paybackAmount, bool burn) = _repayETH(punkIndex, amount, 0);

    // refund remaining dust eth
    if (msg.value > paybackAmount) {
      _safeTransferETH(msg.sender, msg.value - paybackAmount);
    }

    return (paybackAmount, burn);
  }

  function batchRepayETH(uint256[] calldata punkIndexs, uint256[] calldata amounts)
    external
    payable
    override
    nonReentrant
    returns (uint256[] memory, bool[] memory)
  {
    require(punkIndexs.length == amounts.length, "inconsistent amounts length");

    uint256[] memory repayAmounts = new uint256[](punkIndexs.length);
    bool[] memory repayAlls = new bool[](punkIndexs.length);
    uint256 allRepayAmount = 0;

    for (uint256 i = 0; i < punkIndexs.length; i++) {
      (repayAmounts[i], repayAlls[i]) = _repayETH(punkIndexs[i], amounts[i], allRepayAmount);
      allRepayAmount += repayAmounts[i];
    }

    // refund remaining dust eth
    if (msg.value > allRepayAmount) {
      _safeTransferETH(msg.sender, msg.value - allRepayAmount);
    }

    return (repayAmounts, repayAlls);
  }

  function _repayETH(
    uint256 punkIndex,
    uint256 amount,
    uint256 accAmount
  ) internal returns (uint256, bool) {
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    address borrower = cachedPoolLoan.borrowerOf(loanId);
    require(borrower == _msgSender(), "PunkGateway: caller is not borrower");

    (, uint256 repayDebtAmount) = cachedPoolLoan.getLoanReserveBorrowAmount(loanId);
    if (amount < repayDebtAmount) {
      repayDebtAmount = amount;
    }

    require(msg.value >= (accAmount + repayDebtAmount), "msg.value is less than repay amount");

    (uint256 paybackAmount, bool burn) = _wethGateway.repayETH{value: repayDebtAmount}(
      address(wrappedPunks),
      punkIndex,
      amount
    );

    if (burn) {
      _withdrawPunk(punkIndex, borrower);
    }

    return (paybackAmount, burn);
  }

  function auctionETH(uint256 punkIndex, address onBehalfOf) external payable override nonReentrant {
    _checkValidCallerAndOnBehalfOf(onBehalfOf);

    _wethGateway.auctionETH{value: msg.value}(address(wrappedPunks), punkIndex, onBehalfOf);
  }

  function redeemETH(
    uint256 punkIndex,
    uint256 amount,
    uint256 bidFine
  ) external payable override nonReentrant returns (uint256) {
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    //DataTypes.LoanData memory loan = cachedPoolLoan.getLoan(loanId);

    uint256 paybackAmount = _wethGateway.redeemETH{value: msg.value}(address(wrappedPunks), punkIndex, amount, bidFine);

    // refund remaining dust eth
    if (msg.value > paybackAmount) {
      _safeTransferETH(msg.sender, msg.value - paybackAmount);
    }

    return paybackAmount;
  }

  function liquidateETH(uint256 punkIndex) external payable override nonReentrant returns (uint256) {
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();

    uint256 loanId = cachedPoolLoan.getCollateralLoanId(address(wrappedPunks), punkIndex);
    require(loanId != 0, "PunkGateway: no loan with such punkIndex");

    DataTypes.LoanData memory loan = cachedPoolLoan.getLoan(loanId);
    require(loan.bidderAddress == _msgSender(), "PunkGateway: caller is not bidder");

    uint256 extraAmount = _wethGateway.liquidateETH{value: msg.value}(address(wrappedPunks), punkIndex);

    _withdrawPunk(punkIndex, loan.bidderAddress);

    // refund remaining dust eth
    if (msg.value > extraAmount) {
      _safeTransferETH(msg.sender, msg.value - extraAmount);
    }

    return extraAmount;
  }

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "ETH_TRANSFER_FAILED");
  }

  /**
   * @dev
   */
  receive() external payable {}

  /**
   * @dev Revert fallback calls
   */
  fallback() external payable {
    revert("Fallback not allowed");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Interface for a permittable ERC721 contract
 * See https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC72 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC721-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IWrappedPunks is IERC721 {
  function punkContract() external view returns (address);

  function mint(uint256 punkIndex) external;

  function burn(uint256 punkIndex) external;

  function registerProxy() external;

  function proxyInfo(address user) external returns (address proxy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IPunkGateway {
  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral
   * - E.g. User borrows 100 USDC, receiving the 100 USDC in his wallet
   *   and lock collateral asset in contract
   * @param reserveAsset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param punkIndex The index of the CryptoPunk used as collteral
   * @param onBehalfOf Address of the user who will receive the loan. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function borrow(
    address reserveAsset,
    uint256 amount,
    uint256 punkIndex,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function batchBorrow(
    address[] calldata reserveAssets,
    uint256[] calldata amounts,
    uint256[] calldata punkIndexs,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific punk, burning the equivalent loan owned
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param punkIndex The index of the CryptoPunk used as collteral
   * @param amount The amount to repay
   * @return The final amount repaid, loan is burned or not
   **/
  function repay(uint256 punkIndex, uint256 amount) external returns (uint256, bool);

  function batchRepay(uint256[] calldata punkIndexs, uint256[] calldata amounts)
    external
    returns (uint256[] memory, bool[] memory);

  /**
   * @notice auction a unhealth punk loan with ERC20 reserve
   * @param punkIndex The index of the CryptoPunk used as collteral
   * @param bidPrice The bid price
   **/
  function auction(
    uint256 punkIndex,
    uint256 bidPrice,
    address onBehalfOf
  ) external;

  /**
   * @notice redeem a unhealth punk loan with ERC20 reserve
   * @param punkIndex The index of the CryptoPunk used as collteral
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   **/
  function redeem(
    uint256 punkIndex,
    uint256 amount,
    uint256 bidFine
  ) external returns (uint256);

  /**
   * @notice liquidate a unhealth punk loan with ERC20 reserve
   * @param punkIndex The index of the CryptoPunk used as collteral
   **/
  function liquidate(uint256 punkIndex, uint256 amount) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral
   * - E.g. User borrows 100 ETH, receiving the 100 ETH in his wallet
   *   and lock collateral asset in contract
   * @param amount The amount to be borrowed
   * @param punkIndex The index of the CryptoPunk to deposit
   * @param onBehalfOf Address of the user who will receive the loan. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function borrowETH(
    uint256 amount,
    uint256 punkIndex,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function batchBorrowETH(
    uint256[] calldata amounts,
    uint256[] calldata punkIndexs,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific punk with native ETH
   * - E.g. User repays 100 ETH, burning loan and receives collateral asset
   * @param punkIndex The index of the CryptoPunk to repay
   * @param amount The amount to repay
   * @return The final amount repaid, loan is burned or not
   **/
  function repayETH(uint256 punkIndex, uint256 amount) external payable returns (uint256, bool);

  function batchRepayETH(uint256[] calldata punkIndexs, uint256[] calldata amounts)
    external
    payable
    returns (uint256[] memory, bool[] memory);

  /**
   * @notice auction a unhealth punk loan with native ETH
   * @param punkIndex The index of the CryptoPunk to repay
   * @param onBehalfOf Address of the user who will receive the CryptoPunk. Should be the address of the user itself
   * calling the function if he wants to get collateral
   **/
  function auctionETH(uint256 punkIndex, address onBehalfOf) external payable;

  /**
   * @notice liquidate a unhealth punk loan with native ETH
   * @param punkIndex The index of the CryptoPunk to repay
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   **/
  function redeemETH(
    uint256 punkIndex,
    uint256 amount,
    uint256 bidFine
  ) external payable returns (uint256);

  /**
   * @notice liquidate a unhealth punk loan with native ETH
   * @param punkIndex The index of the CryptoPunk to repay
   **/
  function liquidateETH(uint256 punkIndex) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IBNFT} from "../interfaces/IBNFT.sol";
import {ILendPoolLoan} from "../interfaces/ILendPoolLoan.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract LendPoolLoan is Initializable, ILendPoolLoan, ContextUpgradeable, IERC721ReceiverUpgradeable {
  using WadRayMath for uint256;
  using CountersUpgradeable for CountersUpgradeable.Counter;

  ILendPoolAddressesProvider private _addressesProvider;

  CountersUpgradeable.Counter private _loanIdTracker;
  mapping(uint256 => DataTypes.LoanData) private _loans;

  // nftAsset + nftTokenId => loanId
  mapping(address => mapping(uint256 => uint256)) private _nftToLoanIds;
  mapping(address => uint256) private _nftTotalCollateral;
  mapping(address => mapping(address => uint256)) private _userNftCollateral;

  /**
   * @dev Only lending pool can call functions marked by this modifier
   **/
  modifier onlyLendPool() {
    require(_msgSender() == address(_getLendPool()), Errors.CT_CALLER_MUST_BE_LEND_POOL);
    _;
  }

  // called once by the factory at time of deployment
  function initialize(ILendPoolAddressesProvider provider) external initializer {
    __Context_init();

    _addressesProvider = provider;

    // Avoid having loanId = 0
    _loanIdTracker.increment();

    emit Initialized(address(_getLendPool()));
  }

  function initNft(address nftAsset, address bNftAddress) external override onlyLendPool {
    IERC721Upgradeable(nftAsset).setApprovalForAll(bNftAddress, true);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function createLoan(
    address initiator,
    address onBehalfOf,
    address nftAsset,
    uint256 nftTokenId,
    address bNftAddress,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  ) external override onlyLendPool returns (uint256) {
    require(_nftToLoanIds[nftAsset][nftTokenId] == 0, Errors.LP_NFT_HAS_USED_AS_COLLATERAL);

    // index is expressed in Ray, so:
    // amount.wadToRay().rayDiv(index).rayToWad() => amount.rayDiv(index)
    uint256 amountScaled = amount.rayDiv(borrowIndex);

    uint256 loanId = _loanIdTracker.current();
    _loanIdTracker.increment();

    _nftToLoanIds[nftAsset][nftTokenId] = loanId;

    // transfer underlying NFT asset to pool and mint bNFT to onBehalfOf
    IERC721Upgradeable(nftAsset).safeTransferFrom(_msgSender(), address(this), nftTokenId);

    IBNFT(bNftAddress).mint(onBehalfOf, nftTokenId);

    // Save Info
    DataTypes.LoanData storage loanData = _loans[loanId];
    loanData.loanId = loanId;
    loanData.state = DataTypes.LoanState.Active;
    loanData.borrower = onBehalfOf;
    loanData.nftAsset = nftAsset;
    loanData.nftTokenId = nftTokenId;
    loanData.reserveAsset = reserveAsset;
    loanData.scaledAmount = amountScaled;

    _userNftCollateral[onBehalfOf][nftAsset] += 1;

    _nftTotalCollateral[nftAsset] += 1;

    emit LoanCreated(initiator, onBehalfOf, loanId, nftAsset, nftTokenId, reserveAsset, amount, borrowIndex);

    return (loanId);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function updateLoan(
    address initiator,
    uint256 loanId,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);

    uint256 amountScaled = 0;

    if (amountAdded > 0) {
      amountScaled = amountAdded.rayDiv(borrowIndex);
      require(amountScaled != 0, Errors.LPL_INVALID_LOAN_AMOUNT);

      loan.scaledAmount += amountScaled;
    }

    if (amountTaken > 0) {
      amountScaled = amountTaken.rayDiv(borrowIndex);
      require(amountScaled != 0, Errors.LPL_INVALID_TAKEN_AMOUNT);

      require(loan.scaledAmount >= amountScaled, Errors.LPL_AMOUNT_OVERFLOW);
      loan.scaledAmount -= amountScaled;
    }

    emit LoanUpdated(
      initiator,
      loanId,
      loan.nftAsset,
      loan.nftTokenId,
      loan.reserveAsset,
      amountAdded,
      amountTaken,
      borrowIndex
    );
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function repayLoan(
    address initiator,
    uint256 loanId,
    address bNftAddress,
    uint256 amount,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);

    // state changes and cleanup
    // NOTE: these must be performed before assets are released to prevent reentrance
    _loans[loanId].state = DataTypes.LoanState.Repaid;

    _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

    require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, Errors.LP_INVALIED_USER_NFT_AMOUNT);
    _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

    require(_nftTotalCollateral[loan.nftAsset] >= 1, Errors.LP_INVALIED_NFT_AMOUNT);
    _nftTotalCollateral[loan.nftAsset] -= 1;

    // burn bNFT and transfer underlying NFT asset to user
    IBNFT(bNftAddress).burn(loan.nftTokenId);

    IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), _msgSender(), loan.nftTokenId);

    emit LoanRepaid(initiator, loanId, loan.nftAsset, loan.nftTokenId, loan.reserveAsset, amount, borrowIndex);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function auctionLoan(
    address initiator,
    uint256 loanId,
    address onBehalfOf,
    uint256 bidPrice,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];
    address previousBidder = loan.bidderAddress;
    uint256 previousPrice = loan.bidPrice;

    // Ensure valid loan state
    if (loan.bidStartTimestamp == 0) {
      require(loan.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);

      loan.state = DataTypes.LoanState.Auction;
      loan.bidStartTimestamp = block.timestamp;
    } else {
      require(loan.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);

      require(bidPrice > loan.bidPrice, Errors.LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE);
    }

    loan.bidBorrowAmount = borrowAmount;
    loan.bidderAddress = onBehalfOf;
    loan.bidPrice = bidPrice;

    emit LoanAuctioned(
      initiator,
      loanId,
      loan.nftAsset,
      loan.nftTokenId,
      loan.bidBorrowAmount,
      borrowIndex,
      onBehalfOf,
      bidPrice,
      previousBidder,
      previousPrice
    );
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function redeemLoan(
    address initiator,
    uint256 loanId,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);

    uint256 amountScaled = amountTaken.rayDiv(borrowIndex);
    require(amountScaled != 0, Errors.LPL_INVALID_TAKEN_AMOUNT);

    require(loan.scaledAmount >= amountScaled, Errors.LPL_AMOUNT_OVERFLOW);
    loan.scaledAmount -= amountScaled;

    loan.state = DataTypes.LoanState.Active;
    loan.bidStartTimestamp = 0;
    loan.bidBorrowAmount = 0;
    loan.bidderAddress = address(0);
    loan.bidPrice = 0;

    emit LoanRedeemed(initiator, loanId, loan.nftAsset, loan.nftTokenId, loan.reserveAsset, amountTaken, borrowIndex);
  }

  /**
   * @inheritdoc ILendPoolLoan
   */
  function liquidateLoan(
    address initiator,
    uint256 loanId,
    address bNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external override onlyLendPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

    // Ensure valid loan state
    require(loan.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);

    // state changes and cleanup
    // NOTE: these must be performed before assets are released to prevent reentrance
    _loans[loanId].state = DataTypes.LoanState.Defaulted;
    _loans[loanId].bidBorrowAmount = borrowAmount;

    _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

    require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, Errors.LP_INVALIED_USER_NFT_AMOUNT);
    _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

    require(_nftTotalCollateral[loan.nftAsset] >= 1, Errors.LP_INVALIED_NFT_AMOUNT);
    _nftTotalCollateral[loan.nftAsset] -= 1;

    // burn bNFT and transfer underlying NFT asset to user
    IBNFT(bNftAddress).burn(loan.nftTokenId);

    IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), _msgSender(), loan.nftTokenId);

    emit LoanLiquidated(
      initiator,
      loanId,
      loan.nftAsset,
      loan.nftTokenId,
      loan.reserveAsset,
      borrowAmount,
      borrowIndex
    );
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external pure override returns (bytes4) {
    operator;
    from;
    tokenId;
    data;
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  function borrowerOf(uint256 loanId) external view override returns (address) {
    return _loans[loanId].borrower;
  }

  function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view override returns (uint256) {
    return _nftToLoanIds[nftAsset][nftTokenId];
  }

  function getLoan(uint256 loanId) external view override returns (DataTypes.LoanData memory loanData) {
    return _loans[loanId];
  }

  function getLoanCollateralAndReserve(uint256 loanId)
    external
    view
    override
    returns (
      address nftAsset,
      uint256 nftTokenId,
      address reserveAsset,
      uint256 scaledAmount
    )
  {
    return (
      _loans[loanId].nftAsset,
      _loans[loanId].nftTokenId,
      _loans[loanId].reserveAsset,
      _loans[loanId].scaledAmount
    );
  }

  function getLoanReserveBorrowAmount(uint256 loanId) external view override returns (address, uint256) {
    uint256 scaledAmount = _loans[loanId].scaledAmount;
    if (scaledAmount == 0) {
      return (_loans[loanId].reserveAsset, 0);
    }
    uint256 amount = scaledAmount.rayMul(_getLendPool().getReserveNormalizedVariableDebt(_loans[loanId].reserveAsset));

    return (_loans[loanId].reserveAsset, amount);
  }

  function getLoanReserveBorrowScaledAmount(uint256 loanId) external view override returns (address, uint256) {
    return (_loans[loanId].reserveAsset, _loans[loanId].scaledAmount);
  }

  function getLoanHighestBid(uint256 loanId) external view override returns (address, uint256) {
    return (_loans[loanId].bidderAddress, _loans[loanId].bidPrice);
  }

  function getNftCollateralAmount(address nftAsset) external view override returns (uint256) {
    return _nftTotalCollateral[nftAsset];
  }

  function getUserNftCollateralAmount(address user, address nftAsset) external view override returns (uint256) {
    return _userNftCollateral[user][nftAsset];
  }

  function _getLendPool() internal view returns (ILendPool) {
    return ILendPool(_addressesProvider.getLendPool());
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title WadRayMath library
 * @author Bend
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @return One wad, 1e18
   **/

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return HALF_RAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return HALF_WAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - HALF_WAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + HALF_WAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / WAD, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }

    require(a <= (type(uint256).max - HALF_RAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + HALF_RAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
    uint256 halfB = b / 2;

    require(a <= (type(uint256).max - halfB) / RAY, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    require(result >= halfRatio, Errors.MATH_ADDITION_OVERFLOW);

    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    require(result / WAD_RAY_RATIO == a, Errors.MATH_MULTIPLICATION_OVERFLOW);
    return result;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IBToken} from "../interfaces/IBToken.sol";
import {IDebtToken} from "../interfaces/IDebtToken.sol";
import {ILendPoolLoan} from "../interfaces/ILendPoolLoan.sol";
import {ILendPoolLiquidator} from "../interfaces/ILendPoolLiquidator.sol";
import {INFTOracleGetter} from "../interfaces/INFTOracleGetter.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {GenericLogic} from "../libraries/logic/GenericLogic.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {NftLogic} from "../libraries/logic/NftLogic.sol";
import {ValidationLogic} from "../libraries/logic/ValidationLogic.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../libraries/configuration/NftConfiguration.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {LendPoolStorage} from "./LendPoolStorage.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title LendPoolLiquidator contract
 * @dev Implements the actions involving management of liquidation in the Bend Protocol
 * - Users can:
 *   # Auction
 *   # Redeem
 *   # Liquidate
 * IMPORTANT This contract will run always via DELEGATECALL, through the LendPool, so the chain of inheritance
 * is the same as the LendPool, to have compatible storage layouts
 * @author Bend
 **/
contract LendPoolLiquidator is Initializable, ILendPoolLiquidator, LendPoolStorage, ContextUpgradeable {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ReserveLogic for DataTypes.ReserveData;
  using NftLogic for DataTypes.NftData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  struct AuctionLocalVars {
    address loanAddress;
    address initiator;
    uint256 loanId;
    uint256 thresholdPrice;
    uint256 liquidatePrice;
    uint256 borrowAmount;
    uint256 auctionEndTimestamp;
    uint256 minBidDelta;
  }

  /**
   * @dev Function to auction a non-healthy position collateral-wise
   * - The bidder want to buy collateral asset of the user getting liquidated
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param bidPrice The bid price of the bidder want to buy underlying NFT
   * @param onBehalfOf Address of the user who will get the underlying NFT, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of NFT
   *   is a different wallet
   **/
  function auction(
    address nftAsset,
    uint256 nftTokenId,
    uint256 bidPrice,
    address onBehalfOf
  ) external override {
    require(onBehalfOf != address(0), Errors.VL_INVALID_ONBEHALFOF_ADDRESS);

    AuctionLocalVars memory vars;
    vars.initiator = _msgSender();

    vars.loanAddress = _addressesProvider.getLendPoolLoan();
    vars.loanId = ILendPoolLoan(vars.loanAddress).getCollateralLoanId(nftAsset, nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.loanAddress).getLoan(vars.loanId);

    DataTypes.ReserveData storage reserveData = _reserves[loanData.reserveAsset];
    DataTypes.NftData storage nftData = _nfts[loanData.nftAsset];

    ValidationLogic.validateAuction(reserveData, nftData, loanData, bidPrice);

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();

    (vars.borrowAmount, vars.thresholdPrice, vars.liquidatePrice) = GenericLogic.calculateLoanLiquidatePrice(
      vars.loanId,
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      nftData,
      vars.loanAddress,
      _addressesProvider.getReserveOracle(),
      _addressesProvider.getNFTOracle()
    );

    // first time bid need to burn debt tokens and transfer reserve to bTokens
    if (loanData.state == DataTypes.LoanState.Active) {
      // loan's accumulated debt must exceed threshold (heath factor below 1.0)
      require(vars.borrowAmount > vars.thresholdPrice, Errors.LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD);

      // bid price must greater than liquidate price
      require(bidPrice >= vars.liquidatePrice, Errors.LPL_BID_PRICE_LESS_THAN_LIQUIDATION_PRICE);

      // bid price must greater than borrow debt
      require(bidPrice >= vars.borrowAmount, Errors.LPL_BID_PRICE_LESS_THAN_BORROW);
    } else {
      // bid price must greater than borrow debt
      require(bidPrice >= vars.borrowAmount, Errors.LPL_BID_PRICE_LESS_THAN_BORROW);

      vars.auctionEndTimestamp = loanData.bidStartTimestamp + (nftData.configuration.getAuctionDuration() * 1 days);
      require(block.timestamp <= vars.auctionEndTimestamp, Errors.LPL_BID_AUCTION_DURATION_HAS_END);

      // bid price must greater than highest bid + delta
      vars.minBidDelta = vars.borrowAmount.percentMul(PercentageMath.ONE_PERCENT);
      require(bidPrice >= (loanData.bidPrice + vars.minBidDelta), Errors.LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE);
    }

    ILendPoolLoan(vars.loanAddress).auctionLoan(
      vars.initiator,
      vars.loanId,
      onBehalfOf,
      bidPrice,
      vars.borrowAmount,
      reserveData.variableBorrowIndex
    );

    // lock highest bidder bid price amount to lend pool
    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(vars.initiator, address(this), bidPrice);

    // transfer (return back) last bid price amount to previous bidder from lend pool
    if (loanData.bidderAddress != address(0)) {
      IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.bidderAddress, loanData.bidPrice);
    }

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, reserveData.bTokenAddress, 0, 0);

    emit Auction(
      vars.initiator,
      loanData.reserveAsset,
      bidPrice,
      nftAsset,
      nftTokenId,
      onBehalfOf,
      loanData.borrower,
      vars.loanId
    );
  }

  struct RedeemLocalVars {
    address initiator;
    address poolLoan;
    uint256 loanId;
    uint256 borrowAmount;
    uint256 repayAmount;
    uint256 minRepayAmount;
    uint256 maxRepayAmount;
    uint256 bidFine;
    uint256 redeemEndTimestamp;
  }

  /**
   * @notice Redeem a NFT loan which state is in Auction
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   **/
  function redeem(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 bidFine
  ) external override returns (uint256) {
    RedeemLocalVars memory vars;
    vars.initiator = _msgSender();

    vars.poolLoan = _addressesProvider.getLendPoolLoan();

    vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(nftAsset, nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan).getLoan(vars.loanId);

    DataTypes.ReserveData storage reserveData = _reserves[loanData.reserveAsset];
    DataTypes.NftData storage nftData = _nfts[loanData.nftAsset];

    ValidationLogic.validateRedeem(reserveData, nftData, loanData, amount);

    vars.redeemEndTimestamp = (loanData.bidStartTimestamp + nftData.configuration.getRedeemDuration() * 1 days);
    require(block.timestamp <= vars.redeemEndTimestamp, Errors.LPL_BID_REDEEM_DURATION_HAS_END);

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();

    (vars.borrowAmount, , ) = GenericLogic.calculateLoanLiquidatePrice(
      vars.loanId,
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      nftData,
      vars.poolLoan,
      _addressesProvider.getReserveOracle(),
      _addressesProvider.getNFTOracle()
    );

    // check bid fine
    vars.bidFine = vars.borrowAmount.percentMul(nftData.configuration.getRedeemFine());
    require(vars.bidFine <= bidFine, Errors.LPL_BID_INVALID_BID_FINE);

    // check the minimum debt repay amount, use redeem threshold in config
    vars.repayAmount = amount;
    vars.minRepayAmount = vars.borrowAmount.percentMul(nftData.configuration.getRedeemThreshold());
    require(vars.repayAmount >= vars.minRepayAmount, Errors.LP_AMOUNT_LESS_THAN_REDEEM_THRESHOLD);

    // check the maxinmum debt repay amount, 90%?
    vars.maxRepayAmount = vars.borrowAmount.percentMul(PercentageMath.PERCENTAGE_FACTOR - PercentageMath.TEN_PERCENT);
    require(vars.repayAmount <= vars.maxRepayAmount, Errors.LP_AMOUNT_GREATER_THAN_MAX_REPAY);

    ILendPoolLoan(vars.poolLoan).redeemLoan(
      vars.initiator,
      vars.loanId,
      vars.repayAmount,
      reserveData.variableBorrowIndex
    );

    IDebtToken(reserveData.debtTokenAddress).burn(loanData.borrower, vars.repayAmount, reserveData.variableBorrowIndex);

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, reserveData.bTokenAddress, vars.repayAmount, 0);

    // transfer repay amount from borrower to bToken
    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
      vars.initiator,
      reserveData.bTokenAddress,
      vars.repayAmount
    );

    if (loanData.bidderAddress != address(0)) {
      // transfer (return back) last bid price amount from lend pool to bidder
      IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.bidderAddress, loanData.bidPrice);

      // transfer bid penalty fine amount from borrower to bidder
      IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(vars.initiator, loanData.bidderAddress, vars.bidFine);
    }

    emit Redeem(
      vars.initiator,
      loanData.reserveAsset,
      vars.repayAmount,
      vars.bidFine,
      loanData.nftAsset,
      loanData.nftTokenId,
      loanData.borrower,
      vars.loanId
    );

    return (vars.repayAmount + vars.bidFine);
  }

  struct LiquidateLocalVars {
    address poolLoan;
    address initiator;
    uint256 loanId;
    uint256 borrowAmount;
    uint256 extraDebtAmount;
    uint256 remainAmount;
    uint256 auctionEndTimestamp;
  }

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The bidder buy collateral asset of the user getting liquidated, and receives
   *   the collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidate(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) external override returns (uint256) {
    LiquidateLocalVars memory vars;
    vars.initiator = _msgSender();

    vars.poolLoan = _addressesProvider.getLendPoolLoan();

    vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(nftAsset, nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan).getLoan(vars.loanId);

    DataTypes.ReserveData storage reserveData = _reserves[loanData.reserveAsset];
    DataTypes.NftData storage nftData = _nfts[loanData.nftAsset];

    ValidationLogic.validateLiquidate(reserveData, nftData, loanData);

    vars.auctionEndTimestamp = loanData.bidStartTimestamp + (nftData.configuration.getAuctionDuration() * 1 days);
    require(block.timestamp > vars.auctionEndTimestamp, Errors.LPL_BID_AUCTION_DURATION_NOT_END);

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();

    (vars.borrowAmount, , ) = GenericLogic.calculateLoanLiquidatePrice(
      vars.loanId,
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      nftData,
      vars.poolLoan,
      _addressesProvider.getReserveOracle(),
      _addressesProvider.getNFTOracle()
    );

    // Last bid price can not cover borrow amount
    if (loanData.bidPrice < vars.borrowAmount) {
      vars.extraDebtAmount = vars.borrowAmount - loanData.bidPrice;
      require(amount >= vars.extraDebtAmount, Errors.LP_AMOUNT_LESS_THAN_EXTRA_DEBT);
    }

    if (loanData.bidPrice > vars.borrowAmount) {
      vars.remainAmount = loanData.bidPrice - vars.borrowAmount;
    }

    ILendPoolLoan(vars.poolLoan).liquidateLoan(
      loanData.bidderAddress,
      vars.loanId,
      nftData.bNftAddress,
      vars.borrowAmount,
      reserveData.variableBorrowIndex
    );

    IDebtToken(reserveData.debtTokenAddress).burn(
      loanData.borrower,
      vars.borrowAmount,
      reserveData.variableBorrowIndex
    );

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, reserveData.bTokenAddress, vars.borrowAmount, 0);

    // transfer extra borrow amount from liquidator to lend pool
    if (vars.extraDebtAmount > 0) {
      IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(vars.initiator, address(this), vars.extraDebtAmount);
    }

    // transfer borrow amount from lend pool to bToken, repay debt
    IERC20Upgradeable(loanData.reserveAsset).safeTransfer(reserveData.bTokenAddress, vars.borrowAmount);

    // transfer remain amount to borrower
    if (vars.remainAmount > 0) {
      IERC20Upgradeable(loanData.reserveAsset).safeTransfer(loanData.borrower, vars.remainAmount);
    }

    // transfer erc721 to bidder
    IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(address(this), loanData.bidderAddress, nftTokenId);

    emit Liquidate(
      vars.initiator,
      loanData.reserveAsset,
      vars.borrowAmount,
      vars.remainAmount,
      loanData.nftAsset,
      loanData.nftTokenId,
      loanData.borrower,
      vars.loanId
    );

    return (vars.extraDebtAmount);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface ILendPoolLiquidator {
  // Following events copy from LendPool
  /**
   * @dev Emitted when a borrower's loan is auctioned.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param bidPrice The price of the underlying reserve given by the bidder
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param onBehalfOf The address that will be getting the NFT
   * @param loanId The loan ID of the NFT loans
   **/
  event Auction(
    address user,
    address indexed reserve,
    uint256 bidPrice,
    address indexed nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted on redeem()
   * @param user The address of the user initiating the redeem(), providing the funds
   * @param reserve The address of the underlying asset of the reserve
   * @param borrowAmount The borrow amount repaid
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token id of the underlying NFT used as collateral
   * @param loanId The loan ID of the NFT loans
   **/
  event Redeem(
    address user,
    address indexed reserve,
    uint256 borrowAmount,
    uint256 fineAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Emitted when a borrower's loan is liquidated.
   * @param user The address of the user initiating the auction
   * @param reserve The address of the underlying asset of the reserve
   * @param repayAmount The amount of reserve repaid by the liquidator
   * @param remainAmount The amount of reserve received by the borrower
   * @param loanId The loan ID of the NFT loans
   **/
  event Liquidate(
    address user,
    address indexed reserve,
    uint256 repayAmount,
    uint256 remainAmount,
    address indexed nftAsset,
    uint256 nftTokenId,
    address indexed borrower,
    uint256 loanId
  );

  /**
   * @dev Function to auction a non-healthy position collateral-wise
   * - The caller (liquidator) want to buy collateral asset of the user getting liquidated
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param bidPrice The bid price of the liquidator want to buy the underlying NFT
   * @param onBehalfOf Address of the user who will get the underlying NFT, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of NFT
   *   is a different wallet
   **/
  function auction(
    address nftAsset,
    uint256 nftTokenId,
    uint256 bidPrice,
    address onBehalfOf
  ) external;

  /**
   * @notice Redeem a NFT loan which state is in Auction
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   **/
  function redeem(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 bidFine
  ) external returns (uint256);

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The caller (liquidator) buy collateral asset of the user getting liquidated, and receives
   *   the collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidate(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/************
@title INFTOracleGetter interface
@notice Interface for getting NFT price oracle.*/
interface INFTOracleGetter {
  /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
  /***********
    @dev returns the asset price in ETH
     */
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolLoan} from "../../interfaces/ILendPoolLoan.sol";
import {IReserveOracleGetter} from "../../interfaces/IReserveOracleGetter.sol";
import {INFTOracleGetter} from "../../interfaces/INFTOracleGetter.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../configuration/NftConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveLogic} from "./ReserveLogic.sol";

/**
 * @title GenericLogic library
 * @author Bend
 * @notice Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1 ether;

  struct CalculateLoanDataVars {
    uint256 reserveUnitPrice;
    uint256 reserveUnit;
    uint256 reserveDecimals;
    uint256 healthFactor;
    uint256 totalCollateralInETH;
    uint256 totalCollateralInReserve;
    uint256 totalDebtInETH;
    uint256 totalDebtInReserve;
    uint256 nftLtv;
    uint256 nftLiquidationThreshold;
    address nftAsset;
    uint256 nftTokenId;
    uint256 nftUnitPrice;
  }

  /**
   * @dev Calculates the nft loan data.
   * this includes the total collateral/borrow balances in Reserve,
   * the Loan To Value, the Liquidation Ratio, and the Health factor.
   * @param reserveData Data of the reserve
   * @param nftData Data of the nft
   * @param reserveOracle The price oracle address of reserve
   * @param nftOracle The price oracle address of nft
   * @return The total collateral and total debt of the loan in Reserve, the ltv, liquidation threshold and the HF
   **/
  function calculateLoanData(
    address reserveAddress,
    DataTypes.ReserveData storage reserveData,
    address nftAddress,
    DataTypes.NftData storage nftData,
    address loanAddress,
    uint256 loanId,
    address reserveOracle,
    address nftOracle
  )
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    CalculateLoanDataVars memory vars;

    (vars.nftLtv, vars.nftLiquidationThreshold, ) = nftData.configuration.getCollateralParams();

    // calculate total borrow balance for the loan
    if (loanId != 0) {
      (vars.totalDebtInETH, vars.totalDebtInReserve) = calculateNftDebtData(
        reserveAddress,
        reserveData,
        loanAddress,
        loanId,
        reserveOracle
      );
    }

    // calculate total collateral balance for the nft
    (vars.totalCollateralInETH, vars.totalCollateralInReserve) = calculateNftCollateralData(
      reserveAddress,
      reserveData,
      nftAddress,
      nftData,
      reserveOracle,
      nftOracle
    );

    // calculate health by borrow and collateral
    vars.healthFactor = calculateHealthFactorFromBalances(
      vars.totalCollateralInReserve,
      vars.totalDebtInReserve,
      vars.nftLiquidationThreshold
    );

    return (vars.totalCollateralInReserve, vars.totalDebtInReserve, vars.healthFactor);
  }

  function calculateNftDebtData(
    address reserveAddress,
    DataTypes.ReserveData storage reserveData,
    address loanAddress,
    uint256 loanId,
    address reserveOracle
  ) internal view returns (uint256, uint256) {
    CalculateLoanDataVars memory vars;

    // all asset price has converted to ETH based, unit is in WEI (18 decimals)

    vars.reserveDecimals = reserveData.configuration.getDecimals();
    vars.reserveUnit = 10**vars.reserveDecimals;

    vars.reserveUnitPrice = IReserveOracleGetter(reserveOracle).getAssetPrice(reserveAddress);

    (, vars.totalDebtInReserve) = ILendPoolLoan(loanAddress).getLoanReserveBorrowAmount(loanId);
    vars.totalDebtInETH = (vars.totalDebtInReserve * vars.reserveUnitPrice) / vars.reserveUnit;

    return (vars.totalDebtInETH, vars.totalDebtInReserve);
  }

  function calculateNftCollateralData(
    address reserveAddress,
    DataTypes.ReserveData storage reserveData,
    address nftAddress,
    DataTypes.NftData storage nftData,
    address reserveOracle,
    address nftOracle
  ) internal view returns (uint256, uint256) {
    reserveData;
    nftData;

    CalculateLoanDataVars memory vars;

    // calculate total collateral balance for the nft
    // all asset price has converted to ETH based, unit is in WEI (18 decimals)

    vars.nftUnitPrice = INFTOracleGetter(nftOracle).getAssetPrice(nftAddress);
    vars.totalCollateralInETH = vars.nftUnitPrice;

    if (reserveAddress != address(0)) {
      vars.reserveDecimals = reserveData.configuration.getDecimals();
      vars.reserveUnit = 10**vars.reserveDecimals;

      vars.reserveUnitPrice = IReserveOracleGetter(reserveOracle).getAssetPrice(reserveAddress);

      vars.totalCollateralInReserve = (vars.totalCollateralInETH * vars.reserveUnit) / vars.reserveUnitPrice;
    }

    return (vars.totalCollateralInETH, vars.totalCollateralInReserve);
  }

  /**
   * @dev Calculates the health factor from the corresponding balances
   * @param totalCollateral The total collateral
   * @param totalDebt The total debt
   * @param liquidationThreshold The avg liquidation threshold
   * @return The health factor calculated from the balances provided
   **/
  function calculateHealthFactorFromBalances(
    uint256 totalCollateral,
    uint256 totalDebt,
    uint256 liquidationThreshold
  ) internal pure returns (uint256) {
    if (totalDebt == 0) return type(uint256).max;

    return (totalCollateral.percentMul(liquidationThreshold)).wadDiv(totalDebt);
  }

  /**
   * @dev Calculates the equivalent amount that an user can borrow, depending on the available collateral and the
   * average Loan To Value
   * @param totalCollateral The total collateral
   * @param totalDebt The total borrow balance
   * @param ltv The average loan to value
   * @return the amount available to borrow for the user
   **/

  function calculateAvailableBorrows(
    uint256 totalCollateral,
    uint256 totalDebt,
    uint256 ltv
  ) internal pure returns (uint256) {
    uint256 availableBorrows = totalCollateral.percentMul(ltv);

    if (availableBorrows < totalDebt) {
      return 0;
    }

    availableBorrows = availableBorrows - totalDebt;
    return availableBorrows;
  }

  struct CalcLiquidatePriceLocalVars {
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 nftPriceInETH;
    uint256 nftPriceInReserve;
    uint256 reserveDecimals;
    uint256 reservePriceInETH;
    uint256 thresholdPrice;
    uint256 liquidatePrice;
    uint256 borrowAmount;
  }

  function calculateLoanLiquidatePrice(
    uint256 loanId,
    address reserveAsset,
    DataTypes.ReserveData storage reserveData,
    address nftAsset,
    DataTypes.NftData storage nftData,
    address poolLoan,
    address reserveOracle,
    address nftOracle
  )
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    CalcLiquidatePriceLocalVars memory vars;

    /*
     * 0                   CR                  LH                  100
     * |___________________|___________________|___________________|
     *  <       Borrowing with Interest        <
     * CR: Callteral Ratio;
     * LH: Liquidate Threshold;
     * Liquidate Trigger: Borrowing with Interest > thresholdPrice;
     * Liquidate Price: (100% - BonusRatio) * NFT Price;
     */

    vars.reserveDecimals = reserveData.configuration.getDecimals();

    (, vars.borrowAmount) = ILendPoolLoan(poolLoan).getLoanReserveBorrowAmount(loanId);

    (vars.ltv, vars.liquidationThreshold, vars.liquidationBonus) = nftData.configuration.getCollateralParams();

    vars.nftPriceInETH = INFTOracleGetter(nftOracle).getAssetPrice(nftAsset);
    vars.reservePriceInETH = IReserveOracleGetter(reserveOracle).getAssetPrice(reserveAsset);

    vars.nftPriceInReserve = ((10**vars.reserveDecimals) * vars.nftPriceInETH) / vars.reservePriceInETH;

    vars.thresholdPrice = vars.nftPriceInReserve.percentMul(vars.liquidationThreshold);

    vars.liquidatePrice = vars.nftPriceInReserve.percentMul(PercentageMath.PERCENTAGE_FACTOR - vars.liquidationBonus);

    return (vars.borrowAmount, vars.thresholdPrice, vars.liquidatePrice);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IBToken} from "../../interfaces/IBToken.sol";
import {IDebtToken} from "../../interfaces/IDebtToken.sol";
import {IInterestRate} from "../../interfaces/IInterestRate.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {MathUtils} from "../math/MathUtils.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title ReserveLogic library
 * @author Bend
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /**
   * @dev Emitted when the state of a reserve is updated
   * @param asset The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed asset,
    uint256 liquidityRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  /**
   * @dev Returns the ongoing normalized income for the reserve
   * A value of 1e27 means there is no income. As time passes, the income is accrued
   * A value of 2*1e27 means for each unit of asset one unit of income has been accrued
   * @param reserve The reserve object
   * @return the normalized income. expressed in ray
   **/
  function getNormalizedIncome(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == uint40(block.timestamp)) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.liquidityIndex;
    }

    uint256 cumulated = MathUtils.calculateLinearInterest(reserve.currentLiquidityRate, timestamp).rayMul(
      reserve.liquidityIndex
    );

    return cumulated;
  }

  /**
   * @dev Returns the ongoing normalized variable debt for the reserve
   * A value of 1e27 means there is no debt. As time passes, the income is accrued
   * A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
   * @param reserve The reserve object
   * @return The normalized variable debt. expressed in ray
   **/
  function getNormalizedDebt(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == uint40(block.timestamp)) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.variableBorrowIndex;
    }

    uint256 cumulated = MathUtils.calculateCompoundedInterest(reserve.currentVariableBorrowRate, timestamp).rayMul(
      reserve.variableBorrowIndex
    );

    return cumulated;
  }

  /**
   * @dev Updates the liquidity cumulative index and the variable borrow index.
   * @param reserve the reserve object
   **/
  function updateState(DataTypes.ReserveData storage reserve) internal {
    uint256 scaledVariableDebt = IDebtToken(reserve.debtTokenAddress).scaledTotalSupply();
    uint256 previousVariableBorrowIndex = reserve.variableBorrowIndex;
    uint256 previousLiquidityIndex = reserve.liquidityIndex;
    uint40 lastUpdatedTimestamp = reserve.lastUpdateTimestamp;

    (uint256 newLiquidityIndex, uint256 newVariableBorrowIndex) = _updateIndexes(
      reserve,
      scaledVariableDebt,
      previousLiquidityIndex,
      previousVariableBorrowIndex,
      lastUpdatedTimestamp
    );

    _mintToTreasury(
      reserve,
      scaledVariableDebt,
      previousVariableBorrowIndex,
      newLiquidityIndex,
      newVariableBorrowIndex,
      lastUpdatedTimestamp
    );
  }

  /**
   * @dev Accumulates a predefined amount of asset to the reserve as a fixed, instantaneous income. Used for example to accumulate
   * the flashloan fee to the reserve, and spread it between all the depositors
   * @param reserve The reserve object
   * @param totalLiquidity The total liquidity available in the reserve
   * @param amount The amount to accomulate
   **/
  function cumulateToLiquidityIndex(
    DataTypes.ReserveData storage reserve,
    uint256 totalLiquidity,
    uint256 amount
  ) internal {
    uint256 amountToLiquidityRatio = amount.wadToRay().rayDiv(totalLiquidity.wadToRay());

    uint256 result = amountToLiquidityRatio + (WadRayMath.ray());

    result = result.rayMul(reserve.liquidityIndex);
    require(result <= type(uint128).max, Errors.RL_LIQUIDITY_INDEX_OVERFLOW);

    reserve.liquidityIndex = uint128(result);
  }

  /**
   * @dev Initializes a reserve
   * @param reserve The reserve object
   * @param bTokenAddress The address of the overlying bToken contract
   * @param debtTokenAddress The address of the overlying debtToken contract
   * @param interestRateAddress The address of the interest rate strategy contract
   **/
  function init(
    DataTypes.ReserveData storage reserve,
    address bTokenAddress,
    address debtTokenAddress,
    address interestRateAddress
  ) external {
    require(reserve.bTokenAddress == address(0), Errors.RL_RESERVE_ALREADY_INITIALIZED);

    reserve.liquidityIndex = uint128(WadRayMath.ray());
    reserve.variableBorrowIndex = uint128(WadRayMath.ray());
    reserve.bTokenAddress = bTokenAddress;
    reserve.debtTokenAddress = debtTokenAddress;
    reserve.interestRateAddress = interestRateAddress;
  }

  struct UpdateInterestRatesLocalVars {
    uint256 availableLiquidity;
    uint256 newLiquidityRate;
    uint256 newVariableRate;
    uint256 totalVariableDebt;
  }

  /**
   * @dev Updates the reserve current stable borrow rate, the current variable borrow rate and the current liquidity rate
   * @param reserve The address of the reserve to be updated
   * @param liquidityAdded The amount of liquidity added to the protocol (deposit or repay) in the previous action
   * @param liquidityTaken The amount of liquidity taken from the protocol (withdraw or borrow)
   **/
  function updateInterestRates(
    DataTypes.ReserveData storage reserve,
    address reserveAddress,
    address bTokenAddress,
    uint256 liquidityAdded,
    uint256 liquidityTaken
  ) internal {
    UpdateInterestRatesLocalVars memory vars;

    //calculates the total variable debt locally using the scaled borrow amount instead
    //of borrow amount(), as it's noticeably cheaper. Also, the index has been
    //updated by the previous updateState() call
    vars.totalVariableDebt = IDebtToken(reserve.debtTokenAddress).scaledTotalSupply().rayMul(
      reserve.variableBorrowIndex
    );

    (vars.newLiquidityRate, vars.newVariableRate) = IInterestRate(reserve.interestRateAddress).calculateInterestRates(
      reserveAddress,
      bTokenAddress,
      liquidityAdded,
      liquidityTaken,
      vars.totalVariableDebt,
      reserve.configuration.getReserveFactor()
    );
    require(vars.newLiquidityRate <= type(uint128).max, Errors.RL_LIQUIDITY_RATE_OVERFLOW);
    require(vars.newVariableRate <= type(uint128).max, Errors.RL_VARIABLE_BORROW_RATE_OVERFLOW);

    reserve.currentLiquidityRate = uint128(vars.newLiquidityRate);
    reserve.currentVariableBorrowRate = uint128(vars.newVariableRate);

    emit ReserveDataUpdated(
      reserveAddress,
      vars.newLiquidityRate,
      vars.newVariableRate,
      reserve.liquidityIndex,
      reserve.variableBorrowIndex
    );
  }

  struct MintToTreasuryLocalVars {
    uint256 currentVariableDebt;
    uint256 previousVariableDebt;
    uint256 totalDebtAccrued;
    uint256 amountToMint;
    uint256 reserveFactor;
  }

  /**
   * @dev Mints part of the repaid interest to the reserve treasury as a function of the reserveFactor for the
   * specific asset.
   * @param reserve The reserve reserve to be updated
   * @param scaledVariableDebt The current scaled total variable debt
   * @param previousVariableBorrowIndex The variable borrow index before the last accumulation of the interest
   * @param newLiquidityIndex The new liquidity index
   * @param newVariableBorrowIndex The variable borrow index after the last accumulation of the interest
   **/
  function _mintToTreasury(
    DataTypes.ReserveData storage reserve,
    uint256 scaledVariableDebt,
    uint256 previousVariableBorrowIndex,
    uint256 newLiquidityIndex,
    uint256 newVariableBorrowIndex,
    uint40 timestamp
  ) internal {
    timestamp;
    MintToTreasuryLocalVars memory vars;

    vars.reserveFactor = reserve.configuration.getReserveFactor();

    if (vars.reserveFactor == 0) {
      return;
    }

    //calculate the last principal variable debt
    vars.previousVariableDebt = scaledVariableDebt.rayMul(previousVariableBorrowIndex);

    //calculate the new total supply after accumulation of the index
    vars.currentVariableDebt = scaledVariableDebt.rayMul(newVariableBorrowIndex);

    //debt accrued is the sum of the current debt minus the sum of the debt at the last update
    vars.totalDebtAccrued = vars.currentVariableDebt - (vars.previousVariableDebt);

    vars.amountToMint = vars.totalDebtAccrued.percentMul(vars.reserveFactor);

    if (vars.amountToMint != 0) {
      IBToken(reserve.bTokenAddress).mintToTreasury(vars.amountToMint, newLiquidityIndex);
    }
  }

  /**
   * @dev Updates the reserve indexes and the timestamp of the update
   * @param reserve The reserve reserve to be updated
   * @param scaledVariableDebt The scaled variable debt
   * @param liquidityIndex The last stored liquidity index
   * @param variableBorrowIndex The last stored variable borrow index
   **/
  function _updateIndexes(
    DataTypes.ReserveData storage reserve,
    uint256 scaledVariableDebt,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex,
    uint40 timestamp
  ) internal returns (uint256, uint256) {
    uint256 currentLiquidityRate = reserve.currentLiquidityRate;

    uint256 newLiquidityIndex = liquidityIndex;
    uint256 newVariableBorrowIndex = variableBorrowIndex;

    //only cumulating if there is any income being produced
    if (currentLiquidityRate > 0) {
      uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(currentLiquidityRate, timestamp);
      newLiquidityIndex = cumulatedLiquidityInterest.rayMul(liquidityIndex);
      require(newLiquidityIndex <= type(uint128).max, Errors.RL_LIQUIDITY_INDEX_OVERFLOW);

      reserve.liquidityIndex = uint128(newLiquidityIndex);

      //as the liquidity rate might come only from stable rate loans, we need to ensure
      //that there is actual variable debt before accumulating
      if (scaledVariableDebt != 0) {
        uint256 cumulatedVariableBorrowInterest = MathUtils.calculateCompoundedInterest(
          reserve.currentVariableBorrowRate,
          timestamp
        );
        newVariableBorrowIndex = cumulatedVariableBorrowInterest.rayMul(variableBorrowIndex);
        require(newVariableBorrowIndex <= type(uint128).max, Errors.RL_VARIABLE_BORROW_INDEX_OVERFLOW);
        reserve.variableBorrowIndex = uint128(newVariableBorrowIndex);
      }
    }

    //solium-disable-next-line
    reserve.lastUpdateTimestamp = uint40(block.timestamp);
    return (newLiquidityIndex, newVariableBorrowIndex);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title NftLogic library
 * @author Bend
 * @notice Implements the logic to update the nft state
 */
library NftLogic {
  /**
   * @dev Initializes a nft
   * @param nft The nft object
   * @param bNftAddress The address of the bNFT contract
   **/
  function init(DataTypes.NftData storage nft, address bNftAddress) external {
    require(nft.bNftAddress == address(0), Errors.RL_RESERVE_ALREADY_INITIALIZED);

    nft.bNftAddress = bNftAddress;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ReserveLogic} from "./ReserveLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../configuration/NftConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {IInterestRate} from "../../interfaces/IInterestRate.sol";
import {ILendPoolLoan} from "../../interfaces/ILendPoolLoan.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title ValidationLogic library
 * @author Bend
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  /**
   * @dev Validates a deposit action
   * @param reserve The reserve object on which the user is depositing
   * @param amount The amount to be deposited
   */
  function validateDeposit(DataTypes.ReserveData storage reserve, uint256 amount) external view {
    (bool isActive, bool isFrozen, , ) = reserve.configuration.getFlags();

    require(amount != 0, Errors.VL_INVALID_AMOUNT);
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
    require(!isFrozen, Errors.VL_RESERVE_FROZEN);
  }

  /**
   * @dev Validates a withdraw action
   * @param reserveData The reserve state
   * @param amount The amount to be withdrawn
   * @param userBalance The balance of the user
   */
  function validateWithdraw(
    DataTypes.ReserveData storage reserveData,
    uint256 amount,
    uint256 userBalance
  ) external view {
    require(amount != 0, Errors.VL_INVALID_AMOUNT);
    require(amount <= userBalance, Errors.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE);

    (bool isActive, , , ) = reserveData.configuration.getFlags();
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
  }

  struct ValidateBorrowLocalVars {
    uint256 currentLtv;
    uint256 currentLiquidationThreshold;
    uint256 amountOfCollateralNeeded;
    uint256 userCollateralBalance;
    uint256 userBorrowBalance;
    uint256 availableLiquidity;
    uint256 healthFactor;
    bool isActive;
    bool isFrozen;
    bool borrowingEnabled;
    bool stableRateBorrowingEnabled;
    bool nftIsActive;
    bool nftIsFrozen;
    address loanReserveAsset;
    address loanBorrower;
  }

  /**
   * @dev Validates a borrow action
   * @param reserveAsset The address of the asset to borrow
   * @param amount The amount to be borrowed
   * @param reserveData The reserve state from which the user is borrowing
   * @param nftData The state of the user for the specific nft
   */
  function validateBorrow(
    address user,
    address reserveAsset,
    uint256 amount,
    DataTypes.ReserveData storage reserveData,
    address nftAsset,
    DataTypes.NftData storage nftData,
    address loanAddress,
    uint256 loanId,
    address reserveOracle,
    address nftOracle
  ) external view {
    ValidateBorrowLocalVars memory vars;

    require(reserveData.bTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);
    require(nftData.bNftAddress != address(0), Errors.LPC_INVALIED_BNFT_ADDRESS);
    require(amount > 0, Errors.VL_INVALID_AMOUNT);

    if (loanId != 0) {
      DataTypes.LoanData memory loanData = ILendPoolLoan(loanAddress).getLoan(loanId);

      require(loanData.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);
      require(reserveAsset == loanData.reserveAsset, Errors.VL_SPECIFIED_RESERVE_NOT_BORROWED_BY_USER);
      require(user == loanData.borrower, Errors.VL_SPECIFIED_LOAN_NOT_BORROWED_BY_USER);
    }

    (vars.isActive, vars.isFrozen, vars.borrowingEnabled, vars.stableRateBorrowingEnabled) = reserveData
      .configuration
      .getFlags();
    require(vars.isActive, Errors.VL_NO_ACTIVE_RESERVE);
    require(!vars.isFrozen, Errors.VL_RESERVE_FROZEN);
    require(vars.borrowingEnabled, Errors.VL_BORROWING_NOT_ENABLED);

    (vars.nftIsActive, vars.nftIsFrozen) = nftData.configuration.getFlags();
    require(vars.nftIsActive, Errors.VL_NO_ACTIVE_NFT);
    require(!vars.nftIsFrozen, Errors.VL_NFT_FROZEN);

    (vars.currentLtv, vars.currentLiquidationThreshold, ) = nftData.configuration.getCollateralParams();

    (vars.userCollateralBalance, vars.userBorrowBalance, vars.healthFactor) = GenericLogic.calculateLoanData(
      reserveAsset,
      reserveData,
      nftAsset,
      nftData,
      loanAddress,
      loanId,
      reserveOracle,
      nftOracle
    );

    require(vars.userCollateralBalance > 0, Errors.VL_COLLATERAL_BALANCE_IS_0);

    require(
      vars.healthFactor > GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    );

    //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
    //LTV is calculated in percentage
    vars.amountOfCollateralNeeded = (vars.userBorrowBalance + amount).percentDiv(vars.currentLtv);

    require(vars.amountOfCollateralNeeded <= vars.userCollateralBalance, Errors.VL_COLLATERAL_CANNOT_COVER_NEW_BORROW);
  }

  /**
   * @dev Validates a repay action
   * @param reserveData The reserve state from which the user is repaying
   * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
   * @param borrowAmount The borrow balance of the user
   */
  function validateRepay(
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.LoanData memory loanData,
    uint256 amountSent,
    uint256 borrowAmount
  ) external view {
    require(nftData.bNftAddress != address(0), Errors.LPC_INVALIED_BNFT_ADDRESS);
    require(reserveData.bTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    require(reserveData.configuration.getActive(), Errors.VL_NO_ACTIVE_RESERVE);

    require(nftData.configuration.getActive(), Errors.VL_NO_ACTIVE_NFT);

    require(amountSent > 0, Errors.VL_INVALID_AMOUNT);

    require(borrowAmount > 0, Errors.VL_NO_DEBT_OF_SELECTED_TYPE);

    require(loanData.state == DataTypes.LoanState.Active, Errors.LPL_INVALID_LOAN_STATE);
  }

  /**
   * @dev Validates the auction action
   * @param reserveData The reserve data of the principal
   * @param nftData The nft data of the underlying nft
   * @param bidPrice Total variable debt balance of the user
   **/
  function validateAuction(
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.LoanData memory loanData,
    uint256 bidPrice
  ) internal view {
    require(nftData.bNftAddress != address(0), Errors.LPC_INVALIED_BNFT_ADDRESS);
    require(reserveData.bTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    require(reserveData.configuration.getActive(), Errors.VL_NO_ACTIVE_RESERVE);

    require(nftData.configuration.getActive(), Errors.VL_NO_ACTIVE_NFT);

    require(
      loanData.state == DataTypes.LoanState.Active || loanData.state == DataTypes.LoanState.Auction,
      Errors.LPL_INVALID_LOAN_STATE
    );

    require(bidPrice > 0, Errors.VL_INVALID_AMOUNT);
  }

  /**
   * @dev Validates a redeem action
   * @param reserveData The reserve state
   * @param nftData The nft state
   */
  function validateRedeem(
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.LoanData memory loanData,
    uint256 amount
  ) external view {
    require(nftData.bNftAddress != address(0), Errors.LPC_INVALIED_BNFT_ADDRESS);
    require(reserveData.bTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    require(reserveData.configuration.getActive(), Errors.VL_NO_ACTIVE_RESERVE);

    require(nftData.configuration.getActive(), Errors.VL_NO_ACTIVE_NFT);

    require(loanData.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);

    require(loanData.bidderAddress != address(0), Errors.LPL_INVALID_BIDDER_ADDRESS);

    require(amount > 0, Errors.VL_INVALID_AMOUNT);
  }

  /**
   * @dev Validates the liquidation action
   * @param reserveData The reserve data of the principal
   * @param nftData The data of the underlying NFT
   * @param loanData The loan data of the underlying NFT
   **/
  function validateLiquidate(
    DataTypes.ReserveData storage reserveData,
    DataTypes.NftData storage nftData,
    DataTypes.LoanData memory loanData
  ) internal view {
    require(nftData.bNftAddress != address(0), Errors.LPC_INVALIED_BNFT_ADDRESS);
    require(reserveData.bTokenAddress != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    require(reserveData.configuration.getActive(), Errors.VL_NO_ACTIVE_RESERVE);

    require(nftData.configuration.getActive(), Errors.VL_NO_ACTIVE_NFT);

    require(loanData.state == DataTypes.LoanState.Auction, Errors.LPL_INVALID_LOAN_STATE);

    require(loanData.bidderAddress != address(0), Errors.LPL_INVALID_BIDDER_ADDRESS);
  }

  /**
   * @dev Validates an bToken transfer
   * @param from The user from which the bTokens are being transferred
   * @param reserveData The state of the reserve
   */
  function validateTransfer(address from, DataTypes.ReserveData storage reserveData) internal pure {
    from;
    reserveData;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {DataTypes} from "../libraries/types/DataTypes.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {NftLogic} from "../libraries/logic/NftLogic.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";

contract LendPoolStorage {
  using ReserveLogic for DataTypes.ReserveData;
  using NftLogic for DataTypes.NftData;

  ILendPoolAddressesProvider internal _addressesProvider;

  mapping(address => DataTypes.ReserveData) internal _reserves;
  mapping(address => DataTypes.NftData) internal _nfts;

  mapping(uint256 => address) internal _reservesList;
  uint256 internal _reservesCount;

  mapping(uint256 => address) internal _nftsList;
  uint256 internal _nftsCount;

  bool internal _paused;

  uint256 internal _maxNumberOfReserves;
  uint256 internal _maxNumberOfNfts;

  // !!! Never add new variable at here, because this contract is inherited by LendPool !!!
  // !!! Add new variable at LendPool directly !!!
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/************
@title IReserveOracleGetter interface
@notice Interface for getting Reserve price oracle.*/
interface IReserveOracleGetter {
  /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
  /***********
    @dev returns the asset price in ETH
     */
  function getAssetPrice(address asset) external view returns (uint256);

  // get twap price depending on _period
  function getTwapPrice(address _priceFeedKey, uint256 _interval) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title IInterestRate interface
 * @dev Interface for the calculation of the interest rates
 * @author Bend
 */
interface IInterestRate {
  function baseVariableBorrowRate() external view returns (uint256);

  function getMaxVariableBorrowRate() external view returns (uint256);

  function calculateInterestRates(
    address reserve,
    uint256 availableLiquidity,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  ) external view returns (uint256, uint256);

  function calculateInterestRates(
    address reserve,
    address bToken,
    uint256 liquidityAdded,
    uint256 liquidityTaken,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  ) external view returns (uint256 liquidityRate, uint256 variableBorrowRate);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {WadRayMath} from "./WadRayMath.sol";

library MathUtils {
  using WadRayMath for uint256;

  /// @dev Ignoring leap years
  uint256 internal constant SECONDS_PER_YEAR = 365 days;

  /**
   * @dev Function to calculate the interest accumulated using a linear interest rate formula
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate linearly accumulated during the timeDelta, in ray
   **/

  function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
    //solium-disable-next-line
    uint256 timeDifference = block.timestamp - (uint256(lastUpdateTimestamp));

    return ((rate * (timeDifference)) / SECONDS_PER_YEAR) + (WadRayMath.ray());
  }

  /**
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
   * The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
   *
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
  function calculateCompoundedInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp - (uint256(lastUpdateTimestamp));

    if (exp == 0) {
      return WadRayMath.ray();
    }

    uint256 expMinusOne = exp - 1;

    uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

    uint256 ratePerSecond = rate / SECONDS_PER_YEAR;

    uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
    uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

    uint256 secondTerm = (exp * (expMinusOne) * (basePowerTwo)) / 2;
    uint256 thirdTerm = (exp * (expMinusOne) * (expMinusTwo) * (basePowerThree)) / 6;

    return WadRayMath.ray() + (ratePerSecond * (exp)) + (secondTerm) + (thirdTerm);
  }

  /**
   * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
   * @param rate The interest rate (in ray)
   * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
   **/
  function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp) internal view returns (uint256) {
    return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IBToken} from "../interfaces/IBToken.sol";
import {IDebtToken} from "../interfaces/IDebtToken.sol";
import {ILendPoolLoan} from "../interfaces/ILendPoolLoan.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {IReserveOracleGetter} from "../interfaces/IReserveOracleGetter.sol";
import {INFTOracleGetter} from "../interfaces/INFTOracleGetter.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {GenericLogic} from "../libraries/logic/GenericLogic.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {NftLogic} from "../libraries/logic/NftLogic.sol";
import {ValidationLogic} from "../libraries/logic/ValidationLogic.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../libraries/configuration/NftConfiguration.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {LendPoolStorage} from "./LendPoolStorage.sol";
import {LendPoolStorageExt} from "./LendPoolStorageExt.sol";

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title LendPool contract
 * @dev Main point of interaction with an Bend protocol's market
 * - Users can:
 *   # Deposit
 *   # Withdraw
 *   # Borrow
 *   # Repay
 *   # Auction
 *   # Liquidate
 * - To be covered by a proxy contract, owned by the LendPoolAddressesProvider of the specific market
 * - All admin functions are callable by the LendPoolConfigurator contract defined also in the
 *   LendPoolAddressesProvider
 * @author Bend
 **/
// !!! For Upgradable: DO NOT ADJUST Inheritance Order !!!
contract LendPool is
  Initializable,
  ILendPool,
  LendPoolStorage,
  ContextUpgradeable,
  IERC721ReceiverUpgradeable,
  LendPoolStorageExt
{
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using ReserveLogic for DataTypes.ReserveData;
  using NftLogic for DataTypes.NftData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and making it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    // On the first call to nonReentrant, _notEntered will be true
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

    // Any calls to nonReentrant after this point will fail
    _status = _ENTERED;

    _;

    // By storing the original value once again, a refund is triggered (see
    // https://eips.ethereum.org/EIPS/eip-2200)
    _status = _NOT_ENTERED;
  }

  modifier whenNotPaused() {
    _whenNotPaused();
    _;
  }

  modifier onlyLendPoolConfigurator() {
    _onlyLendPoolConfigurator();
    _;
  }

  function _whenNotPaused() internal view {
    require(!_paused, Errors.LP_IS_PAUSED);
  }

  function _onlyLendPoolConfigurator() internal view {
    require(_addressesProvider.getLendPoolConfigurator() == _msgSender(), Errors.LP_CALLER_NOT_LEND_POOL_CONFIGURATOR);
  }

  /**
   * @dev Function is invoked by the proxy contract when the LendPool contract is added to the
   * LendPoolAddressesProvider of the market.
   * - Caching the address of the LendPoolAddressesProvider in order to reduce gas consumption
   *   on subsequent operations
   * @param provider The address of the LendPoolAddressesProvider
   **/
  function initialize(ILendPoolAddressesProvider provider) public initializer {
    _maxNumberOfReserves = 32;
    _maxNumberOfNfts = 256;

    _addressesProvider = provider;
  }

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying bTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 bUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the bTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of bTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external override nonReentrant whenNotPaused {
    require(onBehalfOf != address(0), Errors.VL_INVALID_ONBEHALFOF_ADDRESS);

    DataTypes.ReserveData storage reserve = _reserves[asset];
    address bToken = reserve.bTokenAddress;
    require(bToken != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    ValidationLogic.validateDeposit(reserve, amount);

    reserve.updateState();
    reserve.updateInterestRates(asset, bToken, amount, 0);

    IERC20Upgradeable(asset).safeTransferFrom(_msgSender(), bToken, amount);

    IBToken(bToken).mint(onBehalfOf, amount, reserve.liquidityIndex);

    emit Deposit(_msgSender(), asset, amount, onBehalfOf, referralCode);
  }

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent bTokens owned
   * E.g. User has 100 bUSDC, calls withdraw() and receives 100 USDC, burning the 100 bUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole bToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external override nonReentrant whenNotPaused returns (uint256) {
    require(to != address(0), Errors.VL_INVALID_TARGET_ADDRESS);

    DataTypes.ReserveData storage reserve = _reserves[asset];
    address bToken = reserve.bTokenAddress;
    require(bToken != address(0), Errors.VL_INVALID_RESERVE_ADDRESS);

    uint256 userBalance = IBToken(bToken).balanceOf(_msgSender());

    uint256 amountToWithdraw = amount;

    if (amount == type(uint256).max) {
      amountToWithdraw = userBalance;
    }

    ValidationLogic.validateWithdraw(reserve, amountToWithdraw, userBalance);

    reserve.updateState();

    reserve.updateInterestRates(asset, bToken, 0, amountToWithdraw);

    IBToken(bToken).burn(_msgSender(), to, amountToWithdraw, reserve.liquidityIndex);

    emit Withdraw(_msgSender(), asset, amountToWithdraw, to);

    return amountToWithdraw;
  }

  struct ExecuteBorrowLocalVars {
    address initiator;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 loanId;
    address reserveOracle;
    address nftOracle;
    address loanAddress;
  }

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset
   * - E.g. User borrows 100 USDC, receiving the 100 USDC in his wallet
   *   and lock collateral asset in contract
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param nftAsset The address of the underlying nft used as collateral
   * @param nftTokenId The token ID of the underlying nft used as collateral
   * @param onBehalfOf Address of the user who will receive the loan. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function borrow(
    address asset,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    uint16 referralCode
  ) external override nonReentrant whenNotPaused {
    _borrow(asset, amount, nftAsset, nftTokenId, onBehalfOf, referralCode);
  }

  function batchBorrow(
    address[] calldata assets,
    uint256[] calldata amounts,
    address[] calldata nftAssets,
    uint256[] calldata nftTokenIds,
    address onBehalfOf,
    uint16 referralCode
  ) external override nonReentrant whenNotPaused {
    require(nftAssets.length == assets.length, "inconsistent assets length");
    require(nftAssets.length == amounts.length, "inconsistent amounts length");
    require(nftAssets.length == nftTokenIds.length, "inconsistent tokenIds length");

    for (uint256 i = 0; i < nftAssets.length; i++) {
      _borrow(assets[i], amounts[i], nftAssets[i], nftTokenIds[i], onBehalfOf, referralCode);
    }
  }

  function _borrow(
    address asset,
    uint256 amount,
    address nftAsset,
    uint256 nftTokenId,
    address onBehalfOf,
    uint16 referralCode
  ) internal {
    require(onBehalfOf != address(0), Errors.VL_INVALID_ONBEHALFOF_ADDRESS);

    ExecuteBorrowLocalVars memory vars;
    vars.initiator = _msgSender();

    DataTypes.ReserveData storage reserveData = _reserves[asset];
    DataTypes.NftData storage nftData = _nfts[nftAsset];

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();

    // Convert asset amount to ETH
    vars.reserveOracle = _addressesProvider.getReserveOracle();
    vars.nftOracle = _addressesProvider.getNFTOracle();
    vars.loanAddress = _addressesProvider.getLendPoolLoan();

    vars.loanId = ILendPoolLoan(vars.loanAddress).getCollateralLoanId(nftAsset, nftTokenId);

    ValidationLogic.validateBorrow(
      onBehalfOf,
      asset,
      amount,
      reserveData,
      nftAsset,
      nftData,
      vars.loanAddress,
      vars.loanId,
      vars.reserveOracle,
      vars.nftOracle
    );

    if (vars.loanId == 0) {
      IERC721Upgradeable(nftAsset).safeTransferFrom(_msgSender(), address(this), nftTokenId);

      vars.loanId = ILendPoolLoan(vars.loanAddress).createLoan(
        vars.initiator,
        onBehalfOf,
        nftAsset,
        nftTokenId,
        nftData.bNftAddress,
        asset,
        amount,
        reserveData.variableBorrowIndex
      );
    } else {
      ILendPoolLoan(vars.loanAddress).updateLoan(
        vars.initiator,
        vars.loanId,
        amount,
        0,
        reserveData.variableBorrowIndex
      );
    }

    IDebtToken(reserveData.debtTokenAddress).mint(vars.initiator, onBehalfOf, amount, reserveData.variableBorrowIndex);

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(asset, reserveData.bTokenAddress, 0, amount);

    IBToken(reserveData.bTokenAddress).transferUnderlyingTo(vars.initiator, amount);

    emit Borrow(
      vars.initiator,
      asset,
      amount,
      nftAsset,
      nftTokenId,
      onBehalfOf,
      reserveData.currentVariableBorrowRate,
      vars.loanId,
      referralCode
    );
  }

  struct RepayLocalVars {
    address initiator;
    address poolLoan;
    address onBehalfOf;
    uint256 loanId;
    bool isUpdate;
    uint256 borrowAmount;
    uint256 repayAmount;
  }

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent loan owned
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay
   **/
  function repay(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) external override nonReentrant whenNotPaused returns (uint256, bool) {
    return _repay(nftAsset, nftTokenId, amount);
  }

  function batchRepay(
    address[] calldata nftAssets,
    uint256[] calldata nftTokenIds,
    uint256[] calldata amounts
  ) external override nonReentrant whenNotPaused returns (uint256[] memory, bool[] memory) {
    require(nftAssets.length == amounts.length, "inconsistent amounts length");
    require(nftAssets.length == nftTokenIds.length, "inconsistent tokenIds length");

    uint256[] memory repayAmounts = new uint256[](nftAssets.length);
    bool[] memory repayAlls = new bool[](nftAssets.length);

    for (uint256 i = 0; i < nftAssets.length; i++) {
      (repayAmounts[i], repayAlls[i]) = _repay(nftAssets[i], nftTokenIds[i], amounts[i]);
    }

    return (repayAmounts, repayAlls);
  }

  function _repay(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) internal returns (uint256, bool) {
    RepayLocalVars memory vars;
    vars.initiator = _msgSender();

    vars.poolLoan = _addressesProvider.getLendPoolLoan();

    vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(nftAsset, nftTokenId);
    require(vars.loanId != 0, Errors.LP_NFT_IS_NOT_USED_AS_COLLATERAL);

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan).getLoan(vars.loanId);

    DataTypes.ReserveData storage reserveData = _reserves[loanData.reserveAsset];
    DataTypes.NftData storage nftData = _nfts[loanData.nftAsset];

    // update state MUST BEFORE get borrow amount which is depent on latest borrow index
    reserveData.updateState();

    (, vars.borrowAmount) = ILendPoolLoan(vars.poolLoan).getLoanReserveBorrowAmount(vars.loanId);

    ValidationLogic.validateRepay(reserveData, nftData, loanData, amount, vars.borrowAmount);

    vars.repayAmount = vars.borrowAmount;
    vars.isUpdate = false;
    if (amount < vars.repayAmount) {
      vars.isUpdate = true;
      vars.repayAmount = amount;
    }

    if (vars.isUpdate) {
      ILendPoolLoan(vars.poolLoan).updateLoan(
        vars.initiator,
        vars.loanId,
        0,
        vars.repayAmount,
        reserveData.variableBorrowIndex
      );
    } else {
      ILendPoolLoan(vars.poolLoan).repayLoan(
        vars.initiator,
        vars.loanId,
        nftData.bNftAddress,
        vars.repayAmount,
        reserveData.variableBorrowIndex
      );
    }

    IDebtToken(reserveData.debtTokenAddress).burn(loanData.borrower, vars.repayAmount, reserveData.variableBorrowIndex);

    // update interest rate according latest borrow amount (utilizaton)
    reserveData.updateInterestRates(loanData.reserveAsset, reserveData.bTokenAddress, vars.repayAmount, 0);

    // transfer repay amount to bToken
    IERC20Upgradeable(loanData.reserveAsset).safeTransferFrom(
      vars.initiator,
      reserveData.bTokenAddress,
      vars.repayAmount
    );

    // transfer erc721 to borrower
    if (!vars.isUpdate) {
      IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(address(this), loanData.borrower, nftTokenId);
    }

    emit Repay(
      vars.initiator,
      loanData.reserveAsset,
      vars.repayAmount,
      loanData.nftAsset,
      loanData.nftTokenId,
      loanData.borrower,
      vars.loanId
    );

    return (vars.repayAmount, !vars.isUpdate);
  }

  /**
   * @dev Function to auction a non-healthy position collateral-wise
   * - The bidder want to buy collateral asset of the user getting liquidated
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param bidPrice The bid price of the bidder want to buy underlying NFT
   * @param onBehalfOf Address of the user who will get the underlying NFT, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of NFT
   *   is a different wallet
   **/
  function auction(
    address nftAsset,
    uint256 nftTokenId,
    uint256 bidPrice,
    address onBehalfOf
  ) external override nonReentrant whenNotPaused {
    address poolLiquidator = _addressesProvider.getLendPoolLiquidator();

    //solium-disable-next-line
    (bool success, bytes memory result) = poolLiquidator.delegatecall(
      abi.encodeWithSignature("auction(address,uint256,uint256,address)", nftAsset, nftTokenId, bidPrice, onBehalfOf)
    );

    _verifyCallResult(success, result, Errors.LP_DELEGATE_CALL_FAILED);
  }

  /**
   * @notice Redeem a NFT loan which state is in Auction
   * - E.g. User repays 100 USDC, burning loan and receives collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   * @param amount The amount to repay the debt
   * @param bidFine The amount of bid fine
   **/
  function redeem(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 bidFine
  ) external override nonReentrant whenNotPaused returns (uint256) {
    address poolLiquidator = _addressesProvider.getLendPoolLiquidator();

    //solium-disable-next-line
    (bool success, bytes memory result) = poolLiquidator.delegatecall(
      abi.encodeWithSignature("redeem(address,uint256,uint256,uint256)", nftAsset, nftTokenId, amount, bidFine)
    );

    bytes memory resultData = _verifyCallResult(success, result, Errors.LP_DELEGATE_CALL_FAILED);

    uint256 repayAmount = abi.decode(resultData, (uint256));

    return (repayAmount);
  }

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise
   * - The caller (liquidator) buy collateral asset of the user getting liquidated, and receives
   *   the collateral asset
   * @param nftAsset The address of the underlying NFT used as collateral
   * @param nftTokenId The token ID of the underlying NFT used as collateral
   **/
  function liquidate(
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount
  ) external override nonReentrant whenNotPaused returns (uint256) {
    address poolLiquidator = _addressesProvider.getLendPoolLiquidator();

    //solium-disable-next-line
    (bool success, bytes memory result) = poolLiquidator.delegatecall(
      abi.encodeWithSignature("liquidate(address,uint256,uint256)", nftAsset, nftTokenId, amount)
    );

    bytes memory resultData = _verifyCallResult(success, result, Errors.LP_DELEGATE_CALL_FAILED);

    uint256 extraAmount = abi.decode(resultData, (uint256));

    return (extraAmount);
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external pure override returns (bytes4) {
    operator;
    from;
    tokenId;
    data;
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getReserveConfiguration(address asset)
    external
    view
    override
    returns (DataTypes.ReserveConfigurationMap memory)
  {
    return _reserves[asset].configuration;
  }

  /**
   * @dev Returns the configuration of the NFT
   * @param asset The address of the asset of the NFT
   * @return The configuration of the NFT
   **/
  function getNftConfiguration(address asset) external view override returns (DataTypes.NftConfigurationMap memory) {
    return _nfts[asset].configuration;
  }

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view override returns (uint256) {
    return _reserves[asset].getNormalizedIncome();
  }

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view override returns (uint256) {
    return _reserves[asset].getNormalizedDebt();
  }

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view override returns (DataTypes.ReserveData memory) {
    return _reserves[asset];
  }

  /**
   * @dev Returns the state and configuration of the nft
   * @param asset The address of the underlying asset of the nft
   * @return The state of the nft
   **/
  function getNftData(address asset) external view override returns (DataTypes.NftData memory) {
    return _nfts[asset];
  }

  /**
   * @dev Returns the loan data of the NFT
   * @param nftAsset The address of the NFT
   * @param reserveAsset The address of the Reserve
   * @return totalCollateralInETH the total collateral in ETH of the NFT
   * @return totalCollateralInReserve the total collateral in Reserve of the NFT
   * @return availableBorrowsInETH the borrowing power in ETH of the NFT
   * @return availableBorrowsInReserve the borrowing power in Reserve of the NFT
   * @return ltv the loan to value of the user
   * @return liquidationThreshold the liquidation threshold of the NFT
   * @return liquidationBonus the liquidation bonus of the NFT
   **/
  function getNftCollateralData(address nftAsset, address reserveAsset)
    external
    view
    override
    returns (
      uint256 totalCollateralInETH,
      uint256 totalCollateralInReserve,
      uint256 availableBorrowsInETH,
      uint256 availableBorrowsInReserve,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus
    )
  {
    DataTypes.NftData storage nftData = _nfts[nftAsset];

    DataTypes.ReserveData storage reserveData = _reserves[reserveAsset];

    (ltv, liquidationThreshold, liquidationBonus) = nftData.configuration.getCollateralParams();

    (totalCollateralInETH, totalCollateralInReserve) = GenericLogic.calculateNftCollateralData(
      reserveAsset,
      reserveData,
      nftAsset,
      nftData,
      _addressesProvider.getReserveOracle(),
      _addressesProvider.getNFTOracle()
    );

    availableBorrowsInETH = GenericLogic.calculateAvailableBorrows(totalCollateralInETH, 0, ltv);
    availableBorrowsInReserve = GenericLogic.calculateAvailableBorrows(totalCollateralInReserve, 0, ltv);
  }

  /**
   * @dev Returns the debt data of the NFT
   * @param nftAsset The address of the NFT
   * @param nftTokenId The token id of the NFT
   * @return loanId the loan id of the NFT
   * @return reserveAsset the address of the Reserve
   * @return totalCollateral the total power of the NFT
   * @return totalDebt the total debt of the NFT
   * @return availableBorrows the borrowing power left of the NFT
   * @return healthFactor the current health factor of the NFT
   **/
  function getNftDebtData(address nftAsset, uint256 nftTokenId)
    external
    view
    override
    returns (
      uint256 loanId,
      address reserveAsset,
      uint256 totalCollateral,
      uint256 totalDebt,
      uint256 availableBorrows,
      uint256 healthFactor
    )
  {
    DataTypes.NftData storage nftData = _nfts[nftAsset];

    (uint256 ltv, uint256 liquidationThreshold, ) = nftData.configuration.getCollateralParams();

    loanId = ILendPoolLoan(_addressesProvider.getLendPoolLoan()).getCollateralLoanId(nftAsset, nftTokenId);
    if (loanId == 0) {
      return (0, address(0), 0, 0, 0, 0);
    }

    DataTypes.LoanData memory loan = ILendPoolLoan(_addressesProvider.getLendPoolLoan()).getLoan(loanId);

    reserveAsset = loan.reserveAsset;
    DataTypes.ReserveData storage reserveData = _reserves[reserveAsset];

    (, totalCollateral) = GenericLogic.calculateNftCollateralData(
      reserveAsset,
      reserveData,
      nftAsset,
      nftData,
      _addressesProvider.getReserveOracle(),
      _addressesProvider.getNFTOracle()
    );

    (, totalDebt) = GenericLogic.calculateNftDebtData(
      reserveAsset,
      reserveData,
      _addressesProvider.getLendPoolLoan(),
      loanId,
      _addressesProvider.getReserveOracle()
    );

    availableBorrows = GenericLogic.calculateAvailableBorrows(totalCollateral, totalDebt, ltv);

    if (loan.state == DataTypes.LoanState.Active) {
      healthFactor = GenericLogic.calculateHealthFactorFromBalances(totalCollateral, totalDebt, liquidationThreshold);
    }
  }

  /**
   * @dev Returns the auction data of the NFT
   * @param nftAsset The address of the NFT
   * @param nftTokenId The token id of the NFT
   * @return loanId the loan id of the NFT
   * @return bidderAddress the highest bidder address of the loan
   * @return bidPrice the highest bid price in Reserve of the loan
   * @return bidBorrowAmount the borrow amount in Reserve of the loan
   * @return bidFine the penalty fine of the loan
   **/
  function getNftAuctionData(address nftAsset, uint256 nftTokenId)
    external
    view
    override
    returns (
      uint256 loanId,
      address bidderAddress,
      uint256 bidPrice,
      uint256 bidBorrowAmount,
      uint256 bidFine
    )
  {
    DataTypes.NftData storage nftData = _nfts[nftAsset];
    ILendPoolLoan poolLoan = ILendPoolLoan(_addressesProvider.getLendPoolLoan());

    loanId = poolLoan.getCollateralLoanId(nftAsset, nftTokenId);
    if (loanId != 0) {
      DataTypes.LoanData memory loan = poolLoan.getLoan(loanId);
      if (loan.bidPrice > 0) {
        bidderAddress = loan.bidderAddress;
        bidPrice = loan.bidPrice;
        bidBorrowAmount = loan.bidBorrowAmount;
        uint256 borrowAmount = loan.bidBorrowAmount;
        if (loan.state == DataTypes.LoanState.Active) {
          (, borrowAmount) = poolLoan.getLoanReserveBorrowAmount(loanId);
        }
        bidFine = borrowAmount.percentMul(nftData.configuration.getRedeemFine());
      }
    }
  }

  struct GetLiquidationPriceLocalVars {
    address poolLoan;
    uint256 loanId;
    uint256 thresholdPrice;
    uint256 liquidatePrice;
    uint256 paybackAmount;
    uint256 remainAmount;
  }

  function getNftLiquidatePrice(address nftAsset, uint256 nftTokenId)
    external
    view
    override
    returns (uint256 liquidatePrice, uint256 paybackAmount)
  {
    GetLiquidationPriceLocalVars memory vars;

    vars.poolLoan = _addressesProvider.getLendPoolLoan();
    vars.loanId = ILendPoolLoan(vars.poolLoan).getCollateralLoanId(nftAsset, nftTokenId);
    if (vars.loanId == 0) {
      return (0, 0);
    }

    DataTypes.LoanData memory loanData = ILendPoolLoan(vars.poolLoan).getLoan(vars.loanId);

    DataTypes.ReserveData storage reserveData = _reserves[loanData.reserveAsset];
    DataTypes.NftData storage nftData = _nfts[nftAsset];

    (vars.paybackAmount, vars.thresholdPrice, vars.liquidatePrice) = GenericLogic.calculateLoanLiquidatePrice(
      vars.loanId,
      loanData.reserveAsset,
      reserveData,
      loanData.nftAsset,
      nftData,
      vars.poolLoan,
      _addressesProvider.getReserveOracle(),
      _addressesProvider.getNFTOracle()
    );

    if (vars.liquidatePrice < vars.paybackAmount) {
      vars.liquidatePrice = vars.paybackAmount;
    }

    return (vars.liquidatePrice, vars.paybackAmount);
  }

  /**
   * @dev Validates and finalizes an bToken transfer
   * - Only callable by the overlying bToken of the `asset`
   * @param asset The address of the underlying asset of the bToken
   * @param from The user from which the bToken are transferred
   * @param to The user receiving the bTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The bToken balance of the `from` user before the transfer
   * @param balanceToBefore The bToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external view override whenNotPaused {
    asset;
    from;
    to;
    amount;
    balanceFromBefore;
    balanceToBefore;

    DataTypes.ReserveData storage reserve = _reserves[asset];
    require(_msgSender() == reserve.bTokenAddress, Errors.LP_CALLER_MUST_BE_AN_BTOKEN);

    ValidationLogic.validateTransfer(from, reserve);
  }

  /**
   * @dev Returns the list of the initialized reserves
   **/
  function getReservesList() external view override returns (address[] memory) {
    address[] memory _activeReserves = new address[](_reservesCount);

    for (uint256 i = 0; i < _reservesCount; i++) {
      _activeReserves[i] = _reservesList[i];
    }
    return _activeReserves;
  }

  /**
   * @dev Returns the list of the initialized nfts
   **/
  function getNftsList() external view override returns (address[] memory) {
    address[] memory _activeNfts = new address[](_nftsCount);

    for (uint256 i = 0; i < _nftsCount; i++) {
      _activeNfts[i] = _nftsList[i];
    }
    return _activeNfts;
  }

  /**
   * @dev Set the _pause state of the pool
   * - Only callable by the LendPoolConfigurator contract
   * @param val `true` to pause the pool, `false` to un-pause it
   */
  function setPause(bool val) external override onlyLendPoolConfigurator {
    _paused = val;
    if (_paused) {
      emit Paused();
    } else {
      emit Unpaused();
    }
  }

  /**
   * @dev Returns if the LendPool is paused
   */
  function paused() external view override returns (bool) {
    return _paused;
  }

  /**
   * @dev Returns the cached LendPoolAddressesProvider connected to this contract
   **/
  function getAddressesProvider() external view override returns (ILendPoolAddressesProvider) {
    return _addressesProvider;
  }

  function setMaxNumberOfReserves(uint256 val) external override onlyLendPoolConfigurator {
    _maxNumberOfReserves = val;
  }

  /**
   * @dev Returns the maximum number of reserves supported to be listed in this LendPool
   */
  function getMaxNumberOfReserves() public view override returns (uint256) {
    return _maxNumberOfReserves;
  }

  function setMaxNumberOfNfts(uint256 val) external override onlyLendPoolConfigurator {
    _maxNumberOfNfts = val;
  }

  /**
   * @dev Returns the maximum number of nfts supported to be listed in this LendPool
   */
  function getMaxNumberOfNfts() public view override returns (uint256) {
    return _maxNumberOfNfts;
  }

  /**
   * @dev Initializes a reserve, activating it, assigning an bToken and nft loan and an
   * interest rate strategy
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param bTokenAddress The address of the bToken that will be assigned to the reserve
   * @param debtTokenAddress The address of the debtToken that will be assigned to the reserve
   * @param interestRateAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    address bTokenAddress,
    address debtTokenAddress,
    address interestRateAddress
  ) external override onlyLendPoolConfigurator {
    require(AddressUpgradeable.isContract(asset), Errors.LP_NOT_CONTRACT);
    _reserves[asset].init(bTokenAddress, debtTokenAddress, interestRateAddress);
    _addReserveToList(asset);
  }

  /**
   * @dev Initializes a nft, activating it, assigning nft loan and an
   * interest rate strategy
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the nft
   **/
  function initNft(address asset, address bNftAddress) external override onlyLendPoolConfigurator {
    require(AddressUpgradeable.isContract(asset), Errors.LP_NOT_CONTRACT);
    _nfts[asset].init(bNftAddress);
    _addNftToList(asset);

    require(_addressesProvider.getLendPoolLoan() != address(0), Errors.LPC_INVALIED_LOAN_ADDRESS);
    IERC721Upgradeable(asset).setApprovalForAll(_addressesProvider.getLendPoolLoan(), true);

    ILendPoolLoan(_addressesProvider.getLendPoolLoan()).initNft(asset, bNftAddress);
  }

  /**
   * @dev Updates the address of the interest rate strategy contract
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateAddress(address asset, address rateAddress)
    external
    override
    onlyLendPoolConfigurator
  {
    _reserves[asset].interestRateAddress = rateAddress;
  }

  /**
   * @dev Sets the configuration bitmap of the reserve as a whole
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setReserveConfiguration(address asset, uint256 configuration) external override onlyLendPoolConfigurator {
    _reserves[asset].configuration.data = configuration;
  }

  /**
   * @dev Sets the configuration bitmap of the NFT as a whole
   * - Only callable by the LendPoolConfigurator contract
   * @param asset The address of the asset of the NFT
   * @param configuration The new configuration bitmap
   **/
  function setNftConfiguration(address asset, uint256 configuration) external override onlyLendPoolConfigurator {
    _nfts[asset].configuration.data = configuration;
  }

  function _addReserveToList(address asset) internal {
    uint256 reservesCount = _reservesCount;

    require(reservesCount < _maxNumberOfReserves, Errors.LP_NO_MORE_RESERVES_ALLOWED);

    bool reserveAlreadyAdded = _reserves[asset].id != 0 || _reservesList[0] == asset;

    if (!reserveAlreadyAdded) {
      _reserves[asset].id = uint8(reservesCount);
      _reservesList[reservesCount] = asset;

      _reservesCount = reservesCount + 1;
    }
  }

  function _addNftToList(address asset) internal {
    uint256 nftsCount = _nftsCount;

    require(nftsCount < _maxNumberOfNfts, Errors.LP_NO_MORE_NFTS_ALLOWED);

    bool nftAlreadyAdded = _nfts[asset].id != 0 || _nftsList[0] == asset;

    if (!nftAlreadyAdded) {
      _nfts[asset].id = uint8(nftsCount);
      _nftsList[nftsCount] = asset;

      _nftsCount = nftsCount + 1;
    }
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

contract LendPoolStorageExt {
  // !!! Add new variable MUST append it only, do not insert, update type & name, or change order !!!
  // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#potentially-unsafe-operations

  uint256 internal constant _NOT_ENTERED = 0;
  uint256 internal constant _ENTERED = 1;
  uint256 internal _status;

  // For upgradable, add one new variable above, minus 1 at here
  uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IBNFTRegistry} from "../../interfaces/IBNFTRegistry.sol";
import {IBNFT} from "../../interfaces/IBNFT.sol";

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract BNFTRegistry is IBNFTRegistry, Initializable, OwnableUpgradeable {
  mapping(address => address) public bNftProxys;
  mapping(address => address) public bNftImpls;
  address[] public bNftAssetLists;
  string public namePrefix;
  string public symbolPrefix;
  address public bNftGenericImpl;
  mapping(address => string) public customSymbols;

  function getBNFTAddresses(address nftAsset) external view override returns (address bNftProxy, address bNftImpl) {
    bNftProxy = bNftProxys[nftAsset];
    bNftImpl = bNftImpls[nftAsset];
  }

  function getBNFTAddressesByIndex(uint16 index) external view override returns (address bNftProxy, address bNftImpl) {
    require(index < bNftAssetLists.length, "BNFTR: invalid index");
    bNftProxy = bNftProxys[bNftAssetLists[index]];
    bNftImpl = bNftImpls[bNftAssetLists[index]];
  }

  function getBNFTAssetList() external view override returns (address[] memory) {
    return bNftAssetLists;
  }

  function allBNFTAssetLength() external view override returns (uint256) {
    return bNftAssetLists.length;
  }

  function initialize(
    address genericImpl,
    string memory namePrefix_,
    string memory symbolPrefix_
  ) external override initializer {
    require(genericImpl != address(0), "BNFTR: impl is zero address");

    __Ownable_init();

    bNftGenericImpl = genericImpl;

    namePrefix = namePrefix_;
    symbolPrefix = symbolPrefix_;

    emit Initialized(genericImpl, namePrefix, symbolPrefix);
  }

  /**
   * @dev See {IBNFTRegistry-createBNFT}.
   */
  function createBNFT(address nftAsset) external override returns (address bNftProxy) {
    _requireAddressIsERC721(nftAsset);
    require(bNftProxys[nftAsset] == address(0), "BNFTR: asset exist");
    require(bNftGenericImpl != address(0), "BNFTR: impl is zero address");

    bNftProxy = _createProxyAndInitWithImpl(nftAsset, bNftGenericImpl);

    emit BNFTCreated(nftAsset, bNftImpls[nftAsset], bNftProxy, bNftAssetLists.length);
  }

  /**
   * @dev See {IBNFTRegistry-setBNFTGenericImpl}.
   */
  function setBNFTGenericImpl(address genericImpl) external override onlyOwner {
    require(genericImpl != address(0), "BNFTR: impl is zero address");
    bNftGenericImpl = genericImpl;

    emit GenericImplementationUpdated(genericImpl);
  }

  /**
   * @dev See {IBNFTRegistry-createBNFTWithImpl}.
   */
  function createBNFTWithImpl(address nftAsset, address bNftImpl)
    external
    override
    onlyOwner
    returns (address bNftProxy)
  {
    _requireAddressIsERC721(nftAsset);
    require(bNftImpl != address(0), "BNFTR: implement is zero address");
    require(bNftProxys[nftAsset] == address(0), "BNFTR: asset exist");

    bNftProxy = _createProxyAndInitWithImpl(nftAsset, bNftImpl);

    emit BNFTCreated(nftAsset, bNftImpls[nftAsset], bNftProxy, bNftAssetLists.length);
  }

  /**
   * @dev See {IBNFTRegistry-upgradeBNFTWithImpl}.
   */
  function upgradeBNFTWithImpl(
    address nftAsset,
    address bNftImpl,
    bytes memory encodedCallData
  ) external override onlyOwner {
    address bNftProxy = bNftProxys[nftAsset];
    require(bNftProxy != address(0), "BNFTR: asset nonexist");

    TransparentUpgradeableProxy proxy = TransparentUpgradeableProxy(payable(bNftProxy));

    if (encodedCallData.length > 0) {
      proxy.upgradeToAndCall(bNftImpl, encodedCallData);
    } else {
      proxy.upgradeTo(bNftImpl);
    }

    bNftImpls[nftAsset] = bNftImpl;

    emit BNFTUpgraded(nftAsset, bNftImpl, bNftProxy, bNftAssetLists.length);
  }

  /**
   * @dev See {IBNFTRegistry-addCustomeSymbols}.
   */
  function addCustomeSymbols(address[] memory nftAssets_, string[] memory symbols_) external override onlyOwner {
    require(nftAssets_.length == symbols_.length, "BNFTR: inconsistent parameters");

    for (uint256 i = 0; i < nftAssets_.length; i++) {
      customSymbols[nftAssets_[i]] = symbols_[i];
    }
  }

  function _createProxyAndInitWithImpl(address nftAsset, address bNftImpl) internal returns (address bNftProxy) {
    bytes memory initParams = _buildInitParams(nftAsset);

    TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(bNftImpl, address(this), initParams);

    bNftProxy = address(proxy);

    bNftImpls[nftAsset] = bNftImpl;
    bNftProxys[nftAsset] = bNftProxy;
    bNftAssetLists.push(nftAsset);
  }

  function _buildInitParams(address nftAsset) internal view returns (bytes memory initParams) {
    string memory nftSymbol = customSymbols[nftAsset];
    if (bytes(nftSymbol).length == 0) {
      nftSymbol = IERC721MetadataUpgradeable(nftAsset).symbol();
    }
    string memory bNftName = string(abi.encodePacked(namePrefix, " ", nftSymbol));
    string memory bNftSymbol = string(abi.encodePacked(symbolPrefix, nftSymbol));

    initParams = abi.encodeWithSelector(IBNFT.initialize.selector, nftAsset, bNftName, bNftSymbol);
  }

  function _requireAddressIsERC721(address nftAsset) internal view {
    require(nftAsset != address(0), "BNFTR: asset is zero address");
    require(AddressUpgradeable.isContract(nftAsset), "BNFTR: asset is not contract");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract BendProxyAdmin is ProxyAdmin {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {UserProxy} from "./UserProxy.sol";
import {ICryptoPunk} from "./ICryptoPunk.sol";
import {IWrappedPunks} from "../../interfaces/IWrappedPunks.sol";

contract WrappedPunk is IWrappedPunks, Ownable, ERC721Enumerable, Pausable {
  event ProxyRegistered(address user, address proxy);

  // Instance of cryptopunk smart contract
  ICryptoPunk private _punkContract;

  // Mapping from user address to proxy address
  mapping(address => address) private _proxies;

  /**
   * @dev Initializes the contract settings
   */
  constructor(address punkContract_) ERC721("Wrapped Cryptopunks", "WPUNKS") {
    _punkContract = ICryptoPunk(punkContract_);
  }

  /**
   * @dev Gets address of cryptopunk smart contract
   */
  function punkContract() public view override returns (address) {
    return address(_punkContract);
  }

  /**
   * @dev Registers proxy
   */
  function registerProxy() public override {
    address sender = _msgSender();

    require(_proxies[sender] == address(0), "PunkWrapper: caller has registered the proxy");

    address proxy = address(new UserProxy());

    _proxies[sender] = proxy;

    emit ProxyRegistered(sender, proxy);
  }

  /**
   * @dev Gets proxy address
   */
  function proxyInfo(address user) public view override returns (address) {
    return _proxies[user];
  }

  /**
   * @dev Mints a wrapped punk
   */
  function mint(uint256 punkIndex) public override whenNotPaused {
    address sender = _msgSender();

    UserProxy proxy = UserProxy(_proxies[sender]);

    require(proxy.transfer(address(_punkContract), punkIndex), "PunkWrapper: transfer fail");

    _mint(sender, punkIndex);
  }

  /**
   * @dev Burns a specific wrapped punk
   */
  function burn(uint256 punkIndex) public override whenNotPaused {
    address sender = _msgSender();

    require(_isApprovedOrOwner(sender, punkIndex), "PunkWrapper: caller is not owner nor approved");

    _burn(punkIndex);

    // Transfers ownership of punk on original cryptopunk smart contract to caller
    _punkContract.transferPunk(sender, punkIndex);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return "https://wrappedpunks.com:3000/api/punks/metadata/";
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

contract UserProxy {
  address private immutable _owner;

  /**
   * @dev Initializes the contract settings
   */
  constructor() {
    _owner = msg.sender;
  }

  /**
   * @dev Transfers punk to the smart contract owner
   */
  function transfer(address punkContract, uint256 punkIndex) external returns (bool) {
    if (_owner != msg.sender) {
      return false;
    }

    (bool result, ) = punkContract.call(abi.encodeWithSignature("transferPunk(address,uint256)", _owner, punkIndex));

    return result;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface ICryptoPunk {
  function punkIndexToAddress(uint256 punkIndex) external returns (address);

  function punksOfferedForSale(uint256 punkIndex)
    external
    returns (
      bool,
      uint256,
      address,
      uint256,
      address
    );

  function buyPunk(uint256 punkIndex) external payable;

  function transferPunk(address to, uint256 punkIndex) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title MintableERC721
 * @dev ERC721 minting logic
 */
contract MintableERC721 is ERC721Enumerable {
  string public baseURI;
  mapping(address => uint256) public mintCounts;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    baseURI = "https://MintableERC721/";
  }

  /**
   * @dev Function to mint tokens
   * @param tokenId The id of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(uint256 tokenId) public returns (bool) {
    require(tokenId < 10000, "exceed mint limit");

    mintCounts[_msgSender()] += 1;
    require(mintCounts[_msgSender()] <= 10, "exceed mint limit");

    _mint(_msgSender(), tokenId);
    return true;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory baseURI_) public {
    baseURI = baseURI_;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import {IPunks} from "../interfaces/IPunks.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title WalletBalanceProvider contract
 * @author Bend, influenced by https://github.com/wbobeirne/eth-balance-checker/blob/master/contracts/BalanceChecker.sol
 * @notice Implements a logic of getting multiple tokens balance for one user address
 * @dev NOTE: THIS CONTRACT IS NOT USED WITHIN THE BEND PROTOCOL. It's an accessory contract used to reduce the number of calls
 * towards the blockchain from the Bend backend.
 **/
contract WalletBalanceProvider {
  using Address for address payable;
  using Address for address;
  using SafeERC20 for IERC20;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  address constant MOCK_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
    @dev Check the reserve balance of a wallet in a reserve contract

    Returns the balance of the reserve for user. Avoids possible errors:
      - return 0 on non-contract address
    **/
  function balanceOfReserve(address user, address token) public view returns (uint256) {
    if (token == MOCK_ETH_ADDRESS) {
      return user.balance; // ETH balance
      // check if token is actually a contract
    } else if (token.isContract()) {
      return IERC20(token).balanceOf(user);
    }
    revert("INVALID_TOKEN");
  }

  /**
   * @notice Fetches, for a list of _users and _tokens (ETH included with mock address), the balances
   * @param users The list of users
   * @param tokens The list of tokens
   * @return And array with the concatenation of, for each user, his/her balances
   **/
  function batchBalanceOfReserve(address[] calldata users, address[] calldata tokens)
    external
    view
    returns (uint256[] memory)
  {
    uint256[] memory balances = new uint256[](users.length * tokens.length);

    for (uint256 i = 0; i < users.length; i++) {
      for (uint256 j = 0; j < tokens.length; j++) {
        balances[i * tokens.length + j] = balanceOfReserve(users[i], tokens[j]);
      }
    }

    return balances;
  }

  /**
    @dev provides balances of user wallet for all reserves available on the pool
    */
  function getUserReservesBalances(address provider, address user)
    external
    view
    returns (address[] memory, uint256[] memory)
  {
    ILendPool pool = ILendPool(ILendPoolAddressesProvider(provider).getLendPool());

    address[] memory reserves = pool.getReservesList();
    address[] memory reservesWithEth = new address[](reserves.length + 1);
    for (uint256 i = 0; i < reserves.length; i++) {
      reservesWithEth[i] = reserves[i];
    }
    reservesWithEth[reserves.length] = MOCK_ETH_ADDRESS;

    uint256[] memory balances = new uint256[](reservesWithEth.length);

    for (uint256 j = 0; j < reserves.length; j++) {
      DataTypes.ReserveConfigurationMap memory configuration = pool.getReserveConfiguration(reservesWithEth[j]);

      (bool isActive, , , ) = configuration.getFlagsMemory();

      if (!isActive) {
        balances[j] = 0;
        continue;
      }
      balances[j] = balanceOfReserve(user, reservesWithEth[j]);
    }
    balances[reserves.length] = balanceOfReserve(user, MOCK_ETH_ADDRESS);

    return (reservesWithEth, balances);
  }

  /**
    @dev Check the nft balance of a wallet in a nft contract

    Returns the balance of the nft for user. Avoids possible errors:
      - return 0 on non-contract address
    **/
  function balanceOfNft(address user, address token) public view returns (uint256) {
    if (token.isContract()) {
      return IERC721(token).balanceOf(user);
    }
    revert("INVALID_TOKEN");
  }

  /**
   * @notice Fetches, for a list of _users and _tokens (ETH included with mock address), the balances
   * @param users The list of users
   * @param tokens The list of tokens
   * @return And array with the concatenation of, for each user, his/her balances
   **/
  function batchBalanceOfNft(address[] calldata users, address[] calldata tokens)
    external
    view
    returns (uint256[] memory)
  {
    uint256[] memory balances = new uint256[](users.length * tokens.length);

    for (uint256 i = 0; i < users.length; i++) {
      for (uint256 j = 0; j < tokens.length; j++) {
        balances[i * tokens.length + j] = balanceOfNft(users[i], tokens[j]);
      }
    }

    return balances;
  }

  /**
    @dev provides balances of user wallet for all nfts available on the pool
    */
  function getUserNftsBalances(address provider, address user)
    external
    view
    returns (address[] memory, uint256[] memory)
  {
    ILendPool pool = ILendPool(ILendPoolAddressesProvider(provider).getLendPool());

    address[] memory nfts = pool.getNftsList();

    uint256[] memory balances = new uint256[](nfts.length);

    for (uint256 j = 0; j < nfts.length; j++) {
      /*
      DataTypes.NftConfigurationMap memory configuration = pool.getNftConfiguration(nfts[j]);

      (bool isActive, ) = configuration.getFlagsMemory();

      if (!isActive) {
        balances[j] = 0;
        continue;
      }
      */
      balances[j] = balanceOfNft(user, nfts[j]);
    }

    return (nfts, balances);
  }

  /**
   * @dev Returns a token ID list owned by `owner`.
   * Requirements:
   *  - The `token` must be IERC721Enumerable contract address
   * @param owner The address of user
   * @param token The address of ERC721 contract
   */
  function batchTokenOfOwnerByIndex(address owner, address token) external view returns (uint256[] memory) {
    uint256 tokenBalances = IERC721Enumerable(token).balanceOf(owner);

    uint256[] memory tokenIds = new uint256[](tokenBalances);
    for (uint256 index = 0; index < tokenBalances; index++) {
      tokenIds[index] = IERC721Enumerable(token).tokenOfOwnerByIndex(owner, index);
    }

    return tokenIds;
  }

  /**
   * @dev Returns a token ID list owned by `owner`.
   * Requirements:
   *  - The `token` must be IERC721 contract address
   *  - The `start` plus `count` must be not greater than total supply
   *  - The transaction must not ran out of gas, `count` <= 2000
   * @param owner The address of user
   * @param token The address of ERC721 contract
   * @param start The starting token ID
   * @param count The scaning number
   */
  function batchTokenOfOwner(
    address owner,
    address token,
    uint256 start,
    uint256 count
  ) external view returns (uint256[] memory) {
    uint256 tokenBalances = IERC721(token).balanceOf(owner);

    uint256[] memory tokenIds = new uint256[](tokenBalances);
    uint256 pos = 0;
    uint256 maxTokenId = start + count;
    for (uint256 tokenId = 0; tokenId < maxTokenId; tokenId++) {
      try IERC721(token).ownerOf(tokenId) returns (address tokenOwner) {
        if (tokenOwner == owner) {
          tokenIds[pos] = tokenId;
          pos++;
          //avoid useless loop scan
          if (pos == tokenBalances) {
            return tokenIds;
          }
        }
      } catch Error(
        string memory /*reason*/
      ) {} catch (
        bytes memory /*lowLevelData*/
      ) {}
    }

    return tokenIds;
  }

  /**
   * @dev Returns a punk index list owned by `owner`.
   * Requirements:
   *  - The `punkContract` must be CryptoPunksMarket address
   *  - The `start` plus `count` must be not greater than total supply
   *  - The transaction must not ran out of gas, `count` <= 2000
   * @param owner The address of user
   * @param punkContract The address of punk contract
   * @param start The starting punk index
   * @param count The scaning number
   */
  function batchPunkOfOwner(
    address owner,
    address punkContract,
    uint256 start,
    uint256 count
  ) external view returns (uint256[] memory) {
    uint256 punkBalances = IPunks(punkContract).balanceOf(owner);

    uint256[] memory punkIndexs = new uint256[](punkBalances);
    uint256 pos = 0;
    uint256 maxIndex = start + count;
    for (uint256 punkIndex = 0; punkIndex < maxIndex; punkIndex++) {
      address ownerAddress = IPunks(punkContract).punkIndexToAddress(punkIndex);
      if (ownerAddress != owner) {
        continue;
      }

      punkIndexs[pos] = punkIndex;
      pos++;
      //avoid useless loop scan
      if (pos == punkBalances) {
        return punkIndexs;
      }
    }

    return punkIndexs;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";
import {IERC721Detailed} from "../interfaces/IERC721Detailed.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {IUiPoolDataProvider} from "../interfaces/IUiPoolDataProvider.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {ILendPoolLoan} from "../interfaces/ILendPoolLoan.sol";
import {IReserveOracleGetter} from "../interfaces/IReserveOracleGetter.sol";
import {INFTOracleGetter} from "../interfaces/INFTOracleGetter.sol";
import {IBToken} from "../interfaces/IBToken.sol";
import {IDebtToken} from "../interfaces/IDebtToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../libraries/configuration/NftConfiguration.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {InterestRate} from "../protocol/InterestRate.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

contract UiPoolDataProvider is IUiPoolDataProvider {
  using WadRayMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  IReserveOracleGetter public immutable reserveOracle;
  INFTOracleGetter public immutable nftOracle;

  constructor(IReserveOracleGetter _reserveOracle, INFTOracleGetter _nftOracle) {
    reserveOracle = _reserveOracle;
    nftOracle = _nftOracle;
  }

  function getInterestRateStrategySlopes(InterestRate interestRate) internal view returns (uint256, uint256) {
    return (interestRate.variableRateSlope1(), interestRate.variableRateSlope2());
  }

  function getReservesList(ILendPoolAddressesProvider provider) public view override returns (address[] memory) {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    return lendPool.getReservesList();
  }

  function getSimpleReservesData(ILendPoolAddressesProvider provider)
    public
    view
    override
    returns (AggregatedReserveData[] memory)
  {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    address[] memory reserves = lendPool.getReservesList();
    AggregatedReserveData[] memory reservesData = new AggregatedReserveData[](reserves.length);

    for (uint256 i = 0; i < reserves.length; i++) {
      AggregatedReserveData memory reserveData = reservesData[i];

      DataTypes.ReserveData memory baseData = lendPool.getReserveData(reserves[i]);

      _fillReserveData(reserveData, reserves[i], baseData);
    }

    return (reservesData);
  }

  function getUserReservesData(ILendPoolAddressesProvider provider, address user)
    external
    view
    override
    returns (UserReserveData[] memory)
  {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    address[] memory reserves = lendPool.getReservesList();

    UserReserveData[] memory userReservesData = new UserReserveData[](user != address(0) ? reserves.length : 0);

    for (uint256 i = 0; i < reserves.length; i++) {
      DataTypes.ReserveData memory baseData = lendPool.getReserveData(reserves[i]);

      _fillUserReserveData(userReservesData[i], user, reserves[i], baseData);
    }

    return (userReservesData);
  }

  function getReservesData(ILendPoolAddressesProvider provider, address user)
    external
    view
    override
    returns (AggregatedReserveData[] memory, UserReserveData[] memory)
  {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    address[] memory reserves = lendPool.getReservesList();

    AggregatedReserveData[] memory reservesData = new AggregatedReserveData[](reserves.length);
    UserReserveData[] memory userReservesData = new UserReserveData[](user != address(0) ? reserves.length : 0);

    for (uint256 i = 0; i < reserves.length; i++) {
      AggregatedReserveData memory reserveData = reservesData[i];

      DataTypes.ReserveData memory baseData = lendPool.getReserveData(reserves[i]);
      _fillReserveData(reserveData, reserves[i], baseData);

      if (user != address(0)) {
        _fillUserReserveData(userReservesData[i], user, reserves[i], baseData);
      }
    }

    return (reservesData, userReservesData);
  }

  function _fillReserveData(
    AggregatedReserveData memory reserveData,
    address reserveAsset,
    DataTypes.ReserveData memory baseData
  ) internal view {
    reserveData.underlyingAsset = reserveAsset;

    // reserve current state
    reserveData.liquidityIndex = baseData.liquidityIndex;
    reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
    reserveData.liquidityRate = baseData.currentLiquidityRate;
    reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
    reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
    reserveData.bTokenAddress = baseData.bTokenAddress;
    reserveData.debtTokenAddress = baseData.debtTokenAddress;
    reserveData.interestRateAddress = baseData.interestRateAddress;
    reserveData.priceInEth = reserveOracle.getAssetPrice(reserveData.underlyingAsset);

    reserveData.availableLiquidity = IERC20Detailed(reserveData.underlyingAsset).balanceOf(reserveData.bTokenAddress);
    reserveData.totalVariableDebt = IDebtToken(reserveData.debtTokenAddress).totalSupply();

    // reserve configuration
    reserveData.symbol = IERC20Detailed(reserveData.underlyingAsset).symbol();
    reserveData.name = IERC20Detailed(reserveData.underlyingAsset).name();

    (, , , reserveData.decimals, reserveData.reserveFactor) = baseData.configuration.getParamsMemory();
    (reserveData.isActive, reserveData.isFrozen, reserveData.borrowingEnabled, ) = baseData
      .configuration
      .getFlagsMemory();
    (reserveData.variableRateSlope1, reserveData.variableRateSlope2) = getInterestRateStrategySlopes(
      InterestRate(reserveData.interestRateAddress)
    );
  }

  function _fillUserReserveData(
    UserReserveData memory userReserveData,
    address user,
    address reserveAsset,
    DataTypes.ReserveData memory baseData
  ) internal view {
    // user reserve data
    userReserveData.underlyingAsset = reserveAsset;
    userReserveData.bTokenBalance = IBToken(baseData.bTokenAddress).balanceOf(user);
    userReserveData.variableDebt = IDebtToken(baseData.debtTokenAddress).balanceOf(user);
  }

  function getNftsList(ILendPoolAddressesProvider provider) external view override returns (address[] memory) {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    return lendPool.getNftsList();
  }

  function getSimpleNftsData(ILendPoolAddressesProvider provider)
    external
    view
    override
    returns (AggregatedNftData[] memory)
  {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    ILendPoolLoan lendPoolLoan = ILendPoolLoan(provider.getLendPoolLoan());
    address[] memory nfts = lendPool.getNftsList();
    AggregatedNftData[] memory nftsData = new AggregatedNftData[](nfts.length);

    for (uint256 i = 0; i < nfts.length; i++) {
      AggregatedNftData memory nftData = nftsData[i];

      DataTypes.NftData memory baseData = lendPool.getNftData(nfts[i]);

      _fillNftData(nftData, nfts[i], baseData, lendPoolLoan);
    }

    return (nftsData);
  }

  function getUserNftsData(ILendPoolAddressesProvider provider, address user)
    external
    view
    override
    returns (UserNftData[] memory)
  {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    ILendPoolLoan lendPoolLoan = ILendPoolLoan(provider.getLendPoolLoan());
    address[] memory nfts = lendPool.getNftsList();

    UserNftData[] memory userNftsData = new UserNftData[](user != address(0) ? nfts.length : 0);

    for (uint256 i = 0; i < nfts.length; i++) {
      UserNftData memory userNftData = userNftsData[i];

      DataTypes.NftData memory baseData = lendPool.getNftData(nfts[i]);

      _fillUserNftData(userNftData, user, nfts[i], baseData, lendPoolLoan);
    }

    return (userNftsData);
  }

  // generic method with full data
  function getNftsData(ILendPoolAddressesProvider provider, address user)
    external
    view
    override
    returns (AggregatedNftData[] memory, UserNftData[] memory)
  {
    ILendPool lendPool = ILendPool(provider.getLendPool());
    ILendPoolLoan lendPoolLoan = ILendPoolLoan(provider.getLendPoolLoan());
    address[] memory nfts = lendPool.getNftsList();

    AggregatedNftData[] memory nftsData = new AggregatedNftData[](nfts.length);
    UserNftData[] memory userNftsData = new UserNftData[](user != address(0) ? nfts.length : 0);

    for (uint256 i = 0; i < nfts.length; i++) {
      AggregatedNftData memory nftData = nftsData[i];
      UserNftData memory userNftData = userNftsData[i];

      DataTypes.NftData memory baseData = lendPool.getNftData(nfts[i]);

      _fillNftData(nftData, nfts[i], baseData, lendPoolLoan);
      if (user != address(0)) {
        _fillUserNftData(userNftData, user, nfts[i], baseData, lendPoolLoan);
      }
    }

    return (nftsData, userNftsData);
  }

  function _fillNftData(
    AggregatedNftData memory nftData,
    address nftAsset,
    DataTypes.NftData memory baseData,
    ILendPoolLoan lendPoolLoan
  ) internal view {
    nftData.underlyingAsset = nftAsset;

    // nft current state
    nftData.bNftAddress = baseData.bNftAddress;
    nftData.priceInEth = nftOracle.getAssetPrice(nftData.underlyingAsset);

    nftData.totalCollateral = lendPoolLoan.getNftCollateralAmount(nftAsset);

    // nft configuration
    nftData.symbol = IERC721Detailed(nftData.underlyingAsset).symbol();
    nftData.name = IERC721Detailed(nftData.underlyingAsset).name();

    (nftData.ltv, nftData.liquidationThreshold, nftData.liquidationBonus) = baseData
      .configuration
      .getCollateralParamsMemory();
    (nftData.redeemDuration, nftData.auctionDuration, nftData.redeemFine, nftData.redeemThreshold) = baseData
      .configuration
      .getAuctionParamsMemory();
    (nftData.isActive, nftData.isFrozen) = baseData.configuration.getFlagsMemory();
  }

  function _fillUserNftData(
    UserNftData memory userNftData,
    address user,
    address nftAsset,
    DataTypes.NftData memory baseData,
    ILendPoolLoan lendPoolLoan
  ) internal view {
    userNftData.underlyingAsset = nftAsset;

    // user nft data
    userNftData.bNftAddress = baseData.bNftAddress;

    userNftData.totalCollateral = lendPoolLoan.getUserNftCollateralAmount(user, nftAsset);
  }

  function getSimpleLoansData(
    ILendPoolAddressesProvider provider,
    address[] memory nftAssets,
    uint256[] memory nftTokenIds
  ) external view override returns (AggregatedLoanData[] memory) {
    require(nftAssets.length == nftTokenIds.length, Errors.LP_INCONSISTENT_PARAMS);

    ILendPool lendPool = ILendPool(provider.getLendPool());
    ILendPoolLoan poolLoan = ILendPoolLoan(provider.getLendPoolLoan());

    AggregatedLoanData[] memory loansData = new AggregatedLoanData[](nftAssets.length);

    for (uint256 i = 0; i < nftAssets.length; i++) {
      AggregatedLoanData memory loanData = loansData[i];

      // NFT debt data
      (
        loanData.loanId,
        loanData.reserveAsset,
        loanData.totalCollateralInReserve,
        loanData.totalDebtInReserve,
        loanData.availableBorrowsInReserve,
        loanData.healthFactor
      ) = lendPool.getNftDebtData(nftAssets[i], nftTokenIds[i]);

      DataTypes.LoanData memory loan = poolLoan.getLoan(loanData.loanId);
      loanData.state = uint256(loan.state);

      (loanData.liquidatePrice, ) = lendPool.getNftLiquidatePrice(nftAssets[i], nftTokenIds[i]);

      // NFT auction data
      (, loanData.bidderAddress, loanData.bidPrice, loanData.bidBorrowAmount, loanData.bidFine) = lendPool
        .getNftAuctionData(nftAssets[i], nftTokenIds[i]);
    }

    return loansData;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Detailed is IERC20MetadataUpgradeable {

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC721 standard.
 */
interface IERC721Detailed is IERC721MetadataUpgradeable {

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "./ILendPoolAddressesProvider.sol";
import {IIncentivesController} from "./IIncentivesController.sol";

interface IUiPoolDataProvider {
  struct AggregatedReserveData {
    address underlyingAsset;
    string name;
    string symbol;
    uint256 decimals;
    uint256 reserveFactor;
    bool borrowingEnabled;
    bool isActive;
    bool isFrozen;
    // base data
    uint128 liquidityIndex;
    uint128 variableBorrowIndex;
    uint128 liquidityRate;
    uint128 variableBorrowRate;
    uint40 lastUpdateTimestamp;
    address bTokenAddress;
    address debtTokenAddress;
    address interestRateAddress;
    //
    uint256 availableLiquidity;
    uint256 totalVariableDebt;
    uint256 priceInEth;
    uint256 variableRateSlope1;
    uint256 variableRateSlope2;
  }

  struct UserReserveData {
    address underlyingAsset;
    uint256 bTokenBalance;
    uint256 variableDebt;
  }

  struct AggregatedNftData {
    address underlyingAsset;
    string name;
    string symbol;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 redeemDuration;
    uint256 auctionDuration;
    uint256 redeemFine;
    uint256 redeemThreshold;
    bool isActive;
    bool isFrozen;
    address bNftAddress;
    uint256 priceInEth;
    uint256 totalCollateral;
  }

  struct UserNftData {
    address underlyingAsset;
    address bNftAddress;
    uint256 totalCollateral;
  }

  struct AggregatedLoanData {
    uint256 loanId;
    uint256 state;
    address reserveAsset;
    uint256 totalCollateralInReserve;
    uint256 totalDebtInReserve;
    uint256 availableBorrowsInReserve;
    uint256 healthFactor;
    uint256 liquidatePrice;
    address bidderAddress;
    uint256 bidPrice;
    uint256 bidBorrowAmount;
    uint256 bidFine;
  }

  function getReservesList(ILendPoolAddressesProvider provider) external view returns (address[] memory);

  function getSimpleReservesData(ILendPoolAddressesProvider provider)
    external
    view
    returns (AggregatedReserveData[] memory);

  function getUserReservesData(ILendPoolAddressesProvider provider, address user)
    external
    view
    returns (UserReserveData[] memory);

  // generic method with full data
  function getReservesData(ILendPoolAddressesProvider provider, address user)
    external
    view
    returns (AggregatedReserveData[] memory, UserReserveData[] memory);

  function getNftsList(ILendPoolAddressesProvider provider) external view returns (address[] memory);

  function getSimpleNftsData(ILendPoolAddressesProvider provider) external view returns (AggregatedNftData[] memory);

  function getUserNftsData(ILendPoolAddressesProvider provider, address user)
    external
    view
    returns (UserNftData[] memory);

  // generic method with full data
  function getNftsData(ILendPoolAddressesProvider provider, address user)
    external
    view
    returns (AggregatedNftData[] memory, UserNftData[] memory);

  function getSimpleLoansData(
    ILendPoolAddressesProvider provider,
    address[] memory nftAssets,
    uint256[] memory nftTokenIds
  ) external view returns (AggregatedLoanData[] memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IInterestRate} from "../interfaces/IInterestRate.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title InterestRate contract
 * @notice Implements the calculation of the interest rates depending on the reserve state
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_UTILIZATION_RATE`
 * point of utilization and another from that one to 100%
 * @author Bend
 **/
contract InterestRate is IInterestRate {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

  ILendPoolAddressesProvider public immutable addressesProvider;

  /**
   * @dev this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates.
   * Expressed in ray
   **/
  uint256 public immutable OPTIMAL_UTILIZATION_RATE;

  /**
   * @dev This constant represents the excess utilization rate above the optimal. It's always equal to
   * 1-optimal utilization rate. Added as a constant here for gas optimizations.
   * Expressed in ray
   **/

  uint256 public immutable EXCESS_UTILIZATION_RATE;

  // Base variable borrow rate when Utilization rate = 0. Expressed in ray
  uint256 internal immutable _baseVariableBorrowRate;

  // Slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
  uint256 internal immutable _variableRateSlope1;

  // Slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
  uint256 internal immutable _variableRateSlope2;

  constructor(
    ILendPoolAddressesProvider provider,
    uint256 optimalUtilizationRate_,
    uint256 baseVariableBorrowRate_,
    uint256 variableRateSlope1_,
    uint256 variableRateSlope2_
  ) {
    addressesProvider = provider;
    OPTIMAL_UTILIZATION_RATE = optimalUtilizationRate_;
    EXCESS_UTILIZATION_RATE = WadRayMath.ray() - (optimalUtilizationRate_);
    _baseVariableBorrowRate = baseVariableBorrowRate_;
    _variableRateSlope1 = variableRateSlope1_;
    _variableRateSlope2 = variableRateSlope2_;
  }

  function variableRateSlope1() external view returns (uint256) {
    return _variableRateSlope1;
  }

  function variableRateSlope2() external view returns (uint256) {
    return _variableRateSlope2;
  }

  function baseVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate;
  }

  function getMaxVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate + (_variableRateSlope1) + (_variableRateSlope2);
  }

  /**
   * @dev Calculates the interest rates depending on the reserve's state and configurations
   * @param reserve The address of the reserve
   * @param liquidityAdded The liquidity added during the operation
   * @param liquidityTaken The liquidity taken during the operation
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
   * @return The liquidity rate, the stable borrow rate and the variable borrow rate
   **/
  function calculateInterestRates(
    address reserve,
    address bToken,
    uint256 liquidityAdded,
    uint256 liquidityTaken,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  ) external view override returns (uint256, uint256) {
    uint256 availableLiquidity = IERC20Upgradeable(reserve).balanceOf(bToken);
    //avoid stack too deep
    availableLiquidity = availableLiquidity + (liquidityAdded) - (liquidityTaken);

    return calculateInterestRates(reserve, availableLiquidity, totalVariableDebt, reserveFactor);
  }

  struct CalcInterestRatesLocalVars {
    uint256 totalDebt;
    uint256 currentVariableBorrowRate;
    uint256 currentLiquidityRate;
    uint256 utilizationRate;
  }

  /**
   * @dev Calculates the interest rates depending on the reserve's state and configurations.
   * NOTE This function is kept for compatibility with the previous DefaultInterestRateStrategy interface.
   * New protocol implementation uses the new calculateInterestRates() interface
   * @param reserve The address of the reserve
   * @param availableLiquidity The liquidity available in the corresponding bToken
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
   * @return The liquidity rate and the variable borrow rate
   **/
  function calculateInterestRates(
    address reserve,
    uint256 availableLiquidity,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  ) public view override returns (uint256, uint256) {
    reserve;

    CalcInterestRatesLocalVars memory vars;

    vars.totalDebt = totalVariableDebt;
    vars.currentVariableBorrowRate = 0;
    vars.currentLiquidityRate = 0;

    vars.utilizationRate = vars.totalDebt == 0 ? 0 : vars.totalDebt.rayDiv(availableLiquidity + (vars.totalDebt));

    if (vars.utilizationRate > OPTIMAL_UTILIZATION_RATE) {
      uint256 excessUtilizationRateRatio = (vars.utilizationRate - (OPTIMAL_UTILIZATION_RATE)).rayDiv(
        EXCESS_UTILIZATION_RATE
      );

      vars.currentVariableBorrowRate =
        _baseVariableBorrowRate +
        (_variableRateSlope1) +
        (_variableRateSlope2.rayMul(excessUtilizationRateRatio));
    } else {
      vars.currentVariableBorrowRate =
        _baseVariableBorrowRate +
        (vars.utilizationRate.rayMul(_variableRateSlope1).rayDiv(OPTIMAL_UTILIZATION_RATE));
    }

    vars.currentLiquidityRate = _getOverallBorrowRate(totalVariableDebt, vars.currentVariableBorrowRate)
      .rayMul(vars.utilizationRate)
      .percentMul(PercentageMath.PERCENTAGE_FACTOR - (reserveFactor));

    return (vars.currentLiquidityRate, vars.currentVariableBorrowRate);
  }

  /**
   * @dev Calculates the overall borrow rate as the weighted average between the total variable debt and total stable debt
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param currentVariableBorrowRate The current variable borrow rate of the reserve
   * @return The weighted averaged borrow rate
   **/
  function _getOverallBorrowRate(uint256 totalVariableDebt, uint256 currentVariableBorrowRate)
    internal
    pure
    returns (uint256)
  {
    uint256 totalDebt = totalVariableDebt;

    if (totalDebt == 0) return 0;

    uint256 weightedVariableRate = totalVariableDebt.wadToRay().rayMul(currentVariableBorrowRate);

    uint256 overallBorrowRate = weightedVariableRate.rayDiv(totalDebt.wadToRay());

    return overallBorrowRate;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    uint256[45] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IIncentivesController} from "../interfaces/IIncentivesController.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @title IncentivizedERC20
 * @notice Add Incentivized Logic to ERC20 implementation
 * @author Bend
 **/
abstract contract IncentivizedERC20 is Initializable, IERC20MetadataUpgradeable, ERC20Upgradeable {
  uint8 private _customDecimals;

  function __IncentivizedERC20_init(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) internal initializer {
    __ERC20_init(name_, symbol_);

    _customDecimals = decimals_;
  }

  /**
   * @dev Returns the decimals of the token.
   */
  function decimals() public view virtual override(ERC20Upgradeable, IERC20MetadataUpgradeable) returns (uint8) {
    return _customDecimals;
  }

  /**
   * @return Abstract function implemented by the child bToken/debtToken.
   * Done this way in order to not break compatibility with previous versions of bTokens/debtTokens
   **/
  function _getIncentivesController() internal view virtual returns (IIncentivesController);

  function _getUnderlyingAssetAddress() internal view virtual returns (address);

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    uint256 oldSenderBalance = super.balanceOf(sender);
    uint256 oldRecipientBalance = super.balanceOf(recipient);

    super._transfer(sender, recipient, amount);

    if (address(_getIncentivesController()) != address(0)) {
      uint256 currentTotalSupply = super.totalSupply();
      _getIncentivesController().handleAction(sender, currentTotalSupply, oldSenderBalance);
      if (sender != recipient) {
        _getIncentivesController().handleAction(recipient, currentTotalSupply, oldRecipientBalance);
      }
    }
  }

  function _mint(address account, uint256 amount) internal virtual override {
    uint256 oldTotalSupply = super.totalSupply();
    uint256 oldAccountBalance = super.balanceOf(account);

    super._mint(account, amount);

    if (address(_getIncentivesController()) != address(0)) {
      _getIncentivesController().handleAction(account, oldTotalSupply, oldAccountBalance);
    }
  }

  function _burn(address account, uint256 amount) internal virtual override {
    uint256 oldTotalSupply = super.totalSupply();
    uint256 oldAccountBalance = super.balanceOf(account);

    super._burn(account, amount);

    if (address(_getIncentivesController()) != address(0)) {
      _getIncentivesController().handleAction(account, oldTotalSupply, oldAccountBalance);
    }
  }

  uint256[45] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IDebtToken} from "../interfaces/IDebtToken.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {ILendPoolConfigurator} from "../interfaces/ILendPoolConfigurator.sol";
import {IIncentivesController} from "../interfaces/IIncentivesController.sol";
import {IncentivizedERC20} from "./IncentivizedERC20.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title DebtToken
 * @notice Implements a debt token to track the borrowing positions of users
 * @author Bend
 **/
contract DebtToken is Initializable, IDebtToken, IncentivizedERC20 {
  using WadRayMath for uint256;

  ILendPoolAddressesProvider internal _addressProvider;
  address internal _underlyingAsset;

  mapping(address => mapping(address => uint256)) internal _borrowAllowances;

  modifier onlyLendPool() {
    require(_msgSender() == address(_getLendPool()), Errors.CT_CALLER_MUST_BE_LEND_POOL);
    _;
  }

  modifier onlyLendPoolConfigurator() {
    require(_msgSender() == address(_getLendPoolConfigurator()), Errors.LP_CALLER_NOT_LEND_POOL_CONFIGURATOR);
    _;
  }

  event BorrowAllowanceDelegated(address indexed fromUser, address indexed toUser, address asset, uint256 amount);

  /**
   * @dev Initializes the debt token.
   * @param addressProvider The address of the lend pool
   * @param underlyingAsset The address of the underlying asset
   * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
   * @param debtTokenName The name of the token
   * @param debtTokenSymbol The symbol of the token
   */
  function initialize(
    ILendPoolAddressesProvider addressProvider,
    address underlyingAsset,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol
  ) public override initializer {
    __IncentivizedERC20_init(debtTokenName, debtTokenSymbol, debtTokenDecimals);

    _underlyingAsset = underlyingAsset;

    _addressProvider = addressProvider;

    emit Initialized(
      underlyingAsset,
      address(_getLendPool()),
      address(_getIncentivesController()),
      debtTokenDecimals,
      debtTokenName,
      debtTokenSymbol
    );
  }

  /**
   * @dev Mints debt token to the `user` address
   * -  Only callable by the LendPool
   * @param initiator The address calling borrow
   * @param amount The amount of debt being minted
   * @param index The variable debt index of the reserve
   * @return `true` if the the previous balance of the user is 0
   **/
  function mint(
    address initiator,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external override onlyLendPool returns (bool) {
    if (initiator != onBehalfOf) {
      _decreaseBorrowAllowance(onBehalfOf, initiator, amount);
    }

    uint256 previousBalance = super.balanceOf(onBehalfOf);
    // index is expressed in Ray, so:
    // amount.wadToRay().rayDiv(index).rayToWad() => amount.rayDiv(index)
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);

    _mint(onBehalfOf, amountScaled);

    emit Transfer(address(0), onBehalfOf, amount);
    emit Mint(onBehalfOf, amount, index);

    return previousBalance == 0;
  }

  /**
   * @dev Burns user variable debt
   * - Only callable by the LendPool
   * @param user The user whose debt is getting burned
   * @param amount The amount getting burned
   * @param index The variable debt index of the reserve
   **/
  function burn(
    address user,
    uint256 amount,
    uint256 index
  ) external override onlyLendPool {
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);

    _burn(user, amountScaled);

    emit Transfer(user, address(0), amount);
    emit Burn(user, amount, index);
  }

  /**
   * @dev Calculates the accumulated debt balance of the user
   * @return The debt balance of the user
   **/
  function balanceOf(address user) public view virtual override returns (uint256) {
    uint256 scaledBalance = super.balanceOf(user);

    if (scaledBalance == 0) {
      return 0;
    }

    ILendPool pool = _getLendPool();
    return scaledBalance.rayMul(pool.getReserveNormalizedVariableDebt(_underlyingAsset));
  }

  /**
   * @dev Returns the principal debt balance of the user from
   * @return The debt balance of the user since the last burn/mint action
   **/
  function scaledBalanceOf(address user) public view virtual override returns (uint256) {
    return super.balanceOf(user);
  }

  /**
   * @dev Returns the total supply of the variable debt token. Represents the total debt accrued by the users
   * @return The total supply
   **/
  function totalSupply() public view virtual override returns (uint256) {
    ILendPool pool = _getLendPool();
    return super.totalSupply().rayMul(pool.getReserveNormalizedVariableDebt(_underlyingAsset));
  }

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return the scaled total supply
   **/
  function scaledTotalSupply() public view virtual override returns (uint256) {
    return super.totalSupply();
  }

  /**
   * @dev Returns the principal balance of the user and principal total supply.
   * @param user The address of the user
   * @return The principal balance of the user
   * @return The principal total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view override returns (uint256, uint256) {
    return (super.balanceOf(user), super.totalSupply());
  }

  /**
   * @dev Returns the address of the underlying asset of this bToken
   **/
  function UNDERLYING_ASSET_ADDRESS() public view returns (address) {
    return _underlyingAsset;
  }

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view override returns (IIncentivesController) {
    return _getIncentivesController();
  }

  /**
   * @dev Returns the address of the lend pool where this token is used
   **/
  function POOL() public view returns (ILendPool) {
    return _getLendPool();
  }

  function _getIncentivesController() internal view override returns (IIncentivesController) {
    return IIncentivesController(_addressProvider.getIncentivesController());
  }

  function _getUnderlyingAssetAddress() internal view override returns (address) {
    return _underlyingAsset;
  }

  function _getLendPool() internal view returns (ILendPool) {
    return ILendPool(_addressProvider.getLendPool());
  }

  function _getLendPoolConfigurator() internal view returns (ILendPoolConfigurator) {
    return ILendPoolConfigurator(_addressProvider.getLendPoolConfigurator());
  }

  /**
   * @dev Being non transferrable, the debt token does not implement any of the
   * standard ERC20 functions for transfer and allowance.
   **/
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    recipient;
    amount;
    revert("TRANSFER_NOT_SUPPORTED");
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    owner;
    spender;
    revert("ALLOWANCE_NOT_SUPPORTED");
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    spender;
    amount;
    revert("APPROVAL_NOT_SUPPORTED");
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    sender;
    recipient;
    amount;
    revert("TRANSFER_NOT_SUPPORTED");
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
    spender;
    addedValue;
    revert("ALLOWANCE_NOT_SUPPORTED");
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
    spender;
    subtractedValue;
    revert("ALLOWANCE_NOT_SUPPORTED");
  }

  /**
   * @dev delegates borrowing power to a user on the specific debt token
   * @param delegatee the address receiving the delegated borrowing power
   * @param amount the maximum amount being delegated. Delegation will still
   * respect the liquidation constraints (even if delegated, a delegatee cannot
   * force a delegator HF to go below 1)
   **/
  function approveDelegation(address delegatee, uint256 amount) external override {
    _borrowAllowances[_msgSender()][delegatee] = amount;
    emit BorrowAllowanceDelegated(_msgSender(), delegatee, _getUnderlyingAssetAddress(), amount);
  }

  /**
   * @dev returns the borrow allowance of the user
   * @param fromUser The user to giving allowance
   * @param toUser The user to give allowance to
   * @return the current allowance of toUser
   **/
  function borrowAllowance(address fromUser, address toUser) external view override returns (uint256) {
    return _borrowAllowances[fromUser][toUser];
  }

  function _decreaseBorrowAllowance(
    address delegator,
    address delegatee,
    uint256 amount
  ) internal {
    require(_borrowAllowances[delegator][delegatee] >= amount, Errors.CT_BORROW_ALLOWANCE_NOT_ENOUGH);

    uint256 newAllowance = _borrowAllowances[delegator][delegatee] - amount;
    _borrowAllowances[delegator][delegatee] = newAllowance;

    emit BorrowAllowanceDelegated(delegator, delegatee, _getUnderlyingAssetAddress(), newAllowance);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {ILendPoolConfigurator} from "../interfaces/ILendPoolConfigurator.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {IBToken} from "../interfaces/IBToken.sol";
import {IIncentivesController} from "../interfaces/IIncentivesController.sol";
import {IncentivizedERC20} from "./IncentivizedERC20.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title ERC20 BToken
 * @dev Implementation of the interest bearing token for the Bend protocol
 * @author Bend
 */
contract BToken is Initializable, IBToken, IncentivizedERC20 {
  using WadRayMath for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  ILendPoolAddressesProvider internal _addressProvider;
  address internal _treasury;
  address internal _underlyingAsset;

  modifier onlyLendPool() {
    require(_msgSender() == address(_getLendPool()), Errors.CT_CALLER_MUST_BE_LEND_POOL);
    _;
  }

  modifier onlyLendPoolConfigurator() {
    require(_msgSender() == address(_getLendPoolConfigurator()), Errors.LP_CALLER_NOT_LEND_POOL_CONFIGURATOR);
    _;
  }

  /**
   * @dev Initializes the bToken
   * @param addressProvider The address of the address provider where this bToken will be used
   * @param treasury The address of the Bend treasury, receiving the fees on this bToken
   * @param underlyingAsset The address of the underlying asset of this bToken
   */
  function initialize(
    ILendPoolAddressesProvider addressProvider,
    address treasury,
    address underlyingAsset,
    uint8 bTokenDecimals,
    string calldata bTokenName,
    string calldata bTokenSymbol
  ) external override initializer {
    __IncentivizedERC20_init(bTokenName, bTokenSymbol, bTokenDecimals);

    _treasury = treasury;
    _underlyingAsset = underlyingAsset;

    _addressProvider = addressProvider;

    emit Initialized(
      underlyingAsset,
      _addressProvider.getLendPool(),
      treasury,
      _addressProvider.getIncentivesController()
    );
  }

  /**
   * @dev Burns bTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * - Only callable by the LendPool, as extra state updates there need to be managed
   * @param user The owner of the bTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external override onlyLendPool {
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);
    _burn(user, amountScaled);

    IERC20Upgradeable(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);

    emit Burn(user, receiverOfUnderlying, amount, index);
  }

  /**
   * @dev Mints `amount` bTokens to `user`
   * - Only callable by the LendPool, as extra state updates there need to be managed
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external override onlyLendPool returns (bool) {
    uint256 previousBalance = super.balanceOf(user);

    // index is expressed in Ray, so:
    // amount.wadToRay().rayDiv(index).rayToWad() => amount.rayDiv(index)
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);
    _mint(user, amountScaled);

    emit Mint(user, amount, index);

    return previousBalance == 0;
  }

  /**
   * @dev Mints bTokens to the reserve treasury
   * - Only callable by the LendPool
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external override onlyLendPool {
    if (amount == 0) {
      return;
    }

    address treasury = _treasury;

    // Compared to the normal mint, we don't check for rounding errors.
    // The amount to mint can easily be very small since it is a fraction of the interest ccrued.
    // In that case, the treasury will experience a (very small) loss, but it
    // wont cause potentially valid transactions to fail.
    _mint(treasury, amount.rayDiv(index));

    emit Transfer(address(0), treasury, amount);
    emit Mint(treasury, amount, index);
  }

  /**
   * @dev Calculates the balance of the user: principal balance + interest generated by the principal
   * @param user The user whose balance is calculated
   * @return The balance of the user
   **/
  function balanceOf(address user) public view override returns (uint256) {
    ILendPool pool = _getLendPool();
    return super.balanceOf(user).rayMul(pool.getReserveNormalizedIncome(_underlyingAsset));
  }

  /**
   * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
   * updated stored balance divided by the reserve's liquidity index at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   **/
  function scaledBalanceOf(address user) external view override returns (uint256) {
    return super.balanceOf(user);
  }

  /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view override returns (uint256, uint256) {
    return (super.balanceOf(user), super.totalSupply());
  }

  /**
   * @dev calculates the total supply of the specific bToken
   * since the balance of every single user increases over time, the total supply
   * does that too.
   * @return the current total supply
   **/
  function totalSupply() public view override returns (uint256) {
    uint256 currentSupplyScaled = super.totalSupply();

    if (currentSupplyScaled == 0) {
      return 0;
    }

    ILendPool pool = _getLendPool();
    return currentSupplyScaled.rayMul(pool.getReserveNormalizedIncome(_underlyingAsset));
  }

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return the scaled total supply
   **/
  function scaledTotalSupply() public view virtual override returns (uint256) {
    return super.totalSupply();
  }

  /**
   * @dev Returns the address of the Bend treasury, receiving the fees on this bToken
   **/
  function RESERVE_TREASURY_ADDRESS() public view returns (address) {
    return _treasury;
  }

  /**
   * @dev Returns the address of the underlying asset of this bToken
   **/
  function UNDERLYING_ASSET_ADDRESS() public view override returns (address) {
    return _underlyingAsset;
  }

  /**
   * @dev Returns the address of the lending pool where this bToken is used
   **/
  function POOL() public view returns (ILendPool) {
    return _getLendPool();
  }

  /**
   * @dev For internal usage in the logic of the parent contract IncentivizedERC20
   **/
  function _getIncentivesController() internal view override returns (IIncentivesController) {
    return IIncentivesController(_addressProvider.getIncentivesController());
  }

  function _getUnderlyingAssetAddress() internal view override returns (address) {
    return _underlyingAsset;
  }

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view override returns (IIncentivesController) {
    return _getIncentivesController();
  }

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param target The recipient of the bTokens
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address target, uint256 amount) external override onlyLendPool returns (uint256) {
    IERC20Upgradeable(_underlyingAsset).safeTransfer(target, amount);
    return amount;
  }

  function _getLendPool() internal view returns (ILendPool) {
    return ILendPool(_addressProvider.getLendPool());
  }

  function _getLendPoolConfigurator() internal view returns (ILendPoolConfigurator) {
    return ILendPoolConfigurator(_addressProvider.getLendPoolConfigurator());
  }

  /**
   * @dev Transfers the bTokens between two users. Validates the transfer
   * (ie checks for valid HF after the transfer) if required
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   * @param validate `true` if the transfer needs to be validated
   **/
  function _transfer(
    address from,
    address to,
    uint256 amount,
    bool validate
  ) internal {
    address underlyingAsset = _underlyingAsset;
    ILendPool pool = _getLendPool();

    uint256 index = pool.getReserveNormalizedIncome(underlyingAsset);

    uint256 fromBalanceBefore = super.balanceOf(from).rayMul(index);
    uint256 toBalanceBefore = super.balanceOf(to).rayMul(index);

    super._transfer(from, to, amount.rayDiv(index));

    if (validate) {
      pool.finalizeTransfer(underlyingAsset, from, to, amount, fromBalanceBefore, toBalanceBefore);
    }

    emit BalanceTransfer(from, to, amount, index);
  }

  /**
   * @dev Overrides the parent _transfer to force validated transfer() and transferFrom()
   * @param from The source address
   * @param to The destination address
   * @param amount The amount getting transferred
   **/
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    _transfer(from, to, amount, true);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title BendCollector
 * @notice Stores all the BEND kept for incentives, just giving approval to the different
 * systems that will pull BEND funds for their specific use case
 * @author Bend
 **/
contract BendCollector is Initializable, OwnableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /**
   * @dev initializes the contract upon assignment to the BendUpgradeableProxy
   */
  function initialize() external initializer {
    __Ownable_init();
  }

  function approve(
    IERC20Upgradeable token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    token.safeApprove(recipient, amount);
  }

  function transfer(
    IERC20Upgradeable token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    token.safeTransfer(recipient, amount);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IReserveOracleGetter} from "../interfaces/IReserveOracleGetter.sol";
import {BlockContext} from "../utils/BlockContext.sol";

contract ReserveOracle is IReserveOracleGetter, OwnableUpgradeable, BlockContext {
  uint256 private constant TOKEN_DIGIT = 10**18;

  event AggregatorAdded(address currencyKey, address aggregator);
  event AggregatorRemoved(address currencyKey, address aggregator);

  // key by currency symbol, eg USDT
  mapping(address => AggregatorV3Interface) public priceFeedMap;
  address[] public priceFeedKeys;

  address public weth;

  function initialize(address _weth) public initializer {
    __Ownable_init();
    weth = _weth;
  }

  function setAggregators(address[] calldata _priceFeedKeys, address[] calldata _aggregators) external onlyOwner {
    require(_priceFeedKeys.length == _aggregators.length, "ReserveOracle: INCONSISTENT_PARAMS_LENGTH");
    for (uint256 i = 0; i < _priceFeedKeys.length; i++) {
      _addAggregator(_priceFeedKeys[i], _aggregators[i]);
    }
  }

  function addAggregator(address _priceFeedKey, address _aggregator) external onlyOwner {
    _addAggregator(_priceFeedKey, _aggregator);
  }

  function _addAggregator(address _priceFeedKey, address _aggregator) internal {
    requireNonEmptyAddress(_priceFeedKey);
    requireNonEmptyAddress(_aggregator);
    if (address(priceFeedMap[_priceFeedKey]) == address(0)) {
      priceFeedKeys.push(_priceFeedKey);
    }
    priceFeedMap[_priceFeedKey] = AggregatorV3Interface(_aggregator);
    emit AggregatorAdded(_priceFeedKey, address(_aggregator));
  }

  function removeAggregator(address _priceFeedKey) external onlyOwner {
    address aggregator = address(priceFeedMap[_priceFeedKey]);
    requireNonEmptyAddress(aggregator);
    delete priceFeedMap[_priceFeedKey];

    uint256 length = priceFeedKeys.length;
    for (uint256 i = 0; i < length; i++) {
      if (priceFeedKeys[i] == _priceFeedKey) {
        // if the removal item is the last one, just `pop`
        if (i != length - 1) {
          priceFeedKeys[i] = priceFeedKeys[length - 1];
        }
        priceFeedKeys.pop();
        emit AggregatorRemoved(_priceFeedKey, aggregator);
        break;
      }
    }
  }

  function getAggregator(address _priceFeedKey) public view returns (AggregatorV3Interface) {
    return priceFeedMap[_priceFeedKey];
  }

  function getAssetPrice(address _priceFeedKey) external view override returns (uint256) {
    if (_priceFeedKey == weth) {
      return 1 ether;
    }
    require(isExistedKey(_priceFeedKey), "ReserveOracle: key not existed");
    AggregatorV3Interface aggregator = getAggregator(_priceFeedKey);

    (, int256 _price, , , ) = aggregator.latestRoundData();
    require(_price >= 0, "ReserveOracle: negative answer");
    uint8 decimals = aggregator.decimals();

    return formatDecimals(uint256(_price), decimals);
  }

  function getLatestTimestamp(address _priceFeedKey) public view returns (uint256) {
    AggregatorV3Interface aggregator = getAggregator(_priceFeedKey);
    requireNonEmptyAddress(address(aggregator));

    (, , , uint256 timestamp, ) = aggregator.latestRoundData();

    return timestamp;
  }

  function getTwapPrice(address _priceFeedKey, uint256 _interval) external view override returns (uint256) {
    require(isExistedKey(_priceFeedKey), "ReserveOracle: key not existed");
    require(_interval != 0, "ReserveOracle: interval can't be 0");

    AggregatorV3Interface aggregator = getAggregator(_priceFeedKey);
    (uint80 roundId, int256 _price, , uint256 timestamp, ) = aggregator.latestRoundData();
    require(_price >= 0, "ReserveOracle: negative answer");
    uint8 decimals = aggregator.decimals();

    uint256 latestPrice = formatDecimals(uint256(_price), decimals);

    require(roundId >= 0, "ReserveOracle: Not enough history");
    uint256 latestTimestamp = timestamp;
    uint256 baseTimestamp = _blockTimestamp() - _interval;
    // if latest updated timestamp is earlier than target timestamp, return the latest price.
    if (latestTimestamp < baseTimestamp || roundId == 0) {
      return latestPrice;
    }

    // rounds are like snapshots, latestRound means the latest price snapshot. follow chainlink naming
    uint256 cumulativeTime = _blockTimestamp() - latestTimestamp;
    uint256 previousTimestamp = latestTimestamp;
    uint256 weightedPrice = latestPrice * cumulativeTime;
    while (true) {
      if (roundId == 0) {
        // if cumulative time is less than requested interval, return current twap price
        return weightedPrice / cumulativeTime;
      }

      roundId = roundId - 1;
      // get current round timestamp and price
      (, int256 _priceTemp, , uint256 currentTimestamp, ) = aggregator.getRoundData(roundId);
      require(_priceTemp >= 0, "ReserveOracle: negative answer");

      uint256 price = formatDecimals(uint256(_priceTemp), decimals);

      // check if current round timestamp is earlier than target timestamp
      if (currentTimestamp <= baseTimestamp) {
        // weighted time period will be (target timestamp - previous timestamp). For example,
        // now is 1000, _interval is 100, then target timestamp is 900. If timestamp of current round is 970,
        // and timestamp of NEXT round is 880, then the weighted time period will be (970 - 900) = 70,
        // instead of (970 - 880)
        weightedPrice = weightedPrice + (price * (previousTimestamp - baseTimestamp));
        break;
      }

      uint256 timeFraction = previousTimestamp - currentTimestamp;
      weightedPrice = weightedPrice + (price * timeFraction);
      cumulativeTime = cumulativeTime + timeFraction;
      previousTimestamp = currentTimestamp;
    }
    return weightedPrice / _interval;
  }

  function isExistedKey(address _priceFeedKey) private view returns (bool) {
    uint256 length = priceFeedKeys.length;
    for (uint256 i = 0; i < length; i++) {
      if (priceFeedKeys[i] == _priceFeedKey) {
        return true;
      }
    }
    return false;
  }

  function requireNonEmptyAddress(address _addr) internal pure {
    require(_addr != address(0), "ReserveOracle: empty address");
  }

  function formatDecimals(uint256 _price, uint8 _decimals) internal pure returns (uint256) {
    return (_price * TOKEN_DIGIT) / (10**uint256(_decimals));
  }

  function getPriceFeedLength() public view returns (uint256 length) {
    return priceFeedKeys.length;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

// wrap block.xxx functions for testing
// only support timestamp and number so far
abstract contract BlockContext {
  //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

  //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
  uint256[50] private __gap;

  function _blockTimestamp() internal view virtual returns (uint256) {
    return block.timestamp;
  }

  function _blockNumber() internal view virtual returns (uint256) {
    return block.number;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {INFTOracle} from "../interfaces/INFTOracle.sol";
import {BlockContext} from "../utils/BlockContext.sol";

contract NFTOracle is INFTOracle, Initializable, OwnableUpgradeable, BlockContext {
  modifier onlyAdmin() {
    require(_msgSender() == priceFeedAdmin, "NFTOracle: !admin");
    _;
  }

  event AssetAdded(address indexed asset);
  event AssetRemoved(address indexed asset);
  event FeedAdminUpdated(address indexed admin);
  event SetAssetData(address indexed asset, uint256 price, uint256 timestamp, uint256 roundId);

  struct NFTPriceData {
    uint256 roundId;
    uint256 price;
    uint256 timestamp;
  }

  struct NFTPriceFeed {
    bool registered;
    NFTPriceData[] nftPriceData;
  }

  address public priceFeedAdmin;

  // key is nft contract address
  mapping(address => NFTPriceFeed) public nftPriceFeedMap;
  address[] public nftPriceFeedKeys;

  // data validity check parameters
  uint256 private constant DECIMAL_PRECISION = 10**18;
  // Maximum deviation allowed between two consecutive oracle prices. 18-digit precision.
  uint256 public maxPriceDeviation; // 20%,18-digit precision.
  // The maximum allowed deviation between two consecutive oracle prices within a certain time frame. 18-bit precision.
  uint256 public maxPriceDeviationWithTime; // 10%
  uint256 public timeIntervalWithPrice; // 30 minutes
  uint256 public minimumUpdateTime; // 10 minutes

  mapping(address => bool) internal _nftPaused;

  modifier whenNotPaused(address _nftContract) {
    _whenNotPaused(_nftContract);
    _;
  }

  function _whenNotPaused(address _nftContract) internal view {
    bool _paused = _nftPaused[_nftContract];
    require(!_paused, "NFTOracle: nft price feed paused");
  }

  function initialize(
    address _admin,
    uint256 _maxPriceDeviation,
    uint256 _maxPriceDeviationWithTime,
    uint256 _timeIntervalWithPrice,
    uint256 _minimumUpdateTime
  ) public initializer {
    __Ownable_init();
    priceFeedAdmin = _admin;
    maxPriceDeviation = _maxPriceDeviation;
    maxPriceDeviationWithTime = _maxPriceDeviationWithTime;
    timeIntervalWithPrice = _timeIntervalWithPrice;
    minimumUpdateTime = _minimumUpdateTime;
  }

  function setPriceFeedAdmin(address _admin) external onlyOwner {
    priceFeedAdmin = _admin;
    emit FeedAdminUpdated(_admin);
  }

  function setAssets(address[] calldata _nftContracts) external onlyOwner {
    for (uint256 i = 0; i < _nftContracts.length; i++) {
      _addAsset(_nftContracts[i]);
    }
  }

  function addAsset(address _nftContract) external onlyOwner {
    _addAsset(_nftContract);
  }

  function _addAsset(address _nftContract) internal {
    requireKeyExisted(_nftContract, false);
    nftPriceFeedMap[_nftContract].registered = true;
    nftPriceFeedKeys.push(_nftContract);
    emit AssetAdded(_nftContract);
  }

  function removeAsset(address _nftContract) external onlyOwner {
    requireKeyExisted(_nftContract, true);
    delete nftPriceFeedMap[_nftContract];

    uint256 length = nftPriceFeedKeys.length;
    for (uint256 i = 0; i < length; i++) {
      if (nftPriceFeedKeys[i] == _nftContract) {
        nftPriceFeedKeys[i] = nftPriceFeedKeys[length - 1];
        nftPriceFeedKeys.pop();
        break;
      }
    }
    emit AssetRemoved(_nftContract);
  }

  function setAssetData(
    address _nftContract,
    uint256 _price,
    uint256, /*_timestamp*/
    uint256 _roundId
  ) external override onlyAdmin whenNotPaused(_nftContract) {
    requireKeyExisted(_nftContract, true);
    uint256 _timestamp = _blockTimestamp();
    require(_timestamp > getLatestTimestamp(_nftContract), "NFTOracle: incorrect timestamp");
    require(_price > 0, "NFTOracle: price can not be 0");
    bool dataValidity = checkValidityOfPrice(_nftContract, _price, _timestamp);
    require(dataValidity, "NFTOracle: invalid price data");
    NFTPriceData memory data = NFTPriceData({price: _price, timestamp: _timestamp, roundId: _roundId});
    nftPriceFeedMap[_nftContract].nftPriceData.push(data);

    emit SetAssetData(_nftContract, _price, _timestamp, _roundId);
  }

  function getAssetPrice(address _nftContract) external view override returns (uint256) {
    require(isExistedKey(_nftContract), "NFTOracle: key not existed");
    uint256 len = getPriceFeedLength(_nftContract);
    require(len > 0, "NFTOracle: no price data");
    return nftPriceFeedMap[_nftContract].nftPriceData[len - 1].price;
  }

  function getLatestTimestamp(address _nftContract) public view override returns (uint256) {
    require(isExistedKey(_nftContract), "NFTOracle: key not existed");
    uint256 len = getPriceFeedLength(_nftContract);
    if (len == 0) {
      return 0;
    }
    return nftPriceFeedMap[_nftContract].nftPriceData[len - 1].timestamp;
  }

  function getTwapPrice(address _nftContract, uint256 _interval) external view override returns (uint256) {
    require(isExistedKey(_nftContract), "NFTOracle: key not existed");
    require(_interval != 0, "NFTOracle: interval can't be 0");

    uint256 len = getPriceFeedLength(_nftContract);
    require(len > 0, "NFTOracle: Not enough history");
    uint256 round = len - 1;
    NFTPriceData memory priceRecord = nftPriceFeedMap[_nftContract].nftPriceData[round];
    uint256 latestTimestamp = priceRecord.timestamp;
    uint256 baseTimestamp = _blockTimestamp() - _interval;
    // if latest updated timestamp is earlier than target timestamp, return the latest price.
    if (latestTimestamp < baseTimestamp || round == 0) {
      return priceRecord.price;
    }

    // rounds are like snapshots, latestRound means the latest price snapshot. follow chainlink naming
    uint256 cumulativeTime = _blockTimestamp() - latestTimestamp;
    uint256 previousTimestamp = latestTimestamp;
    uint256 weightedPrice = priceRecord.price * cumulativeTime;
    while (true) {
      if (round == 0) {
        // if cumulative time is less than requested interval, return current twap price
        return weightedPrice / cumulativeTime;
      }

      round = round - 1;
      // get current round timestamp and price
      priceRecord = nftPriceFeedMap[_nftContract].nftPriceData[round];
      uint256 currentTimestamp = priceRecord.timestamp;
      uint256 price = priceRecord.price;

      // check if current round timestamp is earlier than target timestamp
      if (currentTimestamp <= baseTimestamp) {
        // weighted time period will be (target timestamp - previous timestamp). For example,
        // now is 1000, _interval is 100, then target timestamp is 900. If timestamp of current round is 970,
        // and timestamp of NEXT round is 880, then the weighted time period will be (970 - 900) = 70,
        // instead of (970 - 880)
        weightedPrice = weightedPrice + (price * (previousTimestamp - baseTimestamp));
        break;
      }

      uint256 timeFraction = previousTimestamp - currentTimestamp;
      weightedPrice = weightedPrice + price * timeFraction;
      cumulativeTime = cumulativeTime + timeFraction;
      previousTimestamp = currentTimestamp;
    }
    return weightedPrice / _interval;
  }

  function getPreviousPrice(address _nftContract, uint256 _numOfRoundBack) public view override returns (uint256) {
    require(isExistedKey(_nftContract), "NFTOracle: key not existed");

    uint256 len = getPriceFeedLength(_nftContract);
    require(len > 0 && _numOfRoundBack < len, "NFTOracle: Not enough history");
    return nftPriceFeedMap[_nftContract].nftPriceData[len - _numOfRoundBack - 1].price;
  }

  function getPreviousTimestamp(address _nftContract, uint256 _numOfRoundBack) public view override returns (uint256) {
    require(isExistedKey(_nftContract), "NFTOracle: key not existed");

    uint256 len = getPriceFeedLength(_nftContract);
    require(len > 0 && _numOfRoundBack < len, "NFTOracle: Not enough history");
    return nftPriceFeedMap[_nftContract].nftPriceData[len - _numOfRoundBack - 1].timestamp;
  }

  function getPriceFeedLength(address _nftContract) public view returns (uint256 length) {
    return nftPriceFeedMap[_nftContract].nftPriceData.length;
  }

  function getLatestRoundId(address _nftContract) public view returns (uint256) {
    uint256 len = getPriceFeedLength(_nftContract);
    if (len == 0) {
      return 0;
    }
    return nftPriceFeedMap[_nftContract].nftPriceData[len - 1].roundId;
  }

  function isExistedKey(address _nftContract) private view returns (bool) {
    return nftPriceFeedMap[_nftContract].registered;
  }

  function requireKeyExisted(address _key, bool _existed) private view {
    if (_existed) {
      require(isExistedKey(_key), "NFTOracle: key not existed");
    } else {
      require(!isExistedKey(_key), "NFTOracle: key existed");
    }
  }

  function checkValidityOfPrice(
    address _nftContract,
    uint256 _price,
    uint256 _timestamp
  ) private view returns (bool) {
    uint256 len = getPriceFeedLength(_nftContract);
    if (len > 0) {
      uint256 price = nftPriceFeedMap[_nftContract].nftPriceData[len - 1].price;
      if (_price == price) {
        return true;
      }
      uint256 timestamp = nftPriceFeedMap[_nftContract].nftPriceData[len - 1].timestamp;
      uint256 percentDeviation;
      if (_price > price) {
        percentDeviation = ((_price - price) * DECIMAL_PRECISION) / price;
      } else {
        percentDeviation = ((price - _price) * DECIMAL_PRECISION) / price;
      }
      uint256 timeDeviation = _timestamp - timestamp;
      if (percentDeviation > maxPriceDeviation) {
        return false;
      } else if (timeDeviation < minimumUpdateTime) {
        return false;
      } else if ((percentDeviation > maxPriceDeviationWithTime) && (timeDeviation < timeIntervalWithPrice)) {
        return false;
      }
    }
    return true;
  }

  function setDataValidityParameters(
    uint256 _maxPriceDeviation,
    uint256 _maxPriceDeviationWithTime,
    uint256 _timeIntervalWithPrice,
    uint256 _minimumUpdateTime
  ) external onlyOwner {
    maxPriceDeviation = _maxPriceDeviation;
    maxPriceDeviationWithTime = _maxPriceDeviationWithTime;
    timeIntervalWithPrice = _timeIntervalWithPrice;
    minimumUpdateTime = _minimumUpdateTime;
  }

  function setPause(address _nftContract, bool val) external override onlyOwner {
    _nftPaused[_nftContract] = val;
  }

  function paused(address _nftContract) external view override returns (bool) {
    return _nftPaused[_nftContract];
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/************
@title INFTOracle interface
@notice Interface for NFT price oracle.*/
interface INFTOracle {
  /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
  // get latest price
  function getAssetPrice(address _asset) external view returns (uint256);

  // get latest timestamp
  function getLatestTimestamp(address _asset) external view returns (uint256);

  // get previous price with _back rounds
  function getPreviousPrice(address _asset, uint256 _numOfRoundBack) external view returns (uint256);

  // get previous timestamp with _back rounds
  function getPreviousTimestamp(address _asset, uint256 _numOfRoundBack) external view returns (uint256);

  // get twap price depending on _period
  function getTwapPrice(address _asset, uint256 _interval) external view returns (uint256);

  function setAssetData(
    address _asset,
    uint256 _price,
    uint256 _timestamp,
    uint256 _roundId
  ) external;

  function setPause(address _nftContract, bool val) external;

  function paused(address _nftContract) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;
import {NFTOracle} from "../protocol/NFTOracle.sol";

contract MockNFTOracle is NFTOracle {
  uint256 private timestamp = 1444004400;
  uint256 private number = 10001;

  function mock_setBlockTimestamp(uint256 _timestamp) public {
    timestamp = _timestamp;
  }

  function mock_setBlockNumber(uint256 _number) public {
    number = _number;
  }

  function mock_getCurrentTimestamp() public view returns (uint256) {
    return _blockTimestamp();
  }

  // Override BlockContext here
  function _blockTimestamp() internal view override returns (uint256) {
    return timestamp;
  }

  function _blockNumber() internal view override returns (uint256) {
    return number;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";
import {IERC721Detailed} from "../interfaces/IERC721Detailed.sol";
import {ILendPoolAddressesProvider} from "../interfaces/ILendPoolAddressesProvider.sol";
import {ILendPool} from "../interfaces/ILendPool.sol";
import {ILendPoolLoan} from "../interfaces/ILendPoolLoan.sol";
import {IDebtToken} from "../interfaces/IDebtToken.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {NftConfiguration} from "../libraries/configuration/NftConfiguration.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

contract BendProtocolDataProvider {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  struct ReserveTokenData {
    string tokenSymbol;
    address tokenAddress;
    string bTokenSymbol;
    address bTokenAddress;
    string debtTokenSymbol;
    address debtTokenAddress;
  }

  struct NftTokenData {
    string nftSymbol;
    address nftAddress;
    string bNftSymbol;
    address bNftAddress;
  }

  ILendPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

  constructor(ILendPoolAddressesProvider addressesProvider) {
    ADDRESSES_PROVIDER = addressesProvider;
  }

  function getAllReservesTokenDatas() external view returns (ReserveTokenData[] memory) {
    ILendPool pool = ILendPool(ADDRESSES_PROVIDER.getLendPool());
    address[] memory reserves = pool.getReservesList();
    ReserveTokenData[] memory reservesTokens = new ReserveTokenData[](reserves.length);
    for (uint256 i = 0; i < reserves.length; i++) {
      DataTypes.ReserveData memory reserveData = pool.getReserveData(reserves[i]);
      reservesTokens[i] = ReserveTokenData({
        tokenSymbol: IERC20Detailed(reserves[i]).symbol(),
        tokenAddress: reserves[i],
        bTokenSymbol: IERC20Detailed(reserveData.bTokenAddress).symbol(),
        bTokenAddress: reserveData.bTokenAddress,
        debtTokenSymbol: IERC20Detailed(reserveData.debtTokenAddress).symbol(),
        debtTokenAddress: reserveData.debtTokenAddress
      });
    }
    return reservesTokens;
  }

  function getReserveTokenData(address asset) external view returns (ReserveTokenData memory) {
    ILendPool pool = ILendPool(ADDRESSES_PROVIDER.getLendPool());
    DataTypes.ReserveData memory reserveData = pool.getReserveData(asset);
    return
      ReserveTokenData({
        tokenSymbol: IERC20Detailed(asset).symbol(),
        tokenAddress: asset,
        bTokenSymbol: IERC20Detailed(reserveData.bTokenAddress).symbol(),
        bTokenAddress: reserveData.bTokenAddress,
        debtTokenSymbol: IERC20Detailed(reserveData.debtTokenAddress).symbol(),
        debtTokenAddress: reserveData.debtTokenAddress
      });
  }

  function getAllNftsTokenDatas() external view returns (NftTokenData[] memory) {
    ILendPool pool = ILendPool(ADDRESSES_PROVIDER.getLendPool());
    address[] memory nfts = pool.getNftsList();
    NftTokenData[] memory nftTokens = new NftTokenData[](nfts.length);
    for (uint256 i = 0; i < nfts.length; i++) {
      DataTypes.NftData memory nftData = pool.getNftData(nfts[i]);
      nftTokens[i] = NftTokenData({
        nftSymbol: IERC721Detailed(nfts[i]).symbol(),
        nftAddress: nfts[i],
        bNftSymbol: IERC721Detailed(nftData.bNftAddress).symbol(),
        bNftAddress: nftData.bNftAddress
      });
    }
    return nftTokens;
  }

  function getNftTokenData(address nftAsset) external view returns (NftTokenData memory) {
    ILendPool pool = ILendPool(ADDRESSES_PROVIDER.getLendPool());
    DataTypes.NftData memory nftData = pool.getNftData(nftAsset);
    return
      NftTokenData({
        nftSymbol: IERC20Detailed(nftAsset).symbol(),
        nftAddress: nftAsset,
        bNftSymbol: IERC20Detailed(nftData.bNftAddress).symbol(),
        bNftAddress: nftData.bNftAddress
      });
  }

  function getReserveConfigurationData(address asset)
    external
    view
    returns (
      uint256 decimals,
      uint256 reserveFactor,
      bool borrowingEnabled,
      bool isActive,
      bool isFrozen
    )
  {
    DataTypes.ReserveConfigurationMap memory configuration = ILendPool(ADDRESSES_PROVIDER.getLendPool())
      .getReserveConfiguration(asset);

    (, , , decimals, reserveFactor) = configuration.getParamsMemory();

    (isActive, isFrozen, borrowingEnabled, ) = configuration.getFlagsMemory();
  }

  function getNftConfigurationData(address asset)
    external
    view
    returns (
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 redeemDuration,
      uint256 auctionDuration,
      uint256 redeemFine,
      uint256 redeemThreshold,
      bool isActive,
      bool isFrozen
    )
  {
    DataTypes.NftConfigurationMap memory configuration = ILendPool(ADDRESSES_PROVIDER.getLendPool())
      .getNftConfiguration(asset);

    (ltv, liquidationThreshold, liquidationBonus) = configuration.getCollateralParamsMemory();
    (redeemDuration, auctionDuration, redeemFine, redeemThreshold) = configuration.getAuctionParamsMemory();

    (isActive, isFrozen) = configuration.getFlagsMemory();
  }

  function getReserveData(address asset)
    external
    view
    returns (
      uint256 availableLiquidity,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    )
  {
    DataTypes.ReserveData memory reserve = ILendPool(ADDRESSES_PROVIDER.getLendPool()).getReserveData(asset);

    return (
      IERC20Detailed(asset).balanceOf(reserve.bTokenAddress),
      IERC20Detailed(reserve.debtTokenAddress).totalSupply(),
      reserve.currentLiquidityRate,
      reserve.currentVariableBorrowRate,
      reserve.liquidityIndex,
      reserve.variableBorrowIndex,
      reserve.lastUpdateTimestamp
    );
  }

  function getUserReserveData(address asset, address user)
    external
    view
    returns (
      uint256 currentBTokenBalance,
      uint256 currentVariableDebt,
      uint256 scaledVariableDebt,
      uint256 liquidityRate
    )
  {
    DataTypes.ReserveData memory reserve = ILendPool(ADDRESSES_PROVIDER.getLendPool()).getReserveData(asset);

    currentBTokenBalance = IERC20Detailed(reserve.bTokenAddress).balanceOf(user);
    currentVariableDebt = IERC20Detailed(reserve.debtTokenAddress).balanceOf(user);
    scaledVariableDebt = IDebtToken(reserve.debtTokenAddress).scaledBalanceOf(user);
    liquidityRate = reserve.currentLiquidityRate;
  }

  struct LoanData {
    uint256 loanId;
    uint8 state;
    address borrower;
    address nftAsset;
    uint256 nftTokenId;
    address reserveAsset;
    uint256 scaledAmount;
    uint256 currentAmount;
    uint256 bidStartTimestamp;
    address bidderAddress;
    uint256 bidPrice;
    uint256 bidBorrowAmount;
  }

  function getLoanDataByCollateral(address nftAsset, uint256 nftTokenId)
    external
    view
    returns (LoanData memory loanData)
  {
    loanData.loanId = ILendPoolLoan(ADDRESSES_PROVIDER.getLendPoolLoan()).getCollateralLoanId(nftAsset, nftTokenId);
    DataTypes.LoanData memory loan = ILendPoolLoan(ADDRESSES_PROVIDER.getLendPoolLoan()).getLoan(loanData.loanId);
    _fillLoanData(loanData, loan);
  }

  function getLoanDataByLoanId(uint256 loanId) external view returns (LoanData memory loanData) {
    DataTypes.LoanData memory loan = ILendPoolLoan(ADDRESSES_PROVIDER.getLendPoolLoan()).getLoan(loanId);
    _fillLoanData(loanData, loan);
  }

  function _fillLoanData(LoanData memory loanData, DataTypes.LoanData memory loan) internal view {
    loanData.loanId = loan.loanId;
    loanData.state = uint8(loan.state);
    loanData.borrower = loan.borrower;
    loanData.nftAsset = loan.nftAsset;
    loanData.nftTokenId = loan.nftTokenId;
    loanData.reserveAsset = loan.reserveAsset;
    loanData.scaledAmount = loan.scaledAmount;
    (, loanData.currentAmount) = ILendPoolLoan(ADDRESSES_PROVIDER.getLendPoolLoan()).getLoanReserveBorrowAmount(
      loan.loanId
    );
    loanData.bidStartTimestamp = loan.bidStartTimestamp;
    loanData.bidderAddress = loan.bidderAddress;
    loanData.bidPrice = loan.bidPrice;
    loanData.bidBorrowAmount = loan.bidBorrowAmount;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IIncentivesController} from "../interfaces/IIncentivesController.sol";

contract MockIncentivesController is IIncentivesController {
  bool private _handleActionIsCalled;
  address private _asset;
  uint256 private _totalSupply;
  uint256 private _userBalance;

  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param asset The address of the user
   * @param totalSupply The total supply of the asset in the lending pool
   * @param userBalance The balance of the user of the asset in the lending pool
   **/
  function handleAction(
    address asset,
    uint256 totalSupply,
    uint256 userBalance
  ) external override {
    _handleActionIsCalled = true;
    _asset = asset;
    _totalSupply = totalSupply;
    _userBalance = userBalance;
  }

  function checkHandleActionIsCorrect(
    address asset,
    uint256 totalSupply,
    uint256 userBalance
  ) public view returns (bool) {
    return _handleActionIsCalled && asset == _asset && totalSupply == _totalSupply && userBalance == _userBalance;
  }

  function checkHandleActionIsCalled() public view returns (bool) {
    return _handleActionIsCalled;
  }

  function resetHandleActionIsCalled() public {
    _handleActionIsCalled = false;
    _asset = address(0);
    _totalSupply = 0;
    _userBalance = 0;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {ILendPool} from "../interfaces/ILendPool.sol";
import {IDebtToken} from "../interfaces/IDebtToken.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title MaliciousHackerERC721
 * @dev Malicious Hacker Logic
 */
contract MaliciousHackerERC721 is IERC721Receiver {
  ILendPool internal _pool;
  uint256 internal _simulateAction;

  uint256 public constant ACTION_DEPOSIT = 1;
  uint256 public constant ACTION_WITHDRAW = 2;
  uint256 public constant ACTION_BORROW = 3;
  uint256 public constant ACTION_REPAY = 4;
  uint256 public constant ACTION_AUCTION = 5;
  uint256 public constant ACTION_REDEEM = 6;
  uint256 public constant ACTION_LIQUIDATE = 7;

  constructor(address pool_) {
    _pool = ILendPool(pool_);
  }

  function approveDelegate(address reserve, address delegatee) public {
    DataTypes.ReserveData memory reserveData = _pool.getReserveData(reserve);
    IDebtToken debtToken = IDebtToken(reserveData.debtTokenAddress);

    debtToken.approveDelegation(delegatee, type(uint256).max);
  }

  function simulateAction(uint256 simulateAction_) public {
    _simulateAction = simulateAction_;
  }

  struct OnERC721ReceivedLocalVars {
    address[] reserves;
    address[] nfts;
    address onBehalfOf;
    address to;
    uint16 referralCode;
    uint256 amount;
    uint256 bidPrice;
    uint256 bidFine;
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    operator;
    from;
    tokenId;
    data;

    OnERC721ReceivedLocalVars memory vars;

    vars.reserves = _pool.getReservesList();
    vars.nfts = _pool.getNftsList();
    vars.onBehalfOf = msg.sender;
    vars.to = msg.sender;
    vars.referralCode = 0;
    vars.amount = 1 ether;
    vars.bidPrice = 2 ether;
    vars.bidFine = 0.1 ether;

    if (_simulateAction == ACTION_DEPOSIT) {
      _pool.deposit(vars.reserves[0], vars.amount, vars.onBehalfOf, vars.referralCode);
    } else if (_simulateAction == ACTION_WITHDRAW) {
      _pool.withdraw(vars.reserves[0], vars.amount, vars.to);
    } else if (_simulateAction == ACTION_BORROW) {
      _pool.borrow(vars.reserves[0], vars.amount, vars.nfts[0], tokenId, vars.onBehalfOf, vars.referralCode);
    } else if (_simulateAction == ACTION_REPAY) {
      _pool.repay(vars.nfts[0], tokenId, vars.amount);
    } else if (_simulateAction == ACTION_AUCTION) {
      _pool.auction(vars.nfts[0], tokenId, vars.bidPrice, vars.onBehalfOf);
    } else if (_simulateAction == ACTION_REDEEM) {
      _pool.redeem(vars.nfts[0], tokenId, vars.amount, vars.bidFine);
    } else if (_simulateAction == ACTION_LIQUIDATE) {
      _pool.liquidate(vars.nfts[0], tokenId, vars.amount);
    }

    return IERC721Receiver.onERC721Received.selector;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {IBNFT} from "../../interfaces/IBNFT.sol";
import {IFlashLoanReceiver} from "../../interfaces/IFlashLoanReceiver.sol";

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

/**
 * @title BNFT contract
 * @dev Implements the methods for the bNFT protocol
 **/
contract BNFT is ERC721EnumerableUpgradeable, IBNFT {
  address private _underlyingAsset;
  // Mapping from token ID to minter address
  mapping(uint256 => address) private _minters;

  /**
   * @dev Initializes the bNFT
   * @param underlyingAsset The address of the underlying asset of this bNFT (E.g. PUNK for bPUNK)
   */
  function initialize(
    address underlyingAsset,
    string calldata bNftName,
    string calldata bNftSymbol
  ) external override initializer {
    __ERC721_init(bNftName, bNftSymbol);

    _underlyingAsset = underlyingAsset;

    emit Initialized(underlyingAsset);
  }

  /**
   * @dev Mints bNFT token to the user address
   *
   * Requirements:
   *  - The caller must be contract address
   *
   * @param to The owner address receive the bNFT token
   * @param tokenId token id of the underlying asset of NFT
   **/
  function mint(address to, uint256 tokenId) external override {
    require(AddressUpgradeable.isContract(_msgSender()), "BNFT: caller is not contract");
    require(!_exists(tokenId), "BNFT: exist token");
    require(IERC721Upgradeable(_underlyingAsset).ownerOf(tokenId) == _msgSender(), "BNFT: caller is not owner");

    // Receive NFT Tokens
    IERC721Upgradeable(_underlyingAsset).safeTransferFrom(_msgSender(), address(this), tokenId);

    // mint bNFT to user
    _mint(to, tokenId);

    _minters[tokenId] = _msgSender();

    emit Mint(_msgSender(), _underlyingAsset, tokenId, to);
  }

  /**
   * @dev Burns user bNFT token
   *
   * Requirements:
   *  - The caller must be contract address
   *
   * @param tokenId token id of the underlying asset of NFT
   **/
  function burn(uint256 tokenId) external override {
    require(AddressUpgradeable.isContract(_msgSender()), "BNFT: caller is not contract");
    require(_exists(tokenId), "BNFT: nonexist token");
    require(_minters[tokenId] == _msgSender(), "BNFT: caller is not minter");

    address owner = ERC721Upgradeable.ownerOf(tokenId);

    IERC721Upgradeable(_underlyingAsset).safeTransferFrom(address(this), _msgSender(), tokenId);

    _burn(tokenId);

    delete _minters[tokenId];

    emit Burn(_msgSender(), _underlyingAsset, tokenId, owner);
  }

  /**
   * @dev See {IBNFT-flashLoan}.
   */
  function flashLoan(
    address receiverAddress,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) external override {
    uint256 i;
    IFlashLoanReceiver receiver = IFlashLoanReceiver(receiverAddress);

    // !!!CAUTION: receiver contract may reentry mint, burn, flashloan again

    // only token owner can do flashloan
    for (i = 0; i < nftTokenIds.length; i++) {
      require(ownerOf(nftTokenIds[i]) == _msgSender(), "BNFT: caller is not owner");
    }

    // step 1: moving underlying asset forward to receiver contract
    for (i = 0; i < nftTokenIds.length; i++) {
      IERC721Upgradeable(_underlyingAsset).safeTransferFrom(address(this), receiverAddress, nftTokenIds[i]);
    }

    // setup 2: execute receiver contract, doing something like aidrop
    require(
      receiver.executeOperation(_underlyingAsset, nftTokenIds, _msgSender(), address(this), params),
      "BNFT: invalid flashloan executor return"
    );

    // setup 3: moving underlying asset backword from receiver contract
    for (i = 0; i < nftTokenIds.length; i++) {
      IERC721Upgradeable(_underlyingAsset).safeTransferFrom(receiverAddress, address(this), nftTokenIds[i]);

      emit FlashLoan(receiverAddress, _msgSender(), _underlyingAsset, nftTokenIds[i]);
    }
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721Upgradeable, IERC721MetadataUpgradeable)
    returns (string memory)
  {
    return IERC721MetadataUpgradeable(_underlyingAsset).tokenURI(tokenId);
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external pure override returns (bytes4) {
    operator;
    from;
    tokenId;
    data;
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }

  /**
   * @dev See {IBNFT-minterOf}.
   */
  function minterOf(uint256 tokenId) external view override returns (address) {
    address minter = _minters[tokenId];
    require(minter != address(0), "BNFT: minter query for nonexistent token");
    return minter;
  }

  /**
   * @dev Being non transferrable, the bNFT token does not implement any of the
   * standard ERC721 functions for transfer and allowance.
   **/
  function approve(address to, uint256 tokenId) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    to;
    tokenId;
    revert("APPROVAL_NOT_SUPPORTED");
  }

  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override(ERC721Upgradeable, IERC721Upgradeable)
  {
    operator;
    approved;
    revert("APPROVAL_NOT_SUPPORTED");
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    from;
    to;
    tokenId;
    revert("TRANSFER_NOT_SUPPORTED");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    from;
    to;
    tokenId;
    revert("TRANSFER_NOT_SUPPORTED");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override(ERC721Upgradeable, IERC721Upgradeable) {
    from;
    to;
    tokenId;
    _data;
    revert("TRANSFER_NOT_SUPPORTED");
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721Upgradeable) {
    from;
    to;
    tokenId;
    revert("TRANSFER_NOT_SUPPORTED");
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title IFlashLoanReceiver interface
 * @notice Interface for the IFlashLoanReceiver.
 * @author BEND
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface IFlashLoanReceiver {
  function executeOperation(
    address asset,
    uint256[] calldata tokenIds,
    address initiator,
    address operator,
    bytes calldata params
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

// EACAggregatorProxy is (AggregatorProxy is AggregatorV2V3Interface)
contract MockChainlinkOracle is AggregatorV2V3Interface {
  uint80[] internal roundIdArray;
  int256[] internal answerArray;
  uint256[] internal decimalsArray;
  uint256[] internal timestampArray;
  uint80[] internal versionArray;
  uint8 internal _decimals;

  constructor(uint8 decimals_) {
    _decimals = decimals_;
  }

  // Proxy
  function aggregator() public view returns (address) {
    return address(this);
  }

  // V2
  function latestAnswer() external view override returns (int256) {
    uint256 index = roundIdArray.length - 1;
    return answerArray[index];
  }

  function latestTimestamp() external view override returns (uint256) {
    uint256 index = roundIdArray.length - 1;
    return timestampArray[index];
  }

  function latestRound() external view override returns (uint256) {
    uint256 index = roundIdArray.length - 1;
    return roundIdArray[index];
  }

  function getAnswer(uint256 roundId) external view override returns (int256) {
    uint256 maxIndex = roundIdArray.length - 1;
    uint256 index = maxIndex + roundId - roundIdArray[maxIndex];
    return answerArray[index];
  }

  function getTimestamp(uint256 roundId) external view override returns (uint256) {
    uint256 maxIndex = roundIdArray.length - 1;
    uint256 index = maxIndex + roundId - roundIdArray[maxIndex];
    return timestampArray[index];
  }

  // V3
  function decimals() external view override returns (uint8) {
    return _decimals;
  }

  function description() external pure override returns (string memory) {
    return "";
  }

  function version() external pure override returns (uint256) {
    return 0;
  }

  function getRoundData(uint80 _roundId)
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    uint256 maxIndex = roundIdArray.length - 1;
    uint256 index = maxIndex + _roundId - roundIdArray[maxIndex];
    return (roundIdArray[index], answerArray[index], decimalsArray[index], timestampArray[index], versionArray[index]);
  }

  function latestRoundData()
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    uint256 index = roundIdArray.length - 1;
    return (roundIdArray[index], answerArray[index], decimalsArray[index], timestampArray[index], versionArray[index]);
  }

  // mock
  function mockAddAnswer(
    uint80 _roundId,
    int256 _answer,
    uint256 _startedAt,
    uint256 _updatedAt,
    uint80 _answeredInRound
  ) external {
    roundIdArray.push(_roundId);
    answerArray.push(_answer);
    decimalsArray.push(_startedAt);
    timestampArray.push(_updatedAt);
    versionArray.push(_answeredInRound);

    emit AnswerUpdated(_answer, _roundId, _updatedAt);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

//import {IReserveOracle} from "../interfaces/IReserveOracle.sol";
import {ReserveOracle} from "../protocol/ReserveOracle.sol";

contract MockReserveOracle is ReserveOracle {
  uint256 private timestamp = 1444004400;
  uint256 private number = 10001;

  function mock_setBlockTimestamp(uint256 _timestamp) public {
    timestamp = _timestamp;
  }

  function mock_setBlockNumber(uint256 _number) public {
    number = _number;
  }

  function mock_getCurrentTimestamp() public view returns (uint256) {
    return _blockTimestamp();
  }

  // Override BlockContext here
  function _blockTimestamp() internal view override returns (uint256) {
    return timestamp;
  }

  function _blockNumber() internal view override returns (uint256) {
    return number;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "../protocol/BToken.sol";

contract MockBTokenVersionN is BToken {
  uint256 public dummy1;
  uint256 public dummy2;

  function initializeVersionN(uint256 dummy1_, uint256 dummy2_) external initializer {
    dummy1 = dummy1_;
    dummy2 = dummy2_;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "../protocol/DebtToken.sol";

contract MockDebtTokenVersionN is DebtToken {
  uint256 public dummy1;
  uint256 public dummy2;

  function initializeVersionN(uint256 dummy1_, uint256 dummy2_) external initializer {
    dummy1 = dummy1_;
    dummy2 = dummy2_;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import "../access/AccessControl.sol";

/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockController is AccessControl {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with a given `minDelay`.
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);

        // deployer + self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, _msgSender());
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // register proposers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], datas[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(PROPOSER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == datas.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, datas, predecessor, salt);
        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], datas[i]);
        }
        _afterCall(id);
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Execute an operation's call.
     *
     * Emits a {CallExecuted} event.
     */
    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");

        emit CallExecuted(id, index, target, value, data);
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title DependencyStub
 * @dev Dependency Stub
 */
contract DependencyStub {
  constructor(uint256 val) {
    require(val != 0, "zero value");
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract MintableERC20 is ERC20 {
  uint8 private _decimals;
  mapping(address => uint256) public mintValues;

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals_
  ) ERC20(name, symbol) {
    _setupDecimals(decimals_);
  }

  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }

  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Function to mint tokens
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(uint256 value) public returns (bool) {
    mintValues[_msgSender()] += value;
    require(mintValues[_msgSender()] < (1000000 * (10**_decimals)), "exceed mint limit");

    _mint(_msgSender(), value);
    return true;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "../protocol/LendPool.sol";

contract MockLendPoolVersionN is LendPool {
  uint256 public dummy1;
  uint256 public dummy2;

  function initializeVersionN(uint256 dummy1_, uint256 dummy2_) external initializer {
    dummy1 = dummy1_;
    dummy2 = dummy2_;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoPunksMarket is Ownable {
  // You can use this hash to verify the image file containing all the punks
  string public imageHash = "ac39af4793119ee46bbff351d8cb6b5f23da60222126add4268e261199a2921b";

  string public standard = "CryptoPunks";
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  uint256 public nextPunkIndexToAssign = 0;

  bool public allPunksAssigned = false;
  uint256 public punksRemainingToAssign = 0;

  //mapping (address => uint) public addressToPunkIndex;
  mapping(uint256 => address) public punkIndexToAddress;

  /* This creates an array with all balances */
  mapping(address => uint256) public balanceOf;

  struct Offer {
    bool isForSale;
    uint256 punkIndex;
    address seller;
    uint256 minValue; // in ether
    address onlySellTo; // specify to sell only to a specific person
  }

  struct Bid {
    bool hasBid;
    uint256 punkIndex;
    address bidder;
    uint256 value;
  }

  // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
  mapping(uint256 => Offer) public punksOfferedForSale;

  // A record of the highest punk bid
  mapping(uint256 => Bid) public punkBids;

  mapping(address => uint256) public pendingWithdrawals;

  event Assign(address indexed to, uint256 punkIndex);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
  event PunkOffered(uint256 indexed punkIndex, uint256 minValue, address indexed toAddress);
  event PunkBidEntered(uint256 indexed punkIndex, uint256 value, address indexed fromAddress);
  event PunkBidWithdrawn(uint256 indexed punkIndex, uint256 value, address indexed fromAddress);
  event PunkBought(uint256 indexed punkIndex, uint256 value, address indexed fromAddress, address indexed toAddress);
  event PunkNoLongerForSale(uint256 indexed punkIndex);

  /* Initializes contract with initial supply tokens to the creator of the contract */
  constructor() {
    //        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
    totalSupply = 10000; // Update total supply
    punksRemainingToAssign = totalSupply;
    name = "CRYPTOPUNKS"; // Set the name for display purposes
    symbol = "\x3FE"; // Set the symbol for display purposes Ͼ
    decimals = 0; // Amount of decimals for display purposes
  }

  function setInitialOwner(address to, uint256 punkIndex) public onlyOwner {
    require(allPunksAssigned, "CryptoPunksMarket:  allPunksAssigned");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    if (punkIndexToAddress[punkIndex] != to) {
      if (punkIndexToAddress[punkIndex] != address(0)) {
        balanceOf[punkIndexToAddress[punkIndex]]--;
      } else {
        punksRemainingToAssign--;
      }
      punkIndexToAddress[punkIndex] = to;
      balanceOf[to]++;
      emit Assign(to, punkIndex);
    }
  }

  function setInitialOwners(address[] calldata addresses, uint256[] calldata indices) public onlyOwner {
    uint256 n = addresses.length;
    for (uint256 i = 0; i < n; i++) {
      setInitialOwner(addresses[i], indices[i]);
    }
  }

  function allInitialOwnersAssigned() public onlyOwner {
    allPunksAssigned = true;
  }

  function getPunk(uint256 punkIndex) public {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punksRemainingToAssign != 0, "CryptoPunksMarket: empty punksRemainingToAssign");
    require(punkIndexToAddress[punkIndex] == address(0), "CryptoPunksMarket: already got");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    punkIndexToAddress[punkIndex] = msg.sender;
    balanceOf[msg.sender]++;
    punksRemainingToAssign--;

    emit Assign(msg.sender, punkIndex);
  }

  // Transfer ownership of a punk to another user without requiring payment
  function transferPunk(address to, uint256 punkIndex) public {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndexToAddress[punkIndex] == msg.sender, "CryptoPunksMarket: not owner");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    if (punksOfferedForSale[punkIndex].isForSale) {
      punkNoLongerForSale(punkIndex);
    }
    punkIndexToAddress[punkIndex] = to;
    balanceOf[msg.sender]--;
    balanceOf[to]++;

    emit Transfer(msg.sender, to, 1);
    emit PunkTransfer(msg.sender, to, punkIndex);

    // Check for the case where there is a bid from the new owner and refund it.
    // Any other bid can stay in place.
    Bid memory bid = punkBids[punkIndex];
    if (bid.bidder == to) {
      // Kill bid and refund value
      pendingWithdrawals[to] += bid.value;
      punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
    }
  }

  function punkNoLongerForSale(uint256 punkIndex) public {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndexToAddress[punkIndex] == msg.sender, "CryptoPunksMarket: not owner");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, address(0));

    emit PunkNoLongerForSale(punkIndex);
  }

  function offerPunkForSale(uint256 punkIndex, uint256 minSalePriceInWei) public {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndexToAddress[punkIndex] == msg.sender, "CryptoPunksMarket: not owner");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, address(0));

    emit PunkOffered(punkIndex, minSalePriceInWei, address(0));
  }

  function offerPunkForSaleToAddress(
    uint256 punkIndex,
    uint256 minSalePriceInWei,
    address toAddress
  ) public {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndexToAddress[punkIndex] == msg.sender, "CryptoPunksMarket: not owner");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    punksOfferedForSale[punkIndex] = Offer(true, punkIndex, msg.sender, minSalePriceInWei, toAddress);

    emit PunkOffered(punkIndex, minSalePriceInWei, toAddress);
  }

  function buyPunk(uint256 punkIndex) public payable {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    Offer memory offer = punksOfferedForSale[punkIndex];
    require(offer.isForSale, "CryptoPunksMarket: punk not actually for sale");
    require(
      offer.onlySellTo == address(0) || offer.onlySellTo == msg.sender,
      "CryptoPunksMarket: punk not supposed to be sold to this user"
    );

    require(msg.value >= offer.minValue, "CryptoPunksMarket: Didn't send enough ETH");
    require(offer.seller == punkIndexToAddress[punkIndex], "CryptoPunksMarket: Seller no longer owner of punk");

    address seller = offer.seller;

    punkIndexToAddress[punkIndex] = msg.sender;
    balanceOf[seller]--;
    balanceOf[msg.sender]++;

    emit Transfer(seller, msg.sender, 1);

    punkNoLongerForSale(punkIndex);
    pendingWithdrawals[seller] += msg.value;

    emit PunkBought(punkIndex, msg.value, seller, msg.sender);

    // Check for the case where there is a bid from the new owner and refund it.
    // Any other bid can stay in place.
    Bid memory bid = punkBids[punkIndex];
    if (bid.bidder == msg.sender) {
      // Kill bid and refund value
      pendingWithdrawals[msg.sender] += bid.value;
      punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
    }
  }

  function withdraw() public {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");

    uint256 amount = pendingWithdrawals[msg.sender];
    // Remember to zero the pending refund before
    // sending to prevent re-entrancy attacks
    pendingWithdrawals[msg.sender] = 0;

    _safeTransferETH(msg.sender, amount);
  }

  function enterBidForPunk(uint256 punkIndex) public payable {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");
    require(punkIndexToAddress[punkIndex] != msg.sender, "CryptoPunksMarket: can not buy your own punk");
    require(punkIndexToAddress[punkIndex] != address(0), "CryptoPunksMarket: can not buy unassigned punk");
    require(msg.value > 0, "CryptoPunksMarket: should send eth value");

    Bid memory existing = punkBids[punkIndex];
    require(msg.value > existing.value, "CryptoPunksMarket: should send more eth value");

    if (existing.value > 0) {
      // Refund the failing bid
      pendingWithdrawals[existing.bidder] += existing.value;
    }
    punkBids[punkIndex] = Bid(true, punkIndex, msg.sender, msg.value);

    emit PunkBidEntered(punkIndex, msg.value, msg.sender);
  }

  function acceptBidForPunk(uint256 punkIndex, uint256 minPrice) public {
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndexToAddress[punkIndex] == msg.sender, "CryptoPunksMarket: not owner");
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");

    address seller = msg.sender;

    Bid memory bid = punkBids[punkIndex];
    require(bid.value >= minPrice, "CryptoPunksMarket: bid value to small");

    punkIndexToAddress[punkIndex] = bid.bidder;
    balanceOf[seller]--;
    balanceOf[bid.bidder]++;

    emit Transfer(seller, bid.bidder, 1);

    punksOfferedForSale[punkIndex] = Offer(false, punkIndex, bid.bidder, 0, address(0));
    uint256 amount = bid.value;
    punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);
    pendingWithdrawals[seller] += amount;

    emit PunkBought(punkIndex, bid.value, seller, bid.bidder);
  }

  function withdrawBidForPunk(uint256 punkIndex) public {
    require(punkIndex < 10000, "CryptoPunksMarket: punkIndex overflow");
    require(allPunksAssigned, "CryptoPunksMarket: not allPunksAssigned");
    require(punkIndexToAddress[punkIndex] != address(0), "CryptoPunksMarket: punk not assigned");
    require(punkIndexToAddress[punkIndex] != msg.sender, "CryptoPunksMarket: can not withdraw self");

    Bid memory bid = punkBids[punkIndex];
    require(bid.bidder == msg.sender, "CryptoPunksMakrket: not bid bidder");

    emit PunkBidWithdrawn(punkIndex, bid.value, msg.sender);

    uint256 amount = bid.value;

    punkBids[punkIndex] = Bid(false, punkIndex, address(0), 0);

    // Refund the bid money
    _safeTransferETH(msg.sender, amount);
  }

  /**
   * @dev transfer ETH to an address, revert if it fails.
   * @param to recipient of the transfer
   * @param value the amount to send
   */
  function _safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "ETH_TRANSFER_FAILED");
  }
}