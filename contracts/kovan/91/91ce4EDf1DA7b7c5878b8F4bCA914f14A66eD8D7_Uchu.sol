/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Uchu {
    address payable public owner;
    enum State { FREE,BUSY }

    struct Product{
        uint id;
        uint lockPeriod;
        State state;
        address creator;
        string asset;
        string name;
    }
    uint private productId;
    mapping (uint => Product) products;
    mapping (uint => Lender) lenders;
    mapping (uint => Borrower) borrowers;


    function createProduct(uint lockPeriod,string memory asset,string memory name) public {
        products[productId] = Product(productId, lockPeriod, State.FREE, owner, asset, name);
        productId++;
    }

    function getProduct(uint id) public view returns (Product memory) {
        return products[id];
    }

    struct Lender {
        uint id;
        uint state;
        uint proId;
        uint256 amount;
        string lender;
        string createPositionTime;
        string closePositionTime;
    }
    struct Borrower {
        uint id;
        uint state;
        uint256 amount;
        uint proId;
        string repay;
        string updateTime;
    }

    constructor() {
        owner = payable(msg.sender);
    }
}