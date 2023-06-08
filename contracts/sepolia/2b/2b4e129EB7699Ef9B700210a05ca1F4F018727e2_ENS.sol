/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

pragma solidity ^0.8.0;

contract ENS {
    mapping(string => address) private ensRegistry;
    mapping(address => string) private reverseRegistry;

    function register(string memory subdomain, address owner) public {
        require(ensRegistry[subdomain] == address(0), "Subdomain already registered");
        ensRegistry[subdomain] = owner;
        reverseRegistry[owner] = subdomain;
    }

    function resolve(string memory subdomain) public view returns (address) {
        return ensRegistry[subdomain];
    }

    function reverseResolve(address owner) public view returns (string memory) {
        return reverseRegistry[owner];
    }
}