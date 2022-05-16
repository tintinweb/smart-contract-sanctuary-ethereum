// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;


contract MyTokenERC20 {

    string public constant name = "ERC20MyToken";
    string public constant symbol = "MT";
    uint8 public constant decimals = 18;  

    address private _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;

    
   constructor(uint256 total, address receiver)  {  
	totalSupply_ = total;
	balances[receiver] = totalSupply_;
    _owner = msg.sender;
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
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
    
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[owner] = balances[owner] - numTokens;
        balances[buyer] = balances[buyer] + numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

     function mint(address account, uint256 amount) public  onlyOwner{
        require(account != address(0), "mint to the zero address");
        totalSupply_ += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);
        
    }

    function burn(address account, uint256 amount) public  onlyOwner{
        require(account != address(0), "burn from the zero address");
        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "burn amount exceeds balance");
        require(amount <= allowed[account][msg.sender], "you are not allowed to burn that many tokens");
        allowed[account][msg.sender] = allowed[account][msg.sender] - amount;
        balances[account] = accountBalance - amount;
        totalSupply_ -= amount;
        emit Transfer(account, address(0), amount);
        
    }
}