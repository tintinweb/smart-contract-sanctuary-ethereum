// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "../../interfaces/aaveV3/IAaveProtocolDataProvider.sol";
import "../../interfaces/aaveV3/IPool.sol";
import "../../interfaces/ILendingProvider.sol";
import "../../interfaces/IUnwrapper.sol";
import "../../interfaces/IWETH.sol";
import "../../libraries/UniversalERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title AaveV3 Lending Provider.
 * @author Fujidao Labs
 * @notice Adapter for AaveV3.
 */
contract AaveV3Rinkeby is ILendingProvider {
  using UniversalERC20 for IERC20;

  function _getNativeAddr() internal pure returns (address) {
    return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  }

  function _getWrappedNativeAddr() internal pure returns (address) {
    return 0xd74047010D77c5901df5b0f9ca518aED56C85e8D;
  }

  function _getAaveProtocolDataProvider() internal pure returns (IAaveProtocolDataProvider) {
    return IAaveProtocolDataProvider(0xBAB2E7afF5acea53a43aEeBa2BA6298D8056DcE5);
  }

  function _getPool() internal pure returns (IPool) {
    return IPool(0xE039BdF1d874d27338e09B55CB09879Dedca52D8);
  }

  function _getUnwrapper() internal pure returns (address) {
    return 0xBB73511B0099eF355AA580D0149AC4C679A0B805;
  }

  /**
   * @notice See {ILendingProvider}
   */
  function approvedOperator(address) external pure returns (address operator) {
    operator = address(_getPool());
  }

  /**
   * @notice See {ILendingProvider}
   */
  function deposit(address asset, uint256 amount) external returns (bool success) {
    IPool aave = _getPool();

    aave.supply(asset, amount, address(this), 0);

    aave.setUserUseReserveAsCollateral(asset, true);
    success = true;
  }

  /**
   * @notice See {ILendingProvider}
   */
  function borrow(address asset, uint256 amount) external returns (bool success) {
    IPool aave = _getPool();
    bool isNative = asset == _getNativeAddr();
    address _tokenAddr = isNative ? _getWrappedNativeAddr() : asset;

    aave.borrow(_tokenAddr, amount, 2, 0, address(this));

    // convert Native to WrappedNative
    if (isNative) {
      address unwrapper = _getUnwrapper();
      IERC20(_tokenAddr).univTransfer(payable(unwrapper), amount);
      IUnwrapper(unwrapper).withdraw(amount);
    }
    success = true;
  }

  /**
   * @notice See {ILendingProvider}
   */
  function withdraw(address asset, uint256 amount) external returns (bool success) {
    IPool aave = _getPool();
    bool isNative = asset == _getNativeAddr();
    address _tokenAddr = isNative ? _getWrappedNativeAddr() : asset;

    aave.withdraw(_tokenAddr, amount, address(this));

    // convert Native to WrappedNative
    if (isNative) {
      address unwrapper = _getUnwrapper();
      IERC20(_tokenAddr).univTransfer(payable(unwrapper), amount);
      IUnwrapper(unwrapper).withdraw(amount);
    }
    success = true;
  }

  /**
   * @notice See {ILendingProvider}
   */
  function payback(address asset, uint256 amount) external returns (bool success) {
    IPool aave = _getPool();
    bool isNative = asset == _getNativeAddr();
    address _tokenAddr = isNative ? _getWrappedNativeAddr() : asset;
    // convert Native to WrappedNative
    if (isNative) IWETH(_tokenAddr).deposit{ value: amount }();
    IERC20(_tokenAddr).univApprove(address(aave), amount);

    aave.repay(_tokenAddr, amount, 2, address(this));

    success = true;
  }

  /**
   * @notice See {ILendingProvider}
   */
  function getDepositRateFor(address asset) external view returns (uint256 rate) {
    IPool aaveData = _getPool();
    IPool.ReserveData memory rdata = aaveData.getReserveData(
      asset == _getNativeAddr() ? _getWrappedNativeAddr() : asset
    );
    rate = rdata.currentLiquidityRate;
  }

  /**
   * @notice See {ILendingProvider}
   */
  function getBorrowRateFor(address asset) external view returns (uint256 rate) {
    IPool aaveData = _getPool();
    IPool.ReserveData memory rdata = aaveData.getReserveData(
      asset == _getNativeAddr() ? _getWrappedNativeAddr() : asset
    );
    rate = rdata.currentVariableBorrowRate;
  }

  /**
   * @notice See {ILendingProvider}
   */
  function getDepositBalance(address asset, address user) external view returns (uint256 balance) {
    IAaveProtocolDataProvider aaveData = _getAaveProtocolDataProvider();
    bool isNative = asset == _getNativeAddr();
    address _tokenAddr = isNative ? _getWrappedNativeAddr() : asset;
    (balance, , , , , , , , ) = aaveData.getUserReserveData(_tokenAddr, user);
  }

  /**
   * @notice See {ILendingProvider}
   */
  function getBorrowBalance(address asset, address user) external view returns (uint256 balance) {
    IAaveProtocolDataProvider aaveData = _getAaveProtocolDataProvider();
    bool isNative = asset == _getNativeAddr();
    address _tokenAddr = isNative ? _getWrappedNativeAddr() : asset;
    (, , balance, , , , , , ) = aaveData.getUserReserveData(_tokenAddr, user);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface IAaveProtocolDataProvider {
  function getReserveData(address asset)
    external
    view
    returns (
      uint256 unbacked,
      uint256 accruedToTreasuryScaled,
      uint256 totalAToken,
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface IPool {
  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62-63: reserved
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused
    uint256 data;
  }

  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
  }

  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) external returns (uint256);

  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) external;

  function getReserveData(address asset) external view returns (ReserveData memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

/**
 * @title Lending provider interface.
 * @author fujidao Labs
 * @notice  Defines the interface for core engine to perform operations at lending providers.
 */
interface ILendingProvider {
  /**
   * @notice Returns the operator address that requires ERC20-approval for deposits.
   * @param asset address.
   */
  function approvedOperator(address asset) external returns (address operator);

  /**
   * @notice Performs deposit operation at lending provider on behalf caller.
   * @param asset address.
   * @param amount amount integer.
   */
  function deposit(address asset, uint256 amount) external returns (bool success);

  /**
   * @notice Performs borrow operation at lending provider on behalf caller.
   * @param asset address.
   * @param amount amount integer.
   */
  function borrow(address asset, uint256 amount) external returns (bool success);

  /**
   * @notice Performs withdraw operation at lending provider on behalf caller.
   * @param asset address.
   * @param amount amount integer.
   */
  function withdraw(address asset, uint256 amount) external returns (bool success);

  /**
   * @notice Performs payback operation at lending provider on behalf caller.
   * @param asset address.
   * @param amount amount integer.
   * @dev Check erc20-approval to lending provider prior to call.
   */
  function payback(address asset, uint256 amount) external returns (bool success);

  /**
   * @notice Returns the latest SUPPLY annual percent rate (APR) at lending provider.
   * @param asset address.
   * @dev Should return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   */
  function getDepositRateFor(address asset) external view returns (uint256 rate);

  /**
   * @notice Returns the latest BORROW annual percent rate (APR) at lending provider.
   * @param asset address.
   * @dev Should return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   */
  function getBorrowRateFor(address asset) external view returns (uint256 rate);

  /**
   * @notice Returns DEPOSIT balance of 'user' at lending provider.
   * @param asset address.
   * @param user address whom balance is needed.
   */
  function getDepositBalance(address asset, address user) external view returns (uint256 balance);

  /**
   * @notice Returns BORROW balance of 'user' at lending provider.
   * @param asset address.
   * @param user address whom balance is needed.
   */
  function getBorrowBalance(address asset, address user) external view returns (uint256 balance);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface IUnwrapper {
  /**
   * @notice Convert wrappedNative to native and transfer to msg.sender
   * @param amount amount to withdraw.
   * @dev msg.sender needs to send WrappedNative before calling this withdraw
   */
  function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

interface IWETH {
  function approve(address, uint256) external;

  function deposit() external payable;

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title Universal ERC20 Handler.
 * @author fujidao Labs
 * @notice Allows contract to handle both an ERC20 token or the native asset.
 */
library UniversalERC20 {
  IERC20 private constant _NATIVE_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  IERC20 private constant _ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);

  function isNative(IERC20 token) internal pure returns (bool) {
    return (token == _ZERO_ADDRESS || token == _NATIVE_ADDRESS);
  }

  function univBalanceOf(IERC20 token, address account) internal view returns (uint256) {
    if (isNative(token)) {
      return account.balance;
    } else {
      return token.balanceOf(account);
    }
  }

  function univTransfer(
    IERC20 token,
    address payable to,
    uint256 amount
  ) internal {
    if (amount > 0) {
      if (isNative(token)) {
        (bool sent, ) = to.call{ value: amount }("");
        require(sent, "Failed to send Native");
      } else {
        token.transfer(to, amount);
      }
    }
  }

  function univApprove(
    IERC20 token,
    address to,
    uint256 amount
  ) internal {
    require(!isNative(token), "Approve called on Native");

    if (amount == 0) {
      token.approve(to, 0);
    } else {
      uint256 allowance = token.allowance(address(this), to);
      if (allowance < amount) {
        if (allowance > 0) {
          token.approve(to, 0);
        }
        token.approve(to, amount);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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