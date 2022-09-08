// SPDX-License-Identifier:MIT

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

import "SafeMathChainlink.sol";

//import from npm packages
//brownie isn't aware of npm package and cant download from npm
// but brownie can download that from github

//interface AggregatorV3Interface {

//   function decimals() external view returns (uint8);
//   function description() external view returns (string memory);
//   function version() external view returns (uint256);

//   function getRoundData(uint80 _roundId)
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

contract Fundme {
    //using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;

    address public owner;
    address[] public funderArray;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        //set a minimum value
        uint256 minimumUsd = 2 * 10**18;
        //require: get the money back and unspent gas  (like the if syntax)
        require(
            getConversionRate(msg.value) >= minimumUsd,
            "you need to fund more money"
        );

        addressToAmountFunded[msg.sender] += msg.value;

        //go through all the funder to find the funder should be set to "0"\
        //we can not loop through all the key in the mapping, should use array
        funderArray.push(msg.sender);
    }

    //reading the version so 'view'
    function getVersion() public view returns (uint256) {
        //define the interface with its name
        //the contract adress location
        //find the rinkeby , ETH, Dollars

        // a contract that has those funtion defines in the interfaces  locate at FUSD: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e this address
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        //Tuple : a list includes different types whose number is a constant at compile-time.
        // (uint80 roundId,
        // int256 answer,
        // uint256 startedAt,
        // uint256 updatedAt,
        // uint80 answeredInRound)=priceFeed.latestRoundData();

        //delete the useless thing in the Tuple, left the comma
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        //typecasting from int to uint256;
        //1 Ether =10**18 wei= 10**9 gwei
        //????* 10000000000 => return the price with 8 decimal insted of 10
        return uint256(answer * 10000000000);
        //ETH => USD
        //2,003.06000000
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethamountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethamountInUsd;
    }

    //Modifier: used to changed the behavior of a function in a declarative way.
    modifier onlyOwner() {
        require(msg.sender == owner);
        // _; means run the rest of the code
        _;
    }

    function withdraw() public payable onlyOwner {
        //   //funtion transfer : send eth from one address to another
        //   // keyword: THIS， is the contract you are currently in
        //   //address(this) : get the address of this current contract
        //   //balance //100000000000000000 wei
        //??????doesnt work SKIP
        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funderArray.length;
            funderIndex++
        ) {
            address funder = funderArray[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funderArray = new address[](0);
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