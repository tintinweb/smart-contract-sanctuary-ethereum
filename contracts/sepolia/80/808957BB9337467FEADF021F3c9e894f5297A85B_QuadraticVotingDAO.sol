pragma solidity ^0.8.4;
import './VisionTreasury.sol';

contract QuadraticVotingDAO {
    enum Status { Active, Passed, Failed, Executed }

    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 totalVotes;
        Status status;
        uint256 cycle;
    }
    uint256 public votesPerCycle; // Number of votes that each user have per cycle
    uint256 public proposalCount; // Number or available proposals
    uint256 public cycleDuration; // Duration of each cycle in seconds
    uint256 public currentCycle; // Current cycle number
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => uint256)) public proposalVotes;
    address public visionTreasuryAddress;

    // Events
    event ProposalCreated(uint256 proposalId, string title);
    event Voted(uint256 proposalId, address voter, uint256 voteCount);
    event ProposalStatusUpdated(uint256 proposalId, Status status);

    constructor(uint256 _cycleDurationMinutes, uint256 _votesPerCycle, address _visionTreasuryAddress) {
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

    function vote(uint256 _proposalId, uint256 _voteCount) external {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(_voteCount <= votesPerCycle, "Vote count exceeds the limit of 100");

        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == Status.Active, "Proposal is not active");

        // Calculate the square of the number of votes
        uint256 squaredVotes = _voteCount * _voteCount;

        // Subtract the previous votes from the total votes
        uint256 previousVotes = proposalVotes[_proposalId][msg.sender];
        proposal.totalVotes -= previousVotes;

        // Limit the new votes to the maximum of votesPerCycle
        uint256 newVotes = squaredVotes > votesPerCycle ? votesPerCycle : squaredVotes;

        // Update the user's votes for the proposal
        proposalVotes[_proposalId][msg.sender] = newVotes;

        // Add the new votes to the total votes
        proposal.totalVotes += newVotes - previousVotes;

        emit Voted(_proposalId, msg.sender, newVotes);
    }

    function executeProposal(uint256 _proposalId) internal {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == Status.Passed, "Proposal has not passed");

        // Execute the proposal if it has enough total votes
        if (proposal.totalVotes >= (proposalCount * proposalCount) / 2) {
            // Mark the proposal as executed
            proposal.status = Status.Executed;

            emit ProposalStatusUpdated(_proposalId, proposal.status);
        }
    }

    // This function should check if the cycle has finished!
    // Before this, we should call a function that will set the status 'PASSED' to all proposals!
    function executeAllProposals() external {
        for (uint256 i = 1; i <= proposalCount; i++) {
            Proposal storage proposal = proposals[i];
            if (proposal.status == Status.Passed) {
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
        uint256 remainingVotes = votesPerCycle; // Maximum votes allowed per user
        // Subtract the user's existing votes from the maximum limit
        for (uint256 i = 1; i <= proposalCount; i++) {
            remainingVotes -= proposalVotes[i][_voter];
        }
        return remainingVotes;
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
}

pragma solidity ^0.8.4;

contract VisionTreasury {
    address public owner;
    
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
    
    function withdraw() external {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        uint256 balance = address(this).balance;
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Transfer failed");      
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