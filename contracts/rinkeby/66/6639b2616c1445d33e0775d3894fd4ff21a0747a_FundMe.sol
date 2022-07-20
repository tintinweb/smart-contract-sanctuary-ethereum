// prima uplate
// podigne uplate
// ima minimalnu vrijednost uplate u USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded; //addresa sa uint256(koliko je ko dao kesa)

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        //trebamo staviti minimalnu vrijednost za uplatu u USD
        // 1. Kako saljemo ETH ovom kontraktu?

        //msg.value.getConversionRate(); // ovo je sada isto kao getConversionRate(msg.value)
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Nije poslato dovoljno ETH"
        ); // 1e18 == 1 * 10 ** 18 == 100000000000000000
        // (, revert) vrti korak unz i ostatak gasa vrati korisniku
        funders.push(msg.sender); //msg.sender je adresa onoga ko pozove ovu f-ju
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        /*pocetni indeks, krajniji indeks, korak*/
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex]; //nulti element niza
            addressToAmountFunded[funder] = 0;
        }

        //reseturje niz
        funders = new address[](0);
        /*
        // transfer
            //msg.sender = address
            //payable(msg.sender) = payable address (ovo se koristi ako zelis slatati kes ili tokene)
        payable(msg.sender).transfer(address(this).balance); //this pretstavlja ovaj kontrakt


        // send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess,"Send failed");
*/
        // call ovo je preporuceno
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call faied");
    }

    modifier onlyOwner() {
        //require(msg.sender ==  i_owner, "sender is not owner!");
        if (msg.sender != i_owner) {
            revert NotOwner();
        } //ovo stedi dosta gasa
        _;
    }

    //sta ako neko posalje eth bez da pozove fund f-ju

    // recive()

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    //fallback
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

// OVO JE BIBLIOTEKA

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        /*   //ABI
        //adresu 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        ); */
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // cijena ETH u USD
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}