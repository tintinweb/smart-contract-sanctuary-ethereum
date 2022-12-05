// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract EscrowPayment {
    address public lawyer;
    address public payeer;
    address payable public payee;
    uint256 public amount;

    constructor(
        address _payeer,
        address payable _payee,
        uint256 _amount
    ) {
        lawyer = msg.sender;
        payeer = _payeer;
        payee = _payee;
        amount = _amount;
    }

    modifier onlyLawyer() {
        require(msg.sender == lawyer);
        _;
    }

    function send() public payable {
        require(msg.sender == payeer, "only payeer can send");
        require(msg.value <= amount, "can not send more than amount");
    }

    function release() public onlyLawyer {
        require(
            address(this).balance == amount,
            "can not send before full amount deposited"
        );
        payee.transfer(address(this).balance);
    }
}