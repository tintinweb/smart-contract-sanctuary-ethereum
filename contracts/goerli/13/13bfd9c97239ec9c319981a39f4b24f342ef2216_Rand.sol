//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library Rand {
    /* generates a number from 0 to 2^n based on the last n blocks */
    function multiBlockRandomGen(uint seed, uint size) public view returns (uint randomNumber) {
        uint n = 0;
        for (uint i = 0; i < size; i++){
            if (uint(keccak256(abi.encodePacked(blockhash(block.number-i-1), seed )))%2==0)
                n += 2**i;
        }
        return n % 20;
    }

    /* Generates a random number from 0 to 10 based on the last block hash */
    function randomGen11(uint seed, uint num) public view returns (uint randomNumber) {
        return(uint(keccak256(abi.encodePacked(blockhash(block.number-num), seed, block.timestamp )))%11);
    }

    /* Generates a random number from 1 to 12 based on the last block hash */
    function randomGenPos12(uint seed, uint num) public view returns (uint randomNumber) {
        return(uint(keccak256(abi.encodePacked(blockhash(block.number-num), seed, block.timestamp )))%12)+1;
    }

    /* Generates a random number from 1 to 5 based on the last block hash */
    function randomGenPos5(uint seed, uint num) public view returns (uint randomNumber) {
        return(uint(keccak256(abi.encodePacked(blockhash(block.number-num), seed, block.timestamp )))%5)+1;
    }

    /* Generates a random number from 0 to 25 based on the last block hash */
    function randomGen25(uint seed, uint num) public view returns (uint randomNumber) {
        return(uint(keccak256(abi.encodePacked(blockhash(block.number-num), seed, block.timestamp )))%25);
    }

    /* Generates a random number from 0 to 100 based on the last block hash */
    function randomGen100(uint seed, uint num) public view returns (uint randomNumber) {
        return(uint(keccak256(abi.encodePacked(blockhash(block.number-num),seed, block.timestamp )))%100);
    }

    /* Generates a random number from 0 to 15 based on the last block hash */
    function randomGen15(uint seed, uint num) public view returns (uint randomNumber) {
        return(uint(keccak256(abi.encodePacked(blockhash(block.number-num), seed , block.timestamp)))%15);
    }

    /* Generates a random number from 0 to 15 based on the last block hash */
    function randomGenSha15(uint seed, uint num) public view returns (uint randomNumber) {
        return(uint(sha256(abi.encodePacked(blockhash(block.number-num), seed, block.timestamp )))%25);
    }

    /* Generates a random number from 0 to 25 based on the last block hash */
    function randomGenSha25(uint seed, uint num) public view returns (uint randomNumber) {
        return(uint(sha256(abi.encodePacked(blockhash(block.number-num), seed, block.timestamp )))%25);
    }

    /* Generates a random number from 0 to 100 based on the last block hash */
    function randomGenSha100(uint seed, uint num) public view returns (uint randomNumber) {
        return(uint(sha256(abi.encodePacked(blockhash(block.number-num), seed, block.timestamp )))%100);
    }

    function getSeed(uint index) public view returns (uint){
        int price;
        if (index == 1) {
            AggregatorV3Interface feed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); //eth feed
            price = feed.latestAnswer();
        }
        if (index == 2) {
            AggregatorV3Interface feed = AggregatorV3Interface(0xAc559F25B1619171CbC396a50854A3240b6A4e99); //btc/eth feed
            price = feed.latestAnswer();
        }
        if (index == 3) {
            AggregatorV3Interface feed = AggregatorV3Interface(0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676); //matic feed
            price = feed.latestAnswer();
        }
        if (index == 4) {
            AggregatorV3Interface feed = AggregatorV3Interface(0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c); //link feed
            price = feed.latestAnswer();
        }
        if (index == 5) {
            AggregatorV3Interface feed = AggregatorV3Interface(0xA027702dbb89fbd58938e4324ac03B58d812b0E1); //yearn feed
            price = feed.latestAnswer();
        }
        if (index == 6) {
            AggregatorV3Interface feed = AggregatorV3Interface(0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5); //comp feed
            price = feed.latestAnswer();
        }
        if (index == 7) {
            AggregatorV3Interface feed = AggregatorV3Interface(0x547a514d5e3769680Ce22B2361c10Ea13619e8a9); //aave feed
            price = feed.latestAnswer();
        }
        if (index == 8) {
            AggregatorV3Interface feed = AggregatorV3Interface(0xec1D1B3b0443256cc3860e24a46F108e699484Aa); //maker feed
            price = feed.latestAnswer();
        }
        if (index == 9) {
            AggregatorV3Interface feed = AggregatorV3Interface(0x553303d460EE0afB37EdFf9bE42922D8FF63220e); //uni feed
            price = feed.latestAnswer();
        }
        if (index == 10) {
            AggregatorV3Interface feed = AggregatorV3Interface(0xB9E1E3A9feFf48998E45Fa90847ed4D467E8BcfD); //frax feed
            price = feed.latestAnswer();
        }
        
        return uint(price);
    }

function getSeedLocal(uint index) public pure returns (uint){
        int price;
        if (index == 1) {
            price = 1;
        }
        if (index == 2) {
            price = 2;
        }
        if (index == 3) {
            price = 3;
        }
        if (index == 4) {
            price = 4;
        }
        if (index == 5) {
            price = 5;
        }
        if (index == 6) {
            price = 6;
        }
        if (index == 7) {
            price = 7;
        }
        if (index == 8) {
            price = 8;
        }
        if (index == 9) {
            price = 9;
        }
        if (index == 10) {
            price = 10;
        }
        
        return uint(price);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
  
  function latestAnswer() external view returns (int);
}