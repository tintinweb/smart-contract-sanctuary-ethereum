/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// "SPDX-License-Identifier:  MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    string public hello = "Hello World" ;

    //Nuttakit Bio
    string public fullName = "Suppharoek Jiramanon" ;
    string public nickname = "GamesTheory";

    uint256 public age = 29;

    uint256 public money = 0 ;
        
        //function
function deposit(uint256 _amount) public {
    money += 1000;
}

}