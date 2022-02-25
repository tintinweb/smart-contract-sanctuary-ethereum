// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import './interfaces/IReadFarm.sol';
import "@openzeppelin/contracts/math/SafeMath.sol";

contract BeliPoll {
    using SafeMath for uint256;

    event PollCreated(
        uint256 indexed id,
        address indexed proposer,
        string pollMsg,
        uint256 deadline
    );

    event PollOptionCreated(
        uint256 indexed pollId,
        uint256 indexed optionId,
        string pollOption
    );

    event PublicPollChanged(
        bool isPublic,
        address executor
    );

    event Voted(
        uint256 indexed id,
        uint256 indexed optionId,
        address voter,
        uint256 weight
    );

    struct Poll {
        uint256 sharePoolId;
        address proposer;
        string pollMsg;
        uint256 deadline;
        uint256 createdAt;
        uint256 optionsLength;
    }

    struct PollOption {
        string option;
        uint256 voteCount;
        uint256 weight;
    }

    Poll[] public polls;
    mapping(uint256 => PollOption[]) public pollOptions;
    mapping(uint256 => address[]) public voters;
    mapping(uint256 => mapping(address => bool)) public voteStatuses;
    mapping(uint256 => mapping(address => uint256)) public voteWeights;
    mapping(uint256 => uint256) public voteCount;
    IReadFarm public beliFarm;
    mapping(address => bool) public isProposer;
    bool public isPublicPropose;
    address public gov;
    uint256 private _id = 0;

    modifier onlyProposer() {
        if (!isPublicPropose) {
            require(isProposer[msg.sender] == true, 'not allowed to create proposal');
        }
        _;
    }

    constructor(IReadFarm _beliFarm) {
        require(address(_beliFarm) != address(0), 'invalid address');
        beliFarm = _beliFarm;
        isPublicPropose = false;
        isProposer[msg.sender] = true;
        gov = msg.sender;
    }

    function setPublicPropose(bool _isPublic) external {
        require(gov == msg.sender, 'unauthorized');
        isPublicPropose = _isPublic;
        emit PublicPollChanged(_isPublic, msg.sender);
    }

    function createPoll(
        uint256 _sharePoolId,
        string memory _pollMsg,
        string[] memory _options,
        uint256 _deadline
    ) external onlyProposer {
        require(_deadline > block.timestamp, 'invalid deadline');
        require(
            _options.length > 1,
            'should contains at least 2 options'
        );
        Poll memory _poll = Poll({
            pollMsg: _pollMsg,
            sharePoolId: _sharePoolId,
            deadline: _deadline,
            createdAt: block.timestamp,
            proposer: msg.sender,
            optionsLength: _options.length
        });
        polls.push(_poll);
        emit PollCreated(_id, msg.sender, _pollMsg, _deadline);
        uint256 i = 0;
        while (i < _options.length) {
            PollOption memory _opt = PollOption({
                option: _options[i],
                voteCount: 0,
                weight: 0
            });
            pollOptions[_id].push(_opt);
            emit PollOptionCreated(_id, i, _options[i]);
            i += 1;
        }
        _id = _id.add(1);
    }

    function vote(uint256 _pollId, uint256 _optionId, bool bypassShare) external {
        Poll storage poll = polls[_pollId];
        require(msg.sender != poll.proposer, 'cannot vote on own poll');
        require(voteStatuses[_pollId][msg.sender] != true, 'already voted');
        require(poll.deadline >= block.timestamp, 'stale poll');
        uint256 shares = IReadFarm(beliFarm).userInfo(poll.sharePoolId, msg.sender).shares;
        if (!bypassShare) {
            require(shares > 0, 'zero share has no weight');
        }
        PollOption storage option = pollOptions[_pollId][_optionId];
        option.voteCount = option.voteCount.add(1);
        option.weight = option.weight.add(shares);
        voters[_pollId].push(msg.sender);
        voteStatuses[_pollId][msg.sender] = true;
        voteWeights[_pollId][msg.sender] = shares;
        emit Voted(_pollId, _optionId, msg.sender, shares);
    }

    function getPollOptions(uint256 _pollId) external view returns (PollOption[] memory) {
        return pollOptions[_pollId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

struct UserInfo {
  uint256 shares;
  uint256 rewardDebt;
  uint256 rewardFeeReceiverDebt;
  uint256 rewardEarnDebt;
  uint256 lockedReward;
  uint256 lockedUntil;
  uint256 withdrawalFeeUntil;
}

interface IReadFarm {
  function userInfo(uint256 _pid, address _userAddress) external view returns(UserInfo memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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