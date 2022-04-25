/**
 *Submitted for verification at Etherscan.io on 2022-04-23
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
        string status;
    }

    mapping(string => Certificate) certificates;

    function setCertificate(string memory  sn,string memory  _name, string memory  _branch, string memory  _faculty, string memory  _university, string memory  _hash, string memory  _status) public {
        certificates[sn] = Certificate(_name, _branch, _faculty, _university, _hash, _status);
    }

    function getCertificate(string memory  sn) view public returns (string memory, string memory, string memory, string memory, string memory, string memory){
       // require(certificates[sn].isCheck, "Certificate is not create");

        return (certificates[sn].name, certificates[sn].branch, certificates[sn].faculty, certificates[sn].university, certificates[sn].hash, certificates[sn].status);
    }


    function setCertificateStatus(string memory  sn, string memory  _status) public {
       // require(certificates[sn].isCheck, "Certificate is not create");
        
        certificates[sn].status = _status;
    }
}