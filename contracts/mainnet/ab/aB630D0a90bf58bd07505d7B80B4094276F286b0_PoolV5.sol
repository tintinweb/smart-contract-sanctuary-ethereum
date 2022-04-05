// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../lib/openzeppelin/contracts/3.4.1/token/ERC20/IERC20.sol";
import "./lib/SafeMath.sol";
import "./interfaces/StrongPoolInterface.sol";
import "./lib/rewards.sol";

contract PoolV5 {
  event Mined(address indexed miner, uint256 amount);
  event Unmined(address indexed miner, uint256 amount);
  event Claimed(address indexed miner, uint256 reward);

  using SafeMath for uint256;

  bool public initDone;
  address public admin;
  address public pendingAdmin;
  address public superAdmin;
  address public pendingSuperAdmin;
  address public parameterAdmin;
  address payable public feeCollector;

  IERC20 public token;
  IERC20 public strongToken;
  StrongPoolInterface public strongPool;

  mapping(address => uint256) public minerBalance;
  uint256 public totalBalance;
  mapping(address => uint256) public minerBlockLastClaimedOn;

  uint256 public rewardBalance;

  uint256 public rewardPerBlockNumerator;
  uint256 public rewardPerBlockDenominator;

  uint256 public miningFeeNumerator;
  uint256 public miningFeeDenominator;

  uint256 public unminingFeeNumerator;
  uint256 public unminingFeeDenominator;

  uint256 public claimingFeeNumerator;
  uint256 public claimingFeeDenominator;

  uint256 public claimingFeeInWei;

  uint256 public rewardPerBlockNumeratorNew;
  uint256 public rewardPerBlockDenominatorNew;
  uint256 public rewardPerBlockNewEffectiveBlock;

  function init(
    address strongTokenAddress,
    address tokenAddress,
    address strongPoolAddress,
    address adminAddress,
    address superAdminAddress,
    uint256 rewardPerBlockNumeratorValue,
    uint256 rewardPerBlockDenominatorValue,
    uint256 miningFeeNumeratorValue,
    uint256 miningFeeDenominatorValue,
    uint256 unminingFeeNumeratorValue,
    uint256 unminingFeeDenominatorValue,
    uint256 claimingFeeNumeratorValue,
    uint256 claimingFeeDenominatorValue
  ) public {
    require(!initDone, "init done");
    strongToken = IERC20(strongTokenAddress);
    token = IERC20(tokenAddress);
    strongPool = StrongPoolInterface(strongPoolAddress);
    admin = adminAddress;
    superAdmin = superAdminAddress;
    rewardPerBlockNumerator = rewardPerBlockNumeratorValue;
    rewardPerBlockDenominator = rewardPerBlockDenominatorValue;
    miningFeeNumerator = miningFeeNumeratorValue;
    miningFeeDenominator = miningFeeDenominatorValue;
    unminingFeeNumerator = unminingFeeNumeratorValue;
    unminingFeeDenominator = unminingFeeDenominatorValue;
    claimingFeeNumerator = claimingFeeNumeratorValue;
    claimingFeeDenominator = claimingFeeDenominatorValue;
    initDone = true;
  }

  // ADMIN
  // *************************************************************************************
  function updateParameterAdmin(address newParameterAdmin) public {
    require(newParameterAdmin != address(0), "zero");
    require(msg.sender == superAdmin);
    parameterAdmin = newParameterAdmin;
  }

  function setPendingAdmin(address newPendingAdmin) public {
    require(newPendingAdmin != address(0), "zero");
    require(msg.sender == admin, "not admin");
    pendingAdmin = newPendingAdmin;
  }

  function acceptAdmin() public {
    require(msg.sender == pendingAdmin && msg.sender != address(0), "not pendingAdmin");
    admin = pendingAdmin;
    pendingAdmin = address(0);
  }

  function setPendingSuperAdmin(address newPendingSuperAdmin) public {
    require(newPendingSuperAdmin != address(0), "zero");
    require(msg.sender == superAdmin, "not superAdmin");
    pendingSuperAdmin = newPendingSuperAdmin;
  }

  function acceptSuperAdmin() public {
    require(msg.sender == pendingSuperAdmin && msg.sender != address(0), "not pendingSuperAdmin");
    superAdmin = pendingSuperAdmin;
    pendingSuperAdmin = address(0);
  }

  // REWARD
  // *************************************************************************************
  function updateRewardPerBlock(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
    require(denominator != 0, "invalid value");
    rewardPerBlockNumerator = numerator;
    rewardPerBlockDenominator = denominator;
  }

  function deposit(uint256 amount) public {
    require(msg.sender == superAdmin, "not an admin");
    require(amount > 0, "zero");
    strongToken.transferFrom(msg.sender, address(this), amount);
    rewardBalance = rewardBalance.add(amount);
  }

  function withdraw(address destination, uint256 amount) public {
    require(msg.sender == superAdmin, "not an admin");
    require(amount > 0, "zero");
    require(rewardBalance >= amount, "not enough");
    strongToken.transfer(destination, amount);
    rewardBalance = rewardBalance.sub(amount);
  }

  // FEES
  // *************************************************************************************
  function updateFeeCollector(address payable newFeeCollector) public {
    require(newFeeCollector != address(0), "zero");
    require(msg.sender == superAdmin);
    feeCollector = newFeeCollector;
  }

  function updateMiningFee(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
    require(denominator != 0, "invalid value");
    miningFeeNumerator = numerator;
    miningFeeDenominator = denominator;
  }

  function updateUnminingFee(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
    require(denominator != 0, "invalid value");
    unminingFeeNumerator = numerator;
    unminingFeeDenominator = denominator;
  }

  function updateClaimingFee(uint256 numerator, uint256 denominator) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
    require(denominator != 0, "invalid value");
    claimingFeeNumerator = numerator;
    claimingFeeDenominator = denominator;
  }

  // CORE
  // *************************************************************************************
  function mine(uint256 amount) public payable {
    require(amount > 0, "zero");
    uint256 fee = amount.mul(miningFeeNumerator).div(miningFeeDenominator);
    require(msg.value == fee, "invalid fee");
    feeCollector.transfer(msg.value);
    if (block.number > minerBlockLastClaimedOn[msg.sender]) {
      uint256 reward = getReward(msg.sender);
      if (reward > 0) {
        rewardBalance = rewardBalance.sub(reward);
        strongToken.approve(address(strongPool), reward);
        strongPool.mineFor(msg.sender, reward);
        minerBlockLastClaimedOn[msg.sender] = block.number;
      }
    }
    token.transferFrom(msg.sender, address(this), amount);
    minerBalance[msg.sender] = minerBalance[msg.sender].add(amount);
    totalBalance = totalBalance.add(amount);
    if (minerBlockLastClaimedOn[msg.sender] == 0) {
      minerBlockLastClaimedOn[msg.sender] = block.number;
    }
    emit Mined(msg.sender, amount);
  }

  function unmine(uint256 amount) public payable {
    require(amount > 0, "zero");
    uint256 fee = amount.mul(unminingFeeNumerator).div(unminingFeeDenominator);
    require(msg.value == fee, "invalid fee");
    require(minerBalance[msg.sender] >= amount, "not enough");
    feeCollector.transfer(msg.value);
    if (block.number > minerBlockLastClaimedOn[msg.sender]) {
      uint256 reward = getReward(msg.sender);
      if (reward > 0) {
        rewardBalance = rewardBalance.sub(reward);
        strongToken.approve(address(strongPool), reward);
        strongPool.mineFor(msg.sender, reward);
        minerBlockLastClaimedOn[msg.sender] = block.number;
      }
    }
    minerBalance[msg.sender] = minerBalance[msg.sender].sub(amount);
    totalBalance = totalBalance.sub(amount);
    token.transfer(msg.sender, amount);
    if (minerBalance[msg.sender] == 0) {
      minerBlockLastClaimedOn[msg.sender] = 0;
    }
    emit Unmined(msg.sender, amount);
  }

  function claim(uint256 blockNumber) public payable {
    require(blockNumber <= block.number, "invalid block number");
    require(minerBlockLastClaimedOn[msg.sender] != 0, "error");
    require(blockNumber > minerBlockLastClaimedOn[msg.sender], "too soon");
    uint256 reward = getRewardByBlock(msg.sender, blockNumber);
    require(reward > 0, "no reward");
    uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
    require(msg.value == fee, "invalid fee");
    feeCollector.transfer(msg.value);
    strongToken.approve(address(strongPool), reward);
    strongPool.mineFor(msg.sender, reward);
    rewardBalance = rewardBalance.sub(reward);
    minerBlockLastClaimedOn[msg.sender] = blockNumber;
    emit Claimed(msg.sender, reward);
  }

  function getReward(address miner) public view returns (uint256) {
    return getRewardByBlock(miner, block.number);
  }

  function getRewardByBlock(address miner, uint256 blockNumber) public view returns (uint256) {
    uint256 blockLastClaimedOn = minerBlockLastClaimedOn[miner];

    if (blockNumber > block.number) return 0;
    if (blockLastClaimedOn == 0) return 0;
    if (blockNumber < blockLastClaimedOn) return 0;
    if (totalBalance == 0) return 0;

    uint256[2] memory rewardBlocks = rewards.blocks(blockLastClaimedOn, rewardPerBlockNewEffectiveBlock, blockNumber);
    uint256 rewardOld = rewardPerBlockDenominator > 0 ? rewardBlocks[0].mul(rewardPerBlockNumerator).div(rewardPerBlockDenominator) : 0;
    uint256 rewardNew = rewardPerBlockDenominatorNew > 0 ? rewardBlocks[1].mul(rewardPerBlockNumeratorNew).div(rewardPerBlockDenominatorNew) : 0;

    return rewardOld.add(rewardNew).mul(minerBalance[miner]).div(totalBalance);
  }

  function updateRewardPerBlockNew(
    uint256 numerator,
    uint256 denominator,
    uint256 effectiveBlock
  ) public {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");

    rewardPerBlockNumeratorNew = numerator;
    rewardPerBlockDenominatorNew = denominator;
    rewardPerBlockNewEffectiveBlock = effectiveBlock != 0 ? effectiveBlock : block.number;
  }

  function setTokenContract(IERC20 tokenAddress) external {
    require(msg.sender == superAdmin, "not an admin");
    strongToken = tokenAddress;
  }

  function withdrawToken(IERC20 token, address recipient, uint256 amount) external {
    require(msg.sender == superAdmin, "not an admin");
    require(token.transfer(recipient, amount));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    uint256 c = a + b;
    if (c < a) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the substraction of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b > a) return (false, 0);
    return (true, a - b);
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) return (true, 0);
    uint256 c = a * b;
    if (c / a != b) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a / b);
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a % b);
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
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
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
    require(b <= a, "SafeMath: subtraction overflow");
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
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting on
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
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
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
    require(b > 0, "SafeMath: modulo by zero");
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
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryDiv}.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
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
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface StrongPoolInterface {
  function mineFor(address miner, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";

library rewards {

    using SafeMath for uint256;

    function blocks(uint256 lastClaimedOnBlock, uint256 newRewardBlock, uint256 blockNumber) internal pure returns (uint256[2] memory) {
        if (lastClaimedOnBlock >= blockNumber) return [uint256(0), uint256(0)];

        if (blockNumber <= newRewardBlock || newRewardBlock == 0) {
            return [blockNumber.sub(lastClaimedOnBlock), uint256(0)];
        }
        else if (lastClaimedOnBlock >= newRewardBlock) {
            return [uint256(0), blockNumber.sub(lastClaimedOnBlock)];
        }
        else {
            return [newRewardBlock.sub(lastClaimedOnBlock), blockNumber.sub(newRewardBlock)];
        }
    }

}