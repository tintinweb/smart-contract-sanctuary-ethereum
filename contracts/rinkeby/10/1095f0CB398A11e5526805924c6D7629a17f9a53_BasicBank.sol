// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

/**
 * @title BasicBank
 * @dev Implements basic despoit, withdraw, and ability to fund owner
 */
contract BasicBank {
    using SafeMathChainlink for uint256;

    address private owner;

    uint256 private minDepositUSD;

    mapping(address => uint256) public addressToBalance;

    /**
     * @dev Set contract deployer as owner
     */
    constructor() public {
        owner = msg.sender;
        minDepositUSD = 50;
    }

    /**
     * @dev Change the minimumUSD amount
     * @param _minDepositUSD USD amount to change the minimum to
     */
    function setMinDeposit(uint256 _minDepositUSD) public onlyOwner {
        minDepositUSD = _minDepositUSD;
    }

    /**
     * @dev Get the minimum deposit in USD amount
     * @return Minimum deposit in USD
     */
    function getMinDeposit() public view returns (uint256) {
        return minDepositUSD;
    }

    /**
     * @dev Deposit into account
     */
    function deposit() public payable {
        require(
            getConversionRate(msg.value) >= minDepositUSD,
            "Must deposit above the minimum amount"
        );
        addressToBalance[msg.sender] += msg.value;
    }

    /**
     * @dev Fund the owner
     */
    function fundOwner() public payable {
        addressToBalance[owner] += msg.value;
    }

    /**
     * @dev Get price of ETH in USD with 8 decimals
     * @return address of owner
     */
    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer);
    }

    /**
     * @dev Convert ETH in Wei to USD
     * @param ethAmountWei amount of ETH in Wei to convert
     * @return equivalent amount of USD
     */
    function getConversionRate(uint256 ethAmountWei)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = ((ethAmountWei) * (ethPrice)) / 1e26;
        return ethAmountInUsd;
    }

    /**
     * @dev Withdraw a certain amount of Wei
     * @param _amountWei amount of ETH in Wei to withdraw
     */
    function withdraw(uint256 _amountWei) public payable {
        require(
            addressToBalance[msg.sender] - _amountWei >= 0,
            "Insufficient balance"
        );
        addressToBalance[msg.sender] -= _amountWei;
        msg.sender.transfer(_amountWei);
    }

    /**
     * @dev Withdraw all ETH in account
     */
    function withdrawAll() public payable {
        require(addressToBalance[msg.sender] > 0, "Insufficient balance");
        uint256 balance = addressToBalance[msg.sender];
        addressToBalance[msg.sender] = 0;
        msg.sender.transfer(balance);
    }

    /**
     * @dev Return owner address
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
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