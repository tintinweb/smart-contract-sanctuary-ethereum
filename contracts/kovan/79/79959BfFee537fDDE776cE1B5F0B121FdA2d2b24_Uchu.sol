/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
//import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

//contract Uchu is Initializable {
contract Uchu {
 
    event Log(address from, string operation, string name, uint256 value);
    address payable public owner;
    enum State { FREE,BUSY }

    struct Product{
        uint128 id;
        uint yeildNum;
        uint totalNum;
        uint lockPeriod;
        address creator;
        string asset;
        string name;
        State state;
        uint256 createPositionTime;
        uint256 closePositionTime;
    }

    struct MaxProduct{
        uint256 num;
        Product product;
        uint256 createPositionTime;
        uint256 closePositionTime;
    }

    struct Lender {
        uint128 id;
        State state;
        uint128 proId;
        uint128 proIndex;
        uint256 amount;
        address lender;
        uint256 createPositionTime;
        uint256 closePositionTime;
    }

    struct Borrower {
        uint128 id;
        State state;
        uint128 proId;
        uint128 proIndex;
        uint256 amount;
        address borrower;
        string repay;
        uint256 updateTime;
    }

    uint128 private productId;
    uint128 private lenderId;
    uint128 private borrowerId;
    Product public curLenderPro;
    Product private curBorrowerPro;
    mapping (uint128 => Product) public products;
    mapping (uint128 => Lender) public lenders;
    mapping (uint128 => Borrower) public borrowers;
    mapping (string => uint256) public allowance;
    mapping (address => mapping(string => uint256)) public debts;
    mapping (address => mapping(string => uint256)) public balanceOf;
    mapping (address => mapping(uint128 => MaxProduct)) public maxBalance;

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
        products[productId] = Product(productId, yeildNum, totalNum, lockPeriod, owner, asset, name, State.FREE, 0, 0);
        productId++;
    }

    /**
    * usrer select product by position & create lender struct
    */
    function setLendProduct(uint128 index) public returns (Product memory) {
        require(productId > index, "No Product!");
        Product memory pro = products[index];
        curLenderPro = pro;
        for(uint128 i=0; i<lenderId; i++) {
            emit Log(owner, "setLendProduct inside", pro.name, lenders[i].proId);
            if(pro.id == lenders[i].proId) {
                return pro;
            }
        }
        lenders[lenderId] = Lender(lenderId, State.FREE, pro.id, 0, 0, msg.sender, 0, 0);
        lenderId++;
        emit Log(owner, "setLendProduct", pro.name, lenderId);
        return pro;
    }

   /**
    * get products from lenders by address
    */
    function getLenderProducts() public view returns (Product[] memory) {
        Product[] memory pro = new Product[](lenderId);
        for(uint128 i=0;i<lenderId;i++) {
            if(msg.sender == lenders[i].lender)
                pro[i]= products[lenders[i].proId];
        }
        return pro;
    }

    /**
    * usrer select product by position & create borrower struct
    */
    function setBorrowProduct(uint128 index) public returns (Product memory) {
        require(productId > index, "No Product!");
        Product memory pro = products[index];
        curBorrowerPro = pro;
        for(uint128 i=0; i<borrowerId; i++) {
            emit Log(owner, "setBorrowProduct inside", pro.name, borrowers[i].proId);
            if(pro.id == borrowers[i].proId) {
                return pro;
            }
        }
        borrowers[borrowerId] = Borrower(borrowerId, State.FREE, pro.id, 0, 0, msg.sender, "888", 2022);
        borrowerId++;
        emit Log(owner, "setBorrowProduct", pro.name, borrowerId);
        return pro;
    }

   /**
    * get products from borrowers by address
    */
    function getBorrowProducts() public view returns (Product[] memory) {
        Product[] memory pro = new Product[](borrowerId);
        for(uint128 i=0;i<borrowerId;i++) {
            if(msg.sender == borrowers[i].borrower)
                pro[i]= products[borrowers[i].proId];
        }
        return pro;
    }

    function getProductLength() public view returns (uint128) {
        return productId;
    }

    /**
    * return all products
    */
    function getProducts() public view returns (Product[] memory) {
        Product[] memory pro = new Product[](productId);
        for(uint128 i=0;i<productId;i++) {
            pro[i]= products[i];
        }
        return pro;
    }

    /**
    * deposit by current lender product that you selected
    **/
    function deposit() public payable returns (bool) {
        if (productId > 0) {
            balanceOf[msg.sender][curLenderPro.name] += msg.value;
            allowance[curLenderPro.name] += msg.value;
            maxBalance[msg.sender][getCurLender().proIndex] = MaxProduct(msg.value, curLenderPro, block.timestamp, 0);
            for(uint128 i=0; i<lenderId; i++) {
                if(msg.sender == lenders[i].lender) {
                    lenders[i].proIndex++;
                    break;
                }
            }
            emit Log(msg.sender, "deposit", curLenderPro.name, msg.value);
            emit Log(msg.sender, "deposit", "maxBalance", getCurLender().proIndex);
            return true;
        } else {
            return false;
        }
    }

    /**
    *   return current lender
    **/
    function getCurLender() private view returns (Lender memory user) {
        for(uint128 i=0; i<lenderId; i++) {
            if(msg.sender == lenders[i].lender){
                user = lenders[i];
                break;
            }
        }
        return user;
    }

    function singleBalance() public view returns (uint256) {
        uint128 length = getCurLender().proIndex;
        uint128 proId = curLenderPro.id;
        uint256 result;
        for(uint128 i=0; i<length; i++) {
            if(maxBalance[msg.sender][i].product.id == proId) {
                uint256 start = block.timestamp;
                uint256 end = maxBalance[msg.sender][i].createPositionTime;
                uint256 amount = maxBalance[msg.sender][i].num;
                uint pow = caculateTimeGap(start, end, 60 * 2);
                result += amount / (100 ** pow) * ((curLenderPro.yeildNum + curLenderPro.totalNum) ** pow);
            }
        }
        return result;
    }

    /**
    * start: the time
    * end:  the creat time
    * num: the minimum time unit, 60 * 2 = 2 min
    **/
    function caculateTimeGap(uint256 start, uint256 end, uint128 num) private pure returns (uint256) {
        uint256 period = start - end;
        return (period - (period % num)) / num;
    }

    function withdraw(uint256 amount) public returns (bool) {
        if (balanceOf[msg.sender][curLenderPro.name] >= amount){
            allowance[curLenderPro.name] -= amount;
            payable(msg.sender).transfer(amount);
            balanceOf[msg.sender][curLenderPro.name] -= amount;
            return true;
        } else {
            return false;
        }
    }

    function borrow(uint256 amount) public returns (bool) {
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