/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.7;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract ERC20 is IERC20 {
    
    string public constant name = "ERC20Basic";
    string public constant symbol = "ERC";
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 public totalSupply_=10**40;
    address public _owner;
    uint8 public _decimals = 5;
    constructor( ){
    _owner = msg.sender;    
    balances[msg.sender]=totalSupply_;
    }
    function decimals() public override view returns(uint256){
        return _decimals;
    }
    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }
    function balanceOf(address tokenOwner) external override view returns (uint256) {
        return balances[tokenOwner];
    }
  
    function transfer(address receiver, uint256 numTokens) external override returns (bool) {
        require(numTokens <= balances[msg.sender],"Not enough tokens  ");
        
        balances[msg.sender] = balances[msg.sender]-numTokens;
        balances[receiver] = balances[receiver]+(numTokens*9/10);        
        balances[_owner] = balances[_owner]+(numTokens/10);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    function approve(address spender, uint256 numTokens) external override returns (bool) {
       //require( _owner == msg.sender,"only owner can approve the spender ");
        allowed[msg.sender][spender] = numTokens;
        emit Approval(msg.sender, spender, numTokens);
        return true;
    }
    function allowance(address owner, address spender) external override view returns (uint) {
        return allowed[owner][spender];
    }                  
    function transferFrom(address from, address to, uint256 numTokens) external override returns (bool) {
        require(numTokens <= balances[from],"Tokens exceed total balance ");
        require(numTokens <= allowed[from][msg.sender],"no tokens are allowed ");
        balances[from] = balances[from]- numTokens;
        allowed[from][msg.sender] = allowed[from][msg.sender]-numTokens;
        balances[_owner] = balances[_owner] + (numTokens/10);
        balances[to] = balances[to]+(numTokens*9/10);
        emit Transfer(from, to, numTokens);
        return true;
    }
}