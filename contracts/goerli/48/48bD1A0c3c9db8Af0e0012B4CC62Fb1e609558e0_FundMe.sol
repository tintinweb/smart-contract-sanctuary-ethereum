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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {priceLibrary} from "./priceLibrary.sol";

// in remix kanet kafiya anana n importiw had l contract
// but fach ankhedmo b hardhat khsna n installiw module dialha using npm/yarn bach hardhat tfhem ach brina ndiro

// importina dik AggregatorV3Interface directly from GitHub

contract FundMe {
    using priceLibrary for uint256;
    /* had contract brinaha tmewel men taraf xi wahed w had l fund hada rayb9a f contract address m holdi
     w rir l owner of the contract who gonna be able to withdraw this funds */

    uint256 public minimumAmount = 50 * 1e18; //(1*10)**18 => 50 * 1e18 == 50000000000000000000

    address[] public funders; // brina kol funder nsjlo l wallet address dialo f an array

    address public owner;

    AggregatorV3Interface public priceFeed;

    constructor(address priceFeedAddress) {
        // constructor hia awel function rat executa automatiquement after you deploy the contract
        // ya3ni ay 7aja drtiha inside constructor rada t executa une fois deployiti l contract
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        // brina had function t fundi lina l contract with an amount of USD
        // ila brina nredo chi function payable kanzido keyword "payable"
        // payable : kate3ni n9dro ndiro send/receive dial ETH or other token
        // remarque : contract address can hold funds b7alha b7al wallet address
        // db mni 3edna l function payable we can access to one of the global keyword "msg.value"
        // dik value ra kayna jeht l compiler w kat3ni hia l value or l amount li radi yseft xi wahd l had contract

        //ila brina matalan l fund li raysefto l user khesso ykon > 50 USD

        require(
            priceLibrary.EthToUsd(msg.value, priceFeed) > minimumAmount,
            "Not enough amount of funds"
        );
        funders.push(msg.sender); // "msg.sender" gonna return the address of the fund sender
    }

    //1e18== (1 * 10)**18 == 1000000000000000000 wei == 1 eth
    // require dayra b7al " if " ; c est a dire que raychof wach dik msg.value kbira mn dik minimumAmount
    // si oui ray fundi l contract sinon raydir revert l function
    // revert in simple terms kate3ni ila dik section lewla dial require mat7a9e9atch donc ta ila
    // kano xi hajat li kaydiw l gas fees kolxi ray t annula w marayt9at3och l gas fees
    // db ila brina dik l value tkon b USD , ki randiro ??
    // radi nkhedmo b Decentralized Oracles (ChainLink) bach te3tina l price dial Eth li howa outside blockchain
    // Blockchain oracle : any device that interacts with the off-chain world to provide external data to
    // smart contracts

    // khsna dik minimumAmount ykon b USD
    // awalan khsna b3da L PRICE D ETHEREUM b USD

    /* function getPrice() public view returns (uint256) {
        // Address of the contract li rat3tina l price d ethreum b USD
        // 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // ABI dial had contract :
        // kayn a concept in solidity called " Interface " howa li importina f lwel
        // had "AggregatorV3Interface" katweli b7al xi type dial variables
        // donc priceFeed hiya wa7ed contract li rat3tina price d ETH b USD
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    } */

    // db ra creyina a function li kat3tina l price dial ETH b USD

    // now we gonna create a function li rat converti lina l value dial "msg.value" l USD (chof priceLibrary)

    // db ha contract fiha l funds
    // brina ndiro withdraw l had funds ( brina only owners li ydiro l withdraw l funds)
    // donc bax ndiro withdraw khassna dok l addresses li sifto l funds nms7ohom

    function withdrawFunds() public {
        require(msg.sender == owner, "Sender is not the owner!");

        funders = new address[](0);
        // hadi kat3ni anana redina dik funders array khawiya fiha 0 element

        // bach ndiro l withdraw l funds li kaynin f chi contract kaynin 3 methods :
        // 1-Transfer
        // 2-Send
        // 3-Call

        // 1-Transfer:
        payable(msg.sender).transfer(address(this).balance);
        // payable fach katzidha 9bel chi haja donc dik haja t9dar dir liha send/receive dial ETH or tokens
        // f had le cas owner address n9dro n reciviw biha l funds
        // keyword "this" kay3ni had contract donc address(this).balance kay3ni balance d had contract

        // 2-Send:
        //bool sendSuccess = payable(msg.sender).send(address(this).balance); // send returns a boolean
        // require(sendSuccess,"send Failed!");

        // 3-Call:
        //  (bool callSuccess, )=payable(msg.sender).call{value: address(this).balance}("");
        //require(callSuccess,"call Failed!");

        // ahssan method hia Call hit mafihach errors bzaaf.
    }

    // receive() external payable {
    //     fund();
    //     // db receive function kat3ni bli kayna imkanyia dial xi user ysifet l had contract some funds
    //     // without calling the fund function c est a dire y9dar ydkhol l metamask w w y dir send
    //     // l contract address w ysift some ETH
    // }

    // fallback() external payable {
    //     fund();
    //     //fallback kat executa ila kanet data li msifta m3a transaction empty (msg.data==empty)
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// a library is similar to a contract but man9droch n declariw state variables or send ether to this
// library contract.

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library priceLibrary {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function EthToUsd(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed); // fih 18 decimals
        uint256 result = (ethPrice * ethAmount) / 1e18; // 9ssmna ela 18 decimals bach matkhrjch lina 36 decimals
        return result;
    }
}