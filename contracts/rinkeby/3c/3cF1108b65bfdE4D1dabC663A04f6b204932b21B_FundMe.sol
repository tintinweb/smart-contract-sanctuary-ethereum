// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;
// we are using compiler version 0.6.6

// If there is errors in import or compilation, then don't worry we have made changes in brownie config file so use brownie compile

import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

// this import uses Rinkbey test network not rinkbey
// Remember this import from actual test network not vm so we need to deploy it on the inject web of Rinkbey network

contract FundMe {
    // this will solving overflow wrapping problem of large numbers but don't need in 0.8+ solidity
    using SafeMathChainlink for uint256;

    // getting value by addresses // You can't use loop on mapping so in this case we use array for storing the values after that we will set them to zero in withdraw function
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner; // this will persist owner address

    // It will be executed whenever we will deploy this contract
    constructor() public {
        // so when someone deployed this contract whose address will be settled as the owner
        owner = msg.sender;
    }

    function fund() public payable {
        // Now let's set a threshhold that a user can send minimum 20$
        uint256 minimumUSD = 20 * 10**18; // setting 20 Dollar for comparison

        // so it is like if value is greate then or equal to 50 dollar then go further otherwise stop the execution with the msg
        // msg.value (contains eth amount which is sent by user)
        require(
            getConverstionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        // what the ETH -> USD conversion rate

        // msg.sender (address) msg.value (value)    // Having two attributes
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender); // somebody funds multiple times it's redudant but for now it's okay
    }

    function getVersion() public view returns (uint256) {
        // ETH TO USD address we placed inside it
        // https://docs.chain.link/docs/ethereum-addresses/ (get this address from there)
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        // this have 8 decimal we are adding 10 more for make it as wei conversion to usd
        // ETH TO USD 8 DECIMAL GWEI TO USD 18 DECIMAL for wei decimal places
        return uint256(answer * 10000000000); // parsing int256 to uint256
    }

    // getting eth amount in USD according to ETH amount
    function getConverstionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(); // getting etherium current 1ETH price
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000; // Dividing by 18 zeros to remove that decimal 18 values to get the exact to usd price
        return ethAmountInUSD;
    }

    modifier onlyOwner() {
        // _; // means execute all the code of function then run require function
        require(msg.sender == owner, "You are not the owner of this contract!");
        _; // means execute after wards code
    }

    // 10000000000
    function withDraw() public payable onlyOwner {
        // Who ever call this withdraw function transfer all the money on this address

        // To avoid this use inside the function we will use modifier
        // require(msg.sender == owner, "You are not the owner of this contract!");
        msg.sender.transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); // setting array to empty for now
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