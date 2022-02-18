// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;
//https://openzeppelin.com/
// ABI application binary interface which tells solidity and other programs how it can interact with
import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";
//https://github.com/smartcontractkit/chainlink-brownie-contracts



contract Funding{
    using SafeMathChainlink for uint256;

    mapping (address=> uint256) public addressToAmountFunded;
    
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public{

      priceFeed = AggregatorV3Interface(_priceFeed);
      owner = msg.sender ;
    }
    
    function fund () public payable{
      //$50
      uint256 minimumUSD = 50 *10 **18 ; 
      //if (msg.value<minimumUSD){revert?}
      require (gerConversionRate(msg.value)>= minimumUSD, "hey shit u broke in ETH???");
        (addressToAmountFunded[msg.sender]+=msg.value);
    //eth to usd conversion rate 
        funders.push(msg.sender);
    }
    //Mocking 
      //address constant public address1 = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
      //address constant public addresseth_rinkeby = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
      //address constant public addressmatic = 0x7794ee502922e2b723432DDD852B3C30A911F021;
    function getVersion() public view returns (uint256){
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(addresseth_rinkeby);
        //0x6B53bC8D7d03ED975305218bAbc065E1f14b01B0 = bsc testnet
        return priceFeed.version();

    }
     function getPrice() public view returns(uint256){
       //AggregatorV3Interface  priceFeed= AggregatorV3Interface(addresseth_rinkeby);
        (,int256 answer,,,)=priceFeed.latestRoundData();
      return uint256 (answer * 10000000000);


     }
     function gerConversionRate (uint256 ethAmount) public view returns (uint256){
       uint256 ethPrice= getPrice();
       uint256 ethAmountInUSD = (ethPrice*ethAmount);

       return ethAmountInUSD;
     }

      // modifier is used to change behaviour of a function in declararive way 
      //modifier for admin recognition 
    
    modifier onlyOwner {
      _;
      require (msg.sender== owner, "hey you got no right to do this");
      _;


    }

    function checkBalance() public view returns(uint256) {
       uint256 contractbalance = (address(this).balance);

       return contractbalance;
      
    }

    //function getEntranceFee()public view returns (uint256) {

      //uint256 minimumUSD = 50 * 10**18;
      //uint256 price = getPrice();
      //uint256 precision = 1 * 10**18;
      //return (minimumUSD * precision) / price ; 

    //}

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * (10**18);
        uint256 price = getPrice();
        uint256 precision = 1 * (10 ** 18);
        return (minimumUSD * precision) / price;
    }

    function withdraw() payable onlyOwner public {

      //payable(owner). transfer(addressmatic(this).balance);
        //require (msg.sender == owner, "hey bitch why are you withdraw eth not belong to you?");
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 funnderIndex =0; funnderIndex<funders.length; funnderIndex++){
          address funder = funders[funnderIndex];
          addressToAmountFunded[funder]=0;

        }
        // HOW TO RESTRICT WITHDRAWAL FUNCTION ONLY BE USED BY ADMIN 
        funders = new address[](0);
    }


      }

      //brownie compile ***** before heading to deploy.py

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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
library SafeMathChainlink {
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
    require(b <= a, "SafeMath: subtraction overflow");
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
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
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
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}