// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// import a contract to get the latest ETH -> USD price conversion
import "AggregatorV3Interface.sol";

// to avoid overflow when working with compilers < 0.8.0 ONLY
import "SafeMathChainlink.sol";

contract FundMe {
    // enforce using SafeMathChainlink for all uint256 to
    // prevent overflow from happening
    using SafeMathChainlink for uint256;

    // make a mapping to track with account sends money
    mapping(address => uint256) public addressToAmountFunded;

    // create an array of funders' addresses so we can reset their balanace
    address[] public funders;

    // create a constructor that gets the owner of this contract
    // this is needed b/c later on, the owner of this contract
    // is the only able to withdraw a transaction and not anyone
    // else who accesses the `withdraw` function
    address public owner;

    constructor() public {
        owner = msg.sender; // this refers to whoever deploys this contract
    }

    // this contract needs to accept some sort of payment
    // This will be done via a function. Note the keyword 'payable'
    // which means this function is used to pay for things
    // such funcitons has `value` associated with it, measured in wei or Gwei, or Eth
    // which is how much money in a transaction the function will send/pay
    function fund() public payable {
        // set a minimum threshold limit of USD, so that below this threshold,
        // the transaction will not be made
        uint256 minimumUSD = 50 * 10 * 18; // express this quantity in 18 decimals(it is supposed to be 10**18 but it does not work when making a payment!)

        // make sure the msg.value is > minimumUSD, otherwise, revert/ cancel transaction
        // this is similar to an if statement, but we use `require` statement
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );

        // `msg.sender` is a keyword in every transaction referring to the sender,
        // while `msg.value` is how much they sent
        addressToAmountFunded[msg.sender] += msg.value;

        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // define a state variable of type `AggregatorV3Interface`
        // the address we forward to `AggregatorV3Interface` is from the link
        // https://docs.chain.link/docs/ethereum-addresses/ under Rinkeby section
        AggregatorV3Interface aggInterfaceVersion = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return aggInterfaceVersion.version();
    }

    // make a function that returns the ETH to USD exchange rate from the AggregatorV3Interface
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer); // cast the data type of Eth to USD expressed by `answer` from int256 to uint256
    }

    function getConversionRate(uint256 fundedAmountInEth)
        public
        view
        returns (uint256)
    {
        uint256 ethToUsdRate = getPrice();
        uint256 ethAmountInUsd = (ethToUsdRate*fundedAmountInEth)/10000000000;
        return ethAmountInUsd;
    }

    // create a modifier. Before we run the function below,
    // we need to run a modifier that checks the owner of this
    // contract. The `_;` means run whatever comes after the modifier
    // after executing what preceeded the `_;`
    modifier onlyOwner() {
        require(msg.sender == owner); // msg.sender here refers to account address of whoever invokes `withdraw` function
        _;
    }

    // create a withdraw function that helps the sender to
    // withdraw the money transaction
    function withdraw() public payable onlyOwner {
        // transfer money to the sender
        // the keyword `this` refers to this contract
        // `address(this): is the address of the contract
        // that we are currently in`
        msg.sender.transfer(address(this).balance);

        // loop through `funders` array
        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            address funder = funders[fundersIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reset the funders array
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