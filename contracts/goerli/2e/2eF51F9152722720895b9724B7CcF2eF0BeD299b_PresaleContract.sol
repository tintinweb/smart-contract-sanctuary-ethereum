/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SSSSS  H     H  IIIII  PPPPP   CCCCC   OOOO   IIIII  N    N
// S      H     H    I    P    P C     C O    O    I    NN   N
// SSS    HHHHHHH    I    PPPPP  C       O    O    I    N N  N
//    S   H     H    I    P      C     C O    O    I    N  N N
// SSS    H     H  IIIII  P       CCCCC   OOOO   IIIII  N    N

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PresaleContract {
    address public owner;
    uint256 public hardCap;
    uint256 public totalReceived;
    bool public refunding;
    mapping(address => uint256) public balances;

    event ContributionReceived(address sender, uint256 amount);
    event Refund(address recipient, uint256 amount);

    constructor(uint256 _hardCap) {
        owner = msg.sender;
        hardCap = _hardCap;
        refunding = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    function contribute() external payable {
        require(!refunding, "Refunds are currently being processed");
        require(msg.value > 0, "Amount must be greater than zero");

        uint256 newBalance = balances[msg.sender] + msg.value;
        require(newBalance <= hardCap, "Hard cap reached");

        balances[msg.sender] = newBalance;
        totalReceived += msg.value;
        emit ContributionReceived(msg.sender, msg.value);

        if (totalReceived >= hardCap) {
            refunding = true;
            sendRefunds();
        }
    }

    function sendRefunds() internal {
        for (uint256 i = 0; i < msg.sender.balance; i++) {
            address payable recipient = payable(msg.sender);
            uint256 refundAmount = balances[recipient];
            if (refundAmount > 0) {
                balances[recipient] = 0;
                recipient.transfer(refundAmount);
                emit Refund(recipient, refundAmount);
            }
        }
    }

    function withdrawFunds() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract balance must be greater than zero");

        payable(owner).transfer(contractBalance);
    }
}