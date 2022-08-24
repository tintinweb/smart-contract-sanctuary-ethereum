// Get funds from users
// Withdraw funds collected (Withdrawl can be done only by the contract owner)
// Set a minimum funding value in USD

/*
Style Guide - Order of layout
    1)Pragma statements
    2)Import statements
    3)Interfaces
    4)Libraries
    5)Contracts
Order inside each contract,interface or library
    1)Type declarations
    2)State variables
    3)Events
    4)Modifiers
    5)Functions
*/

//SPDX-License-Identifier: MIT

//pragma
pragma solidity ^0.8.7;

//imports
import "./PriceConverter.sol";

//error codes
// custom errors 
error FundMe__NotOwner();

/** @title A contract for crowd funding
  * @author Ganesh Thoutam
  * @notice This contract is to demo a sample funding contract
  * @dev This implements s_priceFeeds as our library
 */
contract FundMe{

    //Type declarations
    using PriceConverter for uint256;

    //State variables
    uint256 public minUSD = 50 * 1e18;

    address[] private s_funders;

    mapping(address => uint256) private s_addressToAmountFunded;
    //payable keyword makes the fund button "red"
    //Just like Wallets holding funds, smart contracts can also hold funds (native blockchain token)
    // By mentioning it as payable, we can access the value attribute 
    
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    //Modifier
    modifier onlyOwner{
        // require(msg.sender == i_owner,"Sender is not owner!!");
        if(msg.sender!=i_owner){
            revert FundMe__NotOwner();
        }
        _; 
    }

    /*
    Functions Order:
        1)Constructor
        2)Receive
        3)Fallback
        4)External
        5)Public
        6)Internal
        7)Private
        8)View/Pure
    */
    constructor(address s_priceFeedAddress){
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    //what happens if someone sends this contract ETH without calling fund function
    //receive()
    /*      Function keyword is not necessary for receive function.
            A contract can have more than 1 receive functions
            This function cannot have any arguments,cannot return anything and must have
            external visibility and payable state mutability.
            It can be virtual, can override and have modifiers.        
    */      
    //fallback()
    /*
        A contract can have only 1 fallback function
        Declaration:
        method-1) fallback() external [payable]
        method-2) fallback(bytes calldata input) external[payable] returns(bytes memory output)
        Without function keyword
        Visibility of external
        It can be virtual, can override and have modifiers.        
    */

    /** 
    * @notice This function funds this contract
    * @dev This implements s_priceFeeds as our library
    */
    function fund() public payable{
        //Want to be able to set a minimum fund amount in USD
        require(msg.value.getConversionRate(s_priceFeed) >= minUSD, "Min value must be 1 ETH"); // 1e18 == 1*(10**18)  -  Money math is done in WEI
        /*
         if require is not met, it will revert with an error message
         Reverting: Undo any action before and send remaining gas back
        */
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner{
        // require(msg.sender == i_owner,"sender is not i_owner!!");
        for(uint256 funderIndex = 0; funderIndex<s_funders.length;funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //reset the s_funders array
        s_funders = new address[](0);
        //actually withdraw the funds - 3methods
        //transfer - simplest one
        //send
        //call

        //msg.sender type is address
        //payable(msg.sender) type is payable address
        // we can only work with payable type
        payable(msg.sender).transfer(address(this).balance);

        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess,"send failed");

        (bool callSuccess,) = payable(msg.sender).call{value:address(this).balance}("");
        require(callSuccess,"call failed");
    }   

    function cheaperWithdraw() public payable onlyOwner{
        address[] memory funders = s_funders;
        //mapping can't be in memory
        for(uint256 funderIndex =0;funderIndex<funders.length;funderIndex++)
        {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        
        (bool success, ) = i_owner.call{value:address(this).balance}("");
        require(success);
    }     

    function getOwner() public view returns(address){
        return i_owner;
    }

    function getFunder(uint256 index) public view returns(address){
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) public view returns(uint256){
        return s_addressToAmountFunded[funder];
    }
    
    function getPriceFeed() public view returns(AggregatorV3Interface){
        return s_priceFeed;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter{
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        //ABI
        //Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // (uint80 roundID, uint price,uint startedAt,uint timeStamp,uint80 answeredInRound)=priceFeed.latestRoundData();
        (, int256 price,,,)=priceFeed.latestRoundData();
        //ETH interms of USD
        //3000.00000000
        return uint256(price*1e10);
    }

/*
    function getVersion() internal view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }
*/
    function getConversionRate(uint256 ethAmount,AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice*ethAmount)/1e18;
        return ethAmountInUSD;
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