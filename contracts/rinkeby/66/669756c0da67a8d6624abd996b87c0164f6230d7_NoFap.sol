// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract NoFap {
    address public owner = msg.sender;
    uint public lastFap = block.timestamp;
    uint public constant milestone = 30 days;
    uint public immutable reward;

    event Relapsed(uint streak);

    constructor() payable {
        reward = msg.value;
    }

    function streak() public view returns(uint) {
        return (block.timestamp - lastFap) / 1 days;
    }

    function relapsed() external {
        require(msg.sender == owner);
        emit Relapsed(streak());
        lastFap = block.timestamp;
    }

    function claim() external {
        require(streak() >= milestone);
        payable(owner).transfer(reward);
    }




}