/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

struct Certificate{
    uint index;
    string certificateNumber;
    string certificateName;
    string certificateHash;
    string receiverName;
    uint dateOfAchievement;
    address issuerAddress;
    bool isValue;
}

contract DigitalCertificate{

    mapping(string => Certificate) private certificateMap;
    uint8 public countCertificateArray=0;
    Certificate [] public certificateArray;

    event AddNewCertificate(string  certificateNumber,string  certificateName,string  certificateHash,string  receiverName,uint dateOfAchievement,address issuerAddress);

    function addCertificate(string memory certificateNumber,string memory certificateName,string memory certificateHash,string memory receiverName,uint dateOfAchievement)public {
        require(!certificateMap[certificateNumber].isValue,"current certificateNumber is already exists.");
        certificateArray.push(Certificate(countCertificateArray,certificateNumber,certificateName,certificateHash,receiverName,dateOfAchievement,msg.sender,true));
        certificateMap[certificateNumber]=certificateArray[countCertificateArray];
        countCertificateArray++;
        emit AddNewCertificate(certificateNumber,certificateName,certificateHash,receiverName,dateOfAchievement,msg.sender);
    }

    function infoCertificate(string memory certificateNumber)public view returns(string memory ,string memory,string memory,string memory,uint,address){
        if(!certificateMap[certificateNumber].isValue) return ("Not Found this Certificate Number","Not Found this Certificate Number","Not Found this Certificate Number","Not Found this Certificate Number",0,0x0000000000000000000000000000000000000000); 
        Certificate storage thisCertificate= certificateMap[certificateNumber];
        return (thisCertificate.certificateNumber,thisCertificate.certificateName,thisCertificate.certificateHash,thisCertificate.receiverName,thisCertificate.dateOfAchievement,thisCertificate.issuerAddress);
    }


    function isValid(string memory certificateNumber,string memory certificateName,string memory certificateHash,string memory receiverName,uint dateOfAchievement)public view returns(bool) {
        Certificate storage thisCertificate= certificateMap[certificateNumber];
        if(thisCertificate.isValue!=true) return false;
        else if(keccak256(bytes(thisCertificate.certificateName))!=keccak256(bytes(certificateName))) return false;
        else if(keccak256(bytes(thisCertificate.certificateHash))!=keccak256(bytes(certificateHash))) return false;
        else if(keccak256(bytes(thisCertificate.receiverName))!=keccak256(bytes(receiverName))) return false;
        else if(thisCertificate.dateOfAchievement!=dateOfAchievement) return false;
        else return true;
    }
}