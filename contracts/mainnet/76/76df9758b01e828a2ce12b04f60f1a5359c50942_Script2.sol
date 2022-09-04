/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Script2 {
    uint public decay;
    mapping (uint => address) public agents;
    mapping (uint => uint) public newDecays;
    mapping (uint => address) public outs;

    constructor(uint newDecay, address agent0, address agent1, address agent2) {
        decay = newDecay;
        agents[0] = agent0;
        agents[1] = agent1;
        agents[2] = agent2;
    }

    function setNewDecay(uint agent, uint newDecay) external {
        require(agent >= 0 && agent <= 2);
        require(msg.sender == agents[agent]);
        newDecays[agent] = newDecay;
    }

    function setOut(uint agent, address out) external {
        require(agent >= 0 && agent <= 2);
        require(msg.sender == agents[agent]);
        outs[agent] = out;
    }

    function applyNewDecay(uint agentA, uint agentB) external {
        require(agentA >= 0 && agentA <= 2);
        require(agentB >= 0 && agentB <= 2);
        require(agentA != agentB);
        uint newDecay = newDecays[agentA];
        require(newDecay > 0);
        require(newDecay == newDecays[agentB]);
        decay = newDecay;
        newDecays[agentA] = 0;
        newDecays[agentB] = 0;
    }

    function applyOut(uint agentA, uint agentB, uint amount) external {
        require(agentA >= 0 && agentA <= 2);
        require(agentB >= 0 && agentB <= 2);
        require(agentA != agentB);
        require(msg.sender == agents[agentA] || msg.sender == agents[agentB]);
        address out = outs[agentA];
        require(out != address(0));
        require(out == outs[agentB]);
        (bool sent, ) = out.call{value: amount}("");
        require(sent, "Failed to send Ether");
        outs[agentA] = address(0);
        outs[agentB] = address(0);
    }

    function applyOutAfterDecay(uint agent, uint amount) external {
        require(agent >= 0 && agent <= 2);
        require(msg.sender == agents[agent]);
        address out = outs[agent];
        require(out != address(0));
        require(block.timestamp >= decay);
        (bool sent, ) = out.call{value: amount}("");
        require(sent, "Failed to send Ether");
        outs[agent] = address(0);
    }

    function time() external view returns (uint) {
        return block.timestamp;
    }

    receive() external payable {}
}