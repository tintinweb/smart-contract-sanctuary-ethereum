// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

import "SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;
    //0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    uint256 minimumAmount = 50 * (10**18); //50usd in wei; (50 usd*10**18)usd in wei is (0.017eth* 10**18 wei) eth in wei
    //uint256 minimumAmount = 50; //bujos way with the 'true' keyword fx
    address owner;
    address[] funders;
    mapping(address => uint256) public addressToAmountFunded;
    AggregatorV3Interface public aggregator;

    constructor(address _priceFeedAddress) public {
        owner = address(msg.sender);
        aggregator = AggregatorV3Interface(_priceFeedAddress);
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 precision = 10**18;
        uint256 entranceFee = (minimumAmount * precision) / getEthPrice();
        return entranceFee;
    }

    function fund() public payable {
        //setting the minimum deposit value to 50 usd
        require(
            convertTrueEthPricetoUsd(msg.value) >= minimumAmount,
            "You need to send more Eth"
        );
        //mapping the address to the value deposited by that address
        addressToAmountFunded[msg.sender] += msg.value;
        // pushing the address to the funders array after depositing
        funders.push(msg.sender);
    }

    function balanceOfTheContract() public view returns (uint256) {
        uint256 balance = (address(this)).balance;
        return balance;
    }

    function getVersion() public view returns (uint256) {
        // calling the contract using the interface by locating where the address lives (ETHUSD price feed contract on rinkeby network)
        //AggregatorV3Interface aggregator = AggregatorV3Interface(
        //   0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //);
        uint256 thisVersion = aggregator.version();
        return thisVersion;
    }

    function getEthPrice() public view returns (uint256) {
        //AggregatorV3Interface aggregator = AggregatorV3Interface(
        //  0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //);
        (, int256 answer, , , ) = aggregator.latestRoundData();
        return uint256(answer * 10**10);
    }

    function getTrueEthPrice() public view returns (uint256) {
        //AggregatorV3Interface aggregator = AggregatorV3Interface(
        //   0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //);
        (, int256 answer, , , ) = aggregator.latestRoundData();
        return uint256(answer / 10**8);
    }

    function convertEthtoUsd(uint256 _ethvalue) public view returns (uint256) {
        uint256 ethprice = getEthPrice();
        return ((ethprice * _ethvalue) / 10**18);
    }

    function convertTrueEthPricetoUsd(uint256 _ethvalue)
        public
        view
        returns (uint256)
    {
        uint256 ethprice = getTrueEthPrice();
        return (ethprice * _ethvalue);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Admins only");
        _;
    }

    function withdraw() public payable onlyOwner {
        //sending this contract's balance to the admin who was initialized as the owner in the constructor using send method
        bool didSend = msg.sender.send(address(this).balance);
        require(didSend);
        //funders length starts from 1 whereas the index starts from zero hence loops until its no truer
        //during the looping all addresses balances mapped to the funders addresses will be set to zero
        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            addressToAmountFunded[funders[fundersIndex]] = 0;
        }
        //resetting the funders array to the new empty array
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