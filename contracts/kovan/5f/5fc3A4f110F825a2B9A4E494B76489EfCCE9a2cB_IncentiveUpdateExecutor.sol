// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import {DataTypes} from '../utils/DataTypes.sol';
import {IAaveEcosystemReserveController} from '../interfaces/IAaveEcosystemReserveController.sol';
import {IAaveIncentivesController} from '../interfaces/IAaveIncentivesController.sol';
import {ILendingPoolData} from '../interfaces/ILendingPoolData.sol';

contract IncentiveUpdateExecutor {

  address constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  address constant CONTROLLER_ECO_RESERVE = 0x1E506cbb6721B83B1549fa1558332381Ffa61A93;
  address constant LENDING_POOL = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
  address constant INCENTIVES_CONTROLLER_PROXY_ADDRESS = 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;

  uint256 constant DISTRIBUTION_DURATION = 7776000;   // 90 days
  uint256 constant DISTRIBUTION_AMOUNT = 97020 ether;

  uint256 constant PROPOSER_GAS_REFUND = 35 ether;
  address constant PROPOSER_REFUND_ADDRESS = 0x6904110f17feD2162a11B5FA66B188d801443Ea4;
  
  function execute() external {

    IAaveEcosystemReserveController ecosystemReserveController = IAaveEcosystemReserveController(CONTROLLER_ECO_RESERVE);
    IAaveIncentivesController incentivesController = IAaveIncentivesController(INCENTIVES_CONTROLLER_PROXY_ADDRESS);

    address payable[19] memory reserves = [
      0x6B175474E89094C44Da98b954EedeAC495271d0F,   // DAI
      0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd,   // GUSD
      0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,   // USDC
      0xdAC17F958D2ee523a2206206994597C13D831ec7,   // USDT
      0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599,   // WBTC
      0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,   // WETH
      0x514910771AF9Ca656af840dff83E8264EcF986CA,   // LINK
      0x57Ab1ec28D129707052df4dF418D58a2D46d5f51,   // sUSD
      0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e,   // YFI
      0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272,   // xSUSHI
      0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2,   // MKR
      0x0000000000085d4780B73119b644AE5ecd22b376,   // TUSD
      0x03ab458634910AaD20eF5f1C8ee96F1D6ac54919,   // RAI
      0xba100000625a3754423978a60c9317c58a424e3D,   // BAL
      0x8E870D67F660D95d5be530380D0eC0bd388289E1,   // USDP
      0x853d955aCEf822Db058eb8505911ED77F175b99e,   // FRAX
      0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b,   // DPI
      0x4Fabb145d64652a948d72533023f6E7A623C7C53,   // BUSD
      0xD533a949740bb3306d119CC777fa900bA034cd52    // CRV
    ];

    uint256[] memory emissions = new uint256[](38);

    emissions[0] = 860629828674028;     // aDAI
    emissions[1] = 1721259657348060;    // vDebtDAI
    emissions[2] = 0;                   // aGUSD
    emissions[3] = 0;                   // vDebtGUSD
    emissions[4] = 1903258773510960;    // aUSDC
    emissions[5] = 3806517547021920;    // vDebtUSDC
    emissions[6] = 694765960976989;     // aUSDT
    emissions[7] = 1389531921953980;    // vDebtUSDT
    emissions[8] = 252193044534425;     // aWBTC
    emissions[9] = 0;                   // vDebtWBTC
    emissions[10] = 933007096551141;    // aWETH
    emissions[11] = 0;                  // vDebtWETH
    emissions[12] = 272977322986304;    // aLINK
    emissions[13] = 0;                  // vDebtLINK
    emissions[14] = 23046648361494;     // aSUSD
    emissions[15] = 46093296722988;     // vDebtSUSD
    emissions[16] = 23204645595171;     // aYFI
    emissions[17] = 0;                  // vDebtYFI
    emissions[18] = 28653877437482;     // aXSUSHI
    emissions[19] = 0;                  // vDebtXSUSHI
    emissions[20] = 109957713960904;    // aMKR
    emissions[21] = 0;                  // vDebtMKR
    emissions[22] = 64158288472709;     // aTUSD
    emissions[23] = 128316576945418;    // vDebtTUSD
    emissions[24] = 9846555646706;      // aRAI
    emissions[25] = 19693111293413;     // vDebtRAI
    emissions[26] = 4875116344638;      // aBAL
    emissions[27] = 0;                  // vDebtBAL
    emissions[28] = 9398984935492;      // aUSDP
    emissions[29] = 18797969870985;     // vDebtUSP
    emissions[30] = 8333031502505;      // aFRAX
    emissions[31] = 16666063005009;     // vDebtFRAX
    emissions[32] = 22409965951501;     // aDPI
    emissions[33] = 0;                  // vDebtDPI
    emissions[34] = 21223932856405;     // aBUSD
    emissions[35] = 42447865712811;     // vDebtBUSD
    emissions[36] = 44508547226299;     // aCRV
    emissions[37] = 0;                  // vDebtCRV

    address[] memory assets = new address[](38);

    for (uint256 i = 0; i < reserves.length; i++) {
      DataTypes.ReserveData memory reserveData = ILendingPoolData(LENDING_POOL).getReserveData(reserves[i]);

      assets[2*i] = reserveData.aTokenAddress;
      assets[2*i+1] = reserveData.variableDebtTokenAddress;
    }

    // Transfer AAVE funds to the Incentives Controller
    ecosystemReserveController.transfer(
      AAVE_TOKEN,
      INCENTIVES_CONTROLLER_PROXY_ADDRESS,
      DISTRIBUTION_AMOUNT
    );

    // Transfer AAVE funds to the proposer to reimburse gas costs
    ecosystemReserveController.transfer(
      AAVE_TOKEN,
      PROPOSER_REFUND_ADDRESS,
      PROPOSER_GAS_REFUND
    );

    // Enable incentives in aTokens and Variable Debt tokens
    incentivesController.configureAssets(assets, emissions);

    // Sets the end date for the distribution
    incentivesController.setDistributionEnd(block.timestamp + DISTRIBUTION_DURATION);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
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
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
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

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

interface IAaveEcosystemReserveController {
  function AAVE_RESERVE_ECOSYSTEM() external view returns (address);

  function approve(
    address token,
    address recipient,
    uint256 amount
  ) external;

  function owner() external view returns (address);

  function renounceOwnership() external;

  function transfer(
    address token,
    address recipient,
    uint256 amount
  ) external;

  function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

pragma experimental ABIEncoderV2;

import {IAaveDistributionManager} from '../interfaces/IAaveDistributionManager.sol';

interface IAaveIncentivesController is IAaveDistributionManager {
  
  event RewardsAccrued(address indexed user, uint256 amount);
  
  event RewardsClaimed(
    address indexed user,
    address indexed to,
    address indexed claimer,
    uint256 amount
  );

  event ClaimerSet(address indexed user, address indexed claimer);

  /**
   * @dev Whitelists an address to claim the rewards on behalf of another address
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
   * @param user The address of the user
   * @return The claimer address
   */
  function getClaimer(address user) external view returns (address);

  /**
   * @dev Configure assets for a certain rewards emission
   * @param assets The assets to incentivize
   * @param emissionsPerSecond The emission for each asset
   */
  function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond)
    external;


  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param asset The address of the user
   * @param userBalance The balance of the user of the asset in the lending pool
   * @param totalSupply The total supply of the asset in the lending pool
   **/
  function handleAction(
    address asset,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

  /**
   * @dev Returns the total of rewards of an user, already accrued + not yet accrued
   * @param user The address of the user
   * @return The rewards
   **/
  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  /**
   * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
   * @param amount Amount of rewards to claim
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
   * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param amount Amount of rewards to claim
   * @param user Address to check and claim rewards
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to
  ) external returns (uint256);

  /**
   * @dev returns the unclaimed rewards of the user
   * @param user the address of the user
   * @return the unclaimed user rewards
   */
  function getUserUnclaimedRewards(address user) external view returns (uint256);

  /**
  * @dev for backward compatibility with previous implementation of the Incentives controller
  */
  function REWARD_TOKEN() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import {DistributionTypes} from '../lib/DistributionTypes.sol';

interface IAaveDistributionManager {
  
  event AssetConfigUpdated(address indexed asset, uint256 emission);
  event AssetIndexUpdated(address indexed asset, uint256 index);
  event UserIndexUpdated(address indexed user, address indexed asset, uint256 index);
  event DistributionEndUpdated(uint256 newDistributionEnd);

  /**
  * @dev Sets the end date for the distribution
  * @param distributionEnd The end date timestamp
  **/
  function setDistributionEnd(uint256 distributionEnd) external;

  /**
  * @dev Gets the end date for the distribution
  * @return The end of the distribution
  **/
  function getDistributionEnd() external view returns (uint256);

  /**
  * @dev for backwards compatibility with the previous DistributionManager used
  * @return The end of the distribution
  **/
  function DISTRIBUTION_END() external view returns(uint256);

   /**
   * @dev Returns the data of an user on a distribution
   * @param user Address of the user
   * @param asset The address of the reference asset of the distribution
   * @return The new index
   **/
   function getUserAssetData(address user, address asset) external view returns (uint256);

   /**
   * @dev Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index, the emission per second and the last updated timestamp
   **/
   function getAssetData(address asset) external view returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

library DistributionTypes {
  struct AssetConfigInput {
    uint104 emissionPerSecond;
    uint256 totalStaked;
    address underlyingAsset;
  }

  struct UserStakeInput {
    address underlyingAsset;
    uint256 stakedByUser;
    uint256 totalStaked;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import {DataTypes} from '../utils/DataTypes.sol';

interface ILendingPoolData {
  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
}