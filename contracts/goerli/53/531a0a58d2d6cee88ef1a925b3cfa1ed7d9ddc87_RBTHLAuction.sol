/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: 35_auction_newest.sol



pragma solidity ^0.8.0;




interface NftContractInterface{
    function awardItem(address player, string memory tokenURI) external returns (uint256);
    function new_transfer(address _from, address _to, uint256 tokenId) external;
}
interface IRBTHL {
     function auctionMint(address _account, uint256 _amount) external;
     function balanceOf(address account) external returns(uint256);
     function transferFrom(address from, address to, uint256 amount)external;
     function sendEth(address _to)external payable ;
     function transfer(address to, uint256 amount)external;
     function approve(address to, uint256 amount)external;
}


contract RBTHLAuction is Ownable {

    using SafeMath for uint256;

    //interface
    NftContractInterface public RBTHLNFT;
    IRBTHL public RBTHL;
    address _RBTHLAuction;
    
    //aggregator
    AggregatorV3Interface public ethPriceFeed;

    //save user bids 
    mapping (address => uint256[]) public _userBids;

    // to add whitelisted_users
    // mapping(string =>mapping(address =>bool)) public isAddressWhitelisted;
    //mapping to check user address by name or gmail
    // mapping (string => address) public _whitelistedUserAddress;

    //mapping to check is whitelisted
    // mapping (address => bool) public _isWhitelisted;

    // mapping (address => uint256) public _toClaim;

    uint256 public balance;
    // eth deposit mapping
    mapping (address => uint256) public  _ethDeposit;

    mapping (address => uint256) public  _rbthlDeposit;

    uint public _auctionId = 0;

    // mapping to get auction id of owner
    mapping (address => uint) public _getAuctionId;

    // get auction owner by id of auction
    mapping (uint => address) public _getAuctionOwner;
    // for sale cashback to update only by admin
    mapping (address => bool) public _isOwner;

    //bidder bids
    // mapping (address => uint256[]) bids;

    uint public saleCashback = 5;

    // token default price
    uint256 public salePriceUsd = 10_000_000_000_000_000; //$0.01 ( 1e18 = 1 token , 1e16 = 0.01 token value)

    //save AuctionDetails
    struct AuctionDetails {
    uint tokenId;
    address owner;
    address highestBidder;
    uint startDate;
    uint auctionId;
    uint endDate;
    uint currentPrice;
    uint actualPrice;
    uint price;
    string state;
    uint minPriceIncrement;
    }

    // uint auctionId;
    
    //fetch auction details of owner
    mapping (address => AuctionDetails) public auctionDetails;

    // mapping auction ID of a specific address
    // mapping (address => auctionId) public getAuctionId;

    constructor (address _rbthlnft, address _rbthl) {
        RBTHLNFT = NftContractInterface(_rbthlnft);
        RBTHL = IRBTHL(_rbthl);
        _RBTHLAuction = address(this);
        ethPriceFeed = AggregatorV3Interface(
                0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
            );
            _isOwner[msg.sender] = true;
    }

        // current price of eth
        function salePriceEth() public view returns (uint256) {
            (, int256 ethPriceUsd, , , ) = ethPriceFeed.latestRoundData();
            uint256 rbthlpriceInEth = (salePriceUsd*(10**18))/(uint256(ethPriceUsd)*(10**10));
            return rbthlpriceInEth;
        }

        function getLatestPrice() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = ethPriceFeed.latestRoundData();
        return price;
    }

    function updateRBTHL(address _newRBTHL) public onlyOwner {
        RBTHL = IRBTHL(_newRBTHL);
    }

    function updateRBTHLNFT(address _newRBTHLNFT) public onlyOwner {
        RBTHLNFT = NftContractInterface(_newRBTHLNFT);
    }

        function createAuction(uint _tokenId, address _owner, uint256 _startDate, uint256 _endDate, uint256 _startingPrice, uint256 _minPriceIncrement) public {
        require(_startDate >= block.timestamp);
        require(_endDate > _startDate);
        require(_minPriceIncrement > 0);
        _auctionId = _auctionId+1;
        auctionDetails[_owner].tokenId = _tokenId;
        auctionDetails[_owner].owner = _owner;
        auctionDetails[_owner].startDate = _startDate;
        auctionDetails[_owner].auctionId = _auctionId;
        auctionDetails[_owner].endDate = _endDate;
        auctionDetails[_owner].price = _startingPrice;
        auctionDetails[_owner].currentPrice = _startingPrice;
        auctionDetails[_owner].minPriceIncrement = _minPriceIncrement;

        _getAuctionId[_owner] = _auctionId;
        _getAuctionOwner[_auctionId] = _owner;
        
        
    }

    function placeBidInETH(uint _aucId) public payable {
        address _owner = _getAuctionOwner[_aucId];
        uint _amount = msg.value;
          // check if the bid is at least the minimum price increment

        require(auctionDetails[_owner].startDate < block.timestamp, "Auction Not Started Yet");
        require(auctionDetails[_owner].endDate > block.timestamp, "Auction Already Ended");
        require(msg.value > auctionDetails[_owner].currentPrice, "Amount Should Be More than Current Price");
        require(_amount >= (auctionDetails[_owner].currentPrice).add(auctionDetails[_owner].minPriceIncrement), "Bid is below the minimum price increment");
        require(auctionDetails[_owner].price <= msg.value);
        
        auctionDetails[_owner].currentPrice = _amount;
        auctionDetails[_owner].actualPrice = auctionDetails[_owner].currentPrice/1e18;
        auctionDetails[_owner].highestBidder = msg.sender;
        auctionDetails[_owner].state = "ETH";
        // auctionDetails[_owner].bids[msg.sender] = _amount;
        _userBids[msg.sender].push(_amount);
        _ethDeposit[msg.sender] = _ethDeposit[msg.sender].add(msg.value);
        // payable(msg.sender).transfer(msg.value);
    }

    function placeBidInToken(uint _aucId, uint256 _amount) public {
        require(RBTHL.balanceOf(msg.sender)>= _amount, "You Dont Have Enough Rabbit Hole Tokens");
        address _owner = _getAuctionOwner[_aucId];
        uint new_amount = _amount/1e18;
        // auctionDetails[_owner].bidders.push(msg.sender);
        // require(_isWhitelisted[msg.sender] = true, "User Should Be Whitelisted");
        require(auctionDetails[_owner].startDate < block.timestamp, "Auction Not Started Yet");
        require(auctionDetails[_owner].endDate > block.timestamp, "Auction Already Ended");
        require(_amount > auctionDetails[_owner].currentPrice, "Amount Should Be More than Current Price");
        // require(auctionDetails[_owner].minPriceIncrement <= _amount);
        // require(auctionDetails[_owner].price < _amount);

        require(auctionDetails[_owner].price <= _amount);
        // set allowance for the contract to transfer the bidAmount of RBTHL tokens from the user's account
        auctionDetails[_owner].actualPrice = new_amount;
        RBTHL.approve(address(this), _amount);
        // transfer the bidAmount of RBTHL tokens from the user's account to the contract's account
        // RBTHL.transferFrom(msg.sender, address(this), _amount);

        auctionDetails[_owner].currentPrice = _amount;
        auctionDetails[_owner].highestBidder = msg.sender;
        auctionDetails[_owner].state = "RBTHL";
        // auctionDetails[_owner].bids[msg.sender] = _amount;
        _userBids[msg.sender].push(_amount);
        // _ethDeposit[msg.sender] = _ethDeposit[msg.sender].add(msg.value);
        _rbthlDeposit[msg.sender] = _rbthlDeposit[msg.sender].add(_amount);
        // payable(msg.sender).transfer(msg.value);
        RBTHL.transferFrom(msg.sender, address(this), _amount);
    }


    function refundETH(address _owner) public {
            
            require(block.timestamp < auctionDetails[_owner].endDate, "Auction ended");
            require(_ethDeposit[msg.sender] > 0, "No ETH deposit to withdraw");
            require(auctionDetails[_owner].highestBidder != msg.sender);

            payable(msg.sender).transfer(_ethDeposit[msg.sender]);
            
            // balance = balance.sub(_ethDeposit[msg.sender]);
            
            _ethDeposit[msg.sender] = 0;
        }

    function refundRBTHL(address _owner) public {
            
            require(block.timestamp < auctionDetails[_owner].endDate, "Auction ended");
            require(_rbthlDeposit[msg.sender] > 0, "No ETH deposit to withdraw");
            // require(_rbthlDeposit[msg.sender]>= auctionDetails[_owner].)
            require(auctionDetails[_owner].highestBidder != msg.sender);

            // payable(msg.sender).transfer(_ethDeposit[msg.sender]);
            
            // balance = balance.sub(_ethDeposit[msg.sender]);
            // uint256 amt = _rbthlDeposit[msg.sender];
            // _ethDeposit[msg.sender] = 0;
            // RBTHL.transferFrom(address(this), msg.sender, amt);
             RBTHL.transferFrom(_RBTHLAuction, msg.sender, _rbthlDeposit[msg.sender]);
            _rbthlDeposit[msg.sender] = 0;
        }

    function auctionSettled(address _owner) public {
        require(block.timestamp > auctionDetails[_owner].endDate, "Auction not ended yet");
        require(msg.sender == auctionDetails[_owner].highestBidder, "You are not the highest Bidder of this auction");
        require(auctionDetails[_owner].currentPrice > 0, "Not Enough Biddings Took Place");
        // if(auctionDetails[_owner].curr == _owner)
        // require(auctionDetails[_owner].cur)
        
        if(_ethDeposit[msg.sender]>0){ //auction settled in eth
        // require(_ethDeposit[msg.sender]>0, "You Not Took Part in Bidding");
        // address payable to = payable(_owner);
        // uint contractBal = address(this).balance;
        // uint transBal = contractBal.sub(auctionDetails[_owner].currentPrice);
        _ethDeposit[msg.sender].sub(auctionDetails[_owner].currentPrice);

        payable(_owner).transfer(auctionDetails[_owner].currentPrice);
        // _ethDeposit[msg.sender] = 0;
        RBTHLNFT.new_transfer(_owner, msg.sender, auctionDetails[_owner].tokenId);
        uint rewardAmount = (saleCashback * auctionDetails[_owner].currentPrice)/100 ;
            RBTHL.auctionMint(auctionDetails[_owner].owner, rewardAmount);//mint the RBTHL token
        }

        if(_rbthlDeposit[msg.sender]>0)
        {
            RBTHL.transfer(_owner, auctionDetails[_owner].currentPrice);
            _rbthlDeposit[msg.sender].sub(auctionDetails[_owner].currentPrice);
            RBTHLNFT.new_transfer(_owner, msg.sender, auctionDetails[_owner].tokenId);
            uint rewardAmount = (saleCashback * auctionDetails[_owner].currentPrice)/100 ;
            RBTHL.auctionMint(auctionDetails[_owner].owner, rewardAmount);//mint the RBTHL token
        
        }

        // payable(_owner).transfer(price);

    }

    function updateSaleCashback(uint256 _updateSaleCashback) public {
        require(_isOwner[msg.sender] == true, "You Are Not An Admin");
          saleCashback = _updateSaleCashback;
    }

    function addOwners(address _own) public onlyOwner{
        require(_isOwner[_own] == false, "Already An Admin");
        _isOwner[_own] = true;
    }

    function removeOwners(address _own)public onlyOwner{
        require(_isOwner[_own] == true, "Not An Admin");
        _isOwner[_own] = false;
    }

    function auctionState(address _auctionOwner) public view returns(string memory) {
        // address _owner = _getAuctionOwner[_aucId];
        string memory abc = "Auction Currently Running";
        string memory bcd = "Auction Ended";
        string memory cde = "Auction Not Started Yet";
        if(block.timestamp > auctionDetails[_auctionOwner].endDate){
            return bcd;
        }
        if(block.timestamp > auctionDetails[_auctionOwner].startDate){
            return abc;
        }
        if(block.timestamp < auctionDetails[_auctionOwner].startDate){
            return cde;
        }
    }


   
}