// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import './SimpleStorage.sol';
contract Operational{
    SimpleStorage_Doctor CREATE;
    function CREATE_BLOCK (string memory name, string memory location, bool availability) public payable{
        CREATE  =  new  SimpleStorage_Doctor(
        name,
        location,
        availability);
    }
    function FETCH_NAME() public view returns (string memory) {
        return CREATE.fetchNAME();
    }
    function FETCH_LOCATION() public view returns (string memory) {
        return CREATE.fetchLOCATION();
    }
    function FETCH_AVAILABILITY() public view returns (bool) {
        return CREATE.fetchAVAILABILITY();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
contract SimpleStorage_Doctor{
    string  NAME ;
    string  LOCATION;
    bool  AVAILABILITY;
    constructor(string memory name, string memory location, bool availability){
        NAME = name;
        LOCATION = location;
        AVAILABILITY = availability;
    }
    function fetchNAME () external view returns(string memory){
        return NAME;
    }
    function fetchLOCATION () external view returns(string memory){
        return LOCATION;
    }
    function fetchAVAILABILITY () external view returns(bool){
        return AVAILABILITY;
    }
}