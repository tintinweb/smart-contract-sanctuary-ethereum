//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract borrowing {
    
    mapping (address => bool) public isBorrowing;    
    mapping(address=>uint256) public borrowAmount;

    event Borrowed(address indexed borrower, uint256 indexed amount, uint256 indexed borrowTime);
    event Repaid(address indexed borrower, uint256 indexed amount, uint256 indexed repayTime);


    function borrow(uint256 amount) public {
        isBorrowing[msg.sender] = true; 
        borrowAmount[msg.sender] += amount;
        emit Borrowed(msg.sender, amount, block.timestamp);
    }

    function repay(uint256 amount) public {
        borrowAmount[msg.sender] -= amount;

        if(borrowAmount[msg.sender] == 0){
            isBorrowing[msg.sender] = false;
        }
        emit Repaid(msg.sender, amount, block.timestamp);
    }


}