// SPDX-License-Identifier: MIT
// Get fund from user
//With draw funds
// Set minimum fuding value in USD

pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";
// constant 
//immuable
// 859,757
error FundMe__NotOwner();

// interfaces, libraries, contracts

/** @title A contract for crowd  funding
* @author Elmond
* @notice this contract is to demo a sample funding contract
* @dev This implements price feed as a our library
 */
contract FundMe{
    // Type declarations 
    using PriceConverter for uint256;

    // State variables
    event Funded(address indexed from, uint256 amount);
    // constant doesn't use the storage slot, but it is stored in the byte code of the contract and decrease the gas price
    uint256 public constant Minimum_USD = 50 * 1e18; 
    
    address[] public funders;
    // it is stored in the byte code of the contract
    address public immutable i_owner;

    mapping(address =>uint256) public addressToAmountFunded;

    AggregatorV3Interface public priceFeed;

    modifier onlyOwner{
        if(msg.sender != i_owner) {revert FundMe__NotOwner();}// other address can't call this sontract 
        _;
    }

    constructor(address priceFeedAddress) {// automatically send the the priceFeed that the coin address is running on
        i_owner = msg.sender; // 
        priceFeed = AggregatorV3Interface(priceFeedAddress);

    }
   
    receive() external payable{
        fund();
    }
    fallback() external payable{
        fund();
    }
     
    function fund() public payable{  // payable make fund function red, but normal is orange.
        // we want to be able to set a minimum amount in USD
        // How do we send to this contract?
        //msg.value is user balance
        require(msg.value.getConversionRate(priceFeed) >= Minimum_USD, "Didn't send enough"); // 1e18 == 1*10**18== 1000000000000000000
        // 18 decimals
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender]+=msg.value;
        emit Funded(msg.sender,msg.value);
        // a ton of computationn here
        //What is reverting

        // oracle is a tool that helps to interact with off-chain information. In this case, USD.
    }

    function withdraw() public onlyOwner { // onlyOwner is modifier below
        // reset the array funds
        for(uint256 funderIndex=0; funderIndex <funders.length; funderIndex++){
            address funder= funders[funderIndex];
            addressToAmountFunded[funder] =0; // msg.value
        }
        //reset the array
        funders = new address[](0);
        // actually withdraw the funds

        //transfer (2300 gas, throws error)
        //payable(msg.sender)=payable address
        // payable(msg.sender).transfer(address(this).balance);// (this) means whole contract
        // // send (2300 gas, return bool)
        // bool sendSuccess= payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed"); // if above sentence fail it will display "send failed"
        // // call (forward all gas or set gas, returns bool)
        (bool callSuccess, )= payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
        revert();

    }
   

    // What happen if someone send this contract ETh without calling the fund function 
    // create to help people who accidentally called wrong function or send this contract money without fund function.
    
    
    //fallback();
}

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
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        // ABI 
        // Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        (,int256 price,,,) = priceFeed.latestRoundData(); // we want just price
        // ETH in terms of USD
        // now the price has 8 decimal, so we have to divind more by 10
        return uint256(price * 1e10); // 1*10
    
    }
    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethPrice= getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) /1e18; // now we have 36 decimal place because 18 places from ethPrice and 18 places for ethAmount
        return ethAmountInUsd;
    }
    //function withdraw(){}
}
// asking questions on github
// markdown 
// ''' make it clear