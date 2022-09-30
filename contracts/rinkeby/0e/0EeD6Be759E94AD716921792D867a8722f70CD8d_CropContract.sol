// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


error NotOwner();

contract CropContract{
    enum State{
        PENDING,
        F_STAGE,
        S_STAGE,
        T_STAGE,
        COMPLETED
    }
    State public state = State.PENDING;
    uint public amount;
    uint public end;
    address payable public borrower;
    address payable public lender;
    uint public valTransfered;

    uint firstStagePercentage;
    uint secondStagePercentage;
    uint thirdStagePercentage;

    constructor(uint _amount, uint _duration, address payable _borrower, address payable _lender, 
    uint _firstStagePercentage, uint _secondStagePercentage, uint _thirdStagePercentage) {
        amount = _amount;
        end = block.timestamp + _duration;
        borrower = _borrower;
        lender = _lender;
        firstStagePercentage = _firstStagePercentage;
        secondStagePercentage = _secondStagePercentage;
        thirdStagePercentage = _thirdStagePercentage;
    }

    function FirstStagefund() payable external {
        require(msg.sender == lender, "Only lender can land");
        valTransfered = (firstStagePercentage * amount * (1 ether)) / 100;
        require(msg.value == valTransfered, "Must give at least: firstStagePercentage");
        _transitionTo(State.F_STAGE);
        borrower.transfer(amount);
    }

    function SecondStagefund() payable external {
        require(msg.sender == lender, "Only lender can land");
        valTransfered = (secondStagePercentage * amount * (1 ether)) / 100;
        require(msg.value == valTransfered, "Must give at least: secondStagePercentage");
        _transitionTo(State.S_STAGE);
        borrower.transfer(amount);
    }

    function ThirdStagefund() payable external {
        require(msg.sender == lender, "Only lender can land");
        valTransfered = (thirdStagePercentage * amount * (1 ether)) / 100;
        require(msg.value == valTransfered, "Must give at least: thirdStagePercentage");
        _transitionTo(State.T_STAGE);
        borrower.transfer(amount);
        payable(borrower).transfer(address(this).balance);
    }

    function _transitionTo(State to) internal{
        require(to != State.PENDING, "Cannot go back to PENDING STATE");
        require(to != state, "Cannot transition to current STATE");
        if(to == State.F_STAGE){
            require(state == State.PENDING, "Can only transition to first stage from pending state");
            state = State.F_STAGE;
        }
        if(to == State.S_STAGE){
            require(state == State.F_STAGE, "Can only transition to second stage from first stage state");
            state = State.S_STAGE;
        }
        if(to == State.T_STAGE){
            require(state == State.S_STAGE, "Can only transition to third stage from second stage state");
            state = State.T_STAGE;
        }
        if(to == State.COMPLETED){
            require(state == State.T_STAGE, "Can only transition to active from pending state");
            state = State.COMPLETED;
        }
    }
    function reimburseOwner() payable external onlyBorrower{
        if(address(this).balance > 0)
            payable(lender).transfer(address(this).balance);
    }
        modifier onlyBorrower{
        require(msg.sender == borrower, "Sender is not borrower!");
        if(msg.sender != borrower){ revert NotOwner();}
        _;
    }  
}