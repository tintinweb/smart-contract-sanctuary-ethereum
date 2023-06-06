/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

contract gcitCert {
    struct Certificate {
        string gcitCertId;
        string title;
        string date;
        address issuer;
        uint cgpa;
        string start;
        string end;
        uint duration;
    }
    
    mapping(string => Certificate) private certificates;
    mapping(address => string[]) private userCertificates;
    
    function addgcitCert(
        address _user,
        string memory _gcitCertId, 
        string memory _title,
        string memory _date, 
        address _issuer, 
        uint _cgpa, 
        string memory _start, 
        string memory _end, 
        uint _duration
    ) public {
        require(msg.sender == address(0x9dC22219076ef89d9E0a6248F18B3582Ea7A93dB), "Only the authorized issuer can add certificates");
        
        Certificate memory newCertificate = Certificate({
            gcitCertId: _gcitCertId,
            title: _title,
            date: _date,
            issuer: _issuer,
            cgpa: _cgpa,
            start: _start,
            end: _end,
            duration: _duration
        });
        
        certificates[_gcitCertId] = newCertificate;
        userCertificates[_user].push(_gcitCertId);
    }
    
    function verifygcitCert(string memory _gcitCertId) public view returns (bool) {
        return bytes(certificates[_gcitCertId].gcitCertId).length != 0;
    }
    
    function getListOfgcitCert(address _user) public view returns (Certificate[] memory) {
        string[] memory certificateIds = userCertificates[_user];
        Certificate[] memory userCertList = new Certificate[](certificateIds.length);
        
        for (uint i = 0; i < certificateIds.length; i++) {
            userCertList[i] = certificates[certificateIds[i]];
        }
        
        return userCertList;
    }
}