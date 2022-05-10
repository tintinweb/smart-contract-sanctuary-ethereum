//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

library SafeMath { 
    function subtract(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a);
      return c;
    }
}

contract ERC20Token {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    address public Owner;
    uint256 public countSupply;

    //Modifier to check whether executer is owner or not
    modifier isOwner {
      require(msg.sender == Owner,"Only Owner has the access");
      _;
    }
    //Events
    event TokensApproved(address  tokenOwner, address  sender, uint256 tokens);
    event Transferred(address  from, address  to, uint256 tokens);
    event TokenMinted(address to, uint256 amount);
    event TokenBurnt(address user, uint256 amount);

    
    //balance of given address
    mapping(address => uint256) public balance;

    //Amount that can be transferred from other address
    mapping(address => mapping (address => uint256)) MaxAmount;
    
   constructor(uint256 _initialSupply, string memory _name, string memory _symbol) {  
	    countSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        Owner = msg.sender;

        balance[msg.sender] = _initialSupply;
        emit Transferred(address(0), msg.sender, _initialSupply);
    }

    function balanceOf(address account) public view returns (uint256){
        return balance[account];
    }

    function totalTokensMinted() public view returns (uint256) {
	return countSupply;
    }
    
    //minting of tokens
    function mint(address to, uint256 amount) public isOwner {

        balance[to] = balance[to].add(amount);
        countSupply = countSupply.add(amount);

        emit TokenMinted(to, amount);
    }

    //Only the token holders can burn tokens
    function burn(uint256 amount) public {
        require(balance[msg.sender] >= amount, "You can't burn more tokens than you have");

        balance[msg.sender] = balance[msg.sender].subtract(amount);
        countSupply = countSupply - amount; 

        emit TokenBurnt(msg.sender, amount);
    }

    //transfer of tokens between sender and receiver
    function transferTokens(address receiver, uint256 amount) public{
        require(amount <= balance[msg.sender],"You don't have enough tokens");
        balance[msg.sender] = balance[msg.sender].subtract(amount);
        balance[receiver] = balance[receiver].add(amount);
        emit Transferred(msg.sender, receiver, amount);
    }

    //approve tokens to transfer by other address up to certain amount
    function approve(address sender, uint256 amount) public {
        MaxAmount[msg.sender][sender] = amount;
        emit TokensApproved(msg.sender, sender, amount);
    }

    //Can be called from only authorized address
    function transferFrom(address owner, address receiver, uint256 amount) public  {
        require(amount <= balance[owner],"Owner don't have enough balance");    
        require(amount <= MaxAmount[owner][msg.sender], "More than the limit");
    
        balance[owner] = balance[owner].subtract(amount);
        MaxAmount[owner][msg.sender] = MaxAmount[owner][msg.sender].subtract(amount);
        balance[receiver] = balance[receiver].add(amount);

        emit Transferred(owner, receiver, amount);
    }
}