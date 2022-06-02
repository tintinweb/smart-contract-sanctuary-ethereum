/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Result {

    string[] public row;
    address owner;
    mapping(address => bool) whitelistedAddresses;

    constructor() {
        owner = msg.sender; // setting the owner the contract deployer
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier isWhitelisted(address _address) {
        require(whitelistedAddresses[_address], "You need to be whitelisted");
        _;
    }

    function addUser(address _addressToWhitelist) public onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    function deleteUser(address _addressToWhitelist) public onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = false;
    }

    function verifyUser(address _whitelistedAddress) public view returns (bool) {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }

    function getAllRecords() public view returns (string[] memory) {
        return row;
    }

    function addRecord(string memory data) public isWhitelisted(msg.sender) {
        row.push(data);
    }

    function editRecord(uint256 index, string memory data) public isWhitelisted(msg.sender) returns (string memory) {
        row[index] = data;
        return row[index];
    }

    function deleteRecord(uint256 _index) public isWhitelisted(msg.sender) returns (bool) {
        if (_index < 0 || _index >= row.length) {
            return false;
        } else if (row.length == 1) {
            row.pop();
            return true;
        } else if (_index == row.length - 1) {
            row.pop();
            return true;
        } else {
            for (uint256 i = _index; i < row.length - 1; i++) {
                row[i] = row[i + 1];
            }
            row.pop();
            return true;
        }
    }

}