/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

//SPDX-License-Identifier:GPL-3.0

pragma solidity ^0.8.0;

contract message{

    event KeepIt(address indexed from);

    mapping(string=>string) public message_data;
    string[] index;

    /*ใส่ messageidและข้อความ ใช้ messageid เข้าถึงข้อความ
    ข้อความจะถูกแช่เก็บไว้
    ตัวอย่าง(0x1232,......ข้อความอะไรก็ได้)
            ^
            ^
            จำ messageid เพื่อใช้เข้าถึงข้อความ
    */
                
    function Keep_Message(string memory MessageId,string memory Message)public{
        index.push(MessageId);
        message_data[MessageId]=Message;

        emit KeepIt(msg.sender);
    }
}