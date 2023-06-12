/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISTETH {
   
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);
}

interface IRETH {

    function getExchangeRate() external view returns (uint256);
}

interface IsfrxETH {

    function  convertToAssets(uint256 _sharesAmount) external view returns (uint256);
}

contract EthPriceFeed {
    ISTETH public stEthContract;
    IRETH public rEthContract;
    IsfrxETH public sfrxETHContract;
    mapping(uint =>  function () view returns (uint256)) funcMap;

    constructor(address _stEthContract, address _rEthContract, address _sfrxETH) {
        stEthContract = ISTETH(_stEthContract);
        rEthContract = IRETH(_rEthContract);
        sfrxETHContract = IsfrxETH(_sfrxETH);
        funcMap[0] = getPooledEthByShares;
        funcMap[1] = getREthExchangeRate;
        funcMap[2] = getsfrxEthExchangeRate;
    }


    function getPooledEthByShares() public view returns (uint256) {
        return stEthContract.getPooledEthByShares(1e18);
    }

    function getREthExchangeRate() public view returns (uint256) {
        return rEthContract.getExchangeRate();
    }

    function getsfrxEthExchangeRate() public view returns (uint256) {
        return sfrxETHContract.convertToAssets(1e18);
    }

    function getPrice(uint id) public view returns (uint256) {
        return funcMap[id]();
    }

}