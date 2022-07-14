/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

pragma solidity ^0.4.24;

contract Calculator{
    function getResult(uint _a, uint _b) public pure returns (uint){
        return _a + _b;
    }
}