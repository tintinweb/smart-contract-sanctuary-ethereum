/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

pragma solidity ^0.8.4;

contract Shrimp {
    address private owner;
    bool private paused = false;

    uint public counterM;
    uint public counterJ;
    uint public counterJC; // for testing


    constructor() {
        owner = msg.sender;
    } 

    event wasIncreased(uint counter, address person);

    function jacey_admin(bool setPause) public {
        // check if person calling is michelle's address
        require (msg.sender == owner);
        paused = setPause;
    }

    // another function just to test, anyone can call it
    function jacey_func() public{
        emit wasIncreased(counterM, msg.sender);
        counterJC++;
    }
    
    function michelle_func() public {
        // check if person calling is michelle's address
        require (msg.sender == 0x83CAAFb813B443fB3fC94A62988665c001a99B05);
        require (paused == false);
        emit wasIncreased(counterM, msg.sender);
        counterM++;
    }

    function james_func() public {
        // check if person calling is james' address
        require (msg.sender == 0x74867FBC6e62Fb01961ad90489617872E05bDdbD);
        require (paused == false);
        emit wasIncreased(counterJ, msg.sender);
        counterJ++;
    }
}