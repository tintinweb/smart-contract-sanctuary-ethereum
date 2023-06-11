/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

//
// SPDX-License-Identifier: MIT
//

pragma solidity ^0.8.19;

contract Escrow {
    enum State { AWAITING_CONFIRMATION, COMPLETE }

    struct Agreement {
        address payable seller;
        address payable buyer;
        address lawyer;
        uint256 amount;
        State state;
        bool lawyerConsulted;
    }

    event AgreementCreated(uint256 agreementId, address seller, address buyer, uint256 amount);
    event AgreementCompleted(uint256 agreementId);

    address payable public owner;
    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    uint256 public feeNumerator = 10;
    uint256 public constant feeDenominator = 1000;
    uint256 public constant maxFee = 200;

    uint256 public minAmount = 100000000000; // 100 gwei 

    mapping(uint256 => Agreement) public agreements;
    uint256 public agreementCount = 0;

    constructor() payable {
        owner = payable(msg.sender);
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

    function createAgreement(address payable _seller, address _lawyer) public payable {
        require(_seller != address(0) && _lawyer != address(0), "Seller and lawyer addresses cannot be zero");
        require(msg.sender != _seller, "Seller cannot be the same as the buyer");
        require(msg.sender != _lawyer, "Lawyer cannot be the same as the buyer");
        require(_seller != _lawyer, "Seller cannot be the same as the lawyer");
        require(msg.value >= minAmount, "Must send the correct amount of ether");

        uint256 feeAmount = calculateFee(msg.value);
        uint256 amount = msg.value - feeAmount;

        agreements[agreementCount] = Agreement(
            _seller,
            payable(msg.sender),
            _lawyer,
            amount,
            State.AWAITING_CONFIRMATION,
            false
        );

        emit AgreementCreated(agreementCount, _seller, msg.sender, amount);
        agreementCount++;
    }

    function releaseFundsAsBuyer(uint256 _agreementId) public {
        require(_agreementId < agreementCount, "Agreement does not exist");
        Agreement storage agreement = agreements[_agreementId];
        require(agreement.state != State.COMPLETE, "Agreement is already complete");
        require(msg.sender == agreement.buyer, "Only the buyer can release funds");

        uint256 amount = agreement.amount;
        agreement.amount = 0;
        agreement.state = State.COMPLETE;

        (bool success, ) = agreement.seller.call{value: amount}("");
        require(success, "Transfer failed");

        emit AgreementCompleted(_agreementId);
    }

    function consultLawyer(uint256 _agreementId) public {
        require(_agreementId < agreementCount, "Agreement does not exist");
        Agreement storage agreement = agreements[_agreementId];
        require(msg.sender == agreement.buyer || msg.sender == agreement.seller, "Only the buyer or seller can consult the lawyer");
        require(agreement.lawyerConsulted == false, "Lawyer has already been consulted");

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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");

        emit AgreementCompleted(_agreementId);
    }
}