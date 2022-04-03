/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract Stocks {

    struct Stock {
        string name;
        string code;
        uint price;
    }
    uint public stocksCount;
    mapping(uint => Stock) public stocks;
    event stockAddEvent(uint _stockId);

    constructor() public {
        stocksCount = 0;
        addStock("Apple", "AAPL", 174);
        addStock("Google", "GOOGL", 2803);
        addStock("Meta", "FB", 224);
        addStock("Microsoft", "MSTF", 309);
        addStock("Tesla", "TSLA", 1084);
    }

    function addStock(string memory name, string memory code, uint price) public {
        stocks[stocksCount] = Stock(name, code, price);
        stocksCount++;
    }

    function get(uint _stockId) public view returns (Stock memory) {
        return stocks[_stockId];
    }

    function getStocksNames() public view returns (string[] memory) {
        string[] memory names = new string[](stocksCount);
        for(uint i = 0; i < stocksCount; i++) {
            names[i] = stocks[i].name;        
        }
        return names;
    }

    function getStocks() public view returns (string[] memory, string[] memory, uint[] memory) {
        string[] memory names = new string[](stocksCount);
        string[] memory codes = new string[](stocksCount);
        uint[] memory prices = new uint[](stocksCount);

        for(uint i = 0; i < stocksCount; i++) {
            Stock memory stock = stocks[i];
            names[i] = stock.name;
            codes[i] = stock.code;
            prices[i] = stock.price;
        }
        return (names, codes, prices);

    }

}