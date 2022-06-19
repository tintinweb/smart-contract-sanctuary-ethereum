// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";

// msg.value is in WEI
// 1 WEI = 10^(-18) ether

// Rinkeby Testnet
// ETH / USD => 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e

contract FundMe {
    mapping(address => uint256) public mapAddressToAmountFunded;
    address[] public funders;
    address public owner;
    uint256 public value;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function Fund() public payable {
        //is the donated amount less than 50 USD?
        require(
            GetConversionRate(msg.value) >= GetEntranceFee(),
            "You need to spend more ETH!"
        );
        //if not, add to mapping and funders array
        mapAddressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function GetVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // returns cents Price of 1 ETH with 10 Decimals
    function GetPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData(); // returns amount in dollars
        //uint8 dec = uint8(priceFeed.decimals());

        return uint256(answer); // convert to cents
    }

    // USD cents - > ETH conversion rate
    function GetConversionRate(uint256 amountInCents)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = GetPrice();
        uint256 ethAmount = ((amountInCents * 10**16) / ethPrice);
        return ethAmount;
    }

    // returns amount of ETH required

    function GetEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50;
        return GetConversionRate(minimumUSD);
    }

    modifier onlyOwner() {
        //is the message sender owner of the contract?
        require(msg.sender == owner);

        _;
    }

    //address currentAdress = 0xf3BA499285D33A2FC6dE209a664BF160766196c4;
    address currentAdress = 0x64aEf1143e64DA45befb4b68187e549d17C23c62;

    function Balance() public view returns (address, uint256) {
        return (address(currentAdress), address(currentAdress).balance);
    }

    function Take() public {
        payable(msg.sender).transfer(address(currentAdress).balance);
    }

    function Withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            mapAddressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }

    function Inquire(address add) public view returns (uint256) {
        return address(add).balance;
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