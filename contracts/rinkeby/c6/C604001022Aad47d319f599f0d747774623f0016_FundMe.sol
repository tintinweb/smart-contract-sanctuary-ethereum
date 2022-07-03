//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// 863315 -> gas for deployment
// 843749 -> with constant
// 820182 -> with constant & immutable

error FundMe__NotOwner(); // gas usage efficiency improvement

/** @title System to fund money to a contract
 *  @author AbaSkillzz
 *  @notice Example of funding contract
 */

contract FundMe{
    // TYPE DECLARATIONS
    using PriceConverter for uint256;

    // STATE
    /*
    _s: storage variable -> more gas usage
    const/_i/memory: no storage usage -> less gas usage
    */
    mapping(address => uint256) private s_fundersAmounts;
    address[] private s_funders;
    address private immutable i_owner;
    uint256 public constant MIN_USD = 50 * 10**18; 
    AggregatorV3Interface public s_priceFeed;

    // modifier, to add to funcs to make it usable only by owner
    modifier onlyOwner{
        // require(msg.sender == i_owner, "Only accessible by the owner!");
        if(msg.sender != i_owner){ revert FundMe__NotOwner();} // for gas efficiency
        _; // execute the code of the func
    }

    // FUNCTIONS
    // func called as soon as smart contract is deployed, init of the state
    constructor(address priceFeedAddress){
        i_owner = msg.sender; // owner=who deploys the contract
        s_priceFeed = AggregatorV3Interface(priceFeedAddress); 
    }

    // send eth to the smart contract
    function fund() public payable{
        require(msg.value.getConvertionRate(s_priceFeed) >= MIN_USD, "You need to pay more!");
        s_fundersAmounts[msg.sender] += msg.value;
        s_funders.push(msg.sender); // sender -> address whose calling the func
    }

    // withdraw funds
    function withdraw() public payable onlyOwner{
        // reset to 0 amounts mapping
        for(uint256 funderIndex=0; funderIndex < s_funders.length;  funderIndex++){
            address funder = s_funders[funderIndex];
            s_fundersAmounts[funder] = 0;
        }
        // reset to 0 funders arr
        s_funders = new address[](0); //(0)->new arr with 0 elements
        // withdraw funded ETH (3 ways)
        // -call
        (bool successfulCall, ) = payable(msg.sender).call{value: address(this).balance}(""); //() <- goes the func to call
        require(successfulCall, "Transaction failed, unsuccessful call!");
    }
    
    function cheaperWithdraw() public payable onlyOwner{
        address[] memory funders = s_funders; // save to memory -> cheaper

        for(uint256 funderIndex=0; funderIndex<funders.length; funderIndex++){
            address funder = funders[funderIndex];
            s_fundersAmounts[funder] = 0;
        } 

        s_funders = new address[](0);
        (bool successfulCall, ) = i_owner.call{value: address(this).balance}(""); //() <- goes the func to call
        require(successfulCall, "Transaction failed, unsuccessful call!");
    }

    // getter funcs, to avoid using public->more gas convenient
    function getOwner() public view returns(address){
        return i_owner;
    }

    function getFunder(uint256 index) public view returns(address){
        return s_funders[index];
    }
    
    function getFunderAmount(address funderAddress) public view returns(uint256){
        return s_fundersAmounts[funderAddress];
    }

    function getPriceFeed() public view returns(AggregatorV3Interface){
        return s_priceFeed;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// library: func->internal && no eth
library PriceConverter{
    // get ETH price with chainlink
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        (, int256 price, , , ) = priceFeed.latestRoundData(); 
        // msg.value: 18 decimali | price: 8 decimali  
        return uint256(price * 10000000000); // cosi price ha 18 decimali
    }

    // convert ETH amount in USD(msg.value)
    function getConvertionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256){
        uint256 ethValue = getPrice(priceFeed);
        return (ethValue * ethAmount)/1000000000000000000; // per nn avere 36 0/deecimali
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