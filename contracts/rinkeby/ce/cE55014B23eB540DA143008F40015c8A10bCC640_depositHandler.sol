/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// SPDX-License-Identifier: NONE



pragma solidity ^0.8.11;

interface IPayment {
    function refund(address _payee, uint256 _amount) external payable;
}

contract depositHandler {

    address payable public owner;    // current owner of the contract
    //address payable public Payments ;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw(uint _amount, address _payee) external {
        require(msg.sender == owner, "Only owner can call this method.");
        payable(_payee).transfer(_amount);
    }

        
    function callRefund(address payable _refundContract, address payable _payee, uint256 _amount) external payable {
        require(msg.sender == owner, "Only owner can call this method.");
        IPayment(_refundContract).refund{value: msg.value}(_payee, _amount);
        
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }
}