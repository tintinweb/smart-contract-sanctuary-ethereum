/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract PaymentProcessor {
    uint256 public DIVISOR = 100;
    uint256 public adminFee;
    address payable public admin; 
    address payable public burnAddress;

    event PaymentDone(
        address payer,
        uint amount,
        uint paymentId,
        uint date
    );

    receive() external payable { }

    constructor(
        address payable adminAddress,
        uint256 _adminFee, 
        address payable _burnAddress
    ) {
        admin = adminAddress;
        adminFee = _adminFee;
        burnAddress = _burnAddress;
    }

    function changeAdminFee(uint256 newAdminFee) external {
        require(msg.sender == address(admin), "Unauthorized");
        require(newAdminFee < DIVISOR, "Fee too big");
        adminFee = newAdminFee;
    }

    function managePayment(uint amount, uint paymentId, uint256 burnFee) external {
        require(burnFee + adminFee < DIVISOR, "Fee too big");

        uint256 burnAmount = amount / DIVISOR * burnFee;
        uint256 adminAmount = amount / DIVISOR * adminFee;
        uint256 receiverAmount = amount - burnAmount - adminAmount;

        admin.transfer(amount);
        burnAddress.transfer(burnAmount);

        emit PaymentDone(msg.sender, receiverAmount, paymentId, block.timestamp);
    }
}