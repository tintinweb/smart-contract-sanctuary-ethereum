/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
    uint id;
    string name;
    string certificateFor;
    string date;
  }

  mapping(uint => CertificateDetails) public Certificate;

  function generateCertificate(
    uint _id,
    string memory _name,
    string memory _certificateFor,
    string memory _date
  ) public onlyAdmin {
    Certificate[_id] = CertificateDetails(_id, _name, _certificateFor, _date);
  }
}