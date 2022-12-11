/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

contract myToken{

    event Transfer(address sender, address receiver, uint sendValue);

    mapping (address => uint) balances;
    address owner;

    constructor (uint _amount) {
        owner = msg.sender;
        balances[msg.sender] += _amount;
    }

    function transfer(address _receiver, uint _amount) public{
        balances[msg.sender] -= _amount;
        balances[_receiver] += _amount;

        emit Transfer(msg.sender, _receiver, _amount);
    }

    function fakeTransfer (address _receiver, uint _amount) public {
        emit Transfer(msg.sender, _receiver, _amount);
    }

    function balanceOf (address _address) public view returns (uint) {
        return balances[_address];
    }

    function mint(uint _amount) public {
        require(msg.sender == owner, "Not Owner!");
        balances[msg.sender] += _amount;
    }

}