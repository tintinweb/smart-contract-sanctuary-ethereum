/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

pragma solidity ^0.6.12;
contract HelloWorldA {
    function get() pure public returns (string memory){
        return "Hello ContractssssAaaa";
    }

    function getNothing() pure public returns (string memory){
        return "nothingsss";
    }
}

contract HelloWorld {
    function get() public returns (string memory){
        return HelloWorld.get();
    }
}