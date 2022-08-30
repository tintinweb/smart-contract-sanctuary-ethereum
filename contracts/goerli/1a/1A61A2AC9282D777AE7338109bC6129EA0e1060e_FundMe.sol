//obtener fondos de usuarios
//retirar fondos
//poner un minimo de valor a los fondos en usd

// SPDX-License-Identifier: MIT
//pragma
pragma solidity 0.8.8;
//imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./PriceConverter.sol";
//errors
error FundMe__NotOwner();

//interfaces, libraries, contract

/** @title un contrato para fondear
 * @author dami
 * @notice esto es un demo de lo q venimos aprendiendo
 * @dev esto implementa precios como las librerias
 */

contract FundMe {
    //type declarations [using PriceConverter for uint256;] la de abajo la unica

    using PriceConverter for uint256;

    // state variables

    uint256 public constant MINIMUM_USD = 10 * 1e18; // 1 * 10 ** 18

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable i_owner;
    AggregatorV3Interface public priceFeed;

    modifier onlyOwner() {
        _;
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }

        // si el guion esta arriba primero la funcion y dsps el modifier
        // en este caso primero el require y despues la funcion
    }

    //orden funciones
    //constructor
    //recieve
    //fallback
    //external
    //public
    //internal
    //private
    //view/pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender; // 858705 gas
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice esta funcion fondea el contrato
     * @dev esto implementa precios como las librerias
     */

    function fund() public payable {
        // que se pueda poner un minimo en usd para enviar
        // como mandamos eth a este contrato?
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "didnt send enough!"
        ); // 1e18 == 1 * 10 ** 18
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        //for loop (como en js)
        // [1,2,3,4]
        //for(/* starting index, ending index, step amount*/)
        // 0, 10, 2
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            //code
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //reset the array
        funders = new address[](0);
        //actually withdraw funds

        payable(msg.sender).transfer(address(this).balance);
        //send
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "send failed!");
        //call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed!");
    }
}

//que pasa si alguien manda eth a este contrato sin la funcion fund?
//hay funciones q sirven para eso, devolver un codigo
//receive
//fallback

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
pragma solidity 0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //ABI
        //Address	0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

        (, int256 price, , , ) = priceFeed.latestRoundData();
        // eth en usd
        // [valor x]
        return uint256(price * 1e10); // 1**10 == 10000000000
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
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}