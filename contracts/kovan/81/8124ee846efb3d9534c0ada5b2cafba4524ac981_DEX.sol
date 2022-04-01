/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20Basic is IERC20 {

    string public constant name = "NewTokenErc20";
    string public constant symbol = "NTK";
    uint8 public constant decimals = 0;
    
    address payable public owner;


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 10000000;


   constructor() {
    balances[msg.sender] = totalSupply_;
    owner= payable(msg.sender);
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-numTokens;
        balances[receiver] = balances[receiver]+numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
       // require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner]-numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]+numTokens;
        balances[buyer] = balances[buyer]+numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}


contract DEX is ERC20Basic {

    event Bought(uint256 amount);
    event Sold(uint256 amount);


    IERC20 public token;

    constructor() {
        token = new ERC20Basic();
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }    
    

    function sell(address payable receiver,uint256 tokenAmount)public payable returns(uint256) {
        balances[receiver] = balances[receiver] - tokenAmount;
        balances[msg.sender] = balances[msg.sender] + tokenAmount;
        uint256 myval=1 ether;
            
        payable(receiver).transfer(msg.value);
        emit Transfer(msg.sender,owner,tokenAmount);
    }

    // function sell(uint256 amount, address buyer) public returns(bool) {
    //     require(amount > 0, "You need to sell at least some tokens");
    //     uint256 allowance = token.allowance(msg.sender, address(this));
    //     require(allowance >= amount, "Check the token allowance");
        
    //     balances[owner] = balances[owner]-amount;
    //     allowed[owner][msg.sender] = allowed[owner][msg.sender]+amount;
    //     balances[buyer] = balances[buyer]+amount;
    //     emit Transfer(owner, buyer, amount);
       
    //     transferFrom(msg.sender, address(this), amount);
    //     payable(msg.sender).transfer(amount);
    //     // emit Sold(amount);
    //     emit Transfer(owner, buyer, amount);
    //     return true;
    // }

    function buy(address buyer, uint256 numTokens) public payable returns(bool) {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;
        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require (msg.value == 1 ether);
        //require(success, "Failed to send Ether");
        require(numTokens <= balances[owner]);
       // require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner]-numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]+numTokens;
        balances[buyer] = balances[buyer]+numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;

    }

}