/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.7.0 <0.9.0;

contract DomainNFT {
    address rootOwner;

    struct Domain {
        string domain;
        string[] nameserver;
    }

    mapping (address => Domain) internal myDomain;

    constructor(){
        rootOwner = msg.sender;
    }

    function addDomain(address _owner, string memory _domain, string[] memory _nameserver) external {
        require(rootOwner == msg.sender, "ROOT Owner isn't match");
        myDomain[_owner] = Domain(_domain, _nameserver);
    }

    function getRootOwner() public view returns (address) {
        return rootOwner;
    }

    function getOwnerDomain(address _owner) public view returns (Domain memory) {
        return myDomain[_owner];
    }
}