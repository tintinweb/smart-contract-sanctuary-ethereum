/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Uchu {
    address payable public owner;
    enum State { FREE,BUSY }

    struct Product{
        uint yeildNum;
        uint totalNum;
        uint lockPeriod;
        address creator;
        string asset;
        string name;
        State state;
    }

    uint private productId;
    mapping (uint => Product) public products;
    mapping (uint => Lender) public lenders;
    mapping (uint => Borrower) public borrowers;

    function createProduct(uint yeildNum, uint totalNum, uint lockPeriod, string memory asset, string memory name) public {
        require(msg.sender == owner, "Need permission");
        products[productId] = Product(yeildNum, totalNum, lockPeriod, owner, asset, name, State.FREE);
        productId++;
    }

    function getProductLength() public view returns (uint) {
        return productId;
    }

    function getProducts() public view returns (Product[] memory) {
        Product[] memory pros = new Product[](productId);
        for(uint i=0;i<productId;i++) {
            pros[i]= products[i];
        }
        return pros;
    }

    struct Lender {
        uint id;
        uint state;
        uint proId;
        uint256 amount;
        address lender;
        string createPositionTime;
        string closePositionTime;
    }

    struct Borrower {
        uint id;
        uint state;
        uint256 amount;
        uint proId;
        address borrower;
        string repay;
        string updateTime;
    }

    constructor() {
        owner = payable(msg.sender);
    }
    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    function deposit(uint amount) public payable {
        balanceOf[msg.sender] += amount;
    }

    function withdraw(uint amount) public payable {
        require(balanceOf[msg.sender] >= amount, "Balance is not enough!");
        balanceOf[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}