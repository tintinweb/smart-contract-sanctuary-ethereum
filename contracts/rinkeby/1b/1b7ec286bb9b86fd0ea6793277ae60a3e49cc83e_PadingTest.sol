/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

pragma solidity ^0.8.0;


contract PadingTest {

    uint public state = 0;

    function add(uint8 a, uint8 b) external returns (uint8) {
        state++;
        return a + b;
    }

    function compareUint8(uint8 a, uint8 b) external returns (bool) {
        state++;
        return a == b;
    }
   
    function compareAddress(address a, address b) external returns (bool) {
        state++;
        return a == b;
    }
}