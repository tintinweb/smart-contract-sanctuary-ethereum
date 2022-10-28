// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18; // constant economiza muito GAS!! quando for usar constant, utilize tudo no CAPSLOCK

    AggregatorV3Interface public priceFeed;

    address[] public funders; // variavel global que armazena todo mundo que mandou dinheiro
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender; // no deploy do contrato ele já seta automaticamente o dono
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD
        // 1. How do we send ETH to this contract
        //

        // msg.value.getConversionRate();
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didnt send enough"
        ); // 1e18 = 1 * 10 ** 18 == 1000000000000000000
        // outra observação: se dentro de uma função houver um "require" e sua condição não for atingida, tudo que estiver para trás vai ser desfeito.

        funders.push(msg.sender); // aqui a gente empilha toda vez que alguém enviar uma transação
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0; // reseta o valor doado por cada pessoa
        }

        funders = new address[](0); // reseta o vetor que armazena as pessoas que doaram

        // faz o saque dos fundos. para isso há 3 maneiras: transfer, send e call. vamos ver qual vai ser a opção do curso

        // transfer - custa 2300 gas e retorna erro caso não consiga
        // DESCOMENTE AQUI PARA USAR TRANSFER - payable(msg.sender).transfer(address(this).balance);
        // por que fazer o cast para payable? porque msg.sender é um endereço e payable(msg.sender) é um endereço "pagável"

        //send - custa 2300 gas e retorna um booleano
        // DESCOMENTE AQUI PARA USAR SEND - bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Envio falhou");

        //call - não tem valor fixado de gas, retorna booleano. Esse é o jeito recomendado de mandar dinheiro
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call falhou");
    }

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner!"); Assim usa muito GAS
        if (msg.sender != i_owner) revert NotOwner(); // Assim usa bem menos
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// O que acontece se alguem tentar mandar dinheiro para esse contrato ETH sem usar a função fund() ?

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI

        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000
        return uint256(price * 1e10); // 1**10 == 10000000000
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