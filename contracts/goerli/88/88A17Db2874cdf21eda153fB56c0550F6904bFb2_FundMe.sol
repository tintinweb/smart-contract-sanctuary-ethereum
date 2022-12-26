// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// Importar AggregatorV3Interface
import "AggregatorV3Interface.sol";

contract FundMe {
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    mapping(address => uint256) public amountfunded; // quantidade doada.
    address public owner;

    modifier isADM() {
        require(msg.sender == owner);
        _;
    }

    function fund() public payable {
        uint256 minUSD = 50 * 10**18;
        require(getConversionRate(msg.value) >= minUSD, "Not enough ETH!!!");
        amountfunded[msg.sender] += msg.value; // msg -> quem chama a funÃ§Ã£o no momento.
    }

    // Cuidado pra pegar o address da rede certa!
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 value, , , ) = priceFeed.latestRoundData();
        return uint256(value * 10**10);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethusd = getPrice();
        uint256 usdAmount = (ethusd * ethAmount) / 10**18; // Smart Contracts sempre trabalham a nivel Wei
        return usdAmount;
    }

    function withdraw() public payable isADM {
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 index = 0; index < Funders.length; index++) {
            address funder = Funders[index];
            amountfunded[funder] = 0;
        }

        Funders = new address[](0);
    }

    address[] public Funders;
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