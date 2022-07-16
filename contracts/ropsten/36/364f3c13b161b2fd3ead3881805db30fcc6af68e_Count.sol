/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

pragma solidity ^0.8.7;
contract Count{
    uint public total = 0;
    constructor(){

    }
    function add() external returns(uint) {
        total++;
        return total;
    }
    function sub() external returns(uint) {
        total--;
        return total;
    }
}