pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

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

contract TST_TOKEN is IERC20 {
    
    string public constant name="Tester token";
    string public constant symbol="TST";
    uint public constant decimals=5;
    uint public constant totalSupply_=1000000;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    using SafeMath for uint256;

    constructor() {
        balances[msg.sender]=totalSupply_;
    }

    function totalSupply() public override pure returns (uint) {
        return totalSupply_;
    }

    function balanceOf(address account) public override view returns (uint) {
        return balances[account];
    }

    function allowance (address owner, address sender) public override view returns (uint){
        return allowed[owner][sender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool){
        require(balances[msg.sender]>amount, "Not enough funds");
        balances[msg.sender]=balances[msg.sender].sub(amount);
        balances[recipient]=balances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) public override returns (bool){
        allowed[msg.sender][spender]=amount;
        emit Approval(msg.sender, spender, amount);
        return true;    
    }

    function transferFrom(address owner, address recipient, uint amount) public override returns (bool){
        require(balances[owner]>amount, "Not enough funds");
        require(allowed[owner][msg.sender]>amount, "Owner did not allow you to send this amount");
        
        balances[owner]=balances[owner].sub(amount);
        allowed[owner][msg.sender]=allowed[owner][msg.sender].sub(amount);
        balances[recipient]=balances[recipient].add(amount);
        emit Transfer(owner, recipient, amount);
        return true;
    }
}