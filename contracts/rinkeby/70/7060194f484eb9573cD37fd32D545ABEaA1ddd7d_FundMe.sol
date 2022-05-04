// SPDX-Licence-Identifiers: MIT << Open licence, anyone can use the code

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";
import "SafeMathChainlink.sol";

contract FundMe {
    // safe math library check uint256 for integer overflows
    using SafeMathChainlink for uint256;

    //mapping between add and value
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders; // funders array, to save those that have funded the contract to use later
    address public owner; // declare the address as owner

    constructor() public {
        //** anything in here will be immediately executed once the contract is deployed **
        owner = msg.sender; // this is going to be the user that deploys the contract
    }

    // We want it to accept payments
    function fund() public payable {
        // $50
        // to guarantee the user amount is at least $50, then multiplied by 10 ^ 18 to convert to gwei
        uint256 minimumUSD = (50 * 10 * 18);
        //rather than using an if statement, we use require
        //if(msg.value < minimumUSD){
        //    revert?
        //}
        // this will check the min USD has been sent, if not it will revert sending their money back and any unsent gas
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        // 1gwei < $50 so we need to put more in the fund
        // using the converter we convert 0.1 ether to gwei and wei
        // wei = 100000000000000000
        // this function can be used to pay for things because of the payable argument
        //when deployed the button for this function is red because its a payable function
        addressToAmountFunded[msg.sender] += msg.value;
        // what the ETH -> USD conversion rate
        // to get this data, we need a oracle

        // whenever a funder funds the contract, it will add them to our funders array
        funders.push(msg.sender); //  doesn't deal with dupes
    }

    function getVersion() public view returns (uint256) {
        //this is a function that exists on the interface
        // this address is actually on a real testnet, its on the Rinkby testnet, so we have to deploy our contract to there
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData(); // remove the unused vars and leave blanks with commas
        return uint256(answer * 1000000000); // type casting to get this to uint from int
        // the multiplicatoin isn't required, but to convert to wei format and give 18 decimals this is why this is done
        //  330017732897 (8 decimals, so 3300.17732897 is the actual number
    }

    // converter page: https://eth-converter.com/
    // 1000000000 = 1 ether in gwei | this needs to be converted to USD
    // 32491627.0308000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000; // this converts the eth to USD
        return ethAmountInUSD; // this results in a bigger number than we are looking for in the beginning
        //when we add the 1 gwei to the getConversionRate function, we get a huge number 32223823304400000000000000000000
        // by dividing the result the price then comes back correctly 1000000000000000000
        // 3249162703080 (i added a zero at the end)
        // 0.000003249162703080 - counted back 13 to total 18 decimals, then added the decimal and 0
        // now mutliple the above by the gwei amount 1000000000, this will give the usd equiv
        // $3,249.16270308 from the above calcs
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _; // this part is the start for the function, so everything above it will
        // be run in the modiefier before the function that includes the modifier is run
    }

    function withdraw() public payable onlyOwner {
        // now includes the modifier
        // FROM msg.sender TO transfer()
        // require msg.sender = owner << how do we get an owner
        // if we created a function called create owner, the issue is someone else could call that function and become the owner right?

        require(msg.sender == owner); // msg.sender HAS TO EQUAL owner, the address who deployed the contract
        // ** To do this properly, we use the constructor so that the owner is assigned upon deployment - GO UP TO TOP **

        msg.sender.transfer(address(this).balance);
        // msg.sender - whoever is calling the function, in this case 'withdraw'
        // 'this' is a keyword in Solidity - this refers to the contract that you are in
        // 'address' is the address of, followed by the keyword 'this' means the address of this contract (presently in)
        // '.balance' attribute called with address shows the balance of the address being referenced, in the above that
        // is 'this address balance' in ether
        // so in english 'caller of the function withdraw, transfer the balance of this contract to them'
        // once clicked, you should receive all the ether transferred via the 'fund' function, back
        // as a public function this allows ANYONE to withdraw the contract funds from it

        // next when we withdraw the contract balance we want to reset everyones balance to 0
        // For Loop
        //funders.length is to get the length of the array
        // the loop will finish whenever the funderIndex is greater than the funders array length (number of funders)
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex]; // use the index as the key in the mapping
            addressToAmountFunded[funder] = 0;
        }
        // reset the funder array to 0
        // we can do this one way by setting the funders to a new array, a new blank address array
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