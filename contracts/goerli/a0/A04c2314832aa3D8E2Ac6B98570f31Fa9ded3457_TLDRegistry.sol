/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TLDRegistry {

// Event to notify other users of a TLD registration
event TLDRegistered(string indexed candidateName, address indexed owner);

// Event to notify other users of a subdomain registration
event SubdomainRegistered(string indexed candidateName, string indexed subdomainName, address indexed owner);

// Constant to store the registration fee for TLDs
uint public constant REGISTRATION_FEE = 0.000 ether;  //For now i am taking 0 fee

// Constant to store the registration fee for subdomains
uint public constant SUBDOMAIN_REGISTRATION_FEE = 0.000 ether;  //for now i am taking 0 fee

// Mapping from TLD to Owner
mapping(string => address) public tlds;

// Mapping from TLD to SubDomain to Owner
mapping(string => mapping(string => address)) public subdomains;


// Function to register a custom TLD
function registerTLD(string memory candidateName) public payable {
        // Check if the candidate name is already registered
        require(tlds[candidateName] == address(0));

        // Check if the user has enough ETH to pay for the registration
        require(msg.value >= REGISTRATION_FEE);

        // Register the TLD
        tlds[candidateName] = msg.sender;

        // Emit an event to notify other users of the registration
        emit TLDRegistered(candidateName, msg.sender);
}


// Function to add a subdomain to a TLD
function addSubdomain(string memory candidateName, string memory subdomainName) public payable {
        // Check if the TLD should be registered by msg.sender
        require(tlds[candidateName] == msg.sender);

        // Check if the subdomain name is already registered
        require(subdomains[candidateName][subdomainName] == address(0));

        // Check if the user has enough ETH to pay for the registration
        require(msg.value >= SUBDOMAIN_REGISTRATION_FEE);

        // Add the subdomain
        subdomains[candidateName][subdomainName] = msg.sender;

        // Emit an event to notify other users of the registration
        emit SubdomainRegistered(candidateName, subdomainName, msg.sender);
}

// Function to resolve a subdomain to an address
function resolve(string memory domain) public view returns(address) {
        
        (string memory first, string memory second) = splitString(domain);

        // // Return the address of the subdomain owner
        return subdomains[second][first];
}


  function splitString(string memory input) public pure returns (string memory, string memory) {
        uint dotIndex = findDotIndex(input);
        require(dotIndex != 0 && dotIndex != bytes(input).length - 1, "Invalid input format");

        string memory firstWord = substring(input, 0, dotIndex);
        string memory secondWord = substring(input, dotIndex + 1, bytes(input).length - dotIndex - 1);

        return (firstWord, secondWord);
    }

    function findDotIndex(string memory input) private pure returns (uint) {
        bytes memory inputBytes = bytes(input);
        for (uint i = 0; i < inputBytes.length; i++) {
            if (inputBytes[i] == bytes1('.')) {
                return i;
            }
        }
        return 0;
    }

    function substring(string memory input, uint startIndex, uint length) private pure returns (string memory) {
        bytes memory inputBytes = bytes(input);
        require(startIndex + length <= inputBytes.length, "Invalid substring length");

        bytes memory result = new bytes(length);
        for (uint i = 0; i < length; i++) {
            result[i] = inputBytes[startIndex + i];
        }

        return string(result);
    }

}