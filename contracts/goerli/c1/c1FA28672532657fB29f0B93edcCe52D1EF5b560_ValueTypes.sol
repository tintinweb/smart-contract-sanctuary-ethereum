/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

pragma solidity ^0.8.18;

contract ValueTypes {
    bool public boo = true;

    uint8 public u8 = 1;
    uint public u256 = 456;
    uint public u = 123;

    int8 public i8 = -1;
    int public i256 = 456;
    int public i = -123;

    int public minInt = type(int).min;
    int public maxInt = type(int).max;

    address public addr = 0x0D350528C4F4b8EC5E82524F71fc160a7E286A94;

    bytes1 a = 0xb5; //  [10110101]
    bytes1 b = 0x56; //  [01010110]
}