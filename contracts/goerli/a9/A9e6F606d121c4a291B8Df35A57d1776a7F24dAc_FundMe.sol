//SPDX-License-Identifier: MIT
//Last update: 25/12/2022

/* ***** ABI = Application Binary Interface *****
 * Interfaces compile down to an ABI. 
 *
 * ABI tells Solidity and other coding languages
 * how it can interact with other contracts. 
 *
 * Anytime you want to interact with another
 * deployed contract, you will need that contracts' ABI.
 */

pragma solidity ^0.6.6;

// ***** Imports *****
import "SafeMathChainlink.sol";
import "AggregatorV3Interface.sol";   //The following library is shown below
/*
 *
 *      interface AggregatorV3Interface 
 *      {
 *       function decimals() external view returns (uint8);
 *
 *       function description() external view returns (string memory);
 *
 *       function version() external view returns (uint256);    <-------------- Version
 *
 *       function getRoundData(uint80 _roundId) external view returns 
 *       (
 *           uint80 roundId,
 *           int256 answer,          
 *           uint256 startedAt,
 *           uint256 updatedAt,
 *           uint80 answeredInRound
 *       );
 *
 *       function latestRoundData() external view returns 
 *       (
 *           uint80 roundId,
 *           int256 answer,             <---------- Value in USD
 *           uint256 startedAt,
 *           uint256 updatedAt,
 *           uint80 answeredInRound
 *       );
 *      }
 *
 */

// ***** FundMe *****
// The following contract allows the end users to send a minimum amount
// of ETH without being able to retrive it.
// This contract is a good example of crowd funding.
contract FundMe{
    AggregatorV3Interface public priceFeed;
    
    // ***** AddressToAmountFunded *****
    // The following mapping allows the user to access the amount funded
    // by somebody, provided the address.
    mapping (address => uint256) public AddressToAmountFunded;

    // Array of addresses where the address of each funder will be stored in a temporary way
    // Every time the owner calls the withdraw function, the array is being reset
    address[] public funders;

    // Owners' address: this will be the only address being able to withdraw
    address public owner;

    // Constructor is called automatically and istantly when the contract is being deployed
    // Such thing allows the deployer of the contract to be the owner
    constructor(address _priceFeed) public
    {
        owner = msg.sender;     // msg.sender is who calls a function, in the constructor case, who deploys the contract
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // ***** onlyOwner *****
    // The following modifier is used in the declaration of functions, such as withdraw, 
    // in order to allow the function, to be called only by the owner.
    modifier onlyOwner
    {
        require(msg.sender == owner);      // Whoever calls the function (msg.sender) must be the owner
        _;                                 // The "_;" means that we call the instruction after we check that the address of the caller is equal to owner
    }

    // ***** fund *****
    // The following function allows the users to fund the contract with a minimum amount of money "minimumUSD"
    // to this date (25/12/2022) 50$ = 0,041ETH = 41000000000000000Wei = (41 * 10^15)Wei - to update the value, check the USD/ETH change and convert to Wei here https://eth-converter.com/
    // If the amount funded is <= minimumUSD the transaction will not go through and will lead to an inversion of the
    // transaction
    // ! ! ! ! ! Please notice that the amount funded cannot be retrived in any way ! ! ! ! !
    function fund() public payable
    {
        uint256 minimumUSD = 41 * 10 ** 15;                                                                                        // Minimum amount transferable
        require(msg.value >= minimumUSD, "The amount of ETH you sent is less then 50$ - Transaction is being inverted");           // "msg.value" is a keyword that stays for the amount of Wei sent

        AddressToAmountFunded[msg.sender] += msg.value;             // Given an address, the mapping will return the amount funded by such account - Note that these values will be reset every time withdraw is called
        funders.push(msg.sender);                                   // The funders' address will be added to the funders array - Note that these values will be reset every time withdraw is called
    }

    // ***** getVersion *****
    // The following function is contained inside of the imported library AggregatorV3Interface
    // When called, the function will return the current version of the contract/library AggregatorV3Interface
    // ! ! ! ! ! This function will only work if the ENVIROMENT used is local (METAMASK) - JVMs will not return any value and will lead to a possible error ! ! ! ! !
    function getVersion() public view returns(uint256)
    {      
        return priceFeed.version();     // .version method is contained inside of AggregatorV3Interface, the address can be find here
        //                                                                                                                                                                                 |
        // The function works also if written like this:                                                                                                                                   |
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);  <--- Address                                                              |
        // return priceFeed.version();                                                                           <--- ABI                                                                 /
        // You can find the Addresses for AggregatorV3Interface here ---> https://docs.chain.link/data-feeds/price-feeds/addresses/ <----------------------------------------------------
    }

    // ***** getPrice *****
    // The following function is contained inside of the imported library AggregatorV3Interface
    // When called, the function will return the current value of 1ETH in USD, please note that you will get an apporximate value 
    // ! ! ! ! ! This function will only work if the ENVIROMENT used is local (METAMASK) - JVMs will not return any value and will lead to a possible error ! ! ! ! !
    function getPrice() public view returns(uint256)
    {                                                                                                           // .latestRoundData method is contained inside of AggregatorV3Interface, the address can be found above
        (,int256 answer,,,) = priceFeed.latestRoundData();                                                      // The method returns 5 different values, we exclude all of them but answer, for further understanding check at AggregatorV3Interface under imports
        return uint256(answer / 10 ** 8);                                                                       // Answer is divided by 10^8 so that the value in USD has no decimals and is easier to read
        
        // Historical:
        // 23/12/2022 - 1,226.67395017
        // 25/12/2022 - 1,220.00000000
    }

    // ***** getConvertionRate *****
    // The following function could be considered an extension of getPrice : given
    // the amount of ETH, the function will return the current value of such amount of ETH
    // in USD
    // ! ! ! ! ! This function will only work if the ENVIROMENT used is local (METAMASK) - JVMs will not return any value and will lead to a possible error ! ! ! ! !
    function getConvertionRate(uint256 ETH_Amount) public view returns(uint256)
    {
        uint256 ETH_Price = getPrice();                         // Calls getPrice function
        uint256 ETH_AmountInUSD = ETH_Price * ETH_Amount;       // Current ETH pirce * ETH amount
        return ETH_AmountInUSD;                                 // Returns the value of amount ETH in USD
    }

    // ***** withdraw *****
    // The following function allows the deployer of the contract (owner) to withdraw
    // the amount of ETH funded to the contract, moreover when the function is called,
    // the funders array will be reset
    function withdraw() payable onlyOwner public                // Check for onlyOwner modifier description at line 77
    {
        payable(msg.sender).transfer(address(this).balance);    // This line of code allows the withdrawal, this refers to the contract

        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++)   // The following cycle allows the reset of the money
        {                                                                           // value sent by the funders, accessible through mapping
            address funder = funders[funderIndex];
            AddressToAmountFunded[funder] = 0;
        }

        funders = new address[] (0);                            // funders array gets reset, so that it's able to store new values starting from 0
    }
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