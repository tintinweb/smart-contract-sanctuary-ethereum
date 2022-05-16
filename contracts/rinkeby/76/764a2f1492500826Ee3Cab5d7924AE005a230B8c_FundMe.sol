// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";
/*
     these are live chainlink oracles imports which only work on test nets
     These imports server to tell which functions can be called in other contracts
     more like the contracts ABI
*/

contract FundMe {

    using SafeMathChainlink for uint256;
    //We want this contract to be able to accept some type of payment
    //0x9326BFA02ADD2366b30bacB125260Af641031331
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public  owner; 
    AggregatorV3Interface priceFeed;
    uint256 uselessVar;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed); // supply the address to the priceFeed contract that we shall be working with 
        owner   =    msg.sender;
    }

    function fund() public payable {
        /* 
            payable means that that function can be used to make payments
        */
        uint256 minimumUSDT = 50 * 10 ** 18; // convert to gwei (18 decimals)
        require(getConversionRate(msg.value)>= minimumUSDT,"You Need to spend more ETH!"); 
        /* a Failed require , initialises a revert */
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }
            //ETH to USDT
        function getVersion() public view returns(uint256){
            return priceFeed.version();
        }

        function getPrice() public view returns(uint256){
           (
               uint80 roundID, // how many times this price has been updated
               int256 answer, // the desired price
               uint256 startedAt,// when this value last updated
               uint256 timeStamp, 
               uint80 answeredInRound
           )= priceFeed.latestRoundData();

            /* 
                The value of the price that we get back is 
                actualPriceWithDecimals * 10^8
                2,614.97384316 * 10 ** 8

                The answer retured looks so big, but one thing to remember 
                is that it  that answer has 8 decimel places
            */

           return uint256(answer * 10000000000);/* we converted the price to wei (18 decimal places) so that we have all values 
           in the same decimal places */
        }

        function getConversionRate(uint256 ethAmount) public view returns (uint256){
           // for testing purposes we were using one gwe 1000000000
            uint256 ethPrice = getPrice();
            uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
            /* 
                since both the ethPrice and ethAmount have an additional 10^18 tacked onto them
                so we have to divide it out
            */
            return ethAmountInUsd;
            /* The answer returned by this has 18 decimals as well */
        }

        function getEntranceFee()  public view returns (uint256) {
            // minmumUSD
            uint256 minimumUSDT = 50*10**18;
            uint256 price = getPrice();
            uint256 precision = 1* 10 ** 18;
            return (minimumUSDT * precision) / price;

        }
        modifier onlyOwner {
            require(msg.sender == owner,"Only Address Owner can call this function");
            _;
        }  

        function withdraw() payable onlyOwner public {
            payable(msg.sender).transfer(address(this).balance);
            for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
                address funder = funders[funderIndex];
                addressToAmountFunded[funder]=0;
                
            }
            funders=new address[](0);
        }

        function getLiquidity() public view returns(uint256){
            return address(this).balance;
        }

        function viewMyBalance() public view returns (uint256){
            return address(msg.sender).balance;
        }

}

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
pragma solidity >=0.6.0;

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