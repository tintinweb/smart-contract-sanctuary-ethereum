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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error notOwner();

contract fundMe {
    using priceConverter for uint256;

    uint256 public constant minUsd = 5 * 1e18;

    address[] public funderAddress;
    address public immutable contractOwner;

    mapping(address => uint256) public addressToAmount;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        contractOwner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        uint256 amt = msg.value.getConversionRate(priceFeed);
        require(amt > minUsd, "Didn't send enough!!");
        funderAddress.push(msg.sender);
        addressToAmount[msg.sender] = msg.value;
    }

    function withDraw() public onlyOwner {
        for (uint i = 0; i < funderAddress.length; i++) {
            address funder = funderAddress[i];
            addressToAmount[funder] = 0;
        }

        funderAddress = new address[](0);

        //withdarwing funds: transfer,send,call
        //payable(msg.sender).transfer(address(this).balance);

        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "send failed");

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    modifier onlyOwner() {
        //require(msg.sender == contractOwner, "Not the Owner");
        if (msg.sender != contractOwner) {
            revert notOwner();
        }
        _;
    }

    //when ppl send eth directly to the contract address instead of using fund function
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library priceConverter {
    function getVersion() internal view returns (uint256) {
        //0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419
        return
            AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e)
                .version();
    }

    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethPriceInUsd = (ethPrice * ethAmount) / 1e18;
        return ethPriceInUsd;
    }
}