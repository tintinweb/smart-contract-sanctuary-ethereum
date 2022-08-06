//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "./PriceConvertor.sol";

contract FundMe{

    address immutable owner;
    address public priceFeed;

    uint256 constant minimumUSD = 50 * 10**18;

    address[] public funders;
    mapping(address => uint) public balanceOf;

    using PriceConvertor for uint256;

    modifier onlyOwner {
        require(msg.sender == owner,"Not the owner!");
        _;
    }

    constructor(address pf) {
        owner = msg.sender;
        priceFeed = pf;
    }

    function fund() public payable {
        require( (msg.value).convertToUSD(priceFeed) > minimumUSD, "Minimum amount to enter : $5.");
        if( balanceOf[msg.sender] == 0 )
            funders.push(msg.sender);
        
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner{
        payable(owner).transfer(address(this).balance);
        for(uint index = 0; index<funders.length ; index++)
            balanceOf[funders[index]] = 0;
        delete funders;
    }
}

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConvertor{
    function getConversionRate(address pf) internal view returns(int) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(pf);
        (,int price,,,) = priceFeed.latestRoundData();
        return price * 10**10;
    }

    function convertToUSD(uint256 ethSentInWei ,address pf) internal view returns(uint256){
        uint price = uint256(getConversionRate(pf));
        return (price * ethSentInWei)/10 ** 18;
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