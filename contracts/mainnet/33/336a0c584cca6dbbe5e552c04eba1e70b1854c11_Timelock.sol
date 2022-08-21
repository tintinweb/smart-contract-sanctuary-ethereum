/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

pragma solidity ^0.8.7;

contract Timelock {
    uint256 public constant duration = 6205 days;
    uint256 public immutable end;
    address payable public immutable owner;

    constructor() {
        end = block.timestamp + duration;
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function withdraw() external {
        require(msg.sender == owner, "Only the owner can withdraw the balance");
        require(block.timestamp >= end, "You have to wait until the timelock is up");
        owner.transfer(address(this).balance);
    }
}