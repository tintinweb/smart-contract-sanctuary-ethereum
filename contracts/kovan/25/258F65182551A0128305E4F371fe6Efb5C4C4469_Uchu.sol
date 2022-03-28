/**
 *Submitted for verification at Etherscan.io on 2022-03-28
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
        uint8 id;
        uint8 yeildNum;
        uint8 totalNum;
        uint8 lockPeriod;
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
        uint256 depositTime;
        uint256 withdrawTime;
    }

    struct Lender {
        uint32 id;
        uint8 proId;
        uint8 proIndex;
        uint256 amount;
        address lender;
        uint256 createPositionTime;
        uint256 closePositionTime;
    }

    struct Borrower {
        uint32 id;
        uint8 proId;
        uint8 proIndex;
        uint256 amount;
        address borrower;
        string repay;
        uint256 updateTime;
    }

    uint8 private productId;
    uint32 private lenderId;
    uint32 private borrowerId;
    mapping (uint8 => Product) public products;
    mapping (uint32 => Lender) private lenders;
    mapping (uint32 => Borrower) private borrowers;
    mapping (string => uint256) private allowance;
    mapping (address => mapping(string => uint256)) private debts;
    mapping (address => mapping(string => uint256)) private balanceOf;
    mapping (address => mapping(uint8 => MaxProduct)) private maxBalance;

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

    function createProduct(uint8 yeildNum, uint8 totalNum, uint8 lockPeriod, string memory asset, string memory name) public {
        require(msg.sender == owner, "Need permission!");
        products[productId] = Product(productId, yeildNum, totalNum, lockPeriod, owner, asset, name, State.FREE, 0, 0);
        productId++;
    }

    /**
    * usrer select product by position & create lender struct
    */
    function selectLendProduct(address user, uint8 index) public returns (uint8 proId) {
        require(productId > index, "No Product!");
        Product memory pro = products[index];
        for(uint32 i=0; i<lenderId; i++) {
            emit Log(owner, "setLendProduct inside", pro.name, lenders[i].proId);
            if(pro.id == lenders[i].proId) {
                return pro.id;
            }
        }
        lenders[lenderId] = Lender(lenderId, pro.id, 0, 0, user, 0, 0);
        lenderId++;
        emit Log(owner, "setLendProduct", pro.name, lenderId);
        return pro.id;
    }

   /**
    * get products from lenders by address
    */
    function getLenderProducts(address user) public view returns (Product[] memory) {
        Product[] memory pro = new Product[](lenderId);
        for(uint32 i=0;i<lenderId;i++) {
            if(user == lenders[i].lender)
                pro[i]= products[lenders[i].proId];
        }
        return pro;
    }

    /**
    * usrer select product by position & create borrower struct
    */
    function selectBorrowProduct(address user, uint8 index) public returns (uint8 proId) {
        require(productId > index, "No Product!");
        Product memory pro = products[index];
        for(uint32 i=0; i<borrowerId; i++) {
            emit Log(owner, "setBorrowProduct inside", pro.name, borrowers[i].proId);
            if(pro.id == borrowers[i].proId) {
                return pro.id;
            }
        }
        borrowers[borrowerId] = Borrower(borrowerId, pro.id, 0, 0, user, "888", 2022);
        borrowerId++;
        emit Log(owner, "setBorrowProduct", pro.name, borrowerId);
        return pro.id;
    }

   /**
    * get products from borrowers by address
    */
    function getBorrowProducts(address user) public view returns (Product[] memory) {
        Product[] memory pro = new Product[](borrowerId);
        for(uint32 i=0;i<borrowerId;i++) {
            if(user == borrowers[i].borrower)
                pro[i]= products[borrowers[i].proId];
        }
        return pro;
    }

    /**
    * return all products
    */
    function getProducts() public view returns (Product[] memory) {
        Product[] memory pro = new Product[](productId);
        for(uint8 i=0;i<productId;i++) {
            pro[i]= products[i];
        }
        return pro;
    }

    /**
    * deposit by current lender product that you selected
    **/
    function deposit(uint8 proId) public payable returns (bool) {
        if (productId > 0) {
            Product memory pro = getProduct(proId);
            balanceOf[msg.sender][pro.name] += msg.value;
            allowance[pro.name] += msg.value;
            setMaxBalance(msg.sender, msg.value, pro,  block.timestamp, 0);
            emit Log(msg.sender, "deposit", pro.name, msg.value);
            return true;
        } else {
            return false;
        }
    }

    function getProduct(uint8 proId) private view returns (Product memory pro) {
        for(uint8 i=0; i<productId; i++) {
            if(proId == products[i].id)
                return products[i];
        }
    }

    function getDeposit(string memory name) public view returns (uint256) {
        return allowance[name];
    }

    function getDeposit(address user, string memory name) public view returns (uint256) {
        return balanceOf[user][name];
    }

    /**
    *   return current lender
    **/
    function getCurLender(address user) private view returns (Lender memory lender) {
        for(uint32 i=0; i<lenderId; i++) {
            if(user == lenders[i].lender){
                lender = lenders[i];
                break;
            }
        }
        return lender;
    }

    /**
    *  caculate user's current product balance with profit
    **/
    function productMaxBalance(address user, uint8 proId) public view returns (uint256) {
        uint8 length = getCurLender(user).proIndex;
        Product memory pro = getProduct(proId);
        uint256 result;
        for(uint8 i=0; i<length; i++) {
            if(maxBalance[user][i].product.id == proId) {
                uint256 start = block.timestamp;
                uint256 end = maxBalance[user][i].depositTime;
                uint256 amount = maxBalance[user][i].num;
                uint256 pow = calculateTimeGap(start, end, pro.lockPeriod * 60);
                uint256 total = pro.yeildNum + pro.totalNum;
                result += amount / (100 ** pow) * (total ** pow);
            }
        }
        return result;
    }

    function getHistory(address user) public view returns (MaxProduct[] memory) {
        uint8 length = getCurLender(user).proIndex;
        MaxProduct[] memory history = new MaxProduct[](length);
        for(uint8 i=0; i<length; i++){
            history[i] = maxBalance[user][i];
        }
        return history;
    }

    /**
    * start: the time
    * end:  the creat time
    * num: the minimum time unit, 60 * 60 = 1 hour
    **/
    function calculateTimeGap(uint256 start, uint256 end, uint128 num) private pure returns (uint256) {
        uint256 period = start - end;
        return (period - (period % num)) / num;
    }

    function withdraw(address user, uint256 amount, uint8 proId) public returns (bool) {
        Product memory pro = getProduct(proId);
        if (balanceOf[user][pro.name] >= amount) {
            allowance[pro.name] -= amount;
            balanceOf[user][pro.name] -= amount;
            setMaxBalance(user, amount, pro, 0, block.timestamp);
            payable(user).transfer(amount);
            return true;
        } else {
            return false;
        }
    }

    /**
    *  set record by current lender's proIndex
    **/
    function setMaxBalance(address user, uint256 amount, Product memory pro, uint256 depositTime, uint256 withdrawTime) private {
        maxBalance[msg.sender][getCurLender(user).proIndex] = MaxProduct(amount, pro, depositTime, withdrawTime);
            for(uint32 i=0; i<lenderId; i++) {
                if(msg.sender == lenders[i].lender) {
                    lenders[i].proIndex++;
                    break;
                }
            }
    }

    function borrow(address user, uint256 amount, uint8 proId) public returns (bool) {
            Product memory pro = getProduct(proId);
        if (allowance[pro.name] >= amount) {
            allowance[pro.name] -= amount;
            debts[user][pro.name] += amount;
            payable(user).transfer(amount);
            return true;
        } else {
            return false;
        }
    }

    function payBack(address user, uint8 proId) public payable returns (bool) {
            Product memory pro = getProduct(proId);
        if (debts[user][pro.name] >= msg.value) {
            allowance[pro.name] += msg.value;
            debts[user][pro.name] -= msg.value;
            return true;
        } else {
            return false;
        }
    }
}