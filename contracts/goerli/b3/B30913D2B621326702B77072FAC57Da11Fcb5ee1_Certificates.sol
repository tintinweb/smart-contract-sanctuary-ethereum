/**
 *Submitted for verification at Etherscan.io on 2023-03-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Certificates {
  address admin;

  constructor() {
    admin = msg.sender;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, 'Unauthorized');
    _;
  }

  struct CertificateDetails {
    string certificateId;
    string name;
    string certificateFor;
    string date;
  }

  mapping(string => CertificateDetails) public Certificate;

  function generateCertificate(
    string memory _certificateId,
    string memory _name,
    string memory _certificateFor,
    string memory _date
  ) public onlyAdmin {
    Certificate[_certificateId] = CertificateDetails(
      _certificateId,
      _name,
      _certificateFor,
      _date
    );
  }
}