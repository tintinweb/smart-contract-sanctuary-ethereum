/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

pragma solidity ^ 0.4.18 ;
contract HelloWorld {
    enum LANGUAGE {EN, FR, DE}

    string english = "Hello World";
    string french = "Bonjour Le Monde";
    string german = "Hallo Welt";

    function HelloWorld () public {
    }

    function sayHello(LANGUAGE lang) public view returns(string) {
        if (lang == LANGUAGE.EN) {
            return english;
        } else if (lang == LANGUAGE.FR) {
            return french;
        } else {
            return german;
        }
    }

}