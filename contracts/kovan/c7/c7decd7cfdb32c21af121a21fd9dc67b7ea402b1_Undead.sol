/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// File: contracts/Undead.sol



pragma solidity >=0.8.0 <0.9.0;

contract Undead {
 
    address public owner;

    mapping (address => uint) public payments;

    constructor() {
        owner = msg.sender; 
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "not an owner!");
        _;
    }

    function payForMint() external payable {  
        payments[msg.sender] = msg.value;  
    } 
    
    event Received(address, uint); 

    receive() external payable {
        emit Received(msg.sender, msg.value); 
    }
    
    fallback() external payable { 
    }

    function getBalance() public view onlyOwner returns(uint) {
        return address(this).balance;
    }

    function withdraw() public onlyOwner {  
        address payable _to = payable(owner);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);
    }

}