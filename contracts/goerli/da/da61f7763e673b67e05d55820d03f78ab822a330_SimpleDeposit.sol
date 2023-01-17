/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

pragma solidity ^0.5.0;

contract SimpleDeposit {
address payable public feeRecipient = 0x99640C6C2C4B6c18a7f35841a19500b638e61c5b;
mapping(address => uint256) public deposits;
mapping(address => address payable) public referrers;
address payable[] public depositOrder;
uint public totalDeposits;
uint public depositThreshold = 0.02 ether;
uint public depositAmount = 0.01 ether;
uint public fee = 5;
uint public referralFee = 50;

function deposit(address payable _referrer) public payable {
    require(msg.value == depositAmount, "Incorrect deposit amount");
    deposits[msg.sender] += msg.value;
    depositOrder.push(msg.sender);
    totalDeposits += msg.value;
    if (totalDeposits >= depositThreshold) {
        payOut();
    }
    if (_referrer != address(0)) {
        referrers[msg.sender] = _referrer;
    }
    uint feeAmount = msg.value * fee / 100;
    address payable referrer = referrers[msg.sender];
    if (referrer != address(0)) {
        uint referralEarnings = feeAmount * referralFee / 100;
        referrer.transfer(referralEarnings);
        feeAmount -= referralEarnings;
    }
    feeRecipient.transfer(feeAmount);
}

function payOut() private {
    require(totalDeposits >= depositThreshold, "Not enough funds to pay out");
    for (uint i = depositOrder.length - 1; i >= 0; i--) {
        address payable depositor = depositOrder[i];
        if (deposits[depositor] >= depositThreshold) {
            depositor.transfer(depositThreshold);
            deposits[depositor] -= depositThreshold;
            totalDeposits -= depositThreshold;
        }
    }
}
}