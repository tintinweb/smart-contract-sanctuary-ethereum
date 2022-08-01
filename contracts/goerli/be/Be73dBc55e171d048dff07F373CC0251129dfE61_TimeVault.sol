// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract TimeVault {
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public times;

    receive() external payable {}

    fallback() external payable {}

    function deposit() public payable{
        require(msg.value > 0, "You must deposit ETH.");
        times[msg.sender] = block.timestamp + 30;
        deposits[msg.sender] = msg.value;
        payable(address(this)).transfer(msg.value);
    }

    function withdraw() public payable{
        require(deposits[msg.sender] > 0, "You didn't deposit any ETH.");
        require(block.timestamp > times[msg.sender], "You still need to wait.");
        payable(msg.sender).transfer(deposits[msg.sender]);
    }

    function increaseTime(uint256 timeToAdd) public{
        require(timeToAdd > 0, "Time to add must be positive.");
        times[msg.sender] += timeToAdd;
    }

    function getDeposit() public view returns (uint256){
        return deposits[msg.sender] / 1e18;
    }

    function getTime() public view returns (uint256){
        uint timeLeft = times[msg.sender] - block.timestamp;
        return timeLeft;
    }
}