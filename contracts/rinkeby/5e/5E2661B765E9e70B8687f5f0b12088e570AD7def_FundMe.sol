//SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity 0.6.0;
// 2. Imports
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "./PriceConvertor.sol";

// 3. Interfaces, Libraries, errors, Contracts
// Error should be written as <ContractName>__<name of error>
// error FundMe__NotOwner(); // this shit is too advanced for our solidity version

/**@title A sample Funding Contract   // what this contract is
 * @author Patrick Collins   // name of author
 * @notice This contract is for creating a sample funding contract  // a note to the people(imporves readability)
 * @dev This implements price feeds as our library  // note for devs.
 */
contract FundMe {
  // Type Declarations
  using SafeMathChainlink for uint256;
  using PriceConvertor for uint256; // ab iss var type (uint256) ke saare instance aise treat honge ki agar koi
  // var ka use ho, to isko as parameter ki jagah, func ko iska func maan ke use kar sakte hain
  // State variables
  mapping(address => uint256) private addressToAmountFunded;
  address payable private owner;
  address[] private funders;
  uint256 public constant MINIMUM_USD = 50 * 10**18;
  AggregatorV3Interface private priceFeed; // this gives us the abi. abi along with address gives us a contract to interact with

  // jo uske type ka wahi na value store karega. isliye AggregatorV3Interface ke type ka var banaya hai
  // Events (we have none!)

  // Modifiers
  modifier checkOwner() {
    require(msg.sender == owner, "You're not the owner! Stop");
    //if (msg.sender != owner) revert FundMe__NotOwner(); // do this if error can be written at the top
    _;
  }

  // Functions Order:
  //// constructor
  //// receive
  //// fallback
  //// external
  //// public
  //// internal
  //// private
  //// view / pure

  constructor(address priceFeedAddress) public {
    // ek baar jo value construcor mein def hojaye, usko kisi ka baap nahi badal sakta
    owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress); // by passing the address, a contract is not created.
  }

  /// @notice Funds our contract based on the ETH/USD price
  function fund() public payable {
    addressToAmountFunded[msg.sender] += msg.value; //+ add karna hai
    require(
      msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
      "Aur paisa do madarchod"
    );
    funders.push(msg.sender);
  }

  function withdraw() public payable checkOwner {
    owner.transfer(address(this).balance);
    for (
      uint256 fundersIndex = 0;
      fundersIndex < funders.length;
      fundersIndex++
    ) {
      address funder = funders[fundersIndex];
      addressToAmountFunded[funder] = 0;
    }
    funders = new address[](0);
  }

  function getAddressToAmountFunded(address funder)
    public
    view
    returns (uint256)
  {
    return (addressToAmountFunded[funder]);
  }

  function getOwner() public view returns (address) {
    return owner;
  }

  function getFunders(uint256 index) public view returns (address) {
    return funders[index];
  }

  function getPriceFeed() public view returns (AggregatorV3Interface) {
    return priceFeed;
  }
}
// FOR FUNCTIONS IN PRICECONVERTOR.sol
/** @notice Gets the amount that an address has funded
 *  @param fundingAddress the address of the funder
 *  @return the amount funded
 */
// recieve aur fallback do special functions hain. one is called if no data is passed through 'transact'-> lower level
// this is recieve(). Fallback is called if some value is passed which is not required by any functions.

// SPDX-License-Identifier: MIT
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

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

library PriceConvertor {
  // libraries cannot have constant state variables

  function getVersion() public view returns (uint256) {
    AggregatorV3Interface latestPrice = AggregatorV3Interface(
      0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    );
    return latestPrice.version();
  }

  function getLatestPrice(AggregatorV3Interface latestPrice)
    public
    view
    returns (uint256)
  {
    // AggregatorV3Interface latestPrice = AggregatorV3Interface(
    //   0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    // );
    (, int256 answer, , , ) = latestPrice.latestRoundData();
    return uint256(answer);
  }

  function getConversionRate(
    uint256 ethAmounts,
    AggregatorV3Interface priceFeed
  ) internal view returns (uint256) {
    //this ethAmounts is a value this func
    // needs to run. Ye number hum input karenge
    uint256 ethPriceInUSD = getLatestPrice(priceFeed);
    uint256 ethAmountInUSD = ethAmounts * ethPriceInUSD;
    return ethAmountInUSD / 10**8;
  }
}