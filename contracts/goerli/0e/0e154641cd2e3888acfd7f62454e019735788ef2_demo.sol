/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
contract demo{
    struct userDetailsStruct
    {
        address user;
        uint num;
        uint ID;
    }

    mapping(address=>userDetailsStruct) public userDetails;

    userDetailsStruct[] public arr;
    
    // userDetailsStruct[] public arr1;
    
    function setDetails(uint _num,uint _ID) public
    {
        userDetails[msg.sender].num=_num;
        userDetails[msg.sender].ID=_ID;
        userDetails[msg.sender].user=msg.sender;
        arr.push(userDetails[msg.sender]);
    }
    function getDetails(address _user) public view returns( userDetailsStruct memory)
    {
        for(uint i = 0; i<arr.length ; i++)
    {
        if(_user==arr[i].user){
            return arr[i];
    }
    }
    
    }
    }