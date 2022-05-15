/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity = 0.8.7;

contract Vote {
    event Voted(address indexed voter, uint8 proposal);

    uint256 public endTime;
    uint256 public proposalA;
    uint256 public proposalB;
    uint256 public proposalC;

    constructor(uint256 _endTime) {
        endTime = _endTime;
    }

    function votes() public view returns(uint256) {
        return proposalA + proposalB + proposalC;
    }

    function vote(uint8 _proposal) public {
        require(block.timestamp < endTime, "Vote expired.");
        require(_proposal >= 1 && _proposal <= 3, "Invalid proposal.");

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
}