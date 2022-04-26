/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract EducCer {
    struct Certificate{
        string name;
        string branch;
        string faculty;
        string university;
        string hash;
        uint index;
    }

    mapping(string => Certificate) private certificates;
    string[] private cerIndex;

    function insertCertificate(string memory  sn,string memory  _name, string memory  _branch, string memory  _faculty, string memory  _university, string memory  _hash) public {
        certificates[sn].name = _name;
        certificates[sn].branch = _branch;
        certificates[sn].faculty = _faculty;
        certificates[sn].university = _university;
        certificates[sn].hash = _hash;
        cerIndex.push(sn);
        certificates[sn].index = cerIndex.length - 1;
    }

    function getCertificate(string memory sn) view public returns (string memory, string memory, string memory, string memory, string memory,uint){
        require(keccak256(abi.encodePacked(cerIndex[certificates[sn].index])) == keccak256(abi.encodePacked(sn)), "Certificate Not Found");
        
        return (certificates[sn].name, certificates[sn].branch, certificates[sn].faculty, certificates[sn].university, certificates[sn].hash, certificates[sn].index);
    }


    function revokeCertificate(string memory sn) public
    {
        require(keccak256(abi.encodePacked(cerIndex[certificates[sn].index])) == keccak256(abi.encodePacked(sn)), "Certificate Not Found");
        
        uint rowToDelete = certificates[sn].index;
        string memory keyToMove = cerIndex[cerIndex.length-1];
        cerIndex[rowToDelete] = keyToMove;
        certificates[keyToMove].index = rowToDelete; 
        cerIndex.pop();
    }

 /*   function getUser()view public returns(string[] memory)
    {
        return cerIndex;
    }

    function getUserLen()view public returns(uint)
    {
        return cerIndex.length;
    }
    */
}