/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.10;

contract Vault {


    event Deposit(address _to, uint256 _amount);
    event Withdrawal(address address1, uint256 _amount); 
    // using SafeMath for uint256;
    //здесь объявляем нужные нам переменные, массивы, списки
    mapping(address => uint256) private _balances;


    

    function deposit(address _to) public payable {
        //можно депозит сделать здесь
        _balances[_to] = _balances[_to] + msg.value;
        emit Deposit(_to, msg.value);
    }

    function balanceOf(address _who) public view returns (uint256 balance) {

    }

    function withdraw(uint256 _amount) public payable {
        /// Снимаем средства здесь
        require( _balances[msg.sender] >= _amount);
       _balances[msg.sender] = _balances[msg.sender] - msg.value;
        // msg.sender.transfer(_amount);
        emit Withdrawal(msg.sender, _amount);
    }

    receive() external payable {
        deposit(msg.sender);
      }

     fallback() external payable {
      revert();
      }
}