/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Uchu {
    address payable public owner;
    enum State { FREE,BUSY }

    struct Product{
        uint id;
        uint yeildNum;
        uint totalNum;
        uint lockPeriod;
        address creator;
        string asset;
        string name;
        State state;
    }

    struct Lender {
        uint id;
        State state;
        uint proId;
        uint256 amount;
        address lender;
        string createPositionTime;
        string closePositionTime;
    }

    struct Borrower {
        uint id;
        State state;
        uint proId;
        uint256 amount;
        address borrower;
        string repay;
        string updateTime;
    }

    uint private productId;
    uint private lenderId;
    uint private borrowerId;
    mapping (uint => Product) private products;
    mapping (uint => Lender) private lenders;
    mapping (uint => Borrower) private borrowers;

    constructor() {
        owner = payable(msg.sender);
    }

    function createProduct(uint yeildNum, uint totalNum, uint lockPeriod, string memory asset, string memory name) public {
        require(msg.sender == owner, "Need permission!");
        products[productId] = Product(productId,yeildNum, totalNum, lockPeriod, owner, asset, name, State.FREE);
        productId++;
    }

    function setLendProduct(uint index) public returns (Product memory){
        require(productId > index, "No Product!");
        Product memory pro = products[index];
        lenders[lenderId] = Lender(lenderId, State.FREE, pro.id, 0, msg.sender, "2022", "2022");
        lenderId++;
        return pro;
    }

    function setBorrowProduct(uint index) public returns (Product memory){
        require(productId > index, "No Product!");
        Product memory pro = products[index];
        borrowers[borrowerId] = Borrower(borrowerId, State.FREE, pro.id, 0, msg.sender, "2022", "2022");
        borrowerId++;
        return pro;
    }

    function getLenderProducts() public view returns (Product[] memory) {
        Product[] memory pro = new Product[](lenderId);
        for(uint i=0;i<lenderId;i++) {
            pro[i]= products[lenders[i].proId];
        }
        return pro;
    }

    function getBorrowProducts() public view returns (Product[] memory) {
        Product[] memory pro = new Product[](borrowerId);
        for(uint i=0;i<borrowerId;i++) {
            pro[i]= products[borrowers[i].proId];
        }
        return pro;
    }

    function getProductLength() public view returns (uint) {
        return productId;
    }

    function getProducts() public view returns (Product[] memory) {
        Product[] memory pro = new Product[](productId);
        for(uint i=0;i<productId;i++) {
            pro[i]= products[i];
        }
        return pro;
    }
}