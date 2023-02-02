/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: FundMe.sol



pragma solidity >=0.6.6 <0.9.0;

contract FundMe{

    mapping(address => uint256) public addressToAmmountFunded;
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

    function fund() public payable  returns(uint256) {
        //min $50
        uint256 minUSD = 50;
        //require((msg.value)*(getLatestPrice()/10**18)>=minUSD, "Need more eth");

        //1000000000*

        addressToAmmountFunded[msg.sender] += msg.value;
        return(msg.value);
    }

    //Eth to USD conversion
    function getVersion() public view returns (uint256){
        
        return priceFeed.version();
    }

    function getLatestPrice() public view returns(uint256){
        
        (,int price,,,) = priceFeed.latestRoundData(); 

        return uint256(price/10**8);
    }
}