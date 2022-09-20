/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

pragma solidity 0.8.17;

// Defining Library
library Algebra {
    function pow(uint a, uint b) public pure returns (uint) {
        return a ** b;
    }

    function add(uint a, uint b) public pure returns (uint){
        return a+b;
    }

    function sub(uint a, uint b) public pure returns (uint){
        return a-b;
    }

    function mul(uint a, uint b) public pure returns (uint){
        return a*b;
    }

    function div(uint a, uint b) public pure returns (uint){
        return a/b;
    }

}