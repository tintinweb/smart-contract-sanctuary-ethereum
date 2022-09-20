pragma solidity ^0.5.0;
contract helloWorld {   
    constructor() public{

    }

    function print () public pure returns (string memory) {       
        return 'Hello World! First Simple Smart Contract';             
    } 
}