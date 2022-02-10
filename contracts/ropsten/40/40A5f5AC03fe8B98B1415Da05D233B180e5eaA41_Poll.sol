/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: None
pragma solidity >=0.4.22 <0.9.0;

contract Poll {
    //VARIABLES
    struct responseInput {
        bytes32 name;
        uint32 nbVote;
    }

    struct response {
        string name;
        uint32 nbVote;
    }

    string public question;
    mapping(string => response) public responses;

    address public owner;

    // MODIFIERS
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not authorized.");
        _;
    }

    //FUNCTIONS
    constructor(bytes32 _question, bytes32[] memory _responseNames) {
        owner = msg.sender;

        question = string(abi.encodePacked(_question));
        for (uint8 i = 0; i < _responseNames.length; i++) {
            responses[string(abi.encodePacked(_responseNames[i]))] = response({
                name: string(abi.encodePacked(_responseNames[i])),
                nbVote: 0
            });
        }
    }

    function vote(responseInput[] memory _responses) 
        public
        onlyOwner()
    {
        for (uint8 i = 0; i < _responses.length; i++) {
            responses[string(abi.encodePacked(_responses[i].name))].nbVote = _responses[i].nbVote;
        }
    }
}