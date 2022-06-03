//SPDX-License-Identifier: MIT
//Day of Solidity 11Apr22
//Project Name: FundMe

pragma solidity ^0.6.6;

// Get the latest ETH/USD price from chainlink price feed
import "AggregatorV3Interface.sol";

import "SafeMathChainlink.sol";

//INTEGER OVERFLOW
//Importing Safemath from OpenZeppelin or chainlink, to make sure the addition of numbers is not happening in loop. For example,
//if uint8 is used the max value is 255. If 5 is added to it, the result will be 4 as it runs in a loop after 255
// eg. uint8 value = 255 + uint8(5) ==> returns the value of 4 ==> This is called INTEGER OVERFLOW
//This is not needed for solidity version about 0.8
//

contract FundMe {
    using SafeMathChainlink for uint256;

    //To keep track who is sending us funding
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders; //For resetting purpose
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        // To set a threshold of 5$
        uint256 minimumUSD = 50 * 10**18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "The amount should be more than 50$"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender); // For restting after withdrawal
    }

    //To assign a minimum value for the transaction, first ETH to USD. We accept ETH but we want to work in USD
    //To get the ETH to USD conversion, got to docs.chain.link/docs/get-the-latest-price/
    //https://docs.chain.link/docs/get-the-latest-price/

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
        //AggregatorV3Interface is where we are initialisin the contract, 2 is the name given, 3 is where to interact
        // with. the address can be found in "https://docs.chain.link/docs/ethereum-addresses/"
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // To get conversion rate, to check whether the ETH sent is equal to value we set (USD value to be set) we use the
    //below function

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = ((ethPrice * ethAmount) / 1000000000000000000);
        return ethAmountInUSD;
        // returns the value in Gwei
    }

    modifier OnlyOwner() {
        //_; means to execute the modifier, after executing the remaining
        require(msg.sender == owner); // == is true
        _; // means to execute the remaining, after executing the modifier
    }

    function Withdraw() public payable OnlyOwner {
        //Only want the contract owner or admin
        //require(msg.sender == owner); // == is true
        msg.sender.transfer(address(this).balance); //Sending all the balance money to this address. Here "This" is a keyword meaning the contract we are currently in

        //Resetting the array of address
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            // index is 0, index should be lesser thant the length of the index, add 1 to the funder index
            address funder = funders[funderIndex];
            // funder is the funderIndex in the funders array
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); //funders set to new blank address array so everything is reset
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