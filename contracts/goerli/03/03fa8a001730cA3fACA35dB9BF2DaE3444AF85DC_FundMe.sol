// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./PriceConverter.sol";

//Get funds from users
//withdraw funds
//set a min funding value in usd

//reverting
//undo any action before, and send remaining gas back

error NotOwner();
error CallFailed(); 

contract FundMe {
    //constant amd immutable keywoords -> decrease the gas price.
    using PriceConverter for uint256;

    uint256 public constant MIN_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public immutable priceFeed;

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        //want to be able to set a min fund amount in usd
        require(msg.value.getConversionRate(priceFeed) >= MIN_USD, "Didn't send enough ether"); // 1e18 = 1 * 10 ** 18 == 1000000000000000000
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex = funderIndex + 1) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        //reset the array
        funders = new address[](0);
        
        //withdraw the funds
        //transfer, send, call

        //msg.sender = address, payable = payable address;
        //payable(msg.sender).transfer(address(this).balance);

       //bool sendSuccess =  payable(msg.sender).send(address(this).balance);
       //require(sendSuccess, "Send failed");

       ( bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
       //require(callSuccess, "Call failed");
       if(!callSuccess) { revert CallFailed(); }
    }

    modifier onlyOwner {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if(msg.sender == i_owner) { revert NotOwner(); }
        _;
    }

    //what happens if someone sends eth without using fund function.
    //receive, fallback

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //to convert to USD
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        //ABI
        //Address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        (, int price,,,) = priceFeed.latestRoundData();
        return uint256(price * 1e10); //1 **10 = 10000000000
    }

    function getVersion(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        return priceFeed.version();
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
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