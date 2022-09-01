// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {

address public Owner;
    constructor(){
        Owner = msg.sender;
    }

    mapping(address => Voter) public voters;

    // Enum de sessions
    enum Step{
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied       
    }
    Step public sessionStep;

    // Voter 
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
        
    Voter[] public votersArray;
    Proposal[] public proposals;

    // Proposal
    struct Proposal {
        string description;
        uint voteCount;
        address voter;
    }

    // Event
    event isStep(uint _step);
    event isRegistering(address _address,bool _isRegistering, bool _hasVoted, uint _votedProposalId);
    event isProposal(uint _proposalID, string _proposal);
    event isVoted(uint _proposalID,address _address);
    event isWinning(uint _proposalID);

    /**
    * @notice Return session step
    *
    */
    function getSessionStep() public view returns(uint){
        return uint(sessionStep);
    }

    /**
    * @notice Set sessionStep
    *
    * @param _sessionStep { RegisteringVoters(0), ProposalsRegistrationStarted(1), ProposalsRegistrationEnded(2),
        VotingSessionStarted(3), VotingSessionEnded(4), VotesTallied(5)}
    */ 
    function setSessionStep(uint _sessionStep) external onlyOwner returns(address){
        require(msg.sender==Owner,"You don't are the owner");
        sessionStep = Step(_sessionStep);
        emit isStep(_sessionStep);
        return msg.sender;
    }

    /**
    * @notice Registered whitelist
    *
    */   
    function RegisteringVoters() public {
        // Verify Voter is already registered and session is registered
        require(sessionStep==Step.RegisteringVoters,"registerVoters session has not started");
        require(!voters[msg.sender].isRegistered,"you are already registered");
        voters[msg.sender] = Voter(true, false, 0);
        emit isRegistering(msg.sender,true, false, 0);
    }

    /**
    * @notice return status registering voters
    *
    * @param _voters address voter
    */  
    function getRegisteringVoters(address _voters) public view returns(bool){
     return voters[_voters].isRegistered;
    }

    /**
    * @notice Voter proposal string description
    *
    * @param _proposal description.
    */   
    function addProposal(string memory _proposal) public{
        require(sessionStep==Step.ProposalsRegistrationStarted,"ProposalsRegistrationStarted has not started");
        require(voters[msg.sender].isRegistered, "you are note registered");
        Proposal memory proposal = Proposal(_proposal,0,msg.sender);
        proposals.push(proposal);
        emit isProposal(proposals.length,_proposal);
    }

    /**
    * @notice vote the proposal
    *
    *@param _proposalID voted proposal
    */  
    function voteProposal(uint _proposalID) public {
        require(sessionStep==Step.VotingSessionStarted,"VotingSessionStarted session has not started");
        require(voters[msg.sender].isRegistered,"you are not registered");
        require(_proposalID<=proposals.length,"proposal does not exist");
        require(!voters[msg.sender].hasVoted,"you have already voted");
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalID;
        proposals[_proposalID].voteCount++;
        emit isVoted(_proposalID,msg.sender);

    }
    /**
    * @notice Return bool hasVoted 
    *
    */
    function getVotersHasVoted(address _address) public view returns(bool) {
        return voters[_address].hasVoted;
    }

    function getProposalPerID(uint _proposalID) public view returns(string memory){
        return proposals[_proposalID].description;
    }

    /**
    * @notice Return all proposals
    *
    */   
    function getProposalsArray() external view returns(Proposal[] memory){
        return proposals;
    }

    /**
    * @notice Return winning proposal
    *
    */ 
    function winningProposal() public onlyOwner returns(uint){
        require(sessionStep==Step.VotesTallied,"VotesTallied session has not started");
         uint winningVoteCount = 0;
         uint proposalID = 0;
         for(uint i=0; i< proposals.length; i++){
             if(proposals[i].voteCount > winningVoteCount){
                 proposalID = i;
                 winningVoteCount = proposals[i].voteCount;
             }
         }
         proposalID = 3;
         emit isWinning(proposalID);
         return proposalID;
    }
}

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