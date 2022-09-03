// SPDX-License-Identifier: MIT
// pragma
pragma solidity ^0.8.8;
//Imports
import "./PriceConverter.sol";
// Error Codes ContractName__error()

// error codes
error FundMe__NotOwner();

// Interfaces, Libraries, Contract

/**  @title Hardhat Free Coding Camp Contract Tutorial for Crowdfunding
 *   @author Sean Francis
 *   @notice This demos a sample funding contract
 *   @dev This implements price feeds as our library
*/
contract FundMe{

    // Type Declarations
    using PriceConverter for uint256;

    // State Variables
    address private immutable i_owner; // save gas using variable you'll define only once
    uint public constant MINIMUM_USD = 50 * 1e18; // multiply by 1e18 to have the same units as eth/ constant with same idea as above
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed; //stored variables COST A LOT OF GAS

    // modifiers
    modifier onlyOwner(){
        //require(msg.sender == i_owner, "You are NOT the owner of this contract!");
        if(msg.sender != i_owner) revert FundMe__NotOwner();
        _; // do the rest of the code - make sure it's after the require function
    }
    
    /*
    constructor
    receive
    fallback
    external
    public
    internal
    private
    view/pure
    */


    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable{
        fund();
    }
    //eth-converter.com
    // use above to convert eth amount to Wei to input in value section


    /**  
     *   @notice This function funds this contract
     *   @dev This implements price feeds as our library
     *   no params
     *   does not return
    */
    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Don't be cheap");
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner{
        for(uint funderIndex =0; funderIndex<s_funders.length ; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        // 3 ways to withdraw
        // wrap address in payable keyword

        // transfer
        //payable(msg.sender).transfer(address(this).balance);

        // send
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send type Withdrawal failed");

        // call - the recommended way to withdraw
        // bytes is an array so declare with memory
        (bool callSuccess, /*bytes memory dataReturned*/) = payable(msg.sender).call{value:address(this).balance}("");
        require(callSuccess, "Call type Withdrawal failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
            // use a memory variable so we don't have to call gas expensive storage variable
            // mappings can't be in memory
            address[] memory m_funders = s_funders; 
            for(uint funderIndex =0; funderIndex<m_funders.length ; funderIndex++){
            address funder = m_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, /*bytes memory dataReturned*/) = payable(i_owner).call{value:address(this).balance}("");
        require(callSuccess, "Call type Withdrawal failed");
    }

    // View / Pure functions

    function getOwner() public view returns (address) {
        return i_owner;
    }
    function getFunder(uint _index) public view returns(address){
        return s_funders[_index];
    }
    function getNumOfFunders() public view returns (uint){
        return s_funders.length;
    }
    function getAddressToAmountFunded(address _funder) public view returns (uint){
        return s_addressToAmountFunded[_funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint){
        // Goerli ETH/USD address
        // 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData(); // returns 8 decimals
        return uint(price * 1e10); // convert to Wei

    }

    function getDecimals(AggregatorV3Interface priceFeed) internal view returns (uint8){
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return priceFeed.decimals(); //gives us 8 decimals
    }

    function getConversionRate(uint256 _ethAmount,AggregatorV3Interface priceFeed) internal view returns(uint256){
        // Only accepts whole numbers
        // https://eth-converter.com/
        // will have to calculate to wei from here
 
        uint256 ethPrice = getPrice(priceFeed); //ETH in USD * 10^18
        uint256 ethAmountinUSD = (ethPrice*_ethAmount) /1e18; // convert back from Wei to readable USD
        return ethAmountinUSD;
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