/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;


contract TestArray{
    string[] nameArray;

    function getArrayLength() public view returns(uint){
        return nameArray.length;
    }

    function findNameToNumber(uint number) public view returns(string memory){
        number = number == 0 ? 0 : nameArray.length - 1;
        return nameArray[number];
    }
    function pushName(string memory name) public{
        nameArray.push(name);
    }
    

}