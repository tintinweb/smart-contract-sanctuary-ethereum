//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;
import "./PriceConverter.sol";
/*
  Get funds from users 
  withdraw funds 
  Set a minimum funding value in USD
*/

//859,757
//840,221

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    /*
     21,415 gas - constant  
     23,515 gas - non-constant
     21,415 * 141000000000 = $9,058545  
     23,515 * 141000000000 = $9,946845
     Casi un dolar mas de gas por no colocar constant
     en MINIMUM_USD
    */
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    /*  
      21,508 gas - immutable
      23,644 gas - non-immutable
      este keyword reduce gas cost          
    */
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        //obtemos el address de quien hizo el deploy del contrato
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        /*Queremos ser capaces de establecer 
        una cantidad minima de fondos en USD */
        /*msg.value se considera el primer parametro para cualquier Library function
        si la funcion recibiera otro parametro(s), entonces si se le pasa el valor */
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        ); // 1e18 == 1 * 10 ** 18 == 1000000000000000000
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        /* starting index, ending index, step amount*/
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //resetear el array funders
        funders = new address[](0);
        //Procedemos a retirar los fondos de tres maneras: transfer, send, call
        // msg.sender = address type
        // payable(msg.sender) = payable address
        //Using transfer
        //payable(msg.sender).transfer(address(this).balance); //revierte automaticamente
        //Using send
        //bool sendSuccesss = payable(msg.sender).send(address(this).balance);
        //require(sendSuccesss, "Send failed"); // se encarga de revertir la transaccion si falla
        //Using Call
        (
            bool callSuccess, /* bytes memory dataReturned*/

        ) = payable(msg.sender).call{value: address(this).balance}(
                "" /*funcion*/
            );
        require(callSuccess, "Call failed"); //revierte la transaccion
    }

    /*la funcion que etiquete (use) un modifier, ejecutara primero las instrucciones del 
       modifier y luego sus instrucciones*/
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner(); //lo hace mas eficiente en gas cost
        }
        _; // significa ejecuta el resto del codigo de la funcion que usa este modifier
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // ABI of the contract and address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        //ETH en terminos de USD
        return uint256(price * 1e10); //1**10 == 10000000000
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    //     );
    //     return priceFeed.version();
    // }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // 1800_000000000000000000 = ETH / USD price
        // 1_000000000000000000 ETH
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