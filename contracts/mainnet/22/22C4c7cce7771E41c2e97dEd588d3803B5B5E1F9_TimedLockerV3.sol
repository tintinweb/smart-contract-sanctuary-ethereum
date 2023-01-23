/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Timed Locker Contract
contract TimedLockerV3 {

    struct PaymentEnvelop {
        uint amountLocked; 
        uint lockedUntil; 
    }
    event Deposited(address depositor, address payee, uint amount, uint lockedUntil);
    event Disbursed(address depositor, address payee, uint amount);

    // mapping of depositor and its all payee and payment envelops
    mapping(address => mapping(address => PaymentEnvelop[])) accountDeposits;
    
    // Returns all the deposits made by given address for the given payee
    function getDepositEnvelops(address depositorAddress, address payeeAddress) external view returns (PaymentEnvelop[] memory envelops) {
        envelops = accountDeposits[depositorAddress][payeeAddress];
    }

    // deposit passed wei amount and lock it until given unix epoch time seconds
    function deposit(uint lockedUntil, address payeeAddress) external payable {
        require(msg.value > 0, "Nothing to deposit.");
        require(payeeAddress != address(0), "Invalid payee address.");
        
        PaymentEnvelop[] storage depositEnvelops = accountDeposits[msg.sender][payeeAddress];
        require(depositEnvelops.length < 10, "You cannot have more than 10 deposits for one payee.");
        depositEnvelops.push(PaymentEnvelop(msg.value, lockedUntil));
        
        emit Deposited(msg.sender, payeeAddress, msg.value, lockedUntil);
    }

    // Disburse all elgible enevelops for the given address. If no address is passed then deposits of sender's address
    // is disbursed
    function disburse(address depositorAddress, address payeeAddress) external {
        require(depositorAddress != address(0), "Invalid depositor address.");
        require(payeeAddress != address(0), "Invalid payee address.");
        PaymentEnvelop[] storage envelops = accountDeposits[depositorAddress][payeeAddress];
        require(envelops.length > 0, "There is no deposit envelops for given depositor and payee.");
        uint disbursementAmount = 0;
        for (uint i=0; i<envelops.length; i++) {
            if(envelops[i].lockedUntil <= block.timestamp) {
                disbursementAmount += envelops[i].amountLocked;
                envelops[i] = envelops[envelops.length-1];
                envelops.pop();
            }
        }

        require(disbursementAmount > 0, "There is no eligible deposit envelops for disbursement for given depositor and payee.");

        (payable(payeeAddress)).transfer(disbursementAmount);

        emit Disbursed(depositorAddress, payeeAddress, disbursementAmount);
    }
}