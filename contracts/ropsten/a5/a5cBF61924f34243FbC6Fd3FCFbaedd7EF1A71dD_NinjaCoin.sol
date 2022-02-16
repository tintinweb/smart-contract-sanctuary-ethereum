/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NinjaCoin {

    mapping (address => uint256) public balanceOf;
    string public name = "NinjaCoin";
    string public symbol = "NjC";
    uint8 public decimals  = 8;
    uint256 public totalSuply = 100000 * (10 ** decimals);

    mapping (address => mapping (address =>uint256)) public allowance; 

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    //Make the contract signing account own all supply
    constructor () {
        balanceOf[msg.sender] = totalSuply;
        emit Transfer(address(0), msg.sender, totalSuply);
    }


    //Make transfer function available to the owner from the contract signing account
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value, "Not enough balance to transfer");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);   
        return true;

    }


    //Allow owner to be able to transfer from one account to the other
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowance[_from][msg.sender] >= _value, "Not Approved To Transfer");
        require(balanceOf[_from] >= _value, "Not Enough Token To Transfer");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value; 

        emit Transfer(_from, _to, _value);

        return true;
    }

    // Allow Others Apart From The Owner To Transfer & Spend The Token

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender,  _spender, _value);
        return true; 
    }

}