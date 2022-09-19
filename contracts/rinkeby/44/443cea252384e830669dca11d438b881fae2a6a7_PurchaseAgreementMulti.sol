/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract PurchaseAgreementMulti {

    uint public value;
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
        value = 0;
    }

    /// Only seller can call this function
    error OnlyOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    function confirmPurchase() external payable {
        value = value + msg.value;
    }

    function payOwner(uint amount) external onlyOwner {
        owner.transfer(amount);
        value = value - amount;
    }

    function payBuyer(address buyer, uint amount) external onlyOwner {
        payable(buyer).transfer(amount);
        value = value - amount;
    }
}