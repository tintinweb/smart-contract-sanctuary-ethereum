/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract HelloWorld {
    enum LANGUAGE {EN, FR, DE}
    
    string english = "Hello World";
    string french  = "Bonjour Le Monde";
    string german  = "Hallo Welt";
    
    
    function sayHello(LANGUAGE lang) public view returns(string memory) {
        if (lang == LANGUAGE.EN) {
            return english;
        } else if (lang == LANGUAGE.FR) {
            return french;
        } else {
            return german;
        }
    }
}