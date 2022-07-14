/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

pragma solidity ^0.4.24;

contract Calculator2000{
    function add(uint _a, uint _b) public pure returns (uint){
        return _a + _b;
    }
    function sub(uint _a, uint _b) public pure returns (uint){
        return _a - _b;
    }
    function mul(uint _a, uint _b) public pure returns (uint){
        return _a * _b;
    }
    function div(uint _a, uint _b) public pure returns (uint){
        return _a / _b;
    }
}