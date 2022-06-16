//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

//import "hardhat/console.sol";
import "./lib/SafeMath.sol";

contract Test {
  using SafeMath for uint256;

  event MigratedToNodePack(address indexed entity, uint128 fromNodeId, uint toPackId, uint nodeSeconds, uint totalSeconds);
  event Created(address indexed entity, uint packType, uint nodesCount, bool usedCredit, uint timestamp, address migratedFrom, uint lastPaidAt);

  uint constant public secondsPerBlock = 13;

  mapping(address => uint128) public entityNodeCount;
  mapping(bytes => uint256) public entityNodePaidOnBlock;
  mapping(bytes => uint256) public entityNodeClaimedTotal;

  function getNodeId(address entity, uint128 nodeId) public view returns (bytes memory) {
    uint128 id = nodeId != 0 ? nodeId : entityNodeCount[entity] + 1;
    return abi.encodePacked(entity, id);
  }

  function getRewardAll(address entity, uint256 blockNumber) public view returns (uint256) {
    return 0;
//    uint256 rewardsAll = 0;
//
//    for (uint128 i = 1; i <= entityNodeCount[entity]; i++) {
//      rewardsAll = rewardsAll.add(getRewardByBlock(entity, i, blockNumber > 0 ? blockNumber : block.number));
//    }
//
//    return rewardsAll;
  }

  function setup() external {
    entityNodeCount[msg.sender] = 5;
    entityNodePaidOnBlock[getNodeId(msg.sender, 1)] = 14848087;
    entityNodePaidOnBlock[getNodeId(msg.sender, 2)] = 14945039;
    entityNodePaidOnBlock[getNodeId(msg.sender, 3)] = 14851391;
    entityNodePaidOnBlock[getNodeId(msg.sender, 4)] = 14982358;
    entityNodePaidOnBlock[getNodeId(msg.sender, 5)] = 14936284;
  }

  function migrateAll() external payable {
//    uint256 blockNumber = 14969712;
//    uint256 blockTimestamp = 1655328937;
//    uint256 blockNumber = block.number;
//    uint256 blockTimestamp = block.timestamp;

    uint256 totalClaimed = 0;
    uint128 migratedNodes = 0;
    uint256 totalSeconds = 0;
    uint256 rewardsDue = getRewardAll(msg.sender, 0);

    for (uint128 nodeId = 1; nodeId <= entityNodeCount[msg.sender]; nodeId++) {
      bytes memory id = getNodeId(msg.sender, nodeId);
      bool migrated = true;
      if (migrated) {
        migratedNodes += 1;
        totalClaimed = totalClaimed.add(entityNodeClaimedTotal[id]);
        totalSeconds = totalSeconds.add(block.timestamp - ((block.number - entityNodePaidOnBlock[id]) * secondsPerBlock));
        emit MigratedToNodePack(msg.sender, nodeId, 1, block.timestamp - ((block.number - entityNodePaidOnBlock[id]) * secondsPerBlock), totalSeconds);
      }
    }

//    console.log("block.number: ", block.number);
//    console.log("block.timestamp: ", block.timestamp);
//    console.log("totalSeconds: ", totalSeconds);
//    console.log("totalSeconds / migratedNodes: ", totalSeconds / migratedNodes);
//    console.log("totalSeconds.div(migratedNodes): ", totalSeconds.div(migratedNodes));

    require(migratedNodes > 0, "nothing to migrate");

//    entityNodeDeactivatedCount[msg.sender] += migratedNodes;
    migrateNodes(msg.sender, 1, migratedNodes, totalSeconds / migratedNodes, rewardsDue, totalClaimed);
  }

  function migrateNodes(address _entity, uint _packType, uint _nodeCount, uint _lastPaidAt, uint _rewardsDue, uint _totalClaimed) public returns (bool) {
    emit Created(_entity, _packType, _nodeCount, false, block.timestamp, msg.sender, _lastPaidAt);

    return true;
  }
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