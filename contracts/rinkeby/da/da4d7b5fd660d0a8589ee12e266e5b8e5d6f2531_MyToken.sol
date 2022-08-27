/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract MyToken{

    address public contractOwner;
    mapping(address=>uint) public balance;
     constructor(){
         contractOwner=msg.sender;
     }
     function addToken(address whoAddToken, uint noOfTokens)public{
         require(contractOwner==msg.sender);
         balance[whoAddToken]+=noOfTokens;

     }
     function send(address rec, uint amount) public{
         require(amount<=balance[msg.sender],"Insufficient amount");
         balance[msg.sender]-=amount;
         balance[rec]+=amount;
     }

    

}