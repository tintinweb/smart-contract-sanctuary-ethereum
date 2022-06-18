// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

    error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) private addressToAmountFunded;
    address private immutable owner;

    AggregatorV3Interface private priceFeed;

    modifier onlyOwner () {
        // require(msg.sender == owner, "Sender is not owner!");
        if (msg.sender != owner) revert FundMe__NotOwner();
        _;
    }

    constructor(address _priceFeed) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) > MINIMUM_USD, "You need to spend more ETH!");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        // transfer
        payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        // (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        // require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory _funders = funders;
        for (uint256 i = 0; i < _funders.length; i++) {
            address _funder = _funders[i];
            addressToAmountFunded[_funder] = 0;
        }
        funders = new address[](0);

        payable(msg.sender).transfer(address(this).balance);
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeed;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getFunder(uint _idx) public view returns (address) {
        return funders[_idx];
    }

    function getAddressToAmountFunded(address _address) public view returns (uint) {
        return addressToAmountFunded[_address];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface _priceFeed) internal view returns (uint256) {
//        // Rinkeby ETH / USD Address
//        // https://docs.chain.link/docs/ethereum-addresses/
//        AggregatorV3Interface priceFeed = AggregatorV3Interface(
//            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
//        );
        (, int256 answer, , , ) = _priceFeed.latestRoundData();
        // price = 176579000000 i.e. 1765 * 1e8
        return uint256(answer);
    }

    function getConversionRate(uint256 _weiAmount, AggregatorV3Interface _priceFeed) internal view returns (uint256) {
        uint256 ethPrice = getPrice(_priceFeed);
        uint256 ethAmountInUsd = (ethPrice * _weiAmount) / 1e8;
        // the actual ETH/USD conversation rate, multiplied by 1e18.
        return ethAmountInUsd;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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