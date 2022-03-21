/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hodl{

    uint256 balance;
    address payable founder;

    uint256 start;
    constructor(){
        founder = payable(msg.sender);
        start = block.timestamp;
    }

    function AddBalance(uint256 value) external{
        balance += value;
    }

    fallback() external payable{

    }

    receive() external payable{

    }

    function Destory() external{
        if(block.timestamp >= start + 365 * 1 days){
            WithDraw();
            selfdestruct(founder);
        }
    }

    function WithDraw() internal{
        founder.transfer(balance);
        balance = 0;
    }

}