/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract StaeVariables{
    string name;
    address owner;

    constructor () {
        name = "unkown";
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Permission denied.");
        _;
    }

    function setName(string calldata _name) public onlyOwner returns (string memory) {
        name = _name;
        return name;
    }

    function getName() public view returns (string memory) {
        return name;
    }

}