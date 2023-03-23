// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract GovernorAlpha is Initializable {
    /// @notice The name of this contract
    string public constant name = "ASTRA Governor Alpha";
    
    uint256 public constant MULTIPLIER_DECIMAL = 10000000000000;
    
    uint private quorumVote;
    
    uint private minVoterCount;
    
    uint private minProposalTimeIntervalSec;
    
    uint public lastProposalTimeIntervalSec;

    uint256 public proposalTokens;

    uint256 public lastProposal;

    uint256 public stakeVault;

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public view returns (uint) { return quorumVote; }

    /// @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint) { return 10; } // 10 actions

    /// @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() public pure returns (uint) { return 1; } // 1 block

    /// @notice The duration of voting on a proposal, in blocks
    function votingPeriod() public pure returns (uint) { return 100; } // ~7 days in blocks (assuming 15s blocks)
    
    /// @notice Minimum number of voters
    function minVotersCount() external view returns (uint) { return minVoterCount; }

    /// @notice The address of the ASTR Protocol Timelock
    TimelockInterface public timelock;

    /// @notice The address of the ASTR governance token
    ASTRInterface public ASTR;

    /// @notice The total number of proposals
    uint public proposalCount;

    /// @notice The total number of targets.
    uint256 public totalTarget;
    
    // @notice voter info 
    struct VoterInfo {
        /// @notice Map voter address for proposal
        mapping (address => bool) voterAddress;
        /// @notice Governors votes
        uint voterCount;
        /// @notice Governors votes
        uint256 governors;
    }

    struct Proposal {
        /// @notice ASTRque id for looking up a proposal
        uint id;

        /// @notice Creator of the proposal
        address proposer;

        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;

        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;

        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;

        /// @notice The ordered list of function signatures to be called
        string[] signatures;

        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;

        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint endBlock;

        /// @notice Current number of votes in favor of this proposal
        uint forVotes;

        /// @notice Current number of votes in opposition to this proposal
        uint againstVotes;

        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;

        /// @notice Flag marking whether the proposal has been executed
        bool executed;

        /// @notice Check is fundamenal changes
        bool fundamentalchanges;

        /// @notice Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    /// @notice Track Time proposal is created.
    mapping(uint256 => uint256)public proposalCreatedTime;

    /// @notice Track total proposal user voted on.
    mapping(address => uint256)public propoasalVoted;

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;

        /// @notice Whether or not the voter supports the proposal
        bool support;

        /// @notice The number of votes the voter had, which were cast
        uint votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }
    
    /// @notice Chef Contract address for getting top stakers
    address public chefAddress;

    /// @notice The official record of all voters with id
    mapping (uint => VoterInfo) public votersInfo;

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    mapping (uint256 => bool) public isProposalQueued;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint id, uint eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    function initialize(address timelock_, address ASTR_,address _chef) external initializer {
        require(timelock_ != address(0), "Zero Address");
        require(ASTR_ != address(0), "Zero Address");
        require(_chef != address(0), "Zero Address");
        timelock = TimelockInterface(timelock_);
        ASTR = ASTRInterface(ASTR_);
        chefAddress = _chef;
        quorumVote = 40e18;
        minVoterCount = 1;
        minProposalTimeIntervalSec = 1 days;
        proposalTokens = 5000000000 * 10**18;
        stakeVault = 6 ;
        totalTarget = 3;
    }
    /**
     * @notice Update Quorum Value
     * @param _quorumValue New quorum Value.
	 * @dev Update Quorum Votes
     */
    function updateQuorumValue(uint256 _quorumValue) external {
        require(msg.sender == address(timelock), "Call must come from Timelock.");
        quorumVote = _quorumValue; 
    }

    /**
     * @notice Update Stake Vault
     * @param _stakeVault New stake vault value.
	 * @dev Update stake vault value
     */
    function updateStakeVault(uint256 _stakeVault) external {
        require(msg.sender == address(timelock), "Call must come from Timelock.");
        stakeVault = _stakeVault; 
    }

    /**
     * @notice Update Min Voter Value
     * @param _minVotersValue New minimum Votes Value.
	 * @dev Update nummber of minimum voters
     */
    
    function updateMinVotersValue(uint256 _minVotersValue) external {
        require(msg.sender == address(timelock), "Call must come from Timelock.");
        minVoterCount = _minVotersValue; 
    }
    
     /**
     * @notice update Minimum  Proposal Time Interval Sec.
     * @param _minProposalTimeIntervalSec New minimum proposal interval.
	 * @dev Update number of minimum Time for Proposal.
     */
    function updateMinProposalTimeIntervalSec(uint256 _minProposalTimeIntervalSec) external {
        require(msg.sender == address(timelock), "Call must come from Timelock.");
        minProposalTimeIntervalSec = _minProposalTimeIntervalSec; 
    }

     /**
     * @notice update Minimum  Proposal Tokens required.
     * @param _proposalTokens New minimum tokens amount.
	 * @dev Update number of minimum Astra required.
     */

    function updateProposalTokens(uint256 _proposalTokens) external {
        require(msg.sender == address(timelock), "Call must come from Timelock.");
        proposalTokens = _proposalTokens; 
    }
    
    /**
     * @notice Update number of target.
     * @param _totalTarget New maxium target.
	 * @dev Update number of maxium target.
     */

    function updateTotalTarget(uint256 _totalTarget) external {
        require(msg.sender == address(timelock), "Call must come from Timelock.");
        totalTarget = _totalTarget; 
    }

    function _acceptAdmin() external {
        timelock.acceptAdmin();
    }

    /**
     * @notice Create a new Proposal
     * @param targets Target contract whose functions will be called.
     * @param values Amount of ether required for function calling.
     * @param signatures Function that will be called.
     * @param calldatas Paramete that will be passed in function paramt in bytes format.
     * @param description Description about proposal.
     * @param _fundametalChanges Check if proposal involved fundamental changes or not.
	 * @dev Create new proposal. Her only top stakers can create proposal and Need to submit 50000000 Astra tokens to create proposal
     */
    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description, bool _fundametalChanges) public returns (uint) {
        // Check if entered configuration is correct or not.
        require(targets.length <= totalTarget, "GovernorAlpha::propose: Target must be in range");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorAlpha::propose: proposal function information arity mismatch");
        require(targets.length != 0, "GovernorAlpha::propose: must provide actions");
        require(targets.length <= proposalMaxOperations(), "GovernorAlpha::propose: too many actions");
        // Deposit some Astra tokens to create proposal.
        (bool transferStatus) = depositToken(msg.sender, address(this), proposalTokens);
        stakeToken(msg.sender, proposalTokens);
        // Check transfer status
        require(transferStatus == true, "GovernorAlpha::propose: need to transfer some tokens on contract to create proposal");
        // Check the minimum proposal that can be created in a single day.
        require(add256(lastProposalTimeIntervalSec, sub256(minProposalTimeIntervalSec, mod256(lastProposalTimeIntervalSec, minProposalTimeIntervalSec))) < block.timestamp, "GovernorAlpha::propose: Only one proposal can be create in one day");

        // Check if caller has active proposal or not. If so previous proposal must be accepted or failed first.
        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "GovernorAlpha::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "GovernorAlpha::propose: one live proposal per proposer, found an already pending proposal");
        }
        uint256 returnValue = setProposalDetail( targets, values, signatures, calldatas, description, _fundametalChanges);
        return returnValue;
    }

    /**
	 * @dev Internal function for creating proposal parameter details is similar to propose functions.
     */

    function setProposalDetail(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description, bool _fundametalChanges)internal returns (uint){
        // Set voting time for proposal.
        uint startBlock = add256(block.number, votingDelay());
        uint endBlock = add256(startBlock, votingPeriod());
        proposalCount = add256(proposalCount,1);
        Proposal storage newProposal = proposals[proposalCount];

        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.eta = 0;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.canceled = false;
        newProposal.executed = false;
        newProposal.fundamentalchanges =_fundametalChanges;

        // Update details for proposal.
        proposalCreatedTime[proposalCount] = block.number;

        latestProposalIds[newProposal.proposer] = newProposal.id;
        lastProposalTimeIntervalSec = block.timestamp;
        
        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return newProposal.id;
    }

    /**
     * @notice Deposit Astra tokens.
     * @param sender Sender Address
     * @param recipient Reciever Address
     * @param amount Amount to spent
	 * @dev Deposit Astra token at time new proposal
     */

    function depositToken(address sender, address recipient, uint256 amount) internal returns(bool) {
        bool transferStatus = ASTR.transferFrom(sender, recipient, amount);
        return transferStatus;
    }
    /**
     * @notice Stake Astra tokens.
     * @param sender Sender Address
     * @param amount Amount to spent
	 * @dev Stake Astra token at time new proposal
     */

    function stakeToken(address sender, uint256 amount) internal {
        ASTR.approve(address(chefAddress),amount);
        ChefInterface(chefAddress).depositFromOtherContract(amount,stakeVault,sender);
    }


    /**
     * @notice Queue your proposal.
     * @param proposalId Proposal Id.
	 * @dev Once proposal is accepted put them in queue over timelock. Proposal can only be put in queue if it is succeeded and crossed minimum voter.
     */

    function queue(uint proposalId) external {
        require(state(proposalId) == ProposalState.Succeeded, "GovernorAlpha::queue: proposal can only be queued if it is succeeded");
        require(votersInfo[proposalId].voterCount >= minVoterCount, "GovernorAlpha::queue: proposal require atleast min governers quorum");
        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, timelock.delay()); 
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        isProposalQueued[proposalId] = true;
        emit ProposalQueued(proposalId, eta);
    }

     /**
	 * @dev Internal function called by queue to check if proposal can be queued or not.
     */

    function _queueOrRevert(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorAlpha::_queueOrRevert: proposal action already queued at eta");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    /**
     * @notice Execute your proposal.
     * @param proposalId Proposal Id.
	 * @dev Once queue time is over you can execute proposal fucntion from here.
     */

    function execute(uint256 proposalId) external payable {
        require(state(proposalId) == ProposalState.Queued, "GovernorAlpha::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value : proposal.values[i]}(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        lastProposal = proposalId;
        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Cancel your proposal.
     * @param proposalId Proposal Id.
	 * @dev If proposal is not executed you can cancel that proposal from here.
     */

    function cancel(uint proposalId) external {
        ProposalState _state = state(proposalId);
        require(_state != ProposalState.Executed, "GovernorAlpha::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];

        require(msg.sender == proposal.proposer, "GovernorAlpha::cancel: Only creator can cancel");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Get Actions details
     * @param proposalId Proposal Id.
	 * @dev Get the details of Functions that will be called.
     */

    function getActions(uint proposalId) external view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

        /**
     * @notice Get Receipt
     * @param proposalId Proposal Id.
     * @param voter Voter address
	 * @dev Get the details of voted on a particular proposal for a user.
     */

    function getReceipt(uint proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function getVotingStatus(address _voter) external view returns(bool) {
        return (propoasalVoted[_voter] == proposalCount);
    }
    /**
     * @notice Get state of proposal
     * @param proposalId Proposal Id.
	 * @dev Check the status of proposal
     */

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        // Check min governor vote required. Each proposal require some minimum proposal based on its type.
        // For testnet and testing these values are set to lower.
        bool checkifMinGovenor;
        bool checkFastVote = checkfastvote(proposalId);
        uint256 percentage = 10;
        // Check if proposal is fundamental or not. For both different requirment is set.
        // This is used to check if proposal passed minimum governor barrier.
        if(proposal.fundamentalchanges){
            percentage = 20;
            if(votersInfo[proposalId].governors>=3){
                checkifMinGovenor = true;
            }else{
                checkifMinGovenor = false;
            }
        }else{
            if(votersInfo[proposalId].governors>=2){
                checkifMinGovenor = true;
            }else{
                checkifMinGovenor = false;
            }
        }
        // Check if proposal is fast vote or not. Only for non fundamental proposal.
        if(checkFastVote && checkifMinGovenor && !isProposalQueued[proposalId]){
            return ProposalState.Succeeded;
        }
        else if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            // Check if proposal matched all the conditions for acceptance.
            if(checkifMinGovenor){
                    if(proposal.againstVotes==0){
                        return ProposalState.Succeeded;
                    }else{
                    uint256 voteper=  div256(mul256(sub256(proposal.forVotes, proposal.againstVotes),100), proposal.againstVotes);
                     if(voteper>percentage){
                        return ProposalState.Succeeded;
                    }
                    }
            }
            return ProposalState.Defeated;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

     /**
     * @notice Get fast vote state of proposal
     * @param proposalId Proposal Id.
	 * @dev Check the fast vote status of proposal
     */

    function checkfastvote(uint proposalId) public view returns (bool){
        require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        uint256 oneday = add256(proposalCreatedTime[proposalId],6500);
        uint256 percentage = 10;
        bool returnValue;
        // Check if proposal is non fundamental and block number is less than for 1 day since the proposal created.
        if(proposal.fundamentalchanges==false && block.number <= oneday){
            // Check if all conditions are matched or not.
            if (block.number <= proposal.endBlock && proposal.againstVotes <= proposal.forVotes && proposal.forVotes >= quorumVotes()) {
                    // uint256 voteper= proposal.forVotes.sub(proposal.againstVotes).mul(100).div(proposal.againstVotes);
                    if(proposal.againstVotes==0){
                        returnValue = true;
                    }else{
                        uint256 voteper=  div256(mul256(sub256(proposal.forVotes, proposal.againstVotes),100), proposal.againstVotes);
                    if(voteper>percentage){
                        returnValue = true;
                    }
                    }
            }
        }
        return returnValue;
    }

     /**
     * @notice Vote on any proposal
     * @param proposalId Proposal Id.
     * @param support Bool value for your vote
	 * @dev Vote on any proposal true for acceptance and false for defeat.
     */

    function castVote(uint proposalId, bool support) external {
        _castVote(msg.sender, proposalId, support);
    }

    /**
     * @notice Vote on any proposal
     * @param proposalId Proposal Id.
     * @param support Bool value for your vote
     * @param v Used for signature
     * @param r Used for signature
     * @param s Used for signature
	 * @dev Vote on any proposal true for acceptance and false for defeat. Here you will vote by signature
     */

    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GovernorAlpha::castVoteBySig: invalid signature");
        _castVote(signatory, proposalId, support);
    }
    /**
    * @dev Cast vote internal function.
    */

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "GovernorAlpha::_castVote: voting is closed");
        bool isTopStaker = ChefInterface(chefAddress).checkHighestStaker(voter);
        if(!votersInfo[proposalId].voterAddress[voter])
        {
          votersInfo[proposalId].voterAddress[voter] = true;
          votersInfo[proposalId].voterCount = add256(votersInfo[proposalId].voterCount,1);
          if(isTopStaker){
              votersInfo[proposalId].governors = add256(votersInfo[proposalId].governors,1);
          }
        }
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");
        // uint256 votes = ASTR.getPriorVotes(voter, proposal.startBlock);
        uint256 votes = userVoteCount(0, voter);
        if (support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }
        propoasalVoted[voter] = add256(propoasalVoted[voter],1);
        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

    function userVoteCount(
        uint256 _pid,
        address _userAddress
    )
        internal
        view
        returns (
            uint256
        )
    {
        uint256 _amount;
        uint256 _stakingScore;
        uint256 _currentMultiplier;
        uint256 _maxMultiplier;
        (_amount,,,,,,) = ChefInterface(chefAddress).userInfo(_pid,_userAddress);
        (_stakingScore, _currentMultiplier, _maxMultiplier) = ChefInterface(chefAddress).stakingScoreAndMultiplier(_userAddress,_amount);
        return div256(mul256(_stakingScore,_currentMultiplier), MULTIPLIER_DECIMAL);
    }

   /**
    * @dev Functions used for internal safemath purpose.
    */
    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }
    
    function mod256(uint a, uint b) internal pure returns (uint) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function mul256(uint256 a, uint256 b) internal pure returns (uint256) {
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

    function div256(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    } 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

interface TimelockInterface {
    function delay() external view returns (uint);
    function GRACE_PERIOD() external view returns (uint);
    function acceptAdmin() external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);
    function cancelTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external;
    function executeTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}

interface ASTRInterface {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ChefInterface{
    function checkHighestStaker(address user) external view returns (bool);
    function stakingScoreAndMultiplier(
        address _userAddress,
        uint256 _stakedAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
    function depositFromOtherContract(
        uint256 _amount,
        uint256 _vault,
        address _userAddress
    ) external;
    function userInfo(uint256 _pid, address _userAddress) external view returns (uint256, uint256, uint256, uint256, uint256, bool,uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}