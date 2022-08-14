// SPDX-License-Identifier: MIT
//pragma statement
pragma solidity ^0.8.8;

//Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";
//import "hardhat/console.sol";

// Error codes stuffs
error FundMe__NotOwner();

// Libraries, Interfaces stuffs here...

/** @title A simple crowd funding contract
 *   @author Carlos Vouking
 *   @notice Its a basic crow funding contract which can be extended
 *   @dev This embeds the PriceFeed library from Chainlink.
 */
contract FundMe {
    //1-Type Declarations
    using PriceConverter for uint256;

    //2-State variables
    mapping(address => uint256) public s_addressToAmountFunded;
    address[] public s_funders;
    uint256 transactionCounter;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address public immutable i_owner;
    uint256 public constant MINIMUM_USD = 50 * 10**18; // in ETH

    event Transfer(
        address from,
        address receiver,
        uint256 amount,
        string message,
        uint256 timestamp,
        string keyword
    );

    struct TransfertStruct {
        address sender;
        address reciever;
        uint256 amountFunded;
        string message;
        uint256 timestamp;
        string keyword;
    }

    TransfertStruct[] transferts;

    // 'priceFeed' et 'priceFeedEuroToUsd' sont variables et modularisés en fonction du type de blockchain (serviront désormais de 'PriceConverter')
    AggregatorV3Interface public s_priceFeed;

    //3-Modifiers
    modifier onlyOwner() {
        // require(msg.sender == owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _; // doing the rest of the code in the function which inherits the 'onlyOwner' modifier
    }

    //4-Constructors
    // Lors du deploiement, passer coe argument l'adresse de prix en fucntion de la blockchain sur laquelle on opère Ethereum, BNB, Polygonlgon...Mainnet, rinkeby, Kovan etc...
    constructor(address priceFeedAddress) {
        i_owner = msg.sender; // the guy who is deploying the contract
        s_priceFeed = AggregatorV3Interface(priceFeedAddress); // ETH<=>USD // instead of 'priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e)' which is only for Rinkeby;
        //priceFeedEuroToUsd = AggregatorV3Interface(priceFeedEuroToUsdAddress);  // Euro=>USD
    }

    //4-Recieves
    // receive() external payable {
    //     fund();
    // }

    // //5-Fallbacks
    // fallback() external payable {
    //     fund();
    // }

    // get the description of the contract
    // function getDescription() external view returns (string memory) {
    //     return priceFeed.description();
    // }

    /**
     * @notice Function is used to fund the contract 'FundMe'
     * @dev The library PriceFeed is implemented here.
     */
    function fund() public payable {
        //getConversionRate(msg.value, priceFeed)
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        ); // ConversionRate ds 'PriceConverter' aura désormais 2 paramètres: 'msg.value' et 'priceFeed'
        //require(msg.value.getConversionRateInEuro(priceFeedEuroToUsd) >= MINIMUM_EUR, "Not enough Eth to proceed !");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    // function fundEuro() public payable {
    //     require(msg.value.getConversionRateInEuro(priceFeedEuroToUsd) >= MINIMUM_EUR,  "You probably need more ETH!");
    //     addressToAmountFunded[msg.sender] = addressToAmountFunded[msg.sender] + msg.value;
    //     funders.push(msg.sender);
    // }

    function withdraw() public payable onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // resetting our funders array with (0) funders inside...thus withdrawing the funds and restart funding with a completely blank array
        s_funders = new address[](0);

        /* 
        Pour retirer les fonds cotisés, il se présente 3 méthodes possibles: Par Transfert, Par Envoi, Par Call 
        remeber Transfer and Send methods are gas expensive 2300TH 
        faut pas oublier de convertir l'adresse 'msg.value' en adresse payable 'payable(msg.value)'.
        */
        // // transfer....throws an error if it fails
        // payable(msg.sender).transfer(address(this).balance);
        // // send...returns a bool if it fails
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");   // help revert the transaction if it fails
        // call...can be used to call any function in ethereum without even have to have an ABI
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed"); // revert if the 'call' fails
    }

    function addToBlockchain(
        address payable _reciever,
        uint256 _amount,
        string memory _message,
        string memory _keyword
    ) public {
        transactionCounter = transactionCounter + 1;
        transferts.push(
            TransfertStruct(
                msg.sender,
                _reciever,
                _amount,
                _message,
                block.timestamp,
                _keyword
            )
        );

        emit Transfer(
            msg.sender,
            _reciever,
            _amount,
            _message,
            block.timestamp,
            _keyword
        );
    }

    function getAllTransgerts() public view returns (TransfertStruct[] memory) {
        return transferts;
    }

    function getTransactionsCount() public view returns (uint256) {
        return transactionCounter;
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
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    // price Of ETH In terms of USD......answer is in USD.....// ie : to buy 1eth , must spend 'answer' USD
    // Donc 'answer' c'est le nombre de $USD qu'il faut pour achetehr 1eth.
    //....We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // // Rinkeby ETH / USD Address
        // // https://docs.chain.link/docs/ethereum-addresses/
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 answer, , , ) = priceFeed.latestRoundData(); //answer= priceOfETHIntermsofUSD
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // function getPriceEuroToUsd(AggregatorV3Interface priceFeedEuroToUsd)
    //     internal
    //     view
    //     returns (uint256)
    // {
    //     // // il nous faut l'adresse Rinkeby de l'équivalence EUR / USD
    //     // // https://docs.chain.link/docs/ethereum-addresses/
    //     // //https://rinkeby.etherscan.io/address/0x78F9e60608bF48a1155b4B2A5e31F32318a1d85F
    //     // AggregatorV3Interface priceFeedEuroToUsd = AggregatorV3Interface(
    //     //     0x78F9e60608bF48a1155b4B2A5e31F32318a1d85F
    //     // );
    //     (, int256 answer, , , ) = priceFeedEuroToUsd.latestRoundData();
    //     return uint256(answer);
    // }

    // 1000000000
    // Pass some ETH Amount and at the other side how much that Eth amount is worth in terms of USD
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed); //ethprice (en $USD )::  le nombre de $USD qu il faut pour acheter 1 eth.
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; //ethAmountInUsd (en Eth)::  le nombre de $USD qu'il faut donc pour le nombre de ETH apportés pour participer (msg.value)
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd; //$USD
    }

    // function getConversionRateInEuro(
    //     uint256 ethAmountEuro,
    //     AggregatorV3Interface priceFeedEuroToUsd
    // ) internal view returns (uint256) {
    //     uint256 ethPriceInEuro = getPriceEuroToUsd(priceFeedEuroToUsd);
    //     uint256 ethAmountInEuro = (ethPriceInEuro * ethAmountEuro) /
    //         1000000000000000000;
    //     // ci dessous la conversion actuelle entre ETH/EUR après ajustement des zéros
    //     return ethAmountInEuro;
    // }
}