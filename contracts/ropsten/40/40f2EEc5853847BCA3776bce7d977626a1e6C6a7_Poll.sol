/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: None
pragma solidity >=0.4.22 <0.9.0;

contract Poll {
    //VARIABLES
    struct response {
        string name;
        uint32 nbVote;
    }

    string public question;
    mapping(string => response) public responses;

    address public owner;

    // MODIFIERS
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //FUNCTIONS
    constructor(string memory _question, string[] memory _responseNames) {
        owner = msg.sender;

        question = _question;
        for (uint8 i = 0; i < _responseNames.length; i++) {
            responses[_responseNames[i]] = response({
                name: _responseNames[i],
                nbVote: 0
            });
        }
    }

    function vote(string[] memory _names, uint32[] memory _nbVotes) 
        public
        onlyOwner()
    {
        for (uint8 i = 0; i < _names.length; i++) {
            responses[_names[i]].nbVote = _nbVotes[i];
        }
    }
}