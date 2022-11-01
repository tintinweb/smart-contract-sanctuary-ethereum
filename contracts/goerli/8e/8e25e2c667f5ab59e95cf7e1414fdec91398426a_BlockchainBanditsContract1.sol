/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

pragma solidity ^0.8.6;

contract BlockchainBanditsContract1{

    address private constant MICHELLE_ADDRESS = 0x83CAAFb813B443fB3fC94A62988665c001a99B05;
    address private constant JACEY_ADDRESS = 0xefb732CA174912587c6f48704eBa3654F53e76de;
    address private owner;

    uint public counterJacey;
    uint public counterMichelle;
    bool public isPaused;

    constructor() {
        owner = msg.sender;
        counterJacey = 0;
        counterMichelle = 0;
        isPaused = false;
    }

    function functionJacey() public {
        require(!isPaused);
        require(msg.sender == JACEY_ADDRESS);
        counterJacey++;
    }

    function functionMichelle() public {
        require(!isPaused);
        require(msg.sender == MICHELLE_ADDRESS);
        counterMichelle++;
    }

    function togglePaused() public {
        require(msg.sender == owner);
        isPaused = !isPaused;
    }
}