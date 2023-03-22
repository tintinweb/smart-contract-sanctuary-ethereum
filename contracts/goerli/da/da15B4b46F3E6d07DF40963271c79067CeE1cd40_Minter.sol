/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
pragma solidity 0.8.0;
contract Minter{
    uint public count;
    struct stu{
        uint id;
        address Addr;
    }

    mapping(address=>stu)public stuData;
    function safeMInt()public {
        stu memory stu2=stuData[msg.sender];
        require(stu2.Addr != msg.sender,"already registered");
        uint _id=count++;
        require(stu2.id != _id,"already registered1");
        stuData[msg.sender] =stu({id:_id,Addr:msg.sender});
    }
    function getdata()public view returns(stu memory )
    {
    for(uint i=0;i<count;i++)
    {
    return stuData[msg.sender];
    } 
    }
    function deldata()public{
        delete stuData[msg.sender];
    }
}