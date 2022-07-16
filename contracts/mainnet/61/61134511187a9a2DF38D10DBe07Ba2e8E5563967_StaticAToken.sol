// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import {ILendingPool} from '../../interfaces/external/aave/ILendingPool.sol';
import {IERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IAToken} from '../../interfaces/external/aave/IAToken.sol';
import {ERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "../../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {WadRayMath} from './WadRayMath.sol';
import {TokenUtils} from "../../libraries/TokenUtils.sol";

/**
 * @title StaticAToken
 * @dev Wrapper token that allows to deposit tokens on the Aave protocol and receive
 * a token which balance doesn't increase automatically, but uses an ever-increasing exchange rate
 * - Only supporting deposits and withdrawals
 * @author Aave
 **/
contract StaticAToken is ERC20 {
  using SafeERC20 for IERC20;
  using WadRayMath for uint256;

  struct SignatureParams {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  bytes public constant EIP712_REVISION = bytes('1');
  bytes32 internal constant EIP712_DOMAIN =
    keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)');
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
  bytes32 public constant METADEPOSIT_TYPEHASH =
    keccak256(
      'Deposit(address depositor,address recipient,uint256 value,uint16 referralCode,bool fromUnderlying,uint256 nonce,uint256 deadline)'
    );
  bytes32 public constant METAWITHDRAWAL_TYPEHASH =
    keccak256(
      'Withdraw(address owner,address recipient,uint256 staticAmount, uint256 dynamicAmount, bool toUnderlying, uint256 nonce,uint256 deadline)'
    );

  ILendingPool public immutable LENDING_POOL;
  IERC20 public immutable ATOKEN;
  IERC20 public immutable ASSET;

  /// @dev owner => next valid nonce to submit with permit(), metaDeposit() and metaWithdraw()
  /// We choose to have sequentiality on them for each user to avoid potentially dangerous/bad UX cases
  mapping(address => uint256) public _nonces;

  uint8 private _decimals;

  constructor(
    ILendingPool lendingPool,
    address aToken,
    string memory wrappedTokenName,
    string memory wrappedTokenSymbol
  ) public ERC20(wrappedTokenName, wrappedTokenSymbol) {
    LENDING_POOL = lendingPool;
    ATOKEN = IERC20(aToken);

    IERC20 underlyingAsset = IERC20(IAToken(aToken).UNDERLYING_ASSET_ADDRESS());
    ASSET = underlyingAsset;
    TokenUtils.safeApprove(address(underlyingAsset), address(lendingPool), type(uint256).max);
    _decimals = IERC20Metadata(aToken).decimals();
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Deposits `ASSET` in the Aave protocol and mints static aTokens to msg.sender
   * @param recipient The address that will receive the static aTokens
   * @param amount The amount of underlying `ASSET` to deposit (e.g. deposit of 100 USDC)
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param fromUnderlying bool
   * - `true` if the msg.sender comes with underlying tokens (e.g. USDC)
   * - `false` if the msg.sender comes already with aTokens (e.g. aUSDC)
   * @return uint256 The amount of StaticAToken minted, static balance
   **/
  function deposit(
    address recipient,
    uint256 amount,
    uint16 referralCode,
    bool fromUnderlying
  ) external returns (uint256) {
    return _deposit(msg.sender, recipient, amount, referralCode, fromUnderlying);
  }

  /**
   * @dev Burns `amount` of static aToken, with recipient receiving the corresponding amount of `ASSET`
   * @param recipient The address that will receive the amount of `ASSET` withdrawn from the Aave protocol
   * @param amount The amount to withdraw, in static balance of StaticAToken
   * @param toUnderlying bool
   * - `true` for the recipient to get underlying tokens (e.g. USDC)
   * - `false` for the recipient to get aTokens (e.g. aUSDC)
   * @return amountToBurn: StaticATokens burnt, static balance
   * @return amountToWithdraw: underlying/aToken send to `recipient`, dynamic balance
   **/
  function withdraw(
    address recipient,
    uint256 amount,
    bool toUnderlying
  ) external returns (uint256, uint256) {
    return _withdraw(msg.sender, recipient, amount, 0, toUnderlying);
  }

  /**
   * @dev Burns `amount` of static aToken, with recipient receiving the corresponding amount of `ASSET`
   * @param recipient The address that will receive the amount of `ASSET` withdrawn from the Aave protocol
   * @param amount The amount to withdraw, in dynamic balance of aToken/underlying asset
   * @param toUnderlying bool
   * - `true` for the recipient to get underlying tokens (e.g. USDC)
   * - `false` for the recipient to get aTokens (e.g. aUSDC)
   * @return amountToBurn: StaticATokens burnt, static balance
   * @return amountToWithdraw: underlying/aToken send to `recipient`, dynamic balance
   **/
  function withdrawDynamicAmount(
    address recipient,
    uint256 amount,
    bool toUnderlying
  ) external returns (uint256, uint256) {
    return _withdraw(msg.sender, recipient, 0, amount, toUnderlying);
  }

  /**
   * @dev Implements the permit function as for
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner The owner of the funds
   * @param spender The spender
   * @param value The amount
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param v Signature param
   * @param s Signature param
   * @param r Signature param
   * @param chainId Passing the chainId in order to be fork-compatible
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint256 chainId
  ) external {
    require(owner != address(0), 'INVALID_OWNER');
    //solium-disable-next-line
    require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
    uint256 currentValidNonce = _nonces[owner];
    bytes32 digest =
      keccak256(
        abi.encodePacked(
          '\x19\x01',
          getDomainSeparator(chainId),
          keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
        )
      );
    require(owner == ecrecover(digest, v, r, s), 'INVALID_SIGNATURE');
    _nonces[owner] = currentValidNonce + 1;
    _approve(owner, spender, value);
  }

  /**
   * @dev Allows to deposit on Aave via meta-transaction
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param depositor Address from which the funds to deposit are going to be pulled
   * @param recipient Address that will receive the staticATokens, in the average case, same as the `depositor`
   * @param value The amount to deposit
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param fromUnderlying bool
   * - `true` if the msg.sender comes with underlying tokens (e.g. USDC)
   * - `false` if the msg.sender comes already with aTokens (e.g. aUSDC)
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param sigParams Signature params: v,r,s
   * @param chainId Passing the chainId in order to be fork-compatible
   * @return uint256 The amount of StaticAToken minted, static balance
   */
  function metaDeposit(
    address depositor,
    address recipient,
    uint256 value,
    uint16 referralCode,
    bool fromUnderlying,
    uint256 deadline,
    SignatureParams calldata sigParams,
    uint256 chainId
  ) external returns (uint256) {
    require(depositor != address(0), 'INVALID_DEPOSITOR');
    //solium-disable-next-line
    require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
    uint256 currentValidNonce = _nonces[depositor];
    bytes32 digest =
      keccak256(
        abi.encodePacked(
          '\x19\x01',
          getDomainSeparator(chainId),
          keccak256(
            abi.encode(
              METADEPOSIT_TYPEHASH,
              depositor,
              recipient,
              value,
              referralCode,
              fromUnderlying,
              currentValidNonce,
              deadline
            )
          )
        )
      );
    require(
      depositor == ecrecover(digest, sigParams.v, sigParams.r, sigParams.s),
      'INVALID_SIGNATURE'
    );
    _nonces[depositor] = currentValidNonce + 1;
    _deposit(depositor, recipient, value, referralCode, fromUnderlying);
  }

  /**
   * @dev Allows to withdraw from Aave via meta-transaction
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner Address owning the staticATokens
   * @param recipient Address that will receive the underlying withdrawn from Aave
   * @param staticAmount The amount of staticAToken to withdraw. If > 0, `dynamicAmount` needs to be 0
   * @param dynamicAmount The amount of underlying/aToken to withdraw. If > 0, `staticAmount` needs to be 0
   * @param toUnderlying bool
   * - `true` for the recipient to get underlying tokens (e.g. USDC)
   * - `false` for the recipient to get aTokens (e.g. aUSDC)
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param sigParams Signature params: v,r,s
   * @param chainId Passing the chainId in order to be fork-compatible
   * @return amountToBurn: StaticATokens burnt, static balance
   * @return amountToWithdraw: underlying/aToken send to `recipient`, dynamic balance
   */
  function metaWithdraw(
    address owner,
    address recipient,
    uint256 staticAmount,
    uint256 dynamicAmount,
    bool toUnderlying,
    uint256 deadline,
    SignatureParams calldata sigParams,
    uint256 chainId
  ) external returns (uint256, uint256) {
    require(owner != address(0), 'INVALID_DEPOSITOR');
    //solium-disable-next-line
    require(block.timestamp <= deadline, 'INVALID_EXPIRATION');
    uint256 currentValidNonce = _nonces[owner];
    bytes32 digest =
      keccak256(
        abi.encodePacked(
          '\x19\x01',
          getDomainSeparator(chainId),
          keccak256(
            abi.encode(
              METAWITHDRAWAL_TYPEHASH,
              owner,
              recipient,
              staticAmount,
              dynamicAmount,
              toUnderlying,
              currentValidNonce,
              deadline
            )
          )
        )
      );
    require(owner == ecrecover(digest, sigParams.v, sigParams.r, sigParams.s), 'INVALID_SIGNATURE');
    _nonces[owner] = currentValidNonce + 1;
    return _withdraw(owner, recipient, staticAmount, dynamicAmount, toUnderlying);
  }

  /**
   * @dev Utility method to get the current aToken balance of an user, from his staticAToken balance
   * @param account The address of the user
   * @return uint256 The aToken balance
   **/
  function dynamicBalanceOf(address account) external view returns (uint256) {
    return staticToDynamicAmount(balanceOf(account));
  }

  /**
   * @dev Converts a static amount (scaled balance on aToken) to the aToken/underlying value,
   * using the current liquidity index on Aave
   * @param amount The amount to convert from
   * @return uint256 The dynamic amount
   **/
  function staticToDynamicAmount(uint256 amount) public view returns (uint256) {
    return amount.rayMul(rate());
  }

  /**
   * @dev Converts an aToken or underlying amount to the what it is denominated on the aToken as
   * scaled balance, function of the principal and the liquidity index
   * @param amount The amount to convert from
   * @return uint256 The static (scaled) amount
   **/
  function dynamicToStaticAmount(uint256 amount) public view returns (uint256) {
    return amount.rayDiv(rate());
  }

  /**
   * @dev Returns the Aave liquidity index of the underlying aToken, denominated rate here
   * as it can be considered as an ever-increasing exchange rate
   * @return bytes32 The domain separator
   **/
  function rate() public view returns (uint256) {
    return LENDING_POOL.getReserveNormalizedIncome(address(ASSET));
  }

  /**
   * @dev Function to return a dynamic domain separator, in order to be compatible with forks changing chainId
   * @param chainId The chain id
   * @return bytes32 The domain separator
   **/
  function getDomainSeparator(uint256 chainId) public view returns (bytes32) {
    return
      keccak256(
        abi.encode(
          EIP712_DOMAIN,
          keccak256(bytes(name())),
          keccak256(EIP712_REVISION),
          chainId,
          address(this)
        )
      );
  }

  function _deposit(
    address depositor,
    address recipient,
    uint256 amount,
    uint16 referralCode,
    bool fromUnderlying
  ) internal returns (uint256) {
    require(recipient != address(0), 'INVALID_RECIPIENT');

    if (fromUnderlying) {
      ASSET.safeTransferFrom(depositor, address(this), amount);
      LENDING_POOL.deposit(address(ASSET), amount, address(this), referralCode);
    } else {
      ATOKEN.safeTransferFrom(depositor, address(this), amount);
    }

    uint256 amountToMint = dynamicToStaticAmount(amount);
    _mint(recipient, amountToMint);
    return amountToMint;
  }

  function _withdraw(
    address owner,
    address recipient,
    uint256 staticAmount,
    uint256 dynamicAmount,
    bool toUnderlying
  ) internal returns (uint256, uint256) {
    require(recipient != address(0), 'INVALID_RECIPIENT');
    require(staticAmount == 0 || dynamicAmount == 0, 'ONLY_ONE_AMOUNT_FORMAT_ALLOWED');

    uint256 userBalance = balanceOf(owner);

    uint256 amountToWithdraw;
    uint256 amountToBurn;

    uint256 currentRate = rate();
    if (staticAmount > 0) {
      amountToBurn = (staticAmount > userBalance) ? userBalance : staticAmount;
      amountToWithdraw = (staticAmount > userBalance)
        ? _staticToDynamicAmount(userBalance, currentRate)
        : _staticToDynamicAmount(staticAmount, currentRate);
    } else {
      uint256 dynamicUserBalance = _staticToDynamicAmount(userBalance, currentRate);
      amountToWithdraw = (dynamicAmount > dynamicUserBalance) ? dynamicUserBalance : dynamicAmount;
      amountToBurn = _dynamicToStaticAmount(amountToWithdraw, currentRate);
    }

    _burn(owner, amountToBurn);

    if (toUnderlying) {
      LENDING_POOL.withdraw(address(ASSET), amountToWithdraw, recipient);
    } else {
      ATOKEN.safeTransfer(recipient, amountToWithdraw);
    }

    return (amountToBurn, amountToWithdraw);
  }

  function _dynamicToStaticAmount(uint256 amount, uint256 rate) internal pure returns (uint256) {
    return amount.rayDiv(rate);
  }

  function _staticToDynamicAmount(uint256 amount, uint256 rate) internal pure returns (uint256) {
    return amount.rayMul(rate);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;

import * as DataTypes from "./DataTypes.sol";

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";

interface ILendingPool {
  /// @dev Emitted on `deposit`.
  ///
  /// @param reserve    The address of the underlying asset of the reserve.
  /// @param user       The address initiating the deposit.
  /// @param onBehalfOf The beneficiary of the deposit, receiving the aTokens.
  /// @param amount     The amount deposited.
  /// @param referral   The referral code used.
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /// @dev Emitted on `withdraw`.
  ///
  /// @param reserve The address of the underlying asset being withdrawn.
  /// @param user    The address initiating the withdrawal, owner of aTokens.
  /// @param to      Address that will receive the underlying.
  /// @param amount  The amount to be withdrawn.
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);
  
  /// @dev Emitted on `borrow` and `flashLoan` when debt needs to be opened.
  ///
  /// @param reserve        The address of the underlying asset being borrowed.
  /// @param user           The address of the user initiating the `borrow`, receiving the funds on `borrow` or just
  ///                       initiator of the transaction on `flashLoan`.
  /// @param onBehalfOf     The address that will be getting the debt.
  /// @param amount         The amount borrowed out.
  /// @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable.
  /// @param borrowRate     The numeric rate at which the user has borrowed.
  /// @param referral       The referral code used.
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /// @dev Emitted on `repay`.
  ///
  /// @param reserve The address of the underlying asset of the reserve.
  /// @param user    The beneficiary of the repayment, getting his debt reduced.
  /// @param repayer The address of the user initiating the `repay`, providing the funds.
  /// @param amount  The amount repaid.
  event Repay(address indexed reserve, address indexed user, address indexed repayer, uint256 amount);
  
  /// @dev Emitted on `swapBorrowRateMode`.
  ///
  /// @param reserve  The address of the underlying asset of the reserve
  /// @param user     The address of the user swapping his rate mode
  /// @param rateMode The rate mode that the user wants to swap to
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);
  
  /// @dev Emitted on `setUserUseReserveAsCollateral`.
  ///
  /// @param reserve The address of the underlying asset of the reserve
  /// @param user    The address of the user enabling the usage as collateral
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /// @dev Emitted on `setUserUseReserveAsCollateral`.
  ///
  /// @param reserve The address of the underlying asset of the reserve
  /// @param user    The address of the user enabling the usage as collateral
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);
  
  /// @dev Emitted on `rebalanceStableBorrowRate`.
  ///
  /// @param reserve The address of the underlying asset of the reserve
  /// @param user    The address of the user for which the rebalance has been executed
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /// @dev Emitted on `flashLoan`.
  ///
  /// @param target       The address of the flash loan receiver contract.
  /// @param initiator    The address initiating the flash loan.
  /// @param asset        The address of the asset being flash borrowed.
  /// @param amount       The amount flash borrowed.
  /// @param premium      The fee flash borrowed.
  /// @param referralCode The referral code used.
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /// @dev Emitted when the pause is triggered.
  event Paused();

  /// @dev Emitted when the pause is lifted.
  event Unpaused();

  /// @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via LendingPoolCollateral
  ///      manager using a DELEGATECALL.
  ///
  /// This allows to have the events in the generated ABI for LendingPool.
  ///
  /// @param collateralAsset            The address of the underlying asset used as collateral, to receive as result of
  ///                                   the liquidation.
  /// @param debtAsset                  The address of the underlying borrowed asset to be repaid with the liquidation.
  /// @param user                       The address of the borrower getting liquidated.
  /// @param debtToCover                The debt amount of borrowed `asset` the liquidator wants to cover.
  /// @param liquidatedCollateralAmount The amount of collateral received by the liquidator.
  /// @param liquidator                 The address of the liquidator
  /// @param receiveAToken              `true` if the liquidators wants to receive the collateral aTokens, `false` if
  ///                                   he wants to receive the underlying collateral asset directly.
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /// @dev Emitted when the state of a reserve is updated.
  ///
  /// NOTE: This event is actually declared in the ReserveLogic library and emitted in the `updateInterestRates`
  /// function. Since the function is internal, the event will actually be fired by the LendingPool contract. The event
  /// is therefore replicated here so it gets added to the LendingPool ABI.
  ///
  /// @param reserve             The address of the underlying asset of the reserve.
  /// @param liquidityRate       The new liquidity rate.
  /// @param stableBorrowRate    The new stable borrow rate.
  /// @param variableBorrowRate  The new variable borrow rate.
  /// @param liquidityIndex      The new liquidity index
  /// @param variableBorrowIndex The new variable borrow index
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /// @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
  ///
  /// - E.g. User deposits 100 USDC and gets in return 100 aUSDC.
  ///
  /// @param asset        The address of the underlying asset to deposit.
  /// @param amount       The amount to be deposited.
  /// @param onBehalfOf   The address that will receive the aTokens, same as msg.sender if the user wants to receive
  ///                     them on his own wallet, or a different address if the beneficiary of aTokens is a different
  ///                     wallet.
  /// @param referralCode Code used to register the integrator originating the operation, for potential rewards.0 if the
  ///                     action is executed directly by the user, without any middle-man
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /// @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned.
  ///
  /// E.g. User has 100 aUSDC, calls `withdraw` and receives 100 USDC, burning the 100 aUSDC.
  ///
  /// @param asset  The address of the underlying asset to withdraw
  /// @param amount The underlying amount to be withdrawn.
  /// @param to     Address that will receive the underlying, same as msg.sender if the user wants to receive it on his
  ///               own wallet, or a different address if the beneficiary is a different wallet.
  ///
  /// @return amountWithdrawn The final amount withdrawn
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256 amountWithdrawn);

  /// @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
  ///     already deposited enough collateral, or he was given enough allowance by a credit delegator on the
  ///     corresponding debt token (StableDebtToken or VariableDebtToken).
  ///
  /// - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet and
  ///   100 stable/variable debt tokens, depending on the `interestRateMode`.
  ///
  /// @param asset            The address of the underlying asset to borrow.
  /// @param amount           The amount to be borrowed.
  /// @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
  /// @param referralCode     Code used to register the integrator originating the operation, for potential rewards.
  ///                         0 if the action is executed directly by the user, without any middle-man
  /// @param onBehalfOf       Address of the user who will receive the debt. Should be the address of the borrower
  ///                         itself calling the function if he wants to borrow against his own collateral, or the
  ///                         address of the credit delegator if he has been given credit delegation allowance
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /// @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned.
  ///
  /// - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address.
  ///
  /// @param asset      The address of the borrowed underlying asset previously borrowed.
  /// @param amount     The amount to repay.
  /// @param rateMode   The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
  /// @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the user
  ///                   calling the function if he wants to reduce/remove his own debt, or the address of any other
  ///                   other borrower whose debt should be removed.
  ///
  /// @return amountRepaid The final amount repaid.
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256 amountRepaid);

  /// @dev Allows a borrower to swap his debt between stable and variable mode, or vice versa.
  ///
  /// @param asset    The address of the underlying asset borrowed.
  /// @param rateMode The rate mode that the user wants to swap to.
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /// @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
  ///
  /// - Users can be rebalanced if the following conditions are satisfied:
  ///   1. Usage ratio is above 95%
  ///   2. the current deposit APY is below REBALANCE_UP_THRESHOLD  maxVariableBorrowRate, which means that too much
  ///      has been borrowed at a stable rate and depositors are not earning enough.
  ///
  /// @param asset The address of the underlying asset borrowed.
  /// @param user The address of the user to be rebalanced.
  function rebalanceStableBorrowRate(address asset, address user) external;

  /// @dev Allows depositors to enable/disable a specific deposited asset as collateral.
  ///
  /// @param asset            The address of the underlying asset deposited.
  /// @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise.
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;
  
  /// @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1.
  ///
  /// - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives a
  ///   proportionally amount of the `collateralAsset` plus a bonus to cover market risk.
  ///
  /// @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the
  ///                        liquidation.
  /// @param debtAsset       The address of the underlying borrowed asset to be repaid with the liquidation.
  /// @param user            The address of the borrower getting liquidated.
  /// @param debtToCover     The debt amount of borrowed `asset` the liquidator wants to cover.
  /// @param receiveAToken   `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants to
  ///                        receive the underlying collateral asset directly
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /// @dev Allows smart contracts to access the liquidity of the pool within one transaction, as long as the amount
  ///      taken plus a fee is returned.
  ///
  /// IMPORTANT There are security concerns for developers of flash loan receiver contracts that must be kept into
  /// consideration.
  ///
  /// For further details please visit https://developers.aave.com.
  ///
  /// @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver
  ///                        interface.
  /// @param assets          The addresses of the assets being flash-borrowed.
  /// @param amounts         The amounts amounts being flash-borrowed.
  /// @param modes           Types of the debt to open if the flash loan is not returned.
  /// @param onBehalfOf      The address  that will receive the debt in the case of using on `modes` 1 or 2.
  /// @param params          Variadic packed params to pass to the receiver as extra information.
  /// @param referralCode    Code used to register the integrator originating the operation, for potential rewards. 0
  ///                        if the action is executed directly by the user, without any middle-man
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /// @dev Returns the user account data across all the reserves.
  ///
  /// @param user The address of the user.
  ///
  /// @return totalCollateralETH          The total collateral in ETH of the user.
  /// @return totalDebtETH                The total debt in ETH of the user.
  /// @return availableBorrowsETH         The borrowing power left of the user.
  /// @return currentLiquidationThreshold The liquidation threshold of the user.
  /// @return ltv                         The loan to value of the user.
  /// @return healthFactor                The current health factor of the user.
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
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /// @dev Returns the configuration of the reserve.
  ///
  /// @param asset The address of the underlying asset of the reserve.
  ///
  /// @return The configuration of the reserve.
  function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

  /// @dev Returns the configuration of the user across all the reserves.
  ///
  /// @param user The user address.
  ///
  /// @return The configuration of the user.
  function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);
  
  /// @dev Returns the normalized income normalized income of the reserve.
  ///
  /// @param asset The address of the underlying asset of the reserve.
  ///
  /// @return The reserve's normalized income.
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /// @dev Returns the normalized variable debt per unit of asset.`
  ///
  /// @param asset The address of the underlying asset of the reserve.
  ///
  /// @return The reserve normalized variable debt.
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /// @dev Returns the state and configuration of the reserve.
  ///
  /// @param asset The address of the underlying asset of the reserve.
  ///
  /// @return The state of the reserve.
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0-rc.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;

import {IERC20} from "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import {IInitializableAToken} from './IInitializableAToken.sol';
import {IAaveIncentivesController} from './IAaveIncentivesController.sol';

interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
  /**
   * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   * @param index The new liquidity index of the reserve
   **/
  event Mint(address indexed from, uint256 value, uint256 index);

  /**
   * @dev Mints `amount` aTokens to `user`
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
   * @dev Emitted after aTokens are burned
   * @param from The owner of the aTokens, getting them burned
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
   * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the aTokens, getting them burned
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
   * @dev Mints aTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
   * @param from The address getting liquidated, current owner of the aTokens
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
   * @dev Invoked to execute actions on the aToken side after a repayment.
   * @param user The user executing the repayment
   * @param amount The amount getting repaid
   **/
  function handleRepayment(address user, uint256 amount) external;

  /**
   * @dev Returns the address of the incentives controller contract
   **/
  function getIncentivesController() external view returns (IAaveIncentivesController);

  /**
   * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
   **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0-rc.0) (token/ERC20/ERC20.sol)

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
pragma solidity >=0.5.0;

import {Errors} from './Errors.sol';

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

pragma solidity ^0.8.13;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IERC20Burnable.sol";
import "../interfaces/IERC20Mintable.sol";

/// @title  TokenUtils
/// @author Alchemix Finance
library TokenUtils {
    /// @notice An error used to indicate that a call to an ERC20 contract failed.
    ///
    /// @param target  The target address.
    /// @param success If the call to the token was a success.
    /// @param data    The resulting data from the call. This is error data when the call was not a success. Otherwise,
    ///                this is malformed data when the call was a success.
    error ERC20CallFailed(address target, bool success, bytes data);

    /// @dev A safe function to get the decimals of an ERC20 token.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
    ///
    /// @param token The target token.
    ///
    /// @return The amount of decimals of the token.
    function expectDecimals(address token) internal view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );

        if (token.code.length == 0 || !success || data.length < 32) {
            revert ERC20CallFailed(token, success, data);
        }

        return abi.decode(data, (uint8));
    }

    /// @dev Gets the balance of tokens held by an account.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
    ///
    /// @param token   The token to check the balance of.
    /// @param account The address of the token holder.
    ///
    /// @return The balance of the tokens held by an account.
    function safeBalanceOf(address token, address account) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, account)
        );

        if (token.code.length == 0 || !success || data.length < 32) {
            revert ERC20CallFailed(token, success, data);
        }

        return abi.decode(data, (uint256));
    }

    /// @dev Transfers tokens to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer failed or returns an unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransfer(address token, address recipient, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount)
        );

        if (token.code.length == 0 || !success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Approves tokens for the smart contract.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the approval fails or returns an unexpected value.
    ///
    /// @param token   The token to approve.
    /// @param spender The contract to spend the tokens.
    /// @param value   The amount of tokens to approve.
    function safeApprove(address token, address spender, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.approve.selector, spender, value)
        );

        if (token.code.length == 0 || !success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Transfer tokens from one address to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer fails or returns an unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param owner     The address of the owner.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransferFrom(address token, address owner, address recipient, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, owner, recipient, amount)
        );

        if (token.code.length == 0 || !success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Mints tokens to an address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the mint fails or returns an unexpected value.
    ///
    /// @param token     The token to mint.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to mint.
    function safeMint(address token, address recipient, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Mintable.mint.selector, recipient, amount)
        );

        if (token.code.length == 0 || !success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Burns tokens.
    ///
    /// Reverts with a `CallFailed` error if execution of the burn fails or returns an unexpected value.
    ///
    /// @param token  The token to burn.
    /// @param amount The amount of tokens to burn.
    function safeBurn(address token, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Burnable.burn.selector, amount)
        );

        if (token.code.length == 0 || !success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Burns tokens from its total supply.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the burn fails or returns an unexpected value.
    ///
    /// @param token  The token to burn.
    /// @param owner  The owner of the tokens.
    /// @param amount The amount of tokens to burn.
    function safeBurnFrom(address token, address owner, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Burnable.burnFrom.selector, owner, amount)
        );

        if (token.code.length == 0 || !success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;

// @dev Refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
struct ReserveData {
  // Stores the reserve configuration.
  ReserveConfigurationMap configuration;
  // The liquidity index. Expressed in ray.
  uint128 liquidityIndex;
  // Variable borrow index. Expressed in ray.
  uint128 variableBorrowIndex;
  // The current supply rate. Expressed in ray.
  uint128 currentLiquidityRate;
  // The current variable borrow rate. Expressed in ray.
  uint128 currentVariableBorrowRate;
  // The current stable borrow rate. Expressed in ray.
  uint128 currentStableBorrowRate;
  uint40 lastUpdateTimestamp;
  // Tokens addresses.
  address aTokenAddress;
  address stableDebtTokenAddress;
  address variableDebtTokenAddress;
  // Address of the interest rate strategy.
  address interestRateStrategyAddress;
  // The id of the reserve. Represents the position in the list of the active reserves.
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;

/// @title  ILendingPoolAddressesProvider
/// @author Aave
///
/// @dev Main registry of addresses part of or connected to the protocol, including permissioned roles.
///
/// - Acting also as factory of proxies and admin of those, so with right to change its implementations.
/// - Owned by the Aave Governance.
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
pragma solidity >=0.5.0;

interface IScaledBalanceToken {
  /// @dev Returns the scaled balance of the user. The scaled balance is the sum of all the updated stored balance
  ///      divided by the reserve's liquidity index at the moment of the update.
  ///
  /// @param user The user whose balance is calculated.
  ///
  /// @return The scaled balance of the user.
  function scaledBalanceOf(address user) external view returns (uint256);

  /// @dev Returns the scaled balance of the user and the scaled total supply.
  ///
  /// @param user The address of the user.
  ///
  /// @return scaledBalance     The scaled balance of the user.
  /// @return scaledTotalSupply The scaled balance and the scaled total supply.
  function getScaledUserBalanceAndSupply(address user)
    external view
    returns (
      uint256 scaledBalance,
      uint256 scaledTotalSupply
    );

  /// @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index).
  ///
  /// @return The scaled total supply.
  function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;

import {ILendingPool} from './ILendingPool.sol';
import {IAaveIncentivesController} from './IAaveIncentivesController.sol';

/**
 * @title IInitializableAToken
 * @notice Interface for the initialize function on AToken
 * @author Aave
 **/
interface IInitializableAToken {
  /**
   * @dev Emitted when an aToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated lending pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this aToken
   * @param aTokenDecimals the decimals of the underlying
   * @param aTokenName the name of the aToken
   * @param aTokenSymbol the symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController,
    uint8 aTokenDecimals,
    string aTokenName,
    string aTokenSymbol,
    bytes params
  );

  /**
   * @dev Initializes the aToken
   * @param pool The address of the lending pool where this aToken will be used
   * @param treasury The address of the Aave treasury, receiving the fees on this aToken
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   */
  function initialize(
    ILendingPool pool,
    address treasury,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 aTokenDecimals,
    string calldata aTokenName,
    string calldata aTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
pragma solidity >=0.5.0;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
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
  string public constant LPC_INVALID_ATOKEN_POOL_ADDRESS = '35'; // 'The liquidity of the reserve needs to be 0'
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
  string public constant LP_CALLER_MUST_BE_AN_ATOKEN = '63';
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

pragma solidity >=0.5.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title  IERC20Burnable
/// @author Alchemix Finance
interface IERC20Burnable is IERC20 {
    /// @notice Burns `amount` tokens from the balance of `msg.sender`.
    ///
    /// @param amount The amount of tokens to burn.
    ///
    /// @return If burning the tokens was successful.
    function burn(uint256 amount) external returns (bool);

    /// @notice Burns `amount` tokens from `owner`'s balance.
    ///
    /// @param owner  The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    ///
    /// @return If burning the tokens was successful.
    function burnFrom(address owner, uint256 amount) external returns (bool);
}

pragma solidity >=0.5.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title  IERC20Mintable
/// @author Alchemix Finance
interface IERC20Mintable is IERC20 {
    /// @notice Mints `amount` tokens to `recipient`.
    ///
    /// @param recipient The address which will receive the minted tokens.
    /// @param amount    The amount of tokens to mint.
    function mint(address recipient, uint256 amount) external;
}