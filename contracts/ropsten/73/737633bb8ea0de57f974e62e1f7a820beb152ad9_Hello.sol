/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

pragma solidity >=0.8 < 0.9;

contract Hello {
    uint[] public values;
    function add(uint value) public{
        values.push(value);
    }
}