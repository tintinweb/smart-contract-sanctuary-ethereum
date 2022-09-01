// "SPDX-License-Identifier: MIT"

pragma solidity ^0.6.6;
// if you're using a compiler < 0.8.0 you will encounter wrapping behavior for uints...
// SafeMath from OpenZeppelin helps decrease bugs from this behavior
import "SafeMath.sol";
import "AggregatorV3Interface.sol";
// import the above is the same as declaring the code in this contract explicitly as below
// displayed for learning so we can see how to interact with the interface in our FundMe contract
// in a real contract obviously the import statement above is preferred

//interface AggregatorV3Interface {
//  function decimals() external view returns (uint8);
//
//  function description() external view returns (string memory);
//
//  function version() external view returns (uint256);
//
//  // getRoundData and latestRoundData should both raise "No data present"
//  // if they do not have data to report, instead of returning unset values
//  // which could be misinterpreted as actual reported values.
//  function getRoundData(uint80 _roundId)
//    external
//    view
//    returns (
//      uint80 roundId,
//      int256 answer,
//      uint256 startedAt,
//      uint256 updatedAt,
//      uint80 answeredInRound
//    );
//
//  function latestRoundData()
//    external
//    view
//    returns (
//      uint80 roundId,
//      int256 answer,
//      uint256 startedAt,
//      uint256 updatedAt,
//      uint80 answeredInRound
//    );
//}

// this contract is meant to be able to accepts payments
contract FundMe {
  // this is how you apply SafeMath to uint256 in your contract
  using SafeMath for uint256;

    // create a mapping of an address to amount sent by address
    mapping(address => uint256) public addressToAmountFunded;
    // we create this array so we can keep track of who has funded
    address[] public funders;
    address public owner;
    // the constructor is called as soon as the smart contract is deployed
    constructor() public {
        // the deployer of the contract is the owner
        owner = msg.sender;
    }

    // payable indicates a function can send a payment
    function fund() public payable {
        // multiplied by 10**18 to be consistent w/ calculations in functions further down
        uint256 minimumUSD = 50 * 10 ** 18;
        // function will not proceed if minimumUSD value is not met
        require(getConversionRate(msg.value) >= minimumUSD, 'You need to spend more ETH!');
        // msg.sender is the caller of the function
        // msg.value is how much they sent
        // msg.value is sent to the FundMe contract address
        // remember that simply choosing an amount to send in remix and then confirming...
        // the transaction is what actually sends the value to the contract address...
        // the code below only updates the mapping addressToAmountFunded w/ the total...
        // value funded
        addressToAmountFunded[msg.sender] += msg.value;
        // add the caller of the function to the funders array
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // declaring priceFeed as a variable of the chainlink AggregatorV3Interface type
        // address for Rinkeby testnet ETH/USD conversion found at https://docs.chain.link/docs/ethereum-addresses/
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // see version fucntion above under the interface defintion
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // this function returns the latest price for eth in USD * 10**18 by leveraging the interface above
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // the latestRoundData method above returns all 5 values shown above into the tuple, this syntax...
        // allows us to only name the returned value that we want
        (,int256 answer,,,) = priceFeed.latestRoundData();
        // we are only interested in answer which we much convert to a uint, although I don't know why we can't have....
        // our function just return an int instead of insising it must return a uint
        // he likes to make sure everything have 18 decimal points since the standard eth is 10* 18 wei and...
        // this return already has 8 decimal places he multiplies by the factor below...
        // to have the return answer be similar to wei (10 ** -18 eth), this will cost more gas and not mandatory
        return uint256(answer * 10000000000);
      }

    function getConversionRate(uint ethAmount) public view returns (uint256) {
        // this function converts a given ethAmount into its current USD price * 10**18
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 10**18;
        // return amount will again have to be divided by 10**18 to get the actual cost in USD
        // I'm not understanding why he likes to use decimals this way, but I'll just follow along for now
        return ethAmountInUsd;
    }

    modifier onlyOwner {
      // only the owner can withdraw the funds
      require(msg.sender == owner);
      _;
    }

    function withdraw() onlyOwner public payable {
        // this line accomplishes two things: 1. payable() allows the address inside to utilize the...
        // transfer and send methods; 2. transfer the balance of the contract to msg.sender address
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++) {
          address funder = funders[funderIndex];
          addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}

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
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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