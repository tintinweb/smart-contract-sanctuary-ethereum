// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Escrow {
    address public lawyer;
    address public payeer;
    address payable payee;
    uint256 public amount;

    constructor(
        address _payeer,
        address payable _payee,
        uint256 _amount
    ) {
        payeer = _payeer;
        payee = _payee;
        amount = _amount;
        lawyer = msg.sender;
    }

    function deposit() public payable {
        require(msg.sender == payeer, "sender must be the payeer");
        require(address(this).balance <= amount);
    }

    function release() public {
        require(
            address(this).balance == amount,
            "cannot release fund before full amount is sent"
        );
        require(msg.sender == lawyer, "only lawyer can release funds");
        payee.transfer(amount);
    }

    function balanceOf() public view returns (uint256) {
        return address(this).balance;
    }
}