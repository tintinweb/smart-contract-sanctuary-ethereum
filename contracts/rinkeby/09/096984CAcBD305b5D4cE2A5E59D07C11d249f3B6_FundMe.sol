//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "PriceConvertor.sol";

error NotOwner();

contract FundMe {
    using PriceConvertor for uint256;

    uint256 public constant MIN_USD = 50 * 1e18;

    address public immutable owner;
    address[] public funders;
    mapping(address => uint256) public addresstoamt;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        require(
            msg.value.getconversionrate(priceFeed) >= MIN_USD,
            "Not Enough ETH"
        );
        funders.push(msg.sender);
        addresstoamt[msg.sender] = msg.value;
    }

    function withdraw() public onlyowner {
        for (uint256 i = 0; i < funders.length; i++)
            addresstoamt[funders[i]] = 0;

        funders = new address[](0);

        (bool callsuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callsuccess, "Call Failed");
    }

    function getaddresstoamt(address _sender) public view returns (uint256) {
        return (addresstoamt[_sender]);
    }

    modifier onlyowner() {
        //require(owner == msg.sender, "ERROR : SENDER NOT OWNER!!!!!");
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _; //Whole Functions code
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

library PriceConvertor {
    function getprice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getconversionrate(uint256 ethamt, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethprice = getprice(priceFeed);
        uint256 ethtot = (ethprice * ethamt) / 1e18;
        return ethtot;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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