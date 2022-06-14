// SPDX-License-Identifier: Apache License 2.0
// --______-----------_____-----------------_----------------------------------_------------------------_----
// -|--____|---------|--__-\---------------|-|--------------------------------|-|----------------------|-|---
// -|-|__-___--_-__--|-|--|-|-_____---_____|-|-___--_-__--_-__-___---___-_-__-|-|_--__------_____--_-__|-|-__
// -|--__/-_-\|-'__|-|-|--|-|/-_-\-\-/-/-_-\-|/-_-\|-'_-\|-'_-`-_-\-/-_-\-'_-\|-__|-\-\-/\-/-/-_-\|-'__|-|/-/
// -|-|-|-(_)-|-|----|-|__|-|--__/\-V-/--__/-|-(_)-|-|_)-|-|-|-|-|-|--__/-|-|-|-|_---\-V--V-/-(_)-|-|--|---<-
// -|_|__\___/|_|----|_____/-\___|-\_/-\___|_|\___/|-.__/|_|-|_|-|_|\___|_|-|_|\__|---\_/\_/-\___/|_|--|_|\_\
// --/-____|----------|-|-----------|-|------------|-|-------------------------------------------------------
// -|-|-----___--_-__-|-|_-__-_--___|-|_---_-__-___|_|___----------------------------------------------------
// -|-|----/-_-\|-'_-\|-__/-_`-|/-__|-__|-|-'_-`-_-\-/-_-\---------------------------------------------------
// -|-|___|-(_)-|-|-|-|-||-(_|-|-(__|-|_--|-|-|-|-|-|--__/---------------------------------------------------
// --\_____\___/|_|-|_|\__\__,_|\___|\__|-|_|-|_|-|_|\___|---------------------- https://duncanpeach.com/ ---
// ----------------------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------------------

pragma solidity ^0.8.14;

import "AggregatorV3Interface.sol";

contract TipsDemo {
    AggregatorV3Interface internal USDETHFeed;
    uint256 internal minimalTipPriceinWei;
    address payable public TipsWallet;

    mapping(address => uint256) public Tips;
    address[] public Tippers;

    constructor(address _USDETHFeed) {
        //100 0000000000 000000000000000000
        minimalTipPriceinWei = 50;
        TipsWallet = payable(msg.sender);
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

    function minimalTipPrice() public view returns (uint256) {
        return uint256(minimalTipPriceinWei);
    }

    function getEthPrice() public view returns (uint256) {
        (, int256 EthPrice, , , ) = USDETHFeed.latestRoundData();
        return uint256(EthPrice);
    }

    function getPrice() public view returns (uint256) {
        uint256 EthPrice = getEthPrice();
        return (minimalTipPriceinWei * (10 * 10)) / EthPrice;
    }

    modifier onlyOwner() {
        require(msg.sender == TipsWallet);
        _;
    }

    function withdraw() public payable onlyOwner {
        TipsWallet.transfer(address(this).balance);
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