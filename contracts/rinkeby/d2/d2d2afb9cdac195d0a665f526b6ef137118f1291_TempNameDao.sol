// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

abstract contract ITempNameDao {
    function getENSList() public virtual pure returns (string[] memory);
    function addEns(string memory subdomain, string memory hash) public virtual;
}

contract TempNameDao is ITempNameDao {
    string domain;
    uint totalSubdomains;
    mapping(string => string) subdomains;
    string[] subdomainArray;
    constructor() {
        domain = "domain.eth";
        totalSubdomains = 0;
    }

    function addEns(string memory subdomain, string memory hash) public override {
        subdomains[subdomain] = hash;
    }

    function getENSList() public pure override returns (string[] memory) {
        string[] memory ensString = new string[](3);
        ensString[0] = "subdomain1.hehehehehe.eth";
        ensString[1] = "subdomain2.hehehehehe.eth";
        ensString[2] = "subdomain3.hehehehehe.eth";
        return (ensString);
    }
}