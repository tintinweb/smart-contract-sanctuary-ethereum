pragma solidity >=0.5.0 <0.9.0;
contract HelloWorldA {
    function get() pure public returns (string memory){
        return "Hello Contracts";
    }

    function getNothing() pure public returns (string memory){
        return "nothing";
    }
}