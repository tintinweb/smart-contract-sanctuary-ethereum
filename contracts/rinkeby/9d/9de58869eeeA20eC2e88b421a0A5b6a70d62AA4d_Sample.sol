// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;

contract Sample {
    // string
    string public constant name = "HtH";
    string public constant str = 'Hello';

    // uint (可以宣告長度)
    uint16 public amount = 12345;

    // array uint 
    uint[12] public uint_array_1;

    // mapping
    mapping (address => uint) public balance;

    // struct
    struct car {
        address owner;
        uint price;
        string color;
    }

    // array struct
    car[] public car_list;

    // mapping struct
    mapping(address=>car) public car_list2;


    constructor() {
        // array struct 
        // car_list[0].owner = 0xD2B7b2E073A1e36326ba5d40A9f042846Ef4A4A3;
        // car_list[0].price = 12345;
        // car_list[0].color = 'blue';

        // car_list2[0xD2B7b2E073A1e36326ba5d40A9f042846Ef4A4A3].owner = 0xD2B7b2E073A1e36326ba5d40A9f042846Ef4A4A3;
        // car_list2[0xD2B7b2E073A1e36326ba5d40A9f042846Ef4A4A3].price = 1234567889;
        // car_list2[0xD2B7b2E073A1e36326ba5d40A9f042846Ef4A4A3].color ='red';

        // for (uint i = 0; index < uint_array_1.length; i++) {
        //     uint_array_1[i] = i
        // }
    }
}