/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

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

     struct WithdrawStatus {
         address user;
         uint amount;
         uint timestamp; 
     } 
    mapping(address => WithdrawStatus) public withdrawStatus;
    
     address public owner;
     uint public depositReceived;
     uint public lockedUntil;
     bool public paused;
     uint public amount;


     constructor() {
         owner = payable(msg.sender);
     }

      modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwnerError();
        }
        _;
    }


    mapping(address => uint) public balanceOf;
    

    function deposit(uint _amount) public payable {
         require (paused == false);
         lockedUntil = block.timestamp + 1 minutes;
         require(_amount >= 5 ether, "Less Than Required Amount of Ether");
         require(_amount <= 15 ether, "More Than Required Amount of Ether");
         emit Deposit(msg.sender, amount);
         balanceOf[msg.sender] += _amount;

    WithdrawStatus storage status = withdrawStatus[msg.sender];
    status.amount = _amount;
    status.user = msg.sender;
    status.timestamp = block.timestamp;
  
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