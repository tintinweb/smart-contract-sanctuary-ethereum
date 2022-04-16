/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract Form {
    address public owner;
    string[] public fields;

    // TODO: Make this private
    mapping(address => string) public responses;
    address[] public respondents;
    uint256 public responsesCount;

    constructor(address _owner, string[] memory _fields) {
        owner = _owner;
        fields = _fields;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function submitResponse(string memory _ipfsUrl) public {
        responses[msg.sender] = _ipfsUrl;
        respondents.push(msg.sender);
    }

    function getResponse(address _user) public view returns (string memory) {
        return responses[_user];
    }

    function getAllFields() public view returns (string[] memory) {
        return fields;
    }
}