/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

/*
The Kingkiller Chronicle by Patrcik Rothfuss

    The Elodin token is named after one of the most beloved characters of the Kvothe triology.
    Its a short, quick and fruitful investment dedicated to bring together the small book-loving
    community and make possible the printing of the last and third part of the triology.

    Once the printing of the copies has started, the publisher will quintuple the initial value
    in ethereum and redistribute it to the owners of Elodin as a way of thanking and supporting 
    the project. 




    Official Website: https://www.patrickrothfuss.com/content/index.asp

    Twitter: https://twitter.com/PatrickRothfuss

    Telegram: https://t.me/@PatrickRothfuss

    Buy Tax: 0%
    Sell Tax: 0%
    
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

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


contract Elodin is IERC20 {
    using SafeMath for uint256;

    string public constant name = "The Kingkiller Chronicle";
    string public constant symbol = "ELODIN";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 private totalSupply_ = 100000000*10**uint256(decimals);

    constructor() public {
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }


    function transfer(address receiver, uint256 numTokens) public override returns (bool) {

        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
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
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;

    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}