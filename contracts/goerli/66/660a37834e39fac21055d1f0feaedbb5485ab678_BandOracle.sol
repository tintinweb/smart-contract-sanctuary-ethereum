/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract BandOracle {
    string [] coins; 
    mapping (string => uint256) prices;
    // uint256 public price;
    uint256 public lastUpdated;

    event PriceUpdated(uint256 indexed timeStamp, uint256 price, string symbol);

    receive() external payable {}

    function updatePrice(string memory _symbol, uint256 _price) external {
        prices[_symbol] = _price;
        lastUpdated = block.timestamp;

        emit PriceUpdated(block.timestamp, _price, _symbol);
    }

    function setCoins(string memory _sybmol) external {
        coins.push(_sybmol);

    }

     function popCoins() external {
        coins.pop();

    }

    function getCoins () public view returns (string [] memory) {

        return coins;

    }
 

}