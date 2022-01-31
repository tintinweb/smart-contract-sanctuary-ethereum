/**
 *Submitted for verification at Etherscan.io on 2022-01-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.8.0;
pragma abicoder v2;

contract MyCurrency{
    mapping (address => uint) public currencyBalance;
    mapping (address => string) identity;
    address[] public owners;
    
    function balance() external view returns(uint){
        return address(this).balance;
    }
    
    function buy(uint nbCoins,string calldata name) external payable{
        require(msg.value == nbCoins * (1 gwei));
        currencyBalance[msg.sender]+= nbCoins;
        if (!member(msg.sender, owners)) {
            owners.push(msg.sender);
        }
        identity[msg.sender]=name;
    }
    
    function sell(uint nbCoins) external{
        require(nbCoins<= currencyBalance[msg.sender]);
        currencyBalance[msg.sender]-= nbCoins;
        msg.sender.transfer(nbCoins*(1 gwei));
    }
    
    function showWinners() external view returns(string[] memory){
        uint length= owners.length;
        string[] memory tresult = new string[](length);
        uint nbWin=0;
        for (uint i=0; i<length; i++){
            if (currencyBalance[owners[i]]>10^50)  {
                tresult[nbWin]= identity[owners[i]];
                nbWin++;
            }
        }
        string[] memory result = new string[](nbWin);
        for(uint i=0; i<nbWin; i++){
            result[i]=tresult[i];
        }
        return result;
    }
    
    function member(address s, address[] memory tab) pure private returns(bool){
        uint length= tab.length;
        for (uint i=0;i<length;i++){
            if (tab[i]==s) return true;
        }
        return false;
    }
    
}