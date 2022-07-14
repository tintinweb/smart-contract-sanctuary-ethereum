/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

pragma solidity ^0.4.24;

contract Calculator2000{
    function add(int _a, int _b) public pure returns (int){
        return _a + _b;
    }
    function sub(int _a, int _b) public pure returns (int){
        return _a - _b;
    }
    function mul(int _a, int _b) public pure returns (int){
        return _a * _b;
    }
    function div(int _a, int _b) public pure returns (int){
        return _a / _b;
    }
}