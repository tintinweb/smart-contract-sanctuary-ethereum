//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// In addition to using breakpoints and javascript tests you can also use console.log directly
// inside your solidity contract to check value (this is part of the hardhat framework)
// import "hardhat/console.sol";
// console.log("Sender balance is %s tokens", balance[msg.sender]);

error FundMe__NotOwner(); // custom error saves gas over standard require() - new in Solidity

// With the following NatSpec we can actually generate a documentation automatically using solc
// solc --userdoc --devdoc FundMe.sol
/** @title A contract for crowd funding
 *  @author Patrick Collins
 *  @notice This contract is to demo a sample funding contract
 *  @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConverter for uint256;
    
    // For variables that are only going to be set once and not changed thereafter we can use the 
    // constant keyword. The real benefit is more efficient use of storage and saving gas!!
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    // Similar to the constant keyword we can use immutable to enjoy the same benefits of efficient
    // storage usage and gas savings. "immutable" is used when we cannot assign a value to the 
    // variable in the same line that we declare it but we still want it to remain constant after assignment.
    address private immutable i_owner;
    AggregatorV3Interface public s_priceFeed;

    // If a modifier is added to a function declaration it will run the code within this modifier
    // first, before running the rest of the code in the actual function that is called
    modifier onlyOwner {
        // require(msg.sender == i_owner, "Sener is not owner!");
        if(msg.sender != i_owner) { revert FundMe__NotOwner(); } // saves gas over require
        _; // implies "do the rest of the code"
        // If "_;" was before the require it would run the called function first, then check the require
    }

    // called in same transaction as the deployment of this contract
    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    // What happens if someone sends this contract ETH without calling the fund function explicitly?
    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }
    
    // If you want a function to be able to receive funds it must be 'payable'
    /**
     *  @notice This function funds this contract
     *  @dev This implements price feeds as our library
     */
    function fund() public payable {
        // Every transaction has attributes / information, such as the 'value' sent with the transaction (msg)
        // msg.value has the unit wei, i.e. 1 ETH = 1e18 wei
        // If the require fails, any prior action (e.g. assignements) is reverted and the remaining
        // gas is sent back to the msg.sender. E.g. if fund() required a lot of gas because of heavy
        // computation after this require, this unspent gas would be sent back to the msg.sender.  
        // To clean up the code a bit we create a library 'PriceConverter' where we build custom functions
        // for uint256. See 'using PriceConverter for uint256'. The object calling the function is passed to 
        // the respective function as the first parameter, i.e. msg.value.getConversionRate is the same as 
        // getConversionRate(msg.value)
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Didn't send enough!");  
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Sener is not owner!");

        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0); // 0 indicates new EMPTY array

        // 3 different ways to actually withdraw funds

        // TRANSFER
        // Check solidity-by-example.org to find that transfer errors if gas is above 2300 for the transfer  
        // We must cast msg.sender to a PAYABLE address. msg.sender is just an address
        // payable(msg.sender).transfer(address(this).balance);

        // SEND
        // Send won't error like transfer, it will return a boolean telling if successful or not
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // CALL (currently recommended)
        // Call allows us to call any function (on the blockchain?) which we would specify in the brackets.
        // However, we don't want to call any explicity function so instead we'll just treat call as a 
        // regular transaction and as we learnt, regular transacitons have a VALUE attribute that we can
        // use to send the funds
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        // we read the s_funders array to memory once and then access it from there!
        address[] memory funders = s_funders;
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            // mappings cannot be stored in memory, unfortunately!
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    // The prepended "s_" can be ugly to work with for others who use our contract. 
    // We therefore create getter functions to provide a nice API that others can use instead
    // when reading our storage variables.
    function getOwner() public view returns(address) {
        return i_owner;
    }
    
    function getFunder(uint256 index) public view returns(address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder) public view returns(uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns(AggregatorV3Interface) {
        return s_priceFeed;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// imports from github (~ npm)
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        // As we rely on an external contract to get the price we'll need the ABI and its address
        // ABI
        // Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // If the contract at this address fits this ABI (interface) then it will work!
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 price,,,) = priceFeed.latestRoundData();
        // returns ETH price in terms of USD
        // E.g., 300000000000. Solidity doesn't work well with explicit decimals (but we can query the 
        // aggregator interface for decimals() to find out it uses 8 decimals, i.e. 3000.00000000
        // As we will use this function in fund() and we're working with uint256 wtih 18 decimals we'll 
        // we'll want to convert it to conform with this numerical format
        return uint256(price * 1e10); 
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // We must remember to 'divide by 1e18' because the multiplication adds another 1e18 decimals to it.
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

}