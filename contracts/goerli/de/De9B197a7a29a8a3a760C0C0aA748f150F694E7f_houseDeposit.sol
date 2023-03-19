/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/utils/Strings.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";

contract houseDeposit{
    address payable owner;
    bool public isPaused;

    constructor() {
        owner = payable(msg.sender);
        isPaused = false; // Add initialization for isPaused
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }
    
    modifier whenNotPaused() {
        require(!isPaused, "The contract is paused.");
        _;
    }

    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value; 
    }
    
    function withdraw(uint _amount) public {
        
        require(balances[msg.sender]>= _amount, "Not enough ether");
        
        balances[msg.sender] -= _amount;
        
        (bool sent,) = msg.sender.call{value: _amount}("Sent");
        require(sent, "failed to send ETH");
    }

    function withdrawAllToOwner() public onlyOwner {
        uint256 amount = address(this).balance;
        owner.transfer(amount);
    }

    function getBal() public view returns(uint){
        return address(this).balance;
    }

    function pause() external onlyOwner {
        isPaused = true;
    }

    function unpause() external onlyOwner {
        isPaused = false;
    }
}