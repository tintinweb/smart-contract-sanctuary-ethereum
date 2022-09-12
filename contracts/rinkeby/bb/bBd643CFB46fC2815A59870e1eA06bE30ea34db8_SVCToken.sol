/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// Sources flattened with hardhat v2.11.1 https://hardhat.org

// File contracts/SVC.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
contract SVCToken is IERC20 {

    string public constant name = "ERC20Basic";
    string public constant symbol = "BSC";
    uint8 public constant decimals = 18;  


    // event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    // event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;

    using SafeMath for uint256;


   constructor() public {  
	totalSupply_ = 100000000000;
	balances[msg.sender] = totalSupply_;
    }  

    function totalSupply() public view virtual override returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view virtual override returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public virtual override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public virtual override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view virtual override returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public virtual override returns (bool) {
        require(numTokens <= balances[owner],"reason1");    
        
    
        balances[owner] = balances[owner] - numTokens;
        //allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer]+ numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}