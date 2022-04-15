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

//Prevent overflow
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
    }
}
//Basic authorization control functions
contract Ownable {
    address public owner;

    constructor()  {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Attempt to call the function you don't have rights to");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract TST_TOKEN is IERC20, Ownable {
    
    string public constant name="Tester token";
    string public constant symbol="TST";
    uint public constant decimals=5;
    uint public constant initialSupply_=1000000*(10**5);
    uint public totalSupply_;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    using SafeMath for uint256;

    constructor() {
        balances[msg.sender]=initialSupply_;
        totalSupply_=initialSupply_;
    }

    function totalSupply() public override view returns (uint) {
        return totalSupply_;
    }

    function balanceOf(address account) public override view returns (uint) {
        return balances[account];
    }

    function allowance (address tokenOwner, address sender) public override view returns (uint){
        return allowed[tokenOwner][sender];
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

    function transferFrom(address tokenOwner, address recipient, uint amount) public override returns (bool){
        require(balances[tokenOwner]>amount, "Not enough funds");
        require(allowed[tokenOwner][msg.sender]>amount, "Token Owner did not allow you to send this amount");
        
        balances[tokenOwner]=balances[tokenOwner].sub(amount);
        allowed[tokenOwner][msg.sender]=allowed[tokenOwner][msg.sender].sub(amount);
        balances[recipient]=balances[recipient].add(amount);
        emit Transfer(tokenOwner, recipient, amount);
        return true;
    }

    function issue(uint amount) public onlyOwner returns (bool) {
        require(totalSupply_ + amount >totalSupply_, "Total supply after issuing new tokens can be lower than before");
        require(balances[owner]+amount>balances[owner]);
        totalSupply_+=amount;
        balances[owner]+=amount;
        emit Issue(amount);
        return true;
    }
    function burn(uint amount) public returns (bool) {
        require(balances[msg.sender] > amount, "Not enough tokens to burn");
        require(totalSupply_ - amount < totalSupply_, "Total supply after burning should be lower than before");    
        balances[msg.sender] -=amount;
        totalSupply_-=amount;
        emit Burn (msg.sender, amount);
        return true;
    }

    event Issue(uint amount);
    event Burn(address burner, uint amount);
}