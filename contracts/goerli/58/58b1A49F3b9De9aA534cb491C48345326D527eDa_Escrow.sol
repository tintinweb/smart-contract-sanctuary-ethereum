// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

contract Escrow {
    uint256 public immutable amount;
    address public immutable escrowManager;
    address public immutable payer;
    address public immutable receiver;

    constructor(
        uint256 _amount,
        address _payer,
        address _receiver
    ) {
        amount = _amount;
        escrowManager = msg.sender;
        payer = _payer;
        receiver = payable(_receiver);
    }

    function deposite() external payable {
        if (msg.sender != payer) revert();
        if (address(this).balance > amount) revert();
    }

    function releasePayment() external {
        if (msg.sender != escrowManager) revert();
        (bool success, ) = receiver.call{value: amount}("");
        if (!success) revert();
    }

}