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

// SPDX-License-Identifier: MIT

//pragma
pragma solidity ^0.8.0;

//Imports
import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//Error Code
error FundMe__NotOwner();

//interfaces, libraries, contracts
/** @title a contract for crowd funding
 * @author David Yang
 * @notice This is to demo a simple funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    //Type Declarations
    using PriceConverter for uint256;
    //before constant 859817, after 840257
    //constant can save a lot of gas money!!

    //State Variables
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] private s_funders; //sender list
    mapping(address => uint256) private s_addressToAmountFunded; //to see who send how much money
    address private immutable i_owner; //immutable can save a lot of gas
    AggregatorV3Interface private s_priceFeed;

    //Modifier
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Senders is not the owner!");
        if (msg.sender != i_owner) revert FundMe__NotOwner(); //error could also save gas
        _; //this means do the original function code after modifier.
    }

    //Functions

    // Functions Order!!!
    // constructor
    // receive
    // fallback
    // external
    // public
    // internal
    // private
    // view / pure

    //constructor
    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    } // set the withdraw funchtion that can only be used by the s_funders

    // //receive()
    // receive() external payable{
    //     fund();//this will lead to the fund function
    // }

    // //fallback()
    // fallback() external payable{
    //     fund();
    // }

    /**
     * @notice This function funds this contract
     * @dev This implements price feeds as our library
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough, you need to spend more ETH!!!"
        ); //1e18 = 1 * 10 ** 18 with 18 decimals

        s_funders.push(msg.sender); //the address whoever calls the fund functions.
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            //code
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //reset array
        s_funders = new address[](0);
        //actually withdraw funds

        // //transfer will automatically revert the contract if it is failed.
        // payable(msg.sender).transfer(address(this).balance);

        // //send will not revert if it is failed!, so you must add require() to prevent this situation.
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed");

        // //call is similar to send
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // mappings can not be in memory, sorry!
        for (
            uint256 fnderIndex = 0;
            fnderIndex < funders.length;
            fnderIndex++
        ) {
            address funder = funders[fnderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns(address) {
        return s_funders[index];
    } 

    function getAddressToAmountFunded(address funder) public view returns(uint256) {
        return s_addressToAmountFunded[funder];
    } 
    function getPriceFeed() public view returns(AggregatorV3Interface){
        return s_priceFeed;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        
        (,int256 price,,,) = priceFeed.latestRoundData();
        //ETH in terms of USD
        //3000.00000000
        return uint256(price * 1e10); // 1**10 == 10000000000

    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // 1300_000000000000000000 = ETH / USD price
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

}