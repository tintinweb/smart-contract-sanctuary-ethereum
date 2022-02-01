// SPDX-License-Identifier: MIT;

// pragma solidity >=0.6.6 <0.8.11;
pragma solidity >=0.4.22 <0.9.0;
import "AggregatorV3Interface.sol";

import "SafeMathChainlink.sol";

// brownie can not directly download from npm but it can fetch from github
// change global compiler version(remote) =0.6.6

// or import safemath from openzupplin
//////////////////////

// interface AggregatorV3Interface {

//   function decimals()
//     external
//     view
//     returns (
//       uint8
//     );

//   function description()
//     external
//     view
//     returns (
//       string memory
//     );

//   function version()
//     external
//     view
//     returns (
//       uint256
//     );

//   // getRoundData and latestRoundData should both raise "No data present"
//   // if they do not have data to report, instead of returning unset values
//   // which could be misinterpreted as actual reported values.
//   function getRoundData(
//     uint80 _roundId
//   )
//     external
//     view
//     returns (
//       uint80 roundId,
//       int256 answer,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     );

//   function latestRoundData()
//     external
//     view
//     returns (
//       uint80 roundId,
//       int256 answer,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     );

// }

/////////////////////////data in import

contract FundMe {
    using SafeMathChainlink for uint256;
    //fundMe: to accept some kind of payment(payable)

    // Who will send us?to eep track
    mapping(address => uint256) public addressToAmountFunded;

    address[] public funders;

    address public owner;

    constructor() public {
        owner = msg.sender; //sender would be one who deploys contract
    }

    function fund() public payable {
        // payable -can be used to pay for things
        //every fn has an associated value with it.when we make transactions ,we can append a value to it
        //that means how many wei or gwei you want to send with your function call

        uint256 minuimunUSD = 50 * 18**10; //ingwei term

        // if(msg.value<minuimunUSD){
        //     revert?
        // }or we can use require statement

        require(
            getConverionRate(msg.value) <= minuimunUSD,
            "you need to spend more eth"
        ); //ifnot enough then revert
        addressToAmountFunded[msg.sender] += msg.value;
        // msg.sender:sender of fncall/msg
        // msg.value:how much they sent

        //wth -> usd conversion rate?
        //to do that w need oracle here
        //oracle shouldn't be centralized and data sources should be just one
        // ..chainlink comes:modulaar,decentralized oracle infrastructure and oracle network that allows us to get data and do external data in highly sybil resistant decentralized manner

        funders.push(msg.sender);
    }

    // chainlink:it can be as customizable as you want.one of features of chainlik are:
    // -data feeds(data.chain.link):
    // you can make API calls and make your own decentralized networkyou can with chaining.
    // -price feeds

    // Interface:
    // 	-function name and return type
    // 	-just to tel what fns can be called
    // interfaces can compile down to ABI:
    // ABI tells solidity how it can interact with other contacts

    //to call version fn in interface
    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        ); //(pricefeedadress)
        //this is  contract adress where interface's functions are defined
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        //this fn returns five variables do
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        ); //(pricefeedadress)

        //tuple:list of objects of potentially different datatypes
        //whose numbe is constant at compile-time.
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer); //

        // 248255877123 = 2482.55877123 eth->usd
    }

    //comverting value we receive to usd
    function getConverionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUSD;
    }

    modifier onlyOwner() {
        //put_: above if statement to run is in between.
        require(msg.sender == owner); //if this statement is being used multiplt times byt mutliple users
        _; //hey,before you run withdraw funtion  execute require statement first and then run rest code where underscore is
    }

    //withdraw
    // function withdraw() payable public {//from contract to sender
    function withdraw() public payable onlyOwner {
        //from contract to sender

        // requiremsg.sender=owner //constructor
        // require(msg.sender==owner);
        payable(msg.sender).transfer(address(this).balance); //transfer to send eth//sending to sender
        //sending all money //this:current contract//balance in h=this address

        //in case of multiplt users trying to use this         require(msg.sender==owner);
        // modifiers:change behavior of function in declarative way.

        //REsetting:we are not updating balances of people who funded this
        // when we with draw we ll set everyone's balance in maaping to 0

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex]; //taking key for mapping
            addressToAmountFunded[funder] = 0;
        }

        // reseting fnders array;
        funders = new address[](0);
    }
}
// import errors

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
pragma solidity >=0.4.22 <0.9.0;


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