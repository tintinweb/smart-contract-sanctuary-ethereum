// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Token/IRepToken.sol";
import "../Arbitration/Arbitration.sol";
import "../DAO/IDAO.sol";
import "../Voting/IVoting.sol";

/// @title Main Project contract
/// @author dOrg
/// @dev Experimental status
/// @custom:experimental This is an experimental contract.
contract ClientProject{
    /* ========== CONTRACT VARIABLES ========== */

    ISource public source;
    IRepToken public repToken;
    IERC20 public paymentToken;
    ArbitrationEscrow public arbitrationEscrow;
    IVoting public voting;

    /* ========== ENUMS AND STRUCTS ========== */

    enum ProjectStatus {proposal, active, inDispute, inactive, completed, rejected}

    struct paymentProposal {
        uint256 amount ;  // TODO: diminish the size here from uint256 to something smaller
        uint16 numberOfApprovals;         
    }

    struct Milestone {
        bool approved;
        bool inDispute;
        uint256 requestedAmount;
        string requirementsCid;
        uint256 index;
        uint256 payrollVetoDeadline;
        address payable[] payees;
        uint256[] payments;
    }

    struct CurrentVoteId {
        uint256 onProject;
        uint256 onSourcingLead;
        uint256 onTeam;
    }

    /* ========== VOTING VARIABLES ========== */
    ProjectStatus public status;
    CurrentVoteId public currentVoteId;
    uint256 public votes_pro;
    uint256 public votes_against;
    uint256 public votingDuration;  // in seconds (1 day = 86400)
    uint256 public vetoDurationForPayments = 300 ;// in seconds
    uint256 public startingTime;    
    
    // TODO: Discuss in dOrg
    uint256 public defaultThreshold = 500;  // in permille
    uint256 public exclusionThreshold = 500;  // in permille

    mapping(address=>bool) _isTeamMember;
    mapping(address=>mapping(address=>bool)) public excludeMember;
    mapping(address=>uint16) public voteToExclude;
    mapping (address=>mapping(address=>uint256)) public votesForNewSourcingLead;
    mapping (address=>mapping(address=>bool)) public alreadyVotedForNewSourcingLead;
    /* ========== ROLES ========== */

    address payable public client;
    address payable public sourcingLead;
    address payable public arbiter;
    address payable[] public team;
    /* ========== PAYMENT ========== */
    
    uint256 public repWeiPerPaymentGwei = 10**9;  // 10**9; for stablecoin
    // You earn one WETH, then how many reptokens you get?
    // (10**18) * (repToPaymentRatio) / (10 ** 9)
    // where the repToPaymentRatio = 3000 * 10 ** 9

    enum MotionType {
        removeTeamMember,
        changeSourcingLead,
        disputeProject,
        refundClient
    }

    struct Motion {
        MotionType motionType;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 timestamp;
        address nominee;
        bool inactive;
    }

    Motion[] public motions;

    /* ========== MILESTONES ========== */

    Milestone[] public milestones;  // holds all the milestones of the project
    
    function numberOfMilestones() public view returns (uint256){
        return milestones.length;
    }

    /* ========== EVENTS ========== */

    event MilestoneApproved(uint256 milestoneIndex, uint256 approvedAmount);
    event RequestedAmountAddedToMilestone(uint256 milestoneIndex, uint256 requetedAmount);
    event PayrollRosterSubmitted(uint256 milestoneIndex);
    event Disputed(address disputer);

    /* ========== CONSTRUCTOR ========== */
    

    constructor(address _sourceAddress,
                address payable _sourcingLead,
                address payable _client,
                address payable _arbiter,
                address repTokenAddress,
                address _arbitrationEscrow,   //TODO! Better use address!
                address _votingAddress,
                address _paymentTokenAddress,
                uint256 _votingDuration){
         
        status=ProjectStatus.proposal;
        sourcingLead=_sourcingLead;
        team.push(sourcingLead);
        _isTeamMember[sourcingLead] = true;
        client=_client;
        arbitrationEscrow=ArbitrationEscrow(_arbitrationEscrow);
        arbiter=_arbiter;
        source = ISource(_sourceAddress);
        repToken = IRepToken(repTokenAddress);
        startingTime = block.timestamp;
        votingDuration = _votingDuration;
        voting = IVoting(_votingAddress);
        // use default ratio between Rep and Payment
        _changePaymentMethod(_paymentTokenAddress, repWeiPerPaymentGwei);
        
    }

    /* ========== VOTING  ========== */

    function voteOnProject(bool decision) external returns(bool){
        // if the duration is less than a week, then set flag to 1
        if(block.timestamp - startingTime > votingDuration ){ 
            _registerVote();
            return false;
        }
        uint256 vote = repToken.balanceOf(msg.sender);
        if (decision){
            votes_pro += vote ;// add safeMath
        } else {
            votes_against += vote;  // add safeMath
        }
        return true;
    }


    function registerVote() public {
        require(block.timestamp - startingTime > votingDuration, "Voting is still ongoing");
        _registerVote();
    }

    function _registerVote() internal {
        if (votes_pro > votes_against) {
            // transact money into enscrow
            status = ProjectStatus.inactive;
       
        } else {
            status = ProjectStatus.rejected;
            // in the case that the client had already some funds locked
            _returnFundsToClient(paymentToken.balanceOf(address(this)));
        }
    }


    // add function if its vetoed
    function vetoPayrollRoster(uint256 milestoneIndex) public{
        require(_isTeamMember[msg.sender]);
        uint256 [] memory NoPayments;
        milestones[milestoneIndex].payments = NoPayments;  // TODO: think about storage 
    }

    /* ========== REPUTATION ========== */

    function setRepWeiValuePerGweiTokenValue(uint256 _repWeiPerPaymentGwei) public {
        // TODO: Careful with the guard
        // require(msg.sender == address(source) || msg.sender==sourcingLead);
        repWeiPerPaymentGwei = _repWeiPerPaymentGwei;
    }

    function sendRepToken(address _to, uint256 _amount) public {
        // TODO send rep from source.
        repToken.transfer(_to, _amount);
    }

    /* ========== TEAM HANDLING ========== */
    
    function addTeamMember (address payable _teamMember) public {
        // add require only majority or sourcing lead and source contract
        require(msg.sender==sourcingLead || msg.sender==address(source));
        team.push(_teamMember);
        _isTeamMember[_teamMember] = true;
    }

    
    function excludeFromTeam(address _teamMember) external {
        // TODO!!!with some vetos or majority
        require(excludeMember[msg.sender][_teamMember] == false && sourcingLead!=_teamMember);
        excludeMember[msg.sender][_teamMember] = true;
        voteToExclude[_teamMember] += 1;
        if (voteToExclude[_teamMember]> (team.length * exclusionThreshold ) / 100){
            _isTeamMember[_teamMember]= false;
            // TODO: add these to the motions, once it passes
            motions.push(Motion({
                motionType: MotionType.removeTeamMember,
                votesFor: voteToExclude[_teamMember],
                votesAgainst: 0,
                timestamp: block.timestamp,
                nominee: _teamMember,
                inactive: true
            }));
        }
    }
    
    function startSourcingLeadVote() external {
        // TODO: Save conversion to uint120!
        currentVoteId.onSourcingLead = voting.start(1, 0, uint120(defaultThreshold), uint120(team.length));
    }

    function replaceSourcingLead(address _nominee) external {
        require(_nominee!=sourcingLead);  // Maybe allow also sourcingLead to         
        voting.safeVote(currentVoteId.onSourcingLead, msg.sender, _nominee, 1);
        voting.getStatus(currentVoteId.onSourcingLead); // you cant hear me probably.
    }

    function claimSourcingLead() external {
        (uint8 votingStatus, address elected) = voting.getStatusAndElected(currentVoteId.onSourcingLead);
        require(votingStatus==2, "Voting has not passed");
        require(elected == msg.sender, "Only elected Project Manager can claim!");
        sourcingLead = payable(msg.sender);
        // reset all the votes maybe.
    }


    /* ========== PROJECT HANDLING ========== */

    function startProject() external{
        require(msg.sender==sourcingLead, "only Sourcing Lead");
        require(status == ProjectStatus.inactive, "not allowed to change status");
        // is there enough money in escrow and project deposited by client?
        status = ProjectStatus.active;
    }


    function addMilestone(string memory _requirementsCid) public {
        require(msg.sender == sourcingLead,"Only the sourcing lead can add milestones");
        require(block.timestamp - startingTime > votingDuration, "Voting is still ongoing");
        if (status==ProjectStatus.proposal){_registerVote();}
        address payable[] memory NoPayees;
        uint256[] memory NoPayments;
        uint256 _index=0;
        if (milestones.length>0){ _index=milestones.length-1;}
        milestones.push(Milestone({
            approved: false,
            inDispute: false,
            requestedAmount: 0,
            requirementsCid: _requirementsCid,
            payrollVetoDeadline: 0,
            index: _index,
            payees: NoPayees,
            payments: NoPayments
        }));
    }

    function addAmountToMilestone(uint256 milestoneIndex, uint256 amount) public {
        require(msg.sender == sourcingLead,"Only the sourcing lead can request payment from client");
        milestones[milestoneIndex].requestedAmount = amount;
        emit RequestedAmountAddedToMilestone(milestoneIndex, amount);
    }

    function approveMilestone(uint256 milestoneIndex) public {
        require(msg.sender == client,"Only the client can approve a milestone");
        milestones[milestoneIndex].approved = true;
        emit MilestoneApproved(milestoneIndex, milestones[milestoneIndex].requestedAmount);
        _releaseMilestoneFunds(milestoneIndex);
    }


    /* ========== PAYMENTS HANDLING ========== */

    function changePaymentMethod(address _tokenAddress, uint256 _repWeiPerPaymentGwei) external {
        require(paymentToken.balanceOf(address(this))==0, "Previous Token needs to be depleted before the change");
        _changePaymentMethod(_tokenAddress, _repWeiPerPaymentGwei);
    }

    function _changePaymentMethod(address _tokenAddress, uint256 _repWeiPerPaymentGwei) internal {
        // TODO: Maybe a guard should be put in place here.
        // require(msg.sender == address(source) || msg.sender== sourcingLead, "source or sourcing Lead!");
        paymentToken = IERC20(_tokenAddress);
        // set the new ratio.
        setRepWeiValuePerGweiTokenValue(_repWeiPerPaymentGwei);
    }


    function _returnFundsToClient(uint256 _amount) internal {
        // return funds to client
        paymentToken.transfer(client, _amount);
    }

    // dev A doesnt withdraw --> then the con 
    function submitPayrollRoster(uint256 milestoneIndex, address payable [] memory _payees, uint256[] memory _amounts) external {
        require(msg.sender==sourcingLead && _payees.length == _amounts.length);
        milestones[milestoneIndex].payrollVetoDeadline = block.timestamp + vetoDurationForPayments;
        milestones[milestoneIndex].payees=_payees;
        milestones[milestoneIndex].payments=_amounts;
        emit PayrollRosterSubmitted(milestoneIndex);  // maybe milestones[milestoneIndex].payrollVetoDeadline
    }

    function _releaseMilestoneFunds(uint256 milestoneIndex) internal {
        // client approves milestone, i.e. approve payment to the developer
        require(milestones[milestoneIndex].approved);
        // NOTE; Might be issues with calculating the 10 % percent of the other splits
        uint256 tenpercent=((milestones[milestoneIndex].requestedAmount * 1000) / 10000);
        paymentToken.transfer(address(source), tenpercent);
    }

    function batchPayout (uint256 milestoneIndex) external {
        require(milestones[milestoneIndex].approved);
        require(block.timestamp > milestones[milestoneIndex].payrollVetoDeadline);
        for (uint i=0; i< milestones[milestoneIndex].payees.length; i++){
            paymentToken.transfer(milestones[milestoneIndex].payees[i], milestones[milestoneIndex].payments[i]);
            source.mintRepTokens(milestones[milestoneIndex].payees[i], milestones[milestoneIndex].payments[i]);
            // _repAmount = _amount * repWeiPerPaymentGwei / (10 ** 9); 
        }
    }
    /* ========== DISPUTE ========== */

    function dispute(uint256[] memory milestoneIndices) external {
        require(msg.sender == client || msg.sender==sourcingLead );
        for (uint256 j=0; j<milestoneIndices.length; j++){
            milestones[milestoneIndices[j]].inDispute = true;
            // emit Disputed(msg.sender, milestoneIndices[j]);
        }
        status = ProjectStatus.inDispute;
        emit Disputed(msg.sender);
        // TODO: emit an event also in case that there are no milestone indices (for the client)
    }
    
    function arbitration(bool forInvoice)public{
        require(msg.sender == arbiter && status==ProjectStatus.inDispute);
        if (forInvoice){
            // approvalAmount = outstandingInvoice;
            for (uint256 j=0; j<milestones.length; j++){
                // Maybe could be more cost efficient in future implementation
                if (milestones[j].inDispute){
                    milestones[j].approved = true;
                    milestones[j].inDispute = false;  
                }
            }
            // in current logic the status reverts to active irrespective of whether motion is for or agains invoice
            // status = ProjectStatus.active;
        }
        // client gets entire funds of the project
        _returnFundsToClient(paymentToken.balanceOf(address(this)));
        // what happens to the project?
        status = ProjectStatus.active;  
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRepToken {
    function mint(address holder, uint256 amount) external;

    function burn(address holder, uint256 amount) external;

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

        /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract ArbitrationEscrow {
    mapping(address=>uint256) arbrationFee;  // project address => fee
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface ISource {
    function mintRepTokens(address payable payee, uint256 amount) external;
    function transferToken(address _erc20address, address _recipient, uint256 _amount) external; 
    function setPayrollRoster(address payable[] memory _payees, uint256[] memory _amounts) external;
    function getStartPaymentTimer() external returns(uint256);
    function mintRep(uint256 _amount) external;
    function burnRep() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IVoting {
    function start(uint8 _votingType, uint40 _deadline, uint120 _threshold, uint120 _totalAmount) external returns(uint256);
    function vote(uint256 poll_id, address votedBy, address votedOn, uint256 amount) external;
    function safeVote(uint256 poll_id, address votedBy, address votedOn, uint128 amount) external;
    function safeVoteReturnStatus(uint256 poll_id, address votedBy, address votedOn, uint128 amount) external returns(uint8);
    function getStatus(uint256 poll_id) external returns(uint8);
    function getElected(uint256 poll_id) view external returns(address);
    function getStatusAndElected(uint256 poll_id) view external returns(uint8, address);
    function stop(uint256 poll_id) external;
    function retrieve(uint256 poll_id) view external returns(uint8, uint40, uint256, uint256, address);
}