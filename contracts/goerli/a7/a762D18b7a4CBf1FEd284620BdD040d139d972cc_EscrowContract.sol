/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// The Fast Way's Assignment
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract EscrowContract {

    address payable public buyer;
    address payable public seller;
    address public arbitrator;
    uint256 public escrowAmount;
    uint256 public disputePeriod;
    uint256 public startTime;
    bool public isDispute;
    bool public isPaid;
    uint256 public approvals;
    
    enum DisputeResolution { NoDispute, BuyerWins, SellerWins, Arbitrator }
    
    mapping(address => bool) public isApproved;
    mapping(address => bool) public isEvidenceSubmitted;
    mapping(address => string) public evidence;

    event EscrowInitialized(address buyer, address seller, uint256 amount);
    event FundsDeposited(address sender, uint256 amount);
    event DisputeRaised(address raiser);
    event DisputeResolved(DisputeResolution resolution);
    event FundsReleased(address recipient, uint256 amount);

    constructor(address payable _seller, address _arbitrator, uint256 _disputePeriod) payable {
        buyer = payable(msg.sender);
        seller = _seller;
        arbitrator = _arbitrator;
        escrowAmount = msg.value;
        disputePeriod = _disputePeriod;
        startTime = block.timestamp;
        
        emit EscrowInitialized(buyer, seller, escrowAmount);
    }
    
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only the buyer can call this function");
        _;
    }
    
    modifier onlySeller() {
        require(msg.sender == seller, "Only the seller can call this function");
        _;
    }
    
    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "Only the arbitrator can call this function");
        _;
    }
    
    modifier inDisputePeriod() {
        require(block.timestamp <= startTime + disputePeriod, "The dispute period has ended");
        _;
    }
    
    modifier notInDispute() {
        require(!isDispute, "The transaction is already in dispute");
        _;
    }
    
    
    function approveTransaction() external notInDispute {
        require(msg.sender == buyer || msg.sender == seller, "Only the buyer or seller can approve the transaction");
        require(!isApproved[msg.sender], "Transaction already approved");
        
        isApproved[msg.sender] = true;
        approvals++;
        
        if (approvals == 2) {
            isPaid = true;
            emit FundsReleased(seller, escrowAmount);
        }
    }
    
    function raiseDispute(string calldata _evidence) external onlyBuyer notInDispute inDisputePeriod {
        isDispute = true;
        isEvidenceSubmitted[buyer] = true;
        evidence[buyer] = _evidence;
        emit DisputeRaised(buyer);
    }
    
    function submitEvidence(string calldata _evidence) external onlySeller inDisputePeriod {
        require(isDispute, "There is no dispute to submit evidence for");
        require(!isEvidenceSubmitted[seller], "Evidence already submitted");
        
        isEvidenceSubmitted[seller] = true;
        evidence[seller] = _evidence;
    }
    
    function resolveDispute(DisputeResolution resolution) external onlyArbitrator {
        require(isDispute, "There is no dispute to resolve");
        
        isDispute = false;
        
        if (resolution == DisputeResolution.BuyerWins) {
            payable(buyer).transfer(escrowAmount);
            emit DisputeResolved(resolution);
            emit FundsReleased(buyer, escrowAmount);
        } else if (resolution == DisputeResolution.SellerWins) {
            payable(seller).transfer(escrowAmount);
            emit DisputeResolved(resolution);
            emit FundsReleased(seller, escrowAmount);
        } else if (resolution == DisputeResolution.Arbitrator) {
            // Additional logic can be implemented for the specific actions taken by the arbitrator
            emit DisputeResolved(resolution);
        }
    }
    
    function releaseFunds() external onlyBuyer {
        require(isPaid, "The transaction has not been approved and paid yet");
        require(!isDispute, "The transaction is currently in dispute");
        
        payable(seller).transfer(escrowAmount);
        emit FundsReleased(seller, escrowAmount);
    }
    
    function refundFunds() external onlySeller {
        require(!isPaid, "The transaction has already been paid");
        require(!isDispute, "The transaction is currently in dispute");
        
        payable(buyer).transfer(escrowAmount);
        emit FundsReleased(buyer, escrowAmount);
    }
}