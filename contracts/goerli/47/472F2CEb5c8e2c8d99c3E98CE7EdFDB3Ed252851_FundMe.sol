// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// Get funds from Users
// Withdraw funds
// Set a minimum funding value in USD

//SPDX-License-Identifier: MIT

//Pragma
pragma solidity ^0.8.0;

//Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

//Error Codes
error FundMe__NotOwner();

/** @title A contract for crowd funding
 * @author Rahul Bansode
 * @notice This contract is to demo a sample funding contract
 * @dev This implements price feds as our library
 */

contract FundMe {
    //Type Declaration
    using PriceConverter for uint256;

    //State Variables
    uint256 public constant MINIMUM_USD = .2 * 1e18;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;

    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    //Modifiers
    modifier onlyOwner() {
        //require(msg.sender == iOwner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; //execute the rest of the code where the modifier is used
    }

    //Functions
    ///Construcotr
    constructor(address _priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    ///Receive
    receive() external payable {
        fund();
    }

    ///fallback
    fallback() external payable {
        fund();
    }

    //Public Functions
    /**
     * @notice This function to recives the fund for the contract
     * @dev This implement price feeds as our library
     */

    function fund() public payable {
        // Want to be able to set a minimum fund amount in USA
        // 1. How do we send ETH to this contract

        /* Explaination of how ether is calculated
        //1e18 = 1* 10* 18 = 1000000000000000000
        //require is validation function to verify if we need to proceed further. 
        // We have the option to revert the transaction, if the condition is not met
        //What is reverting? Undo any prior action done in the code, and send remaining gas back
        require (msg.value >1e18, "Didn't send enought ETH!!!");
        */

        //Check if the ether value is greater than the minimum USD
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    /**
     * @notice This function withdras all the funds from the contract. This function can be called only by the owner
     */
    function withdraw() public onlyOwner {
        //For loop syntact for (starting index, loop condition, step )
        for (uint256 i = 0; i < s_funders.length; i++) {
            //Get the address of the funders
            address funderAddress = s_funders[i];

            s_addressToAmountFunded[funderAddress] = 0;
        }

        /*
        //Transfer:
        //transfer funds to the caller of the function
        //transfer will fail if there is any error while executing the transaction
        payable(msg.sender).transfer(address(this).balance);

        //Send:
        // Semd returns a bool if the transfer fails
        payable(msg.sender).send(address(this).balance);
        */

        //Call:
        // Semd returns a bool if the transfer fails
        (bool callSuccess, bytes memory dataReturned) = payable(msg.sender)
            .call{value: address(this).balance}("");

        //Check if the call is success or failed
        require(callSuccess, "Call Failed to withdraw all the funds.");
    }

    //Cheaper withdraw
    function cheaperWithdraw() public onlyOwner {
        //Store the funders in the local variable
        address[] memory funders = s_funders;

        //For loop syntact for (starting index, loop condition, step )
        for (uint256 i = 0; i < funders.length; i++) {
            //Get the address of the funders
            address funderAddress = funders[i];

            s_addressToAmountFunded[funderAddress] = 0;
        }

        s_funders = new address[](0);

        // Semd returns a bool if the transfer fails
        (bool callSuccess, bytes memory dataReturned) = i_owner.call{
            value: address(this).balance
        }("");

        //Check if the call is success or failed
        require(callSuccess, "Call Failed to withdraw all the funds.");
    }

    //Get for the iOwner
    function getOwner() public view returns (address) {
        return i_owner;
    }

    //Get for the funders
    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    //Get for the AddressToAmountFunded
    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    //Get for the Price Feed
    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        //Address of the contract from ChainLink  - 	0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );

        AggregatorV3Interface priceFeed = _priceFeed;

        (, int256 price, , , ) = priceFeed.latestRoundData();

        //ETH in tersm of USD = 3000.00000000
        return uint256(price * 1e18); //1 * 10 = 10000000000
    }

    function getDescription() internal view returns (string memory) {
        //Address of the contract from ChainLink  - 	0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );

        return priceFeed.description();
    }

    function getDecimals() internal view returns (uint8) {
        //Address of the contract from ChainLink  - 	0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );

        return priceFeed.decimals();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint256) {
        /*Example of the calculation 
            Price of ETH in USD amount = 3000_0000000000000000 ($3K)
             ETHs = 1_0000000000000000 ETH
             Conversion Amount = 2999.99999999999999999
        */
        //Get the latest price
        uint256 ethPrice = getPrice(_priceFeed);

        //COvert the eth amount in USD
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;

        return ethAmountInUSD;
    }
}