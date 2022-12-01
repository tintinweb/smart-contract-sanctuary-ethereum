// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol"; //we can also paste the code here if we want

//takes from chainlink npm package

//Interface compiles down to ABI. Tells solidity and other programming languages how 
//to interact with another contract


contract FundMe {
    address owner;
    address[] public funders;

    // keep track of who sending money
    mapping(address => uint256) public addressToAmountFunded;
    
    constructor() {
        owner = msg.sender; //defining Smart contract creator as owner
    }
    //sending money
    // payable means can get money
    function fund() public payable {
        //$50 minimum amount
        uint256 minimumUSD = 0.5 * 10 ** 18;

        if(msg.value < minimumUSD){
            require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");
        }
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        // what the ETH -> USD conversion rate is
    }

    modifier onlyOwner { // says before you run function, check this first. Then continue with the code after the underscore
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable public {
        //whoever called withdraw, transfer it all out
        // require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 funderIndex=0; funderIndex<funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); //reset GLOBAL ARRAY VARIABLE
    }

    function getVersion() public view returns (uint256){
        //finding pricefeed address at Oracle pricefeed destination
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,
        int256 answer,
        ,
        ,
        )
        = priceFeed.latestRoundData();
        // answer has 8 decimals (function decimals() external view returns (uint8);
      return uint256(answer * 10000000000); //price in WEI (18 decimal)
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd; //price in USD 
    }

    //challenge of ETH: Overflow
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