/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract ComicStore {
    // Defining Store Variables (State Variables)
    address public immutable storeOwner;
    uint256 public storeAcc;
    string public storeName;
    uint256 public immutable TaxPercent;
    uint256 public storeSales;

    // Tracking users number of sales
    mapping(address => uint256) public salesOf;

    //Declaring Events within each sale
    event Sale(
        address indexed buyer,
        address indexed seller,
        uint256 amount,
        uint256 timestamp
    );

    event Withdrawal(
        address indexed receiver,
        uint256 amount,
        uint256 timestamp
    );

    // Structuring the sales object
    struct SalesStruct {
        address buyer;
        address seller;
        uint256 amount;
        string purpose_of_sale;
        uint256 timestamp;
    }

    SalesStruct[] sales;

    //Initializing the ComicStore
    constructor(
        string memory _storeName,
        address _storeOwner,
        uint256 _TaxPercent
    ){
        storeName = _storeName;
        storeOwner = _storeOwner;
        TaxPercent = _TaxPercent;
        storeAcc = 0;
    }

    //PayNow
    //_PayTo -- Send funds to someone
    //WithdrawMoneyTo -- Send funds to an account
    //GetAllSales

    //Perform Sales Payment
    function payNow(address seller, string memory purpose_of_sale)
        public
        payable
        returns(bool success){
            
            //Validating Payments
            require(msg.value > 0, "Ethers can not be zero");
            require(msg.sender != storeOwner, "Sale Not Allowed");

            //Calculating the cost and tax fees
            uint256 fee = (msg.value / 100) * TaxPercent;
            uint256 cost = msg.value - fee;

            //Assigning sales and payment to the store and product owner
            storeAcc += msg.value;
            storeSales += 1;
            salesOf[seller] += 1;

            // Cashing out to sales party
            withdrawMoneyTo(storeOwner, fee);
            withdrawMoneyTo(seller, cost);

            //Record sales in smart contract
            sales.push(
                SalesStruct(msg.sender, seller, cost, purpose_of_sale, block.timestamp)
            );

            //Captures sales data on event
            emit Sale(msg.sender, seller, cost, block.timestamp);
            return true;
        }

        // Sends ethers to a specified address
        function _payTo(address _to, uint256 _amount) internal {
            (bool success1, ) = payable(_to).call{value:_amount}("");
            require(success1);
        }

        // Performs ethers transfer
        function withdrawMoneyTo(address receiver, uint256 amount) internal returns (bool success) {
            require(storeAcc >= amount, "Insuffient Funds");

            _payTo(receiver, amount);
            storeAcc -= amount;

            //Captures transfer data on event
            emit Withdrawal(receiver, amount, block.timestamp);
            return true;
        }

        // Retrieves all processed sales from smart contract
        function getAllSales() public view returns(SalesStruct[] memory){
            return sales;
        }


}