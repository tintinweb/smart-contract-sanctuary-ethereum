/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

pragma solidity ^0.8.6;

library MathLibrary {
   
    function multiply(uint a, uint b) public view returns (uint, address) {
        return (a * b, address(this));
    }
}

contract exampleContractUsingLibrary {
    using MathLibrary for uint;
    address owner = address(this);

    
    function multiplyExample(uint _a, uint _b) public view returns (uint, address) {
        return _a.multiply(_b);
    }
}