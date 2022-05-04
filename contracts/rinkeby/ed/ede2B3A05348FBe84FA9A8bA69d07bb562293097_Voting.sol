/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;



// Part: OpenZeppelin/[email protected]/Context

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/Ownable

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: voting.sol

/*
VOTING SYSTEM
1 - User can run to be a candidate (a user can only run once per voting period)
1 - User can vote for a candidate (only one vote and the candidate needs to isCandidate)
2 - User can vote for a candidate (only one vote per user)
3 - User can fund a candidate if a candidate has at least 5 votes (minimum 0.01 ETH)
4 - Candidate can delegate vote and funding to another candidate (Can only delegate once if has votes already, cannot receive more votes)
5 - Admin can close the voting period and the winner is decided by the number of votes
6 - user who funded non-elected candidates can claim their money back
*/
contract Voting is Ownable {
    address payable public electedCandidate;
    address[] public candidates;
    uint256 public constant MIN_FUNDING_AMOUNT = 0.01 * 10**18;
    uint256 public MIN_NUMBER_OF_VOTES;
    mapping(address => address) public voterToCandidate;
    mapping(address => uint256) public voterToAmountFunded;

    enum VOTING_STATE {
        OPEN,
        CLOSED,
        ELECTING_CANDIDATE,
        CLAIM_PERIOD
    }
    VOTING_STATE public voting_state;

    struct CandidateProfile {
        bool isCandidate;
        uint256 fundedAmount;
        uint256 numberOfVotes;
    }
    mapping(address => CandidateProfile) public candidateToProfile;

    event VotingOpened(uint256 min_number_of_votes);
    event NewCandidate(address indexed user);
    event NewVote(address indexed voter, address indexed candidate);
    event Funded(
        address indexed voter,
        address indexed candidate,
        uint256 amountFunded
    );
    event Delegated(
        address indexed delegater,
        address indexed delegatee,
        uint256 amountFunded,
        uint256 numberOfVotes
    );
    event CandidateElected(
        address indexed candidate,
        uint256 amountFunded,
        uint256 numberOfVotes
    );
    event CandidateClaim(address indexed candidate, uint256 amount);
    event VoterClaim(address indexed voter, uint256 amount);

    constructor(uint256 _min_number_of_votes) public {
        voting_state = VOTING_STATE.CLOSED;
        MIN_NUMBER_OF_VOTES = _min_number_of_votes;
    }

    function startVotingPeriod() public onlyOwner {
        // The owner can start the voting period if the voting has not already started
        require(
            voting_state == VOTING_STATE.CLOSED,
            "A voting period is already on-going"
        );
        voting_state = VOTING_STATE.OPEN;
        emit VotingOpened(MIN_NUMBER_OF_VOTES);
    }

    function runAsCandidate() public {
        // Voting period needs to be open and the users shouldn't already be a candidate
        require(
            voting_state == VOTING_STATE.OPEN,
            "The voting period has not started"
        );
        require(
            candidateToProfile[msg.sender].isCandidate == false,
            "You are already running as a candidate"
        );
        candidateToProfile[msg.sender] = CandidateProfile(true, 0, 0);
        candidates.push(msg.sender);
        emit NewCandidate(msg.sender);
    }

    function vote(address _candidate) public {
        require(
            voting_state == VOTING_STATE.OPEN,
            "The voting period has not started"
        );
        require(
            voterToCandidate[msg.sender] == address(0),
            "You have already voted"
        );
        require(
            candidateToProfile[_candidate].isCandidate == true,
            "You are voting for someone who is not a candidate"
        );

        voterToCandidate[msg.sender] = _candidate;
        candidateToProfile[_candidate].numberOfVotes += 1;
        emit NewVote(msg.sender, _candidate);
    }

    // User can fund a candidate if a candidate has at least 5 votes (minimum 0.01 ETH)
    function fund(address _candidate) public payable {
        require(
            voting_state == VOTING_STATE.OPEN,
            "The voting period has not started"
        );
        require(
            candidateToProfile[_candidate].isCandidate == true,
            "You are funding for someone who is not a candidate"
        );
        require(
            candidateToProfile[_candidate].numberOfVotes >= MIN_NUMBER_OF_VOTES,
            "The candidate needs at least 5 votes to receive funding"
        );
        require(
            msg.value >= MIN_FUNDING_AMOUNT,
            "Your funding amount is below the minimum 0.01 ETH"
        );
        require(
            voterToCandidate[msg.sender] == _candidate,
            "You are funding a candidate you didn't vote for"
        );

        voterToAmountFunded[msg.sender] += msg.value;
        candidateToProfile[_candidate].fundedAmount += msg.value;
        emit Funded(msg.sender, _candidate, msg.value);
    }

    modifier onlyCandidate() {
        require(
            candidateToProfile[msg.sender].isCandidate == true,
            "You are not a candidate"
        );
        _;
    }

    // 4 - Candidate can delegate vote and funding to another candidate (Can only delegate once if has votes already, cannot receive more votes)
    function delegate(address _candidate) public onlyCandidate {
        require(
            voting_state == VOTING_STATE.OPEN,
            "The voting period has not started"
        );
        require(
            candidateToProfile[_candidate].isCandidate == true,
            "You are delegating to someone who is not a candidate"
        );
        require(
            candidateToProfile[_candidate].numberOfVotes >= MIN_NUMBER_OF_VOTES,
            "The delegate candidate needs at least 5 votes to be delegated to"
        );
        candidateToProfile[_candidate].numberOfVotes += candidateToProfile[
            msg.sender
        ].numberOfVotes;

        // Saving info for the event
        uint256 numberOfVotesTemp = candidateToProfile[msg.sender]
            .numberOfVotes;
        uint256 fundedAmountTemp = candidateToProfile[msg.sender].fundedAmount;
        // Re-initializing candidate info
        candidateToProfile[msg.sender].numberOfVotes = 0;
        candidateToProfile[msg.sender].isCandidate = false;

        if (candidateToProfile[msg.sender].fundedAmount > MIN_FUNDING_AMOUNT) {
            candidateToProfile[_candidate].fundedAmount += candidateToProfile[
                msg.sender
            ].fundedAmount;
            candidateToProfile[msg.sender].fundedAmount = 0;
        }

        emit Delegated(
            msg.sender,
            _candidate,
            fundedAmountTemp,
            numberOfVotesTemp
        );
    }

    // The Candidate with most votes wins. If there's a similar number of votes for multiple candidates,
    // the candidate with the most funding between those candidates wins. If there's similar amount of funding,
    // the candidate who has been running for the longest time wins
    function electCandidate() public onlyOwner returns (address) {
        // The owner can start the voting period if the voting has not already started
        require(
            voting_state == VOTING_STATE.OPEN,
            "The voting period has not started"
        );
        require(candidates.length > 0, "No Candidate running");
        require(
            electedCandidate == address(0),
            "A candidate has already been elected"
        );

        uint256 maxVotes;
        uint256 maxfunding;
        address winner;

        voting_state = VOTING_STATE.ELECTING_CANDIDATE;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (
                (candidateToProfile[candidates[i]].isCandidate &&
                    candidateToProfile[candidates[i]].numberOfVotes >
                    maxVotes) || winner == address(0)
            ) {
                maxVotes = candidateToProfile[candidates[i]].numberOfVotes;
                maxfunding = candidateToProfile[candidates[i]].fundedAmount;
                winner = candidates[i];
            } else if (
                candidateToProfile[candidates[i]].numberOfVotes == maxVotes &&
                candidateToProfile[candidates[i]].fundedAmount > maxfunding
            ) {
                maxfunding = candidateToProfile[candidates[i]].fundedAmount;
                winner = candidates[i];
            }
        }
        electedCandidate = payable(winner);
        voting_state = VOTING_STATE.CLAIM_PERIOD;
        emit CandidateElected(electedCandidate, maxfunding, maxVotes);
    }

    function ElectedCandidateFundClaim() public payable onlyCandidate {
        // The owner can start the voting period if the voting has not already started
        require(
            voting_state == VOTING_STATE.CLAIM_PERIOD,
            "The election period hasn't started yet"
        );
        require(
            electedCandidate != address(0),
            "No candidate has been elected yet"
        );
        require(
            msg.sender == electedCandidate,
            "You cannot claim funding since you are not the elected candidate"
        );
        // Zero the balance before the transfer to prevent re-entrancy
        uint256 amount = candidateToProfile[msg.sender].fundedAmount;
        candidateToProfile[msg.sender].fundedAmount = 0;
        msg.sender.transfer(amount);
        emit CandidateClaim(msg.sender, amount);
    }

    // Users who have funded non-elected candidates can claim their funding back
    function voterFundClaim() public payable {
        // The owner can start the voting period if the voting has not already started
        require(
            voting_state == VOTING_STATE.CLAIM_PERIOD,
            "The claiming period isn't open"
        );
        require(
            electedCandidate != address(0),
            "No candidate has been elected yet"
        );
        require(
            voterToCandidate[msg.sender] != electedCandidate,
            "You cannot claim your funds since your candidate has been elected"
        );
        require(
            voterToAmountFunded[msg.sender] > 0,
            "You haven't funded your candidate"
        );

        // Zero the balance before the transfer to prevent re-entrancy
        uint256 amount = voterToAmountFunded[msg.sender];
        voterToAmountFunded[msg.sender] = 0;
        msg.sender.transfer(amount);
        emit VoterClaim(msg.sender, amount);
    }
}