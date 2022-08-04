/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract BriklPayment {
    address public owner = msg.sender;
    uint128 public lastTransactionId;

    struct TransactionData {
        address userWallet;
        uint256 transactionId;
        uint256 timestamp;
        uint256 amount;
    }

    struct CustomerData {
        address userWallet;
        string userName;
    }

    mapping(address => TransactionData) public allTransactions; 
    mapping(address => CustomerData) public allUsers;


    constructor() {
        lastTransactionId = 0;
    }

    // modifier restricted() {
    //     require(
    //         msg.sender == owner,
    //         "This function is restricted to the contract's owner"
    //     );
    //     _;
    // }

    // function viewTransactions(uint256 limit, uint256 offset) public restricted {
    //     last_completed_migration = completed;
    // }

    // function createPayment(uint256 amount, address receiver) public {
    //     require(amount > 0);
    //     require(receiver != address(0));
    //     Brikl.createPayment(amount, receiver);
    // }

    // function createPayment(address userWallet, uint amount) public payable returns (bool) {
    function createPayment() public payable returns (bool) {

        // require(amount > 0);
        assert(msg.value > 0);

        uint128 updatedTransactionId = lastTransactionId + 1;

        lastTransactionId = updatedTransactionId;

        TransactionData memory data = TransactionData({
            userWallet: msg.sender,
            transactionId: updatedTransactionId,
            timestamp: block.timestamp,
            amount: msg.value
        });

        // allTransactions[address(0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC)].userTransactions["test"] = data;

        allTransactions[msg.sender] = data;

        return true;
    }
}