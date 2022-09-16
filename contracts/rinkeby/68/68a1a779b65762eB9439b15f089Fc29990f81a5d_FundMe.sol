// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    //uint256 public minimumUsd = 50 * 1e18;
    uint256 public constant MINIMUM_USD = 50 * 10**18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;

        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //payable es necesaria para las funciones que se destinaran a realizar transacciones
    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );

        //cuando el require da negativo hace un revert, todo el codigo anterior a este dentro de la misma funcion se revertira, pero aun asi gastara gas, el gas usado para todo lo anteior al revert, no lo posterior ya que nunca llegara hasta alli
        //require(msg.value.gerConversionRate() >= minimumUsd, "no se envio el suficiente dinero"); //1e18 == 1 * 10 ** 18 == 1000000000000000000 == 1 ethereum
        //msg.value.gerConversionRate() en las librerias el objeto al cual se el esta aplicando el metodo es considerado su primer parametro
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 founderIndex = 0;
            founderIndex < funders.length;
            founderIndex++
        ) {
            address funder = funders[founderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        //tres tipode formas de hacer una trasnferencia
        //transfer
        //payable(msg.sender).transfer(address(this).balance);

        //send
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "error al hacer send");

        //call
        (
            bool callSuccess, /*bytes memory dataReturned*/

        ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "error al hacer call");
    }

    // ejemplo de modificador
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "sender is not owner");
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _; // esto representa al resto del codigo en la funcion con el modificador en este caso hara la linea de arriba y cuando lo haga, hara todo lo demas
    }

    //si se hace un llamado a este contrato con algun tipo de informacion y este no es reconocido por el contrato, lo redirigira a found
    fallback() external payable {
        fund();
    }

    //si se hace un llamado a este contrato sin ningun tipo de informacion, lo redirigira a found
    receive() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // Rinkeby ETH / USD Address
        // https://docs.chain.link/docs/ethereum-addresses/
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
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