// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Coin{

    address public minter;
    mapping(address => uint256) public balances;

    constructor(){
        minter = msg.sender;
    }

    event minted(address from, uint256 amount);

    // Can only be called by creater of the contract
    function mint(address _receiver, uint256 _amount) public{
        require(msg.sender == minter, "You are not the owner of this contract");
        balances[_receiver] += _amount;
        emit minted(msg.sender, _amount);
    }

    error InsufficientBalance(uint256 requested, uint256 available);

    event Sent(address from, address to, uint256 amount);

    function sender(address _receiver, uint256 _amount) public{
        if(_amount > balances[msg.sender]){
            revert InsufficientBalance({
                requested: _amount,
                available: balances[msg.sender]
            });
        }

        balances[msg.sender] -= _amount;
        balances[_receiver] += _amount;

        emit Sent(msg.sender, _receiver, _amount);
    }
}