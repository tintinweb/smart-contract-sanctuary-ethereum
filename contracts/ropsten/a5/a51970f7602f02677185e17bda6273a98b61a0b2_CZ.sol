/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

pragma solidity ^0.4.26; 
contract CZ {
    function f() external pure returns (uint256)  {
        return g(8) ;    // simply passing an integer to another function
    }
    function g(uint x)  public pure returns (uint256)
    {uint b = x ;
        return b;
    }
}