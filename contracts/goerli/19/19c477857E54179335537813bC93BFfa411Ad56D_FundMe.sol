//SPDX-License-Identifier: IMT

pragma solidity >=0.6.0 <=0.9.0;
import "AggregatorV3Interface.sol";

contract FundMe {
    mapping(address => uint256) public adressToMountFunded;
    address[] public funders; //Arreglo para recorrr los adress de los aportantes
    address payable owner; //Indicando el propietario de contrato

    constructor() {
        owner = payable(msg.sender); //constructo para indicar que solo el owner puede hacer retiros
    }

    function fund() public payable {
        //Monto mino a enviar 50 USD
        uint256 miniumUSD = 50 * 10**18; //monto minimo a depositar al contrato
        require(
            getConversionRate(msg.value) >= miniumUSD,
            "El valor enviado es menor a lo requerido"
        );
        //Cuanto ETH => USD, tasa de conversion
        adressToMountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountUSD = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountUSD;
    }

    //Indicando las modificaciones que quiero realizar
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        //Only owner
        //msg.sender.transfer(address(this).balance);V6
        payable(msg.sender).transfer(address(this).balance); //V8

        for (uint256 funderIndex; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            adressToMountFunded[funder] = 0;
        }

        funders = new address[](0);
    }
}

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