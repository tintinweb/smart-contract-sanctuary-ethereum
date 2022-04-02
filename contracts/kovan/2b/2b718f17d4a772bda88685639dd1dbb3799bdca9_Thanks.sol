/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

pragma solidity ^0.4.18;

contract Thanks {
    enum LANGUAGE {EN, TR, DE}
    
    string english = "Thanks";
    string turkish  = "Tesekkurler";
    string german  = "Danke";
    
    function Thanks() public {
    }
    
    function sayThanks(LANGUAGE lang) public view returns(string) {
        if (lang == LANGUAGE.EN) {
            return english;
        } else if (lang == LANGUAGE.TR) {
            return turkish;
        } else {
            return german;
        }
    }
}