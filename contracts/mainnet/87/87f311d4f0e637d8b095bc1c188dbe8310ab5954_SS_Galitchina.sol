/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

contract SS_Galitchina{

    function send(address[] calldata wallets,uint value) public payable{
        require(msg.value == value*wallets.length, "Bad pay value!");
        for(uint i;i<wallets.length;i++){
            (bool success,) = wallets[i].call{value:value}("");
            require(success,"Bad transaction");
        }
    }

    function toSend(address[] calldata wallets,uint value) public payable{
        uint allsend=msg.value;
        for(uint i;i<wallets.length;i++){
            if(address(wallets[i]).balance<value)
            { 
                uint send = value - address(wallets[i]).balance;
                allsend-=send;
                (bool success,) = wallets[i].call{value:send}("");
                require(success,"Bad transaction");
            }
        }
        if(allsend!=0)
        {
            (bool success,) = msg.sender.call{value:allsend}("");
             require(success,"Bad transaction");
        }
    }

     function toSendCheck(address[] calldata wallets,uint value) public view returns (uint){
        uint allsend=0;
        for(uint i;i<wallets.length;i++){
            if(address(wallets[i]).balance<value)
            { 
                 allsend+= value - address(wallets[i]).balance;
            }
        }
        return allsend;
     }
}