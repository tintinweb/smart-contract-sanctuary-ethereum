// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "../interfaces/IStaking.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeERC20.sol";


/** 
 * Allows for FLOOR to be swapped for sFLOOR.
 */

contract StakeAndWrapZap {

  using SafeERC20 for IERC20;

  IStaking public immutable staking;
  IERC20 public immutable FLOOR;
  IERC20 public immutable sFLOOR;

  // Event fired when FLOOR is staked and wrapped
  event FloorStakedAndWrapped(address user, uint256 amount, uint256 received);


  /** 
   * @notice Sets up our contract with references to relevant existing contracts.
   *
   * @param _staking     FLOOR Staking contract
   * @param _floor       Floor token
   * @param _sFloor      sFloor token
   */

  constructor (address _staking, address _floor, address _sFloor) {
    // Set our staking contract
    staking = IStaking(_staking);

    // Store our FLOOR and sFLOOR ERC20 contracts
    FLOOR = IERC20(_floor);
    sFLOOR = IERC20(_sFloor);
  }


  /** 
   * @notice Approves all FLOOR and sFLOOR in this contract to be
   * used by the staking contract.
   */

  function approve() external {
    FLOOR.approve(address(staking), type(uint256).max);
    sFLOOR.approve(address(staking), type(uint256).max);
  }


  /** 
   * @notice Stakes FLOOR and returns sFLOOR to the requested user.
   *
   * @param _to       The recipient of payout
   * @param _amount   Amount of FLOOR to stake
   *
   * @return returnedAmount_ sFloor sent to recipient
   */

  function stakeAndWrap(address _to, uint256 _amount) external returns (uint256 returnedAmount_) {
    require(_to != address(0));

    // Transfer FLOOR from sender to our zap contract
    FLOOR.safeTransferFrom(msg.sender, address(this), _amount);

    // Stake the FLOOR transferred from sender without rebasing or claiming
    staking.stake(address(this), _amount, false, false);
    
    // Return the amount of sFLOOR received by `_to`
    returnedAmount_ = staking.wrap(_to, _amount);

    // Emit our event for subgraph visibility
    emit FloorStakedAndWrapped(_to, _amount, returnedAmount_);
  }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}