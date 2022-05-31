pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Voting is Ownable {
    using SafeMath for uint256;

    uint256 private constant VOTING_DURATION_SEC = 3 * 24 * 60 * 60;
    uint256 private constant VOTING_FEE = 0.01 ether;

    /*
     * Structure to hold information about election round
     */
    struct Election {
        uint256 startTime; // time when election was created
        string name; // election's name
        bool exists; // check existing inside blockchain
        bool rewardDistributed; // is reward already distributed over winners
        mapping(address => uint256) candidatesCount; // candidates and votes
        address[] candidates; // candidates list
        mapping(address => bool) votedElectorates; // check that candidate votes
        address[] electorates; // electorate list
    }

    // emits when electorate votes into electionName for candidate
    event VoteForEvent(
        string electionName,
        address electorate,
        address candidate
    );
    // emits when money distribution happens
    event DistributeReward(
        uint256 winnersCount,
        uint256 winnerReward,
        uint256 taxes
    );
    // marks that ether transfer happens
    event Received(address sender, uint256 amount);

    mapping(string => Election) private electionsMap;
    string[] private electionsList;

    uint256 private unallocatedTaxMoney; // non distributed tax money

    constructor() {
        unallocatedTaxMoney = 0;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier electionExists(string memory electionName) {
        require(electionsMap[electionName].exists, "Election not found");
        _;
    }

    modifier electionStillGoing(string memory electionName) {
        require(
            timeInElectionRange(electionsMap[electionName].startTime),
            "Election is over"
        );
        _;
    }

    modifier electionFinished(string memory electionName) {
        require(
            !timeInElectionRange(electionsMap[electionName].startTime),
            "Election is active"
        );
        _;
    }

    function createElection(string memory electionName) public onlyOwner {
        require(!electionsMap[electionName].exists, "Election already exists");
        Election storage newElection = electionsMap[electionName];
        newElection.exists = true;
        newElection.rewardDistributed = false;
        newElection.name = electionName;
        newElection.startTime = block.timestamp;
        electionsList.push(electionName);
    }

    function voteForCandidate(string memory electionName, address candidate)
        public
        payable
        electionExists(electionName)
        electionStillGoing(electionName)
    {
        Election storage currentElection = electionsMap[electionName];

        require(
            currentElection.votedElectorates[msg.sender] == false,
            "Elector already voted"
        );
        require(msg.value == VOTING_FEE, "Incorrect ethers amount");
        address payable contractAddress = payable(address(this));
        contractAddress.transfer(VOTING_FEE);

        currentElection.electorates.push(msg.sender);
        currentElection.votedElectorates[msg.sender] = true;

        if (currentElection.candidatesCount[candidate] == 0) {
            currentElection.candidates.push(candidate);
        }
        currentElection.candidatesCount[candidate] += 1;
        emit VoteForEvent(electionName, msg.sender, candidate);
    }

    function finishElection(string memory electionName)
        public
        payable
        electionExists(electionName)
        electionFinished(electionName)
    {
        Election storage election = electionsMap[electionName];
        require(!election.rewardDistributed, "Reward already distributed");
        election.rewardDistributed = true;
        if (election.electorates.length == 0) {
            emit DistributeReward(0, 0, 0);
            return;
        }
        address[] memory winners;
        uint256 maxVoteCount;
        (winners, maxVoteCount) = getFavorites(electionName);
        uint256 worth = election.electorates.length * VOTING_FEE;

        uint256 perAddressReward;
        uint256 taxes;
        (perAddressReward, taxes) = distributeReward(winners.length, worth);
        unallocatedTaxMoney = unallocatedTaxMoney.add(taxes);
        for (uint256 i = 0; i < winners.length; i++) {
            address winner = winners[i];
            payable(winner).transfer(perAddressReward);
        }
        emit DistributeReward(winners.length, perAddressReward, taxes);
    }

    /*
     * Calculates how many each winner will receive rewards, and how much taxes will the owner receive
     *
     * @param winner -- number of winners
     * @param amount -- amount of donated ethers
     * @return -- tuple with: 1) ether's amount which will receive each winner, 2) taxes for the owner
     */
    function distributeReward(uint256 winner, uint256 amount)
        public
        pure
        returns (uint256, uint256)
    {
        require(winner > 0, "Winners are absent");
        require(amount > 0, "Amount can't be empty");

        uint256 taxes = amount / 10;
        // takes worth's 10% only

        // because fractional math is computer's bottleneck
        // we can't just write amount * 0.9 -- we'll lose some ethers
        // we need to use sub command
        uint256 reward = amount - taxes;

        uint256 perAddressReward = reward / winner;
        taxes += reward - perAddressReward * winner;
        // final taxes
        // if we'll use amount % 10 and amount % 90 / winner -- some worth might be stuck in the contract
        // so we carefully handle all places where we may lose ethers
        // and because amount is in ether, we won't work with small values
        return (perAddressReward, taxes);
    }

    function getTaxes() public payable onlyOwner {
        uint256 moneyToTransfer = unallocatedTaxMoney;
        unallocatedTaxMoney = 0;
        payable(owner()).transfer(moneyToTransfer);
    }

    /*
     * Returns addresses with maximum votes for this election
     *
     * @param electionName -- election to get favorites
     * @return -- tuple with: 1) addresses -- which have maximum vote count, 2) max vote
     */
    function getFavorites(string memory electionName)
        public
        view
        electionExists(electionName)
        returns (address[] memory, uint256)
    {
        uint256 maxFavoritesCount;
        uint256 maxCount;
        (maxFavoritesCount, maxCount) = getLargestVotesFor(electionName);
        address[] memory favoriteCandidates = new address[](maxFavoritesCount);

        mapping(address => uint256) storage candidatesCount = electionsMap[
            electionName
        ].candidatesCount;
        address[] storage candidates = electionsMap[electionName].candidates;

        uint256 idx = 0;
        for (uint256 i = 0; i < candidates.length; i++) {
            address candidate = candidates[i];
            if (candidatesCount[candidate] == maxCount) {
                favoriteCandidates[idx] = candidate;
                idx += 1;
            }
        }
        return (favoriteCandidates, maxCount);
    }

    /*
    * Returns information about election
    *
    * @param electionName -- election to fetch information
    * @return -- tuple with: 1) electionName, 2) start time, 3) is election still active,
    4) is reward distributed, 5) list of electorates, 6) list of candidates, 7) list of corresponded votes for candidate
    */
    function getElectionInfo(string memory electionName)
        public
        view
        electionExists(electionName)
        returns (
            string memory,
            uint256,
            bool,
            bool,
            address[] memory,
            address[] memory,
            uint256[] memory
        )
    {
        Election storage election = electionsMap[electionName];
        uint256[] memory candidatesCount = new uint256[](
            election.candidates.length
        );
        for (uint256 i = 0; i < candidatesCount.length; i++) {
            candidatesCount[i] = election.candidatesCount[
                election.candidates[i]
            ];
        }
        return (
            electionName,
            election.startTime,
            timeInElectionRange(election.startTime),
            election.rewardDistributed,
            election.electorates,
            election.candidates,
            candidatesCount
        );
    }

    /*
     * Forbids transfer ownership
     */
    function transferOwnership(address newOwner)
        public
        virtual
        override
        onlyOwner
    {
        revert("Changing the owner is forbidden");
    }

    function getElections() public view returns (string[] memory) {
        return electionsList;
    }

    function timeInElectionRange(uint256 startTime)
        private
        view
        returns (bool)
    {
        return
            startTime <= block.timestamp &&
            block.timestamp <= (startTime + VOTING_DURATION_SEC);
    }

    /*
     * Returns maximum count of votes and candidates count who have this votes
     */
    function getLargestVotesFor(string memory electionName)
        private
        view
        electionExists(electionName)
        returns (uint256, uint256)
    {
        uint256 maxCount = 0;
        uint256 maxFavoritesCount = 0;
        mapping(address => uint256) storage candidatesCount = electionsMap[
            electionName
        ].candidatesCount;
        address[] storage candidates = electionsMap[electionName].candidates;

        for (uint256 i = 0; i < candidates.length; i++) {
            address candidate = candidates[i];
            if (candidatesCount[candidate] == maxCount) {
                maxFavoritesCount += 1;
            }
            if (candidatesCount[candidate] > maxCount) {
                maxCount = candidatesCount[candidate];
                maxFavoritesCount = 1;
            }
        }
        return (maxFavoritesCount, maxCount);
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