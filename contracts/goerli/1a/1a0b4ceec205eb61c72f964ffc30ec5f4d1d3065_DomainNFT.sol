/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.7.0 <0.9.0;

contract DomainNFT {
    address rootOwner;

    struct Domain {
        string domain;
        string[4] nameserver;
    }

    mapping (address => Domain) internal myDomain;

    constructor(address _rootOwner){
        rootOwner = _rootOwner;
    }

    function addDomain(address _owner, string memory _domain, string[4] memory _nameserver) external {
        require(rootOwner == msg.sender, "ROOT Owner isn't match");
        myDomain[_owner] = Domain(_domain, _nameserver);
    }

    function getOwnerDomain(address _owner) public view returns (Domain memory) {
        return myDomain[_owner];
    }
}