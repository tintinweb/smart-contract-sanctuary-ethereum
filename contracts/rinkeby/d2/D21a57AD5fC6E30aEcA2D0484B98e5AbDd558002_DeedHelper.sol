// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

interface ICoinDeedAddressesProvider {
    event FeedRegistryChanged(address feedRegistry);
    event SwapRouterChanged(address router);
    event LendingPoolChanged(address lendingPool);
    event CoinDeedFactoryChanged(address coinDeedFactory);
    event WholesaleFactoryChanged(address wholesaleFactory);
    event DeedTokenChanged(address deedToken);
    event CoinDeedDeployerChanged(address coinDeedDeployer);
    event TreasuryChanged(address treasury);
    event CoinDeedDaoChanged(address coinDeedDao);
    event VaultChanged(address vault);

    function feedRegistry() external view returns (address);
    function swapRouter() external view returns (address);
    function lendingPool() external view returns (address);
    function coinDeedFactory() external view returns (address);
    function wholesaleFactory() external view returns (address);
    function deedToken() external view returns (address);
    function coinDeedDeployer() external view returns (address);
    function treasury() external view returns (address);
    function coinDeedDao() external view returns (address);
    function vault() external view returns (address);
} 

interface ICoinDeedAddressesProviderUtils {
  function tokenRatio(
        ICoinDeedAddressesProvider coinDeedAddressesProvider,
        address tokenA,
        uint256 tokenAAmount,
        address tokenB
    ) external view returns (uint256 tokenBAmount);
}

contract DeedHelper {
  ICoinDeedAddressesProvider coinDeedAddressesProvider;
  ICoinDeedAddressesProviderUtils coinDeedAddressesProviderUtils;

  constructor() {
    coinDeedAddressesProvider = ICoinDeedAddressesProvider(0x109B78c9FD9B9aEa106f0275Bb93A517865c5f19);
    coinDeedAddressesProviderUtils = ICoinDeedAddressesProviderUtils(0xf54c78EedE124D3088bf22aEED21B2802fe1fC40);
  }

  function get(address tokenA, uint256 amount, address tokenB) external view returns(uint256) {
    return coinDeedAddressesProviderUtils.tokenRatio(
      coinDeedAddressesProvider, 
      tokenA,
      amount,
      tokenB
      // 0xd35d2e839d888d1cdbadef7de118b87dfefed20e,
      // 73500000,
      // 0x730129b9ae5a6b3fa6a674a5dc33a84cb1711d07
    );
  }
}