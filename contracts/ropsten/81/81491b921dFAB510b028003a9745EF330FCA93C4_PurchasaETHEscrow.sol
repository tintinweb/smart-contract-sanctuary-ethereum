/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

}


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PurchasaETHEscrow is Ownable {
    using SafeMath for uint256;

    struct Category {
        uint256 escrowtime;
        string name;
        uint commission;
    }

    struct Orders {
        string orderId;
        string categoryName;
        uint256 amount;
    }

    struct Escrow {
        uint256 totalLocked;
        address reciever;
        address sender;
        uint256 start;
        uint256 end;
        string orderId;
        uint totalCommission;
        bool isDispute;
        string currency;
        Category itemCategory;
    }

    struct ERCTokenList {
        IERC20 tokenAddress;
        string tokenName;
        string tokenSymbol;
        address tokenAdd;
        uint commission;
    }

    mapping (string => Category) public categoryList;
    mapping (string => Escrow) public escrowList;
    mapping (address => ERCTokenList) public tokens;
    mapping (address => bool) public tokenslist;

    Escrow[] public userOrders; //create array from struct
    
    ERCTokenList[] public tokensArray;


    function addNewCategory(uint256 escrowt,string memory name,uint tcommission) public onlyOwner {
        require(keccak256(abi.encodePacked(categoryList[name].name)) != keccak256(abi.encodePacked(name)), "Category already exists");
        Category storage newCategory = categoryList[name];
        newCategory.name = name;
        newCategory.escrowtime = escrowt;
        newCategory.commission = tcommission;
    }

    function EditCategory(uint256 escrowt,string memory name,uint tcommission) public onlyOwner {
        require(keccak256(abi.encodePacked(categoryList[name].name)) == keccak256(abi.encodePacked(name)), "Category not exists");
        categoryList[name].escrowtime = escrowt;
        categoryList[name].commission = tcommission;
    }

    function addNewToken(address tokenAddress,string memory tokenName,string memory tokenSymbol,uint tcommission) public onlyOwner {
        require(tokenslist[tokenAddress] == false, "Token already exists");
        tokenslist[tokenAddress] = true;
        ERCTokenList storage newTokenList = tokens[tokenAddress];
        newTokenList.tokenAddress = IERC20(tokenAddress);
        newTokenList.tokenName = tokenName;
        newTokenList.tokenSymbol = tokenSymbol;
        newTokenList.commission = tcommission;
        newTokenList.tokenAdd = tokenAddress;
        ERCTokenList memory tokenData = ERCTokenList(IERC20(tokenAddress),tokenName,tokenSymbol,tokenAddress,tcommission);
        tokensArray.push(tokenData);
    }

    function EditToken(address tokenAddress, string memory tokenName,string memory tokenSymbol,uint tcommission) public onlyOwner {
        require(tokenslist[tokenAddress] == true, "Token not exists");
        tokens[tokenAddress].tokenName = tokenName;
        tokens[tokenAddress].tokenSymbol = tokenSymbol;
        tokens[tokenAddress].commission = tcommission;
        for(uint i=0; i < tokensArray.length; i++){
            if(tokenAddress == tokensArray[i].tokenAdd) {
                tokensArray[i].tokenName = tokenName;
                tokensArray[i].tokenSymbol = tokenSymbol;
                tokensArray[i].commission = tcommission;
            }
        }
    }
 

    function lockETHToken(Orders[] memory orders, address reciever,string memory currency) payable public {
        require(msg.sender.balance >= msg.value, "Insufficient Balance");
        uint256 currentTime = block.timestamp;
        uint256 lengthO = orders.length;
        for(uint256 i = 0; i < lengthO; i++) {
        require(keccak256(abi.encodePacked(categoryList[orders[i].categoryName].name)) == keccak256(abi.encodePacked(orders[i].categoryName)), "Category not exists");
        Escrow storage escrowOrderList = escrowList[orders[i].orderId];
        escrowOrderList.totalLocked = orders[i].amount;
        escrowOrderList.reciever = reciever;
        escrowOrderList.sender = msg.sender;
        escrowOrderList.start = currentTime;
        escrowOrderList.end = currentTime + categoryList[orders[i].categoryName].escrowtime;
        escrowOrderList.orderId = orders[i].orderId;
        escrowOrderList.totalCommission = ((orders[i].amount / 100) * categoryList[orders[i].categoryName].commission);
        escrowOrderList.isDispute = false;
        escrowOrderList.currency = currency;
        escrowOrderList.itemCategory = categoryList[orders[i].categoryName];
        Escrow memory orderData = Escrow(orders[i].amount,reciever,msg.sender,currentTime,currentTime + categoryList[orders[i].categoryName].escrowtime,orders[i].orderId,((orders[i].amount / 100) * categoryList[orders[i].categoryName].commission),false,currency,categoryList[orders[i].categoryName]);
        userOrders.push(orderData);
        }
    }


    function payoutETH(string memory currency) public {
        uint256 totalAmount = 0;
        uint256 currentTime = block.timestamp;
        for(uint i=0; i < userOrders.length; i++){
            if(keccak256(abi.encodePacked(userOrders[i].currency)) == keccak256(abi.encodePacked(currency)) && userOrders[i].reciever == msg.sender && currentTime >= userOrders[i].end && userOrders[i].isDispute == false) {
                totalAmount = totalAmount.add(userOrders[i].totalLocked - userOrders[i].totalCommission);
            }
        }
        require(totalAmount > 0, "Balance must be greater then 0");
       payable(msg.sender).transfer(totalAmount);
        for(uint i=0; i < userOrders.length; i++){
            if(keccak256(abi.encodePacked(userOrders[i].currency)) == keccak256(abi.encodePacked(currency)) && userOrders[i].reciever == msg.sender && currentTime >= userOrders[i].end && userOrders[i].isDispute == false) {
                userOrders[i].totalLocked = 0;
            }
        }
    }

    function lockERCToken(Orders[] memory orders, address tokenAddress,uint256 amount, address reciever,string memory currency) public {
        require(tokenslist[tokenAddress] == true, "We are not providing services for this token");
        require(keccak256(abi.encodePacked(tokens[tokenAddress].tokenSymbol)) == keccak256(abi.encodePacked(currency)), "We are not providing services for this currency");
        require(tokens[tokenAddress].tokenAddress.balanceOf(msg.sender) >= amount, "Insufficient Balance");
        require(amount > 0, "Amount must be greater then 0");
        tokens[tokenAddress].tokenAddress.transferFrom(msg.sender, address(this), amount);
        uint256 currentTime = block.timestamp;
        uint256 lengthO = orders.length;
        for(uint256 i = 0; i < lengthO; i++) {
        require(keccak256(abi.encodePacked(categoryList[orders[i].categoryName].name)) == keccak256(abi.encodePacked(orders[i].categoryName)), "Category not exists");
        Escrow storage escrowOrderList = escrowList[orders[i].orderId];
        escrowOrderList.totalLocked = orders[i].amount;
        escrowOrderList.reciever = reciever;
        escrowOrderList.sender = msg.sender;
        escrowOrderList.start = currentTime;
        escrowOrderList.end = currentTime + categoryList[orders[i].categoryName].escrowtime;
        escrowOrderList.orderId = orders[i].orderId;
        escrowOrderList.totalCommission = ((orders[i].amount / 100) * tokens[tokenAddress].commission);
        escrowOrderList.isDispute = false;
        escrowOrderList.currency = currency;
        escrowOrderList.itemCategory = categoryList[orders[i].categoryName];
        Escrow memory orderData = Escrow(orders[i].amount,reciever,msg.sender,currentTime,currentTime + categoryList[orders[i].categoryName].escrowtime,orders[i].orderId,((orders[i].amount / 100) * tokens[tokenAddress].commission),false,currency,categoryList[orders[i].categoryName]);
        userOrders.push(orderData);
        }
    }


    function payoutERC(address tokenAddress,string memory currency) public {
        require(tokenslist[tokenAddress] == true, "We are not providing services for this token");
        require(keccak256(abi.encodePacked(tokens[tokenAddress].tokenSymbol)) == keccak256(abi.encodePacked(currency)), "We are not providing services for this currency");
        uint256 totalAmount = 0;
        uint256 currentTime = block.timestamp;
        for(uint i=0; i < userOrders.length; i++){
            if(keccak256(abi.encodePacked(userOrders[i].currency)) == keccak256(abi.encodePacked(currency)) && userOrders[i].reciever == msg.sender && currentTime >= userOrders[i].end && userOrders[i].isDispute == false) {
                totalAmount = totalAmount.add(userOrders[i].totalLocked - userOrders[i].totalCommission);
            }
        }
        require(totalAmount > 0, "Balance must be greater then 0");
        tokens[tokenAddress].tokenAddress.transfer(msg.sender,  totalAmount);
        for(uint i=0; i < userOrders.length; i++){
            if(keccak256(abi.encodePacked(userOrders[i].currency)) == keccak256(abi.encodePacked(currency)) && userOrders[i].reciever == msg.sender && currentTime >= userOrders[i].end && userOrders[i].isDispute == false) {
                userOrders[i].totalLocked = 0;
            }
        }
    }

    function withdrawalERCCommission(address tokenAddress,string memory currency) public onlyOwner {
        require(tokenslist[tokenAddress] == true, "We are not providing services for this token");
        require(keccak256(abi.encodePacked(tokens[tokenAddress].tokenSymbol)) == keccak256(abi.encodePacked(currency)), "We are not providing services for this currency");
        uint256 totalAmount = 0;
        uint256 currentTime = block.timestamp;
        for(uint i=0; i < userOrders.length; i++){
            if(keccak256(abi.encodePacked(userOrders[i].currency)) == keccak256(abi.encodePacked(currency)) && currentTime <= userOrders[i].end && userOrders[i].isDispute == false) {
                totalAmount = totalAmount.add(userOrders[i].totalCommission);
            }
        }
        require(totalAmount > 0, "Balance must be greater then 0");
        tokens[tokenAddress].tokenAddress.transfer(msg.sender,  totalAmount);
    }

    function withdrawalETHCommission(string memory currency) public onlyOwner {
        uint256 totalAmount = 0;
        uint256 currentTime = block.timestamp;
        for(uint i=0; i < userOrders.length; i++){
            if(keccak256(abi.encodePacked(userOrders[i].currency)) == keccak256(abi.encodePacked(currency)) && currentTime <= userOrders[i].end && userOrders[i].isDispute == false) {
                totalAmount = totalAmount.add(userOrders[i].totalCommission);
            }
        }
        require(totalAmount > 0, "Balance must be greater then 0");
       payable(msg.sender).transfer(totalAmount);
    }

    function disputeOrder(string memory orderId) public {
        require(escrowList[orderId].sender == msg.sender, "You are not authorize to dispute this order");
         uint256 currentTime = block.timestamp;
        require(currentTime >= escrowList[orderId].end, "You can not disupte now");
        escrowList[orderId].isDispute == true;
         for(uint i=0; i < userOrders.length; i++){
            if(keccak256(abi.encodePacked(userOrders[i].orderId)) == keccak256(abi.encodePacked(orderId))) {
                userOrders[i].isDispute = true;
            }
        }
    }

    function disputeETHAction(string memory orderId,address refundAddress) payable public onlyOwner {
        uint256 amount = 0;
        uint256 tcommission = 0;
        if(escrowList[orderId].sender == refundAddress) {
            amount = amount.add(escrowList[orderId].totalLocked);
        }
        if(escrowList[orderId].reciever == refundAddress) {
           amount = amount.add(escrowList[orderId].totalLocked - escrowList[orderId].totalCommission);
           tcommission = tcommission.add(escrowList[orderId].totalCommission);
        }
        payable(refundAddress).transfer(amount);
        if(tcommission > 0) {
        payable(msg.sender).transfer(tcommission);
        }
        escrowList[orderId].totalLocked = 0;
    }

    

    function disputeTokenAction(address tokenAddress,string memory orderId,address refundAddress) payable public onlyOwner {
        require(tokenslist[tokenAddress] == true, "We are not providing services for this token");
        uint256 amount = 0;
        uint256 tcommission = 0;
        if(escrowList[orderId].sender == refundAddress) {
            amount = amount.add(escrowList[orderId].totalLocked);
        }
        if(escrowList[orderId].reciever == refundAddress) {
           amount = amount.add(escrowList[orderId].totalLocked - escrowList[orderId].totalCommission);
           tcommission = tcommission.add(escrowList[orderId].totalCommission);
        }
        tokens[tokenAddress].tokenAddress.transfer(refundAddress,  amount);
         if(tcommission > 0) {
             tokens[tokenAddress].tokenAddress.transfer(msg.sender,  tcommission);
        }
        escrowList[orderId].totalLocked = 0;
    }


    function ownerChangeERCCommission(address tokenAddress,uint commissions) public onlyOwner{
        require(tokenslist[tokenAddress] == true, "We are not providing services for this token");
        tokens[tokenAddress].commission = commissions;
    }

    function getERCBalance(address tokenAddress,address merchantAddress,string memory currency) public view returns (uint256) {
        require(tokenslist[tokenAddress] == true, "We are not providing services for this token");
        require(keccak256(abi.encodePacked(tokens[tokenAddress].tokenSymbol)) == keccak256(abi.encodePacked(currency)), "We are not providing services for this currency");
        uint256 totalAmount = 0;
        for(uint i=0; i < userOrders.length; i++){
            if(keccak256(abi.encodePacked(userOrders[i].currency)) == keccak256(abi.encodePacked(currency)) && userOrders[i].reciever == merchantAddress && userOrders[i].isDispute == false) {
                totalAmount = totalAmount.add(userOrders[i].totalLocked - userOrders[i].totalCommission);
            }
        }
        return totalAmount;
    }

    function getBalance(address merchantAddress,string memory currency) public view returns (uint256) {
        uint256 totalAmount = 0;
        for(uint i=0; i < userOrders.length; i++){
            if(keccak256(abi.encodePacked(userOrders[i].currency)) == keccak256(abi.encodePacked(currency)) && userOrders[i].reciever == merchantAddress && userOrders[i].isDispute == false) {
                totalAmount = totalAmount.add(userOrders[i].totalLocked - userOrders[i].totalCommission);
            }
        }
        return totalAmount;
    }

    function getTokens() public view returns (ERCTokenList[] memory) {
       return tokensArray;
    }
}