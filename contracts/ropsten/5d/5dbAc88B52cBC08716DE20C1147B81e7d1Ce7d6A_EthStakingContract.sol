/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: GPL3-3.0

pragma solidity >=0.8.7;

contract EthStakingContract{
    mapping(address => uint) public stakes;
    mapping(address => uint) public maturityTime;

    
    function isMatured(address stakeholder) internal view returns(bool){
        return maturityTime[stakeholder] <= block.timestamp;
    }

    function deposit() public payable{
        maturityTime[msg.sender] = block.timestamp + 60;
        stakes[msg.sender] = msg.value;
    }

    function withdraw() public payable {
        require(isMatured(msg.sender), "Maturity time is not reached");
        require(stakes[msg.sender] > 0, "Not enough amount staked");
        payable(msg.sender).transfer(stakes[msg.sender]);
        stakes[msg.sender] = 0;
    }
}