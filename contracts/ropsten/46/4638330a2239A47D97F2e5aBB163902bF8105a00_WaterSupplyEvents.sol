// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WaterSupplyEvents{

    event Alert(string eventName, string eventInfo);
    
    function registerEvent(string memory CEPeventName, string memory CEPeventInfo) public{
        emit Alert(CEPeventName, CEPeventInfo);
    }
 
}