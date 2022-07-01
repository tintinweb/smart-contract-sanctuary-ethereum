//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Proposal.sol";

/**
 Multisig Wallet smart constract for approving proposals
@dev Smart contract allows for the following:
    1. one administrator who adds/remove member, determine the percentage
    2. Multiple owners
    3. every owner can make a proposal
    4. only co-owners can agree/disagree to a propsal
    5. The approval is executed only when a stated percentage of other members approve

 */
contract Wallet {

    //state variables
    address public owner;
    uint256 private proposalId;
    uint256 private totalNumberOwners;
    Proposal private myProposal;
    

    //mapping
    mapping(address => bool) public ownersList; //address of all owners mapped to true
    mapping(uint => Proposal) private listOfProposals; //
    

    constructor(address _proposalAddress) {
        owner = msg.sender;
        myProposal = Proposal(_proposalAddress);
    }

    //MODIFIERS
    modifier onlyAdmin {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwners {
        require(ownersList[msg.sender]);
        _;
    }

    //EVENTS
    event CreateProposal(address indexed sender, uint256 id);
    event AddOwners(address indexed member);
    event RemoveOwners(address indexed member);


    //FUNCTIONS
    /**
    @dev function calls to add owners to the proposals owners list
    @dev function calls to remove owners address to the proposals owners list
    @dev only Admin can run this
     */


    function addAdr(address _adr) 
    external {
        require(!ownersList[_adr]);
        ownersList[_adr] = true;
        totalNumberOwners = totalNumberOwners + 1;
        emit AddOwners(_adr);
    }

    function removeAdr(address _adr) 
    external {
        require(ownersList[_adr]);
        ownersList[_adr] = false;
        totalNumberOwners = totalNumberOwners - 1;
        emit RemoveOwners(_adr);
    }

    /**
    @dev funtion change the percentage accepted for each proposal
    @dev only admin can run this
     */
    function changePercentage(uint256 _percentage, uint256 _proposalId) 
    external
    onlyAdmin {
    
        listOfProposals[_proposalId].changePercent(_percentage);

    }

    /**
    @dev create a new instance of a proposal smart contract.
    @dev takes in information about the proposal as its constructor arguments
    @dev sets the calling address as the owner of the proposal
     */
    function createProposal() 
    external 
    onlyOwners {
        myProposal = new Proposal();
       
        // listOfProposals[proposalId].setProposerAddress(msg.sender);
        proposalId = proposalId + 1;
       emit CreateProposal(msg.sender, proposalId);
    }

    /**
    @dev function calls the approve function in Id'd proposal
    @dev only owners can run this
     */
    function approveProposal(uint256 _proposalId) 
    external
    onlyOwners {
        listOfProposals[_proposalId].approve(msg.sender);
    }

    /**
    @dev function calls a proposal by id and run its exection function
    @dev only owners can run this
     */
    function executeProposal(uint256 _proposalId)
    external
    onlyOwners {
    
        listOfProposals[_proposalId].execute(msg.sender, totalNumberOwners);
        
    }

    //get the the proposer of a proposal
    function getProposer(uint256 _proposalId) 
    public 
    view
    returns(address) {
        return listOfProposals[_proposalId].getProposerAddress();
    }  

    function getOwnerr(uint256 _proposalId) 
    public 
    view
    returns(address) {
        return listOfProposals[_proposalId].getOwner();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
@dev An instance of a proposal
 */

contract Proposal {

    //state variables
    uint private percentageAcceptance;
    bool private isProposalOn;
    uint256 private numberOfApprovals;
    uint256 approvedPercent;
    address ownerContract;
    address public proposalOwner;

    address[] public agreeingOwners;
    string public proposalInformation;
    

    //mapping
    mapping(address => bool) public agreeingOwnersList;


    constructor() {
        // proposalOwner = _proposer;
        // proposalInformation = _info;
        // percentageAcceptance = 60;
        ownerContract = msg.sender;
    }

    //MODIFIERS
    
    modifier onlyWallet {
        require(msg.sender == ownerContract); //the wallet contract can only call the proposal
        _;
    }

    

    //EVENTS
    event ChangeAcceptance(uint256 _percentage);
    event CreateProposal(address indexed sender, uint256 id);
    event ApproveProposal(address indexed sender);
    event ExecuteApproval(address indexed sender);

    //change the percentage
    function changePercent(uint256 _percentage) 
    external 
    onlyWallet {
        assert(_percentage <= 100);
        percentageAcceptance = _percentage;

        emit ChangeAcceptance(_percentage);
    }

    //approve a proposal
    function approve(address _sender) 
    external
    onlyWallet {
        require(isProposalOn);
        require(!agreeingOwnersList[_sender]);
        agreeingOwnersList[_sender] = true;
        agreeingOwners.push(_sender);
        numberOfApprovals = numberOfApprovals + 1;
        
        
        emit ApproveProposal(msg.sender);
    }

    //execute proposal
    function execute(address _sender,uint256 _totalNumberOwners)
    external
    onlyWallet {
        //function can only be called by the owner who made the proposal
        if(_sender != proposalOwner) {
            revert("Caller is no allowed!!");
        } else {
        // calculate the percentage of acceptance
        //check that the specified percentage condition is met
        approvedPercent = numberOfApprovals/_totalNumberOwners*100;
        require(approvedPercent >= percentageAcceptance);

        //EXECUTE 

        for(uint256 i; i < agreeingOwners.length; i++) {
            agreeingOwnersList[agreeingOwners[i]] = false; //reset the list of owners that approved the proposal
        }
        //reset 
        isProposalOn = false; 
        numberOfApprovals = 0;

        emit ExecuteApproval(msg.sender);
        }
        
        
    }

    
    function setProposerAddress(address _adr)
    external
    returns(bool) {
        proposalOwner = _adr;
        return true;
    }

    function getProposerAddress()
    external
    view
    returns(address) {
        return proposalOwner;
    }

    function getOwner()
    external
    view
    returns(address) {
        return ownerContract;
    }
    




    
}