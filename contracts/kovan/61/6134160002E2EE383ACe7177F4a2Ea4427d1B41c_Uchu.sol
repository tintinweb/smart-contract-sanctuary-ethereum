/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
//import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

//contract Uchu is Initializable {
contract Uchu {
 
    event Log(address from, string operation, string name, uint256 value);
    address payable public owner;
    enum State { DEPOSIT,WITHDRAW,BORROW,REPAY }

    struct Product{
        uint8 id;
        uint8 yieldNum;
        uint8 totalNum;
        uint8 lockPeriod;
        address creator;
        string asset;
        string name;
        uint256 createTime;
    }

    struct Position{
        address suer;
        uint256 amount;
        State state;
        Product product;
        uint256 createTime;
        uint256 closeTime;
    }

    struct Lender {
        uint32 id;
        uint8 proId;
        uint8 poIndex;
        address lender;
    }

    struct Borrower {
        uint32 id;
        uint8 proId;
        uint8 poIndex;
        address borrower;
    }

    uint8 private productId;
    uint32 private lenderId;
    uint32 private borrowerId;
    mapping (uint8 => Product) private products;
    mapping (uint32 => Lender) private lenders;
    mapping (uint32 => Borrower) private borrowers;
    mapping (string => uint256) private allowance;
    mapping (address => mapping(string => uint256)) private debts;
    mapping (address => mapping(string => uint256)) private balanceOf;
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

    function createProduct(uint8 yeildNum, uint8 totalNum, uint8 lockPeriod, string memory asset, string memory name) public {
        require(msg.sender == owner, "Need permission!");
        products[productId] = Product(productId, yeildNum, totalNum, lockPeriod, owner, asset, name, 0);
        insertBorrowerProduct(owner, productId);
        productId++;
    }

    /**
    * usrer select product by position & create lender struct
    */
    function insertLenderProduct(address user, uint8 index) private {
        Product memory pro = products[index];
        for(uint32 i=0; i<lenderId; i++) {
            if(pro.id == lenders[i].proId) {
                return;
            }
        }
        lenders[lenderId] = Lender(lenderId, pro.id, 0, user);
        lenderId++;
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
    function insertBorrowerProduct(address user, uint8 index) private {
        Product memory pro = products[index];
        for(uint32 i=0; i<borrowerId; i++) {
            if(pro.id == borrowers[i].proId) {
                return;
            }
        }
        borrowers[borrowerId] = Borrower(borrowerId, pro.id, 0, user);
        borrowerId++;
    }

   /**
    * get products from borrowers by address
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

    /**
    * deposit by current lender product that you selected, proId = index
    **/
    function deposit(uint8 proId) public payable returns (bool) {
        if (productId > 0) {
            Product memory pro = getProduct(proId);
            balanceOf[msg.sender][pro.name] += msg.value;
            allowance[pro.name] += msg.value;
            insertLenderProduct(msg.sender, proId);
            createPosition(msg.sender, msg.value, State.DEPOSIT, pro,  block.timestamp, 0);
            emit Log(msg.sender, "deposit", pro.name, msg.value);
            return true;
        } else {
            return false;
        }
    }

    function getProduct(uint8 proId) public view returns (Product memory pro) {
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
        uint8 length = getCurLender(user).poIndex;
        Product memory pro = getProduct(proId);
        uint256 result;
        for(uint8 i=0; i<length; i++) {
            if(positions[user][i].product.id == proId) {
                uint256 start = block.timestamp;
                uint256 end = positions[user][i].createTime;
                uint256 amount = positions[user][i].amount;
                uint256 pow = calculateTimeGap(start, end, pro.lockPeriod * 2);
                uint256 total = pro.yieldNum + pro.totalNum;
                result += amount / (100 ** pow) * (total ** pow);
            }
        }
        return result;
    }

    function getHistory(address user) public view returns (Position[] memory) {
        uint8 length = getCurLender(user).poIndex;
        Position[] memory history = new Position[](length);
        for(uint8 i=0; i<length; i++){
            history[i] = positions[user][i];
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
            createPosition(user, amount, State.WITHDRAW, pro, 0, block.timestamp);
            payable(user).transfer(amount);
            return true;
        } else {
            return false;
        }
    }

    /**
    *  set record by current lender's positionIndex
    **/
    function createPosition(address user, uint256 amount, State state, Product memory pro, uint256 depositTime, uint256 withdrawTime) private {
        positions[msg.sender][getCurLender(user).poIndex] = Position(user, amount, state, pro, depositTime, withdrawTime);
            for(uint32 i=0; i<lenderId; i++) {
                if(msg.sender == lenders[i].lender) {
                    lenders[i].poIndex++;
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