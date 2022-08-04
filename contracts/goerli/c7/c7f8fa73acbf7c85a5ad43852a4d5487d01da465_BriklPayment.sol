/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract BriklPayment {
    address public owner = msg.sender;
    uint256 public lastTransactionId;

    struct TransactionData {
        address userWallet;
        uint256 transactionId;
        uint256 timestamp;
        uint256 amount;
    }

    struct CustomerData {
        address userWallet;
        string name;
        string email;
        string phone;
    }

    TransactionData[] public allTransactions;
    CustomerData[] public allCustomers;

    constructor() {
        lastTransactionId = 0;
    }

    function getTransactionData(uint256 txnId)
        public
        view
        returns (TransactionData memory)
    {
        for (uint256 i = 0; i < allTransactions.length; i++) {
            TransactionData memory data = allTransactions[i];
            if (data.transactionId == txnId) {
                return data;
            }
        }

        return
            TransactionData({
                userWallet: address(0x0),
                transactionId: uint256(1),
                timestamp: uint256(1),
                amount: uint256(0)
            });
    }

    function getCustomerData(address walletAddress)
        public
        view
        returns (CustomerData memory)
    {
        for (uint256 i = 0; i < allCustomers.length; i++) {
            CustomerData memory data = allCustomers[i];
            if (data.userWallet == walletAddress) {
                return data;
            }
        }

        return
            CustomerData({
                userWallet: address(0x0),
                name: string(""),
                email: string(""),
                phone: string("")
            });
    }

    function createPayment() public payable returns (bool) {
        assert(msg.value > 0);

        uint256 updatedTransactionId = lastTransactionId + 1;

        lastTransactionId = updatedTransactionId;

        TransactionData memory data = TransactionData({
            userWallet: msg.sender,
            transactionId: updatedTransactionId,
            timestamp: block.timestamp,
            amount: msg.value
        });

        allTransactions.push(data);

        return true;
    }

    function createMyData(
        string memory _name,
        string memory _email,
        string memory _phone
    ) public returns (bool) {
        require(
            bytes(_name).length > 0 &&
                bytes(_email).length > 0 &&
                bytes(_phone).length > 0
        );

        CustomerData memory data = CustomerData({
            userWallet: msg.sender,
            name: _name,
            email: _email,
            phone: _phone
        });

        allCustomers.push(data);

        return true;
    }

    function updateMyData(
        string memory _name,
        string memory _email,
        string memory _phone
    ) public returns (bool) {
        require(
            bytes(_name).length > 0 &&
                bytes(_email).length > 0 &&
                bytes(_phone).length > 0
        );

        for (uint256 i = 0; i < allCustomers.length; i++) {
            CustomerData memory data = allCustomers[i];
            if (data.userWallet == msg.sender) {
                allCustomers[i].name = _name;
                allCustomers[i].email = _email;
                allCustomers[i].phone = _phone;
            }
        }

        return true;
    }
}