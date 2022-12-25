// SPDX-License-Identifier: MIT  
pragma solidity ^0.8.7;

contract EquityPriceStorage {
    
    Equity[] public underlyings;
    mapping(string => uint256) public nameToPrice;

    struct Equity{
        string name;
        uint256 price;
    }

    //view, pure
    function getPrice(string memory _name) public view returns(uint256){
        return nameToPrice[_name];
    }

    function addEquity(string memory _name, uint256 _price) public {
        underlyings.push(Equity(_name,_price));
        nameToPrice[_name]=_price;
    }
}

//0xd9145CCE52D386f254917e481eB44e9943F39138