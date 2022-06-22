/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; 

contract HelloWorld {

	string[] private numbers; //Array สามารถมี key ที่ไม่จำกัด  

    constructor(string[] memory initData){
    numbers = initData; //รับค่าลง Array ตอน Deploy
    }
    // Array Numbers
    function pushNumber(string memory newNumber)public{
        numbers.push(newNumber); //function ที่สามารถเพิ่มค่าลง Array ได้
    }
    function getNumber(uint256 index)public view returns(string memory){
        return numbers[index]; //แสดง List numbers ออกมา โดยที่ไม่ต้อง public numbers
    }
    function getNumberLength() public view returns(uint256){
        return numbers.length; //ประกาศความยาวของ Array
    }

}