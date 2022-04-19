// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/MathUtil.sol";
import "./interfaces/IHeroInfinityNodePool.sol";

contract HeroInfinityNodePoolV2 is Ownable {
  using SafeMath for uint256;
  using MathUtil for uint256;

  struct NodeEntity {
    string name;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 feeTime;
    uint256 dueTime;
  }

  mapping(address => mapping(uint256 => uint256)) public userFees;
  mapping(address => bool) public migrated;
  mapping(address => uint256) public nodeOwners;
  mapping(address => NodeEntity[]) private _nodesOfUser;

  uint256 public nodePrice = 200000 * 10**18;
  uint256 public initialRewardRate = 0.04 * 10**4; // starting at 4%
  uint256 public rewardReduceRatePerDay = 0.97 * 100;
  uint256 public minRewardRatePerDay = 0.003 * 10**4; // min rate 0.3%
  uint256 public maxNodesPerWallet = 50;
  uint256 public maxNodes = 5000;

  uint256 public initialNodeFee = 10000000000000000;
  uint256 public minNodeFee = 1000000000000000;
  uint256 public feeDeductionRate = 15; // 15% per month
  uint256 public feeDuration = 28 days;
  uint256 public overDuration = 2 days;

  uint256 public totalNodesCreated = 0;

  IERC20 public hriToken = IERC20(0x0C4BA8e27e337C5e8eaC912D836aA8ED09e80e78);
  IHeroInfinityNodePool public oldNodePool =
    IHeroInfinityNodePool(0xFAd5Ef0F347eb7bB89E798B5d026F60aFA3E2bF4);

  constructor() {}

  function upgradeNode() external {
    IHeroInfinityNodePool.NodeEntity[] memory nodes = oldNodePool.getNodes(
      msg.sender
    );

    for (uint256 i = 0; i < nodes.length; i++) {
      address account = msg.sender;
      _nodesOfUser[account].push(
        NodeEntity({
          name: nodes[i].name,
          creationTime: nodes[i].creationTime,
          lastClaimTime: nodes[i].lastClaimTime,
          feeTime: nodes[i].feeTime,
          dueTime: nodes[i].dueTime
        })
      );
      nodeOwners[account]++;
      totalNodesCreated++;
    }

    migrated[msg.sender] = true;
  }

  function createNode(string memory nodeName, uint256 count) external {
    require(count > 0, "Count should be not 0");
    address account = msg.sender;
    uint256 ownerCount = nodeOwners[account];
    require(
      isNameAvailable(account, nodeName),
      "CREATE NODE: Name not available"
    );
    require(ownerCount + count <= maxNodesPerWallet, "Count Limited");
    require(
      ownerCount == 0 ||
        _nodesOfUser[account][ownerCount - 1].creationTime < block.timestamp,
      "Too many requests"
    );
    require(totalNodesCreated + count <= maxNodes, "Exceed max nodes limit");

    uint256 price = nodePrice * count;

    hriToken.transferFrom(account, address(this), price);

    for (uint256 i = 0; i < count; i++) {
      uint256 time = block.timestamp + i;
      _nodesOfUser[account].push(
        NodeEntity({
          name: nodeName,
          creationTime: time,
          lastClaimTime: time,
          feeTime: time + feeDuration,
          dueTime: time + feeDuration + overDuration
        })
      );
      nodeOwners[account]++;
      totalNodesCreated++;
    }
  }

  function isNameAvailable(address account, string memory nodeName)
    internal
    view
    returns (bool)
  {
    NodeEntity[] memory nodes = _nodesOfUser[account];
    for (uint256 i = 0; i < nodes.length; i++) {
      if (keccak256(bytes(nodes[i].name)) == keccak256(bytes(nodeName))) {
        return false;
      }
    }
    return true;
  }

  function _getNodeWithCreatime(
    NodeEntity[] storage nodes,
    uint256 _creationTime
  ) internal view returns (NodeEntity storage) {
    uint256 numberOfNodes = nodes.length;
    require(numberOfNodes > 0, "CLAIM ERROR: You don't have nodes to claim");
    bool found = false;
    int256 index = binarySearch(nodes, 0, numberOfNodes, _creationTime);
    uint256 validIndex;
    if (index >= 0) {
      found = true;
      validIndex = uint256(index);
    }
    require(found, "NODE SEARCH: No NODE Found with this blocktime");
    return nodes[validIndex];
  }

  function binarySearch(
    NodeEntity[] memory arr,
    uint256 low,
    uint256 high,
    uint256 x
  ) internal view returns (int256) {
    if (high >= low) {
      uint256 mid = (high + low).div(2);
      if (arr[mid].creationTime == x) {
        return int256(mid);
      } else if (arr[mid].creationTime > x) {
        return binarySearch(arr, low, mid - 1, x);
      } else {
        return binarySearch(arr, mid + 1, high, x);
      }
    } else {
      return -1;
    }
  }

  function getRewardsForDay(uint256 passedDays) public view returns (uint256) {
    uint256 rewards = (nodePrice * initialRewardRate) / (10**4);

    for (uint256 i = 0; i < passedDays - 1; i++) {
      rewards = (rewards * rewardReduceRatePerDay) / 100;
    }

    uint256 minRewards = (nodePrice * minRewardRatePerDay) / (10**4);
    return rewards > minRewards ? rewards : minRewards;
  }

  function getNodeReward(NodeEntity memory node)
    internal
    view
    returns (uint256)
  {
    if (block.timestamp > node.dueTime) {
      return 0;
    }

    uint256 passedSeconds = block.timestamp - node.creationTime;
    uint256 passedDays = passedSeconds.divCeil(86400);
    uint256 todayPassedSeconds = passedSeconds % 86400;
    uint256 secondsDiffBetweenLCTAndNow = block.timestamp - node.lastClaimTime;
    todayPassedSeconds = todayPassedSeconds > secondsDiffBetweenLCTAndNow
      ? secondsDiffBetweenLCTAndNow
      : todayPassedSeconds;

    uint256 rewards = 0;
    for (uint256 i = 1; i <= passedDays; i++) {
      if (node.creationTime + 86400 * i > node.lastClaimTime) {
        uint256 passedSecondsAfterClaim = node.creationTime +
          86400 *
          i -
          node.lastClaimTime;

        uint256 dayReward = getRewardsForDay(i);
        if (i == passedDays) {
          rewards += (dayReward * todayPassedSeconds) / 86400;
        } else {
          if (passedSecondsAfterClaim >= 1 days) {
            rewards += dayReward;
          } else {
            rewards += (dayReward * passedSecondsAfterClaim) / 86400;
          }
        }
      }
    }
    return rewards;
  }

  function getFeeAmount(address account, uint256 createTime)
    public
    view
    returns (uint256)
  {
    uint256 lastFee = userFees[account][createTime];
    if (lastFee == 0) {
      return initialNodeFee;
    }

    uint256 estimatedFee = (lastFee * (100 - feeDeductionRate)) / 100;
    return minNodeFee > estimatedFee ? minNodeFee : estimatedFee;
  }

  function getAllFee(address user) public view returns (uint256) {
    NodeEntity[] storage nodes = _nodesOfUser[user];

    uint256 allFee = 0;
    for (uint256 i = 0; i < nodes.length; i++) {
      if (nodes[i].dueTime >= block.timestamp) {
        allFee += getFeeAmount(user, nodes[i].creationTime);
      }
    }

    return allFee;
  }

  function payNodeFee(uint256 _creationTime) external payable {
    address user = msg.sender;
    NodeEntity[] storage nodes = _nodesOfUser[user];
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    uint256 nodeFee = getFeeAmount(user, _creationTime);
    require(msg.value >= nodeFee, "Need to pay fee amount");
    require(node.dueTime >= block.timestamp, "Node is disabled");
    node.feeTime = block.timestamp + feeDuration;
    node.dueTime = node.feeTime + overDuration;
    userFees[user][_creationTime] = nodeFee;
  }

  function payAllNodesFee() external payable {
    address user = msg.sender;
    NodeEntity[] storage nodes = _nodesOfUser[user];
    uint256 allFee = getAllFee(user);

    require(msg.value >= allFee, "Need to pay fee amount");
    for (uint256 i = 0; i < nodes.length; i++) {
      if (nodes[i].dueTime >= block.timestamp) {
        uint256 nodeFee = getFeeAmount(user, nodes[i].creationTime);
        nodes[i].feeTime = block.timestamp + feeDuration;
        nodes[i].dueTime = nodes[i].feeTime + overDuration;
        userFees[user][nodes[i].creationTime] = nodeFee;
      }
    }
  }

  function claimNodeReward(uint256 _creationTime) external {
    address account = msg.sender;
    require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 numberOfNodes = nodes.length;
    require(numberOfNodes > 0, "CLAIM ERROR: You don't have nodes to claim");
    NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
    uint256 rewardNode = getNodeReward(node);
    node.lastClaimTime = block.timestamp;
    hriToken.transfer(account, rewardNode);
  }

  function claimAllNodesReward() external {
    address account = msg.sender;
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 nodesCount = nodes.length;
    require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity storage _node;
    uint256 rewardsTotal = 0;
    for (uint256 i = 0; i < nodesCount; i++) {
      _node = nodes[i];
      uint256 nodeReward = getNodeReward(_node);
      rewardsTotal += nodeReward;
      _node.lastClaimTime = block.timestamp;
    }
    hriToken.transfer(account, rewardsTotal);
  }

  function getRewardTotalAmountOf(address account)
    external
    view
    returns (uint256)
  {
    uint256 nodesCount;
    uint256 rewardCount = 0;

    NodeEntity[] storage nodes = _nodesOfUser[account];
    nodesCount = nodes.length;

    for (uint256 i = 0; i < nodesCount; i++) {
      uint256 nodeReward = getNodeReward(nodes[i]);
      rewardCount += nodeReward;
    }

    return rewardCount;
  }

  function getRewardAmountOf(address account, uint256 creationTime)
    external
    view
    returns (uint256)
  {
    require(creationTime > 0, "NODE: CREATIME must be higher than zero");
    NodeEntity[] storage nodes = _nodesOfUser[account];
    uint256 numberOfNodes = nodes.length;
    require(numberOfNodes > 0, "CLAIM ERROR: You don't have nodes to claim");
    NodeEntity storage node = _getNodeWithCreatime(nodes, creationTime);
    uint256 nodeReward = getNodeReward(node);
    return nodeReward;
  }

  function getNodes(address account)
    external
    view
    returns (NodeEntity[] memory nodes)
  {
    nodes = _nodesOfUser[account];
  }

  function getNodeNumberOf(address account) external view returns (uint256) {
    return nodeOwners[account];
  }

  function withdrawReward(uint256 amount) external onlyOwner {
    hriToken.transfer(msg.sender, amount);
  }

  function withdrawFee(uint256 amount) external onlyOwner {
    payable(msg.sender).transfer(amount);
  }

  function setNodePrice(uint256 newNodePrice) external onlyOwner {
    nodePrice = newNodePrice;
  }

  function setInitialRewardRate(uint256 rate) external onlyOwner {
    initialRewardRate = rate;
  }

  function setRewardReduceRatePerDay(uint256 rate) external onlyOwner {
    rewardReduceRatePerDay = rate;
  }

  function setMinRewardRatePerDay(uint256 rate) external onlyOwner {
    minRewardRatePerDay = rate;
  }

  function setInitialNodeFee(uint256 _feeAmount) external onlyOwner {
    initialNodeFee = _feeAmount;
  }

  function setFeeDuration(uint256 _feeDuration) external onlyOwner {
    feeDuration = _feeDuration;
  }

  function setOverDuration(uint256 _overDuration) external onlyOwner {
    overDuration = _overDuration;
  }

  function setMaxNodesPerWallet(uint256 _count) external onlyOwner {
    maxNodesPerWallet = _count;
  }

  function setFeeDeductionRate(uint256 rate) external onlyOwner {
    feeDeductionRate = rate;
  }

  function setMinNodeFee(uint256 fee) external onlyOwner {
    minNodeFee = fee;
  }

  function setMaxNodes(uint256 _count) external onlyOwner {
    maxNodes = _count;
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

library MathUtil {
  function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 m = a % b;
    uint256 r = (a - m) / b;
    if (m > 0) {
      r += 1;
    }

    return r;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IHeroInfinityNodePool {
  struct NodeEntity {
    string name;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 feeTime;
    uint256 dueTime;
  }

  function getNodeNumberOf(address account) external view returns (uint256);

  function getNodes(address account)
    external
    view
    returns (NodeEntity[] memory nodes);
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