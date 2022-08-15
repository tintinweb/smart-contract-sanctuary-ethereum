/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

pragma solidity ^0.5.16;


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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}





interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
     * @dev Returns the erc token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract DService is Ownable {
    using SafeMath for uint256;
    //vote coin contract
    address public voteCoinAddress =   0xebBA921554901aBc495Bf4C9f5E8F1C1c98078d9;

    IERC20 voteCoinContract = IERC20(voteCoinAddress);

    // app owner
    mapping(uint256 => address) private _ownerOf;

    //app vote price
    mapping(uint256 =>  uint256) public appVotePrice;

    //app min vote quantity
    mapping(uint256 =>  uint256) public appMinVotes;

    //app min votes difference
    mapping(uint256 => uint256) public appMinVoteDiff;

    //how many seconds after order paid, can buyer make dispute
    mapping(uint256 =>  uint256)    public  intervalDispute;

    //how many seconds after order paid, can seller cash out order
    mapping(uint256 =>  uint256)    public  intervalCashOut;

    //how many seconds after dispute made, if seller does not response, buyer can cashout the refund
    mapping(uint256 =>  uint256)    public  intervalRefuse;

    // app uri
    mapping(uint256 =>  string)     public  appURI;

    // app name
    mapping(uint256 =>  string)     public  appName;

    // app max order id
    mapping(uint256 =>  uint256)    public  appMaxOrder;

    // app owner commission ratio
    mapping(uint256 =>  uint8)      public  appOwnerCommission;

    // platform commission ratio
    mapping(uint256 =>  uint8)      public  platformCommission;

    //after such time, if seller does not refuse refund, buyer can cashout the refund.
    mapping(uint256 => mapping(uint256 => uint256)) public refuseExpired;

    //Struct Order
    struct Order {
        uint256 id;             //order id
        uint256 amount;         //order amount
        address coinAddress;    //coin contract address
        address buyer;          //buyer address
        address seller;         //seller address
        uint256 appOrderId;     //centralized app order id
        uint256 timestamp;      //timestamp
        uint256 refundTime;     //before when can ask refund
        uint256 cashOutTime;    //when can be cash out
        uint8   status;         //order status, 1 paid, 2 buyer ask refund, 3 completed, 4 seller refuse dispute, 5 buyer or seller appeal, so voters can vote
        uint256 refund;         //disputeId
        uint256 votePrice;      //the price to vote refund
        uint256 minVotes;       //min votes to finish the order
        uint256 minVoteDiff;    //min different votes to finish the order
        address[] agree;        //referees who agrees the refund
        address[] disagree;     //referees who disagree the refund
    }

    // appId => Order[]
    mapping(uint256 =>  mapping(uint256 =>  Order))    public orderBook;

    // user balance (userAddress => mapping(coinAddress => balance))
    mapping(address =>  mapping(address => uint256))    public userBalance;

    // total app num
    uint256 private  _totalSupply;

    //Withdraw event
    event Withdraw(
        address indexed user,           //user wallet address
        uint256 indexed amount,         //withdraw amount
        address indexed coinContract    //withdraw coin contract
    );

    //Create new APP event
    event NewApp(uint256 indexed appId);    //appId

    //Create order event
    event CreateOrder(
        uint256 indexed orderId,
        uint256 indexed appOrderId,
        address indexed coinAddress,
        uint256  amount,
        address  buyer,
        address  seller,
        uint256  appId,
        uint256  entityId
    );

    //Confirm Done event
    event ConfirmDone(
        uint256 indexed appId,
        uint256 indexed orderId
    );

    //Ask refund event
    event AskRefund(
        uint256 indexed appId,
        uint256 indexed orderId,
        uint256 indexed refund
    );

    //Cancel refund event
    event CancelRefund(
        uint256 indexed appId,
        uint256 indexed orderId
    );

    //Refuse refund event
    event RefuseRefund(
        uint256 indexed appId,
        uint256 indexed orderId
    );

    //Appeal dispute event
    event Appeal(
        uint256 indexed appId,
        uint256 indexed orderId
    );

    //Vote to Agree or Disagree refund
    event Vote(
        address indexed user,
        bool    indexed isAgree,
        uint256 indexed orderId,
        uint256 appId,
        uint256 price
    );

    //Refund now event
    event RefundNow(
        uint256 indexed appId,
        uint256 indexed orderId,
        uint8   indexed refundType      //0 disagree win, 1 agree win, 2 seller refund
    );

    //Cash out event
    event CashOut(
        address indexed user,
        uint256 indexed appId,
        uint256 indexed orderId
    );

    //User Balance Changed event
    event UserBalanceChanged(
        address indexed user,
        bool    indexed isIn,
        uint256 indexed amount,
        address coinAddress,
        uint256 appId,
        uint256 orderId
    );

    constructor() public {

    }

    // make the contract payable
    function () payable external {}

    // get total supply apps
    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    // get owner of appId
    function ownerOf(uint256 appId) public view returns(address) {
        return _ownerOf[appId];
    }
    //Create new APP
    function newApp(address appOwner, string memory _appName, string memory websiteURI) public onlyOwner returns(uint256) {

        uint256 appId                     =  totalSupply().add(1);
        _ownerOf[appId]                   =  appOwner;
        appURI[appId]                     =   websiteURI;
        appName[appId]                    =   _appName;
        appMaxOrder[appId]                =   uint256(0);
        intervalDispute[appId]            =   uint256(1000000);
        intervalCashOut[appId]            =   uint256(1000000);
        intervalRefuse[appId]             =   uint256(86400);
        appVotePrice[appId]               =   uint256(1500000000);
        appMinVotes[appId]                =   uint256(5);
        appMinVoteDiff[appId]             =   uint256(2);
        appOwnerCommission[appId]         =   uint8(5);
        platformCommission[appId]         =   uint8(2);
        _totalSupply                      =   appId;
        emit NewApp(appId);

        return appId;
    }
    //Set platformCommission ratio
    function setPlatformCommission(uint256 appId, uint8 _ratio) public onlyOwner {
        require(_ratio <= 20, 'platform commission can not be over than 20%');
        platformCommission[appId]   =   _ratio;
    }

    //Set app vote price
    function setAppVotePrice(uint256 appId, uint256 _price) public onlyOwner {
        require(_price < 100000000000, 'price should be smaller than 100000');
        require(_price > 1000000000, 'price should be larger than 1000');
        appVotePrice[appId]    =   _price;
    }

    //Set app min votes
    function setAppMinVotes(uint256 appId, uint256 _minVotes) public onlyOwner {
        require(_minVotes > 3, 'min votes must greater than 3');
        require(_minVotes < 15,'min votes must less than 15');
        appMinVotes[appId]  =   _minVotes;
    }

    //Set app min votes difference
    function setAppMinVotesDiff(uint256 appId, uint256 _minVotesDiff) public onlyOwner {
        require(_minVotesDiff > 1, 'min votes difference must greater than 1');
        require(_minVotesDiff < appMinVotes[appId],'min votes difference must less than min votes');
        appMinVoteDiff[appId]   =   _minVotesDiff;
    }

    //Set dispute interval timestamp
    function setIntervalDispute(uint256 appId, uint256 _timestamp) public onlyOwner {
        require(_timestamp > 10, 'interval time too small!');
        require(_timestamp < 10000000, 'interval time too big!');
        intervalDispute[appId]    =   _timestamp;
    }

    //Set refuse interval timestamp
    function setIntervalRefuse(uint256 appId, uint256 _timestamp) public onlyOwner {
        require(_timestamp > 10, 'interval time too small!');
        require(_timestamp < 10000000, 'interval time too big!');
        intervalRefuse[appId]    =   _timestamp;
    }

    //Set cash out interval timestamp
    function setIntervalCashOut(uint256 appId, uint256 _timestamp) public onlyOwner {
        require(_timestamp > 20, 'interval time too small!');
        require(_timestamp < 10000000, 'interval time too big!');
        intervalCashOut[appId]    =   _timestamp;
    }

    //Set APP Owner commission ratio
    function setAppOwnerCommission(uint256 appId,   uint8 _ratio) public {
        require(_msgSender() == ownerOf(appId), "only app owner can set its owner commission");
        require(_ratio <= 50, "app owner commission can not bigger than 50%");
        appOwnerCommission[appId]   =   _ratio;
    }

    //Set APP URI
    function setAppURI(uint256 appId,   string memory websiteURI)   public  {
        require(_msgSender() == ownerOf(appId), "only app owner can set its uri");

        appURI[appId]   =   websiteURI;
    }

    //Set APP NAME
    function setAppName(uint256 appId,   string memory name)   public  {
        require(_msgSender() == ownerOf(appId), "only app owner can set its uri");

        appName[appId]   =   name;
    }

    //Create Order
    function createOrder(uint256 appId, uint256 amount, address coinAddress, address seller, uint256 appOrderId, uint256 entityId) public payable returns(uint256) {
        require(entityId > 0 && appId > 0 && appId <= totalSupply() && appOrderId > 0 && amount > 0);
        //check if app order id already is already on the blockchain. PS : It is wrong to do that, as appId with appOrderId maybe duplicated, and it is acceptable.
        // if(chainOrderIdOfAppOrderId[appId][appOrderId] > 0 ) {
        //     revert("Dservice : The order is already paid");
        // }
        //BNB or ETH
        if(coinAddress  ==  address(0)) {
            require(msg.value   ==  amount, 'Wrong amount or wrong value sent');
            //send BNB/ETH to this contract
            address(this).transfer(amount);
        } else {
            IERC20 buyCoinContract = IERC20(coinAddress);
            //send ERC20 to this contract
            buyCoinContract.transferFrom(msg.sender, address(this), amount);
        }
        uint256 orderId =   appMaxOrder[appId].add(1);
        // store order information
        Order memory _order;
        _order.id           =   orderId;
        _order.coinAddress  =   coinAddress;
        _order.amount       =   amount;
        _order.appOrderId   =   appOrderId;
        _order.buyer        =   _msgSender();
        _order.seller       =   seller;
        _order.timestamp    =   block.timestamp;
        _order.refundTime   =   block.timestamp.add(intervalDispute[appId]);
        _order.cashOutTime  =   block.timestamp.add(intervalCashOut[appId]);
        _order.refund       =   uint256(0);
        _order.status       =   uint8(1);
        _order.votePrice    =   appVotePrice[appId];
        _order.minVotes     =   appMinVotes[appId];
        _order.minVoteDiff  =   appMinVoteDiff[appId];

        orderBook[appId][orderId]    =   _order;
        //update max order information
        appMaxOrder[appId]  =   orderId;
        // record the app order id on blockchain. PS : No need any more.
        // chainOrderIdOfAppOrderId[appId][appOrderId] = orderId;

        // emit event
        emit CreateOrder(orderId, appOrderId, coinAddress,amount,_msgSender(),seller,appId, entityId);

        return orderId;
    }

    //confirm order received, and money will be cash out to seller
    //triggled by buyer
    function confirmDone(uint256 appId, uint256 orderId) public {

        require(_msgSender()==orderBook[appId][orderId].buyer,'Only buyer can confirm done');

        require(orderBook[appId][orderId].status==uint8(1)||
                orderBook[appId][orderId].status==uint8(2)||
                orderBook[appId][orderId].status==uint8(4),
                'Order status must be equal to just paid or refund asked or dispute refused');

        // cash out money to seller
        userBalance[orderBook[appId][orderId].seller][orderBook[appId][orderId].coinAddress]    =   userBalance[orderBook[appId][orderId].seller][orderBook[appId][orderId].coinAddress].add(orderBook[appId][orderId].amount);
            emit UserBalanceChanged(
                orderBook[appId][orderId].seller,
                true,
                orderBook[appId][orderId].amount,
                orderBook[appId][orderId].coinAddress,
                appId,
                orderId
            );

        // set order status to completing
        orderBook[appId][orderId].status==uint8(3);

        //emit event
        emit ConfirmDone(appId, orderId);

    }

    //ask refund
    //triggled by buyer
    function askRefund(uint256 appId, uint256 orderId, uint256 refund) public {

        require(_msgSender()==orderBook[appId][orderId].buyer,'Only buyer can make dispute');

        require(orderBook[appId][orderId].status==uint8(1)||orderBook[appId][orderId].status==uint8(2),'Order status must be equal to just paid or refund asked');

        require(block.timestamp < orderBook[appId][orderId].refundTime, "It is too late to make dispute");

        require(refund > 0, "Refund amount must be bigger than 0");

        require(refund <= orderBook[appId][orderId].amount, "Refund amount can not be bigger than paid amount");

        // update order status
        if(orderBook[appId][orderId].status==uint8(1)) {
            orderBook[appId][orderId].status=uint8(2);
        }
        // update refund of order
        orderBook[appId][orderId].refund=refund;
        // update refuse expired
        refuseExpired[appId][orderId] = block.timestamp.add(intervalRefuse[appId]);
        //emit event
        emit AskRefund(appId, orderId, refund);
    }

    //cancel refund
    //triggled by buyer
    function cancelRefund(uint256 appId, uint256 orderId) public {

        require(_msgSender()==orderBook[appId][orderId].buyer,'Only buyer can make dispute');

        require(orderBook[appId][orderId].status==uint8(2)||orderBook[appId][orderId].status==uint8(4),'Order status must be equal to refund asked or refund refused');

        //update order status to paid
        orderBook[appId][orderId].status=uint8(1);

        emit CancelRefund(appId, orderId);
    }

    //refuse refund
    //triggled by seller
    function refuseRefund(uint256 appId, uint256 orderId) public {

        require(_msgSender()==orderBook[appId][orderId].seller,'Only seller can refuse dispute');

        require(orderBook[appId][orderId].status==uint8(2),'Order status must be equal to refund asked');

        //update order status to refund refused
        orderBook[appId][orderId].status=uint8(4);

        emit RefuseRefund(appId, orderId);
    }

    //appeal, so voters can vote
    //triggled by seller or buyer
    function appeal(uint256 appId, uint256 orderId) public {

        require(_msgSender()==orderBook[appId][orderId].seller || _msgSender()==orderBook[appId][orderId].buyer,'Only seller or buyer can appeal');

        require(orderBook[appId][orderId].status==uint8(4),'Order status must be equal to refund refused by seller');

        //update order status to appeal dispute
        orderBook[appId][orderId].status=uint8(5);

        emit Appeal(appId, orderId);

    }



    // if seller agreed refund, then refund immediately
    // else the msg.sender must deposit 1000 DService coin into it to vote agree
    function agreeRefund(uint256 appId, uint256 orderId) public {

        //if seller agreed refund, than refund immediately
        if(_msgSender()==orderBook[appId][orderId].seller) {
            require(orderBook[appId][orderId].status==uint8(2) || orderBook[appId][orderId].status==uint8(4),'order status must be equal to 2 or 4');
            sellerAgree(appId, orderId);
        } else {
            require(orderBook[appId][orderId].status==uint8(5),'only can vote on appealing');
            // check if order now meet the condition of finishing the order
            if(orderBook[appId][orderId].agree.length.add(1) >= orderBook[appId][orderId].minVoteDiff.add(orderBook[appId][orderId].disagree.length)
                &&
                orderBook[appId][orderId].agree.length.add(1).add(orderBook[appId][orderId].disagree.length) >= orderBook[appId][orderId].minVotes) {
                refundNow(appId, orderId, true);
            } else if(orderBook[appId][orderId].disagree.length >= orderBook[appId][orderId].agree.length.add(1).add(orderBook[appId][orderId].minVoteDiff)
                &&
                orderBook[appId][orderId].agree.length.add(1).add(orderBook[appId][orderId].disagree.length) >= orderBook[appId][orderId].minVotes){
                refundNow(appId, orderId, false);
            } else {
                // deposit vote coins to this contract according to the vote appVotePrice
                voteCoinContract.transferFrom(_msgSender(), address(this), orderBook[appId][orderId].votePrice);
                //register the referee as order agree
                orderBook[appId][orderId].agree.push(_msgSender());

                emit Vote(_msgSender(), true, orderId, appId, orderBook[appId][orderId].votePrice);
            }
        }

    }

    // the msg.sender must deposit exactly DService coin into it to vote disagree
    function disagreeRefund(uint256 appId, uint256 orderId) public {

        require(orderBook[appId][orderId].status==uint8(5),'only can vote on appealing');
        // check if order now meet the condition of finishing the order
        if(orderBook[appId][orderId].disagree.length.add(1) >= orderBook[appId][orderId].minVoteDiff.add(orderBook[appId][orderId].agree.length)
            &&
            orderBook[appId][orderId].agree.length.add(1).add(orderBook[appId][orderId].disagree.length) >= orderBook[appId][orderId].minVotes) {
            refundNow(appId, orderId, false);
        } else if (orderBook[appId][orderId].agree.length >= orderBook[appId][orderId].disagree.length.add(1).add(orderBook[appId][orderId].minVoteDiff)
            &&
            orderBook[appId][orderId].agree.length.add(1).add(orderBook[appId][orderId].disagree.length) >= orderBook[appId][orderId].minVotes) {
            refundNow(appId, orderId, true);
        } else {
            // deposit vote coins to this contract according to the vote appVotePrice
            voteCoinContract.transferFrom(_msgSender(), address(this), orderBook[appId][orderId].votePrice);
            //register the referee as order disagree
            orderBook[appId][orderId].disagree.push(_msgSender());

            emit Vote(_msgSender(), false, orderId, appId, orderBook[appId][orderId].votePrice);
        }
    }

    // if seller agreed refund, then refund immediately
    function sellerAgree(uint256 appId, uint256 orderId) internal {
        require(_msgSender()==orderBook[appId][orderId].seller);
        // update order status to finish
        orderBook[appId][orderId].status=uint8(3);
        //return all the voters the same amount they vote
        uint256 amount_to_voter    = orderBook[appId][orderId].votePrice;
        // refund to disagree
        for(uint256 i = 0; i < orderBook[appId][orderId].disagree.length; i++) {
            userBalance[orderBook[appId][orderId].disagree[i]][voteCoinAddress]    =   userBalance[orderBook[appId][orderId].disagree[i]][voteCoinAddress].add(amount_to_voter);
            emit UserBalanceChanged(
                orderBook[appId][orderId].disagree[i],
                true,
                amount_to_voter,
                voteCoinAddress,
                appId,
                orderId
            );
        }
        // refund to agree
        for(uint256 i = 0; i < orderBook[appId][orderId].agree.length; i++) {
            userBalance[orderBook[appId][orderId].agree[i]][voteCoinAddress]    =   userBalance[orderBook[appId][orderId].agree[i]][voteCoinAddress].add(amount_to_voter);
            emit UserBalanceChanged(
                orderBook[appId][orderId].agree[i],
                true,
                amount_to_voter,
                voteCoinAddress,
                appId,
                orderId
            );
        }
        // as the refund is approved, refund to buyer
        userBalance[orderBook[appId][orderId].buyer][orderBook[appId][orderId].coinAddress]    =   userBalance[orderBook[appId][orderId].buyer][orderBook[appId][orderId].coinAddress].add(orderBook[appId][orderId].refund);
        emit UserBalanceChanged(
                orderBook[appId][orderId].buyer,
                true,
                orderBook[appId][orderId].refund,
                orderBook[appId][orderId].coinAddress,
                appId,
                orderId
            );
        // if there is amount left, then send left amount to seller
        if(orderBook[appId][orderId].amount > orderBook[appId][orderId].refund) {
            userBalance[orderBook[appId][orderId].seller][orderBook[appId][orderId].coinAddress]    =   userBalance[orderBook[appId][orderId].seller][orderBook[appId][orderId].coinAddress].add(orderBook[appId][orderId].amount.sub(orderBook[appId][orderId].refund));
            emit UserBalanceChanged(
                orderBook[appId][orderId].seller,
                true,
                orderBook[appId][orderId].amount.sub(orderBook[appId][orderId].refund),
                orderBook[appId][orderId].coinAddress,
                appId,
                orderId
            );
        }

        emit RefundNow(appId, orderId, uint8(2));
    }

    function refundNow(uint256 appId, uint256 orderId, bool result) internal {

        // update order status to finish
        orderBook[appId][orderId].status=uint8(3);

        // return back the referee vote coins
        // the referee who judge wrong decision will only get 80% of what they deposit
        // the winner will share the difference as bonus
        //if result is to refund, then refund to buyer, the left will be sent to seller
        //else all paid to the seller
        if(result == true) {
            // winner is the agree, and loser is the disagree
            uint256 to_disagree =   orderBook[appId][orderId].votePrice.mul(80).div(100);
            uint256 to_agree    =   orderBook[appId][orderId].votePrice.mul((orderBook[appId][orderId].disagree.length.mul(20)).add(orderBook[appId][orderId].agree.length.mul(100)))
            .div(orderBook[appId][orderId].agree.length).div(100);
            // refund to disagree
            for(uint256 i = 0; i < orderBook[appId][orderId].disagree.length; i++) {
                userBalance[orderBook[appId][orderId].disagree[i]][voteCoinAddress]    =   userBalance[orderBook[appId][orderId].disagree[i]][voteCoinAddress].add(to_disagree);
                emit UserBalanceChanged(
                    orderBook[appId][orderId].disagree[i],
                    true,
                    to_disagree,
                    voteCoinAddress,
                    appId,
                    orderId
                );
            }
            // refund to agree
            for(uint256 i = 0; i < orderBook[appId][orderId].agree.length; i++) {
                userBalance[orderBook[appId][orderId].agree[i]][voteCoinAddress]    =   userBalance[orderBook[appId][orderId].agree[i]][voteCoinAddress].add(to_agree);
                emit UserBalanceChanged(
                    orderBook[appId][orderId].agree[i],
                    true,
                    to_agree,
                    voteCoinAddress,
                    appId,
                    orderId
                );
            }
            // as the refund is approved, refund to buyer
            userBalance[orderBook[appId][orderId].buyer][orderBook[appId][orderId].coinAddress]    =   userBalance[orderBook[appId][orderId].buyer][orderBook[appId][orderId].coinAddress].add(orderBook[appId][orderId].refund);
            emit UserBalanceChanged(
                orderBook[appId][orderId].buyer,
                true,
                orderBook[appId][orderId].refund,
                orderBook[appId][orderId].coinAddress,
                appId,
                orderId
            );
            // if there is amount left, then send left amount to seller
            if(orderBook[appId][orderId].amount > orderBook[appId][orderId].refund) {
                userBalance[orderBook[appId][orderId].seller][orderBook[appId][orderId].coinAddress]    =   userBalance[orderBook[appId][orderId].seller][orderBook[appId][orderId].coinAddress].add(orderBook[appId][orderId].amount.sub(orderBook[appId][orderId].refund));
                emit UserBalanceChanged(
                orderBook[appId][orderId].seller,
                true,
                orderBook[appId][orderId].amount.sub(orderBook[appId][orderId].refund),
                orderBook[appId][orderId].coinAddress,
                appId,
                orderId
                );
            }
            emit RefundNow(appId, orderId, uint8(1));
        } else {
            // winner is the disagree, and loser is the agree
            uint256 to_agree    =   orderBook[appId][orderId].votePrice.mul(80).div(100);
            uint256 to_disagree =   orderBook[appId][orderId].votePrice.mul((orderBook[appId][orderId].agree.length.mul(20)).add(orderBook[appId][orderId].disagree.length.mul(100)))
            .div(orderBook[appId][orderId].disagree.length).div(100);
            // refund to disagree
            for(uint256 i = 0; i < orderBook[appId][orderId].disagree.length; i++) {
                userBalance[orderBook[appId][orderId].disagree[i]][voteCoinAddress]    =   userBalance[orderBook[appId][orderId].disagree[i]][voteCoinAddress].add(to_disagree);
                emit UserBalanceChanged(
                    orderBook[appId][orderId].disagree[i],
                    true,
                    to_disagree,
                    voteCoinAddress,
                    appId,
                    orderId
                );
            }
            // refund to agree
            for(uint256 i = 0; i < orderBook[appId][orderId].agree.length; i++) {
                userBalance[orderBook[appId][orderId].agree[i]][voteCoinAddress]    =   userBalance[orderBook[appId][orderId].agree[i]][voteCoinAddress].add(to_agree);
                emit UserBalanceChanged(
                    orderBook[appId][orderId].agree[i],
                    true,
                    to_agree,
                    voteCoinAddress,
                    appId,
                    orderId
                );
            }
            // send all the amount to the seller
            userBalance[orderBook[appId][orderId].seller][orderBook[appId][orderId].coinAddress]    =   userBalance[orderBook[appId][orderId].seller][orderBook[appId][orderId].coinAddress].add(orderBook[appId][orderId].amount);
            emit UserBalanceChanged(
                orderBook[appId][orderId].seller,
                true,
                orderBook[appId][orderId].amount,
                orderBook[appId][orderId].coinAddress,
                appId,
                orderId
            );
            emit RefundNow(appId, orderId, uint8(0));
        }

    }

    //seller want to cash out money from order to balance
    //or
    //buyer want to cash out money after seller either not to refuse dispute or agree dispute
    function cashOut(uint256 appId, uint256 orderId) public {

        //seller cashout
        if(_msgSender()==orderBook[appId][orderId].seller) {

            require(orderBook[appId][orderId].status==uint8(1),'order status must be equal to 1 ');

            require(block.timestamp > orderBook[appId][orderId].cashOutTime, "currently seller can not cash out, need to wait");

            userBalance[orderBook[appId][orderId].seller][orderBook[appId][orderId].coinAddress]    =   userBalance[orderBook[appId][orderId].seller][orderBook[appId][orderId].coinAddress].add(orderBook[appId][orderId].amount);
            emit UserBalanceChanged(
                orderBook[appId][orderId].seller,
                true,
                orderBook[appId][orderId].amount,
                orderBook[appId][orderId].coinAddress,
                appId,
                orderId
            );

        } else if(_msgSender()==orderBook[appId][orderId].buyer) { // buyer cashout

            require(orderBook[appId][orderId].status==uint8(2),'order status must be equal to 2 ');

            require(block.timestamp > refuseExpired[appId][orderId], "currently buyer can not cash out, need to wait");

            //give refund to buyer balance
            userBalance[orderBook[appId][orderId].buyer][orderBook[appId][orderId].coinAddress]    =   userBalance[orderBook[appId][orderId].buyer][orderBook[appId][orderId].coinAddress].add(orderBook[appId][orderId].refund);
            emit UserBalanceChanged(
                orderBook[appId][orderId].buyer,
                true,
                orderBook[appId][orderId].refund,
                orderBook[appId][orderId].coinAddress,
                appId,
                orderId
            );
            // if there is amount left, then send left amount to seller
            if(orderBook[appId][orderId].amount > orderBook[appId][orderId].refund) {
                userBalance[orderBook[appId][orderId].seller][orderBook[appId][orderId].coinAddress]    =   userBalance[orderBook[appId][orderId].seller][orderBook[appId][orderId].coinAddress].add(orderBook[appId][orderId].amount.sub(orderBook[appId][orderId].refund));
                emit UserBalanceChanged(
                orderBook[appId][orderId].seller,
                true,
                orderBook[appId][orderId].amount.sub(orderBook[appId][orderId].refund),
                orderBook[appId][orderId].coinAddress,
                appId,
                orderId
                );
            }
        } else {
            revert("only seller or buyer can cash out");
        }

        orderBook[appId][orderId].status    =   3;
        emit CashOut(_msgSender(), appId, orderId);
    }

    //withdraw from user balance
    function withdraw(uint256 _amount, address _coinAddress) public {

        //get user balance
        uint256 _balance = userBalance[_msgSender()][_coinAddress];

        require(_balance >= _amount, 'Insufficient balance!');

        //descrease user balance
        userBalance[_msgSender()][_coinAddress] = _balance.sub(_amount);

        //if the coin type is ETH
        if(_coinAddress == address(0)) {

            //check balance is enough
            require(address(this).balance > _amount, 'Insufficient balance');

            msg.sender.transfer(_amount);

        } else { //if the coin type is ERC20

            IERC20 _token = IERC20(_coinAddress);

            _token.transfer(msg.sender, _amount);
        }

        //emit withdraw event
        emit Withdraw(msg.sender, _amount, _coinAddress);
    }

}