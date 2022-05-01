/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

contract TradingLimit {

    uint cash;
    uint totalBuy;
    uint totalSell;
    uint fees;
    uint t1;
    uint t2;
    int tradingLimit;

    function getCash() public view returns (uint) {
        return cash;
    }

    function setCash(uint _cash) public {
        //console.log("Changing cash from '%s' to '%s'", cash, _cash);
        cash = _cash;
    }

    function getTotalBuy() public view returns (uint) {
        return totalBuy;
    }

    function setTotalBuy(uint _totalBuy) public {
        //console.log("Changing total buy from '%s' to '%s'", totalBuy, _totalBuy);
        totalBuy = _totalBuy;
    }

    function getTotalSell() public view returns (uint) {
        return totalSell;
    }

    function setTotalSell(uint _totalSell) public {
        //console.log("Changing total sell from '%s' to '%s'", totalSell, _totalSell);
        totalSell = _totalSell;
    }

   function getFees() public view returns (uint) {
        return fees;
    }

    function setFees(uint _fees) public {
        fees = _fees;
    }

    function getT1() public view returns (uint) {
        return t1;
    }

    function setT1(uint _t1) public {
        //console.log("Changing T1 from '%s' to '%s'", t1, _t1);
        t1 = _t1;
    }

    function getT2() public view returns (uint) {
        return t2;
    }

    function setT2(uint _t2) public {
        //console.log("Changing T2 from '%s' to '%s'", t2, _t2);
        t2 = _t2;
    }

    function setTradingLimit() public {
        uint totalFees = (totalSell + totalBuy) * fees / 10000;
        int t0 = int(totalSell - totalBuy - totalFees);
        tradingLimit = (int(cash) + t0 + int(t1) + int(t2));
    }

    function getTradingLimit() public view returns (int) {
        return tradingLimit;
    }
    
}