/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.7;

contract Vote2 {

    event Voted(address indexed voter, uint8 proposal);

    mapping(address => bool) public voted;
    address [] votelist;

    uint256 public endTime;

    uint256 public proposalA;
    uint256 public proposalB;
    uint256 public proposalC;

    address public owner;
    constructor(uint256 _endTime) {
        endTime = _endTime;
        owner=msg.sender;
    }

    function vote(uint8 _proposal) public {
        require(block.timestamp < endTime, "Vote expired.");
        require(_proposal >= 1 && _proposal <= 3, "Invalid proposal.");
        require(!voted[msg.sender], "Cannot vote again.");
        voted[msg.sender] = true;
        votelist.push(msg.sender);
        if (_proposal == 1) {
            proposalA ++;
        }
        else if (_proposal == 2) {
            proposalB ++;
        }
        else if (_proposal == 3) {
            proposalC ++;
        }
        emit Voted(msg.sender, _proposal);
    }

    function votes() public view returns (uint256) {
        return proposalA + proposalB + proposalC;
    }

    function reset() public {
        require(msg.sender == owner, "Not Smart contract owner");      
        delete proposalA;
        delete proposalB;
        delete proposalC;
        for (uint i=0; i< votelist.length ; i++){
         delete voted[votelist[i]];
        }
        delete votelist;
    }
}