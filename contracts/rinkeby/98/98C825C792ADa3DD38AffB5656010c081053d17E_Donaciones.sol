// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error Donaciones__UsuarioNoAutorizado();
error Donaciones__NecesitasEnviarMasETH();
error Donaciones__NoHayDonacionesTodavia();

contract Donaciones {
    using PriceConverter for uint256;

    uint256 public constant MINIMO_USD = 1 * 10**18;
    address private immutable i_admin;
    address[] private s_donadores;
    uint256 private s_totalDonaciones;
    uint256 private s_totalDonado;
    mapping(address => uint256) private s_donadorCantidadDonada;
    AggregatorV3Interface private s_precioActual;

    modifier soloAdmin() {
        if (msg.sender != i_admin) revert Donaciones__UsuarioNoAutorizado();
        _;
    }

    constructor(address precioActual) {
        s_precioActual = AggregatorV3Interface(precioActual);
        i_admin = msg.sender;
        s_totalDonaciones = 0;
        s_totalDonado = 0;
    }

    receive() external payable {
        donar();
    }

    fallback() external payable {
        donar();
    }

    function donar() public payable {
        if (MINIMO_USD >= msg.value.getConversionRate(s_precioActual))
            revert Donaciones__NecesitasEnviarMasETH();
        s_totalDonaciones++;
        s_donadorCantidadDonada[msg.sender] += msg.value;
        s_donadores.push(msg.sender);
    }

    function retirar() public payable soloAdmin {
        if (s_totalDonaciones <= 0) {
            revert Donaciones__NoHayDonacionesTodavia();
        }
        address[] memory donadores = s_donadores;
        for (
            uint256 donadorIndex = 0;
            donadorIndex < donadores.length;
            donadorIndex++
        ) {
            address donador = donadores[donadorIndex];
            s_donadorCantidadDonada[donador] = 0;
        }
        s_totalDonado += (address(this).balance);
        s_donadores = new address[](0);
        (bool success, ) = i_admin.call{value: address(this).balance}("");
        require(success);
    }

    function verCantidadDonada(address direccionDonador)
        public
        view
        returns (uint256)
    {
        return s_donadorCantidadDonada[direccionDonador];
    }

    function verDonador(uint256 donador) public view returns (address) {
        return s_donadores[donador];
    }

    function verDonadoActual() public view returns (uint256) {
        return address(this).balance;
    }

    function verDonadores() public view returns (address[] memory) {
        return s_donadores;
    }

    function verTotalDonadores() public view returns (uint256) {
        return s_donadores.length;
    }

    function verTotalDonaciones() public view returns (uint256) {
        return s_totalDonaciones;
    }

    function verTotalDonado() public view returns (uint256) {
        return s_totalDonado;
    }

    function verAdmin() public view returns (address) {
        return i_admin;
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
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    // call it get fiatConversionRate, since it assumes something about decimals
    // It wouldn't work for every aggregator
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
}