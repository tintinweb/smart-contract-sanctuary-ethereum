// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract TransactionRecord {
    address public owner;

    mapping(address => customer) public customers;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct customer { address customerId; string name; uint256 mobile; string product_name; uint256 price; uint256 productCode; string Address; string city; bool isExist;
    }

    function entry( address customerId, string memory name, uint256 mobile, string memory product_name, uint256 price, uint256 productCode, string memory Address, string memory city
    ) public onlyOwner {
        require(
            customers[customerId].isExist == false,
            "customer registerd already and cannot be altered"
        );

        customers[customerId] = customer(
            customerId,
            name,
            mobile,
            product_name,
            price,
            productCode,
            Address,
            city,
            true
        );
    }
}