// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract MyContract {
    
    bytes32 public my_bytes32;
    bytes1 public my_bytes1; 
    bytes public my_bytes;
    //一個十六進位是 4 個 bit，8 個 bytes 可以放 16 個 16進位的字符
    // 前導的 "0x" 只是符號表示這是一個十六進位的格式，不具其他意義。
    // bytes32 可以表示 256 個 bits，常用於存放 block hash (sha-256)
    // bytes 是位元組陣列，可以輸入任意位數的十六進位字元。預設值是 "0x"

    function set_bytes32(bytes32 _bytes32) public {
        my_bytes32 = _bytes32;
    }

    function set_bytes1(bytes1 _bytes1) public {
        my_bytes1 = _bytes1;
    }

    function set_bytes(bytes memory _bytes) public {
        my_bytes = _bytes;
    }
}