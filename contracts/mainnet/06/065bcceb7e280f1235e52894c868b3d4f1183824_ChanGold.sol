/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract ChanGold {

    string public constant name = "ChanGold";
    string public constant symbol = "CHANG";
    uint8 public constant decimals = 18;

    address public  contractOwner;

    uint256 totalSupply_;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    // events
    event Inflation(address indexed tokenOwner, uint tokensAdded, uint newTotal);
    event Deflation(address indexed tokenOwner, uint tokensRemoved, uint newTotal);
    event NewOwner(address indexed newOwner, address indexed oldOwner);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    using SafeMath for uint256;

    constructor(uint256 total) {
	    totalSupply_ = total;
        contractOwner = msg.sender; // deployer
	    balances[contractOwner] = totalSupply_;
    }

//  Contract owner -----------------------------------------

    function inflate(uint numTokens) public returns (bool) {
        require(msg.sender == contractOwner, "Caller is not the owner of the contract");
        balances[msg.sender] = balances[msg.sender].add(numTokens);
        totalSupply_ = totalSupply_.add(numTokens);
        emit Inflation(msg.sender, numTokens, totalSupply_);
        return true;
    }

    function deflate(uint numTokens) public returns (bool) {
        require(msg.sender == contractOwner, "Caller is not the owner of the contract");
        require(numTokens <= balances[msg.sender], "Owner of contract - not enough tokens to burn");
        require(numTokens <= totalSupply_, "Burn is greater than total supply");
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        totalSupply_ = totalSupply_.sub(numTokens);
        emit Deflation(msg.sender, numTokens, totalSupply_);
        return true;
    }

    function newowner(address newOwner) public returns (bool) {
        require(msg.sender == contractOwner, "Caller is not the current owner of the contract");
        contractOwner = newOwner;
        emit NewOwner(newOwner, msg.sender);
        return true;
    }
    
// ERC20 -------------------------------------------------
    
    function totalSupply() public view returns (uint256) {
	    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

// ---------------------------------------------------------------------

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