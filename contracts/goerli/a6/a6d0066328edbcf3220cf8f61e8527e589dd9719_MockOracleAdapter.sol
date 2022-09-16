/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

/*

    Copyright 2021 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;

interface IOracle {
    function getPrice(address base) external view returns (uint256 latestPrice,bool isValid,bool isStale,uint256 timestamp);    

    function prices(address base) external view returns (uint256);
    
    function isFeasible(address base) external view returns (bool); 
}

interface IWooracle {
    function timestamp() external view returns (uint256);
    function isFeasible(address base) external view returns (bool);
    function getPrice(address base) external view returns (uint256);
    function price(address base) external view returns (uint256 priceNow, bool feasible);
}

contract MockOracleAdapter is IOracle {
    uint256 price;

    function setPrice(uint256 p) public {
        price = p;
    }

    function getPrice(address base) external override view returns (uint256 latestPrice,bool isValid,bool isStale,uint256 timestamp) {
        latestPrice = price;
        isValid = true;
        isStale = !isValid;
        timestamp = block.timestamp;
        return (latestPrice, isValid, isStale, timestamp);
    }    

    function prices(address base) external override view returns (uint256) {
        return price;
    }
    
    function isFeasible(address base) external override view returns (bool) {
        return true;
    }
}