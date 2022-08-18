/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;



contract WowCoin {

    string public name;
    string public symbol;
    uint8 public decimals;


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    mapping(address=>uint256) balances;
    mapping(address=> mapping(address=>uint256)) allowed;

    uint256 totalSupply_;
    address admin;

    constructor() {
        totalSupply_ = 10000000 * 10**18;
        balances[msg.sender] = totalSupply_;
        name = "WowCoin";
        symbol = "wow1";
        decimals = 18;
        admin = msg.sender;
    }


function totalSupply() public view returns (uint256){
    return totalSupply_;
    }

function balanceOf(address tokenOwner) public view returns (uint256){
    return balances[tokenOwner];
    }

function transfer(address reciever, uint256 numTokens) public returns (bool){
    require(numTokens <= balances[msg.sender]);
    balances[msg.sender] -= numTokens;
    balances[reciever] += numTokens;
    emit Transfer(msg.sender,reciever,numTokens);
    return true;
    }

modifier onlyAdmin {
    require (msg.sender == admin, "Only admin can run this function");
    _;
    }

function mint(uint256 _qty) public onlyAdmin returns(uint256){
    totalSupply_ += _qty;
    balances[msg.sender] += _qty;
    return totalSupply_;
    }

function burn(uint256 _qty) public onlyAdmin returns(uint256){
    require(balances[msg.sender] >= _qty);
    totalSupply_ -= _qty;
    balances[msg.sender] -= _qty;
    return totalSupply_;
    }

}