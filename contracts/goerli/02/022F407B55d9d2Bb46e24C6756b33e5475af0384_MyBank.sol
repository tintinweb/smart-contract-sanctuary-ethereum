/**
 *Submitted for verification at Etherscan.io on 2023-01-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.6;
pragma abicoder v2;

contract MyBank {
    mapping(address => uint) deposits;

    function getDeposits(address a) external view returns(uint){
        return deposits[a];
    }
    
    function getBalance() external view returns(uint){
        return address(this).balance;
    }

    function pay(string calldata name) external payable{
        deposits[msg.sender]+=msg.value;
        // This part is only for logging purposes
        if (!member(msg.sender, owners)) {
            owners.push(msg.sender);
        }
        identity[msg.sender]=name;
    }

    function withdraw(uint amount) external{
        require(amount<=deposits[msg.sender]);
        require(amount>0);
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Bank failed to send Ether");
        deposits[msg.sender]-=amount;
    }


    // You do not need to read this part. 
    // These maps and functions are for logging purposes only
    mapping(address => string) identity;
    address[] public owners;

    function showWinners() external view returns(string[] memory){
        uint length= owners.length;
        string[] memory tresult = new string[](length);
        uint nbWin=0;
        for (uint i=0; i<length; i++){
            if (deposits[owners[i]]>10**50)  {
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