/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

pragma solidity ^0.8.7;

contract Dervied {

    uint a;
    uint b;

    constructor(uint _a, uint _b) {
        a = _a;
        b = _b;
    }

    function get() public returns(uint,uint) {
        return (a, b);
    }
}