// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;

    // array of address that fund the contract.
    address[] public funders;
    // address of the contract creator
    address public owner;
    // priceFeed
    AggregatorV3Interface public priceFeed;

    // this is always initiated at contract deployment
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    /**
     * @dev Funds the contract with ETH
     *
     * This function keeps track of address that funds
     * the contract and amount funded.
     *
     * Requirements:
     * - ETH Deposited > minimum threshold
     **/
    function fund() public payable {
        // $50 threshold
        uint256 minimumUSD = 50 * 10**8;
        require(
            getEthDepositedInUSD(msg.value) >= minimumUSD,
            "Gas Insufficient"
        );
        // maps funder address to value funded
        addressToAmountFunded[msg.sender] += msg.value;
        // adds funder's address to array
        funders.push(msg.sender);
    }

    /**
     * @dev Returns the price feed version
     *
     *
     **/
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    /**
     * @dev Returns the latest USD value of ETH
     *
     * This function uses the AggregatorV3Interface of Chainlink
     * to fetch the current price of ETH stored on a contract.
     *
     *
     **/
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer * (10**8));
    }

    /**
     * @dev Returns the USD value of ETH deposited
     *
     * getPrice() function is called for current
     * price of ETH.
     *
     **/
    function getEthDepositedInUSD(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethDepositedInUSD = (ethPrice * ethAmount);

        return ethDepositedInUSD;
    }

    /**
     * @dev Returns the USD value of ETH deposited
     *
     * getPrice() function is called for current
     * price of ETH.
     *
     **/
    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10**8;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**8;
        return (minimumUSD * precision) / price;
    }

    /**
     * @dev Withdraws funds from the contract.
     *
     * This function uses a modifier to check the
     * the address of the sender equals that of the contract owner.
     *
     *
     * Requirements:
     * - Withdrawal address should be the owner of contract.
     **/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdrawAmountFunded() public payable onlyOwner {
        // withdraw funds to contract owner address.
        msg.sender.transfer(address(this).balance);
        // Loop through the addresses in the array, setting the value to 0
        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset the array
        funders = new address[](0);
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