/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Uchu {
 
    event Log(address from, string operation, uint amount);
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
        uint256 createPositionTime;
        uint256 closePositionTime;
    }

    struct Borrower {
        uint id;
        State state;
        uint proId;
        uint256 amount;
        address borrower;
        string repay;
        uint256 updateTime;
    }

    uint private productId;
    uint private lenderId;
    uint private borrowerId;
    Product private curLenderPro;
    Product private curBorrowerPro;
    mapping (uint => Product) public products;
    mapping (uint => Lender) public lenders;
    mapping (uint => Borrower) public borrowers;
    mapping (address => mapping(string => uint)) public balanceOf;
    mapping(string => uint) public allowance;

    constructor() {
        owner = payable(msg.sender);
    }    
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function changeOwner(address payable newOwner) public isOwner {
        owner = newOwner;
    }

    function createProduct(uint yeildNum, uint totalNum, uint lockPeriod, string memory asset, string memory name) public {
        require(msg.sender == owner, "Need permission!");
        products[productId] = Product(productId,yeildNum, totalNum, lockPeriod, owner, asset, name, State.FREE);
        productId++;
    }

    /**
    * usrer select product by position & create lender struct
    */
    function setLendProduct(uint index) public returns (Product memory) {
        require(productId > index, "No Product!");
        Product memory pro = products[index];
        for(uint i=0; i<lenderId; i++) {
            require(pro.id != lenders[i].proId, "It's repetitive!");
        }
        lenders[lenderId] = Lender(lenderId, State.FREE, pro.id, 0, msg.sender, block.timestamp, 2022);
        lenderId++;
        curLenderPro = pro;
        return pro;
    }

    /**
    * usrer select product by position & create borrower struct
    */
    function setBorrowProduct(uint index) public returns (Product memory) {
        require(productId > index, "No Product!");
        Product memory pro = products[index];
        for(uint i=0; i<borrowerId; i++) {
            require(pro.id != borrowers[i].proId, "It's repetitive!");
        }
        borrowers[borrowerId] = Borrower(borrowerId, State.FREE, pro.id, 0, msg.sender, "888", 2022);
        borrowerId++;
        curBorrowerPro = pro;
        return pro;
    }

   /**
    * get products from lenders by address
    */
    function getLenderProducts() public view returns (Product[] memory) {
        Product[] memory pro = new Product[](lenderId);
        for(uint i=0;i<lenderId;i++) {
            if(msg.sender == lenders[i].lender)
                pro[i]= products[lenders[i].proId];
        }
        return pro;
    }

   /**
    * get products from borrowers by address
    */
    function getBorrowProducts() public view returns (Product[] memory) {
        Product[] memory pro = new Product[](borrowerId);
        for(uint i=0;i<borrowerId;i++) {
            if(msg.sender == borrowers[i].borrower)
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

    function deposit() public payable {
        require(productId>0, "Create product please!");
        balanceOf[msg.sender][curLenderPro.name] += msg.value;
        allowance[curLenderPro.name] += msg.value;
    }

    function withdraw(uint amount) public returns(uint) {
        require(balanceOf[msg.sender][curLenderPro.name] >= amount);
        allowance[curLenderPro.name] -= amount;
        payable(msg.sender).transfer(amount);
        return balanceOf[msg.sender][curLenderPro.name] -= amount;
    }
}