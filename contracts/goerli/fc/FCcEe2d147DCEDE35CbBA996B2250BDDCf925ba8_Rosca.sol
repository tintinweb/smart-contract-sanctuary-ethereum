// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Rosca is Ownable {
    using SafeMath for uint256;

    uint256 private constant MAX_MEMBERS = 50;

    uint256 public constant MIN_CONTRIBUTION = 1000000 wei;

    uint256 public constant MAX_CONTRIBUTION = 10000000 wei;

    uint256 public constant MIN_ROUNDS = 2;

    uint256 public constant MAX_ROUNDS = 50;

    uint256 public constant FEE_PERCENTAGE = 1;

    uint256 public constant SECONDS_IN_DAY = 86400;

    uint256 public constant GRACE_PERIOD = 3 * SECONDS_IN_DAY; // 3 days

    uint256 public constant MAX_ADMIN_FEE = 10;

    uint256 public constant MAX_WINNER_FEE = 2;

    enum State { Setup, Open, Closed, Completed }

    struct Member {
        uint256 contribution;
        uint256 paidRounds;
        bool paid;
    }

    struct Round {
        uint256 roundNumber;
        uint256 contribution;
        uint256 adminFee;
        uint256 winnerFee;
        uint256 payout;
        uint256 startTime;
        uint256 gracePeriodEndTime;
        uint256 endTime;
        address[] members;
        mapping(address => Member) memberInfo;
        address winner;
        bool paidOut;
    }

    mapping(uint256 => Round) public rounds;

    uint256 public currentRound;

    uint256 public maxRounds;

    uint256 public maxMembers;

    uint256 public currentFeePercentage;

    uint256 public startTime;

    address public feeAccount;

    State public state;

    event RoundStarted(uint256 roundNumber, uint256 startTime, uint256 endTime);

    event MemberJoined(uint256 roundNumber, address member);

    event ContributionAdded(uint256 roundNumber, address member, uint256 amount);

    event RoundCompleted(uint256 roundNumber, address winner, uint256 payout);

    event ContractClosed(uint256 time);

    modifier onlyState(State _state) {
        require(state == _state, "Invalid state");
        _;
    }

     /**
     * @param _maxRounds Rounds the contract will run for
     * @param _maxMembers The number of members
     * @param _feePercentage The percentage of the contribution that will be used for admin fees
     * @param _feeAccount The account that will receive the admin fees
     */
    constructor(
        uint256 _maxRounds,
        uint256 _maxMembers,
        uint256 _feePercentage,
        address _feeAccount
    ) payable{
        require(_maxRounds >= MIN_ROUNDS && _maxRounds <= MAX_ROUNDS, "Invalid number of rounds");
        require(_maxMembers > 1 && _maxMembers <= MAX_MEMBERS, "Invalid number of members");
        require(_feePercentage <= MAX_ADMIN_FEE, "Invalid fee percentage");
        require(_feeAccount != address(0), "Invalid fee account");

        maxRounds = _maxRounds;
        maxMembers = _maxMembers;
        currentFeePercentage = _feePercentage;
        feeAccount = _feeAccount;

        state = State.Setup;
    }
    
     //The Reason I have private and public is startRound() is only called by the owner and _startRound() is called by startRound() and completeRound()
     function _startRound()  private{
        currentRound++;

        require(currentRound <= maxRounds, "Maximum rounds reached");

        Round storage round = rounds[currentRound];
        round.roundNumber = currentRound;
        round.contribution = MIN_CONTRIBUTION;
        round.adminFee = currentFeePercentage;
        round.winnerFee = MAX_WINNER_FEE;
        round.startTime = block.timestamp;
        round.gracePeriodEndTime = round.startTime + GRACE_PERIOD;
        round.endTime = round.startTime + GRACE_PERIOD.mul(maxMembers);
        //payout = contribution * maxmembers * (100 - adminFee - winnerFee) / 100
        round.payout = (round.contribution.mul(maxMembers).mul(100 - round.adminFee - round.winnerFee)).div(100); 
        round.winner = address(0);
        round.paidOut = false;

        state = State.Open;

        emit RoundStarted(currentRound, round.startTime, round.endTime);
    }

    function startRound() external onlyOwner onlyState(State.Setup){
        _startRound();
    }

    function joinRound() external payable onlyState(State.Open) {
        require(msg.value == MIN_CONTRIBUTION, "Invalid contribution amount");
        require(rounds[currentRound].memberInfo[msg.sender].contribution == 0, "You have already joined this round");
        require(rounds[currentRound].members.length < maxMembers, "Maximum number of members reached");

        Round storage round = rounds[currentRound];
        round.memberInfo[msg.sender].contribution = msg.value;
        round.memberInfo[msg.sender].paidRounds = 0;
        round.memberInfo[msg.sender].paid = false;
        round.members.push(msg.sender);

        emit MemberJoined(currentRound, msg.sender);

        if (round.members.length == maxMembers) {
            state = State.Closed;
            round.endTime = block.timestamp;
        }
    }

    function addContribution() external payable onlyState(State.Open) {
        require(msg.value == MIN_CONTRIBUTION, "Invalid contribution amount");
        require(rounds[currentRound].memberInfo[msg.sender].contribution > 0, "You have not joined this round");

        rounds[currentRound].memberInfo[msg.sender].contribution = rounds[currentRound].memberInfo[msg.sender].contribution.add(msg.value);

        emit ContributionAdded(currentRound, msg.sender, msg.value);
    }

    function completeRound(address payable winner) external onlyOwner onlyState(State.Closed) {
        Round storage round = rounds[currentRound];
        require(round.winner == address(0), "Round already completed");
        
        uint totalContribution = 0;
        for (uint i = 0; i < round.members.length; i++) {
            totalContribution = totalContribution.add(round.memberInfo[round.members[i]].contribution);
        }
        require(totalContribution >= round.payout, "Not enough contributions");

        round.winner = winner;
        round.paidOut = true;

        
      // Calculate payout and fees
        uint256 winnerPayout = round.payout.sub(round.contribution.mul(round.winnerFee).div(100));
        uint256 totalAdminFee = round.contribution.mul(round.adminFee).div(100);

        // Check contract balance
        require(address(this).balance >= winnerPayout.add(totalAdminFee), "Insufficient contract balance");

        // Transfer funds to winner and owner
        winner.transfer(winnerPayout);
        payable(feeAccount).transfer(totalAdminFee);

        if (currentFeePercentage < MAX_ADMIN_FEE) {
            currentFeePercentage++;
        }

        if (currentRound == maxRounds) {
            state = State.Completed;
            emit ContractClosed(block.timestamp);
        } else {
            _startRound();
        }

        emit RoundCompleted(currentRound, winner, round.payout);
    }

    function closeContract() external onlyOwner onlyState(State.Open) {
        require(currentRound > 0, "No rounds started");

        // Close current round if it is still open
        if (rounds[currentRound].endTime > 0 && rounds[currentRound].endTime > block.timestamp) {
            rounds[currentRound].endTime = block.timestamp;
        }

        state = State.Closed;

        emit ContractClosed(block.timestamp);
    }
}