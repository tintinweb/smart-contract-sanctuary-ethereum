/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

pragma solidity 0.8.0;

contract Helloworld {

    string lastText = "Hello Li";

    function getString() public view returns(string memory){
        return lastText;
    }

    function setSTring(string memory text) public {
        lastText = text;
    }

}