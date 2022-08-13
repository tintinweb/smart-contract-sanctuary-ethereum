/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Vault{

    error NotOwnerError();
    error LessThanMinEtherError();
    error MoreThanMaxEtherError();


    event Deposit(
        address indexed sender,
        uint amount
        );

    event Withdraw(
        address indexed sender,
        uint amount
    );

     struct withdraw{
         address payable _to;
         uint amount;
         uint timestamp; 
     } 

    
     address public owner = msg.sender;
     uint public depositReceived;
     uint public lockedUntil;
     bool public paused;
     uint public amount;


     constructor() {
         owner = msg.sender;
     }

      modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwnerError();
        }
        _;
    }


    mapping(address => uint) public balanceOf;

    function deposit() public payable {
         require (paused == false);
         depositReceived += msg.value;
         lockedUntil = block.timestamp + 300 seconds;

         if (depositReceived < 5 ether) {
             revert LessThanMinEtherError();
         }

         if (depositReceived > 15 ether) {
             revert MoreThanMaxEtherError();
         }

         emit Deposit(msg.sender, amount);
         balanceOf[msg.sender] += amount;
         
     }

     function setPaused(bool _paused) public onlyOwner {
       //require(msg.sender == owner, "You are not the owner");
       paused = _paused;

     }

    
    function withdrawEther(uint _amount) public payable {
        require (lockedUntil < block.timestamp, "Time Not Yet Reached");
            emit Withdraw(msg.sender, _amount);

        require (balanceOf[msg.sender] > _amount, "Ether Not Enough");
            balanceOf[msg.sender] -= _amount;
            
    }

}