// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {IllegalState, Unauthorized} from "../../base/ErrorMessages.sol";
import {MutexLock} from "../../base/MutexLock.sol";
import {IERC20Metadata} from "../../interfaces/IERC20Metadata.sol";
import {ITokenAdapter} from "../../interfaces/ITokenAdapter.sol";
import {IStaticAToken} from "../../interfaces/external/aave/IStaticAToken.sol";

import {TokenUtils} from "../../libraries/TokenUtils.sol";

struct InitializationParams {
    address alchemist;
    address token;
    address underlyingToken;
}

contract AAVETokenAdapter is ITokenAdapter, MutexLock {
    string public constant override version = "1.0.0";
    address public alchemist;
    address public override token;
    address public override underlyingToken;
    uint8 public tokenDecimals;

    constructor(InitializationParams memory params) {
        alchemist = params.alchemist;
        token = params.token;
        underlyingToken = params.underlyingToken;
        TokenUtils.safeApprove(underlyingToken, token, type(uint256).max);
        tokenDecimals = TokenUtils.expectDecimals(token);
    }

    /// @dev Checks that the message sender is the alchemist that the adapter is bound to.
    modifier onlyAlchemist() {
        if (msg.sender != alchemist) {
            revert Unauthorized("Not alchemist");
        }
        _;
    }

    /// @inheritdoc ITokenAdapter
    function price() external view override returns (uint256) {
        return IStaticAToken(token).staticToDynamicAmount(10**tokenDecimals);
    }

    /// @inheritdoc ITokenAdapter
    function wrap(uint256 amount, address recipient) external lock onlyAlchemist override returns (uint256) {
        TokenUtils.safeTransferFrom(underlyingToken, msg.sender, address(this), amount);
        // 0 - referral code (deprecated).
        // true - "from underlying", we are depositing the underlying token, not the aToken.
        return IStaticAToken(token).deposit(recipient, amount, 0, true);
    }

    /// @inheritdoc ITokenAdapter
    function unwrap(uint256 amount, address recipient) external lock onlyAlchemist override returns (uint256) {
        TokenUtils.safeTransferFrom(token, msg.sender, address(this), amount);
        // true - "to underlying", we are withdrawing the underlying token, not the aToken.
        (uint256 amountBurnt, uint256 amountWithdrawn) = IStaticAToken(token).withdraw(recipient, amount, true);
        if (amountBurnt != amount) {
           revert IllegalState("Amount burnt mismatch");
        }
        return amountWithdrawn;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

/// @notice An error used to indicate that an argument passed to a function is illegal or
///         inappropriate.
///
/// @param message The error message.
error IllegalArgument(string message);

/// @notice An error used to indicate that a function has encountered an unrecoverable state.
///
/// @param message The error message.
error IllegalState(string message);

/// @notice An error used to indicate that an operation is unsupported.
///
/// @param message The error message.
error UnsupportedOperation(string message);

/// @notice An error used to indicate that a message sender tried to execute a privileged function.
///
/// @param message The error message.
error Unauthorized(string message);

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.13;

import {IllegalState} from "./ErrorMessages.sol";

/// @title  Mutex
/// @author Alchemix Finance
///
/// @notice Provides a mutual exclusion lock for implementing contracts.
abstract contract MutexLock {
    enum State {
        RESERVED,
        UNLOCKED,
        LOCKED
    }

    /// @notice The lock state.
    State private _lockState = State.UNLOCKED;

    /// @dev A modifier which acquires the mutex.
    modifier lock() {
        _claimLock();

        _;

        _freeLock();
    }

    /// @dev Gets if the mutex is locked.
    ///
    /// @return if the mutex is locked.
    function _isLocked() internal view returns (bool) {
        return _lockState == State.LOCKED;
    }

    /// @dev Claims the lock. If the lock is already claimed, then this will revert.
    function _claimLock() internal {
        // Check that the lock has not been claimed yet.
        if (_lockState != State.UNLOCKED) {
            revert IllegalState("Lock already claimed");
        }

        // Claim the lock.
        _lockState = State.LOCKED;
    }

    /// @dev Frees the lock.
    function _freeLock() internal {
        _lockState = State.UNLOCKED;
    }
}

pragma solidity >=0.5.0;

/// @title  IERC20Metadata
/// @author Alchemix Finance
interface IERC20Metadata {
    /// @notice Gets the name of the token.
    ///
    /// @return The name.
    function name() external view returns (string memory);

    /// @notice Gets the symbol of the token.
    ///
    /// @return The symbol.
    function symbol() external view returns (string memory);

    /// @notice Gets the number of decimals that the token has.
    ///
    /// @return The number of decimals.
    function decimals() external view returns (uint8);
}

pragma solidity >=0.5.0;

/// @title  ITokenAdapter
/// @author Alchemix Finance
interface ITokenAdapter {
    /// @notice Gets the current version.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Gets the address of the yield token that this adapter supports.
    ///
    /// @return The address of the yield token.
    function token() external view returns (address);

    /// @notice Gets the address of the underlying token that the yield token wraps.
    ///
    /// @return The address of the underlying token.
    function underlyingToken() external view returns (address);

    /// @notice Gets the number of underlying tokens that a single whole yield token is redeemable
    ///         for.
    ///
    /// @return The price.
    function price() external view returns (uint256);

    /// @notice Wraps `amount` underlying tokens into the yield token.
    ///
    /// @param amount    The amount of the underlying token to wrap.
    /// @param recipient The address which will receive the yield tokens.
    ///
    /// @return amountYieldTokens The amount of yield tokens minted to `recipient`.
    function wrap(uint256 amount, address recipient)
        external
        returns (uint256 amountYieldTokens);

    /// @notice Unwraps `amount` yield tokens into the underlying token.
    ///
    /// @param amount    The amount of yield-tokens to redeem.
    /// @param recipient The recipient of the resulting underlying-tokens.
    ///
    /// @return amountUnderlyingTokens The amount of underlying tokens unwrapped to `recipient`.
    function unwrap(uint256 amount, address recipient)
        external
        returns (uint256 amountUnderlyingTokens);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.5.0;

import {IERC20} from "../../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {IAToken} from "./IAToken.sol";
import {ILendingPool} from "./ILendingPool.sol";

/// @title  IStaticAToken
/// @author Aave
///
/// @dev Wrapper token that allows to deposit tokens on the Aave protocol and receive token which balance doesn't
///      increase automatically, but uses an ever-increasing exchange rate. Only supporting deposits and withdrawals.
interface IStaticAToken is IERC20 {
  struct SignatureParams {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  function LENDING_POOL() external returns (ILendingPool);
  function ATOKEN() external returns (IERC20);
  function ASSET() external returns (IERC20);

  function _nonces(address owner) external returns (uint256);

  function deposit(
    address recipient,
    uint256 amount,
    uint16 referralCode,
    bool fromUnderlying
  ) external returns (uint256);

  function withdraw(
    address recipient,
    uint256 amount,
    bool toUnderlying
  ) external returns (uint256, uint256);

  function withdrawDynamicAmount(
    address recipient,
    uint256 amount,
    bool toUnderlying
  ) external returns (uint256, uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s,
    uint256 chainId
  ) external;

  function metaDeposit(
    address depositor,
    address recipient,
    uint256 value,
    uint16 referralCode,
    bool fromUnderlying,
    uint256 deadline,
    SignatureParams calldata sigParams,
    uint256 chainId
  ) external returns (uint256);

  function metaWithdraw(
    address owner,
    address recipient,
    uint256 staticAmount,
    uint256 dynamicAmount,
    bool toUnderlying,
    uint256 deadline,
    SignatureParams calldata sigParams,
    uint256 chainId
  ) external returns (uint256, uint256);

  function dynamicBalanceOf(address account) external view returns (uint256);

  /// @dev Converts a static amount (scaled balance on aToken) to the aToken/underlying value, using the current
  ///      liquidity index on Aave.
  ///
  /// @param amount The amount to convert from.
  ///
  /// @return dynamicAmount The dynamic amount.
  function staticToDynamicAmount(uint256 amount) external view returns (uint256 dynamicAmount);

  /// @dev Converts an aToken or underlying amount to the what it is denominated on the aToken as scaled balance,
  ///      function of the principal and the liquidity index.
  ///
  /// @param amount The amount to convert from.
  ///
  /// @return staticAmount The static (scaled) amount.
  function dynamicToStaticAmount(uint256 amount) external view returns (uint256 staticAmount);

  /// @dev Returns the Aave liquidity index of the underlying aToken, denominated rate here as it can be considered as
  ///      an ever-increasing exchange rate.
  ///
  /// @return The rate.
  function rate() external view returns (uint256);

  /// @dev Function to return a dynamic domain separator, in order to be compatible with forks changing chainId.
  ///
  /// @param chainId The chain id.
  ///
  /// @return The domain separator.
  function getDomainSeparator(uint256 chainId) external returns (bytes32);
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