// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.14;

import "AggregatorV3Interface.sol";

contract CV {
    AggregatorV3Interface internal USDETHFeed;
    uint256 internal minimalTipPriceinWei;
    address payable public DuncanPeachWallet;

    mapping(address => uint256) public Tips;
    address[] public Tippers;

    constructor(address _USDETHFeed) {
        minimalTipPriceinWei = 50 * (10**18);
        DuncanPeachWallet = payable(msg.sender);
        USDETHFeed = AggregatorV3Interface(_USDETHFeed);
    }

    function sendTipForNFT() public payable {
        require(
            msg.value >= getPrice(),
            "Not Enough for NFT, $50 minimal eth "
        );
        Tips[msg.sender] += msg.value;
        Tippers.push(msg.sender);
    }

    function getEthPrice() internal view returns (uint256) {
        (, int256 EthPrice, , , ) = USDETHFeed.latestRoundData();
        return uint256(EthPrice);
    }

    function getPrice() public view returns (uint256) {
        uint256 EthPrice = getEthPrice();
        return (minimalTipPriceinWei * (10**18)) / EthPrice;
    }

    modifier onlyDuncanPeach() {
        require(msg.sender == DuncanPeachWallet);
        _;
    }

    function withdraw() public payable onlyDuncanPeach {
        DuncanPeachWallet.transfer(address(this).balance);
        for (
            uint256 TipperIndex = 0;
            TipperIndex < Tippers.length;
            TipperIndex++
        ) {
            address Tipper = Tippers[TipperIndex];
            Tips[Tipper] = 0;
        }
        Tippers = new address[](0);
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