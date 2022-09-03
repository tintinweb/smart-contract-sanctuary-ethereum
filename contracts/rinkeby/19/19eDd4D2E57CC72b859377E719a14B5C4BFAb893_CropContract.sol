// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
enum State{
        PENDING,
        ACTIVE,
        CLOSED
    }


contract CropContract{
    
    State public state = State.PENDING;
    uint public amount;
    uint public interest;
    uint public end;
    address payable public borrower;
    address payable public lender;

    constructor(uint _amount, uint _interest, uint _duration, address payable _borrower,address payable _lender) {
        amount = _amount;
        interest = _interest;
        end = block.timestamp + _duration;
        borrower = _borrower;
        lender = _lender;
    }

    function fund() payable external {
        require(msg.sender == lender, "Only lender can land");
        // require(
        //     // address(this).balance
        //     msg.value <= amount, "Cannot lend more than the amount");
        _transitionTo(State.ACTIVE);
        borrower.transfer(amount);
    }

    function reimburse() payable external {
        require(msg.sender == borrower, "Only borrower can reimburse");
        require(msg.value >= amount + interest, "Borrowoer needs to reimburse amount + interest ");
        _transitionTo(State.CLOSED);
        lender.transfer(amount + interest);
    }

    function _transitionTo(State to) internal{
        require(to != State.PENDING, "Cannot go back to PENDING STATE");
        require(to != state, "Cannot transition to current STATE");
        if(to == State.ACTIVE){
            require(state == State.PENDING, "Can only transition to active from pending state");
            state = State.ACTIVE;
        }
        if(to == State.CLOSED){
            require(state == State.ACTIVE, "Can only transition to closed from active state");
            require(block.timestamp >= end, "Loan has not matured yet");
            state = State.CLOSED;
        }
    }
    function reimburseOwner() payable external {
        if(address(this).balance > 0)
            payable(lender).transfer(address(this).balance);
    }
    //     modifier onlyBorrower{
    //     require(msg.sender == borrower, "Sender is not borrower!");
    //     if(msg.sender != borrower){ revert NotOwner;}
    //     _;
    // }  
}