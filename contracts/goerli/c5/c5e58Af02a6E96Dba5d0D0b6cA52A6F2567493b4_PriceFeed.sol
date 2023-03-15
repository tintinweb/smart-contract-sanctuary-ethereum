// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract PriceFeed {
    int256 price ;
    address owner ;

    constructor(int _price){
        owner = msg.sender;
        price = _price ;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can execute this function!");
        _;
    }

    function setPrice(int _price) public onlyOwner{
        price = _price ;
    }

    function latestRoundData() external view returns (uint80 roundId, int answer, uint startedAt, uint updatedAt, uint80 answeredInRound ){
        return (0, price, 0, 0, 0);
    }
}

    // price has 8 decimals 
    // price of Dirham in USD (notice that decimals is 6) ==>> https://www.xe.com/currencycharts/?from=AED&to=USD&view=10Y
    // answer = 27229400 ;