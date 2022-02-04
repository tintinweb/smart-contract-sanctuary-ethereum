/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

pragma solidity ^0.4.18;
contract hello {
    string greeting;

    function hello(string _greeting) public {
        greeting = _greeting;
    }

    function say() constant public returns (string) {
        return greeting;
    }
}