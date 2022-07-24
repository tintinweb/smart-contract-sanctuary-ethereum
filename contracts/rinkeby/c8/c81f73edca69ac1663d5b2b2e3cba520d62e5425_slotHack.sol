/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// SPDX-License-Identifier: UNLICENSED
//Author : 0xNezha
//Twitter : https://twitter.com/0xNezha
//Github : https://github.com/0xNezha


pragma solidity ^0.8.15;
contract slotHack {
    // uint256长度为32字节，每个变量占用一个 slot
    uint256 public  count_A = 0x2560A0256;     // slot 0
    uint256 public  count_B = 0x2560B0256;     // slot 1
    uint256 private count_C = 0x2560C0256;     // slot 2

    // 以下几个变量长度加一起也不足32字节，所以共同占用一个 slot
    uint128 private count_128 = 0x128FFFFFFFFFFFFFFFFFFFFFFFFFF128; //slot 3
    uint64  private count_64  = 0x64FFFFFFFFFFFF64;                 //slot 3
    uint32  private count_32  = 0x32FFFF32;                         //slot 3
    uint16  private count_5   = 0x1616;                             //slot 3
    uint8   public  count_6   = 0x88;                               //slot 3

   // 以下几个变量加一起也不足32字节，同样也是共同占用一个slot (address 20字节，bool 1 字节)
    address public owner = msg.sender;    //slot 4 
    bool private isOpen1 = true;          //slot 4 
    bool private isOpen2 = true;          //slot 4 
    bool private isOpen3 = true;          //slot 4 
    bool private isOpen4 = true;          //slot 4 
    bool private isOpen5 = true;          //slot 4 

    // constant 常量不放在存储槽中，而是硬编码在代码里，所以不占用slot
    uint256 public constant fixed_num = 0xC1; 

    // 没有初始化的变量，仍然按各自的顺序和长度占用 slot ，但里面没有存储数据
    bytes32    private secret_num;     // slot 5
    bytes32[3] private secret_data;     // slot 6 ~ 8
    mapping(uint256 => uint256) public  item_1;          // slot 9
    mapping(uint256 => uint256) private item_2;          // slot 10 [十六进制是 slot 0xa ]

    constructor() payable {
      set_item_2(12345);
    }

    function set_count_A(uint256 _value)  public {
      count_A = _value;
    }
    function set_item_1()  public {
      item_1[0xC0FFEE] = 0x123456;
    }
    function set_item_2(uint256 _value)  public {
      item_2[count_A] = _value;
    }

    function guess_item_2(uint256 _guessValue) public view returns(string memory){       
       require(item_2[count_A] != 0, "The value has not been set.");
       if (item_2[count_A] < _guessValue) {
        return "Greater than the value";
        }else
       if (item_2[count_A] > _guessValue) {
        return "Less than the value";
        }else
        if (item_2[count_A] == _guessValue) {
        return "YOU WIN! Equal to the value";
        }else{
          return "Error";  
        }
    }
}