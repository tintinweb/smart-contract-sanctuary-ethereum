/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Escrow {
    enum State { AWAITING_DELIVERY, AWAITING_CONFIRMATION, COMPLETE }
    
    address public owner;

    struct TransactionStruct {
        bool isActive;
        address payable buyer;
        address payable seller;
        State currState;
        uint256 amount;
    }

    mapping (string => TransactionStruct) public txns;

    modifier onlyCreator() {
        require(msg.sender == owner, "Only the contract creator can call this method");
        _;
    }

    modifier onlyBuyer(string memory _id) {
        require(msg.sender == txns[_id].buyer, "Only the buyer can call this method");
        _;
    }

    modifier onlySeller(string memory _id) {
        require(msg.sender == txns[_id].seller, "Only the seller can call this method");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }

    function createEscrow(string memory id, address payable seller) external payable {
        if(isExistingTransaction(id)) revert();
        txns[id].isActive = true;
        txns[id].amount = msg.value;
        txns[id].buyer = payable(msg.sender);
        txns[id].seller = seller;
        txns[id].currState = State.AWAITING_DELIVERY;
    }
    
    function isExistingTransaction(string memory id) public view returns(bool isIndeed) {
        return txns[id].isActive;
    }

    function buyConfirm(string memory id) onlyBuyer(id) external {
        require(txns[id].currState == State.AWAITING_CONFIRMATION, "Seller hasn't confirmed yet.");
        txns[id].currState = State.COMPLETE;
        txns[id].seller.transfer(txns[id].amount);
        txns[id].isActive = false;
    }

    function sellerConfirm(string memory id) onlySeller(id) external {
        require(txns[id].currState == State.AWAITING_DELIVERY, "Transaction not active.");
        txns[id].currState = State.AWAITING_CONFIRMATION;
    }
}