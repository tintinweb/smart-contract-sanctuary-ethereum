// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "AggregatorV2V3Interface.sol";
import "SafeMathChainlink.sol";


contract FundMe{

    using SafeMathChainlink for uint256;

    AggregatorV2V3Interface public priceFeed;

    mapping (address => uint256) public addressToAmountFunded;

    address [] public funders;

    address public owner;

    uint256 public balance;

    constructor(address _priceFeed) public {

        owner = msg.sender;

        priceFeed = AggregatorV2V3Interface(_priceFeed);

    }

    function fund()payable public {
        uint256 minimumUSD = 50 * (10**18);
        require(getConversionRate(msg.value)>= minimumUSD, "Insufficent Eht!");
        addressToAmountFunded[msg.sender] = msg.value;
        funders.push(msg.sender);
        balance += msg.value;

    }

    function getVersion()public view returns (uint256){
        // AggregatorV2V3Interface priceFeed = AggregatorV2V3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        return priceFeed.version();
    }

    function getPrice()public view returns (uint256){
        // AggregatorV2V3Interface priceFeed = AggregatorV2V3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        (,int rate,,,) = priceFeed.latestRoundData();
        return uint256(rate) * 10000000000;
    }

    function getConversionRate(uint256 ethAmt)public view returns(uint256){
        uint256 rate = getPrice();
        uint256 ethInUsd = (ethAmt * rate) / (10**18);
        return ethInUsd;
    }

    function getEnteranceFee() public view returns (uint256){
        uint256 minimumUSD = 50 * (10**18);
        uint256 precision = 1 * (10**18);
        uint256 rate = getPrice();
        return (minimumUSD/precision) * rate;

    }


    modifier onlyOwner () {
        require (msg.sender == owner);
        _;
    }



    function withdraw() onlyOwner payable public {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 index=0; index < funders.length; index++){
            address funder = funders[index];
            balance -= addressToAmountFunded[funder];
            addressToAmountFunded[funder]=0;

        }
        funders = new address[](0);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "AggregatorInterface.sol";
import "AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
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