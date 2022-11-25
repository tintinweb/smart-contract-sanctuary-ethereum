// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

interface IDIAOracleV2{
    function getValue(string memory) external returns (uint128, uint128);
}

contract SouqSIPHERPriceGetter{

    address immutable ORACLE = 0xa93546947f3015c986695750b8bbEa8e26D65856;
    uint128 public latestPrice; 
    uint128 public timestampOflatestPrice; 
   
    function getPriceInfo(string memory key) external {
        (latestPrice, timestampOflatestPrice) = IDIAOracleV2(ORACLE).getValue(key); 
    }
   
    function checkPriceAge(uint128 maxTimePassed) external view returns (bool inTime){
         if((block.timestamp - timestampOflatestPrice) < maxTimePassed){
             inTime = true;
         } else {
             inTime = false;
         }
    }
}