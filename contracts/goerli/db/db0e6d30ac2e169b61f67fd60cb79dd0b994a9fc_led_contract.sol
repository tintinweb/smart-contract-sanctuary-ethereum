/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

pragma solidity >=0.7.0 <0.8.0;

contract led_contract {
    
    address payable private owner;
    int8 private led;
    
     modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor() {
        owner = msg.sender; 
        led = 0; // set LED value to 0 (i.e. off)
        
    }
    
    function setLed(int8 newOn) public payable {
        require(newOn == 0 || newOn == 1, "Status can only be 0 or 1 (i.e. on or off)");
        led = newOn; // set LED to new value
    }
    
    function readLed() public view returns (int8) {
        return led; // return current value of LED
    }
    
    function retrieveEther() public isOwner {
        msg.sender.transfer(address(this).balance); // transfer current contract balance to owner
    }
    
    function kill() public payable isOwner {
        selfdestruct(owner);
    }
}