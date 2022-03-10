/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Transaction {

   string username;

    constructor(string memory name) {
        username = name;
    }

    mapping(address => uint) balances;
    event sent(address sender, address receiver, uint amount);

    function mint(address receiver, uint amount) public {

        balances[receiver] += amount;

    }

    function send(address sender, address receiver, uint amount) public {

        require(balances[msg.sender] >= amount, "not enough amount");
        balances[sender] -= amount;
        balances[receiver] += amount;
        emit sent(msg.sender, receiver, amount);        

    }

    function balanceOf(address user) public view returns(uint){

        return balances[user];
    }
  
}