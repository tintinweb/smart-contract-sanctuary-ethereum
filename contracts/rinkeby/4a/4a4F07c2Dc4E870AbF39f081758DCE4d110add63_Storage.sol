/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Storage{
    event PotholeAdded(string id,address reporter);
    event PotholeFixed(string id,address fixer);
    event IpfsImagehashAdded(uint256 id, address reporter,string image);
    struct Position{
        uint256 preLat;
        uint256 postLat;
        uint256 preLong;
        uint256 postLong;
        string city;
        string reprotedArea;
        string reportedRoad;
    }
    struct Pothole{
        address reportedBy;
        string reportedTime;
    }
    struct Proof{
        address user;
        address official;
        string _userImage;
        string _officialsImage;
        bool _isFixed;
    }
    mapping (string => Pothole) _potholes;
    mapping (string => Position) _positions;
    mapping (string => Proof) _proofs;
    function addPotholeUser(string memory id,uint256 prelatitude,uint256 postLatitude,
    uint256 preLongitude,uint256 postLongitude,string memory time,string memory city,string memory area,string memory road,string memory hash)public{
        Position memory position = Position(prelatitude,postLatitude,preLongitude,postLongitude,city,area,road);
        Pothole memory pothole = Pothole(msg.sender,time);
        Proof memory proof = Proof(msg.sender,address(0),hash,"",false);
        _positions[id] = position;
        _potholes[id] = pothole;
        _proofs[id] = proof;
        emit PotholeAdded(id,msg.sender);
       
    }
    function fixPotholeOfficial(string memory id,string memory hash)public {
        _proofs[id]._isFixed = true;
        _proofs[id]._officialsImage = hash;
        _proofs[id].official = msg.sender;
        emit PotholeFixed(id,msg.sender);

    }
    function getPothole(string memory id)public view returns(Pothole memory,Position memory,Proof memory){
        return (_potholes[id],_positions[id],_proofs[id]);
    }
    
    
}