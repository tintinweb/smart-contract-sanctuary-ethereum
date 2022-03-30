/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
//import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

//contract Uchu is Initializable {
contract Uchu {
 
    event Log(address from, string operation, uint8 name, uint256 value);
    address payable public owner;

    /**
    * asset:ETH = 10,USDT = 21,WBTC = 31
    * Product Name is unique and there must not be 2 products that have same names. Product Name = Asset + Number of Day.
    * name:ETH7 = 107,ETH14 = 1014,USDT30 = 2130,USDT90 = 2190,WBTC365 = 31365...
    * the frontend need decode the number to string name for display.
    */
    struct Product {
        uint8 id;
        uint8 yieldNum;
        uint8 totalNum;
        uint8 lockPeriod;
        uint8 asset;
        uint8 name;
        address creator;
        uint256 createTime;
    }

    struct Position {
        uint8 proId;
        uint8 status;
        uint32 lenderId;
        uint32 borrowerId;
        uint256 amount;
        uint256 createTime;
        uint256 closeTime;
    }

    struct Lender {
        uint32 id;
        uint8 proId;
        uint8 posIndex;
        address lender;
    }

    struct Borrower {
        uint32 id;
        uint8 proId;
        uint8 posIndex;
        address borrower;
    }

    /*
    * OPEN: Lender deposited the funds.
    * LOCKTIMEUP_UNREPAID: The position lock time ends but the lender can not withdraw all the funds because the borrower failed to repay the full amount.
    * LOCKTIMEUP_ALL_REPAID: The position lock time ends and the lender can withdraw the funds.
    * CLOSED: Funds are withdrawn by the lender.
    */
    uint8 OPEN = 10;
    uint8 LOCKTIMEUP_UNREPAID = 80;
    uint8 LOCKTIMEUP_ALL_REPAID = 90;
    uint8 CLOSED = 100;
    
    uint8 private productId;
    uint32 private lenderId;
    uint32 private borrowerId;
    mapping (uint8 => Product) private products;
    mapping (uint32 => Lender) private lenders;
    mapping (uint32 => Borrower) private borrowers;
    mapping (uint8 => uint256) private allowance;
    mapping (address => mapping(uint8 => uint256)) private debts;
    mapping (address => mapping(uint8 => uint256)) private balanceOf;
    mapping (address => mapping(uint8 => Position)) private positions;

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

    function createProduct(uint8 yeildNum, uint8 totalNum, uint8 lockPeriod, uint8 asset, uint8 name) public {
        require(msg.sender == owner, "Need permission!");
        products[productId] = Product(productId, yeildNum, totalNum, lockPeriod, asset, name, owner, 0);
        createBorrower(owner, productId);
        productId++;
    }

    function createBorrower(address user, uint8 index) private {
        Product memory pro = products[index];
        for(uint32 i=0; i<borrowerId; i++) {
            if(pro.id == borrowers[i].proId) {
                return;
            }
        }
        borrowers[borrowerId] = Borrower(borrowerId + 1, pro.id, 0, user);
        borrowerId++;
    }

   /**
    * get products from borrowers by address.
    */
    function getBorrowerProducts(address user) public view returns (Product[] memory) {
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

    function getProduct(uint8 proId) public view returns (Product memory pro) {
        for(uint8 i=0; i<productId; i++) {
            if(proId == products[i].id)
                return products[i];
        }
    }

    /**
    * deposit by current product, proId = index
    **/
    function deposit(uint8 proId) public payable returns (bool) {
        if (productId > 0) {
            Product memory pro = getProduct(proId);
            balanceOf[msg.sender][pro.name] += msg.value;
            allowance[pro.name] += msg.value;
            createLender(msg.sender, proId);
            createPosition(proId, OPEN, msg.sender, msg.value,  block.timestamp, 0);
            emit Log(msg.sender, "deposit", pro.name, msg.value);
            return true;
        } else {
            return false;
        }
    }

    function createLender(address user, uint8 index) private {
        Product memory pro = products[index];
        for(uint32 i=0; i<lenderId; i++) {
            if(pro.id == lenders[i].proId) {
                return;
            }
        }
        lenders[lenderId] = Lender(lenderId + 1, pro.id, 0, user);
        lenderId++;
    }

    /**
    *  insert record by current lender's positionIndex
    **/
    function createPosition(uint8 proId, uint8 status, address user, uint256 amount, uint256 depositTime, uint256 withdrawTime) private {
        Lender memory lender = getCurLender(user);
        positions[msg.sender][lender.posIndex] = Position(proId, status, lender.id, 0, amount, depositTime, withdrawTime);
            for(uint32 i=0; i<lenderId; i++) {
                if(msg.sender == lenders[i].lender) {
                    lenders[i].posIndex++;
                    break;
                }
            }
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

    function getDeposit(uint8 name) public view returns (uint256) {
        return allowance[name];
    }

    function getDeposit(address user, uint8 name) public view returns (uint256) {
        return balanceOf[user][name];
    }

    /**
    *   return current lender
    **/
    function getCurLender(address user) private view returns (Lender memory lender) {
        for(uint32 i=0; i<lenderId; i++) {
            if(user == lenders[i].lender) {
                lender = lenders[i];
                break;
            }
        }
        return lender;
    }

    /**
    *  caculate user's current product balance with profit
    **/
    function getProductReturn(address user, uint8 proId) public view returns (uint256) {
        uint8 length = getCurLender(user).posIndex;
        Product memory pro = getProduct(proId);
        uint256 result;
        for(uint8 i=0; i<length; i++) {
            if(positions[user][i].proId == proId) {
                uint256 start = block.timestamp;
                uint256 end = positions[user][i].createTime;
                uint256 amount = positions[user][i].amount;
                uint256 pow = calculateTimeGap(start, end, pro.lockPeriod);
                uint256 total = pro.yieldNum + pro.totalNum;
                result += amount / (100 ** pow) * (total ** pow);
            }
        }
        return result;
    }

    function getPositions(address user) public view returns (Position[] memory) {
        uint8 length = getCurLender(user).posIndex;
        Position[] memory history = new Position[](length);
        for(uint8 i=0; i<length; i++) {
            history[i] = positions[user][i];
        }
        return history;
    }

    /**
    * start: the time
    * end:  the creat time
    * period: the minimum time unit of day
    **/
    function calculateTimeGap(uint256 start, uint256 end, uint128 period) private pure returns (uint256) {
        uint256 step = start - end;
        uint256 num = 60 * 60 * 24 * period;
        uint256 base = step - (step % num);
        if (base <= num) {
            return 1;
        }
        return base / num;
    }

    function withdraw(address user, uint256 amount, uint8 proId) public returns (bool) {
        Product memory pro = getProduct(proId);
        if (balanceOf[user][pro.name] >= amount) {
            allowance[pro.name] -= amount;
            balanceOf[user][pro.name] -= amount;
            createPosition(proId, CLOSED, user, amount, 0, block.timestamp);
            payable(user).transfer(amount);
            return true;
        } else {
            return false;
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

    function repay(address user, uint8 proId) public payable returns (bool) {
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