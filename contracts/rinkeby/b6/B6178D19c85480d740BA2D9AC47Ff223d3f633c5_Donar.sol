// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error Donar__RetiroNoAutorizado();

contract Donar {
    using PriceConverter for uint256;

    // Variables de estado
    uint256 public constant MINIMO_USD = 5 * 10**18;
    address private immutable i_caridad;
    address[] private s_donadores;
    mapping(address => uint256) private s_donadorCantidadDonada;
    AggregatorV3Interface private s_precioActual;

    modifier soloAdmin() {
        if (msg.sender != i_caridad) {
            revert Donar__RetiroNoAutorizado();
        }
        _;
    }

    constructor(address precioActual) {
        s_precioActual = AggregatorV3Interface(precioActual);
        i_caridad = msg.sender;
    }

    receive() external payable {
        donar();
    }

    fallback() external payable {
        donar();
    }

    /// @notice donaciones el contrato esta basado en el precio ETH/USD
    function donar() public payable {
        require(
            msg.value.getConversionRate(s_precioActual) >= MINIMO_USD,
            "Necesitas enviar mas ETH!"
        );
        s_donadorCantidadDonada[msg.sender] += msg.value;
        s_donadores.push(msg.sender);
    }

    function retirar() public payable soloAdmin {
        for (
            uint256 donadorIndex = 0;
            donadorIndex < s_donadores.length;
            donadorIndex++
        ) {
            address donador = s_donadores[donadorIndex];
            s_donadorCantidadDonada[donador] = 0;
        }
        s_donadores = new address[](0);
        // Transfer vs call vs Send
        // payable(msg.sender).transfer(address(this).balance); // es mejor usar call
        (bool success, ) = i_caridad.call{value: address(this).balance}("");
        require(success);
    }

    function retirarMejorado() public payable soloAdmin {
        address[] memory donadores = s_donadores;
        for (
            uint256 donadorIndex = 0;
            donadorIndex < donadores.length;
            donadorIndex++
        ) {
            address donador = donadores[donadorIndex];
            s_donadorCantidadDonada[donador] = 0;
        }
        s_donadores = new address[](0);
        (bool success, ) = i_caridad.call{value: address(this).balance}("");
        require(success);
    }

    function verCantidadDonada(address direccionDonador)
        public
        view
        returns (uint256)
    {
        return s_donadorCantidadDonada[direccionDonador];
    }

    function verVersion() public view returns (uint256) {
        return s_precioActual.version();
    }

    function verDonador(uint256 index) public view returns (address) {
        return s_donadores[index];
    }

    function verAdmin() public view returns (address) {
        return i_caridad;
    }

    function verPrecioActual() public view returns (AggregatorV3Interface) {
        return s_precioActual;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface precioActual)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = precioActual.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    // call it get fiatConversionRate, since it assumes something about decimals
    // It wouldn't work for every aggregator
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface precioActual
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(precioActual);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
}