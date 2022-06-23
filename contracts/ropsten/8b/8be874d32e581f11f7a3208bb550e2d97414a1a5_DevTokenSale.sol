/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;



contract DevTokenSale {
    // address of admin
    address payable public  admin;
    // define the instance of DevToken

    // token price variable
    uint256 public tokenprice;
    // count of token sold vaariable
    uint256 public totalsold; 
     
    event Sell(address sender,uint256 totalvalue); 
   
    // constructor 
   
    // buyTokens function
    function buyTokens() public payable{
    // check if the contract has the tokens or notmsg
    require(address(this).balance <= 10 ether, 'the smart contract dont hold the enough tokens');
    require(msg.value >= .1 ether, 'Not enough BNB');
    require(msg.value <= 2 ether, 'Too much BNB');
    // transfer the token to the user
 
    // increase the token sold
    totalsold += msg.value*tokenprice;
    // emit sell event for ui
     emit Sell(msg.sender, msg.value*tokenprice);
    }

    // end sale
    function endsale() public{
    // check if admin has clicked the function
    require(msg.sender == admin , ' you are not the admin');
    // transfer all the remaining tokens to admin
    
    // transfer all the etherum to admin and self selfdestruct the contract
    selfdestruct(admin);
    }
}