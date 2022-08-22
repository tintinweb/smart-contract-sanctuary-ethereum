// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";
// This file will allow for the following to be possible:
    // 1. Get funds from users
    // 2. Withdraw funds
    // 3. Set a minimum funding value in USD

// Gas Optimization
    // GAS : 995131 (no constatn)
    // GAS : 972630 (constant) 
    // GAS : 945556 (immutable) 

error NotOwner();
contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    address public immutable i_owner;
    mapping (address => uint256) public addressToAmountFunded;
    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }
    
    // will be used to send funds
    function fund() public payable{ 
        // Want to be able to set a minimum fund amount in US -- use require to achieve this
            // 1. How do we send ETH to this contract ? use payable
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,"Didn't Send Enough");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }
    // the owner of the contract can then withdraw the funds sent by the different funders
    function withdraw() public onlyOwner{
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address  funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // reset the array 
        funders = new address[](0);
        // type(msg.sender) = address
        // type(payable(msg.sender)) = payable address -- only can send eth using payable addresses
        // withdraw the funds 
            // methods to transfer
                // transfer
                    //    payable(msg.sender).transfer(address(this).balance)
                // send
                    //    bool sendSuccess = payable(msg.sender).send(addres(this).balance)
                    //    require(sendSuccess,"Failed to send ether")
                // call
        (bool callSuccess,) = payable(msg.sender).call{value:address(this).balance}("");
        require(callSuccess,"Call failed");
    }

    modifier onlyOwner {
        // require(msg.sender == i_owner,"Fraud detected !!! \n you are not the owner of this contract \n you can not withdraw");
       if ( msg.sender != i_owner) revert NotOwner();
        _;  // perform rest of the code
    }
    
    // what happens if someone sends this contract ETH w/o calling the fund function 
    receive() external payable {
        fund();
    }
    fallback() external payable {
        fund();
    }


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
pragma solidity 0.8.9;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// Libraries can not have/do any of the following
    // 1. state variable
    // 2. can't send ether
    // 3. all functions will be internal
library PriceConverter {
  // convert msg.price native currency to equivalent USD value
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        // Whenever interacting with a contract you will always need: 
            // 1. ABI:  is a minimalistic ABI AggregatorV3Interface that allows for interaction with contracts outside of the
            // 2. Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        (, int256 price,,,) = priceFeed.latestRoundData();
        // price of ETH in USD
        return uint256( price * 1e10);
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18; 
        return ethAmountInUSD;
    }
}