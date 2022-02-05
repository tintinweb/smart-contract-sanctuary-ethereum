/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// File: contracts/math/SafeMath.sol



pragma solidity >=0.7.0 <0.9.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
// File: contracts/VoteSystem.sol



pragma solidity >=0.7.0 <0.9.0;


/** 
 * @title VoteSystem
 * @dev Implements voting process
 */
contract VoteSystem {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;

    bool private _voteFinished = false;

    struct Voter {
        bool voted; // if true, that person already voted
        uint256 vote; // index of the voted proposal
    }

    struct Proposal {
        string name;   // proposal name
        uint256 voteCount; // number of accumulated votes
        // address[] voters; // address of the voters
    }

    address public owner;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;
    string[] private _names;
    address[] public _countedVoters;
    address[] public _votersForWinningProposal;

    /**
     * Event for crowdsale extending
     * @param newClosingTime new closing time
     * @param prevClosingTime old closing time
     */
    event VotingExtended(uint256 prevClosingTime, uint256 newClosingTime);

    /**
     * @dev Reverts if not in voting period time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "Vote System is not open.");
        _;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "only owner of this contract can call this function.");
        _;
    }
    

    /** 
     * @dev Create a new ballot to choose one of 'proposalNames'.
     * @param proposalNames names of proposals
     */
    constructor(uint256 openingTimestamp, uint256 closingTimestamp, string[] memory proposalNames) payable {
        require(msg.value == 0.01 ether, "Need to deposit 0.1 ether to winner");
        owner = msg.sender;

        _openingTime = openingTimestamp;
        _closingTime = closingTimestamp;

        for (uint i = 0; i < proposalNames.length; i++) {
            // 'Proposal({...})' creates a temporary
            // Proposal object and 'proposals.push(...)'
            // appends it to the end of 'proposals'.
            Proposal memory temp;
            temp.name = proposalNames[i];
            temp.voteCount = 0;

            proposals.push(temp);

            _names.push(proposalNames[i]);
        }
    }

    function createProposal(string memory proposalName) public onlyOwner {
        Proposal memory temp;
        temp.name = proposalName;
        temp.voteCount = 0;

        proposals.push(temp);

        _names.push(proposalName);
    }
    
    /**
     * @return the opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @return true if the vote system is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the vote system is open has already elapsed.
     * @return Whether voting period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }

    /**
     * @dev Extend voting period.
     * @param newClosingTime voting period closing time
     */
    function extendClosingTime(uint256 newClosingTime) public onlyOwner {
        require(!hasClosed(), "Vote System already closed.");
        // solhint-disable-next-line max-line-length
        require(newClosingTime > _closingTime, "New closing time is before current closing time");

        emit VotingExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }

    function getProposalNames() public view returns (string[] memory) {
        return _names;
    }

    /**
     * @dev Give your vote to proposal 'proposals[proposal].name'.
     * @param proposal index of proposal in the proposals array
     */
    function vote(uint proposal) public onlyWhileOpen {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = proposal;

        // If 'proposal' is out of the range of the array,
        // this will throw automatically and revert all
        // changes.
        proposals[proposal].voteCount += 1;
        // proposals[proposal].voters.push(msg.sender);
        _countedVoters.push(msg.sender);
    }

    function getVoteCount(uint proposal) public view virtual returns(uint256) {
        return proposals[proposal].voteCount;
    }

    /** 
     * @dev Computes the winning proposal taking all previous votes into account.
     * @return winningProposal_ index of winning proposal in the proposals array
     */
    function getWinningProposal() public view
            returns (uint winningProposal_)
    {
        require(hasClosed(), "Voting is still open.");

        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function random(uint numOfVoters) private view returns (uint8) {
        return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % numOfVoters);
    }

    function finalize() public onlyOwner {
        require(hasClosed(), "Voting period has not closed.");
        require(!_voteFinished, "Vote System has concluded.");

        // get winning proposals
        uint winningProposal = getWinningProposal();

        // get votersForWinningProposal
        populateVotersForWinningProposal(winningProposal);

        // call random function to get a random index from the list of voters in the winning proposal
        uint numOfVoters = _votersForWinningProposal.length;

        uint index = random(numOfVoters);

        // give the voter the promised eth.
        address winner = _votersForWinningProposal[index];

        (bool success, ) = payable(winner).call{
            value: 0.01 ether
        }("");

        require(success);
    }

    function populateVotersForWinningProposal(uint winningProposal) private onlyOwner {
        for (uint i = 0; i < _countedVoters.length; i++) {
            address voterAddress = _countedVoters[i];
            Voter storage voter = voters[voterAddress];
            if (voter.vote == winningProposal) {
                _votersForWinningProposal.push(voterAddress);
            }
        }
    }
}