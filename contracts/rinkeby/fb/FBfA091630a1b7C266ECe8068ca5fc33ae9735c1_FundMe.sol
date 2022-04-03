// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

// Solidity interfaces are compiled down to ABIs, which are needed for 
// interacting with any data or functions defined in third-party contracts.

// This import allows the FundMe contract to interact with the Chainlink 
// contract actually providing the pricing feed.
import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

// The following contract should showcase how payments made
// by different users might be (1) independently tracked and
// how (2) the aggregate sum of these payments might be calulated
// and visualized.
contract FundMe {
    // This will make sure that arithmetic overflows will throw an error,
    // allowing us to implement specific behavior for handling that case.
    // This is not needed in versions >=0.8, because such version set
    // will automatically add overflow checks to arithmetic operations.
    using SafeMathChainlink for uint256;

    mapping(address => uint256) public addressToAmountFunded;

    event FundCast(address funder, uint sentWei, uint USDCentValue);

    // TODO: ENSURE THAT ITEMS MIGHT BE EFFICIENTLY REMOVED FROM THE ARRAY
    address payable [] public funders;

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {

        // We should bear in mind that since Solidity has no native support
        // for floating point numbers, we can only carry out precise operations
        // involving small quantities by representing values with as many bits
        // as possible and representing them with the finest available units
        // of measure.
        // 
        // Following this philosophy, msg.value encodes the amount of sent
        // funds in wei (ETH / 10^18) rather than gwei, finnei, or Ether.
        uint256 usdAmount = getConversion(msg.value);
        require(usdAmount >= 500, "You need to send at least 5 USD!");
        emit FundCast(msg.sender, msg.value, usdAmount);
        bool isNewFunder = (addressToAmountFunded[msg.sender] == 0);
        if (isNewFunder) {
            funders.push(msg.sender);
        }
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns(uint256) {
        return AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e).version();
    }

    function getETHUSDRate() public view returns(int256) {
        (
            ,
            int256 answer,
            ,
            ,
            
        ) = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e).latestRoundData();
        return answer;
        // return 291640000000;
    }

    // This function receives an amount of wei and converts it
    // to USD cents.
    function getConversion(uint256 ethAmount) public view returns(uint256) {
        //  IMPORTANT NOTE: A ^ B results in the xor operation between 
        //  A and B, not in A to the power of B!
        //return ethAmount * uint256(getETHUSDRate()) / (10 ^ 24); // WRONG!
        return ethAmount * uint256(getETHUSDRate()) / (10 ** 24);
    }

    function getCurrentBalance() public view returns(uint256) {
        return address(this).balance;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "This function can only be called by the contract owner.");
        _;
    }

    modifier onlyLonelyFunder {
        require(getCurrentBalance() == addressToAmountFunded[msg.sender], "This function only succeeds if the caller is the only funder of the pool.");
        _;
    }

    function withdraw() payable onlyOwner onlyLonelyFunder public {
        uint256 currentBalance = getCurrentBalance();
        addressToAmountFunded[msg.sender] -= currentBalance;
        msg.sender.transfer(currentBalance);
    }

    function withdrawAmount(uint256 amount) payable public {
        require(addressToAmountFunded[msg.sender] >= amount, "The user can only withdraw up to as much as he or she has funded.");
        addressToAmountFunded[msg.sender] -= amount;
        msg.sender.transfer(amount);
    }

    function withdrawToAll() payable onlyOwner public {
        for (uint256 i = 0; i < funders.length; i++) {
            address payable funder = funders[i];
            uint256 amount = addressToAmountFunded[funder];
            if (amount > 0) {
                funder.transfer(amount);
                addressToAmountFunded[funder] = 0;
            }
        }

        // This effectively removes all entries from the funders array.
        funders = new address payable [](0);
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