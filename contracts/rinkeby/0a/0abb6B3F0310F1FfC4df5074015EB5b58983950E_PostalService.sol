/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// File: PostalService.sol

contract PostalService {
    struct postalOffice {
        string officeName;
        bool valid;
    }

    address public owner; //Owner address
    mapping(address => string[]) public addressToPackages; //mapping address for array of Tracking number of packges
    mapping(address => postalOffice) public postals; //mapping for valid postals office

    //Constructor
    //Set Owner for the smart contract
    constructor() public {
        owner = msg.sender;
    }

    //modifier for allowing only owner to run actions
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //modifier for allowing only postal offices to run actions
    modifier onlyPostalOffice() {
        require(postals[msg.sender].valid == true);
        _;
    }

    //Adding new postal office to the system
    //Also allowing edit office name
    //can use only by owner
    function addPostalOffice(address _postalOfficeAddress, string memory _name)
        public
        onlyOwner
    {
        postals[_postalOfficeAddress].officeName = _name;
        postals[_postalOfficeAddress].valid = true;
    }

    //Edit postal office valid to flase
    //Keep the office in the system for future using
    //can use only by owner
    function setPostalOfficeToFalse(address _postalOfficeAddress)
        public
        onlyOwner
    {
        postals[_postalOfficeAddress].valid = false;
    }

    //Removing postal office from the system
    //can use only by owner
    function removePostalOffice(address _postalOfficeAddress) public onlyOwner {
        delete (postals[_postalOfficeAddress]);
    }

    //sending new tracking number to client
    //can use only by postal office
    function sendTackingNumber(
        address _clientAddress,
        string memory _trackingNumber
    ) public onlyPostalOffice {
        string[] storage Packages = addressToPackages[_clientAddress];
        Packages.push(_trackingNumber);
        addressToPackages[_clientAddress] = Packages;
    }

    //Recevieng package from postal office and remove tracking number from array of packages
    function receivePackage(string memory _trackingNumber)
        public
        returns (bool)
    {
        string[] storage Packages = addressToPackages[msg.sender];

        for (uint256 i = 0; i < Packages.length; i++) {
            if (
                keccak256(abi.encodePacked(_trackingNumber)) ==
                keccak256(abi.encodePacked(Packages[i]))
            ) {
                Packages[i] = Packages[Packages.length - 1];
                Packages.pop();
                return true;
            }
        }
        return false;
    }

    //Return user package by index from packages array
    function showPackage(uint256 _index) public view returns (string memory) {
        return addressToPackages[msg.sender][_index];
    }
}