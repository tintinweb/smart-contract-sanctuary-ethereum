/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/**
 * @title Simple bank contract from hardcod3d.eth
 */

 contract SimpleBank {

    //set variables and mapping
    address public owner;
    mapping(address => uint) public balance;
    
    //set owner
    constructor() {
        owner = msg.sender;
    }

    //update balance if sent directly to the contract address
    receive() external payable{
        uint _amount = msg.value;
        balance[msg.sender] += _amount;
    } 

    //fallback updates balance
    fallback() external payable{
        uint _amount = msg.value;
        balance[msg.sender] += _amount;
    } 

    //deposit and increase amount
    function deposit() external payable {
        uint _amount = msg.value;
        balance[msg.sender] += _amount;
    }

    //withdraw function custom amount
    function withdraw(uint _amount) external {
        address payable to =  payable(msg.sender);
        balance[msg.sender] -= _amount;
        to.transfer(_amount);
    }
    
    //withdraw all balance
    function withdrawAll() external {
        address payable to =  payable(msg.sender);
        uint balanceAll = balance[msg.sender];
        balance[msg.sender] -= balanceAll;
        to.transfer(balanceAll);
    }

    // getbalance
    function getBalance () external view returns(uint) {
        uint balanceOf = balance[msg.sender];
        return balanceOf;
    }
 }