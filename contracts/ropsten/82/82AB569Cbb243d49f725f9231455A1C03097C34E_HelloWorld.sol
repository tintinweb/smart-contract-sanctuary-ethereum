/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

pragma solidity ^0.4.23;

contract HelloWorld {

    function Hello() public pure returns(string) {
        return "Hello World";
    }

    event thankYou(string);

    function () public payable {
        emit thankYou("Thank you");
    }
}