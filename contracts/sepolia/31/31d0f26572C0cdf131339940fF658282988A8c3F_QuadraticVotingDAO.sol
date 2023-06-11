pragma solidity ^0.8.4;
import './VisionTreasury.sol';

contract QuadraticVotingDAO {
    enum Status { Active, Failed, Executed }

    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 totalVotes;
        Status status;
        uint256 cycle;
    }
    uint256 public voteCost; // Number of tokens that is paid per vote ( example, 1 )
    uint256 public votesPerCycle; // Number of votes that each user have per cycle
    uint256 public proposalCount; // Number or available proposals
    uint256 public cycleDuration; // Duration of each cycle in seconds
    uint256 public currentCycle; // Current cycle number
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => uint256)) public proposalVotes; // User's / voters cost for the proposal
    mapping(address => uint256) userVoteCost;
    address public visionTreasuryAddress;

    // Events
    event ProposalCreated(uint256 proposalId, string title);
    event Voted(uint256 proposalId, address voter, uint256 voteCount);
    event ProposalStatusUpdated(uint256 proposalId, Status status);

    constructor(uint256 _cycleDurationMinutes, uint256 _votesPerCycle, address _visionTreasuryAddress) {
        voteCost = 1;
        cycleDuration = _cycleDurationMinutes * 1 minutes; // Convert minutes to seconds
        votesPerCycle = _votesPerCycle; // Set votes that people can use per cycle
        visionTreasuryAddress = _visionTreasuryAddress;
        currentCycle = 1; // Start with cycle 1
    }

    function createProposal(string memory _title, string memory _description) external {
        proposalCount++;
        proposals[proposalCount] = Proposal(proposalCount, _title, _description, 0, Status.Active, currentCycle);

        emit ProposalCreated(proposalCount, _title);
    }

    function vote(uint256 _proposalId) external {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");

        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == Status.Active, "Proposal is not active");

        // Get current votes already casted to the proposal
        uint256 currentVoteWeight = proposal.totalVotes;

        // Get weight that will this vote add to the proposal
        uint256 nextVoteWeight = currentVoteWeight + 1;
        // this would cost 16x (5 * 5 - 3 * 3) instead of 25x the vote cost
        // Calculate the cost of the next vote
        uint256 nextVoteCost = (nextVoteWeight  * nextVoteWeight - currentVoteWeight * currentVoteWeight) * voteCost;

        // Check if the user has enough remaining votes for the cost
        require(nextVoteCost <= getRemainingVotes(msg.sender), "Insufficient remaining votes");

        // Update the user's cost
        userVoteCost[msg.sender] += nextVoteCost;

        // Update the user's cost for proposal
        proposalVotes[_proposalId][msg.sender] += nextVoteCost;

        // Add the new votes to the total votes
        proposal.totalVotes += 1;

        emit Voted(_proposalId, msg.sender, proposal.totalVotes);
    }

    // remove voteWeight for 1
    // return money to the user
    function decreaseVote(uint256 _proposalId) external {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");

        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == Status.Active, "Proposal is not active");

        // Subtract the previous votes from the total votes
        proposal.totalVotes -= 1;

        // Reduce the user's cost for the proposal
        uint256 costOfVote = proposalVotes[_proposalId][msg.sender];

        // Reduce the user's cost ( general )
        userVoteCost[msg.sender] -= costOfVote;

        proposalVotes[_proposalId][msg.sender] = 0;

        emit Voted(_proposalId, msg.sender, proposal.totalVotes);
    }

    function executeProposal(uint256 _proposalId) internal {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == Status.Active, "Proposal is not active");

        // Execute the proposal if it has enough total votes
        if (proposal.totalVotes >= (proposalCount * proposalCount) / 2) {
            // Mark the proposal as executed
            proposal.status = Status.Executed;

            emit ProposalStatusUpdated(_proposalId, proposal.status);
        }
    }

    // This function should check if the cycle has finished!
    function executeAllProposals() external {
        for (uint256 i = 1; i <= proposalCount; i++) {
            Proposal storage proposal = proposals[i];
            if (proposal.status == Status.Active) {
                executeProposal(i);
            }
        }
        // Transfer funds from VisionTreasury contract to this contract
        VisionTreasury treasury = VisionTreasury(visionTreasuryAddress);
        treasury.withdraw();

    }

    function startNewCycle() external {
        require(block.timestamp >= currentCycle * cycleDuration, "It's not yet time to start a new cycle");
        currentCycle++;
    }

    function updateProposalStatus(uint256 _proposalId, Status _status) external {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status != Status.Executed, "Cannot update status of an executed proposal");
        proposal.status = _status;

        emit ProposalStatusUpdated(_proposalId, proposal.status);
    }

    function getRemainingVotes(address _voter) public view returns (uint256) {
        return 100 - userVoteCost[_voter];
    }

    function getRemainingCycleTime() public view returns (uint256) {
        uint256 cycleEndTime = currentCycle * cycleDuration;
        if (block.timestamp >= cycleEndTime) {
            return 0;
        } else {
            return cycleEndTime - block.timestamp;
        }
    }

    function getAllProposals() public view returns (Proposal[] memory) {
        Proposal[] memory allProposals = new Proposal[](proposalCount);
        for (uint256 i = 1; i <= proposalCount; i++) {
            allProposals[i - 1] = proposals[i];
        }
        return allProposals;
    }
    function getVotesByUser(address _voter) public view returns (uint256) {
        uint256 previousVotes = 0;
        // Iterate through all proposals
        for (uint256 i = 1; i <= proposalCount; i++) {
            // If the _voter has voted for the proposal, increment previousVotes by 1
            if (proposalVotes[i][_voter] > 0) {
                previousVotes += 1;
            }
        }

        // Return the total number of votes made by the _voter
        return previousVotes;
    }
}

pragma solidity ^0.8.4;

contract VisionTreasury {
    address owner;
    address payable public visionDAO;
    
    constructor() {
        owner = msg.sender;
    }
    // Events
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);
    
    function deposit() external payable {
        // Accept incoming Ether and add it to the treasury
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw() external payable {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        uint256 balance = address(this).balance;
        visionDAO.transfer(balance);
        emit Withdrawal(owner, balance);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function setOwner(address _owner) external {
        require(msg.sender == owner, "Only the owner can set a new owner");
        owner = _owner;
    }
}