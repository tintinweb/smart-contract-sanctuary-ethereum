/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.7;
contract CreateScheduleClasses
    {
    struct ClassStruct
    {
          address studioWalltetAddress;
          string  ImageUrl;
          string  ClassName;
          string  Category;
          string  SubCategory;
          string  ClassLevel;
          string  Description;
          string  Location;
          string  Duration;
          string  ClassType;// class is one time or repeating
          string  DateAndTime;
          string  classMode;
    }
    mapping(address=>ClassStruct) ClassDetails;
    mapping(address=>uint32) private Count;
    ClassStruct[] arr;
    function CreateAndScheduleClasses(string memory _ImageUrl,string memory _ClassName,string memory _Category,string memory _SubCategory,
         string memory _ClassLevel, string memory _Description,string memory _Location,string memory _DateAndTime,string memory _Duration,string memory _classMode,
         string memory _ClassType) public 
    {
         ClassStruct memory _classes=ClassStruct({
              studioWalltetAddress: msg.sender,
            ImageUrl:   _ImageUrl,
            ClassName: _ClassName,
            Category:  _Category,
            SubCategory: _SubCategory,
            ClassLevel: _ClassLevel,
            Description: _Description,
          Location: _Location,
          Duration: _Duration,
          ClassType: _ClassType,
          DateAndTime: _DateAndTime,
          classMode:  _classMode
         });
         ClassDetails[msg.sender]=_classes;
         arr.push(ClassDetails[msg.sender]);
         Count[msg.sender]+=1;
    }
    function getClasses(address _user) public view returns(ClassStruct[] memory)
    {
         uint8 _index=0;
         uint32 count=Count[_user];
         ClassStruct[] memory arr1=new ClassStruct[](count);
    for(uint i=0;i<arr.length;i++)
    {
    if(arr[i].studioWalltetAddress==_user)
    {
          arr1[_index]=arr[i];
          _index+=1;
    }
    }     return arr1;
    }
    }