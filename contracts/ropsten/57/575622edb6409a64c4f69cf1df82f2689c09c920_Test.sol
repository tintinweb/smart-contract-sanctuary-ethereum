/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

pragma solidity ^0.6.1;

contract Test {
    function fangChuanWangCalculate(uint8 arg1, uint8 arg2) public pure returns (uint8){
        return arg1 + arg2 + arg1 * arg2;
    }
}