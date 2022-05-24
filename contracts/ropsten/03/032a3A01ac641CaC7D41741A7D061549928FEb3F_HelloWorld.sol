// My First Smart Contract 
pragma solidity ^0.8.3;
contract HelloWorld {
    function get()public pure returns (string memory){
        return 'Hello Contracts';
    }
}