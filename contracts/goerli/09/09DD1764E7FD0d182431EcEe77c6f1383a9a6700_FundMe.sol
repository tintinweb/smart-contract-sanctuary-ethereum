//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "AggregatorV3Interface.sol";
contract FundMe{
    mapping(address=>uint) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    constructor(){
        owner = msg.sender;
    }
    function fund() public payable{
        uint minimumUSD = 1 * (10**8);
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
        //addressToAmountFunded[msg.sender] = addressToAmountFunded[msg.sender] + msg.value;   
    }
    function getVersion() public view returns(uint){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return priceFeed.version();
    }
    function getPrice() public view returns(uint){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,int answer,,,) = priceFeed.latestRoundData();
        return uint(answer);
    }
    function getConversionRate(uint ethAmount) public view returns (uint){
        uint ethPrice = getPrice();
        uint ethAmountInUSD = (ethPrice * ethAmount)/10**8;
        return ethAmountInUSD;
    }
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    function withdraw() payable public onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
        for(uint funderIndex=0; funderIndex<funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
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