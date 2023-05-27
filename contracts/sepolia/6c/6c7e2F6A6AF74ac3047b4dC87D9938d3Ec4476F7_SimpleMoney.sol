// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract SimpleMoney
{
    mapping(address=>uint)public ledger;
        function deposit()external payable 
        {
            ledger[msg.sender]+=msg.value;
        }

        function withdraw(uint amt)external
         {
             require(amt!=0,"make sure amount is not zero");
             require(amt<=ledger[msg.sender],"insuffiecient balance");
             //uint sendable=amt > ledger[msg.sender]?ledger[msg.sender]:amt;
             ledger[msg.sender]-=amt;
             payable (msg.sender).transfer(amt);
         }
}