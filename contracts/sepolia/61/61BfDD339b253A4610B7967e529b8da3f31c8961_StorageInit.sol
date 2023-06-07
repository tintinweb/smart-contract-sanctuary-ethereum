// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract StorageUnint {
    uint public magic_number;
    string public magic_string;
    address public magic_address;
    bool public magic_bool;
    int public magic_int;
}

contract StorageInit {
    uint public magic_number = 42;
    string public magic_string = "Hello World";
    address public magic_address = 0x000000000000000000000000000000000000dEaD;
    bool public magic_bool = true;
    int public magic_int = -42;

}