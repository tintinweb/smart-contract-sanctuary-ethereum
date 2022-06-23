/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract IntegrityChecker {

  address public owner;
  address[] public authorizedWallets;
  mapping(bytes32 => bytes32) public certifications;

  constructor() {
    owner = msg.sender;
    authorizedWallets.push(msg.sender);
  }

  modifier onlyAuthorized {
    bool isAuthorized = false;
    for(uint i=0; i < authorizedWallets.length; i++) {
      if(authorizedWallets[i] == msg.sender) {
        isAuthorized = true;
        _;
      }
    }
    if(!isAuthorized){
      revert("only authorized");
    }
  }

  modifier onlyOwner {
    require(msg.sender == owner, "only owner");
    _;
  }

  function setCertification(bytes32 _uuid, bytes32 _hash) external onlyAuthorized {
    require(certifications[_uuid] == 0, "duplicate key error");
    certifications[_uuid] = _hash;
  }

  function getCertification(bytes32 _uuid) external view returns(bytes32) {
    return certifications[_uuid];
  }

  function addAuthorizedWallet(address authorizedAddress) external onlyOwner {
    authorizedWallets.push(authorizedAddress);
  }

  function removeAuthorizedWallet(address authorizedAddress) external onlyOwner {
    for(uint i=0; i < authorizedWallets.length; i++) {
      if(authorizedWallets[i] == authorizedAddress) {
        authorizedWallets[i] = authorizedWallets[authorizedWallets.length - 1];
        authorizedWallets.pop();
        return;
      }
    }
  }
}