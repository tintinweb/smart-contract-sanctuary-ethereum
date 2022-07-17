//Queremos poder alamacenar fondos de usuarios
//Poder retirarlos
//Poder setear unos fondos mínimos valorados en USD

//SPDX-License-Identifier: MIT


//Gas inicial 882144
//            862614
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error Unauthorized();


contract FundMe{

    using PriceConverter for uint256;

    uint256 public  MIN_USD = 50 * 1e18;

    //sin constant  23471
    //con constant 	21371
    //ahorro = 2100 gas * 8000000000 wei/gas = 1.68e13 = 0.0000168ETH = 0.0205968 USD

    address [] public funders;
    mapping (address=>uint256) public Address2donacion;
    address creador = 0x6219209bE755AE519c483464D59069aDeb876431;

    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress){
        i_owner = msg.sender;//Con esto inicializamos owner con la dirección que despliegue el contrato
        priceFeed= AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable{        
        //msg.value.getConvRate(); //el valor de msg.value se va a pasar como variable a la funcion getConvRate
        require (msg.value.getConvRate(priceFeed)>= MIN_USD, "Not enough"); //msg.value viene en WEI, 18 decimales
        funders.push(msg.sender);
        Address2donacion[msg.sender] += msg.value;
    
    }    

    function withdraw() public onlyOwner{
        //Vamos direccion por direccion y ponemos que cada una ha donado 0
        for(uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            Address2donacion[funder] =0;

        }
        //Reseteamos el vector que contenía todas las direcciones donadoras
        funders = new address[](0);

        //Retiramos los fondos del contrato
            //Transfer
            //payable(msg.sender).transfer(address(this).balance);
            //Send
            // bool sendSuccess = payable(msg.sender).send(address(this).blance);
            //require(sendSuccess, "Send failed");
            //call -> comando de nivel bajo
            (bool Success, ) = payable(msg.sender).call{value: address(this).balance}("");
            require(Success, "Llamada a la funcion fallida");

    }

    modifier onlyOwner{
        if(msg.sender != i_owner){
            revert Unauthorized();
        }
        _;
    }

    //Que pasa si alguien manda ETH a este contrato sin acceder a la función fund

    receive() external payable {
        fund();
    }

    fallback() external payable{
        fund();
    }

}

//Creanos una librería que hará las operaciones de la conversion del precio

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library PriceConverter{

    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256){
        //Como debemos interactuar con un contrato exterior ya existente, Address y ABI
        //Address 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //Si añadimos el priceFeed, no hace falta hardcodear la dirección del oráculo
        //AggregatorV3Interface priceFeed= AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer, , , )=  priceFeed.latestRoundData(); //Con esto conseguimos el precio de ETH en USD 
        return uint256(answer * 1e10);  //Le quitamos 10 decimales y lo convertimos en uint256 para operar con msg.value
    }

    /* function getConvRate() internal view returns (uint256){
        AggregatorV3Interface pr = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return pr.version();
    } */


    function getConvRate(uint256 ethAmount, AggregatorV3Interface priceFeed ) internal view returns (uint256){
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethEnUsd = (ethPrice * ethAmount) / 1e18;

        return ethEnUsd;



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