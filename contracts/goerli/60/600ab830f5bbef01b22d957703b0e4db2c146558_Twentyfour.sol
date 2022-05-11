//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "console.sol";

contract Twentyfour {
    string private dbcid;
    address public admin;

    constructor(string memory _dbcid) {
        admin = msg.sender;
        console.log("Hello admin:", admin);
        dbcid = _dbcid;
        console.log("Deploying:", _dbcid);
    }

    function getAdmin() public view returns (address) {
        return admin;
    }

    function getDbcid() public view returns (string memory) {
        return dbcid;
    }

    function setDbcid(string memory _dbcid) public {
        require(msg.sender == admin);
        console.log("Changing from '%s' to '%s'", dbcid, _dbcid);
        dbcid = _dbcid;
    }
}