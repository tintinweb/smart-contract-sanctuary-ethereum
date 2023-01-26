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

pragma solidity ^0.8.8;
import "./PriceConverter.sol";

contract FundMe{
    using PriceConverter for uint;
    // 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
    uint public constant minimumUSD = 50 * 10 ** 18;
    address[] funders;
    mapping(address=>uint) public addressToAmount;
    address public owner;

    AggregatorV3Interface public priceFeed;
    constructor(address priceFeedAddress){
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable{
        require(msg.value.getConversionRate(priceFeed)>= minimumUSD,"Eth not enough to send"); // 1e18 = 1 * 10 ** 18 = 1000000000000000000 wei
        funders.push(msg.sender);
        addressToAmount[msg.sender]=msg.value;
    }
    function withdraw() public onlyOwner{
        
        for(uint funderIndex=0;funderIndex > funders.length; funderIndex++){
            address funder=funders[funderIndex];
            addressToAmount[funder]=0;
        }
        funders = new address[](0);
        (bool callSuccess,) = payable(msg.sender).call{value:address(this).balance}("");
        require(callSuccess,'Call failed');
    }
    modifier onlyOwner{
        require(owner == msg.sender,"Sender is not owner");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // gorerli 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeed);
        (/* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/) = priceFeed.latestRoundData();
        return uint(price * 1e10);
    }
    // function getVersion() internal view returns(uint) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    //     return priceFeed.version();
    // }
    function getConversionRate(uint ethAmount,AggregatorV3Interface priceFeed) internal view returns(uint) {
        uint ethPrice = getPrice(priceFeed);
        uint ethAmountUsd = (ethPrice * ethAmount) / 1e18 ;
        return ethAmountUsd;
    }
}