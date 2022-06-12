// SPDX-License-Identifier: MIT

/*
    Smart contract that lets anyone depopst ETH into the contract
    Only the owner of hte contract can widthraw the deposited ETH
*/

pragma solidity ^0.6.6;

// Get hte latest ETH/USD price from the Chanilink price feed
// these are NPM packages
// NOTE: brownie doesn't know how to donwload NPM packages, but it does know how to download from GitHub, so we'll set that up
// in brownie-config.yaml
import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    // network: Kovan, aggregator: ETH/USD address
    address internal constant kovan_eth_usd_aggregator =
        0x9326BFA02ADD2366b30bacB125260Af641031331;

    // mapping to store which address deposited how much ETH
    mapping(address => uint256) public addressToAmountFunded;
    // array of addresses that deposited ETH
    address[] public funders;
    // address of the owner (who deployed the contract)
    address public owner;

    // constructor() is called on the contract deploy. msg.sender contains the address
    // of the entity performing the contract call. on contract creation this entity will
    // be the one that created the contract, thus msg.sender in the constructor()
    // will containd the address of the entity that created/owns the contract
    constructor() public {
        owner = msg.sender;
    }

    // get version of ChaninLink pricefeed
    function getVersion() public view returns (uint256) {
        // network: Kovan, aggregator: ETH/USD address
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            kovan_eth_usd_aggregator
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // network: Kovan, aggregator: ETH/USD address
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            kovan_eth_usd_aggregator
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digits. the returned value already has 8 zeroes, so we will add 10 more
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        // remove the 18 zeroes from the price
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    /*
        A function marked as "payable" can receive and/or send ETH. The amount of ETH received will go into the
        "value" field.
    */
    function fund() public payable {
        // WEI contain 18 zeroes, so let's convert to that format the USD too, so that we can then compare them
        uint256 minimumUSD = 2 * 10**18;
        // if the donated amount is less than 2 USD, then revert
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "A minimum of 50 USD is required"
        );
        // if we reach this line, then the sent ETH amount was >= 50 USD
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    modifier onlyOwner() {
        // asssert that the message sender is the owner of the contract, or revert
        require(msg.sender == owner);
        _;
        // "_" means run whatever the code is in the funciton after. you can also put it above the code in the modifier, and this way,
        // the code of the function that you are modifying will run before the code of the modifier.
        // this is very similar to a decorator in Python, or the decorator design pattern
    }

    function withdraw() public payable onlyOwner {
        // in Solidity v0.8.0 you must put payable(msg.sender)
        msg.sender.transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // clear the funders array
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