/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract RegisterObject {
  struct objectInformation {
    uint registerNumber;
    uint originObjectNumber;
    string objectName;
    string objectInformation;
    string objectCost;
    string objectOwner;
    string registerTime;
  }

  // key : objectNumber
  mapping(uint => objectInformation) objectInfo;

  // Setting object informations when client register Item
  function setObjectInfo(uint _registerNumber, uint _originObjectNumber, string memory _objectName, string memory _objectInformation, string memory _objectCost, string memory _objectOwner, string memory _registerTime) public {
    
    objectInformation storage obj = objectInfo[_registerNumber];

    obj.registerNumber = _registerNumber;
    obj.originObjectNumber = _originObjectNumber;
    obj.objectName = _objectName;
    obj.objectInformation = _objectInformation;
    obj.objectCost = _objectCost;
    obj.objectOwner = _objectOwner;
    obj.registerTime = _registerTime;

  }

  // Getting object information when clien require
  function getObjectInfo(uint _registerNumber ) public view returns (uint, uint, string memory, string memory, string memory, string memory, string memory){
    return (objectInfo[_registerNumber].registerNumber, objectInfo[_registerNumber].originObjectNumber, objectInfo[_registerNumber].objectName, objectInfo[_registerNumber].objectInformation, objectInfo[_registerNumber].objectCost, objectInfo[_registerNumber].objectOwner, objectInfo[_registerNumber].registerTime);
  }
}