// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract FunTypes {
    // Integers     
    // Can go from 8 up to 256 bits
    int _int; // int is alias for int256
    uint _uint; // uint is alias for uin256
    

    // Booleans
    bool _flag1;

    // Fixed Point Numbers
    // Keywords ufixedMxN and fixedMxN, where M represents the number of bits taken by the type and N represents how many decimal points are available. 
    // M must be divisible by 8 and goes from 8 to 256 bits. N must be between 0 and 80, inclusive.
    fixed _fixed; // alias for fixed128x18 
    ufixed _ufixed; // alias for ufixed128x18 

    // Address
    address _address; // Holds a 20 byte value (size of an Ethereum address).
    address payable _addressPayable; // Same as address, but with the additional members transfer and send.

    // Fixed-size byte arrays
    bytes1[] _bytes1; // The value types bytes1, bytes2, bytes3, …, bytes32 hold a sequence of bytes from one to up to 32.

    // Dynamically-sized byte arrayy
    bytes _bytes; // Dynamically-sized byte array
    string _string; // Dynamically-sized UTF-8-encoded string
    
}