/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: MIT
// File: @aave/protocol-v2/contracts/interfaces/IScaledBalanceToken.sol


pragma solidity 0.6.12;

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

// File: @aave/protocol-v2/contracts/dependencies/openzeppelin/contracts/IERC20.sol


pragma solidity 0.6.12;

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

// File: @aave/protocol-v2/contracts/interfaces/IAToken.sol


pragma solidity 0.6.12;



interface IAToken is IERC20, IScaledBalanceToken {
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
   * @param user The recipient of the aTokens
   * @param amount The amount getting transferred
   * @return The amount transferred
   **/
  function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);
}

// File: contracts/SentibleRouterV1.sol


pragma solidity >=0.6.12 < 0.9.0;
// pragma experimental ABIEncoderV2;
/// @title Sentible v1 Router Contract
/// @author SentibleLabs
/// @notice This contract is used to deposit and withdraw from the Sentible Pool


interface AaveLendingPool {
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function getReserveData(address asset) external view returns (
    uint256 configuration,
    uint128 liquidityIndex,
    uint128 variableBorrowIndex,
    uint128 currentLiquidityRate,
    uint128 currentVariableBorrowRate,
    uint128 currentStableBorrowRate,
    uint40 lastUpdateTimestamp,
    address aTokenAddress,
    address stableDebtTokenAddress,
    address variableDebtTokenAddress,
    address interestRateStrategyAddress,
    uint8 id
  );

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external;

  function paused() external view returns (bool);
}

contract SentibleRouterV1 {
  address public owner;
  address public lendingPoolAddress;
  bool public isPaused = false;
  AaveLendingPool aaveLendingPool;

  event Deposit(address owner, uint256 amount, address asset);
  event Withdraw(address owner, uint256 amount, address asset);

  modifier poolActive {
    require(!aaveLendingPool.paused(), "Aave contract is paused");
    require(!isPaused, "Sentible contract is paused");
    _;
  }

  modifier onlyOwner {
    require(msg.sender == owner, "Only owner can call this function");
    _;
  }

  constructor() public {
    owner = msg.sender;
    lendingPoolAddress = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    aaveLendingPool = AaveLendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
  }

  function approveSpender(address asset, uint256 amount, address spender) public onlyOwner {
    IERC20(asset).approve(spender, amount);
  }

  function approvePool(address asset, uint256 amount) public onlyOwner {
    IERC20(asset).approve(lendingPoolAddress, amount);
  }

  // Deposit to lending pool
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf
  ) public poolActive {
    require(IERC20(asset).allowance(msg.sender, address(this)) >= amount, "Allowance required");

    IERC20(asset).approve(lendingPoolAddress, amount);
    IERC20(asset).transferFrom(msg.sender, address(this), amount);
    aaveLendingPool.deposit(asset, amount, onBehalfOf, 0);
    emit Deposit(msg.sender, amount, asset);
  }

  // Withdraw from lending pool
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) public poolActive {
    (, , , , , , , address aTokenAddress, , , , ) = aaveLendingPool.getReserveData(asset);
    address borrower = address(this);
    IAToken aToken = IAToken(aTokenAddress);

    aToken.transferFrom(msg.sender, borrower, amount);
    aaveLendingPool.withdraw(asset, amount, to);
    emit Withdraw(msg.sender, amount, asset);
  }

  // Set Pool Address
  function setPoolAddress(address _poolAddress) public onlyOwner {
    require(msg.sender == owner, "Only owner can set pool address");
    lendingPoolAddress = _poolAddress;
    aaveLendingPool = AaveLendingPool(_poolAddress);
  }

  function setPaused(bool _isPaused) public onlyOwner {
    require(msg.sender == owner, "Only owner can pause");
    isPaused = _isPaused;
  }
}