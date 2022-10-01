//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8; 

//To Do 
//Get funds from users 
//withdraw funds 
//set a minimum funding value in USD


import "./PriceConverter.sol";
contract FundMe{
    
    address public immutable owner; 

    AggregatorV3Interface public priceFeed; 
    // we gonna pass priceFeed to the constructor

    constructor(address priceFeedAddress) { 
        owner = msg.sender; 
        priceFeed = AggregatorV3Interface(priceFeedAddress); 
    }
    using PriceConverter for uint256; 
    
    uint256 public constant MINIMUM_USD = 50 * 1e18; 
    //address is a data type
    address[] public funders; 
    mapping(address => uint256) public addressToAmount; 
    //payable means you need to also send some value 
    function fund() public payable{
        //want to be able to set a minimum fund amount 
        // 1. How do we send Eth to this contract 
        //msg.value is in WEI that is 10^18 wei == 1 eth
        require(msg.value.getConversionRate(priceFeed) > MINIMUM_USD, "Didn't send enough!");
        funders.push(msg.sender);
        addressToAmount[msg.sender] = MINIMUM_USD; 
        //1e18 is 10^18 in wei that is 1 ethereum 
        //if the value didn't met the condition then it will revert and undo any changes 
        //that happened in contract 

        // function getConversionRate() public {}

    }
    function withdraw() public onlyOwner {
        //we will reset the mapping
        for(uint256 funderIndex = 0; funderIndex<funders.length ; funderIndex++){
            address funder = funders[funderIndex]; 
            addressToAmount[funder] = 0;
        }

        //Now we will reset the Array 
        funders = new address[](0); 

        //withdraw fund from contract 
        //transfer directly revert back 
        //send return bool
        //call return bool and value
        
        //we typecasted msg.sender from address to payable address so that we can transfer the fund
        // payable(msg.sender).transfer(address(this).balance); 

        // //send function 
        // //(this).balance returns the balance of current contract that is FundMe contract
        // bool sendSuccess = payable(msg.sender).send(address(this).balance); 
        // require(sendSuccess,"Transfer Failed");

        //call function
        (bool sendSuccess, /*bytes memory dataReturned*/) = payable(msg.sender).call{value: address(this).balance}(""); 
        require(sendSuccess,"Transfer Failed");
    }

    receive() external payable{
        fund();  
    }

    //if the calldata not find the appropriate function we access the fall back function 
    fallback() external payable{
        fund(); 
    }

    modifier onlyOwner{ 
        require(owner == msg.sender, "fuck off , baap ko bulake lao"); 
        _; 
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; 

library PriceConverter{

    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        //chains: rinkeby, goerli 
        //we need dynamic priceFeed address for different networks 
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (
            /*uint80 roundID*/,
            int256 price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint256(price) * 1e10;
    }

    function getConversionRate(uint256 ethAmount,AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 latestPrice = getPrice(priceFeed); 
        return (ethAmount*latestPrice)/ 1e18; 
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