/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.7;
contract GenerateCertificate
     {
     struct CertificateDetails
     {
         string userName;
         string courseName;
         string CertificationLevel;
         string CreatedBy;
         string authorWebLink;
         uint   creationDate;
     }
     mapping(address=>mapping(uint=>CertificateDetails)) private certificate;
     uint private uinqueId=0;
     function generateCertificate(
         string calldata _user,string calldata _courseName,string calldata _CertificationLevel,
         string calldata _CreatedBy,string calldata _authorWebLink) external returns(uint)
    {
         CertificateDetails memory myStruct=CertificateDetails
         ({
          userName:_user,
          courseName:_courseName,
          CertificationLevel:_CertificationLevel,
          CreatedBy:_CreatedBy,
          authorWebLink:_authorWebLink,
          creationDate:block.timestamp
         });
          certificate[msg.sender][uinqueId]=myStruct;
          uinqueId++;
          return uinqueId-1;
     } 
     function getYourCertificate(address _user,uint _Id) public view returns(CertificateDetails memory){
          return certificate[_user][_Id];
     }
     }