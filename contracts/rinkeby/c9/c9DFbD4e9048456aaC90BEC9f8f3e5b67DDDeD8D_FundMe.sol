// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;
//chainlink interface to get latest conversion
import "AggregatorV3Interface.sol";

//import "SafeMathChainlink.sol";

contract FundMe {
    // safe math library check uint256 for integer overflows
    // using SafeMathChainlink for uint256;
    //creating mapping of address to  uint456(value)
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address[] public funders;

    constructor() public {
        owner = msg.sender;
    }

    //payable here means that it can perform a transaction
    function Fund() public payable {
        //setting minimimum usd value and converting it into
        uint256 minimumUSD = 50 * 10**18;
        //to make sure that the transfer doesnot happen oif the entered amount is less than 50$USD
        require(
            getConverionRate(msg.value) >= minimumUSD,
            "Need to spend more ETH you miser bitch"
        );
        //here msg.addres & msg.value are special keywords to keep track of all the funding
        //msg.sender is the sender of the vlaur
        //msg.value is the amount of money sent and everything will be saved in the addressToAmountFunded
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        //interfaces help to interact with contracts they compile down to ABI which we discussed earlier
        //ABI's are the one that tells what functions to call or use from the contract or how to interact with other contracts
        //as discussed earlier we know that ABI is one of the nessicety to interact with another contract
        //when we go to the cod ewe see that the code is an interface not a contract
        /* so here to interact with the interface we will call its type like we used to in structs or variables in this case it is the "AggregatorV3Interface" and 
        then we would give its visibility but hrere we are in the contract and if we follow rthe link we see the visubility is alredy told for the it so we will name it
        then we do equals and name of interface "vAggregatorV3Interface" and then in the bracket we type the contract address 
        we get he contract form chainlink data site which acts as oracles here an we find the contract with the testchain/mainnet we want to use
        here we are using the rinkbey test chain whivh is "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"and the contract addres is diffrent for every cain   */
        //the line mean that we have an interface "AggregatorV3Interface" having some functions at agddress"0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return priceFeed.version();
        //here we made a contract call form one caontract o another contrac using interfaces
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        /*here extra comma mean that ther is afunction but we wnat to ignore it 
        as in the interface we use have 5 function and we inly need one*/
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        /*here we used uint256 because in the interface it is
        set as int256 anw while defining the function 
        we said tht we want the output to be uint256
        In additonn to that we multlipid it to 10000000000 to convert the gwei to wei 
        so that the all the values have 18 decimal places since we had 8 decimal places alredy hence we multiplied it to 10 additional decimal places  */
        return uint256(answer * 10000000000);
    }

    function getConverionRate(uint256 ethAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUSD;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you greedy son of bitch");
        _;
    }

    function withdraw() public payable onlyOwner {
        //transfer is a function that we can call on any
        //this are keyword in saolidity which meant the coontract we are
        //hence address of this means the address of the contract we areworing on
        //this mean that who ever cakk the withdraw finction transfer them all the money
        payable(msg.sender).transfer(address(this).balance);
        //iterate through all the mappings and make them 0
        //since all the deposited amount has been withdrawn
        //resetting the whole ammount to zero as the all the currewncy will be withdrawn by the owner
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //funders array will be initialized to 0
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