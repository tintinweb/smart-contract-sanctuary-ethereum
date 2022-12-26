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

//Get funds from users
//Withdraw funds
//Set a minimum funding value in USD

//SPDX-License-Identifier: MIT

//pragma
pragma solidity ^0.8.0;
//imports
import "./PriceConverter.sol";

/** @title A contract for crowd funding
 *  @author Haseeb Malik
 *  @notice This contract is to demo a simple funding contract
 *  @dev This implements price feeds as our library
 */
///

//custom error instead of storing a string in revert,because string will cost way more gas.

//Error Codes
error FundMe_NotOwner();

contract FundMe {
    //Type Declarations

    //this is library
    using PriceConverter for uint256;
    //this is equal to 50 dollers.
    //constants and immutable are keyword we use for the variables which are dont change in the app
    //we can also use these two variables for the variable in constructor.
    //basically these are used to optimize gas for contract execution.
    //state variables

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    //21,415 gas -execution cost of calling MINIMUM_USD function with constant
    //23,515 gas -execution cost of calling MINIMUM_USD function without constant
    //21,415*141000000000 =$9.058545
    //23,515*141000000000 =$9.946845
    //without const the calling of MINIMUM_USD function will cost almost 1doller more.

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;
    //21,508 gas -execution cost of calling i_owner function with immutable
    //23,644 gas -execution cost of calling i_owner function without immutable
    //events

    //modifiers
    modifier onlyOwner() {
        // require(msg.sender==i_owner,"Sender is not owner.");
        //it will cost less gas then require
        if (msg.sender != i_owner) {
            revert FundMe_NotOwner();
        }
        _;
    }

    ////Please write things in this order from here

    //constructor
    //receive
    //fallback
    //external
    //public
    //internal
    //private
    //view / pure

    //the reason why constant and immutable will cost less gas because instead of storing them in storage slot, we will save them directaly store them into byte code of the contract.
    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //what happens if someone sends this contract eth without calling the fund function
    //if some one call a function of a contract which is not present ,then receive function trigger automatically

    //receive
    //fallback

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This funtion funds this contract
     * @dev Write any thing here for devs
     */

    function fund() public payable {
        //Want to be able to set a minimum fund amount in USD.
        //How do we send eath to this account
        // require(msg.value>1e18,"Didn't send enough");

        // require(getConversionRate(msg.value)>=MINIMUM_USD,"Didn't send enough");
        //or with library
        //here msg.value is automatically send as first parameter in getConversionRate function.
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough"
        );

        //18 decimals
        //What is reverting?
        //Undo any action before, and send remaining gas back.

        //msg.sender is a global function which is the address of the user which calls this function
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        //but if we have many functions which need to be a sender, then we need modifiers.
        //   require(msg.sender==i_owner,"Sender is not owner.");
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //reset the funders array with zero element
        s_funders = new address[](0);
        //Now withdraw the funds

        //There are three ways to transfer funds from contract
        //1. transfer
        //2. send
        //3. call

        //msg.sender= address
        //payable(msg.sender)= payable address
        //here "this" keyword is the balance of this whole contract.
        //transfer will revert back transaction if it fails
        //  payable(msg.sender).transfer(address(this).balance);
        //           // send will not revert transaction but returns a bool
        //  bool sendSuccess =payable(msg.sender).send(address(this).balance);
        //      //Now we have to revert transaction ourself
        //      require(sendSuccess, "Send failed.");

        //call is the best method to send and receive tokens
        //because "dataReturn" is an array so we give it memory
        (bool callSuccess, bytes memory dataReturn) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call Failed.");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        //mapping cant be in memory
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, bytes memory dataReturn) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call Failed.");
    }


//  view /pure
    function getOwner() public view returns (address){
        return i_owner;
        }
    

    function getFunder(uint256 index) public view returns (address){
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) public view returns (uint256){
      return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns(AggregatorV3Interface){
        return s_priceFeed;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


// a library can also have state variables and can send ethers
// All the functions in a library are internal.
library PriceConverter {


    function getPrice(AggregatorV3Interface priceFeed) internal returns(uint256){
        //ABI
        //Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    //  AggregatorV3Interface priceFeed=AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    
      (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        //ETH in term of USD.
        //3000.00000000
        //here uint256 is type casting from int to uint256 because message.value is uint.
        //remember that not all type are castable, some types including int256 and uint256 are convertable into eachother. 
        //we multipy the price with 1e10 because it already have 8 decimals and we take it to 18 decimals because 1eth=1e18
        return uint256(price * 1e10);
    }
    function getConversionRate(uint256 ethAmount,AggregatorV3Interface priceFeed) internal returns(uint256) {
        uint256 ethPrice=getPrice(priceFeed);
        uint256 ethAmountInUsd=(ethPrice*ethAmount)/1e18;
        return ethAmountInUsd;
    }
   


}