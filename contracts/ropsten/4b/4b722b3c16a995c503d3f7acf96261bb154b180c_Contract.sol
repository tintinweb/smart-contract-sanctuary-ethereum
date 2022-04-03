/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

pragma solidity >=0.7.0 <0.9.0;

contract Contract {
   
    address internal Owner;
    uint totalSupply = 10000;
    
    constructor() payable {
        Owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == Owner, "you are not the owner");
        _;
    }
   
    function viewOwner() public view returns(address) {
        return Owner;
    }
   
    function transferOwnership(address NewOwner) public isOwner {
        Owner = NewOwner;
    }

    function donateMoney() external payable {
        require(msg.value >= .01 ether);
    }

    function sendViaCall(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}