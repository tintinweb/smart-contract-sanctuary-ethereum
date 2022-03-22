/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
//import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

//contract Uchu is Initializable {
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
    mapping (string => uint) public allowance;
    mapping (address => mapping(string => uint)) public debts;
    mapping (address => mapping(string => uint)) public balanceOf;
    mapping (address => mapping(string => uint)) public finalBalance;

    // function initialize() public payable initializer {
    //     owner = payable(msg.sender);
    // }

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
        products[productId] = Product(productId, yeildNum, totalNum, lockPeriod, owner, asset, name, State.FREE);
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
        lenders[lenderId] = Lender(lenderId, State.FREE, pro.id, 0, msg.sender, 0, 0);
        lenderId++;
        curLenderPro = pro;
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

    /**
    * return all products
    */
    function getProducts() public view returns (Product[] memory) {
        Product[] memory pro = new Product[](productId);
        for(uint i=0;i<productId;i++) {
            pro[i]= products[i];
        }
        return pro;
    }

    function deposit() public payable returns (bool) {
        if (productId > 0) {
            balanceOf[msg.sender][curLenderPro.name] += msg.value;
            allowance[curLenderPro.name] += msg.value;
            if(getPoint().createPositionTime == 0) {
                getPoint().createPositionTime = block.timestamp;
            emit Log(msg.sender, "deposit 22", getPoint().createPositionTime);
            }
            emit Log(msg.sender, "deposit", msg.value);
            return true;
        } else {
            return false;
        }
    }

    /**
    *   return current lender
    **/
    function getPoint() private view returns (Lender memory lender) {
        for(uint i=0; i<lenderId; i++) {
            if(lenders[i].proId == curLenderPro.id) {
                lender = lenders[i];
                break;
            }
        }
        return lender;
    }

    function singleBalance() public view returns (uint256) {
        uint amount = balanceOf[msg.sender][curLenderPro.name];
        uint startTime = getPoint().createPositionTime;
        //uint a = block.timestamp - startTime;
        //uint b = 60;
        //uint pow = a/b;
        return amount / (100 ** 2) * ((curLenderPro.yeildNum + curLenderPro.totalNum) ** 2);
    }


    function withdraw(uint amount) public returns (bool) {
        if (balanceOf[msg.sender][curLenderPro.name] >= amount){
            allowance[curLenderPro.name] -= amount;
            payable(msg.sender).transfer(amount);
            balanceOf[msg.sender][curLenderPro.name] -= amount;
            return true;
        } else {
            return false;
        }
    }

    function borrow(uint amount) public returns (bool) {
        if (allowance[curBorrowerPro.name] >= amount) {
            allowance[curBorrowerPro.name] -= amount;
            debts[msg.sender][curBorrowerPro.name] += amount;
            payable(msg.sender).transfer(amount);
            return true;
        } else {
            return false;
        }
    }

    function payBack() public payable returns (bool) {
        if (debts[msg.sender][curBorrowerPro.name] >= msg.value) {
            allowance[curBorrowerPro.name] += msg.value;
            debts[msg.sender][curBorrowerPro.name] -= msg.value;
            return true;
        } else {
            return false;
        }
    }
}