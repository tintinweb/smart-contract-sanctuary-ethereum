/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// Part: smartcontractkit/[email protected]/SafeMathChainlink

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

// File: FundMe.sol

// THIS ALSO IS THE CODE WE IMPORTED
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

contract FundMe {

    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;

    address[] public funders;

    address public owner;

    // CONSTRUCTOR IS WHAT CONSTRUCT THE CONTRACT, IT IS THE FUNCTION CALLED IMMEDIATELY A CONTRACT IS DEPOLYED
    // SO ONCE THE CONTRACT IS DEPLOYED, IT IMMEDIATELY SETS THE OWNER VARIABLE
    constructor() public {
        owner = msg.sender;
    }

    // THE PAYABLE KEYWORD MEANS THIS FUNCTION CAN BE USED TO PAY FOR THINGS
    function fund() public payable {
        // minimum of $50
        uint256 minimumUSD = 50 * 10**18;
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!!" );
        addressToAmountFunded[msg.sender] += msg.value;
        // WHAT IS THE ETH > USD CONVERSION RATE

        // THIS BELOW PUSHES THE ADDRESS TO THE FUNDERS LIST
        funders.push(msg.sender);
    }
    
    // THESE FUNCTION BELOW WILL LOOK INTO THE INTERFACE OF AggregatorV3Interface AND CHECK THE ADDRESS CONTAINING
    // THE CURRENCY CONVERSION WE WANT FROM THE DOCS.CHAIN.LINK -> ETHEREUM PRICE FEED -> RINKEBY 
    // THIS IS BECAUSE WE HAVE IMPORTED THE WHOLE INTERFACE FROM CHAINLINK WEBSITE 

    // THIS RETURN THE VERSION (V3)
    function getVersion() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface( 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e );
        return priceFeed.version();
    }

    // THIS WILL RETURN THE PRICE
    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface( 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e );

        // HERE WE ARE SAYING ALL THE VALUES IN THE TUPLE IS ASSIGNED TO PRICEFEED BECAUSE THAT FUNCTION IN THE CONTRACT RETURNED A TUPLE 
        // AND WE MUST ACCEPT THEM IN A TUPLE
        // (
        //     uint80 roundId,
        //     int256 answer,
        //     uint256 startedAt,
        //     uint256 updatedAt,
        //     uint80 answeredInRound
        // ) = priceFeed.latestRoundData();

    // SO BECAUSE WE ARE NOT USING OTHER VARIABLES, WE NEED TO SKIP THEM  BUT RETAINING THEIR PRESENCE WITH A COMMA
        (,int256 answer,,,) = priceFeed.latestRoundData();

    //   WE ARE WRAPPING (TYPE CASTING) ANSWER BECAUSE IT RETURNED AN INT AND WE NEED AN UINT
        return uint256(answer * 10000000000);
    //   WE MULTIPLIED ABOVE SO WE CAN ALWAYS HAVE OUR ANSWERS IN WEI
    // BECAUSE THAT FUNCTION RETURNS GWEI AND WE NEED WEI
    }

    // THIS FUNCTION CONVERTS THE AMOUNT INTO USD
    // 1000000000 IS WHAT WE WILL USE
    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; // WE DIVIDED BY THAT FIGURE COZ THEY HAVE EXTRA FIGURE 0f 1*10^8 EACH
        return ethAmountInUsd; // THIS WILL RETURN VALUE IN GWEI SO WE CAN DIVIDE BY 10000000000 TO GET IN ETH
    }

    // THIS MODIFIER WILL CHECK IF THE CONDITION IS MET THEN THE _; EXECUTES THE OTHER FUNCTION BODY
    modifier OnlyOwner {
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable OnlyOwner public {
        // WE ONLY WANT THE CONTRACT ONWER/ADMIN
        msg.sender.transfer(address(this).balance);

        // WHEN ALL MONEY HAS BEEN WITHDRAWN,WE WANT TO SET THE BALANCE OF THE CONTRACT TO 0
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex ++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // THE WE RESET THE FUNDERS ARRAY
        funders = new address[](0);
    }
}