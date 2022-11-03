/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  function getRoundData(
    uint80 _roundId
  )
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

// File: presaleContract.sol

pragma solidity 0.6.0;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

pragma experimental ABIEncoderV2;

library SafeMath {
    function percent(uint value,uint numerator, uint denominator, uint precision) internal pure  returns(uint quotient) {
        uint _numerator  = numerator * 10 ** (precision+1);
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return (value*_quotient/1000000000000000000);
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

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
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
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
contract Ownable is Context{
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () internal {
    address msgSender = 0x2C2ed7349332Eaf2d84851Dd5F50d81E5c488fA1;//_msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns ( address ) {
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
//   function renounceOwnership() public onlyOwner {
//     emit OwnershipTransferred(_owner, address(0));
//     _owner = address(0);
//   }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
//   function transferOwnership(address newOwner) public onlyOwner {
//     _transferOwnership(newOwner);
//   }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract PriceContract {
    
    AggregatorV3Interface internal priceFeed;
    address private priceAddress = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // ETH/USD Mainnet
    //address private priceAddress = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e; // ETH/USD Goerli Testnet
    //https://docs.chain.link/docs/bnb-chain-addresses/

    constructor() public {
        priceFeed = AggregatorV3Interface(priceAddress);
    }

    function getLatestPrice() public view returns (uint) {
        (,int price,,uint timeStamp,)= priceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        return (uint)(price);
    }
}

contract tokenSale is Ownable,PriceContract{
    
    address public reduxToken;
    uint256 internal price = 200*1e18; //0.005 usdt // 200 token per USD
    uint256 public minInvestment = 15*1e18; 
    bool saleActive=false; 
    //uint256 public softCap = 1200000*1e18;
    //uint256 public hardCap = 3000000*1e18;
    uint256 public totalInvestment = 0;
    Token token = Token(0x2d6e9d6b362354a5Ca7b03581Aa2aAc81bb530Db); // Token;
    Token usdt = Token(0xdAC17F958D2ee523a2206206994597C13D831ec7); // USDT

    struct userStruct{
        bool isExist;
        uint256 investment;
        uint256 ClaimTime;
        uint256 lockedAmount;
    }
    mapping(address => userStruct) public user;
    mapping(address => uint256) public ethInvestment;
    mapping(address => uint256) public usdtInvestment;

    constructor() public{
    }
    
    fallback() external  {
        purchaseTokensWithETH();
    }
    
    
    function purchaseTokensWithETH() payable public{   // with BNB
        uint256 amount = msg.value;       
        require(saleActive == true, "Sale not started yet!");
     
        //busd.transferFrom(msg.sender, address(this), amount);
        uint256 ethToUsd =  calculateUsd(amount); 
        require(ethToUsd>=minInvestment ,"Check minimum investment!");
        uint256 usdToTokens = SafeMath.mul(price, ethToUsd);
        uint256 tokenAmount = SafeMath.div(usdToTokens,1e18);
        
        user[msg.sender].lockedAmount = user[msg.sender].lockedAmount + tokenAmount;
        user[msg.sender].ClaimTime = now;

        ethInvestment[msg.sender] = ethInvestment[msg.sender] + msg.value ;
        totalInvestment = totalInvestment + ethToUsd;

        //require(totalInvestment <= hardCap, "Trying to cross Hardcap!"); 
        forwardFunds();
    }

    function calculateUsd(uint256 bnbAmount) public view returns(uint256){
        uint256 ethPrice = getLatestPrice();
        uint256 incomingEthToUsd = SafeMath.mul(bnbAmount, ethPrice) ;
        uint256 fixIncomingEthToUsd = SafeMath.div(incomingEthToUsd,1e8);
        return fixIncomingEthToUsd;
    }

    function purchaseTokensWithStableCoin(uint256 amount) public {
        require(amount>=minInvestment ,"Check minimum investment!");   
        require(saleActive == true, "Sale not started yet!");

        uint256 usdToTokens = SafeMath.mul(price, amount);
        uint256 tokenAmount = SafeMath.div(usdToTokens,1e18);
       
        usdt.transferFrom(msg.sender, address(this), amount/1e12);
        usdtInvestment[msg.sender] = usdtInvestment[msg.sender] + amount ;
        
        user[msg.sender].lockedAmount = user[msg.sender].lockedAmount + tokenAmount;
        user[msg.sender].ClaimTime = now; 
        totalInvestment = totalInvestment + amount;

        //require(totalInvestment <= hardCap, "Trying to cross Hardcap!"); 
        forwardFunds();
    }
    
    function claimTokens() public{ 
        require(saleActive == false,"Sale should be close before claim!");
        require(user[msg.sender].ClaimTime < now,"Claim time not reached!");
        require(user[msg.sender].lockedAmount >=0,"No Amount to Claim");
        token.transfer(msg.sender,user[msg.sender].lockedAmount);
        user[msg.sender].lockedAmount = 0;
    }
     
    function updatePrice(uint256 tokenPrice) public {
        require(msg.sender==owner(),"Only owner can update contract!");
        price=tokenPrice;
    }
    
    function startSale() public{
        require(msg.sender==owner(),"Only owner can update contract!");
        saleActive = true;
    }

    function stopSale() public{
        require(msg.sender==owner(),"Only owner can update contract!");
        saleActive = false;
    }

    function setMin(uint256 min) public{
        require(msg.sender==owner(),"Only owner can update contract!");
        minInvestment=min;
    }
        
    function withdrawRemainingTokensAfterICO() public{
        require(msg.sender==owner(),"Only owner can update contract!");
        require(token.balanceOf(address(this)) >=0 , "Tokens Not Available in contract, contact Admin!");
        token.transfer(msg.sender,token.balanceOf(address(this)));
    }
    
    function forwardFunds() internal {
        address payable ICOadmin = address(uint160(owner()));
        ICOadmin.transfer(address(this).balance);   
        usdt.transfer(owner(), usdt.balanceOf(address(this)));
    }
    
    function withdrawFunds() public{
        //require(totalInvestment >= softCap,"Sale Not Success!");
        require(msg.sender==owner(),"Only owner can Withdraw!");
        forwardFunds();
    }

       
    function calculateTokenAmount(uint256 amount) external view returns (uint256){
        uint tokens = SafeMath.mul(amount,price);
        return tokens;
    }
    
    function tokenPrice() external view returns (uint256){
        return price;
    }
    
    function investments(address add) external view returns (uint256,uint256,uint256,uint256){
        return (ethInvestment[add], ethInvestment[add], usdtInvestment[add],totalInvestment);
    }
}

abstract contract Token {
    function transferFrom(address sender, address recipient, uint256 amount) virtual external;
    function transfer(address recipient, uint256 amount) virtual external;
    function balanceOf(address account) virtual external view returns (uint256)  ;

}