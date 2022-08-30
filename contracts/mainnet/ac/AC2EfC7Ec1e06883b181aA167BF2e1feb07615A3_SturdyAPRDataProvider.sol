// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IPriceOracle} from '../interfaces/IPriceOracle.sol';
import {ILidoOracle} from '../interfaces/ILidoOracle.sol';
import {ILido} from '../interfaces/ILido.sol';
import {IConvexBooster} from '../interfaces/IConvexBooster.sol';
import {IProtocolDataProvider} from '../interfaces/IProtocolDataProvider.sol';
import {ICurvePool} from '../interfaces/ICurvePool.sol';
import {IConvexBaseRewardPool} from '../interfaces/IConvexBaseRewardPool.sol';
import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from '../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {ICollateralAdapter} from '../interfaces/ICollateralAdapter.sol';
import {IIncentiveVault} from '../interfaces/IIncentiveVault.sol';
import {IGeneralVault} from '../interfaces/IGeneralVault.sol';
import {ILendingPool} from '../interfaces/ILendingPool.sol';
import {PercentageMath} from '../protocol/libraries/math/PercentageMath.sol';
import {ReserveConfiguration} from '../protocol/libraries/configuration/ReserveConfiguration.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {Errors} from '../protocol/libraries/helpers/Errors.sol';

contract SturdyAPRDataProvider is Ownable {
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  struct ConvexPoolInfo {
    uint256 poolId;
    address poolAddress;
  }

  address private constant LIDO = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
  address private constant LIDO_ORACLE = 0x442af784A788A5bd6F42A01Ebe9F287a871243fb;
  address private constant CONVEX_BOOSTER = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
  address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
  address private constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
  address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  uint256 private constant STURDY_FEE = 10_00;
  uint256 private constant CVX_CLIFF_SIZE = 1e23; // new cliff every 100,000 tokens
  uint256 private constant CVX_CLIFF_COUNT = 1000; //1,000 cliffs
  uint256 private constant CVX_MAX_SUPPLY = 1e26; //100 mil max supply
  uint256 private constant YEAR_BLOCK_CNT = 2_102_400; // 4 * 60 * 24 * 365

  IProtocolDataProvider private immutable DATA_PROVIDER;
  IPriceOracle private immutable ORACLE;
  ICollateralAdapter private immutable COLLATERAL_ADAPTER;
  ILendingPool private immutable LENDING_POOL;

  // convex reserve's internal asset -> convex pool info
  mapping(address => ConvexPoolInfo) internal convexReserves;

  //borrow reserve's yield ratio with wad decimal(=18) and previous yield processing block number
  mapping(address => uint256) public prevBlock;
  mapping(address => uint256) public yieldRatio;

  modifier onlyLendingPool() {
    require(msg.sender == address(LENDING_POOL), Errors.CT_CALLER_MUST_BE_LENDING_POOL);
    _;
  }

  constructor(address _provider) public {
    DATA_PROVIDER = IProtocolDataProvider(_provider);
    ORACLE = IPriceOracle(DATA_PROVIDER.ADDRESSES_PROVIDER().getPriceOracle());
    COLLATERAL_ADAPTER = ICollateralAdapter(
      DATA_PROVIDER.ADDRESSES_PROVIDER().getAddress('COLLATERAL_ADAPTER')
    );
    LENDING_POOL = ILendingPool(DATA_PROVIDER.ADDRESSES_PROVIDER().getLendingPool());
    prevBlock[DAI] = block.number;
    prevBlock[USDC] = block.number;
    prevBlock[USDT] = block.number;
  }

  function registerConvexReserve(
    address _reserve,
    uint256 _poolId,
    address _poolAddress
  ) external payable onlyOwner {
    convexReserves[_reserve] = ConvexPoolInfo(_poolId, _poolAddress);
  }

  /**
   * @dev Update reserve's APR based on yield
   */
  function updateAPR(
    address _borrowReserve,
    uint256 _yield,
    uint256 _totalSupply
  ) external onlyLendingPool {
    uint256 ratioInWad = (1e18 * _yield) / _totalSupply;
    yieldRatio[_borrowReserve] =
      (ratioInWad * YEAR_BLOCK_CNT) /
      (block.number - prevBlock[_borrowReserve]);
    prevBlock[_borrowReserve] = block.number;
  }

  /**
   * @dev Get APR with wad decimal(=18)
   */
  function APR(address _borrowReserve, bool _not_real) external view returns (uint256) {
    if (_not_real) {
      return _getAPRBasedonYield(_borrowReserve);
    }

    address[] memory reserves = LENDING_POOL.getReservesList();
    uint256 reserveCount = reserves.length;
    uint256 totalYieldInPrice;
    uint256 totalBorrowableLiquidityInPrice = _getTotalLiquidity(DAI, true) +
      _getTotalLiquidity(USDC, true) +
      _getTotalLiquidity(USDT, true);

    for (uint256 i; i < reserveCount; ++i) {
      DataTypes.ReserveConfigurationMap memory reserveConfiguration = LENDING_POOL.getConfiguration(
        reserves[i]
      );
      (, , , , bool isCollateral) = reserveConfiguration.getFlagsMemory();
      if (!isCollateral) continue;

      if (reserves[i] == LIDO) {
        totalYieldInPrice += _lidoVaultYieldInPrice();
      } else {
        totalYieldInPrice += _convexVaultYieldInPrice(reserves[i]);
      }
    }

    uint256 totalVaultAPR = totalYieldInPrice / totalBorrowableLiquidityInPrice;
    uint256 liquidityRate = uint256(
      LENDING_POOL.getReserveData(_borrowReserve).currentLiquidityRate
    ) / 1e9; // dividing by 1e9 to pass from ray to wad

    return totalVaultAPR + liquidityRate;
  }

  /**
   * @dev Get vault APR with wad decimal(=18)
   * @param _reserve - vault's internal asset address
   */
  function vaultReserveAPR(address _reserve) external view returns (uint256) {
    uint256 totalBorrowableLiquidityInPrice = _getTotalLiquidity(DAI, true) +
      _getTotalLiquidity(USDC, true) +
      _getTotalLiquidity(USDT, true);

    if (_reserve == LIDO) {
      return _lidoVaultYieldInPrice() / totalBorrowableLiquidityInPrice;
    }

    return _convexVaultYieldInPrice(_reserve) / totalBorrowableLiquidityInPrice;
  }

  /**
   * @dev Get APR with wad decimal(=18)
   */
  function _getAPRBasedonYield(address _borrowReserve) internal view returns (uint256) {
    return yieldRatio[_borrowReserve];
  }

  /**
   * @dev Get lidoVault Yield per year with wad decimal(=18)
   */
  function _lidoVaultYieldInPrice() internal view returns (uint256) {
    uint256 stETHCollateralInPrice = _getTotalLiquidity(LIDO, true);
    uint256 stETHYieldInPrice = (_lidoAPR() * stETHCollateralInPrice).percentMul(
      PercentageMath.PERCENTAGE_FACTOR - STURDY_FEE
    );

    return stETHYieldInPrice;
  }

  /**
   * @dev Get convexVault Yield per year with wad decimal(=18)
   * @param _reserve - convex vault's internal asset address
   */
  function _convexVaultYieldInPrice(address _reserve) internal view returns (uint256) {
    ConvexPoolInfo memory reserveInfo = convexReserves[_reserve];
    if (reserveInfo.poolAddress == address(0)) {
      return _fallbackVaultYieldInPrice(_reserve);
    }

    IConvexBooster.PoolInfo memory poolInfo = IConvexBooster(CONVEX_BOOSTER).poolInfo(
      reserveInfo.poolId
    );
    // lptoken is external asset of convex vault
    address vault = COLLATERAL_ADAPTER.getAcceptableVault(poolInfo.lptoken);
    uint256 incentiveFee = IIncentiveVault(vault).getIncentiveRatio();

    uint256 convexLPCollateral = _getTotalLiquidity(_reserve, false);
    uint8 decimals = IERC20Detailed(_reserve).decimals();
    (uint256 crvAPYInPrice, uint256 cvxAPYInPrice) = _convexCRVCVXAPYInPrice(
      poolInfo.crvRewards,
      reserveInfo.poolAddress
    );
    uint256 convexLPYieldInPrice = ((crvAPYInPrice.percentMul(
      PercentageMath.PERCENTAGE_FACTOR - STURDY_FEE - incentiveFee
    ) + cvxAPYInPrice.percentMul(PercentageMath.PERCENTAGE_FACTOR - STURDY_FEE)) *
      convexLPCollateral) / 10**decimals;

    return convexLPYieldInPrice * 1e18;
  }

  /**
   * @dev Get other vault Yield per year with wad decimal(=18)
   * @param _reserve - vault's internal asset address
   */
  function _fallbackVaultYieldInPrice(address _reserve) internal view returns (uint256) {
    address externalAsset = COLLATERAL_ADAPTER.getExternalCollateralAsset(_reserve);
    IGeneralVault vault = IGeneralVault(COLLATERAL_ADAPTER.getAcceptableVault(externalAsset));
    return vault.vaultYieldInPrice();
  }

  /**
   * @dev APR percent value with wad decimal(=18)
   */
  function _lidoAPR() internal view returns (uint256) {
    (uint256 postTotalPooledEther, uint256 preTotalPooledEther, uint256 timeElapsed) = ILidoOracle(
      LIDO_ORACLE
    ).getLastCompletedReportDelta();
    uint256 lidoFee = uint256(ILido(LIDO).getFee());
    uint256 protocolAPR = ((postTotalPooledEther - preTotalPooledEther) * 365 days * 1e18) /
      (preTotalPooledEther * timeElapsed);

    return protocolAPR.percentMul(PercentageMath.PERCENTAGE_FACTOR - lidoFee);
  }

  /**
   * @dev CRV/CVX APY in price
   * @param _stakeContract - convex LP pool's crvRewards address
   * @param _poolAddress - convex LP pool address
   */
  function _convexCRVCVXAPYInPrice(address _stakeContract, address _poolAddress)
    internal
    view
    returns (uint256, uint256)
  {
    uint256 virtualPrice = ICurvePool(_poolAddress).get_virtual_price(); //decimal 18
    uint256 rate = IConvexBaseRewardPool(_stakeContract).rewardRate(); //decimal 18
    uint256 supply = IConvexBaseRewardPool(_stakeContract).totalSupply(); //decimal 18

    // crvPerUnderlying = rate / ((supply / 1e18) * (virtualPrice / 1e18))
    uint256 crvPerUnderlying = (rate * 1e36) / (supply * virtualPrice);
    uint256 crvPerYear = crvPerUnderlying * 365 days;
    uint256 cvxPerYear = _getCVXMintAmount(crvPerYear);
    return (
      (crvPerYear * ORACLE.getAssetPrice(CRV)) / 1e18,
      (cvxPerYear * ORACLE.getAssetPrice(CVX)) / 1e18
    ); //crv/cvx decimal 18
  }

  function _getTotalLiquidity(address _asset, bool _inPrice)
    internal
    view
    returns (uint256 totalLiquidity)
  {
    uint8 decimals = IERC20Detailed(_asset).decimals();
    (
      uint256 availbleLiquidity,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      ,
      ,
      ,
      ,
      ,
      ,

    ) = DATA_PROVIDER.getReserveData(_asset);
    totalLiquidity = (totalLiquidity + availbleLiquidity + totalStableDebt + totalVariableDebt);
    if (_inPrice) {
      totalLiquidity = (totalLiquidity * ORACLE.getAssetPrice(_asset)) / 10**decimals;
    }
  }

  function _getCVXMintAmount(uint256 _crvEarned) internal view returns (uint256) {
    //first get total supply
    uint256 cvxSupply = IERC20(CVX).totalSupply();

    //get current cliff
    uint256 currentCliff = cvxSupply / CVX_CLIFF_SIZE;
    if (currentCliff < CVX_CLIFF_COUNT) {
      //get remaining cliffs
      uint256 remaining = CVX_CLIFF_COUNT - currentCliff;

      //multiply ratio of remaining cliffs to total cliffs against amount CRV received
      uint256 cvxEarned = (_crvEarned * remaining) / CVX_CLIFF_COUNT;

      //double check we have not gone over the max supply
      uint256 amountTillMax = CVX_MAX_SUPPLY - cvxSupply;
      if (cvxEarned > amountTillMax) {
        cvxEarned = amountTillMax;
      }

      return cvxEarned;
    }

    return 0;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/************
@title IPriceOracle interface
@notice Interface for the Sturdy price oracle.*/
interface IPriceOracle {
  /***********
    @dev returns the asset price in ETH
     */
  function getAssetPrice(address asset) external view returns (uint256);

  /***********
    @dev sets the asset price, in wei
     */
  function setAssetPrice(address asset, uint256 price) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ILidoOracle {
  function getLastCompletedReportDelta()
    external
    view
    returns (
      uint256 postTotalPooledEther,
      uint256 preTotalPooledEther,
      uint256 timeElapsed
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ILido {
  /**
   * @dev From ISTETH interface, because "Interfaces cannot inherit".
   */
  function totalSupply() external view returns (uint256);

  function getTotalShares() external view returns (uint256);

  /**
   * @notice Stop pool routine operations
   */
  function stop() external;

  /**
   * @notice Resume pool routine operations
   */
  function resume() external;

  event Stopped();
  event Resumed();

  /**
   * @notice Set fee rate to `_feeBasisPoints` basis points. The fees are accrued when oracles report staking results
   * @param _feeBasisPoints Fee rate, in basis points
   */
  function setFee(uint16 _feeBasisPoints) external;

  /**
   * @notice Set fee distribution: `_treasuryFeeBasisPoints` basis points go to the treasury, `_insuranceFeeBasisPoints` basis points go to the insurance fund, `_operatorsFeeBasisPoints` basis points go to node operators. The sum has to be 10 000.
   */
  function setFeeDistribution(
    uint16 _treasuryFeeBasisPoints,
    uint16 _insuranceFeeBasisPoints,
    uint16 _operatorsFeeBasisPoints
  ) external;

  /**
   * @notice Returns staking rewards fee rate
   */
  function getFee() external view returns (uint16 feeBasisPoints);

  /**
   * @notice Returns fee distribution proportion
   */
  function getFeeDistribution()
    external
    view
    returns (
      uint16 treasuryFeeBasisPoints,
      uint16 insuranceFeeBasisPoints,
      uint16 operatorsFeeBasisPoints
    );

  event FeeSet(uint16 feeBasisPoints);

  event FeeDistributionSet(
    uint16 treasuryFeeBasisPoints,
    uint16 insuranceFeeBasisPoints,
    uint16 operatorsFeeBasisPoints
  );

  /**
   * @notice Set credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched to `_withdrawalCredentials`
   * @dev Note that setWithdrawalCredentials discards all unused signing keys as the signatures are invalidated.
   * @param _withdrawalCredentials hash of withdrawal multisignature key as accepted by
   *        the deposit_contract.deposit function
   */
  function setWithdrawalCredentials(bytes32 _withdrawalCredentials) external;

  /**
   * @notice Returns current credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched
   */
  function getWithdrawalCredentials() external view returns (bytes memory);

  event WithdrawalCredentialsSet(bytes32 withdrawalCredentials);

  /**
   * @notice Ether on the ETH 2.0 side reported by the oracle
   * @param _epoch Epoch id
   * @param _eth2balance Balance in wei on the ETH 2.0 side
   */
  function pushBeacon(uint256 _epoch, uint256 _eth2balance) external;

  // User functions

  /**
   * @notice Adds eth to the pool
   * @return StETH Amount of StETH generated
   */
  function submit(address _referral) external payable returns (uint256 StETH);

  // Records a deposit made by a user
  event Submitted(address indexed sender, uint256 amount, address referral);

  // The `_amount` of ether was sent to the deposit_contract.deposit function.
  event Unbuffered(uint256 amount);

  /**
   * @notice Issues withdrawal request. Large withdrawals will be processed only after the phase 2 launch.
   * @param _amount Amount of StETH to burn
   * @param _pubkeyHash Receiving address
   */
  function withdraw(uint256 _amount, bytes32 _pubkeyHash) external;

  // Requested withdrawal of `etherAmount` to `pubkeyHash` on the ETH 2.0 side, `tokenAmount` burned by `sender`,
  // `sentFromBuffer` was sent on the current Ethereum side.
  event Withdrawal(
    address indexed sender,
    uint256 tokenAmount,
    uint256 sentFromBuffer,
    bytes32 indexed pubkeyHash,
    uint256 etherAmount
  );

  // Info functions

  /**
   * @notice Gets the amount of Ether controlled by the system
   */
  function getTotalPooledEther() external view returns (uint256);

  /**
   * @notice Gets the amount of Ether temporary buffered on this contract balance
   */
  function getBufferedEther() external view returns (uint256);

  /**
   * @notice Returns the key values related to Beacon-side
   * @return depositedValidators - number of deposited validators
   * @return beaconValidators - number of Lido's validators visible in the Beacon state, reported by oracles
   * @return beaconBalance - total amount of Beacon-side Ether (sum of all the balances of Lido validators)
   */
  function getBeaconStat()
    external
    view
    returns (
      uint256 depositedValidators,
      uint256 beaconValidators,
      uint256 beaconBalance
    );

  function balanceOf(address _account) external view returns (uint256);

  function depositBufferedEther() external;

  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) external returns (bool);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IConvexBooster {
  struct PoolInfo {
    address lptoken;
    address token;
    address gauge;
    address crvRewards;
    address stash;
    bool shutdown;
  }

  function minter() external view returns (address);

  function poolInfo(uint256 _poolId) external view returns (PoolInfo memory);

  function poolLength() external view returns (uint256);

  //deposit lp tokens and stake
  function deposit(
    uint256 _pid,
    uint256 _amount,
    bool _stake
  ) external returns (bool);

  //withdraw lp tokens
  function withdraw(uint256 _pid, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';

interface IProtocolDataProvider {
  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

  function getAllReservesTokens() external view returns (TokenData[] memory);

  function getAllATokens() external view returns (TokenData[] memory);

  function getReserveConfigurationData(address asset)
    external
    view
    returns (
      uint256 decimals,
      uint256 ltv,
      uint256 liquidationThreshold,
      uint256 liquidationBonus,
      uint256 reserveFactor,
      bool usageAsCollateralEnabled,
      bool borrowingEnabled,
      bool stableBorrowRateEnabled,
      bool isActive,
      bool isFrozen
    );

  function getReserveData(address asset)
    external
    view
    returns (
      uint256 availableLiquidity,
      uint256 totalStableDebt,
      uint256 totalVariableDebt,
      uint256 liquidityRate,
      uint256 variableBorrowRate,
      uint256 stableBorrowRate,
      uint256 averageStableBorrowRate,
      uint256 liquidityIndex,
      uint256 variableBorrowIndex,
      uint40 lastUpdateTimestamp
    );

  function getUserReserveData(address asset, address user)
    external
    view
    returns (
      uint256 currentATokenBalance,
      uint256 currentStableDebt,
      uint256 currentVariableDebt,
      uint256 principalStableDebt,
      uint256 scaledVariableDebt,
      uint256 stableBorrowRate,
      uint256 liquidityRate,
      uint40 stableRateLastUpdated,
      bool usageAsCollateralEnabled
    );

  function getReserveTokensAddresses(address asset)
    external
    view
    returns (
      address aTokenAddress,
      address stableDebtTokenAddress,
      address variableDebtTokenAddress
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ICurvePool {
  function get_virtual_price() external view returns (uint256 price);

  function coins(uint256) external view returns (address);

  function calc_withdraw_one_coin(
    uint256 _burn_amount,
    int128 i,
    bool _previous
  ) external view returns (uint256);

  function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _burn_amount,
    int128 i,
    uint256 _min_received,
    address _receiver
  ) external returns (uint256);

  function remove_liquidity_one_coin(
    uint256 _burn_amount,
    int128 i,
    uint256 _min_received
  ) external;

  /**
   * @dev Index values can be found via the `coins` public getter method
   * @param i Index value for the coin to send
   * @param j Index valie of the coin to recieve
   * @param dx Amount of `i` being exchanged
   * @param min_dy Minimum amount of `j` to receive
   * @return Actual amount of `j` received
   **/
  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external payable returns (uint256);

  function get_dy(
    int128 i,
    int128 j,
    uint256 dx
  ) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IConvexBaseRewardPool {
  function earned(address account) external view returns (uint256);

  function withdrawAndUnwrap(uint256 amount, bool claim) external;

  function getReward(address _account, bool _claimExtras) external;

  function getReward() external;

  function rewardToken() external view returns (address);

  function extraRewardsLength() external view returns (uint256);

  function extraRewards(uint256) external view returns (address);

  function rewardRate() external view returns (uint256);

  function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IERC20} from './IERC20.sol';

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title ICollateralAdapter
 * @author Sturdy
 * @notice Defines the relation between external/internal collateral assets and acceptable vaults.
 **/
interface ICollateralAdapter {
  function getAcceptableVault(address _externalAsset) external view returns (address);

  function getInternalCollateralAsset(address _externalAsset) external view returns (address);

  function getExternalCollateralAsset(address _internalAsset) external view returns (address);

  function addCollateralAsset(
    address _externalAsset,
    address _internalAsset,
    address _acceptVault
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IIncentiveVault {
  function getIncentiveRatio() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IGeneralVault {
  function pricePerShare() external view returns (uint256);

  function vaultYieldInPrice() external view returns (uint256);

  function withdrawOnLiquidation(address _asset, uint256 _amount) external returns (uint256);

  function convertOnLiquidation(address _assetOut, uint256 _amountIn) external;

  function processYield() external;

  function getYieldAmount() external view returns (uint256);

  function setTreasuryInfo(address _treasury, uint256 _fee) external;

  function depositCollateral(address _asset, uint256 _amount) external payable;

  function depositCollateralFrom(
    address _asset,
    uint256 _amount,
    address _user
  ) external payable;

  function withdrawCollateral(
    address _asset,
    uint256 _amount,
    uint256 _slippage,
    address _to
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
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
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * - Caller is anyone.
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve for supplier from vault
   * - Caller is only Vault which is registered in this contract
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   **/
  function depositYield(address asset, uint256 amount) external;

  /**
   * @dev Grab an Yield `amount` of underlying asset into the vault
   * - Caller is only Vault which is registered in this contract
   * @param asset The address of the underlying asset to get yield
   * @param amount The yield amount
   **/
  function getYield(address asset, uint256 amount) external;

  /**
   * @dev Get underlying asset and aToken's total balance
   * @param asset The address of the underlying asset
   **/
  function getTotalBalanceOfAssetPair(address asset) external view returns (uint256, uint256);

  /**
   * @dev Get total underlying asset which is borrowable
   *  and also list of underlying asset
   **/
  function getBorrowingAssetAndVolumes()
    external
    view
    returns (
      uint256,
      uint256[] memory,
      address[] memory,
      uint256
    );

  /**
   * @dev Register the vault address
   * - To check if the caller is vault for some functions
   * - Caller is only LendingPoolConfigurator
   * @param _vaultAddress The address of the Vault
   **/
  function registerVault(address _vaultAddress) external payable;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * - E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * - Caller is anyone
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * - E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * - Caller is anyone
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param from The address of user who is depositor of underlying asset
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdrawFrom(
    address asset,
    uint256 amount,
    address from,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * - Caller is anyone
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * - Caller is anyone
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * - Caller is anyone
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  /**
   * @dev Initializes a reserve, activating it, assigning an aToken and debt tokens and an
   * interest rate strategy
   * - Only callable by the LendingPoolConfigurator contract
   * - Caller is only LendingPoolConfigurator
   * @param reserve The address of the underlying asset of the reserve
   * @param yieldAddress The address of the underlying asset's yield contract of the reserve
   * @param aTokenAddress The address of the aToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address reserve,
    address yieldAddress,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external payable;

  /**
   * @dev Updates the address of the interest rate strategy contract
   * - Caller is only LendingPoolConfigurator
   * @param reserve The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external
    payable;

  /**
   * @dev Sets the configuration bitmap of the reserve as a whole
   * - Caller is only LendingPoolConfigurator
   * @param reserve The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setConfiguration(address reserve, uint256 configuration) external payable;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

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

  /**
   * @dev Validates and finalizes an aToken transfer
   * - Only callable by the overlying aToken of the `asset`
   * - Caller is only aToken contract which is storing the underlying asset of depositors
   * @param asset The address of the underlying asset of the aToken
   * @param from The user from which the aTokens are transferred
   * @param to The user receiving the aTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromAfter The aToken balance of the `from` user before the transfer
   * @param balanceToBefore The aToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  /**
   * @dev Returns the list of the initialized reserves
   **/
  function getReservesList() external view returns (address[] memory);

  /**
   * @dev Returns the cached LendingPoolAddressesProvider connected to this contract
   **/
  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  /**
   * @dev Set the _pause state of a reserve
   * - Caller is only LendingPoolConfigurator
   * @param val `true` to pause the reserve, `false` to un-pause it
   */
  function setPause(bool val) external payable;

  /**
   * @dev Returns if the LendingPool is paused
   */
  function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {Errors} from '../helpers/Errors.sol';

/**
 * @title PercentageMath library
 * @author Sturdy, inspiration from Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

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

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
    uint256 halfPercentage = percentage / 2;

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title ReserveConfiguration library
 * @author Sturdy, inspiration from Aave
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
  uint256 constant COLLATERAL_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
  uint256 constant COLLATERAL_ENABLED_START_BIT_POSITION = 60;
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
  function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold)
    internal
    pure
  {
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.RC_INVALID_LIQ_THRESHOLD);

    self.data =
      (self.data & LIQUIDATION_THRESHOLD_MASK) |
      (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @return The liquidation threshold
   **/
  function getLiquidationThreshold(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (uint256)
  {
    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @dev Sets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @param bonus The new liquidation bonus
   **/
  function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus)
    internal
    pure
  {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.RC_INVALID_LIQ_BONUS);

    self.data =
      (self.data & LIQUIDATION_BONUS_MASK) |
      (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @return The liquidation bonus
   **/
  function getLiquidationBonus(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (uint256)
  {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @dev Sets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @param decimals The decimals
   **/
  function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals)
    internal
    pure
  {
    require(decimals <= MAX_VALID_DECIMALS, Errors.RC_INVALID_DECIMALS);

    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
  }

  /**
   * @dev Gets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @return The decimals of the asset
   **/
  function getDecimals(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (uint256)
  {
    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
  }

  /**
   * @dev Sets the active state of the reserve
   * @param self The reserve configuration
   * @param active The active state
   **/
  function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
    self.data =
      (self.data & ACTIVE_MASK) |
      (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
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
    self.data =
      (self.data & FROZEN_MASK) |
      (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
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
  function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled)
    internal
    pure
  {
    self.data =
      (self.data & BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @dev Gets the borrowing state of the reserve
   * @param self The reserve configuration
   * @return The borrowing state
   **/
  function getBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (bool)
  {
    return (self.data & ~BORROWING_MASK) != 0;
  }

  /**
   * @dev Sets the collateral state of the reserve
   * @param self The reserve configuration
   * @param enabled The collateral state
   **/
  function setCollateralEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled)
    internal
    pure
  {
    self.data =
      (self.data & COLLATERAL_MASK) |
      (uint256(enabled ? 1 : 0) << COLLATERAL_ENABLED_START_BIT_POSITION);
  }

  /**
   * @dev Gets the collateral state of the reserve
   * @param self The reserve configuration
   * @return The collateral state
   **/
  function getCollateralEnabled(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (bool)
  {
    return (self.data & ~COLLATERAL_MASK) != 0;
  }

  /**
   * @dev Enables or disables stable rate borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
   **/
  function setStableRateBorrowingEnabled(
    DataTypes.ReserveConfigurationMap memory self,
    bool enabled
  ) internal pure {
    self.data =
      (self.data & STABLE_BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @dev Gets the stable rate borrowing state of the reserve
   * @param self The reserve configuration
   * @return The stable rate borrowing state
   **/
  function getStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (bool)
  {
    return (self.data & ~STABLE_BORROWING_MASK) != 0;
  }

  /**
   * @dev Sets the reserve factor of the reserve
   * @param self The reserve configuration
   * @param reserveFactor The reserve factor
   **/
  function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor)
    internal
    pure
  {
    require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.RC_INVALID_RESERVE_FACTOR);

    self.data =
      (self.data & RESERVE_FACTOR_MASK) |
      (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
  }

  /**
   * @dev Gets the reserve factor of the reserve
   * @param self The reserve configuration
   * @return The reserve factor
   **/
  function getReserveFactor(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (uint256)
  {
    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

  /**
   * @dev Gets the configuration flags of the reserve
   * @param self The reserve configuration
   * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled, collateral enabled
   **/
  function getFlags(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (
      bool,
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
      (dataLocal & ~STABLE_BORROWING_MASK) != 0,
      (dataLocal & ~COLLATERAL_MASK) != 0
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
   * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled, collateral enabled
   **/
  function getFlagsMemory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      bool,
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
      (self.data & ~STABLE_BORROWING_MASK) != 0,
      (self.data & ~COLLATERAL_MASK) != 0
    );
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

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
    //address of the yield contract
    address yieldAddress;
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

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Context.sol';

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public payable virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public payable virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author Sturdy, inspiration from Aave
 * @notice Defines the error messages emitted by the different contracts of the Sturdy protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - AT = AToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = LendingPoolAddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolCollateralManager
 *  - P = Pausable
 */
library Errors {
  //common errors
  string internal constant CALLER_NOT_POOL_ADMIN = '33'; // 'The caller must be the pool admin'
  string internal constant BORROW_ALLOWANCE_NOT_ENOUGH = '59'; // User borrows on behalf, but allowance are too small

  //contract specific errors
  string internal constant VL_INVALID_AMOUNT = '1'; // 'Amount must be greater than 0'
  string internal constant VL_NO_ACTIVE_RESERVE = '2'; // 'Action requires an active reserve'
  string internal constant VL_RESERVE_FROZEN = '3'; // 'Action cannot be performed because the reserve is frozen'
  string internal constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = '4'; // 'The current liquidity is not enough'
  string internal constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // 'User cannot withdraw more than the available balance'
  string internal constant VL_TRANSFER_NOT_ALLOWED = '6'; // 'Transfer cannot be allowed.'
  string internal constant VL_BORROWING_NOT_ENABLED = '7'; // 'Borrowing is not enabled'
  string internal constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '8'; // 'Invalid interest rate mode selected'
  string internal constant VL_COLLATERAL_BALANCE_IS_0 = '9'; // 'The collateral balance is 0'
  string internal constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '10'; // 'Health factor is lesser than the liquidation threshold'
  string internal constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = '11'; // 'There is not enough collateral to cover a new borrow'
  string internal constant VL_STABLE_BORROWING_NOT_ENABLED = '12'; // stable borrowing not enabled
  string internal constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = '13'; // collateral is (mostly) the same currency that is being borrowed
  string internal constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '14'; // 'The requested amount is greater than the max loan size in stable rate mode
  string internal constant VL_NO_DEBT_OF_SELECTED_TYPE = '15'; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string internal constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '16'; // 'To repay on behalf of an user an explicit amount to repay is needed'
  string internal constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = '17'; // 'User does not have a stable rate loan in progress on this reserve'
  string internal constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = '18'; // 'User does not have a variable rate loan in progress on this reserve'
  string internal constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // 'The underlying balance needs to be greater than 0'
  string internal constant VL_DEPOSIT_ALREADY_IN_USE = '20'; // 'User deposit is already being used as collateral'
  string internal constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = '21'; // 'User does not have any stable rate loan for this reserve'
  string internal constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '22'; // 'Interest rate rebalance conditions were not met'
  string internal constant LP_LIQUIDATION_CALL_FAILED = '23'; // 'Liquidation call failed'
  string internal constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = '24'; // 'There is not enough liquidity available to borrow'
  string internal constant LP_REQUESTED_AMOUNT_TOO_SMALL = '25'; // 'The requested amount is too small for a FlashLoan.'
  string internal constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = '26'; // 'The actual balance of the protocol is inconsistent'
  string internal constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = '27'; // 'The caller of the function is not the lending pool configurator'
  string internal constant LP_INCONSISTENT_FLASHLOAN_PARAMS = '28';
  string internal constant CT_CALLER_MUST_BE_LENDING_POOL = '29'; // 'The caller of this function must be a lending pool'
  string internal constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = '30'; // 'User cannot give allowance to himself'
  string internal constant CT_TRANSFER_AMOUNT_NOT_GT_0 = '31'; // 'Transferred amount needs to be greater than zero'
  string internal constant RL_RESERVE_ALREADY_INITIALIZED = '32'; // 'Reserve has already been initialized'
  string internal constant LPC_RESERVE_LIQUIDITY_NOT_0 = '34'; // 'The liquidity of the reserve needs to be 0'
  string internal constant LPC_INVALID_ATOKEN_POOL_ADDRESS = '35'; // 'The liquidity of the reserve needs to be 0'
  string internal constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = '36'; // 'The liquidity of the reserve needs to be 0'
  string internal constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = '37'; // 'The liquidity of the reserve needs to be 0'
  string internal constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '38'; // 'The liquidity of the reserve needs to be 0'
  string internal constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '39'; // 'The liquidity of the reserve needs to be 0'
  string internal constant LPC_INVALID_ADDRESSES_PROVIDER_ID = '40'; // 'The liquidity of the reserve needs to be 0'
  string internal constant LPC_INVALID_CONFIGURATION = '75'; // 'Invalid risk parameters for the reserve'
  string internal constant LPC_CALLER_NOT_EMERGENCY_ADMIN = '76'; // 'The caller must be the emergency admin'
  string internal constant LPAPR_PROVIDER_NOT_REGISTERED = '41'; // 'Provider is not registered'
  string internal constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '42'; // 'Health factor is not below the threshold'
  string internal constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = '43'; // 'The collateral chosen cannot be liquidated'
  string internal constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '44'; // 'User did not borrow the specified currency'
  string internal constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = '45'; // "There isn't enough liquidity available to liquidate"
  string internal constant LPCM_NO_ERRORS = '46'; // 'No errors'
  string internal constant LP_INVALID_FLASHLOAN_MODE = '47'; //Invalid flashloan mode selected
  string internal constant MATH_MULTIPLICATION_OVERFLOW = '48';
  string internal constant MATH_ADDITION_OVERFLOW = '49';
  string internal constant MATH_DIVISION_BY_ZERO = '50';
  string internal constant RL_LIQUIDITY_INDEX_OVERFLOW = '51'; //  Liquidity index overflows uint128
  string internal constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = '52'; //  Variable borrow index overflows uint128
  string internal constant RL_LIQUIDITY_RATE_OVERFLOW = '53'; //  Liquidity rate overflows uint128
  string internal constant RL_VARIABLE_BORROW_RATE_OVERFLOW = '54'; //  Variable borrow rate overflows uint128
  string internal constant RL_STABLE_BORROW_RATE_OVERFLOW = '55'; //  Stable borrow rate overflows uint128
  string internal constant CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
  string internal constant LP_FAILED_REPAY_WITH_COLLATERAL = '57';
  string internal constant CT_INVALID_BURN_AMOUNT = '58'; //invalid amount to burn
  string internal constant LP_FAILED_COLLATERAL_SWAP = '60';
  string internal constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = '61';
  string internal constant LP_REENTRANCY_NOT_ALLOWED = '62';
  string internal constant LP_CALLER_MUST_BE_AN_ATOKEN = '63';
  string internal constant LP_IS_PAUSED = '64'; // 'Pool is paused'
  string internal constant LP_NO_MORE_RESERVES_ALLOWED = '65';
  string internal constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = '66';
  string internal constant RC_INVALID_LTV = '67';
  string internal constant RC_INVALID_LIQ_THRESHOLD = '68';
  string internal constant RC_INVALID_LIQ_BONUS = '69';
  string internal constant RC_INVALID_DECIMALS = '70';
  string internal constant RC_INVALID_RESERVE_FACTOR = '71';
  string internal constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = '72';
  string internal constant VL_INCONSISTENT_FLASHLOAN_PARAMS = '73';
  string internal constant LP_INCONSISTENT_PARAMS_LENGTH = '74';
  string internal constant UL_INVALID_INDEX = '77';
  string internal constant LP_NOT_CONTRACT = '78';
  string internal constant SDT_STABLE_DEBT_OVERFLOW = '79';
  string internal constant SDT_BURN_EXCEEDS_BALANCE = '80';
  string internal constant VT_COLLATERAL_DEPOSIT_REQUIRE_ETH = '81'; //Only accept ETH for collateral deposit
  string internal constant VT_COLLATERAL_DEPOSIT_INVALID = '82'; //Collateral deposit failed
  string internal constant VT_LIQUIDITY_DEPOSIT_INVALID = '83'; //Only accept USDC, USDT, DAI for liquidity deposit
  string internal constant VT_COLLATERAL_WITHDRAW_INVALID = '84'; //Collateral withdraw failed
  string internal constant VT_COLLATERAL_WITHDRAW_INVALID_AMOUNT = '85'; //Collateral withdraw has not enough amount
  string internal constant VT_CONVERT_ASSET_BY_CURVE_INVALID = '86'; //Convert asset by curve invalid
  string internal constant VT_PROCESS_YIELD_INVALID = '87'; //Processing yield is invalid
  string internal constant VT_TREASURY_INVALID = '88'; //Treasury is invalid
  string internal constant LP_ATOKEN_INIT_INVALID = '89'; //aToken invalid init
  string internal constant VT_FEE_TOO_BIG = '90'; //Fee is too big
  string internal constant VT_COLLATERAL_DEPOSIT_VAULT_UNAVAILABLE = '91';
  string internal constant LP_LIQUIDATION_CONVERT_FAILED = '92';
  string internal constant VT_DEPLOY_FAILED = '93'; // Vault deploy failed
  string internal constant VT_INVALID_CONFIGURATION = '94'; // Invalid vault configuration
  string internal constant VL_OVERFLOW_MAX_RESERVE_CAPACITY = '95'; // overflow max capacity of reserve
  string internal constant VT_WITHDRAW_AMOUNT_MISMATCH = '96'; // not performed withdraw 100%
  string internal constant VT_SWAP_MISMATCH_RETURNED_AMOUNT = '97'; //Returned amount is not enough
  string internal constant CALLER_NOT_YIELD_PROCESSOR = '98'; // 'The caller must be the pool admin'
  string internal constant VT_EXTRA_REWARDS_INDEX_INVALID = '99'; // Invalid extraRewards index
  string internal constant VT_SWAP_PATH_LENGTH_INVALID = '100'; // Invalid token or fee length
  string internal constant VT_SWAP_PATH_TOKEN_INVALID = '101'; // Invalid token information
  string internal constant CLAIMER_UNAUTHORIZED = '102'; // 'The claimer is not authorized'
  string internal constant YD_INVALID_CONFIGURATION = '103'; // 'The yield distribution's invalid configuration'
  string internal constant CALLER_NOT_EMISSION_MANAGER = '104'; // 'The caller must be emission manager'
  string internal constant CALLER_NOT_INCENTIVE_CONTROLLER = '105'; // 'The caller must be incentive controller'
  string internal constant YD_VR_ASSET_ALREADY_IN_USE = '106'; // Vault is already registered
  string internal constant YD_VR_INVALID_VAULT = '107'; // Invalid vault is used for an asset
  string internal constant YD_VR_INVALID_REWARDS_AMOUNT = '108'; // Rewards amount should be bigger than before
  string internal constant YD_VR_REWARD_TOKEN_NOT_VALID = '109'; // The reward token must be same with configured address
  string internal constant YD_VR_ASSET_NOT_REGISTERED = '110';
  string internal constant YD_VR_CALLER_NOT_VAULT = '111'; // The caller must be same with configured vault address
  string internal constant LS_INVALID_CONFIGURATION = '112'; // Invalid Leverage Swapper configuration
  string internal constant LS_SWAP_AMOUNT_NOT_GT_0 = '113'; // Collateral amount needs to be greater than zero
  string internal constant LS_STABLE_COIN_NOT_SUPPORTED = '114'; // Doesn't support swap for the stable coin
  string internal constant LS_SUPPLY_NOT_ALLOWED = '115'; // no sufficient funds
  string internal constant LS_SUPPLY_FAILED = '116'; // Deposit fails when leverage works
  string internal constant LS_REMOVE_ITERATION_OVER = '117'; // Withdraw iteration limit over

  enum CollateralManagerErrors {
    NO_ERROR,
    NO_COLLATERAL_AVAILABLE,
    COLLATERAL_CANNOT_BE_LIQUIDATED,
    CURRRENCY_NOT_BORROWED,
    HEALTH_FACTOR_ABOVE_THRESHOLD,
    NOT_ENOUGH_LIQUIDITY,
    NO_ACTIVE_RESERVE,
    HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD,
    INVALID_EQUAL_ASSETS_TO_SWAP,
    FROZEN_RESERVE
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Sturdy Governance
 * @author Sturdy, inspiration from Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event IncentiveControllerUpdated(address indexed newAddress);
  event IncentiveTokenUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external payable;

  function setAddress(bytes32 id, address newAddress) external payable;

  function setAddressAsProxy(bytes32 id, address impl) external payable;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external payable;

  function getIncentiveController() external view returns (address);

  function setIncentiveControllerImpl(address incentiveController) external payable;

  function getIncentiveToken() external view returns (address);

  function setIncentiveTokenImpl(address incentiveToken) external payable;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external payable;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external payable;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external payable;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external payable;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external payable;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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