/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract BandOracleUpdate {
    string [] public coins; 
    address [] public pTokens;
    mapping (string => uint256) public prices;
    mapping (address => uint256) public irBankPrices;
    // uint256 public price;
    uint256 public lastUpdated;

    event PriceUpdated(uint256 indexed timeStamp, uint256 price, string symbol);
    event PriceIrBankUpdated(uint256 indexed timeStamp, uint256 price, address pToken);


    receive() external payable {}

    function updatePrice(string memory _symbol, uint256 _price) external {
        prices[_symbol] = _price;
        lastUpdated = block.timestamp;

        emit PriceUpdated(block.timestamp, _price, _symbol);
    }

    function updateIrBankPrice(address _ptoken, uint256 _price) external {
        irBankPrices[_ptoken] = _price;
        lastUpdated = block.timestamp;

        emit PriceIrBankUpdated(block.timestamp, _price, _ptoken);
    }


    function setCoins(string memory _symbol) external {
        coins.push(_symbol);

    }

     function popCoins() external {
        coins.pop();

    }


    function setPTokens(address _pToken) external {
        pTokens.push(_pToken);
    }


    function popPTokens() external {
        pTokens.pop();
    }


    function getPrice(string memory _symbol) external view  returns (uint256) {

        return  prices[_symbol];   

    }

    function getIrBankPrice(address _pToken) external view  returns (uint256) {

        return  irBankPrices[_pToken];   

    }

}