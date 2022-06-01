/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// File: contracts/A.sol



pragma solidity >=0.7.0 <0.9.0;

contract A {
    function test() public pure returns (uint) {
        return 0;
    } 
}

// File: contracts/B.sol



pragma solidity >=0.7.0 <0.9.0;


contract B is A {
    function test2() public pure returns (uint) {
        return 1;
    }
}