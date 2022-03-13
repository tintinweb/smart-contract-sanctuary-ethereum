/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// Part: smartcontractkit/[email protected]/AggregatorV3Interface

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

// File: FundMe.sol

contract FundMe {
    //using SafeMathChainlink for uint256; // solo per solidity < 0.8.8

    mapping(address => uint256) public address_amount;
    address[] private founders;

    address private eth_usd = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;
    address private owner;

    constructor() public {
        //eseguito al momento del deploy e poi mai piÃ¹
        owner = msg.sender; // il mio address
    }

    function fund() public payable {
        uint256 minimumUsd = 50 * 10**18;

        // una sorta di assert, se fallisce fa revert a restituisce tutto, anche il gas che non Ã¨ stato speso!
        require(
            getConversionRate(msg.value) >= minimumUsd,
            "You need to spend at least 50$ of ETH"
        );

        address_amount[msg.sender] += msg.value;
        founders.push(msg.sender);
        // ETH -> USD? dobbiamo ottenerlo da un Oracle (contracts non vedono il mondo esterno)
        // ciÃ² perchÃ© i contracts devono dare lo stesso output su tutti i nodi (ridondanza di comportamento) -> determinismo
        // Una chiamata API puÃ² dare risposte diverse ai nodi in base a parametri estrerni (eg tempo della richiesta)
    }

    // i modificatori permettono di eseguire codice (eg require) prima o dopo la chiamata della funzione decorata
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the owner of the contract can call this function."
        );
        _; // esegui il resto del codice
    }

    function withdraw() public payable onlyOwner {
        //solo l'owner del contratto puÃ² fare withdraw
        //require(msg.sender == owner, "Only the owner of the contract can call this function.");

        // sender.transfer(mny) trasferisce mny all'indirizzo di sender. mny deve essere un balance
        // this si riferisce al contract attuale
        // balance di un address restituisce il totale di ETH di un dato address
        // payable dichiara che l'address puÃ² ricevere token.
        payable(msg.sender).transfer(address(this).balance);
        // come capisco di resettare l'address corretto?
        // mi salvo tutti quelli che hanno mandato fondi e resetto tutti i loro contributi (basterebbe buttare via tutto)
        for (uint256 i = 0; i < founders.length; i++) {
            address_amount[founders[i]] = 0;
        }

        founders = new address[](0); // reset
    }

    function getVersion() public view returns (uint256) {
        //"carica" il contratto
        AggregatorV3Interface priceFeed = AggregatorV3Interface(eth_usd); //ABI e address
        //ora posso chiamare tutti i metodi esposti AggregatorV3Interface
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // chiamata all'oracolo
        AggregatorV3Interface priceFeed = AggregatorV3Interface(eth_usd); //ABI e address
        (
            ,
            //uint80 roundId
            int256 answer, //uint256 startedAt //uint256 updatedAt //uint80 answeredInRound
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(answer * (10**10));
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 10**18;
        return ethAmountInUsd;
    }
}