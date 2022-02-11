// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Get the latest ETH/USD price from chainlink price feed
import "AggregatorV3Interface.sol";

// contratto che deve poter ricevere fondi dall'esterno.
// ogni donazione deve essere maggiore di 50$ (inizialmente 1 ETH)
// deve essere prelevato l'intero ammontare di donazioni
// l'owner puÃ² fornire un indirizzo e in quel caso Ã¨ possibile restituire i soldi versati a quell'indirizzo

contract FundMe {
    mapping(address => uint256) addressAmountMap;
    address[] funders;
    address owner; // chi ha deployato il contratto
    AggregatorV3Interface priceFeed;

    constructor() {
        // dalla 0.8 non si mette il public
        // require(msg.value>=1, "Provide more ETH");
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        owner = msg.sender;
    }

    function fund() public payable {
        require(msg.value >= 1000000000000000000, "Provide more ETH");
        // l'amount lo sistema lui in automatico
        funders.push(msg.sender);
        addressAmountMap[msg.sender] = msg.value;
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    function getTotalBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getFunderAddress(uint256 index) public view returns (address) {
        return funders[index];
    }

    function getFunderAmount(address a) public view returns (uint256) {
        return addressAmountMap[a];
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can withdraw");
        _;
    }

    // solo l'owner puÃ² prelevare i fondi
    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressAmountMap[funder] = 0;
        }

        funders = new address[](0);
    }

    // restituisce i soldi agli investitori
    function refundFunders() public payable onlyOwner {
        for (uint256 i; i < funders.length; i++) {
            address funder = funders[i];
            payable(funder).transfer(addressAmountMap[funder]);
            addressAmountMap[funder] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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