/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0 
pragma solidity ^ 0.8.7 ;

contract HelloWorld {
    enum LANGUAGE {EN, FR, DE}

    string english = "Hello World";
    string french  = "Bonjour Le Monde";
    string german  = "Hallo Welt";

    function vize() public {
    }

    function sayHello(LANGUAGE lang) public view returns(string memory) {
        if(lang == LANGUAGE.EN) {
            return english;
        } else if(lang == LANGUAGE.FR) {
            return french;
        } else {
            return german;
        }
    }
}