/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;



contract GreedyRobot {
    mapping(address => uint256) public contributors;
    uint64 public constant MINIMUM_CONTRIBUTION = 0.1 ether;
    address immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    function canPass(address contributorAddress) public view returns (bool) {
        return contributors[contributorAddress] >= MINIMUM_CONTRIBUTION;
    }

    receive() external payable {
        require(msg.value == 0.1 ether);
        contributors[msg.sender] += msg.value;
    }

    function widthdraw() external {
        require(i_owner == msg.sender);
        payable(msg.sender).transfer(address(this).balance);
    }
}