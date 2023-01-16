/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
contract My_flag {

    address private owner;
    address private agent;
    string private secretFlag;

    constructor(address agentAddress) {
        owner = msg.sender;
        agent = agentAddress;
    }

    function saveFlag(string memory Myflag) external {
        require(msg.sender == owner, "Not owner"); //only owner can set secretFlag
        secretFlag = Myflag; 
    }

    function giveMeFlag() public view returns(string memory) {
        require(msg.sender == agent);  //only agents can access this flag
        string memory theSecretFlag = secretFlag;
        return theSecretFlag;
    }
}