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
pragma solidity ^0.8.0;
import "./priceConvertor.sol";

contract FundMe {
    error unauthorized();
    //constant and immutable cost less gas!
    using conversions for uint256;

    address[] public addressesOfFunder;
    mapping(address => uint256) public weiFromAddress;

    uint256 constant minimumUSD = 3 * 1e18;
    string errorMsg = "ERROR!";
    address public owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert unauthorized();
        }
        _;
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= minimumUSD, errorMsg);
        addressesOfFunder.push(msg.sender);
        weiFromAddress[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < addressesOfFunder.length; i++) {
            address funder = addressesOfFunder[i];
            weiFromAddress[funder] = 0;
        }

        addressesOfFunder = new address[](0);
        // //transfer
        // payable(msg.sender).transfer(address(this).balance);
        // //send
        // bool sended = payable(msg.sender).send(address(this).balance);
        // require(sended, "ERROR!");

        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");

        require(callSuccess, "ERROR!");
    }

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

library conversions {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        //ETH in terms of USB
        //3000.00000000
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 eth,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 rate = getPrice(priceFeed);
        uint256 USD = (rate * eth) / 1e18;
        return USD;
    }
}