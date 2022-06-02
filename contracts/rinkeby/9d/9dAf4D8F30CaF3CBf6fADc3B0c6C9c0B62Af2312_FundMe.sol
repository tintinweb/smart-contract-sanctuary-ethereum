// SPDX-License-Identifier: MIT
//Pragma
pragma solidity ^0.8.8;
//Imports
//Import the PriceConverter library
import "./PriceConverter.sol";
//Error codes
//There are now defined errors in Solidity that require less gas.
error FundMe__NotOwner();

//This contract will be used to get funds from users, withdraw funds, set a minimum funding value in USD
/** @title A contract for crowdfunding
 *   @author Nathan Alexander
 *   @notice This contract is to demo a sample funding contract
 *   @dev This implements price feeds as our library
 */
contract FundMe {
    //Type Declarations

    //This is how we use the library as extensions - any library method that returns uint256 can be used as a method on uint256
    using PriceConverter for uint256;
    //State Variables
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToContribution;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner.");

        //Better way than require because it says gas.
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    //The payable modifier lets the compiler know that value can be sent to this function. The balance is stored in the contract's address.
    /**
     *   @notice This function allows function callers to fund the contract
     *   @dev Funders will be added to the map and the funders array
     */
    function fund() public payable {
        //Want to be able to set a minimum fund amount in USD

        //msg.value gets the amount of value sent in the transaction
        //The require method is a checker, it will make sure that msg.value is at least 50 USD or revert
        //msg.value is uint256 so we can call getConversionRate on it implicity, we don't need to pass in the parameter - it is inferred.
        //If you have additional parameters, they must be passed in.
        require(
            msg.value.getConversationRate(priceFeed) >= MINIMUM_USD,
            "Minimum not met."
        );
        funders.push(msg.sender);
        addressToContribution[msg.sender] = msg.value;
        //Reverting: All computation that fails gets the value returned to the user. All prior work will still cost gas but be undone.
    }

    function showContribution(address _address) public view returns (uint256) {
        return addressToContribution[_address];
    }

    function withdraw() public onlyOwner {
        //for loops in Solidity take three arguments: starting index, ending index, and step amount.
        //We define a variable and set it to 0 for the starting index
        //We set the ending condition, the funderIndex variable can't be larger than the funders array
        //We increment fundersIndex
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToContribution[funder] = 0;
        }
        //reset the array
        //This sets funders to a new array with no elements in it - this is what the (0) means.
        funders = new address[](0);
        //withdraw funds

        //msg.sender = address
        //payable(msg.sender) = payable address

        //As of right now call is the best way to send funds from a contract.
        //We say (bool callSuccess, ) because call returns two values, but we only want to use callSuccess so we disregard the other
        //To use call as a payment, we have to include the value in the call, which is set to address(this).balance;
        //"this" always refers to the current contract, so we are saying get the balance of this contract's address.
        //the ("") is necessary because call is a base level function and can call other functions, but we don't want it to - so we leave it blank with empty string.
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        //We are going to use the callSuccess bool to make sure the transaction went thru. This is so we can revert and not waste funds if it fails.
        require(callSuccess, "Call failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//We can import directly from GitHub to get the price aggregator interface - this also gives us the ABI.
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//Libraries are similar to contracts
//Library methods must have the internal view modifier on them
//They can be called in the main contract on the type that they return, in this code its uint256.
library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //The aggregator's latestRoundData() function returns several different variables, however we are only interested in price.
        //You can add a comma in place of the variables you don't wish to store.
        //(uint80 roundID, int price, uint startedAt, uint timeStamp, uint80 answeredInRound) becomes (,int price,,,)
        //We can explicity say int256 in place of int because int defaults to int256
        (, int256 price, , , ) = priceFeed.latestRoundData();

        //We are typecasing int256 price to uint256 because this is a large number
        return uint256(price * 1e10); // 1**10
    }

    function getConversationRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed); //Get the price of eth in USD
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1e18; //Returns in amount specified in USD
        return ethAmountInUsd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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