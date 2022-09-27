// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Payment {
    address public owner;

    event payment_received(address from, uint256 amount);

    struct purchases {
        uint timestamp;
        uint256 amount;
    }

    mapping(address=>purchases[]) public userPaymentHistory;
    mapping(address=>uint256) public userPayments;

    constructor() {
        owner = msg.sender;
    }

    function getCredits() public payable {
        processPayment(msg.sender, msg.value);
    }

    function processPayment(address from, uint256 amount) internal {
        userPaymentHistory[from].push(purchases(block.timestamp, amount));
        userPayments[from] = userPayments[from]+1;
        emit payment_received(from, amount);
    }
    
    function cashout() public {
        payable(owner).transfer(address(this).balance);
    }
    
    receive() external payable {
        processPayment(msg.sender, msg.value);
    }
    
    fallback() external payable {
        processPayment(msg.sender, msg.value);
    }
}