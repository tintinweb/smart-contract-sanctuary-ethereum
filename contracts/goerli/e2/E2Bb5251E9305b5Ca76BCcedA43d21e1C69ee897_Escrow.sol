/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

//
// SPDX-License-Identifier: MIT
//

pragma solidity ^0.8.19;

contract Escrow {
    event AgreementCreated(uint256 agreementId, address seller, address buyer, uint256 amount);
    event AgreementCompleted(uint256 agreementId);

    enum State { AWAITING_CONFIRMATION, COMPLETE }

    struct Agreement {
        address payable seller;
        address payable buyer;
        address lawyer;
        uint256 amount;
        State state;
        bool lawyerConsulted;
    }
    mapping(uint256 => Agreement) public agreements;
    uint256 public agreementCount = 0;

    int8 constant maxScore = 100;
    int8 constant minScore = -100;

    struct Reputation {
        int8 buyerScore;
        int8 sellerScore;
        int8 lawyerScore;
    }
    mapping(address => Reputation) public reputations;

    function _updateReputation(int8 score, bool positive) internal pure returns (int8) {
        if (positive && score < maxScore) {
            return score + 1;
        }
        else if (!positive && score > minScore) {
            return score - 1;
        }
        return score;
    }

    address payable public owner;
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    uint256 public feeNumerator = 10;
    uint256 public constant feeDenominator = 1000;
    uint256 public constant maxFee = 200;
    address payable public feeRecipient;
    uint256 public totalFeesCollected = 0;

    modifier onlyFeeRecipient {
        require(msg.sender == feeRecipient, "Only the fee recipient can call this function");
        _;
    }

    uint256 public minAmount = 100000000000; // 100 gwei 


    constructor(address payable _feeRecipient) payable {
        owner = payable(msg.sender);
        feeRecipient = _feeRecipient;
    }

    function setFeeRecipient(address payable _feeRecipient) public onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function collectFees() public onlyFeeRecipient {
        uint256 balance = address(this).balance;
        require(balance > totalFeesCollected, "Balance must be greater than total fees");
        require(totalFeesCollected > 0, "No fees to collect");

        uint256 _totalFeesCollected = totalFeesCollected;
        totalFeesCollected = 0;
        feeRecipient.transfer(_totalFeesCollected);
    }

    function calculateFee(uint256 _amount) public view returns (uint256) {
        return _amount * feeNumerator / feeDenominator;
    }

    function setFee(uint256 _numerator) public onlyOwner {
        require(_numerator <= maxFee, "Fees must be less than 20%");
        feeNumerator = _numerator;
    }

    function setMinAmount(uint256 _minAmount) public onlyOwner {
        minAmount = _minAmount;
    }

    function createAgreement(address payable _seller, address _lawyer, uint256 _amount) public payable {
        require(_seller != address(0) && _lawyer != address(0), "Seller and lawyer addresses cannot be zero");
        require(msg.sender != _seller, "Seller cannot be the same as the buyer");
        require(msg.sender != _lawyer, "Lawyer cannot be the same as the buyer");
        require(_seller != _lawyer, "Seller cannot be the same as the lawyer");
        require(_amount >= minAmount, "Must send the correct amount of ether");

        uint256 feeAmount = calculateFee(_amount);
        require(msg.value >= _amount + feeAmount, "Must send the correct amount of ether");

        agreements[agreementCount] = Agreement(
            payable(_seller),
            payable(msg.sender),
            _lawyer,
            _amount,
            State.AWAITING_CONFIRMATION,
            false
        );
        agreementCount++;

        totalFeesCollected += feeAmount;
        emit AgreementCreated(agreementCount, _seller, msg.sender, _amount);
    }

    function releaseFundsAsBuyer(uint256 _agreementId) public {
        require(_agreementId < agreementCount, "Agreement does not exist");
        Agreement storage agreement = agreements[_agreementId];
        require(agreement.state != State.COMPLETE, "Agreement is already complete");
        require(msg.sender == agreement.buyer, "Only the buyer can release funds");

        uint256 amount = agreement.amount;
        agreement.amount = 0;
        agreement.state = State.COMPLETE;

        agreement.seller.transfer(amount);

        emit AgreementCompleted(_agreementId);
    }

    function consultLawyer(uint256 _agreementId) public {
        require(_agreementId < agreementCount, "Agreement does not exist");
        Agreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.buyer || msg.sender == agreement.seller, "Only the buyer or seller can consult the lawyer");
        require(agreement.lawyerConsulted == false, "Lawyer has already been consulted");
        require(agreement.state != State.COMPLETE, "Agreement is already complete");

        agreement.lawyerConsulted = true;
    }

    function transferAsLawyer(uint256 _agreementId, bool _returnToBuyer) public {
        require(_agreementId < agreementCount, "Agreement does not exist");
        Agreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.lawyer, "Only the lawyer can transfer funds");
        require(agreement.lawyerConsulted == true, "Lawyer must be consulted before funds can be transferred");
        require(agreement.state != State.COMPLETE, "Agreement is already complete");

        address payable recipient = _returnToBuyer ? agreement.buyer : agreement.seller;

        uint256 amount = agreement.amount;
        agreement.amount = 0;
        agreement.state = State.COMPLETE;

        recipient.transfer(amount);

        emit AgreementCompleted(_agreementId);
    }

    function rateAsBuyer(uint256 _agreementId, bool _scoreSeller, bool _scoreLawyer) public {
        require(_agreementId < agreementCount, "Agreement does not exist");
        Agreement memory agreement = agreements[_agreementId];
        require(msg.sender == agreement.buyer, "Only the buyer can rate the agreement");
        require(agreement.state == State.COMPLETE, "Agreement must be complete before it can be rated");

        Reputation storage sellerReputation = reputations[agreement.seller];
        sellerReputation.sellerScore = _updateReputation(sellerReputation.sellerScore, _scoreSeller);
        
        
        if(agreement.lawyerConsulted) {
            Reputation storage lawyerReputation = reputations[agreement.lawyer];
            lawyerReputation.lawyerScore = _updateReputation(lawyerReputation.lawyerScore, _scoreLawyer);
        }
    }

    function rateAsSeller(uint256 _agreementId, bool _scoreBuyer, bool _scoreLawyer) public {
        require(_agreementId < agreementCount, "Agreement does not exist");
        Agreement memory agreement = agreements[_agreementId];
        require(msg.sender == agreement.seller, "Only the seller can rate the agreement");
        require(agreement.state == State.COMPLETE, "Agreement must be complete before it can be rated");

        Reputation storage buyerReputation = reputations[agreement.buyer];
        buyerReputation.buyerScore = _updateReputation(buyerReputation.buyerScore, _scoreBuyer);

        if(agreement.lawyerConsulted) {
            Reputation storage lawyerReputation = reputations[agreement.lawyer];
            lawyerReputation.lawyerScore = _updateReputation(lawyerReputation.lawyerScore, _scoreLawyer);
        }
    }

    function rateAsLawyer(uint256 _agreementId, bool _scoreBuyer, bool _scoreSeller) public {
        require(_agreementId < agreementCount, "Agreement does not exist");
        Agreement memory agreement = agreements[_agreementId];
        require(msg.sender == agreement.lawyer, "Only the lawyer can rate the agreement");
        require(agreement.state == State.COMPLETE, "Agreement must be complete before it can be rated");
        require(agreement.lawyerConsulted == true, "Lawyer must be consulted before being able to rate");

        Reputation storage buyerReputation = reputations[agreement.buyer];
        buyerReputation.buyerScore = _updateReputation(buyerReputation.buyerScore, _scoreBuyer);

        Reputation storage sellerReputation = reputations[agreement.seller];
        sellerReputation.sellerScore = _updateReputation(sellerReputation.sellerScore, _scoreSeller);

    }
}