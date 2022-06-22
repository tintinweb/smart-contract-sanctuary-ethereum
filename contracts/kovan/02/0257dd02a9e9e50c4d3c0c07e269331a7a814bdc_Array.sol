/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract Array{

    uint256[] private numbers;
    constructor(uint256[] memory initData){
        numbers = initData; //รับค่าลง Array ตอน Deploy
    }
    //Array Numbers
    function pushNumber(uint256 newNumber) public {
        numbers.push(newNumber); //function ที่สามารถเพิ่มค่าลง Array ได้ โดยสามารถ push ได้ทีละ 1 ค่า
    }
    function getNumber(uint256 index) public view returns(uint256){
        return numbers[index]; ////แสดง List numbers ออกมา โดยที่ไม่ต้อง public numbers
    }
    function getNumberLength() public view returns (uint256){
        return numbers.length; //ประกาศความยาวของ Array
    }
}