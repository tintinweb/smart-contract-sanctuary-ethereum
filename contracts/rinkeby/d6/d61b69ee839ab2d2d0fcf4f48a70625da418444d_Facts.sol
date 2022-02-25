/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

pragma solidity ^0.8.0;

contract Facts {
    uint256 factCount;
    address owner;
    bool paused = false;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(owner == msg.sender, "You are not the owner");
        _;
    }

    modifier isUser() {
        require(tx.origin == msg.sender, "Contracts aren't allowed to interact with this method");
        _;
    }

    event MintFact(address from, uint amount, uint256 timestamp);

    function generateFact() payable public isUser {
        require(!paused, "This contract is currently paused");

        incrementFactCount();
        emit MintFact(msg.sender, msg.value, block.timestamp);
    }

    function setOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    function setPaused() public isOwner {
        paused = !paused;
    }

    function incrementFactCount() private {
        factCount += 1;
    }
}