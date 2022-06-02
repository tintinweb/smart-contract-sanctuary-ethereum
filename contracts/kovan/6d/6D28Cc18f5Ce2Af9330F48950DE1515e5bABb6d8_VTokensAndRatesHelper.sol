// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

import {LendingPool} from '../protocol/lendingpool/LendingPool.sol';
import {
  LendingPoolAddressesProvider
} from '../protocol/configuration/LendingPoolAddressesProvider.sol';
import {LendingPoolConfigurator} from '../protocol/lendingpool/LendingPoolConfigurator.sol';
import {VToken} from '../protocol/tokenization/VToken.sol';
import {
  DefaultReserveInterestRateStrategy
} from '../protocol/lendingpool/DefaultReserveInterestRateStrategy.sol';
import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';
import {StringLib} from './StringLib.sol';

contract VTokensAndRatesHelper is Ownable {
  address payable private pool;
  address private addressesProvider;
  address private poolConfigurator;
  event deployedContracts(address vToken, address strategy);

  struct InitDeploymentInput {
    address asset;
    uint256[6] rates;
  }

  struct ConfigureReserveInput {
    address asset;
    uint256 baseLTV;
    uint256 liquidationThreshold;
    uint256 liquidationBonus;
    uint256 reserveFactor;
    bool stableBorrowingEnabled;
    bool borrowingEnabled;
  }

  constructor(
    address payable _pool,
    address _addressesProvider,
    address _poolConfigurator
  ) public {
    pool = _pool;
    addressesProvider = _addressesProvider;
    poolConfigurator = _poolConfigurator;
  }

  function initDeployment(InitDeploymentInput[] calldata inputParams) external onlyOwner {
    for (uint256 i = 0; i < inputParams.length; i++) {
      emit deployedContracts(
        address(new VToken()),
        address(
          new DefaultReserveInterestRateStrategy(
            LendingPoolAddressesProvider(addressesProvider),
            inputParams[i].rates[0],
            inputParams[i].rates[1],
            inputParams[i].rates[2],
            inputParams[i].rates[3],
            inputParams[i].rates[4],
            inputParams[i].rates[5]
          )
        )
      );
    }
  }

  function configureReserves(ConfigureReserveInput[] calldata inputParams) external onlyOwner {
    LendingPoolConfigurator configurator = LendingPoolConfigurator(poolConfigurator);
    for (uint256 i = 0; i < inputParams.length; i++) {
      if (inputParams[i].borrowingEnabled) {
        configurator.enableBorrowingOnReserve(
          inputParams[i].asset,
          inputParams[i].stableBorrowingEnabled
        );
      }
      configurator.setReserveFactor(inputParams[i].asset, inputParams[i].reserveFactor);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma abicoder v2;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IERC721} from '../../dependencies/openzeppelin/contracts/IERC721.sol';
import {SafeERC721} from '../libraries/helpers/SafeERC721.sol';
import {Address} from '../../dependencies/openzeppelin/contracts/Address.sol';
import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';
import {IVToken} from '../../interfaces/IVToken.sol';
import {INToken} from '../../interfaces/INToken.sol';
import {IERC721WithStat} from '../../interfaces/IERC721WithStat.sol';
import {INFTFlashLoanReceiver} from '../../flashloan/interfaces/INFTFlashLoanReceiver.sol';
import {IVariableDebtToken} from '../../interfaces/IVariableDebtToken.sol';
import {IPriceOracleGetter} from '../../interfaces/IPriceOracleGetter.sol';
import {INFTXEligibility} from '../../interfaces/INFTXEligibility.sol';
//import {IStableDebtToken} from '../../interfaces/IStableDebtToken.sol';
import {ILendingPool} from '../../interfaces/ILendingPool.sol';
import {VersionedInitializable} from '../libraries/aave-upgradeability/VersionedInitializable.sol';
import {Helpers} from '../libraries/helpers/Helpers.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {PercentageMath} from '../libraries/math/PercentageMath.sol';
import {ReserveLogic} from '../libraries/logic/ReserveLogic.sol';
import {NFTVaultLogic} from '../libraries/logic/NFTVaultLogic.sol';
import {GenericLogic} from '../libraries/logic/GenericLogic.sol';
import {ValidationLogic} from '../libraries/logic/ValidationLogic.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {NFTVaultConfiguration} from '../libraries/configuration/NFTVaultConfiguration.sol';
import {UserConfiguration} from '../libraries/configuration/UserConfiguration.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {LendingPoolStorage} from './LendingPoolStorage.sol';

/**
 * @title LendingPool contract
 * @dev Main point of interaction with a Vinci protocol's market
 * - Users can:
 *   # Deposit
 *   # Withdraw
 *   # Deposit NFT
 *   # Withdraw NFT
 *   # Borrow
 *   # Repay
 *   # Enable/disable their NFTs as collateral
 *   # Liquidate positions
 * - To be covered by a proxy contract, owned by the LendingPoolAddressesProvider of the specific market
 * - All admin functions are callable by the LendingPoolConfigurator contract defined also in the
 *   LendingPoolAddressesProvider
 * @author Aave
 * @author Vinci
 **/
contract LendingPool is VersionedInitializable, ILendingPool, LendingPoolStorage {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using GPv2SafeERC20 for IERC20;
  using SafeERC721 for IERC721;
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NFTVaultLogic for DataTypes.NFTVaultData;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  uint256 public constant LENDINGPOOL_REVISION = 0x2;

  modifier whenNotPaused() {
    _whenNotPaused();
    _;
  }

  modifier onlyLendingPoolConfigurator() {
    _onlyLendingPoolConfigurator();
    _;
  }

  function _whenNotPaused() internal view {
    require(!_paused, Errors.LP_IS_PAUSED);
  }

  function _onlyLendingPoolConfigurator() internal view {
    require(
      _addressesProvider.getLendingPoolConfigurator() == msg.sender,
      Errors.LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR
    );
  }

  function getRevision() internal pure override returns (uint256) {
    return LENDINGPOOL_REVISION;
  }

  /**
   * @dev Function is invoked by the proxy contract when the LendingPool contract is added to the
   * LendingPoolAddressesProvider of the market.
   * - Caching the address of the LendingPoolAddressesProvider in order to reduce gas consumption
   *   on subsequent operations
   * @param provider The address of the LendingPoolAddressesProvider
   **/
  function initialize(ILendingPoolAddressesProvider provider) public initializer {
    _addressesProvider = provider;
    _maxStableRateBorrowSizePercent = 2500;
    _flashLoanPremiumTotal = 0;
    _maxNumberOfReserves = 128;
    _maxNumberOfNFTVaults = 256;
  }

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying vTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the vTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of vTokens
   *   is a different wallet
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external override whenNotPaused {
    DataTypes.ReserveData storage reserve = _reserves.data[asset];

    ValidationLogic.validateDeposit(reserve, amount);

    address vToken = reserve.vTokenAddress;

    reserve.updateState();
    reserve.updateInterestRates(asset, vToken, amount, 0);

    IERC20(asset).safeTransferFrom(msg.sender, vToken, amount);

    IVToken(vToken).mint(onBehalfOf, amount, reserve.liquidityIndex);

    emit Deposit(asset, msg.sender, onBehalfOf, amount, referralCode);
  }

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 vUSDC, calls withdraw() and receives 100 USDC, burning the 100 vUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole vToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external override whenNotPaused returns (uint256) {
    DataTypes.ReserveData storage reserve = _reserves.data[asset];

    address vToken = reserve.vTokenAddress;

    uint256 userBalance = IVToken(vToken).balanceOf(msg.sender);

    uint256 amountToWithdraw = amount;

    if (amount == type(uint256).max) {
      amountToWithdraw = userBalance;
    }

    ValidationLogic.validateWithdraw(
      asset,
      amountToWithdraw,
      userBalance,
      _reserves,
      _usersConfig[msg.sender],
      _addressesProvider.getPriceOracle()
    );

    reserve.updateState();

    reserve.updateInterestRates(asset, vToken, 0, amountToWithdraw);

    IVToken(vToken).burn(msg.sender, to, amountToWithdraw, reserve.liquidityIndex);

    emit Withdraw(asset, msg.sender, to, amountToWithdraw);

    return amountToWithdraw;
  }

  /**
   * @dev Deposits NFTs with given `tokenIds` and `amounts` into the vault, receiving in return overlying nTokens.
   * E.g. User deposits an MAYC with tokenid 1234 and gets in return 1 vnMAYC with tokenid 1234
   * @param nft The address of the underlying asset to deposit
   * @param tokenIds The array of token ids to deposit
   * @param amounts The array of amounts to deposit. 
   * - Must be the same length with `tokenIds`. 
   * - All elements must be 1 for ERC721 NFT.
   * @param onBehalfOf The address that will receive the vnTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of vnTokens
   *   is a different wallet
   **/
  function depositNFT(
    address nft,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    address onBehalfOf,
    uint16 referralCode
  ) external override whenNotPaused {
    require(tokenIds.length == amounts.length, Errors.LP_TOKEN_AND_AMOUNT_LENGTH_NOT_MATCH);
    DataTypes.NFTVaultData storage vault = _nftVaults.data[nft];

    ValidationLogic.validateDepositNFT(
      vault,
      tokenIds,
      amounts
    );

    address nToken = vault.nTokenAddress;
    for(uint256 i = 0; i < tokenIds.length; ++i){
      IERC721(nft).safeTransferFrom(msg.sender, nToken, tokenIds[i]);
      bool isFirstDeposit = INToken(nToken).mint(onBehalfOf, tokenIds[i], 1);
      if (isFirstDeposit) {
        _usersConfig[onBehalfOf].setUsingNFTVaultAsCollateral(vault.id, true);
        emit NFTVaultUsedAsCollateralEnabled(nft, onBehalfOf);
      }
    }

    emit DepositNFT(nft, msg.sender, onBehalfOf, tokenIds, amounts, referralCode);

  }

  function depositAndLockNFT(
    address nft,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    address onBehalfOf,
    uint16 lockType,
    uint16 referralCode
  ) external override whenNotPaused {
    require(tokenIds.length == amounts.length, Errors.LP_TOKEN_AND_AMOUNT_LENGTH_NOT_MATCH);
    DataTypes.NFTVaultData storage vault = _nftVaults.data[nft];

    ValidationLogic.validateDepositNFT(
      vault,
      tokenIds,
      amounts
    );

    ValidationLogic.validateLockNFT(
      vault,
      uint40(block.timestamp)
    );    

    address nToken = vault.nTokenAddress;
    for(uint256 i = 0; i < tokenIds.length; ++i){
      IERC721(nft).safeTransferFrom(msg.sender, nToken, tokenIds[i]);
      bool isFirstDeposit = INToken(nToken).mint(onBehalfOf, tokenIds[i], 1);
      if(lockType != 0) {
        INToken(nToken).lock(tokenIds[i], lockType);
      }
      if (isFirstDeposit) {
        _usersConfig[onBehalfOf].setUsingNFTVaultAsCollateral(vault.id, true);
        emit NFTVaultUsedAsCollateralEnabled(nft, onBehalfOf);
      }
    }

    emit DepositNFT(nft, msg.sender, onBehalfOf, tokenIds, amounts, referralCode);

  }

  /**
   * @dev Withdraws underlying NFTs with given `tokenIds` and `amounts` from the vault, burning the equivalent nTokens owned
   * E.g. User has vnMAYC with token id 1234, calls withdraw() and receives the MAYC with token id 1234, burning the vUSDC with token id 1234.
   * @param nft The address of the underlying NFT to withdraw
   * @param tokenIds The array of token ids to withdraw
   * @param amounts The array of amounts to withdraw. 
   * - Must be the same length with `tokenIds`. 
   * - All elements must be 1 for ERC721 NFT.
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdrawNFT(
    address nft,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    address to
  ) external override whenNotPaused returns (uint256[] memory) {
    require(tokenIds.length == amounts.length, Errors.LP_TOKEN_AND_AMOUNT_LENGTH_NOT_MATCH);
    DataTypes.NFTVaultData storage vault = _nftVaults.data[nft];

    address nToken = vault.nTokenAddress;

    uint256[] memory userBalances = INToken(nToken).unlockedBalanceOfBatch(msg.sender, tokenIds);

    uint256[] memory amountsToWithdraw = amounts;

    uint256 amountToWithdraw = 0;

    for(uint256 i = 0; i < tokenIds.length; ++i){
      if (amounts[i] == type(uint256).max) {
        amountsToWithdraw[i] = userBalances[i];
      }
      amountToWithdraw = amountToWithdraw + amountsToWithdraw[i];
    }

    ValidationLogic.validateWithdrawNFT(
      nft,
      tokenIds,
      amountsToWithdraw,
      userBalances,
      _reserves,
      _nftVaults,
      _usersConfig[msg.sender],
      _addressesProvider.getPriceOracle()
    );

    if (amountToWithdraw == IERC721(nToken).balanceOf(msg.sender)) {
      _usersConfig[msg.sender].setUsingNFTVaultAsCollateral(vault.id, false);
      emit NFTVaultUsedAsCollateralDisabled(nft, msg.sender);
    }

    INToken(nToken).burnBatch(msg.sender, to, tokenIds, amountsToWithdraw);
    
    INFTXEligibility(vault.nftEligibility).afterRedeemHook(tokenIds);
    emit WithdrawNFT(nft, msg.sender, to, tokenIds, amountsToWithdraw);

    return amountsToWithdraw;
  }

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 variable debt tokens.
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow. Unused currently, must be > 0
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
  ) external override whenNotPaused {
    DataTypes.ReserveData storage reserve = _reserves.data[asset];

    _executeBorrow(
      ExecuteBorrowParams(
        asset,
        msg.sender,
        onBehalfOf,
        amount,
        interestRateMode,
        reserve.vTokenAddress,
        referralCode,
        true
      )
    );
  }

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay. Unused Currently, must be > 0
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
  ) external override whenNotPaused returns (uint256) {
    DataTypes.ReserveData storage reserve = _reserves.data[asset];

    (, uint256 variableDebt) = Helpers.getUserCurrentDebt(onBehalfOf, reserve);

    DataTypes.InterestRateMode interestRateMode = DataTypes.InterestRateMode(rateMode);

    ValidationLogic.validateRepay(
      reserve,
      amount,
      interestRateMode,
      onBehalfOf,
      0,
      variableDebt
    );

    uint256 paybackAmount = variableDebt;

    if (amount < paybackAmount) {
      paybackAmount = amount;
    }

    reserve.updateState();

    /*if (interestRateMode == DataTypes.InterestRateMode.STABLE) {
      IStableDebtToken(reserve.stableDebtTokenAddress).burn(onBehalfOf, paybackAmount);
    } else {*/
      IVariableDebtToken(reserve.variableDebtTokenAddress).burn(
        onBehalfOf,
        paybackAmount,
        reserve.variableBorrowIndex
      );
    //}

    address vToken = reserve.vTokenAddress;
    reserve.updateInterestRates(asset, vToken, paybackAmount, 0);

    if (variableDebt - paybackAmount == 0) {
      _usersConfig[onBehalfOf].setBorrowing(reserve.id, false);
    }

    IERC20(asset).safeTransferFrom(msg.sender, vToken, paybackAmount);

    IVToken(vToken).handleRepayment(msg.sender, paybackAmount);

    emit Repay(asset, onBehalfOf, msg.sender, paybackAmount);

    return paybackAmount;
  }

  struct NFTLiquidationCallParameters {
    address collateralAsset;
    address debtAsset;
    address user;
    uint256[] tokenIds;
    uint256[] amounts;
    bool receiveNToken;
  }

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) chooses `tokenIds` and `amounts` of the `collateralAsset` NFTs of the 
   *   user getting liquidated, and pays the corrensponding discounted `debtAsset` price
   *   to cover the debt of the user getting liquidated. 
   * - If there is any `debtAsset` left after repayment of the debt, it will be converted to vToken
   *   and transferred to the user getting liquidated.
   * @param collateralAsset The address of the underlying NFT used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param tokenIds The array of token ids of the NFTs that the liquidator wants to receive
   * - Starting from the front, only the portion that covers 50% of the debt of the user get liquidating will be liquidated
   * @param amounts The array of ammounts of the NFTs that the liquidator wants to receive
   * - Must be the same length with `tokenIds`
   * @param receiveNToken `true` if the liquidators wants to receive the collateral nTokens, `false` if he wants
   * to receive the underlying collateral NFT directly
   **/
  function nftLiquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bool receiveNToken
  ) external override whenNotPaused {
    address collateralManager = _addressesProvider.getLendingPoolCollateralManager();
    NFTLiquidationCallParameters memory params;
    params.collateralAsset = collateralAsset;
    params.debtAsset = debtAsset;
    params.user = user;
    params.tokenIds = tokenIds;
    params.amounts = amounts;
    params.receiveNToken = receiveNToken;
    //solium-disable-next-line
    (bool success, bytes memory result) =
      collateralManager.delegatecall(
        abi.encodeWithSignature(
          'nftLiquidationCall((address,address,address,uint256[],uint256[],bool))',
          params
        )
      );

    require(success, Errors.LP_LIQUIDATION_CALL_FAILED);

    (uint256 returnCode, string memory returnMessage) = abi.decode(result, (uint256, string));

    require(returnCode == 0, string(abi.encodePacked(returnMessage)));
  }

  struct NFTFlashLoanLocalVars {
    INFTFlashLoanReceiver receiver;
    uint256 i;
    address asset;
    address nTokenAddress;
    uint256 currentAmount;
    uint256 currentPremium;
    uint256 currentAmountPlusPremium;
  }

  /**
   * @dev Allows smartcontracts to access the nft vault of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the INFTFlashLoanReceiver interface
   * @param asset The addresses of the assets being flash-borrowed
   * @param tokenIds The tokenIds of the NFTs being flash-borrowed
   * @param amounts For ERC1155 only: The amounts of NFTs being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   **/
  function nftFlashLoan(
    address receiverAddress,
    address asset,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata params,
    uint16 referralCode
  ) external override whenNotPaused 
  {
    NFTFlashLoanLocalVars memory vars;

    vars.nTokenAddress = _nftVaults.data[asset].nTokenAddress;
    // uint256 premium = tokenIds.length * _flashLoadPremiumTotal / 10000;
    uint256 premium = 0;

    uint256[] memory userBalances = IERC721WithStat(vars.nTokenAddress).balanceOfBatch(msg.sender, tokenIds);
    ValidationLogic.validateNFTFlashloan(asset, tokenIds, amounts, userBalances);

    vars.receiver = INFTFlashLoanReceiver(receiverAddress);
    for (vars.i = 0; vars.i < tokenIds.length; vars.i++) {
      INToken(vars.nTokenAddress).transferUnderlyingTo(receiverAddress, tokenIds[vars.i], amounts[vars.i]);
    }
    require(
      vars.receiver.executeOperation(asset, tokenIds, amounts, premium, msg.sender, params),
      Errors.LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN
    );

    for (vars.i = 0; vars.i < tokenIds.length; vars.i++) {
      IERC721(asset).safeTransferFrom(receiverAddress, vars.nTokenAddress, tokenIds[vars.i]);
    }
    emit NFTFlashLoan(
      receiverAddress,
      msg.sender,
      asset,
      tokenIds,
      amounts,
      0,
      referralCode
    );
  }

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset)
    external
    view
    override
    returns (DataTypes.ReserveData memory)
  {
    return _reserves.data[asset];
  }

  /**
   * @dev Returns the state and configuration of the vault
   * @param asset The address of the underlying NFT of the vault
   * @return The state of the vault
   **/
  function getNFTVaultData(address asset) 
    external 
    view 
    override
    returns (DataTypes.NFTVaultData memory)
  {
    return _nftVaults.data[asset];
  }

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
    override
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    )
  {
    (
      totalCollateralETH,
      totalDebtETH,
      ltv,
      currentLiquidationThreshold,
      healthFactor
    ) = GenericLogic.calculateUserAccountData(
      user,
      _reserves,
      _nftVaults,
      _usersConfig[user],
      _addressesProvider.getPriceOracle()
    );

    availableBorrowsETH = GenericLogic.calculateAvailableBorrowsETH(
      totalCollateralETH,
      totalDebtETH,
      ltv
    );
  }

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    override
    returns (DataTypes.ReserveConfigurationMap memory)
  {
    return _reserves.data[asset].configuration;
  }

  /**
   * @dev Returns the configuration of the vault
   * @param asset The address of the underlying nft of the vault
   * @return The configuration of the vault
   **/
  function getNFTVaultConfiguration(address asset)
    external
    view
    override
    returns (DataTypes.NFTVaultConfigurationMap memory)
  {
    return _nftVaults.data[asset].configuration;
  }

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    override
    returns (DataTypes.UserConfigurationMap memory)
  {
    return _usersConfig[user];
  }

  /**
   * @dev Returns the normalized income per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return _reserves.data[asset].getNormalizedIncome();
  }

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset)
    external
    view
    override
    returns (uint256)
  {
    return _reserves.data[asset].getNormalizedDebt();
  }

  /**
   * @dev Returns if the LendingPool is paused
   */
  function paused() external view override returns (bool) {
    return _paused;
  }

  /**
   * @dev Returns the list of the initialized reserves
   **/
  function getReservesList() external view override returns (address[] memory) {
    address[] memory _activeReserves = new address[](_reserves.count);

    for (uint256 i = 0; i < _reserves.count; i++) {
      _activeReserves[i] = _reserves.list[i];
    }
    return _activeReserves;
  }

  /**
   * @dev Returns the list of the initialized vaults
   **/
  function getNFTVaultsList() external view override returns (address[] memory) {
    address[] memory _activeVaults = new address[](_nftVaults.count);

    for (uint256 i = 0; i < _nftVaults.count; i++) {
      _activeVaults[i] = _nftVaults.list[i];
    }
    return _activeVaults;
  }

  /**
   * @dev Returns the cached LendingPoolAddressesProvider connected to this contract
   **/
  function getAddressesProvider() external view override returns (ILendingPoolAddressesProvider) {
    return _addressesProvider;
  }

  /**
   * @dev Returns the percentage of available liquidity that can be borrowed at once at stable rate
   */
  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() public view returns (uint256) {
    return _maxStableRateBorrowSizePercent;
  }

  /**
   * @dev Returns the fee on flash loans 
   */
  function FLASHLOAN_PREMIUM_TOTAL() public view returns (uint256) {
    return _flashLoanPremiumTotal;
  }

  /**
   * @dev Returns the maximum number of reserves supported to be listed in this LendingPool
   */
  function MAX_NUMBER_RESERVES() public view returns (uint256) {
    return _maxNumberOfReserves;
  }

  /**
   * @dev Validates and finalizes a vToken transfer
   * - Only callable by the overlying vToken of the `asset`
   * @param asset The address of the underlying asset of the vToken
   * @param from The user from which the vTokens are transferred
   * @param to The user receiving the vTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The vToken balance of the `from` user before the transfer
   * @param balanceToBefore The vToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external override whenNotPaused {
    require(msg.sender == _reserves.data[asset].vTokenAddress, Errors.LP_CALLER_MUST_BE_AN_VTOKEN);

    ValidationLogic.validateTransfer(
      from,
      _reserves,
      _nftVaults,
      _usersConfig[from],
      _addressesProvider.getPriceOracle()
    );
  }

  /**
   * @dev Validates and finalizes a nToken transfer
   * - Only callable by the overlying nToken of the `asset`
   * @param asset The address of the underlying NFT of the nToken
   * @param from The user from which the nTokens are transferred
   * @param to The user receiving the nTokens
   * @param tokenId The token id of the NFT being transferred/withdrawn
   * @param amount The amount of the NFT with `tokenId` being transferred/withdrawn
   * @param balanceFromBefore The vToken balance of the `from` user before the transfer
   * @param balanceToBefore The vToken balance of the `to` user before the transfer
   */
  function finalizeNFTSingleTransfer(
    address asset,
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external override whenNotPaused {
    require(msg.sender == _nftVaults.data[asset].nTokenAddress, Errors.LP_CALLER_MUST_BE_AN_VTOKEN);

    ValidationLogic.validateTransfer(
      from,
      _reserves,
      _nftVaults,
      _usersConfig[from],
      _addressesProvider.getPriceOracle()
    );

    uint256 vaultId = _nftVaults.data[asset].id;

    if (from != to) {
      if (balanceFromBefore -amount == 0) {
        DataTypes.UserConfigurationMap storage fromConfig = _usersConfig[from];
        fromConfig.setUsingNFTVaultAsCollateral(vaultId, false);
        emit NFTVaultUsedAsCollateralDisabled(asset, from);
      }

      if (balanceToBefore == 0 && amount != 0) {
        DataTypes.UserConfigurationMap storage toConfig = _usersConfig[to];
        toConfig.setUsingNFTVaultAsCollateral(vaultId, true);
        emit NFTVaultUsedAsCollateralEnabled(asset, to);
      }
    }

  }

  /**
   * @dev Validates and finalizes a batch nToken transfer
   * - Only callable by the overlying nToken of the `asset`
   * @param asset The address of the underlying NFT of the nTokens
   * @param from The user from which the nTokens are transferred
   * @param to The user receiving the vTokens
   * @param tokenIds The array of token ids of the NFTs being transferred/withdrawn
   * @param amounts The array of amounts of the NFTs being transferred/withdrawn
   * - Must be the same length with `tokenIds`
   * @param balanceFromBefore The vToken balance of the `from` user before the transfer
   * @param balanceToBefore The vToken balance of the `to` user before the transfer
   */
  function finalizeNFTBatchTransfer(
    address asset,
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external override whenNotPaused {
    require(msg.sender == _nftVaults.data[asset].nTokenAddress, Errors.LP_CALLER_MUST_BE_AN_VTOKEN);

    ValidationLogic.validateTransfer(
      from,
      _reserves,
      _nftVaults,
      _usersConfig[from],
      _addressesProvider.getPriceOracle()
    );

    uint256 vaultId = _nftVaults.data[asset].id;
    uint256 amount = 0;
    for(uint256 i = 0; i < amounts.length; ++i){
      amount = amount + amounts[i];
    }

    if (from != to) {
      if (balanceFromBefore - amount == 0) {
        DataTypes.UserConfigurationMap storage fromConfig = _usersConfig[from];
        fromConfig.setUsingNFTVaultAsCollateral(vaultId, false);
        emit NFTVaultUsedAsCollateralDisabled(asset, from);
      }

      if (balanceToBefore == 0 && amount != 0) {
        DataTypes.UserConfigurationMap storage toConfig = _usersConfig[to];
        toConfig.setUsingNFTVaultAsCollateral(vaultId, true);
        emit NFTVaultUsedAsCollateralEnabled(asset, to);
      }
    }

  }

  /**
   * @dev Initializes a reserve, activating it, assigning a vToken and debt tokens and an
   * interest rate strategy
   * - Only callable by the LendingPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param vTokenAddress The address of the vToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param vTokenAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    address vTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external override onlyLendingPoolConfigurator {
    require(Address.isContract(asset), Errors.LP_NOT_CONTRACT);
    _reserves.data[asset].init(
      vTokenAddress,
      stableDebtAddress,
      variableDebtAddress,
      interestRateStrategyAddress
    );
    _addReserveToList(asset);
  }

  /**
   * @dev Initializes a vault, activating it, assigning a nToken and an eligibility checker
   * - Only callable by the LendingPoolConfigurator contract
   * @param nft The address of the underlying NFT of the vault
   * @param nTokenAddress The address of the nToken that will be assigned to the vault
   * @param nftEligibility The address of the NFTXEligibility contract that will be used for checking NFT eligibility
   **/
  function initNFTVault(
    address nft,
    address nTokenAddress,
    address nftEligibility
  ) external override onlyLendingPoolConfigurator {
    require(Address.isContract(nft), Errors.LP_NOT_CONTRACT);
    _nftVaults.data[nft].init(
      nTokenAddress,
      nftEligibility
    );
    _addNFTVaultToList(nft);
  }

  /**
   * @dev Updates the address of the interest rate strategy contract
   * - Only callable by the LendingPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    external
    override
    onlyLendingPoolConfigurator
  {
    _reserves.data[asset].interestRateStrategyAddress = rateStrategyAddress;
  }

  /**
   * @dev Sets the configuration bitmap of the reserve as a whole
   * - Only callable by the LendingPoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setConfiguration(address asset, uint256 configuration)
    external
    override
    onlyLendingPoolConfigurator
  {
    _reserves.data[asset].configuration.data = configuration;
  }

  /**
   * @dev Sets the configuration bitmap of the vault as a whole
   * - Only callable by the LendingPoolConfigurator contract
   * @param vault The address of the underlying NFT of the vault
   * @param configuration The new configuration bitmap
   **/
  function setNFTVaultConfiguration(address vault, uint256 configuration)
   external
   override
   onlyLendingPoolConfigurator
  {
    _nftVaults.data[vault].configuration.data = configuration;
  }

  function setNFTVaultActionExpiration(address vault, uint40 expiration)
   external
   override
   onlyLendingPoolConfigurator
  {
    _nftVaults.data[vault].expiration = expiration;
  }

  /**
   * @dev Set the _pause state of a reserve
   * - Only callable by the LendingPoolConfigurator contract
   * @param val `true` to pause the reserve, `false` to un-pause it
   */
  function setPause(bool val) external override onlyLendingPoolConfigurator {
    _paused = val;
    if (_paused) {
      emit Paused();
    } else {
      emit Unpaused();
    }
  }

  struct ExecuteBorrowParams {
    address asset;
    address user;
    address onBehalfOf;
    uint256 amount;
    uint256 interestRateMode;
    address vTokenAddress;
    uint16 referralCode;
    bool releaseUnderlying;
  }

  function _executeBorrow(ExecuteBorrowParams memory vars) internal {
    DataTypes.ReserveData storage reserve = _reserves.data[vars.asset];
    DataTypes.UserConfigurationMap storage userConfig = _usersConfig[vars.onBehalfOf];

    address oracle = _addressesProvider.getPriceOracle();

    uint256 amountInETH =
      IPriceOracleGetter(oracle).getAssetPrice(vars.asset) * vars.amount
        / (10**reserve.configuration.getDecimals());

    ValidationLogic.validateBorrow(
      vars.asset,
      reserve,
      vars.onBehalfOf,
      vars.amount,
      amountInETH,
      vars.interestRateMode,
      0, //_maxStableRateBorrowSizePercent,
      _reserves,
      _nftVaults,
      userConfig,
      oracle
    );

    reserve.updateState();

    //uint256 currentStableRate = 0;

    bool isFirstBorrowing = false;
    /*if (DataTypes.InterestRateMode(vars.interestRateMode) == DataTypes.InterestRateMode.STABLE) {
      currentStableRate = reserve.currentStableBorrowRate;

      isFirstBorrowing = IStableDebtToken(reserve.stableDebtTokenAddress).mint(
        vars.user,
        vars.onBehalfOf,
        vars.amount,
        currentStableRate
      );
    } else {*/
      isFirstBorrowing = IVariableDebtToken(reserve.variableDebtTokenAddress).mint(
        vars.user,
        vars.onBehalfOf,
        vars.amount,
        reserve.variableBorrowIndex
      );
    //}

    if (isFirstBorrowing) {
      userConfig.setBorrowing(reserve.id, true);
    }

    reserve.updateInterestRates(
      vars.asset,
      vars.vTokenAddress,
      0,
      vars.releaseUnderlying ? vars.amount : 0
    );

    if (vars.releaseUnderlying) {
      IVToken(vars.vTokenAddress).transferUnderlyingTo(vars.user, vars.amount);
    }

    emit Borrow(
      vars.asset,
      vars.user,
      vars.onBehalfOf,
      vars.amount,
      vars.interestRateMode,
      //DataTypes.InterestRateMode(vars.interestRateMode) == DataTypes.InterestRateMode.STABLE
      //  ? currentStableRate
      reserve.currentVariableBorrowRate,
      vars.referralCode
    );
  }

  function _addReserveToList(address asset) internal {
    uint256 reservesCount = _reserves.count;

    require(reservesCount < _maxNumberOfReserves, Errors.LP_NO_MORE_RESERVES_ALLOWED);

    bool reserveAlreadyAdded = _reserves.data[asset].id != 0 || _reserves.list[0] == asset;

    if (!reserveAlreadyAdded) {
      _reserves.data[asset].id = uint8(reservesCount);
      _reserves.list[reservesCount] = asset;

      _reserves.count = reservesCount + 1;
    }
  }

  function _addNFTVaultToList(address nft) internal {
    uint256 nftVaultsCount = _nftVaults.count;

    require(nftVaultsCount < _maxNumberOfNFTVaults, Errors.LP_NO_MORE_RESERVES_ALLOWED);

    bool vaultAlreadyAdded = _nftVaults.data[nft].id != 0 || _nftVaults.list[0] == nft;

    if (!vaultAlreadyAdded) {
      _nftVaults.data[nft].id = uint8(nftVaultsCount);
      _nftVaults.list[nftVaultsCount] = nft;

      _nftVaults.count = nftVaultsCount + 1;
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';

// Prettier ignore to prevent buidler flatter bug
// prettier-ignore
import {InitializableImmutableAdminUpgradeabilityProxy} from '../libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';

import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
contract LendingPoolAddressesProvider is Ownable, ILendingPoolAddressesProvider {
  string private _marketId;
  mapping(bytes32 => address) private _addresses;

  bytes32 private constant LENDING_POOL = 'LENDING_POOL';
  bytes32 private constant LENDING_POOL_CONFIGURATOR = 'LENDING_POOL_CONFIGURATOR';
  bytes32 private constant POOL_ADMIN = 'POOL_ADMIN';
  bytes32 private constant EMERGENCY_ADMIN = 'EMERGENCY_ADMIN';
  bytes32 private constant LENDING_POOL_COLLATERAL_MANAGER = 'COLLATERAL_MANAGER';
  bytes32 private constant PRICE_ORACLE = 'PRICE_ORACLE';
  bytes32 private constant LENDING_RATE_ORACLE = 'LENDING_RATE_ORACLE';

  constructor(string memory marketId) public {
    _setMarketId(marketId);
  }

  /**
   * @dev Returns the id of the Aave market to which this contracts points to
   * @return The market id
   **/
  function getMarketId() external view override returns (string memory) {
    return _marketId;
  }

  /**
   * @dev Allows to set the market which this LendingPoolAddressesProvider represents
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
  function setAddressAsProxy(bytes32 id, address implementationAddress)
    external
    override
    onlyOwner
  {
    _updateImpl(id, implementationAddress);
    emit AddressSet(id, implementationAddress, true);
  }

  /**
   * @dev Sets an address for an id replacing the address saved in the addresses map
   * IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external override onlyOwner {
    _addresses[id] = newAddress;
    emit AddressSet(id, newAddress, false);
  }

  /**
   * @dev Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) public view override returns (address) {
    return _addresses[id];
  }

  /**
   * @dev Returns the address of the LendingPool proxy
   * @return The LendingPool proxy address
   **/
  function getLendingPool() external view override returns (address) {
    return getAddress(LENDING_POOL);
  }

  /**
   * @dev Updates the implementation of the LendingPool, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * @param pool The new LendingPool implementation
   **/
  function setLendingPoolImpl(address pool) external override onlyOwner {
    _updateImpl(LENDING_POOL, pool);
    emit LendingPoolUpdated(pool);
  }

  /**
   * @dev Returns the address of the LendingPoolConfigurator proxy
   * @return The LendingPoolConfigurator proxy address
   **/
  function getLendingPoolConfigurator() external view override returns (address) {
    return getAddress(LENDING_POOL_CONFIGURATOR);
  }

  /**
   * @dev Updates the implementation of the LendingPoolConfigurator, or creates the proxy
   * setting the new `configurator` implementation on the first time calling it
   * @param configurator The new LendingPoolConfigurator implementation
   **/
  function setLendingPoolConfiguratorImpl(address configurator) external override onlyOwner {
    _updateImpl(LENDING_POOL_CONFIGURATOR, configurator);
    emit LendingPoolConfiguratorUpdated(configurator);
  }

  /**
   * @dev Returns the address of the LendingPoolCollateralManager. Since the manager is used
   * through delegateCall within the LendingPool contract, the proxy contract pattern does not work properly hence
   * the addresses are changed directly
   * @return The address of the LendingPoolCollateralManager
   **/

  function getLendingPoolCollateralManager() external view override returns (address) {
    return getAddress(LENDING_POOL_COLLATERAL_MANAGER);
  }

  /**
   * @dev Updates the address of the LendingPoolCollateralManager
   * @param manager The new LendingPoolCollateralManager address
   **/
  function setLendingPoolCollateralManager(address manager) external override onlyOwner {
    _addresses[LENDING_POOL_COLLATERAL_MANAGER] = manager;
    emit LendingPoolCollateralManagerUpdated(manager);
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

  function getPriceOracle() external view override returns (address) {
    return getAddress(PRICE_ORACLE);
  }

  function setPriceOracle(address priceOracle) external override onlyOwner {
    _addresses[PRICE_ORACLE] = priceOracle;
    emit PriceOracleUpdated(priceOracle);
  }

  function getLendingRateOracle() external view override returns (address) {
    return getAddress(LENDING_RATE_ORACLE);
  }

  function setLendingRateOracle(address lendingRateOracle) external override onlyOwner {
    _addresses[LENDING_RATE_ORACLE] = lendingRateOracle;
    emit LendingRateOracleUpdated(lendingRateOracle);
  }

  /**
   * @dev Internal function to update the implementation of a specific proxied component of the protocol
   * - If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
   *   as implementation and calls the initialize() function on the proxy
   * - If there is already a proxy registered, it just updates the implementation to `newAddress` and
   *   calls the initialize() function via upgradeToAndCall() in the proxy
   * @param id The id of the proxy to be updated
   * @param newAddress The address of the new implementation
   **/
  function _updateImpl(bytes32 id, address newAddress) internal {
    address payable proxyAddress = payable(_addresses[id]);

    InitializableImmutableAdminUpgradeabilityProxy proxy =
      InitializableImmutableAdminUpgradeabilityProxy(proxyAddress);
    bytes memory params = abi.encodeWithSignature('initialize(address)', address(this));

    if (proxyAddress == address(0)) {
      proxy = new InitializableImmutableAdminUpgradeabilityProxy(address(this));
      proxy.initialize(newAddress, params);
      _addresses[id] = address(proxy);
      emit ProxyCreated(id, address(proxy));
    } else {
      proxy.upgradeToAndCall(newAddress, params);
    }
  }

  function _setMarketId(string memory marketId) internal {
    _marketId = marketId;
    emit MarketIdSet(marketId);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma abicoder v2;

import {VersionedInitializable} from '../libraries/aave-upgradeability/VersionedInitializable.sol';
import {
  InitializableImmutableAdminUpgradeabilityProxy
} from '../libraries/aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {NFTVaultConfiguration} from '../libraries/configuration/NFTVaultConfiguration.sol';
import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';
import {ILendingPool} from '../../interfaces/ILendingPool.sol';
import {IERC20Metadata} from '../../dependencies/openzeppelin/contracts/IERC20Metadata.sol';
import {IERC721} from '../../dependencies/openzeppelin/contracts/IERC721.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {PercentageMath} from '../libraries/math/PercentageMath.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';
import {IInitializableDebtToken} from '../../interfaces/IInitializableDebtToken.sol';
import {IInitializableVToken} from '../../interfaces/IInitializableVToken.sol';
import {IInitializableNToken} from '../../interfaces/IInitializableNToken.sol';
import {IAaveIncentivesController} from '../../interfaces/IAaveIncentivesController.sol';
import {ILendingPoolConfigurator} from '../../interfaces/ILendingPoolConfigurator.sol';

/**
 * @title LendingPoolConfigurator contract
 * @author Aave
 * @dev Implements the configuration methods for the Aave protocol
 **/

contract LendingPoolConfigurator is VersionedInitializable, ILendingPoolConfigurator {
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;

  ILendingPoolAddressesProvider internal addressesProvider;
  ILendingPool internal pool;

  modifier onlyPoolAdmin {
    require(addressesProvider.getPoolAdmin() == msg.sender, Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  modifier onlyEmergencyAdmin {
    require(
      addressesProvider.getEmergencyAdmin() == msg.sender,
      Errors.LPC_CALLER_NOT_EMERGENCY_ADMIN
    );
    _;
  }

  uint256 internal constant CONFIGURATOR_REVISION = 0x1;

  function getRevision() internal pure override returns (uint256) {
    return CONFIGURATOR_REVISION;
  }

  function initialize(ILendingPoolAddressesProvider provider) public initializer {
    addressesProvider = provider;
    pool = ILendingPool(addressesProvider.getLendingPool());
  }

  /**
   * @dev Initializes reserves in batch
   **/
  function batchInitReserve(InitReserveInput[] calldata input) external onlyPoolAdmin {
    ILendingPool cachedPool = pool;
    for (uint256 i = 0; i < input.length; i++) {
      _initReserve(cachedPool, input[i]);
    }
  }

  function _initReserve(ILendingPool pool, InitReserveInput calldata input) internal {
    address vTokenProxyAddress =
      _initTokenWithProxy(
        input.vTokenImpl,
        abi.encodeWithSelector(
          IInitializableVToken.initialize.selector,
          pool,
          input.treasury,
          input.underlyingAsset,
          IAaveIncentivesController(input.incentivesController),
          input.underlyingAssetDecimals,
          input.vTokenName,
          input.vTokenSymbol,
          input.params
        )
      );

    address stableDebtTokenProxyAddress =
      _initTokenWithProxy(
        input.stableDebtTokenImpl,
        abi.encodeWithSelector(
          IInitializableDebtToken.initialize.selector,
          pool,
          input.underlyingAsset,
          IAaveIncentivesController(input.incentivesController),
          input.underlyingAssetDecimals,
          input.stableDebtTokenName,
          input.stableDebtTokenSymbol,
          input.params
        )
      );

    address variableDebtTokenProxyAddress =
      _initTokenWithProxy(
        input.variableDebtTokenImpl,
        abi.encodeWithSelector(
          IInitializableDebtToken.initialize.selector,
          pool,
          input.underlyingAsset,
          IAaveIncentivesController(input.incentivesController),
          input.underlyingAssetDecimals,
          input.variableDebtTokenName,
          input.variableDebtTokenSymbol,
          input.params
        )
      );

    pool.initReserve(
      input.underlyingAsset,
      vTokenProxyAddress,
      stableDebtTokenProxyAddress,
      variableDebtTokenProxyAddress,
      input.interestRateStrategyAddress
    );

    DataTypes.ReserveConfigurationMap memory currentConfig =
      pool.getConfiguration(input.underlyingAsset);

    currentConfig.setDecimals(input.underlyingAssetDecimals);

    currentConfig.setActive(true);
    currentConfig.setFrozen(false);

    pool.setConfiguration(input.underlyingAsset, currentConfig.data);

    emit ReserveInitialized(
      input.underlyingAsset,
      vTokenProxyAddress,
      stableDebtTokenProxyAddress,
      variableDebtTokenProxyAddress,
      input.interestRateStrategyAddress
    );
  }

   /**
   * @dev Initializes vaults in batch
   **/
  function batchInitNFTVault(InitNFTVaultInput[] calldata input) external onlyPoolAdmin {
    ILendingPool cachedPool = pool;
    for (uint256 i = 0; i < input.length; i++) {
      _initNFTVault(cachedPool, input[i]);
    }
  }

  function _initNFTVault(ILendingPool pool, InitNFTVaultInput calldata input) internal {
    address nTokenProxyAddress =
      _initTokenWithProxy(
        input.nTokenImpl,
        abi.encodeWithSelector(
          IInitializableNToken.initialize.selector,
          pool,
          input.underlyingAsset,
          input.nTokenName,
          input.nTokenSymbol,
          input.baseURI,
          input.params
        )
      );

    pool.initNFTVault(
      input.underlyingAsset,
      nTokenProxyAddress,
      input.nftEligibility
    );

    DataTypes.NFTVaultConfigurationMap memory currentConfig =
      pool.getNFTVaultConfiguration(input.underlyingAsset);

    currentConfig.setActive(true);
    currentConfig.setFrozen(false);

    pool.setNFTVaultConfiguration(input.underlyingAsset, currentConfig.data);

    emit NFTVaultInitialized(
      input.underlyingAsset,
      nTokenProxyAddress
    );
  }

  /**
   * @dev Updates the vToken implementation for the reserve
   **/
  function updateVToken(UpdateVTokenInput calldata input) external onlyPoolAdmin {
    ILendingPool cachedPool = pool;

    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    (, , , uint256 decimals, ) = cachedPool.getConfiguration(input.asset).getParamsMemory();

    bytes memory encodedCall = abi.encodeWithSelector(
        IInitializableVToken.initialize.selector,
        cachedPool,
        input.treasury,
        input.asset,
        input.incentivesController,
        decimals,
        input.name,
        input.symbol,
        input.params
      );

    _upgradeTokenImplementation(
      reserveData.vTokenAddress,
      input.implementation,
      encodedCall
    );

    emit VTokenUpgraded(input.asset, reserveData.vTokenAddress, input.implementation);
  }

  /**
   * @dev Updates the stable debt token implementation for the reserve
   **/
  function updateStableDebtToken(UpdateDebtTokenInput calldata input) external onlyPoolAdmin {
    ILendingPool cachedPool = pool;

    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);
     
    (, , , uint256 decimals, ) = cachedPool.getConfiguration(input.asset).getParamsMemory();

    bytes memory encodedCall = abi.encodeWithSelector(
        IInitializableDebtToken.initialize.selector,
        cachedPool,
        input.asset,
        input.incentivesController,
        decimals,
        input.name,
        input.symbol,
        input.params
      );

    _upgradeTokenImplementation(
      reserveData.stableDebtTokenAddress,
      input.implementation,
      encodedCall
    );

    emit StableDebtTokenUpgraded(
      input.asset,
      reserveData.stableDebtTokenAddress,
      input.implementation
    );
  }

  /**
   * @dev Updates the variable debt token implementation for the asset
   **/
  function updateVariableDebtToken(UpdateDebtTokenInput calldata input)
    external
    onlyPoolAdmin
  {
    ILendingPool cachedPool = pool;

    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    (, , , uint256 decimals, ) = cachedPool.getConfiguration(input.asset).getParamsMemory();

    bytes memory encodedCall = abi.encodeWithSelector(
        IInitializableDebtToken.initialize.selector,
        cachedPool,
        input.asset,
        input.incentivesController,
        decimals,
        input.name,
        input.symbol,
        input.params
      );

    _upgradeTokenImplementation(
      reserveData.variableDebtTokenAddress,
      input.implementation,
      encodedCall
    );

    emit VariableDebtTokenUpgraded(
      input.asset,
      reserveData.variableDebtTokenAddress,
      input.implementation
    );
  }

  /**
   * @dev Updates the nToken implementation for the vault
   **/
  function updateNToken(UpdateNTokenInput calldata input) external onlyPoolAdmin {
    ILendingPool cachedPool = pool;

    DataTypes.NFTVaultData memory vaultData = cachedPool.getNFTVaultData(input.asset);

    bytes memory encodedCall = abi.encodeWithSelector(
        IInitializableNToken.initialize.selector,
        cachedPool,
        input.asset,
        input.name,
        input.symbol,
        input.params
      );

    _upgradeTokenImplementation(
      vaultData.nTokenAddress,
      input.implementation,
      encodedCall
    );

    emit NTokenUpgraded(input.asset, vaultData.nTokenAddress, input.implementation);
  }

  /**
   * @dev Enables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param stableBorrowRateEnabled True if stable borrow rate needs to be enabled by default on this reserve
   **/
  function enableBorrowingOnReserve(address asset, bool stableBorrowRateEnabled)
    external
    onlyPoolAdmin
  {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setBorrowingEnabled(true);
    currentConfig.setStableRateBorrowingEnabled(stableBorrowRateEnabled);

    pool.setConfiguration(asset, currentConfig.data);

    emit BorrowingEnabledOnReserve(asset, stableBorrowRateEnabled);
  }

  /**
   * @dev Disables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function disableBorrowingOnReserve(address asset) external onlyPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setBorrowingEnabled(false);

    pool.setConfiguration(asset, currentConfig.data);
    emit BorrowingDisabledOnReserve(asset);
  }

  /**
   * @dev Configures the nft vault collateralization parameters
   * all the values are expressed in percentages with two decimals of precision. A valid value is 10000, which means 100.00%
   * @param nft The address of the underlying NFT of the vault
   * @param ltv The loan to value of the NFT when used as collateral
   * @param liquidationThreshold The threshold at which loans using this NFT as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this NFT. The values is always above 100%. A value of 105%
   * means the liquidator will receive a 5% bonus
   **/
  function configureNFTVaultAsCollateral(
    address nft,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external onlyPoolAdmin {
    DataTypes.NFTVaultConfigurationMap memory currentConfig = pool.getNFTVaultConfiguration(nft);

    //validation of the parameters: the LTV can
    //only be lower or equal than the liquidation threshold
    //(otherwise a loan against the asset would cause instantaneous liquidation)
    require(ltv <= liquidationThreshold, Errors.LPC_INVALID_CONFIGURATION);

    if (liquidationThreshold != 0) {
      //liquidation bonus must be bigger than 100.00%, otherwise the liquidator would receive less
      //collateral than needed to cover the debt
      require(
        liquidationBonus > PercentageMath.PERCENTAGE_FACTOR,
        Errors.LPC_INVALID_CONFIGURATION
      );

      //if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
      //a loan is taken there is enough collateral available to cover the liquidation bonus
      require(
        liquidationThreshold.percentMul(liquidationBonus) <= PercentageMath.PERCENTAGE_FACTOR,
        Errors.LPC_INVALID_CONFIGURATION
      );
    } else {
      require(liquidationBonus == 0, Errors.LPC_INVALID_CONFIGURATION);
      //if the liquidation threshold is being set to 0,
      // the reserve is being disabled as collateral. To do so,
      //we need to ensure no liquidity is deposited
      _checkNoLiquidity(nft);
    }

    currentConfig.setLtv(ltv);
    currentConfig.setLiquidationThreshold(liquidationThreshold);
    currentConfig.setLiquidationBonus(liquidationBonus);

    pool.setNFTVaultConfiguration(nft, currentConfig.data);

    emit CollateralConfigurationChanged(nft, ltv, liquidationThreshold, liquidationBonus);
  }

  /**
   * @dev Enable stable rate borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function enableReserveStableRate(address asset) external onlyPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setStableRateBorrowingEnabled(true);

    pool.setConfiguration(asset, currentConfig.data);

    emit StableRateEnabledOnReserve(asset);
  }

  /**
   * @dev Disable stable rate borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function disableReserveStableRate(address asset) external onlyPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setStableRateBorrowingEnabled(false);

    pool.setConfiguration(asset, currentConfig.data);

    emit StableRateDisabledOnReserve(asset);
  }

  /**
   * @dev Activates a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function activateReserve(address asset) external onlyPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setActive(true);

    pool.setConfiguration(asset, currentConfig.data);

    emit ReserveActivated(asset);
  }

  /**
   * @dev Deactivates a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function deactivateReserve(address asset) external onlyPoolAdmin {
    _checkNoLiquidity(asset);

    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setActive(false);

    pool.setConfiguration(asset, currentConfig.data);

    emit ReserveDeactivated(asset);
  }

  /**
   * @dev Freezes a reserve. A frozen reserve doesn't allow any new deposit, borrow
   *  but allows repayments, liquidations, and withdrawals
   * @param asset The address of the underlying asset of the reserve
   **/
  function freezeReserve(address asset) external onlyPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setFrozen(true);

    pool.setConfiguration(asset, currentConfig.data);

    emit ReserveFrozen(asset);
  }

  /**
   * @dev Unfreezes a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function unfreezeReserve(address asset) external onlyPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setFrozen(false);

    pool.setConfiguration(asset, currentConfig.data);

    emit ReserveUnfrozen(asset);
  }

  /**
   * @dev Updates the reserve factor of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param reserveFactor The new reserve factor of the reserve
   **/
  function setReserveFactor(address asset, uint256 reserveFactor) external onlyPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setReserveFactor(reserveFactor);

    pool.setConfiguration(asset, currentConfig.data);

    emit ReserveFactorChanged(asset, reserveFactor);
  }

  /**
   * @dev Sets the interest rate strategy of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The new address of the interest strategy contract
   **/
  function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    external
    onlyPoolAdmin
  {
    pool.setReserveInterestRateStrategyAddress(asset, rateStrategyAddress);
    emit ReserveInterestRateStrategyChanged(asset, rateStrategyAddress);
  }

  /**
   * @dev Activates a vault
   * @param asset The address of the underlying NFT of the vault
   **/
  function activateNFTVault(address asset) external onlyPoolAdmin {
    DataTypes.NFTVaultConfigurationMap memory currentConfig = pool.getNFTVaultConfiguration(asset);

    currentConfig.setActive(true);

    pool.setNFTVaultConfiguration(asset, currentConfig.data);

    emit NFTVaultActivated(asset);
  }

  /**
   * @dev Deactivates a vault
   * @param asset The address of the underlying NFT of the vault
   **/
  function deactivateNFTVault(address asset) external onlyPoolAdmin {
    _checkNFTVaultNoLiquidity(asset);

    DataTypes.NFTVaultConfigurationMap memory currentConfig = pool.getNFTVaultConfiguration(asset);

    currentConfig.setActive(false);

    pool.setNFTVaultConfiguration(asset, currentConfig.data);

    emit NFTVaultDeactivated(asset);
  }

  /**
   * @dev Freezes a vault. A frozen vault doesn't allow any new deposit,
   *  but allows liquidations and withdrawals
   * @param asset The address of the underlying NFT of the reserve
   **/
  function freezeNFTVault(address asset) external onlyPoolAdmin {
    DataTypes.NFTVaultConfigurationMap memory currentConfig = pool.getNFTVaultConfiguration(asset);

    currentConfig.setFrozen(true);

    pool.setNFTVaultConfiguration(asset, currentConfig.data);

    emit NFTVaultFrozen(asset);
  }

  function updateNFTVaultActionExpiration(address asset, uint40 expiration) external onlyPoolAdmin {
    pool.setNFTVaultActionExpiration(asset, expiration);
    emit NFTVaultActionExpirationUpdated(asset, expiration);
  }

  /**
   * @dev pauses or unpauses all the actions of the protocol, including vToken transfers
   * @param val true if protocol needs to be paused, false otherwise
   **/
  function setPoolPause(bool val) external onlyEmergencyAdmin {
    pool.setPause(val);
  }

  function _initTokenWithProxy(address implementation, bytes memory initParams)
    internal
    returns (address)
  {
    InitializableImmutableAdminUpgradeabilityProxy proxy =
      new InitializableImmutableAdminUpgradeabilityProxy(address(this));

    proxy.initialize(implementation, initParams);

    return address(proxy);
  }

  function _upgradeTokenImplementation(
    address proxyAddress,
    address implementation,
    bytes memory initParams
  ) internal {
    InitializableImmutableAdminUpgradeabilityProxy proxy =
      InitializableImmutableAdminUpgradeabilityProxy(payable(proxyAddress));

    proxy.upgradeToAndCall(implementation, initParams);
  }

  function _checkNoLiquidity(address asset) internal view {
    DataTypes.ReserveData memory reserveData = pool.getReserveData(asset);

    uint256 availableLiquidity = IERC20Metadata(asset).balanceOf(reserveData.vTokenAddress);

    require(
      availableLiquidity == 0 && reserveData.currentLiquidityRate == 0,
      Errors.LPC_RESERVE_LIQUIDITY_NOT_0
    );
  }

  function _checkNFTVaultNoLiquidity(address asset) internal view {
    DataTypes.NFTVaultData memory vaultData = pool.getNFTVaultData(asset);

    uint256 availableLiquidity = IERC721(asset).balanceOf(vaultData.nTokenAddress);

    require(
      availableLiquidity == 0,
      Errors.LPC_RESERVE_LIQUIDITY_NOT_0
    );
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {ILendingPool} from '../../interfaces/ILendingPool.sol';
import {IVToken} from '../../interfaces/IVToken.sol';

import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {VersionedInitializable} from '../libraries/aave-upgradeability/VersionedInitializable.sol';
import {IncentivizedERC20} from './IncentivizedERC20.sol';
import {IAaveIncentivesController} from '../../interfaces/IAaveIncentivesController.sol';

/**
 * @title Aave ERC20 VToken
 * @dev Implementation of the interest bearing token for the Aave protocol
 * @author Aave
 */
contract VToken is
  VersionedInitializable,
  IncentivizedERC20('VTOKEN_IMPL', 'VTOKEN_IMPL', 0),
  IVToken
{
  using WadRayMath for uint256;
  using GPv2SafeERC20 for IERC20;

  bytes public constant EIP712_REVISION = bytes('1');
  bytes32 internal constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');

  uint256 public constant VTOKEN_REVISION = 0x1;

  /// @dev owner => next valid nonce to submit with permit()
  mapping(address => uint256) public _nonces;

  bytes32 public DOMAIN_SEPARATOR;

  ILendingPool internal _pool;
  address internal _treasury;
  address internal _underlyingAsset;
  IAaveIncentivesController internal _incentivesController;

  modifier onlyLendingPool {
    require(_msgSender() == address(_pool), Errors.CT_CALLER_MUST_BE_LENDING_POOL);
    _;
  }

  function getRevision() internal pure virtual override returns (uint256) {
    return VTOKEN_REVISION;
  }

  /**
   * @dev Initializes the vToken
   * @param pool The address of the lending pool where this vToken will be used
   * @param treasury The address of the Aave treasury, receiving the fees on this vToken
   * @param underlyingAsset The address of the underlying asset of this vToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param vTokenDecimals The decimals of the vToken, same as the underlying asset's
   * @param vTokenName The name of the vToken
   * @param vTokenSymbol The symbol of the vToken
   */
  function initialize(
    ILendingPool pool,
    address treasury,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 vTokenDecimals,
    string calldata vTokenName,
    string calldata vTokenSymbol,
    bytes calldata params
  ) external override initializer {
    uint256 chainId;

    //solium-disable-next-line
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        EIP712_DOMAIN,
        keccak256(bytes(vTokenName)),
        keccak256(EIP712_REVISION),
        chainId,
        address(this)
      )
    );

    _setName(vTokenName);
    _setSymbol(vTokenSymbol);
    _setDecimals(vTokenDecimals);

    _pool = pool;
    _treasury = treasury;
    _underlyingAsset = underlyingAsset;
    _incentivesController = incentivesController;

    emit Initialized(
      underlyingAsset,
      address(pool),
      treasury,
      address(incentivesController),
      vTokenDecimals,
      vTokenName,
      vTokenSymbol,
      params
    );
  }

  /**
   * @dev Burns vTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * - Only callable by the LendingPool, as extra state updates there need to be managed
   * @param user The owner of the vTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external override onlyLendingPool {
    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_BURN_AMOUNT);
    _burn(user, amountScaled);

    IERC20(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);

    emit Transfer(user, address(0), amount);
    emit Burn(user, receiverOfUnderlying, amount, index);
  }

  /**
   * @dev Mints `amount` vTokens to `user`
   * - Only callable by the LendingPool, as extra state updates there need to be managed
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external override onlyLendingPool returns (bool) {
    uint256 previousBalance = super.balanceOf(user);

    uint256 amountScaled = amount.rayDiv(index);
    require(amountScaled != 0, Errors.CT_INVALID_MINT_AMOUNT);
    _mint(user, amountScaled);

    emit Transfer(address(0), user, amount);
    emit Mint(user, amount, index);

    return previousBalance == 0;
  }

  /**
   * @dev Mints vTokens to the reserve treasury
   * - Only callable by the LendingPool
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external override onlyLendingPool {
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
   * @dev Transfers vTokens in the event of a borrow being liquidated, in case the liquidators reclaims the vToken
   * - Only callable by the LendingPool
   * @param from The address getting liquidated, current owner of the vTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external override onlyLendingPool {
    // Being a normal transfer, the Transfer() and BalanceTransfer() are emitted
    // so no need to emit a specific event here
    _transfer(from, to, value, false);

    emit Transfer(from, to, value);
  }

  /**
   * @dev Calculates the balance of the user: principal balance + interest generated by the principal
   * @param user The user whose balance is calculated
   * @return The balance of the user
   **/
  function balanceOf(address user)
    public
    view
    override(IncentivizedERC20, IERC20)
    returns (uint256)
  {
    return super.balanceOf(user).rayMul(_pool.getReserveNormalizedIncome(_underlyingAsset));
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
  function getScaledUserBalanceAndSupply(address user)
    external
    view
    override
    returns (uint256, uint256)
  {
    return (super.balanceOf(user), super.totalSupply());
  }

  /**
   * @dev calculates the total supply of the specific vToken
   * since the balance of every single user increases over time, the total supply
   * does that too.
   * @return the current total supply
   **/
  function totalSupply() public view override(IncentivizedERC20, IERC20) returns (uint256) {
    uint256 currentSupplyScaled = super.totalSupply();

    if (currentSupplyScaled == 0) {
      return 0;
    }

    return currentSupplyScaled.rayMul(_pool.getReserveNormalizedIncome(_underlyingAsset));
  }

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return the scaled total supply
   **/
  function scaledTotalSupply() public view virtual override returns (uint256) {
    return super.totalSupply();
  }

  /**
   * @dev Returns the address of the Aave treasury, receiving the fees on this vToken
   **/
  function RESERVE_TREASURY_ADDRESS() public view returns (address) {
    return _treasury;
  }

  /**
   * @dev Returns the address of the underlying asset of this vToken (E.g. WETH for aWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() public override view returns (address) {
    return _underlyingAsset;
  }

  /**
   * @dev Returns the address of the lending pool where this vToken is used
   **/
  function POOL() public view returns (ILendingPool) {
    return _pool;
  }

  /**
   * @dev For internal usage in the logic of the parent contract IncentivizedERC20
   **/
  function _getIncentivesController() internal view override returns (IAaveIncentivesController) {
    return _incentivesController;
  }

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view override returns (IAaveIncentivesController) {
    return _getIncentivesController();
  }

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param target The recipient of the vTokens
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address target, uint256 amount)
    external
    override
    onlyLendingPool
    returns (uint256)
  {
    IERC20(_underlyingAsset).safeTransfer(target, amount);
    return amount;
  }

  /**
   * @dev Invoked to execute actions on the vToken side after a repayment.
   * @param user The user executing the repayment
   * @param amount The amount getting repaid
   **/
  function handleRepayment(address user, uint256 amount) external override onlyLendingPool {}

  /**
   * @dev implements the permit function as for
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner The owner of the funds
   * @param spender The spender
   * @param value The amount
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param v Signature param
   * @param s Signature param
   * @param r Signature param
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(owner != address(0), 'INVALID_OWNER');
    //solium-disable-next-line
    require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
    uint256 currentValidNonce = _nonces[owner];
    bytes32 digest =
      keccak256(
        abi.encodePacked(
          '\x19\x01',
          DOMAIN_SEPARATOR,
          keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
        )
      );
    require(owner == ecrecover(digest, v, r, s), 'INVALID_SIGNATURE');
    _nonces[owner] = currentValidNonce + 1;
    _approve(owner, spender, value);
  }

  /**
   * @dev Transfers the vTokens between two users. Validates the transfer
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
    ILendingPool pool = _pool;

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
pragma solidity 0.8.11;

import {IReserveInterestRateStrategy} from '../../interfaces/IReserveInterestRateStrategy.sol';
import {WadRayMath} from '../libraries/math/WadRayMath.sol';
import {PercentageMath} from '../libraries/math/PercentageMath.sol';
import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';
import {ILendingRateOracle} from '../../interfaces/ILendingRateOracle.sol';
import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';

/**
 * @title DefaultReserveInterestRateStrategy contract
 * @notice Implements the calculation of the interest rates depending on the reserve state
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_UTILIZATION_RATE`
 * point of utilization and another from that one to 100%
 * - An instance of this same contract, can't be used across different Aave markets, due to the caching
 *   of the LendingPoolAddressesProvider
 * @author Aave
 **/
contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
  using WadRayMath for uint256;
  using PercentageMath for uint256;

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

  ILendingPoolAddressesProvider public immutable addressesProvider;

  // Base variable borrow rate when Utilization rate = 0. Expressed in ray
  uint256 internal immutable _baseVariableBorrowRate;

  // Slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
  uint256 internal immutable _variableRateSlope1;

  // Slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
  uint256 internal immutable _variableRateSlope2;

  // Slope of the stable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
  uint256 internal immutable _stableRateSlope1;

  // Slope of the stable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
  uint256 internal immutable _stableRateSlope2;

  constructor(
    ILendingPoolAddressesProvider provider,
    uint256 optimalUtilizationRate,
    uint256 baseVariableBorrowRate,
    uint256 variableRateSlope1,
    uint256 variableRateSlope2,
    uint256 stableRateSlope1,
    uint256 stableRateSlope2
  ) public {
    OPTIMAL_UTILIZATION_RATE = optimalUtilizationRate;
    EXCESS_UTILIZATION_RATE = WadRayMath.ray() - optimalUtilizationRate;
    addressesProvider = provider;
    _baseVariableBorrowRate = baseVariableBorrowRate;
    _variableRateSlope1 = variableRateSlope1;
    _variableRateSlope2 = variableRateSlope2;
    _stableRateSlope1 = stableRateSlope1;
    _stableRateSlope2 = stableRateSlope2;
  }

  function variableRateSlope1() external view returns (uint256) {
    return _variableRateSlope1;
  }

  function variableRateSlope2() external view returns (uint256) {
    return _variableRateSlope2;
  }

  function stableRateSlope1() external view returns (uint256) {
    return _stableRateSlope1;
  }

  function stableRateSlope2() external view returns (uint256) {
    return _stableRateSlope2;
  }

  function baseVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate;
  }

  function getMaxVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
  }

  /**
   * @dev Calculates the interest rates depending on the reserve's state and configurations
   * @param reserve The address of the reserve
   * @param liquidityAdded The liquidity added during the operation
   * @param liquidityTaken The liquidity taken during the operation
   * @param totalStableDebt The total borrowed from the reserve a stable rate
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param averageStableBorrowRate The weighted average of all the stable rate loans
   * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
   * @return The liquidity rate, the stable borrow rate and the variable borrow rate
   **/
  function calculateInterestRates(
    address reserve,
    address vToken,
    uint256 liquidityAdded,
    uint256 liquidityTaken,
    uint256 totalStableDebt,
    uint256 totalVariableDebt,
    uint256 averageStableBorrowRate,
    uint256 reserveFactor
  )
    external
    view
    override
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 availableLiquidity = IERC20(reserve).balanceOf(vToken);
    //avoid stack too deep
    availableLiquidity = availableLiquidity + liquidityAdded - liquidityTaken;

    return
      calculateInterestRates(
        reserve,
        availableLiquidity,
        totalStableDebt,
        totalVariableDebt,
        averageStableBorrowRate,
        reserveFactor
      );
  }

  struct CalcInterestRatesLocalVars {
    uint256 totalDebt;
    uint256 currentVariableBorrowRate;
    uint256 currentStableBorrowRate;
    uint256 currentLiquidityRate;
    uint256 utilizationRate;
  }

  /**
   * @dev Calculates the interest rates depending on the reserve's state and configurations.
   * NOTE This function is kept for compatibility with the previous DefaultInterestRateStrategy interface.
   * New protocol implementation uses the new calculateInterestRates() interface
   * @param reserve The address of the reserve
   * @param availableLiquidity The liquidity available in the corresponding vToken
   * @param totalStableDebt The total borrowed from the reserve a stable rate
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param averageStableBorrowRate The weighted average of all the stable rate loans
   * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
   * @return The liquidity rate, the stable borrow rate and the variable borrow rate
   **/
  function calculateInterestRates(
    address reserve,
    uint256 availableLiquidity,
    uint256 totalStableDebt,
    uint256 totalVariableDebt,
    uint256 averageStableBorrowRate,
    uint256 reserveFactor
  )
    public
    view
    override
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    CalcInterestRatesLocalVars memory vars;

    vars.totalDebt = totalVariableDebt;
    vars.currentVariableBorrowRate = 0;
    vars.currentLiquidityRate = 0;

    vars.utilizationRate = vars.totalDebt == 0
      ? 0
      : vars.totalDebt.rayDiv(availableLiquidity + vars.totalDebt);

    /*vars.currentStableBorrowRate = ILendingRateOracle(addressesProvider.getLendingRateOracle())
      .getMarketBorrowRate(reserve)*/

    if (vars.utilizationRate > OPTIMAL_UTILIZATION_RATE) {
      uint256 excessUtilizationRateRatio =
        (vars.utilizationRate - OPTIMAL_UTILIZATION_RATE).rayDiv(EXCESS_UTILIZATION_RATE);

      /*vars.currentStableBorrowRate = vars.currentStableBorrowRate + _stableRateSlope1
        + _stableRateSlope2.rayMul(excessUtilizationRateRatio);*/

      vars.currentVariableBorrowRate = _baseVariableBorrowRate + _variableRateSlope1
        + _variableRateSlope2.rayMul(excessUtilizationRateRatio);
    } else {
      /*vars.currentStableBorrowRate = vars.currentStableBorrowRate
        + _stableRateSlope1.rayMul(vars.utilizationRate.rayDiv(OPTIMAL_UTILIZATION_RATE));*/
      vars.currentVariableBorrowRate = _baseVariableBorrowRate
        + vars.utilizationRate.rayMul(_variableRateSlope1).rayDiv(OPTIMAL_UTILIZATION_RATE);
    }

    vars.currentLiquidityRate = vars.currentVariableBorrowRate
    /*_getOverallBorrowRate(
      0,
      totalVariableDebt,
      vars
        .currentVariableBorrowRate,
      0//averageStableBorrowRate
    )*/
      .rayMul(vars.utilizationRate)
      .percentMul(PercentageMath.PERCENTAGE_FACTOR - reserveFactor);

    return (
      vars.currentLiquidityRate,
      0, //vars.currentStableBorrowRate,
      vars.currentVariableBorrowRate
    );
  }

  /**
   * @dev Calculates the overall borrow rate as the weighted average between the total variable debt and total stable debt
   * @param totalStableDebt The total borrowed from the reserve a stable rate
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param currentVariableBorrowRate The current variable borrow rate of the reserve
   * @param currentAverageStableBorrowRate The current weighted average of all the stable rate loans
   * @return The weighted averaged borrow rate
   **/
  function _getOverallBorrowRate(
    uint256 totalStableDebt,
    uint256 totalVariableDebt,
    uint256 currentVariableBorrowRate,
    uint256 currentAverageStableBorrowRate
  ) internal pure returns (uint256) {
    uint256 totalDebt = totalVariableDebt;

    if (totalDebt == 0) return 0;

    //uint256 weightedVariableRate = totalVariableDebt.wadToRay().rayMul(currentVariableBorrowRate);

    //uint256 weightedStableRate = totalStableDebt.wadToRay().rayMul(currentAverageStableBorrowRate);

    uint256 overallBorrowRate =
      currentVariableBorrowRate;

    return overallBorrowRate;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
pragma solidity 0.8.11;

library StringLib {
  function concat(string memory a, string memory b) internal pure returns (string memory) {
    return string(abi.encodePacked(a, b));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.11;

import {IERC20} from '../../openzeppelin/contracts/IERC20.sol';

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract.
library GPv2SafeERC20 {
  /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
  /// also when the token returns `false`.
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    bytes4 selector_ = token.transfer.selector;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let freeMemoryPointer := mload(0x40)
      mstore(freeMemoryPointer, selector_)
      mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
      mstore(add(freeMemoryPointer, 36), value)

      if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    require(getLastTransferResult(token), 'GPv2: failed transfer');
  }

  /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
  /// reverts also when the token returns `false`.
  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    bytes4 selector_ = token.transferFrom.selector;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      let freeMemoryPointer := mload(0x40)
      mstore(freeMemoryPointer, selector_)
      mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
      mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
      mstore(add(freeMemoryPointer, 68), value)

      if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    require(getLastTransferResult(token), 'GPv2: failed transferFrom');
  }

  /// @dev Verifies that the last return was a successful `transfer*` call.
  /// This is done by checking that the return data is either empty, or
  /// is a valid ABI encoded boolean.
  function getLastTransferResult(IERC20 token) private view returns (bool success) {
    // NOTE: Inspecting previous return data requires assembly. Note that
    // we write the return data to memory 0 in the case where the return
    // data size is 32, this is OK since the first 64 bytes of memory are
    // reserved by Solidy as a scratch space that can be used within
    // assembly blocks.
    // <https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html>
    // solhint-disable-next-line no-inline-assembly
    assembly {
      /// @dev Revert with an ABI encoded Solidity error with a message
      /// that fits into 32-bytes.
      ///
      /// An ABI encoded Solidity error has the following memory layout:
      ///
      /// ------------+----------------------------------
      ///  byte range | value
      /// ------------+----------------------------------
      ///  0x00..0x04 |        selector("Error(string)")
      ///  0x04..0x24 |      string offset (always 0x20)
      ///  0x24..0x44 |                    string length
      ///  0x44..0x64 | string value, padded to 32-bytes
      function revertWithMessage(length, message) {
        mstore(0x00, '\x08\xc3\x79\xa0')
        mstore(0x04, 0x20)
        mstore(0x24, length)
        mstore(0x44, message)
        revert(0x00, 0x64)
      }

      switch returndatasize()
      // Non-standard ERC20 transfer without return.
      case 0 {
        // NOTE: When the return data size is 0, verify that there
        // is code at the address. This is done in order to maintain
        // compatibility with Solidity calling conventions.
        // <https://docs.soliditylang.org/en/v0.7.6/control-structures.html#external-function-calls>
        if iszero(extcodesize(token)) {
          revertWithMessage(20, 'GPv2: not a contract')
        }

        success := 1
      }
      // Standard ERC20 transfer returning boolean success value.
      case 32 {
        returndatacopy(0, 0, returndatasize())

        // NOTE: For ABI encoding v1, any non-zero value is accepted
        // as `true` for a boolean. In order to stay compatible with
        // OpenZeppelin's `SafeERC20` library which is known to work
        // with the existing ERC20 implementation we care about,
        // make sure we return success for any non-zero return value
        // from the `transfer*` call.
        success := iszero(iszero(mload(0)))
      }
      default {
        revertWithMessage(31, 'GPv2: malformed transfer result')
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

pragma solidity ^0.8.0;

import "../../../dependencies/openzeppelin/contracts/IERC721.sol";
import "../../../dependencies/openzeppelin/contracts/Address.sol";

library SafeERC721 {
   using Address for address;

    function safeApprove(
        IERC721 token,
        address spender,
        uint256 tokenId
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, tokenId));
    }

    function safeSetApprovalForAll(
        IERC721 token,
        address operator,
        bool approved
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.setApprovalForAll.selector, operator, approved));

    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC721 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC721: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC721: ERC721 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import {IInitializableVToken} from './IInitializableVToken.sol';
import {IAaveIncentivesController} from './IAaveIncentivesController.sol';

interface IVToken is IERC20, IScaledBalanceToken, IInitializableVToken {
  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   * @param index The new liquidity index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints `amount` vTokens to `user`
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
   * @dev Emitted after vTokens are burned
   * @param from The owner of the vTokens, getting them burned
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
   * @dev Burns vTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the vTokens, getting them burned
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
   * @dev Mints vTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @dev Transfers vTokens in the event of a borrow being liquidated, in case the liquidators reclaims the vToken
   * @param from The address getting liquidated, current owner of the vTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external;

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
   * assets in borrow(), withdraw() and flashLoan()
   * @param user The recipient of the underlying
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

  /**
   * @dev Invoked to execute actions on the vToken side after a repayment.
   * @param user The user executing the repayment
   * @param amount The amount getting repaid
   **/
  function handleRepayment(address user, uint256 amount) external;

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view returns (IAaveIncentivesController);

  /**
   * @dev Returns the address of the underlying asset of this vToken (E.g. WETH for aWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {ITimeLockableERC721} from './ITimeLockableERC721.sol';
import {IInitializableNToken} from './IInitializableNToken.sol';

interface INToken is ITimeLockableERC721, IInitializableNToken {
    /**
    * @dev Emitted after the mint action
    * @param from The address performing the mint
    * @param tokenId The token id being
    * @param value The amount being
    **/
    event Mint(address indexed from, uint256 tokenId, uint256 value);

    /**
    * @dev Mints `amount` NTokens with `tokenId` to `user`
    * @param user The address receiving the minted tokens
    * @param tokenId The NFT's id
    * @param amount The amount of tokens getting minted
    * @return `true` if the the previous balance of the user was 0
    */
    function mint(
        address user,
        uint256 tokenId,
        uint256 amount
    ) external returns (bool);

    /**
   * @dev Emitted after nTokens are burned
   * @param from The owner of the nTokens, getting them burned
   * @param target The address that will receive the underlying
   * @param tokenId The token id being burned
   * @param value The amount being burned
   **/
  event Burn(address indexed from, address indexed target, uint256 tokenId, uint256 value);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param tokenId The NFT token id being transfered
   * @param amount The amount being transferred
   **/
  event BalanceTransfer(address indexed from, address indexed to, uint256 tokenId, uint256 amount);

  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param tokenIds The ids of NFT tokens being transferred
   * @param amounts The amounts being transferred
   **/
  event BalanceBatchTransfer(address indexed from, address indexed to, uint256[] tokenIds, uint256[] amounts);

  /**
   * @dev Burns nTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the vTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param tokenId The token id being burned
   * @param amount The amount being burned
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 tokenId,
    uint256 amount
  ) external;

  function burnBatch(
    address user,
    address receiverOfUnderlying,
    uint256[] memory tokenIds,
    uint256[] memory amounts
  ) external;

  /**
   * @dev Transfers nTokens in the event of a borrow being liquidated, in case the liquidators reclaims the nToken
   * @param from The address getting liquidated, current owner of the vTokens
   * @param to The recipient
   * @param tokenIds The token id of tokens getting transffered
   * @param values The amount of tokens getting transferred
   **/
  function transferOnLiquidation(
    address from,
    address to,
    uint256[] memory tokenIds,
    uint256[] memory values
  ) external;

  /**
   * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
   * assets in withdrawNFT()
   * @param user The recipient of the underlying
   * @param tokenId The token id getting transferred
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 tokenId, uint256 amount) external returns (uint256);

  function getLiquidationAmounts(address user, uint256 maxTotal, uint256[] memory tokenIds, uint256[] memory amounts) external view returns(uint256, uint256[] memory);

  /**
   * @dev Returns the address of the underlying asset of this nToken
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721Enumerable} from '../dependencies/openzeppelin/contracts/IERC721Enumerable.sol';


interface IERC721WithStat is IERC721Enumerable{
    function balanceOfBatch(address user, uint256[] calldata ids) external view returns (uint256[] memory);
    function tokensByAccount(address account) external view returns (uint256[] memory);
    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getUserBalanceAndSupply(address user) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';
import {ILendingPool} from '../../interfaces/ILendingPool.sol';

/**
 * @title INFTFlashLoanReceiver interface
 * @notice Interface for the Vinci fee INFTFlashLoanReceiver.
 * @author Aave
 * @author Vinci
 * @dev implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 **/
interface INFTFlashLoanReceiver {
  function executeOperation(
    address assets,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    uint256 premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);

  function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider);

  function LENDING_POOL() external view returns (ILendingPool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import {IInitializableDebtToken} from './IInitializableDebtToken.sol';
import {IAaveIncentivesController} from './IAaveIncentivesController.sol';

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param onBehalfOf The address of the user on which behalf minting has been performed
   * @param value The amount to be minted
   * @param index The last index of the reserve
   **/
  event Mint(address indexed from, address indexed onBehalfOf, uint256 value, uint256 index);

  /**
   * @dev Mints debt token to the `onBehalfOf` address
   * @param user The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `onBehalfOf` otherwise
   * @param onBehalfOf The address receiving the debt tokens
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
  function getIncentivesController() external view returns (IAaveIncentivesController);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

/**
 * @title IPriceOracleGetter interface
 * @notice Interface for the Aave price oracle.
 **/

interface IPriceOracleGetter {
  /**
   * @dev returns the asset price in ETH
   * @param asset the address of the asset
   * @return the ETH price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTXEligibility {
    // Read functions.
    function name() external pure returns (string memory);
    function finalized() external view returns (bool);
    function targetAsset() external pure returns (address);
    function checkAllEligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool);
    function checkEligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool[] memory);
    function checkAllIneligible(uint256[] calldata tokenIds)
        external
        view
        returns (bool);
    function checkIsEligible(uint256 tokenId) external view returns (bool);

    // Write functions.
    function __NFTXEligibility_init_bytes(bytes calldata configData) external;
    function beforeMintHook(uint256[] calldata tokenIds) external;
    function afterMintHook(uint256[] calldata tokenIds) external;
    function beforeRedeemHook(uint256[] calldata tokenIds) external;
    function afterRedeemHook(uint256[] calldata tokenIds) external;
    function afterLiquidationHook(uint256[] calldata tokenIds, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma abicoder v2;

import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the vTokens
   * @param amount The amount deposited
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
   * @param user The address initiating the withdrawal, owner of vTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  event DepositNFT(
    address indexed vault, 
    address user,
    address indexed onBehalfOf, 
    uint256[] tokenIds, 
    uint256[] amounts,
    uint16 indexed referral
  );

  event WithdrawNFT(
    address indexed vault, 
    address indexed user, 
    address indexed to, 
    uint256[] tokenIds,
    uint256[] amounts
  );

  /**
   * @dev Emitted on nftFlashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param tokenIds The token IDs for each NFT being flash borrowed
   * @param amounts The amounts for each NFT being flash borrowed
   * @param premium The fee flash borrowed
   **/
  event NFTFlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256[] tokenIds,
    uint256[] amounts,
    uint256 premium,
    uint16 referralCode
  );


  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
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
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted when a reserve is disabled as collateral for an user
   * @param reserve The address of the reserve
   * @param user The address of the user
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted when a reserve is enabled as collateral for an user
   * @param reserve The address of the reserve
   * @param user The address of the user
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseNFTVaultAsCollateral()
   * @param nftVault The address of the underlying asset of the vault
   * @param user The address of the user enabling the usage as collateral
   **/
  event NFTVaultUsedAsCollateralEnabled(address indexed nftVault, address indexed user);

  /**
   * @dev Emitted on setUserUseNFTVaultAsCollateral()
   * @param nftVault The address of the underlying asset of the vault
   * @param user The address of the user enabling the usage as collateral
   **/
  event NFTVaultUsedAsCollateralDisabled(address indexed nftVault, address indexed user);

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
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying vTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the vTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of vTokens
   *   is a different wallet
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent vTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole vToken balance
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
   * @dev Deposits an `amounts[i]` of underlying `tokenIds[i]` into the NFT reserve, receiving in return overlying nTokens.
   * @param tokenIds The tokenIds of the NFTs to be deposited
   * @param amounts For ERC1155 only: The amounts of NFTs to be deposited
   * @param onBehalfOf The address that will receive the nTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of nTokens
   *   is a different wallet
   **/
  function depositNFT(
    address nft,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Deposits an `amounts[i]` of underlying `tokenIds[i]` into the NFT reserve, receiving in return overlying nTokens.
   * @param tokenIds The tokenIds of the NFTs to be deposited
   * @param amounts For ERC1155 only: The amounts of NFTs to be deposited
   * @param onBehalfOf The address that will receive the nTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of nTokens
   *   is a different wallet
   **/
  function depositAndLockNFT(
    address nft,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    address onBehalfOf,
    uint16 lockType,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amounts[i]` of nTokens with `tokenIds[i]` from the reserve, burning the equivalent nTokens owned
   * @param tokenIds The tokenIds of the NFTs to be withdraw
   * @param amounts For ERC1155 only: The amounts of NFTs to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole ERC1155 tokenId balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn. 
       - the `returnedValue[i]` equals the amount of `tokenIds[i]` that has been withdrawn.
   **/
  function withdrawNFT(
    address nft,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    address to
  ) external returns (uint256[] memory);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral.
   * @param amount The amount to be borrowed
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
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  function nftLiquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    bool receiveNToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the nft vault of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the INFTFlashLoanReceiver interface
   * @param asset The addresses of the assets being flash-borrowed
   * @param tokenIds The tokenIds of the NFTs being flash-borrowed
   * @param amounts For ERC1155 only: The amounts of NFTs being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   **/
  function nftFlashLoan(
    address receiverAddress,
    address asset,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    bytes calldata params,
    uint16 referralCode
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

  function initReserve(
    address reserve,
    address vTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function initNFTVault(
    address vault,
    address nTokenAddress,
    address nftEligibility
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;
  function setNFTVaultConfiguration(address reserve, uint256 configuration) external;
  function setNFTVaultActionExpiration(address nftValue, uint40 expiration) external;

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
   * @dev Returns the configuration of the NFT reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getNFTVaultConfiguration(address asset)
    external
    view
    returns (DataTypes.NFTVaultConfigurationMap memory);

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
   * @dev Returns the state and configuration of the NFT reserve
   * @param asset The address of the underlying NFT of the reserve
   * @return The state of the reserve
   **/
  function getNFTVaultData(address asset) external view returns (DataTypes.NFTVaultData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function finalizeNFTSingleTransfer(
    address asset,
    address from,
    address to,
    uint256 tokenId,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function finalizeNFTBatchTransfer(
    address asset,
    address from,
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);
  function getNFTVaultsList() external view returns (address[] memory);


  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 */
abstract contract VersionedInitializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 private lastInitializedRevision = 0;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    require(
      initializing || isConstructor() || revision > lastInitializedRevision,
      'Contract instance has already been initialized'
    );

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      lastInitializedRevision = revision;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /**
   * @dev returns the revision number of the contract
   * Needs to be defined in the inherited class as a constant.
   **/
  function getRevision() internal pure virtual returns (uint256);

  /**
   * @dev Returns true if and only if the function is running in the constructor
   **/
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    //solium-disable-next-line
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title Helpers library
 * @author Aave
 */
library Helpers {
  /**
   * @dev Fetches the user current stable and variable debt balances
   * @param user The user address
   * @param reserve The reserve data object
   * @return The stable and variable debt balance
   **/
  function getUserCurrentDebt(address user, DataTypes.ReserveData storage reserve)
    internal
    view
    returns (uint256, uint256)
  {
    return (
      0, //IERC20(reserve.stableDebtTokenAddress).balanceOf(user),
      IERC20(reserve.variableDebtTokenAddress).balanceOf(user)
    );
  }

  function getUserCurrentDebtMemory(address user, DataTypes.ReserveData memory reserve)
    internal
    view
    returns (uint256, uint256)
  {
    return (
      0, //IERC20(reserve.stableDebtTokenAddress).balanceOf(user),
      IERC20(reserve.variableDebtTokenAddress).balanceOf(user)
    );
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (VToken, VariableDebtToken and StableDebtToken)
 *  - AT = VToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = LendingPoolAddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - NL = NFTVaultLogic
 *  - LPCM = LendingPoolCollateralManager
 *  - P = Pausable
 */
library Errors {
  //common errors
  string public constant CALLER_NOT_POOL_ADMIN = '33'; // 'The caller must be the pool admin'
  string public constant BORROW_ALLOWANCE_NOT_ENOUGH = '59'; // User borrows on behalf, but allowance are too small

  //contract specific errors
  string public constant VL_INVALID_AMOUNT = '1'; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = '2'; // 'Action requires an active reserve'
  string public constant VL_RESERVE_FROZEN = '3'; // 'Action cannot be performed because the reserve is frozen'
  string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = '4'; // 'The current liquidity is not enough'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // 'User cannot withdraw more than the available balance'
  string public constant VL_TRANSFER_NOT_ALLOWED = '6'; // 'Transfer cannot be allowed.'
  string public constant VL_BORROWING_NOT_ENABLED = '7'; // 'Borrowing is not enabled'
  string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '8'; // 'Invalid interest rate mode selected'
  string public constant VL_COLLATERAL_BALANCE_IS_0 = '9'; // 'The collateral balance is 0'
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '10'; // 'Health factor is lesser than the liquidation threshold'
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = '11'; // 'There is not enough collateral to cover a new borrow'
  string public constant VL_STABLE_BORROWING_NOT_ENABLED = '12'; // stable borrowing not enabled
  string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = '13'; // collateral is (mostly) the same currency that is being borrowed
  string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '14'; // 'The requested amount is greater than the max loan size in stable rate mode
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = '15'; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '16'; // 'To repay on behalf of an user an explicit amount to repay is needed'
  string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = '17'; // 'User does not have a stable rate loan in progress on this reserve'
  string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = '18'; // 'User does not have a variable rate loan in progress on this reserve'
  string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // 'The underlying balance needs to be greater than 0'
  string public constant VL_DEPOSIT_ALREADY_IN_USE = '20'; // 'User deposit is already being used as collateral'
  string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = '21'; // 'User does not have any stable rate loan for this reserve'
  string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '22'; // 'Interest rate rebalance conditions were not met'
  string public constant LP_LIQUIDATION_CALL_FAILED = '23'; // 'Liquidation call failed'
  string public constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = '24'; // 'There is not enough liquidity available to borrow'
  string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = '25'; // 'The requested amount is too small for a FlashLoan.'
  string public constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = '26'; // 'The actual balance of the protocol is inconsistent'
  string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = '27'; // 'The caller of the function is not the lending pool configurator'
  string public constant LP_INCONSISTENT_FLASHLOAN_PARAMS = '28';
  string public constant CT_CALLER_MUST_BE_LENDING_POOL = '29'; // 'The caller of this function must be a lending pool'
  string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = '30'; // 'User cannot give allowance to himself'
  string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = '31'; // 'Transferred amount needs to be greater than zero'
  string public constant RL_RESERVE_ALREADY_INITIALIZED = '32'; // 'Reserve has already been initialized'
  string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = '34'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_VTOKEN_POOL_ADDRESS = '35'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = '36'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = '37'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '38'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '39'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = '40'; // 'The liquidity of the reserve needs to be 0'
  string public constant LPC_INVALID_CONFIGURATION = '75'; // 'Invalid risk parameters for the reserve'
  string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = '76'; // 'The caller must be the emergency admin'
  string public constant LPAPR_PROVIDER_NOT_REGISTERED = '41'; // 'Provider is not registered'
  string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '42'; // 'Health factor is not below the threshold'
  string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = '43'; // 'The collateral chosen cannot be liquidated'
  string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '44'; // 'User did not borrow the specified currency'
  string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = '45'; // "There isn't enough liquidity available to liquidate"
  string public constant LPCM_NO_ERRORS = '46'; // 'No errors'
  string public constant LP_INVALID_FLASHLOAN_MODE = '47'; //Invalid flashloan mode selected
  string public constant MATH_MULTIPLICATION_OVERFLOW = '48';
  string public constant MATH_ADDITION_OVERFLOW = '49';
  string public constant MATH_DIVISION_BY_ZERO = '50';
  string public constant RL_LIQUIDITY_INDEX_OVERFLOW = '51'; //  Liquidity index overflows uint128
  string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = '52'; //  Variable borrow index overflows uint128
  string public constant RL_LIQUIDITY_RATE_OVERFLOW = '53'; //  Liquidity rate overflows uint128
  string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = '54'; //  Variable borrow rate overflows uint128
  string public constant RL_STABLE_BORROW_RATE_OVERFLOW = '55'; //  Stable borrow rate overflows uint128
  string public constant CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
  string public constant LP_FAILED_REPAY_WITH_COLLATERAL = '57';
  string public constant CT_INVALID_BURN_AMOUNT = '58'; //invalid amount to burn
  string public constant LP_FAILED_COLLATERAL_SWAP = '60';
  string public constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = '61';
  string public constant LP_REENTRANCY_NOT_ALLOWED = '62';
  string public constant LP_CALLER_MUST_BE_AN_VTOKEN = '63';
  string public constant LP_IS_PAUSED = '64'; // 'Pool is paused'
  string public constant LP_NO_MORE_RESERVES_ALLOWED = '65';
  string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = '66';
  string public constant RC_INVALID_LTV = '67';
  string public constant RC_INVALID_LIQ_THRESHOLD = '68';
  string public constant RC_INVALID_LIQ_BONUS = '69';
  string public constant RC_INVALID_DECIMALS = '70';
  string public constant RC_INVALID_RESERVE_FACTOR = '71';
  string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = '72';
  string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = '73';
  string public constant LP_INCONSISTENT_PARAMS_LENGTH = '74';
  string public constant UL_INVALID_INDEX = '77';
  string public constant LP_NOT_CONTRACT = '78';
  string public constant SDT_STABLE_DEBT_OVERFLOW = '79';
  string public constant SDT_BURN_EXCEEDS_BALANCE = '80';
  string public constant CT_CALLER_MUST_BE_CLAIM_ADMIN = '81';
  string public constant CT_TOKEN_CAN_NOT_BE_UNDERLYING = '82';
  string public constant CT_TOKEN_CAN_NOT_BE_SELF = '83';
  string public constant VL_NFT_LOCK_ACTION_IS_EXPIRED = '84';
  string public constant NL_VAULT_ALREADY_INITIALIZED = '100'; // 'NFT vault has already been initialized'
  string public constant VL_NFT_INELIGIBLE_TOKEN_ID = '130';
  string public constant LP_TOKEN_AND_AMOUNT_LENGTH_NOT_MATCH = "148";


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
pragma solidity 0.8.11;

import {Errors} from '../helpers/Errors.sol';

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

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
    return halfRAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
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

    require(a <= (type(uint256).max - halfWAD) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + halfWAD) / WAD;
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

    require(a <= (type(uint256).max - halfRAY) / b, Errors.MATH_MULTIPLICATION_OVERFLOW);

    return (a * b + halfRAY) / RAY;
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {Errors} from '../helpers/Errors.sol';

/**
 * @title PercentageMath library
 * @author Aave
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

    require(
      value <= (type(uint256).max - HALF_PERCENT) / percentage,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

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

    require(
      value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
      Errors.MATH_MULTIPLICATION_OVERFLOW
    );

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {IVToken} from '../../../interfaces/IVToken.sol';
//import {IStableDebtToken} from '../../../interfaces/IStableDebtToken.sol';
import {IVariableDebtToken} from '../../../interfaces/IVariableDebtToken.sol';
import {IReserveInterestRateStrategy} from '../../../interfaces/IReserveInterestRateStrategy.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {MathUtils} from '../math/MathUtils.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title ReserveLogic library
 * @author Aave
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using GPv2SafeERC20 for IERC20;

  /**
   * @dev Emitted when the state of a reserve is updated
   * @param asset The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed asset,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
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
  function getNormalizedIncome(DataTypes.ReserveData storage reserve)
    internal
    view
    returns (uint256)
  {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == uint40(block.timestamp)) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.liquidityIndex;
    }

    uint256 cumulated =
      MathUtils.calculateLinearInterest(reserve.currentLiquidityRate, timestamp).rayMul(
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
  function getNormalizedDebt(DataTypes.ReserveData storage reserve)
    internal
    view
    returns (uint256)
  {
    uint40 timestamp = reserve.lastUpdateTimestamp;

    //solium-disable-next-line
    if (timestamp == uint40(block.timestamp)) {
      //if the index was updated in the same block, no need to perform any calculation
      return reserve.variableBorrowIndex;
    }

    uint256 cumulated =
      MathUtils.calculateCompoundedInterest(reserve.currentVariableBorrowRate, timestamp).rayMul(
        reserve.variableBorrowIndex
      );

    return cumulated;
  }

  /**
   * @dev Updates the liquidity cumulative index and the variable borrow index.
   * @param reserve the reserve object
   **/
  function updateState(DataTypes.ReserveData storage reserve) internal {
    uint256 scaledVariableDebt =
      IVariableDebtToken(reserve.variableDebtTokenAddress).scaledTotalSupply();
    uint256 previousVariableBorrowIndex = reserve.variableBorrowIndex;
    uint256 previousLiquidityIndex = reserve.liquidityIndex;
    uint40 lastUpdatedTimestamp = reserve.lastUpdateTimestamp;

    (uint256 newLiquidityIndex, uint256 newVariableBorrowIndex) =
      _updateIndexes(
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

    uint256 result = amountToLiquidityRatio + WadRayMath.ray();

    result = result.rayMul(reserve.liquidityIndex);
    require(result <= type(uint128).max, Errors.RL_LIQUIDITY_INDEX_OVERFLOW);

    reserve.liquidityIndex = uint128(result);
  }

  /**
   * @dev Initializes a reserve
   * @param reserve The reserve object
   * @param vTokenAddress The address of the overlying vtoken contract
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
  function init(
    DataTypes.ReserveData storage reserve,
    address vTokenAddress,
    address stableDebtTokenAddress,
    address variableDebtTokenAddress,
    address interestRateStrategyAddress
  ) external {
    require(reserve.vTokenAddress == address(0), Errors.RL_RESERVE_ALREADY_INITIALIZED);

    reserve.liquidityIndex = uint128(WadRayMath.ray());
    reserve.variableBorrowIndex = uint128(WadRayMath.ray());
    reserve.vTokenAddress = vTokenAddress;
    reserve.stableDebtTokenAddress = stableDebtTokenAddress;
    reserve.variableDebtTokenAddress = variableDebtTokenAddress;
    reserve.interestRateStrategyAddress = interestRateStrategyAddress;
  }

  struct UpdateInterestRatesLocalVars {
    //address stableDebtTokenAddress;
    uint256 availableLiquidity;
    //uint256 totalStableDebt;
    uint256 newLiquidityRate;
    //uint256 newStableRate;
    uint256 newVariableRate;
    //uint256 avgStableRate;
    uint256 totalVariableDebt;
  }

  /**
   * @dev Updates the reserve current stable borrow rate, the current variable borrow rate and the current liquidity rate
   * @param reserve The address of the reserve to be updated
   * @param liquidityAdded The amount of liquidity added to the protocol (deposit or repay) in the previous action
   * @param liquidityTaken The amount of liquidity taken from the protocol (redeem or borrow)
   **/
  function updateInterestRates(
    DataTypes.ReserveData storage reserve,
    address reserveAddress,
    address vTokenAddress,
    uint256 liquidityAdded,
    uint256 liquidityTaken
  ) internal {
    UpdateInterestRatesLocalVars memory vars;

    //vars.stableDebtTokenAddress = reserve.stableDebtTokenAddress;

    //(vars.totalStableDebt, vars.avgStableRate) = IStableDebtToken(vars.stableDebtTokenAddress)
    //  .getTotalSupplyAndAvgRate();

    //calculates the total variable debt locally using the scaled total supply instead
    //of totalSupply(), as it's noticeably cheaper. Also, the index has been
    //updated by the previous updateState() call
    vars.totalVariableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress)
      .scaledTotalSupply()
      .rayMul(reserve.variableBorrowIndex);

    (
      vars.newLiquidityRate,
      ,
      vars.newVariableRate
    ) = IReserveInterestRateStrategy(reserve.interestRateStrategyAddress).calculateInterestRates(
      reserveAddress,
      vTokenAddress,
      liquidityAdded,
      liquidityTaken,
      0,//vars.totalStableDebt,
      vars.totalVariableDebt,
      0,//vars.avgStableRate,
      reserve.configuration.getReserveFactor()
    );
    require(vars.newLiquidityRate <= type(uint128).max, Errors.RL_LIQUIDITY_RATE_OVERFLOW);
    //require(vars.newStableRate <= type(uint128).max, Errors.RL_STABLE_BORROW_RATE_OVERFLOW);
    require(vars.newVariableRate <= type(uint128).max, Errors.RL_VARIABLE_BORROW_RATE_OVERFLOW);

    reserve.currentLiquidityRate = uint128(vars.newLiquidityRate);
    //reserve.currentStableBorrowRate = uint128(vars.newStableRate);
    reserve.currentVariableBorrowRate = uint128(vars.newVariableRate);

    emit ReserveDataUpdated(
      reserveAddress,
      vars.newLiquidityRate,
      0, //vars.newStableRate,
      vars.newVariableRate,
      reserve.liquidityIndex,
      reserve.variableBorrowIndex
    );
  }

  struct MintToTreasuryLocalVars {
    //uint256 currentStableDebt;
    //uint256 principalStableDebt;
    //uint256 previousStableDebt;
    uint256 currentVariableDebt;
    uint256 previousVariableDebt;
    //uint256 avgStableRate;
    //uint256 cumulatedStableInterest;
    uint256 totalDebtAccrued;
    uint256 amountToMint;
    uint256 reserveFactor;
    //uint40 stableSupplyUpdatedTimestamp;
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
    MintToTreasuryLocalVars memory vars;

    vars.reserveFactor = reserve.configuration.getReserveFactor();

    if (vars.reserveFactor == 0) {
      return;
    }

    //fetching the principal, total stable debt and the avg stable rate
    /*(
      vars.principalStableDebt,
      vars.currentStableDebt,
      vars.avgStableRate,
      vars.stableSupplyUpdatedTimestamp
    ) = IStableDebtToken(reserve.stableDebtTokenAddress).getSupplyData();*/

    //calculate the last principal variable debt
    vars.previousVariableDebt = scaledVariableDebt.rayMul(previousVariableBorrowIndex);

    //calculate the new total supply after accumulation of the index
    vars.currentVariableDebt = scaledVariableDebt.rayMul(newVariableBorrowIndex);

    //calculate the stable debt until the last timestamp update
    /*vars.cumulatedStableInterest = MathUtils.calculateCompoundedInterest(
      vars.avgStableRate,
      vars.stableSupplyUpdatedTimestamp,
      timestamp
    );*/

    //vars.previousStableDebt = vars.principalStableDebt.rayMul(vars.cumulatedStableInterest);

    //debt accrued is the sum of the current debt minus the sum of the debt at the last update
    vars.totalDebtAccrued = vars.currentVariableDebt - vars.previousVariableDebt;

    vars.amountToMint = vars.totalDebtAccrued.percentMul(vars.reserveFactor);

    if (vars.amountToMint != 0) {
      IVToken(reserve.vTokenAddress).mintToTreasury(vars.amountToMint, newLiquidityIndex);
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
      uint256 cumulatedLiquidityInterest =
        MathUtils.calculateLinearInterest(currentLiquidityRate, timestamp);
      newLiquidityIndex = cumulatedLiquidityInterest.rayMul(liquidityIndex);
      require(newLiquidityIndex <= type(uint128).max, Errors.RL_LIQUIDITY_INDEX_OVERFLOW);

      reserve.liquidityIndex = uint128(newLiquidityIndex);

      //as the liquidity rate might come only from stable rate loans, we need to ensure
      //that there is actual variable debt before accumulating
      if (scaledVariableDebt != 0) {
        uint256 cumulatedVariableBorrowInterest =
          MathUtils.calculateCompoundedInterest(reserve.currentVariableBorrowRate, timestamp);
        newVariableBorrowIndex = cumulatedVariableBorrowInterest.rayMul(variableBorrowIndex);
        require(
          newVariableBorrowIndex <= type(uint128).max,
          Errors.RL_VARIABLE_BORROW_INDEX_OVERFLOW
        );
        reserve.variableBorrowIndex = uint128(newVariableBorrowIndex);
      }
    }

    //solium-disable-next-line
    reserve.lastUpdateTimestamp = uint40(block.timestamp);
    return (newLiquidityIndex, newVariableBorrowIndex);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {NFTVaultConfiguration} from '../configuration/NFTVaultConfiguration.sol';
import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title NFTVaultLogic library
 * @author Vinci
 * @notice Implements the logic to update the vault state
 */
library NFTVaultLogic {
  using NFTVaultLogic for DataTypes.NFTVaultData;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;

  /**
   * @dev Initializes a reserve
   * @param reserve The reserve object
   * @param nTokenAddress The address of the overlying vtoken contract
   **/
  function init(
    DataTypes.NFTVaultData storage reserve,
    address nTokenAddress,
    address nftEligibility
  ) external {
    require(reserve.nTokenAddress == address(0), Errors.NL_VAULT_ALREADY_INITIALIZED);
    reserve.nTokenAddress = nTokenAddress;
    reserve.nftEligibility = nftEligibility;
  }

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma abicoder v2;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC721WithStat} from '../../../interfaces/IERC721WithStat.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {NFTVaultLogic} from './NFTVaultLogic.sol';
import {NFTVaultConfiguration} from '../configuration/NFTVaultConfiguration.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title GenericLogic library
 * @author Aave
 * @title Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using NFTVaultLogic for DataTypes.NFTVaultData;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1 ether;

  struct balanceDecreaseAllowedLocalVars {
    uint256 liquidationThreshold;
    uint256 totalCollateralInETH;
    uint256 totalDebtInETH;
    uint256 avgLiquidationThreshold;
    uint256 amountToDecreaseInETH;
    uint256 collateralBalanceAfterDecrease;
    uint256 liquidationThresholdAfterDecrease;
    uint256 healthFactorAfterDecrease;
    bool reserveUsageAsCollateralEnabled;
  }

  /**
   * @dev Checks if a specific balance decrease is allowed
   * (i.e. doesn't bring the user borrow position health factor under HEALTH_FACTOR_LIQUIDATION_THRESHOLD)
   * @param asset The address of the underlying asset of the reserve
   * @param user The address of the user
   * @param amount The amount to decrease
   * @param reserves The data of all the reserves
   * @param nftVaults The data of all the vaults
   * @param userConfig The user configuration
   * @param oracle The address of the oracle contract
   * @return true if the decrease of the balance is allowed
   **/
  function balanceDecreaseAllowed(
    address asset,
    address user,
    uint256 amount,
    DataTypes.PoolReservesData storage reserves,
    DataTypes.PoolNFTVaultsData storage nftVaults,
    DataTypes.UserConfigurationMap calldata userConfig,
    address oracle
  ) external view returns (bool) {
    if (!userConfig.isBorrowingAny()) {
      return true;
    }

    balanceDecreaseAllowedLocalVars memory vars;

    (, vars.liquidationThreshold, ) = nftVaults.data[asset]
      .configuration
      .getParams();

    if (vars.liquidationThreshold == 0) {
      return true;
    }

    (
      vars.totalCollateralInETH,
      vars.totalDebtInETH,
      ,
      vars.avgLiquidationThreshold,

    ) = calculateUserAccountData(user, reserves, nftVaults, userConfig, oracle);

    if (vars.totalDebtInETH == 0) {
      return true;
    }

    vars.amountToDecreaseInETH = IPriceOracleGetter(oracle).getAssetPrice(asset) * amount;

    vars.collateralBalanceAfterDecrease = vars.totalCollateralInETH - vars.amountToDecreaseInETH;

    //if there is a borrow, there can't be 0 collateral
    if (vars.collateralBalanceAfterDecrease == 0) {
      return false;
    }

    vars.liquidationThresholdAfterDecrease = (vars.totalCollateralInETH * vars.avgLiquidationThreshold
      - vars.amountToDecreaseInETH * vars.liquidationThreshold)
      / vars.collateralBalanceAfterDecrease;

    uint256 healthFactorAfterDecrease =
      calculateHealthFactorFromBalances(
        vars.collateralBalanceAfterDecrease,
        vars.totalDebtInETH,
        vars.liquidationThresholdAfterDecrease
      );

    return healthFactorAfterDecrease >= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD;
  }

  struct CalculateUserAccountDataVars {
    uint256 reserveUnitPrice;
    uint256 tokenUnit;
    uint256 compoundedLiquidityBalance;
    uint256 compoundedBorrowBalance;
    uint256 decimals;
    uint256 ltv;
    uint256 liquidationThreshold;
    uint256 i;
    uint256 healthFactor;
    uint256 totalCollateralInETH;
    uint256 totalDebtInETH;
    uint256 avgLtv;
    uint256 avgLiquidationThreshold;
    uint256 reservesLength;
    bool healthFactorBelowThreshold;
    address currentReserveAddress;
    bool usageAsCollateralEnabled;
    bool userUsesReserveAsCollateral;
  }

  /**
   * @dev Calculates the user data across the reserves.
   * this includes the total liquidity/collateral/borrow balances in ETH,
   * the average Loan To Value, the average Liquidation Ratio, and the Health factor.
   * @param user The address of the user
   * @param reserves data of all the reserves
   * @param userConfig The configuration of the user
   * @param reserves The list of the available reserves
   * @param oracle The price oracle address
   * @return The total collateral and total debt of the user in ETH, the avg ltv, liquidation threshold and the HF
   **/
  function calculateUserAccountData(
    address user,
    DataTypes.PoolReservesData storage reserves,
    DataTypes.PoolNFTVaultsData storage nftVaults,
    DataTypes.UserConfigurationMap memory userConfig,
    address oracle
  )
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
    CalculateUserAccountDataVars memory vars;

    if (userConfig.isEmpty()) {
      return (0, 0, 0, 0, type(uint256).max);
    }
    for (vars.i = 0; vars.i < reserves.count; vars.i++) {
      if (!userConfig.isUsingAsCollateralOrBorrowing(vars.i)) {
        continue;
      }

      vars.currentReserveAddress = reserves.list[vars.i];
      DataTypes.ReserveData storage currentReserve = reserves.data[vars.currentReserveAddress];

      (vars.ltv, vars.liquidationThreshold, , vars.decimals, ) = currentReserve
        .configuration
        .getParams();

      vars.tokenUnit = 10**vars.decimals;
      vars.reserveUnitPrice = IPriceOracleGetter(oracle).getAssetPrice(vars.currentReserveAddress);

      if (vars.liquidationThreshold != 0 && userConfig.isUsingAsCollateral(vars.i)) {
        vars.compoundedLiquidityBalance = IERC20(currentReserve.vTokenAddress).balanceOf(user);

        uint256 liquidityBalanceETH =
          vars.reserveUnitPrice * vars.compoundedLiquidityBalance / vars.tokenUnit;

        vars.totalCollateralInETH = vars.totalCollateralInETH + liquidityBalanceETH;

        vars.avgLtv = vars.avgLtv + liquidityBalanceETH * vars.ltv;
        vars.avgLiquidationThreshold = vars.avgLiquidationThreshold
          + liquidityBalanceETH * vars.liquidationThreshold;
      }

      if (userConfig.isBorrowing(vars.i)) {
        vars.compoundedBorrowBalance = IERC20(currentReserve.variableDebtTokenAddress).balanceOf(user);

        vars.totalDebtInETH = vars.totalDebtInETH
          + vars.reserveUnitPrice * vars.compoundedBorrowBalance / vars.tokenUnit;
      }
    }

    for (vars.i = 0; vars.i < nftVaults.count; vars.i++) {
      if (!userConfig.isUsingNFTVaultAsCollateral(vars.i)) {
        continue;
      }

      vars.currentReserveAddress = nftVaults.list[vars.i];
      DataTypes.NFTVaultData storage currentVault = nftVaults.data[vars.currentReserveAddress];

      (vars.ltv, vars.liquidationThreshold, ) = currentVault
        .configuration
        .getParams();

      vars.reserveUnitPrice = IPriceOracleGetter(oracle).getAssetPrice(vars.currentReserveAddress);

      if (vars.liquidationThreshold != 0 && userConfig.isUsingNFTVaultAsCollateral(vars.i)) {
        vars.compoundedLiquidityBalance = IERC721WithStat(currentVault.nTokenAddress).balanceOf(user);

        uint256 liquidityBalanceETH =
          vars.reserveUnitPrice * vars.compoundedLiquidityBalance;

        vars.totalCollateralInETH = vars.totalCollateralInETH + liquidityBalanceETH;

        vars.avgLtv = vars.avgLtv + liquidityBalanceETH * vars.ltv;
        vars.avgLiquidationThreshold = vars.avgLiquidationThreshold
          + liquidityBalanceETH * vars.liquidationThreshold;
      }
    }

    vars.avgLtv = vars.totalCollateralInETH > 0 ? vars.avgLtv / vars.totalCollateralInETH : 0;
    vars.avgLiquidationThreshold = vars.totalCollateralInETH > 0
      ? vars.avgLiquidationThreshold / vars.totalCollateralInETH
      : 0;

    vars.healthFactor = calculateHealthFactorFromBalances(
      vars.totalCollateralInETH,
      vars.totalDebtInETH,
      vars.avgLiquidationThreshold
    );
    return (
      vars.totalCollateralInETH,
      vars.totalDebtInETH,
      vars.avgLtv,
      vars.avgLiquidationThreshold,
      vars.healthFactor
    );
  }

  /**
   * @dev Calculates the health factor from the corresponding balances
   * @param totalCollateralInETH The total collateral in ETH
   * @param totalDebtInETH The total debt in ETH
   * @param liquidationThreshold The avg liquidation threshold
   * @return The health factor calculated from the balances provided
   **/
  function calculateHealthFactorFromBalances(
    uint256 totalCollateralInETH,
    uint256 totalDebtInETH,
    uint256 liquidationThreshold
  ) internal pure returns (uint256) {
    if (totalDebtInETH == 0) return type(uint256).max;

    return (totalCollateralInETH.percentMul(liquidationThreshold)).wadDiv(totalDebtInETH);
  }

  /**
   * @dev Calculates the equivalent amount in ETH that an user can borrow, depending on the available collateral and the
   * average Loan To Value
   * @param totalCollateralInETH The total collateral in ETH
   * @param totalDebtInETH The total borrow balance
   * @param ltv The average loan to value
   * @return the amount available to borrow in ETH for the user
   **/

  function calculateAvailableBorrowsETH(
    uint256 totalCollateralInETH,
    uint256 totalDebtInETH,
    uint256 ltv
  ) internal pure returns (uint256) {
    uint256 availableBorrowsETH = totalCollateralInETH.percentMul(ltv);

    if (availableBorrowsETH < totalDebtInETH) {
      return 0;
    }

    availableBorrowsETH = availableBorrowsETH - totalDebtInETH;
    return availableBorrowsETH;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma abicoder v2;

import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {NFTVaultLogic} from './NFTVaultLogic.sol';
import {GenericLogic} from './GenericLogic.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {PercentageMath} from '../math/PercentageMath.sol';
import {GPv2SafeERC20} from '../../../dependencies/gnosis/contracts/GPv2SafeERC20.sol';
import {NFTVaultConfiguration} from '../configuration/NFTVaultConfiguration.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {UserConfiguration} from '../configuration/UserConfiguration.sol';
import {Errors} from '../helpers/Errors.sol';
import {Helpers} from '../helpers/Helpers.sol';
import {IReserveInterestRateStrategy} from '../../../interfaces/IReserveInterestRateStrategy.sol';
import {INFTXEligibility} from '../../../interfaces/INFTXEligibility.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title ReserveLogic library
 * @author Aave
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
  using ReserveLogic for DataTypes.ReserveData;
  using NFTVaultLogic for DataTypes.NFTVaultData;
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using GPv2SafeERC20 for IERC20;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  uint256 public constant REBALANCE_UP_LIQUIDITY_RATE_THRESHOLD = 4000;
  uint256 public constant REBALANCE_UP_USAGE_RATIO_THRESHOLD = 0.95 * 1e27; //usage ratio of 95%

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

  function validateDepositNFT(DataTypes.NFTVaultData storage vault, uint256[] memory ids, uint256[] memory amounts) external view {
    (bool isActive, bool isFrozen) = vault.configuration.getFlags();

    require(ids.length != 0, Errors.VL_INVALID_AMOUNT);
    for(uint256 i = 0; i < ids.length; ++i) {
      require(amounts[i] != 0, Errors.VL_INVALID_AMOUNT);
    }
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
    require(!isFrozen, Errors.VL_RESERVE_FROZEN);
    INFTXEligibility eligibility = INFTXEligibility(vault.nftEligibility);
    require(eligibility.checkAllEligible(ids), Errors.VL_NFT_INELIGIBLE_TOKEN_ID);
  }

  function validateLockNFT(DataTypes.NFTVaultData storage vault, uint40 now) external view {
    require(vault.expiration >= now, Errors.VL_NFT_LOCK_ACTION_IS_EXPIRED);
  }

  /**
   * @dev Validates a withdraw action
   * @param reserveAddress The address of the reserve
   * @param amount The amount to be withdrawn
   * @param userBalance The balance of the user
   * @param reserves The reserves state
   * @param userConfig The user configuration
   * @param oracle The price oracle
   */
  function validateWithdraw(
    address reserveAddress,
    uint256 amount,
    uint256 userBalance,
    DataTypes.PoolReservesData storage reserves,
    DataTypes.UserConfigurationMap storage userConfig,
    address oracle
  ) external view {
    require(amount != 0, Errors.VL_INVALID_AMOUNT);
    require(amount <= userBalance, Errors.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE);

    (bool isActive, , , ) = reserves.data[reserveAddress].configuration.getFlags();
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
  }

  /**
   * @dev Validates a withdraw action
   * @param vaultAddress The address of the vault
   * @param tokenIds The array of token ids of the NFTs to be withdrawn
   * @param amounts The array of amounts of the NFTs to be withdrawn
   * @param userBalances The array of balances of every NFT in `tokenIds` of the user
   * @param reserves The reserves state
   * @param nftVaults The vaults state
   * @param userConfig The user configuration
   * @param oracle The price oracle
   */
  function validateWithdrawNFT(
    address vaultAddress,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts,
    uint256[] calldata userBalances,
    DataTypes.PoolReservesData storage reserves,
    DataTypes.PoolNFTVaultsData storage nftVaults,
    DataTypes.UserConfigurationMap storage userConfig,
    address oracle
  ) external view {
    require(tokenIds.length == amounts.length, Errors.VL_INVALID_AMOUNT);
    uint256 amount;
    for(uint256 i = 0; i < tokenIds.length; ++i) {
      require(amounts[i] != 0, Errors.VL_INVALID_AMOUNT);
      require(amounts[i] <= userBalances[i], Errors.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE);
      amount = amount + amounts[i];
    }

    (bool isActive, ) = nftVaults.data[vaultAddress].configuration.getFlags();
    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);

    require(
      GenericLogic.balanceDecreaseAllowed(
        vaultAddress,
        msg.sender,
        amount,
        reserves,
        nftVaults,
        userConfig,
        oracle
      ),
      Errors.VL_TRANSFER_NOT_ALLOWED
    );
  }


  struct ValidateBorrowLocalVars {
    uint256 currentLtv;
    uint256 currentLiquidationThreshold;
    uint256 amountOfCollateralNeededETH;
    uint256 userCollateralBalanceETH;
    uint256 userBorrowBalanceETH;
    uint256 availableLiquidity;
    uint256 healthFactor;
    bool isActive;
    bool isFrozen;
    bool borrowingEnabled;
    //bool stableRateBorrowingEnabled;
  }

  /**
   * @dev Validates a borrow action
   * @param asset The address of the asset to borrow
   * @param reserve The reserve state from which the user is borrowing
   * @param userAddress The address of the user
   * @param amount The amount to be borrowed
   * @param amountInETH The amount to be borrowed, in ETH
   * @param interestRateMode The interest rate mode at which the user is borrowing
   * @param maxStableLoanPercent The max amount of the liquidity that can be borrowed at stable rate, in percentage
   * @param reserves The reserves state
   * @param nftVaults The vaults state
   * @param userConfig The user configuration
   * @param oracle The price oracle
   */
  function validateBorrow(
    address asset,
    DataTypes.ReserveData storage reserve,
    address userAddress,
    uint256 amount,
    uint256 amountInETH,
    uint256 interestRateMode,
    uint256 maxStableLoanPercent,
    DataTypes.PoolReservesData storage reserves,
    DataTypes.PoolNFTVaultsData storage nftVaults,
    DataTypes.UserConfigurationMap storage userConfig,
    address oracle
  ) external view {
    ValidateBorrowLocalVars memory vars;

    (vars.isActive, vars.isFrozen, vars.borrowingEnabled, ) = reserve
      .configuration
      .getFlags();

    require(vars.isActive, Errors.VL_NO_ACTIVE_RESERVE);
    require(!vars.isFrozen, Errors.VL_RESERVE_FROZEN);
    require(amount != 0, Errors.VL_INVALID_AMOUNT);

    require(vars.borrowingEnabled, Errors.VL_BORROWING_NOT_ENABLED);

    //validate interest rate mode
    require(
      uint256(DataTypes.InterestRateMode.VARIABLE) == interestRateMode,
      Errors.VL_INVALID_INTEREST_RATE_MODE_SELECTED
    );

    (
      vars.userCollateralBalanceETH,
      vars.userBorrowBalanceETH,
      vars.currentLtv,
      vars.currentLiquidationThreshold,
      vars.healthFactor
    ) = GenericLogic.calculateUserAccountData(
      userAddress,
      reserves,
      nftVaults,
      userConfig,
      oracle
    );

    require(vars.userCollateralBalanceETH > 0, Errors.VL_COLLATERAL_BALANCE_IS_0);

    require(
      vars.healthFactor > GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
    );

    //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
    vars.amountOfCollateralNeededETH = (vars.userBorrowBalanceETH + amountInETH).percentDiv(
      vars.currentLtv
    ); //LTV is calculated in percentage

    require(
      vars.amountOfCollateralNeededETH <= vars.userCollateralBalanceETH,
      Errors.VL_COLLATERAL_CANNOT_COVER_NEW_BORROW
    );

  }

  /**
   * @dev Validates a repay action
   * @param reserve The reserve state from which the user is repaying
   * @param amountSent The amount sent for the repayment. Can be an actual value or uint(-1)
   * @param onBehalfOf The address of the user msg.sender is repaying for
   * @param stableDebt The borrow balance of the user
   * @param variableDebt The borrow balance of the user
   */
  function validateRepay(
    DataTypes.ReserveData storage reserve,
    uint256 amountSent,
    DataTypes.InterestRateMode rateMode,
    address onBehalfOf,
    uint256 stableDebt,
    uint256 variableDebt
  ) external view {
    bool isActive = reserve.configuration.getActive();

    require(isActive, Errors.VL_NO_ACTIVE_RESERVE);

    require(amountSent > 0, Errors.VL_INVALID_AMOUNT);

    require(
        (variableDebt > 0 &&
          DataTypes.InterestRateMode(rateMode) == DataTypes.InterestRateMode.VARIABLE),
      Errors.VL_NO_DEBT_OF_SELECTED_TYPE
    );

    require(
      amountSent != type(uint256).max || msg.sender == onBehalfOf,
      Errors.VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF
    );
  }

    /**
   * @dev Validates a nft-flashloan action
   * @param asset The asset being flashborrowed
   * @param tokenIds The tokenIds for each NFT being borrowed
   * @param amounts The amounts for each NFT being borrowed
   * @param userBalances The amounts for each NFT in the vault
   **/
  function validateNFTFlashloan(address asset, uint256[] memory tokenIds, uint256[] memory amounts, uint256[] memory userBalances) internal pure {
    require(tokenIds.length == amounts.length, Errors.VL_INCONSISTENT_FLASHLOAN_PARAMS);
    for(uint256 i = 0; i < tokenIds.length; ++i) {
      require(amounts[i] != 0, Errors.VL_INVALID_AMOUNT);
      require(amounts[i] <= userBalances[i], Errors.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE);
    }
  }

  /**
   * @dev Validates the liquidation action
   * @param collateralVault The vault data of the collateral
   * @param principalReserve The reserve data of the principal
   * @param userConfig The user configuration
   * @param userHealthFactor The user's health factor
   * @param userStableDebt Total stable debt balance of the user
   * @param userVariableDebt Total variable debt balance of the user
   **/
  function validateNFTLiquidationCall(
    DataTypes.NFTVaultData storage collateralVault,
    DataTypes.ReserveData storage principalReserve,
    DataTypes.UserConfigurationMap storage userConfig,
    uint256 userHealthFactor,
    uint256 userStableDebt,
    uint256 userVariableDebt
  ) internal view returns (uint256, string memory) {
    if (
      !collateralVault.configuration.getActive() || !principalReserve.configuration.getActive()
    ) {
      return (
        uint256(Errors.CollateralManagerErrors.NO_ACTIVE_RESERVE),
        Errors.VL_NO_ACTIVE_RESERVE
      );
    }

    if (userHealthFactor >= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD) {
      return (
        uint256(Errors.CollateralManagerErrors.HEALTH_FACTOR_ABOVE_THRESHOLD),
        Errors.LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD
      );
    }

    bool isCollateralEnabled =
      collateralVault.configuration.getLiquidationThreshold() > 0 &&
        userConfig.isUsingNFTVaultAsCollateral(collateralVault.id);

    //if collateral isn't enabled as collateral by user, it cannot be liquidated
    if (!isCollateralEnabled) {
      return (
        uint256(Errors.CollateralManagerErrors.COLLATERAL_CANNOT_BE_LIQUIDATED),
        Errors.LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED
      );
    }

    if (userVariableDebt == 0) {
      return (
        uint256(Errors.CollateralManagerErrors.CURRRENCY_NOT_BORROWED),
        Errors.LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER
      );
    }

    return (uint256(Errors.CollateralManagerErrors.NO_ERROR), Errors.LPCM_NO_ERRORS);
  }

  /**
   * @dev Validates a vToken transfer or an nToken transfer
   * @param from The user from which the vTokens/nTokens are being transferred
   * @param reserves The state of all the reserves
   * @param nftVaults The state of all the NFT vaults
   * @param userConfig The state of the user for the specific reserve
   * @param oracle The price oracle
   */
  function validateTransfer(
    address from,
    DataTypes.PoolReservesData storage reserves,
    DataTypes.PoolNFTVaultsData storage nftVaults,
    DataTypes.UserConfigurationMap storage userConfig,
    address oracle
  ) internal view {
    (, , , , uint256 healthFactor) =
      GenericLogic.calculateUserAccountData(
        from,
        reserves,
        nftVaults,
        userConfig,
        oracle
      );

    require(
      healthFactor >= GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
      Errors.VL_TRANSFER_NOT_ALLOWED
    );
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title ReserveConfiguration library
 * @author Aave
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
pragma solidity 0.8.11;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title NFTVaultConfiguration library
 * @author Vinci
 * @notice Implements the bitmap logic to handle the NFT vault configuration
 */
library NFTVaultConfiguration {
  uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  // uint256 constant DECIMALS_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
  uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  // uint256 constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  // uint256 constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
  // uint256 constant RESERVE_FACTOR_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  // uint256 constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
  // uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  // uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
  // uint256 constant RESERVE_FACTOR_START_BIT_POSITION = 64;

  uint256 constant MAX_VALID_LTV = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  // uint256 constant MAX_VALID_DECIMALS = 255;
  // uint256 constant MAX_VALID_RESERVE_FACTOR = 65535;

  /**
   * @dev Sets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @param ltv the new ltv
   **/
  function setLtv(DataTypes.NFTVaultConfigurationMap memory self, uint256 ltv) internal pure {
    require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

    self.data = (self.data & LTV_MASK) | ltv;
  }

  /**
   * @dev Gets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @return The loan to value
   **/
  function getLtv(DataTypes.NFTVaultConfigurationMap storage self) internal view returns (uint256) {
    return self.data & ~LTV_MASK;
  }

  /**
   * @dev Sets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @param threshold The new liquidation threshold
   **/
  function setLiquidationThreshold(DataTypes.NFTVaultConfigurationMap memory self, uint256 threshold)
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
  function getLiquidationThreshold(DataTypes.NFTVaultConfigurationMap storage self)
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
  function setLiquidationBonus(DataTypes.NFTVaultConfigurationMap memory self, uint256 bonus)
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
  function getLiquidationBonus(DataTypes.NFTVaultConfigurationMap storage self)
    internal
    view
    returns (uint256)
  {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @dev Sets the active state of the reserve
   * @param self The reserve configuration
   * @param active The active state
   **/
  function setActive(DataTypes.NFTVaultConfigurationMap memory self, bool active) internal pure {
    self.data =
      (self.data & ACTIVE_MASK) |
      (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the active state of the reserve
   * @param self The reserve configuration
   * @return The active state
   **/
  function getActive(DataTypes.NFTVaultConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~ACTIVE_MASK) != 0;
  }

  /**
   * @dev Sets the frozen state of the reserve
   * @param self The reserve configuration
   * @param frozen The frozen state
   **/
  function setFrozen(DataTypes.NFTVaultConfigurationMap memory self, bool frozen) internal pure {
    self.data =
      (self.data & FROZEN_MASK) |
      (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  /**
   * @dev Gets the frozen state of the reserve
   * @param self The reserve configuration
   * @return The frozen state
   **/
  function getFrozen(DataTypes.NFTVaultConfigurationMap storage self) internal view returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

   /**
   * @dev Gets the configuration flags of the reserve
   * @param self The reserve configuration
   * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
   **/
  function getFlags(DataTypes.NFTVaultConfigurationMap storage self)
    internal
    view
    returns (
      bool,
      bool
    )
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~ACTIVE_MASK) != 0,
      (dataLocal & ~FROZEN_MASK) != 0
    );
  }

  /**
   * @dev Gets the configuration paramters of the reserve
   * @param self The reserve configuration
   * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
   **/
  function getParams(DataTypes.NFTVaultConfigurationMap storage self)
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
   * @dev Gets the configuration paramters of the reserve from a memory object
   * @param self The reserve configuration
   * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
   **/
  function getParamsMemory(DataTypes.NFTVaultConfigurationMap memory self)
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
   * @dev Gets the configuration flags of the reserve from a memory object
   * @param self The reserve configuration
   * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
   **/
  function getFlagsMemory(DataTypes.NFTVaultConfigurationMap memory self)
    internal
    pure
    returns (
      bool,
      bool
    )
  {
    return (
      (self.data & ~ACTIVE_MASK) != 0,
      (self.data & ~FROZEN_MASK) != 0
    );
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title UserConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserConfiguration {
  uint256 internal constant BORROWING_MASK =
    0x5555555555555555555555555555555555555555555555555555555555555555;

  /**
   * @dev Sets if the user is borrowing the reserve identified by reserveIndex
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @param borrowing True if the user is borrowing the reserve, false otherwise
   **/
  function setBorrowing(
    DataTypes.UserConfigurationMap storage self,
    uint256 reserveIndex,
    bool borrowing
  ) internal {
    require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
    self.data =
      (self.data & ~(1 << (reserveIndex * 2))) |
      (uint256(borrowing ? 1 : 0) << (reserveIndex * 2));
  }

  /**
   * @dev Sets if the user is using as collateral the reserve identified by reserveIndex
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @param usingAsCollateral True if the user is usin the reserve as collateral, false otherwise
   **/
  function setUsingAsCollateral(
    DataTypes.UserConfigurationMap storage self,
    uint256 reserveIndex,
    bool usingAsCollateral
  ) internal {
    require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
    self.data =
      (self.data & ~(1 << (reserveIndex * 2 + 1))) |
      (uint256(usingAsCollateral ? 1 : 0) << (reserveIndex * 2 + 1));
  }

  /**
   * @dev Sets if the user is using as collateral the nft vault identified by vaultIndex
   * @param self The configuration object
   * @param vaultIndex The index of the nft vault in the bitmap
   * @param usingAsCollateral True if the user is usin the nft vault as collateral, false otherwise
   **/
  function setUsingNFTVaultAsCollateral(
    DataTypes.UserConfigurationMap storage self,
    uint256 vaultIndex,
    bool usingAsCollateral
  ) internal {
    require(vaultIndex < 256, Errors.UL_INVALID_INDEX);
    self.nData =
      (self.nData & ~(1 << vaultIndex)) |
      (uint256(usingAsCollateral ? 1 : 0) << vaultIndex);
  }

  /**
   * @dev Used to validate if a user has been using the reserve for borrowing or as collateral
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve for borrowing or as collateral, false otherwise
   **/
  function isUsingAsCollateralOrBorrowing(
    DataTypes.UserConfigurationMap memory self,
    uint256 reserveIndex
  ) internal pure returns (bool) {
    require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
    return (self.data >> (reserveIndex * 2)) & 3 != 0;
  }

  /**
   * @dev Used to validate if a user has been using the reserve for borrowing
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve for borrowing, false otherwise
   **/
  function isBorrowing(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
    internal
    pure
    returns (bool)
  {
    require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
    return (self.data >> (reserveIndex * 2)) & 1 != 0;
  }

  /**
   * @dev Used to validate if a user has been using the reserve as collateral
   * @param self The configuration object
   * @param reserveIndex The index of the reserve in the bitmap
   * @return True if the user has been using a reserve as collateral, false otherwise
   **/
  function isUsingAsCollateral(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
    internal
    pure
    returns (bool)
  {
    require(reserveIndex < 128, Errors.UL_INVALID_INDEX);
    return (self.data >> (reserveIndex * 2 + 1)) & 1 != 0;
  }

  /**
   * @dev Used to validate if a user has been using the nft vault as collateral
   * @param self The configuration object
   * @param vaultIndex The index of the nft vault in the bitmap
   * @return True if the user has been using a nft vault as collateral, false otherwise
   **/
  function isUsingNFTVaultAsCollateral(DataTypes.UserConfigurationMap memory self, uint256 vaultIndex)
    internal
    pure
    returns (bool)
  {
    require(vaultIndex < 256, Errors.UL_INVALID_INDEX);
    return (self.nData >> vaultIndex) & 1 != 0;
  }

  /**
   * @dev Used to validate if a user has been borrowing from any reserve
   * @param self The configuration object
   * @return True if the user has been borrowing any reserve, false otherwise
   **/
  function isBorrowingAny(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
    return self.data & BORROWING_MASK != 0;
  }

  /**
   * @dev Used to validate if a user has not been using any reserve
   * @param self The configuration object
   * @return True if the user has been borrowing any reserve, false otherwise
   **/
  function isEmpty(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
    return self.data == 0 && self.nData == 0;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

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
    address vTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct NFTVaultData {
    NFTVaultConfigurationMap configuration;
    address nTokenAddress;
    address nftEligibility;
    uint32 id;
    uint40 expiration;
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

  struct NFTVaultConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. thresold
    //bit 32-47: Liq. bonus
    //bit 48-55: reserved
    //bit 56: Vault is active
    //bit 57: Vault is frozen
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
    uint256 nData;
  }

  struct PoolReservesData {
    uint256 count;
    mapping(address => ReserveData) data;
    mapping(uint256 => address) list;
  }

  struct PoolNFTVaultsData {
    uint256 count;
    mapping(address => NFTVaultData) data;
    mapping(uint256 => address) list;
  }

  struct TimeLock {
    uint40 expiration;
    uint16 lockType;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {UserConfiguration} from '../libraries/configuration/UserConfiguration.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {NFTVaultConfiguration} from '../libraries/configuration/NFTVaultConfiguration.sol';
import {ReserveLogic} from '../libraries/logic/ReserveLogic.sol';
import {NFTVaultLogic} from '../libraries/logic/NFTVaultLogic.sol';
import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';
import {INFTXEligibility} from '../../interfaces/INFTXEligibility.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';

contract LendingPoolStorage {
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NFTVaultLogic for DataTypes.NFTVaultData;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  ILendingPoolAddressesProvider internal _addressesProvider;
  INFTXEligibility internal _nftEligibility;

  DataTypes.PoolReservesData internal _reserves;
  DataTypes.PoolNFTVaultsData internal _nftVaults;

  mapping(address => DataTypes.UserConfigurationMap) internal _usersConfig;

  bool internal _paused;

  uint256 internal _maxStableRateBorrowSizePercent;

  uint256 internal _flashLoanPremiumTotal;

  uint256 internal _maxNumberOfReserves;
  uint256 internal _maxNumberOfNFTVaults;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
pragma solidity 0.8.11;

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {ILendingPool} from './ILendingPool.sol';
import {IAaveIncentivesController} from './IAaveIncentivesController.sol';

/**
 * @title IInitializableVToken
 * @notice Interface for the initialize function on VToken
 * @author Aave
 **/
interface IInitializableVToken {
  /**
   * @dev Emitted when an vToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this vToken
   * @param vTokenDecimals the decimals of the underlying
   * @param vTokenName the name of the vToken
   * @param vTokenSymbol the symbol of the vToken
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController,
    uint8 vTokenDecimals,
    string vTokenName,
    string vTokenSymbol,
    bytes params
  );

  /**
   * @dev Initializes the vToken
   * @param pool The address of the lending pool where this vToken will be used
   * @param treasury The address of the Aave treasury, receiving the fees on this vToken
   * @param underlyingAsset The address of the underlying asset of this vToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param vTokenDecimals The decimals of the vToken, same as the underlying asset's
   * @param vTokenName The name of the vToken
   * @param vTokenSymbol The symbol of the vToken
   */
  function initialize(
    ILendingPool pool,
    address treasury,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 vTokenDecimals,
    string calldata vTokenName,
    string calldata vTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

interface IAaveIncentivesController {
  event RewardsAccrued(address indexed user, uint256 amount);

  event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

  event RewardsClaimed(
    address indexed user,
    address indexed to,
    address indexed claimer,
    uint256 amount
  );

  event ClaimerSet(address indexed user, address indexed claimer);

  /*
   * @dev Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index, the emission per second and the last updated timestamp
   **/
  function getAssetData(address asset)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  /*
   * LEGACY **************************
   * @dev Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index, the emission per second and the last updated timestamp
   **/
  function assets(address asset)
    external
    view
    returns (
      uint128,
      uint128,
      uint256
    );

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
   * @param assetsToConfig The assets to incentivize
   * @param emissionsPerSecond The emission for each asset
   */
  function configureAssets(address[] calldata assetsToConfig, uint256[] calldata emissionsPerSecond)
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
  function getRewardsBalance(address[] calldata assetsToCheck, address user)
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
    address[] calldata assetsToClaim,
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
    address[] calldata assetsToClaim,
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
   * @dev returns the unclaimed rewards of the user
   * @param user the address of the user
   * @param asset The asset to incentivize
   * @return the user index for the asset
   */
  function getUserAssetData(address user, address asset) external view returns (uint256);

  /**
   * @dev for backward compatibility with previous implementation of the Incentives controller
   */
  function REWARD_TOKEN() external view returns (address);

  /**
   * @dev for backward compatibility with previous implementation of the Incentives controller
   */
  function PRECISION() external view returns (uint8);

  /**
   * @dev Gets the distribution end timestamp of the emissions
   */
  function DISTRIBUTION_END() external view returns (uint256);
}

pragma solidity 0.8.11;

import {IERC721} from '../dependencies/openzeppelin/contracts/IERC721.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

interface ITimeLockableERC721 is IERC721 {
  event TimeLocked(
    uint256 indexed tokenid,
    uint256 indexed lockType,
    uint40 indexed expirationTime
  );

  function lock(uint256 tokenid, uint16 lockType) external;

  function getUnlockTime(uint256 tokenId) external view returns(uint40 unlockTime);

  function getLockData(uint256 tokenId) external view returns(DataTypes.TimeLock memory lock);

  function unlockedBalanceOfBatch(address user, uint256[] memory tokenIds) external view returns(uint256[] memory amounts);

  function tokensAndLocksByAccount(address user) external view returns(uint256[] memory tokenIds, DataTypes.TimeLock[] memory locks);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {ILendingPool} from './ILendingPool.sol';

/**
 * @title IInitializableVToken
 * @notice Interface for the initialize function on NToken
 * @author Aave
 **/
interface IInitializableNToken {
  /**
   * @dev Emitted when an vToken is initialized
   * @param underlyingAsset The address of the underlying NFT asset
   * @param pool The address of the associated lending pool
   * @param nTokenName the name of the NToken
   * @param nTokenSymbol the symbol of the NToken
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    string nTokenName,
    string nTokenSymbol,
    string baseURI,
    bytes params
  );

  /**
   * @dev Initializes the nToken
   * @param pool The address of the lending pool where this nToken will be used
   * @param underlyingAsset The address of the underlying asset of this nToken
   * @param nTokenName The name of the nToken
   * @param nTokenSymbol The symbol of the nToken
   */
  function initialize(
    ILendingPool pool,
    address underlyingAsset,
    string calldata nTokenName,
    string calldata nTokenSymbol,
    string calldata baseURI,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

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
pragma solidity 0.8.11;

import {ILendingPool} from './ILendingPool.sol';
import {IAaveIncentivesController} from './IAaveIncentivesController.sol';

/**
 * @title IInitializableDebtToken
 * @notice Interface for the initialize function common between debt tokens
 * @author Aave
 **/
interface IInitializableDebtToken {
  /**
   * @dev Emitted when a debt token is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param incentivesController The address of the incentives controller for this vToken
   * @param debtTokenDecimals the decimals of the debt token
   * @param debtTokenName the name of the debt token
   * @param debtTokenSymbol the symbol of the debt token
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address incentivesController,
    uint8 debtTokenDecimals,
    string debtTokenName,
    string debtTokenSymbol,
    bytes params
  );

  /**
   * @dev Initializes the debt token.
   * @param pool The address of the lending pool where this vToken will be used
   * @param underlyingAsset The address of the underlying asset of this vToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
   * @param debtTokenName The name of the token
   * @param debtTokenSymbol The symbol of the token
   */
  function initialize(
    ILendingPool pool,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

/**
 * @title IReserveInterestRateStrategyInterface interface
 * @dev Interface for the calculation of the interest rates
 * @author Aave
 */
interface IReserveInterestRateStrategy {
  function baseVariableBorrowRate() external view returns (uint256);

  function getMaxVariableBorrowRate() external view returns (uint256);

  function calculateInterestRates(
    address reserve,
    uint256 availableLiquidity,
    uint256 totalStableDebt,
    uint256 totalVariableDebt,
    uint256 averageStableBorrowRate,
    uint256 reserveFactor
  )
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function calculateInterestRates(
    address reserve,
    address vToken,
    uint256 liquidityAdded,
    uint256 liquidityTaken,
    uint256 totalStableDebt,
    uint256 totalVariableDebt,
    uint256 averageStableBorrowRate,
    uint256 reserveFactor
  )
    external
    view
    returns (
      uint256 liquidityRate,
      uint256 stableBorrowRate,
      uint256 variableBorrowRate
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {WadRayMath} from './WadRayMath.sol';

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

  function calculateLinearInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    //solium-disable-next-line
    uint256 timeDifference = block.timestamp - uint256(lastUpdateTimestamp);

    return (rate * timeDifference / SECONDS_PER_YEAR + WadRayMath.ray());
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
    uint256 exp = currentTimestamp - uint256(lastUpdateTimestamp);

    if (exp == 0) {
      return WadRayMath.ray();
    }

    uint256 expMinusOne = exp - 1;

    uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

    uint256 ratePerSecond = rate / SECONDS_PER_YEAR;

    uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
    uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

    uint256 secondTerm = exp * expMinusOne * basePowerTwo/ 2;
    uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree / 6;

    return WadRayMath.ray() + ratePerSecond * exp + secondTerm + thirdTerm;
  }

  /**
   * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
   * @param rate The interest rate (in ray)
   * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
   **/
  function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import './BaseImmutableAdminUpgradeabilityProxy.sol';
import '../../../dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol';

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends BaseAdminUpgradeabilityProxy with an initializer function
 */
contract InitializableImmutableAdminUpgradeabilityProxy is
  BaseImmutableAdminUpgradeabilityProxy,
  InitializableUpgradeabilityProxy
{
  constructor(address admin) public BaseImmutableAdminUpgradeabilityProxy(admin) {}

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal override(BaseImmutableAdminUpgradeabilityProxy, Proxy) {
    BaseImmutableAdminUpgradeabilityProxy._willFallback();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
pragma solidity 0.8.11;

import '../../../dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol';

/**
 * @title BaseImmutableAdminUpgradeabilityProxy
 * @author Aave, inspired by the OpenZeppelin upgradeability proxy pattern
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks. The admin role is stored in an immutable, which
 * helps saving transactions costs
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  address immutable ADMIN;

  constructor(address admin) public {
    ADMIN = admin;
  }

  modifier ifAdmin() {
    if (msg.sender == ADMIN) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return ADMIN;
  }

  /**
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data)
    external
    payable
    ifAdmin
  {
    _upgradeTo(newImplementation);
    (bool success, ) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal virtual override {
    require(msg.sender != ADMIN, 'Cannot call fallback function from the proxy admin');
    super._willFallback();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if (_data.length > 0) {
      (bool success, ) = _logic.delegatecall(_data);
      require(success);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import './Proxy.sol';
import '../contracts/Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal view override returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    //solium-disable-next-line
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(
      Address.isContract(newImplementation),
      'Cannot set a proxy implementation to a non-contract address'
    );

    bytes32 slot = IMPLEMENTATION_SLOT;

    //solium-disable-next-line
    assembly {
      sstore(slot, newImplementation)
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Will run if no other function in the contract matches the call data.
   * Implemented entirely in `_fallback`.
   */
  fallback() external payable {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view virtual returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    //solium-disable-next-line
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
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal virtual {}

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

interface ILendingPoolConfigurator {
  struct InitReserveInput {
    address vTokenImpl;
    address stableDebtTokenImpl;
    address variableDebtTokenImpl;
    uint8 underlyingAssetDecimals;
    address interestRateStrategyAddress;
    address underlyingAsset;
    address treasury;
    address incentivesController;
    string underlyingAssetName;
    string vTokenName;
    string vTokenSymbol;
    string variableDebtTokenName;
    string variableDebtTokenSymbol;
    string stableDebtTokenName;
    string stableDebtTokenSymbol;
    bytes params;
  }

  struct InitNFTVaultInput {
    address nTokenImpl;
    address underlyingAsset;
    address nftEligibility;
    string underlyingAssetName;
    string nTokenName;
    string nTokenSymbol;
    bytes params;
    string baseURI;
  }

  struct UpdateVTokenInput {
    address asset;
    address treasury;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  struct UpdateDebtTokenInput {
    address asset;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  struct UpdateNTokenInput {
    address asset;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param vToken The address of the associated vToken contract
   * @param stableDebtToken The address of the associated stable rate debt token
   * @param variableDebtToken The address of the associated variable rate debt token
   * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
   **/
  event ReserveInitialized(
    address indexed asset,
    address indexed vToken,
    address stableDebtToken,
    address variableDebtToken,
    address interestRateStrategyAddress
  );

  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the NFTVault
   * @param nToken The address of the associated nToken contract
   **/
  event NFTVaultInitialized(
    address indexed asset,
    address indexed nToken
  );

  /**
   * @dev Emitted when borrowing is enabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param stableRateEnabled True if stable rate borrowing is enabled, false otherwise
   **/
  event BorrowingEnabledOnReserve(address indexed asset, bool stableRateEnabled);

  /**
   * @dev Emitted when borrowing is disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event BorrowingDisabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
   * @param asset The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as collateral
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset
   **/
  event CollateralConfigurationChanged(
    address indexed asset,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  );

  /**
   * @dev Emitted when stable rate borrowing is enabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event StableRateEnabledOnReserve(address indexed asset);

  /**
   * @dev Emitted when stable rate borrowing is disabled on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  event StableRateDisabledOnReserve(address indexed asset);

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
   * @dev Emitted when a reserve is activated
   * @param asset The address of the underlying asset of the reserve
   **/
  event NFTVaultActivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is deactivated
   * @param asset The address of the underlying asset of the reserve
   **/
  event NFTVaultDeactivated(address indexed asset);

  /**
   * @dev Emitted when a reserve is frozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event NFTVaultFrozen(address indexed asset);

  /**
   * @dev Emitted when a reserve is unfrozen
   * @param asset The address of the underlying asset of the reserve
   **/
  event NFTVaultUnfrozen(address indexed asset);

  event NFTVaultActionExpirationUpdated(address indexed asset, uint40 expiration);

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
  event ReserveInterestRateStrategyChanged(address indexed asset, address strategy);

  /**
   * @dev Emitted when an vToken implementation is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The vToken proxy address
   * @param implementation The new vToken implementation
   **/
  event VTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a stable debt token is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The stable debt token proxy address
   * @param implementation The new vToken implementation
   **/
  event StableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when the implementation of a variable debt token is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The variable debt token proxy address
   * @param implementation The new vToken implementation
   **/
  event VariableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  /**
   * @dev Emitted when an nToken implementation is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The vToken proxy address
   * @param implementation The new vToken implementation
   **/
  event NTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import {Context} from '../../dependencies/openzeppelin/contracts/Context.sol';
import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Metadata} from '../../dependencies/openzeppelin/contracts/IERC20Metadata.sol';
import {SafeMath} from '../../dependencies/openzeppelin/contracts/SafeMath.sol';
import {IAaveIncentivesController} from '../../interfaces/IAaveIncentivesController.sol';

/**
 * @title ERC20
 * @notice Basic ERC20 implementation
 * @author Aave, inspired by the Openzeppelin ERC20 implementation
 **/
abstract contract IncentivizedERC20 is Context, IERC20, IERC20Metadata {
  using SafeMath for uint256;

  mapping(address => uint256) internal _balances;

  mapping(address => mapping(address => uint256)) private _allowances;
  uint256 internal _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
  }

  /**
   * @return The name of the token
   **/
  function name() public view override returns (string memory) {
    return _name;
  }

  /**
   * @return The symbol of the token
   **/
  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  /**
   * @return The decimals of the token
   **/
  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  /**
   * @return The total supply of the token
   **/
  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @return The balance of the token
   **/
  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @return Abstract function implemented by the child vToken/debtToken. 
   * Done this way in order to not break compatibility with previous versions of vTokens/debtTokens
   **/
  function _getIncentivesController() internal view virtual returns(IAaveIncentivesController);

  /**
   * @dev Executes a transfer of tokens from _msgSender() to recipient
   * @param recipient The recipient of the tokens
   * @param amount The amount of tokens being transferred
   * @return `true` if the transfer succeeds, `false` otherwise
   **/
  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    emit Transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev Returns the allowance of spender on the tokens owned by owner
   * @param owner The owner of the tokens
   * @param spender The user allowed to spend the owner's tokens
   * @return The amount of owner's tokens spender is allowed to spend
   **/
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  /**
   * @dev Allows `spender` to spend the tokens owned by _msgSender()
   * @param spender The user allowed to spend _msgSender() tokens
   * @return `true`
   **/
  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev Executes a transfer of token from sender to recipient, if _msgSender() is allowed to do so
   * @param sender The owner of the tokens
   * @param recipient The recipient of the tokens
   * @param amount The amount of tokens being transferred
   * @return `true` if the transfer succeeds, `false` otherwise
   **/
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
    );
    emit Transfer(sender, recipient, amount);
    return true;
  }

  /**
   * @dev Increases the allowance of spender to spend _msgSender() tokens
   * @param spender The user allowed to spend on behalf of _msgSender()
   * @param addedValue The amount being added to the allowance
   * @return `true`
   **/
  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  /**
   * @dev Decreases the allowance of spender to spend _msgSender() tokens
   * @param spender The user allowed to spend on behalf of _msgSender()
   * @param subtractedValue The amount being subtracted to the allowance
   * @return `true`
   **/
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    uint256 oldSenderBalance = _balances[sender];
    _balances[sender] = oldSenderBalance.sub(amount, 'ERC20: transfer amount exceeds balance');
    uint256 oldRecipientBalance = _balances[recipient];
    _balances[recipient] = oldRecipientBalance + amount;

    if (address(_getIncentivesController()) != address(0)) {
      uint256 currentTotalSupply = _totalSupply;
      _getIncentivesController().handleAction(sender, currentTotalSupply, oldSenderBalance);
      if (sender != recipient) {
        _getIncentivesController().handleAction(recipient, currentTotalSupply, oldRecipientBalance);
      }
    }
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    uint256 oldTotalSupply = _totalSupply;
    _totalSupply = oldTotalSupply + amount;

    uint256 oldAccountBalance = _balances[account];
    _balances[account] = oldAccountBalance + amount;

    if (address(_getIncentivesController()) != address(0)) {
      _getIncentivesController().handleAction(account, oldTotalSupply, oldAccountBalance);
    }
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    uint256 oldTotalSupply = _totalSupply;
    _totalSupply = oldTotalSupply - amount;

    uint256 oldAccountBalance = _balances[account];
    _balances[account] = oldAccountBalance.sub(amount, 'ERC20: burn amount exceeds balance');

    if (address(_getIncentivesController()) != address(0)) {
      _getIncentivesController().handleAction(account, oldTotalSupply, oldAccountBalance);
    }
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setName(string memory newName) internal {
    _name = newName;
  }

  function _setSymbol(string memory newSymbol) internal {
    _symbol = newSymbol;
  }

  function _setDecimals(uint8 newDecimals) internal {
    _decimals = newDecimals;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

/**
 * @title ILendingRateOracle interface
 * @notice Interface for the Aave borrow rate oracle. Provides the average market borrow rate to be used as a base for the stable borrow rate calculations
 **/

interface ILendingRateOracle {
  /**
    @dev returns the market borrow rate in ray
    **/
  function getMarketBorrowRate(address asset) external view returns (uint256);

  /**
    @dev sets the market borrow rate. Rate value must be in ray
    **/
  function setMarketBorrowRate(address asset, uint256 rate) external;
}