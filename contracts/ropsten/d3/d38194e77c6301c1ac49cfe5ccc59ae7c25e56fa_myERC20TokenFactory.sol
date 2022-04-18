/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract myERC20Token {

    address public _Owner;
    uint256 internal _totalSupply;
    string public _name;
    string public _symbol;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    modifier onlyOwner()  {
        require(msg.sender == _Owner, "Unauthorize: caller is not the owner");
        _;
    }
    
 // ICO to contract Owner   
    constructor(string memory name_, string memory symbol_, uint256 totalSupply_) {
        _Owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_;
        balances[_Owner] = _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

// balanceOf function will return the current token balance of an account, identified by its owner’s address.
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

 // mint function will also incease the Total Supply, and tokens will be minted/transfer to the function caller address   
    function _mint(uint256 _tokens) public {
        require(msg.sender != address(0), "ERC20: mint to the zero address");

        _totalSupply += _tokens;
        balances[msg.sender] += _tokens;
        emit Transfer(address(0), msg.sender, _tokens);

    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        require(receiver != address(0), "Token Burn not allowed through this function");
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

// 3rd party Authorization by Owner for token transfer as per given token quantity
   function approve(address spender, uint numTokens) public onlyOwner {
        allowed[_Owner][spender] = numTokens;
        emit Approval(_Owner, spender, numTokens);
    } 

// Get Number of Tokens Approved for Withdrawal
    function allowance(address spender) public view returns (uint) {
        return allowed[_Owner][spender];
    }

// Transfer tokens by approved 3rd party
    function transferFrom(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[_Owner]);
        require(numTokens <= allowed[_Owner][msg.sender]);
        require(receiver != address(0), "Token Burn not allowed through this function");
        balances[_Owner] -= numTokens;
        allowed[_Owner][msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(_Owner, receiver, numTokens);
        return true;
    }

}

/* contract AstroToken is myERC20Token {
    constructor (){
    _totalSupply = 5000;
    _name = "Astro";
    _symbol = "AST";
   }
}

contract VeaponToken is myERC20Token {
    constructor (){
    _totalSupply = 7000;
    _name = "Veapon";
    _symbol = "VPN";
   }
} */

contract myERC20TokenFactory {

    address public _Owner;

    constructor() {
        _Owner = msg.sender;
    }

    modifier onlyOwner()  {
        require(msg.sender == _Owner, "Unauthorize: caller is not the owner");
        _;
    } 
    
    //myERC20Token instanceERCToken;
    myERC20Token[] public myERC20TokenList;

    function createERC20Token(string memory name_, string memory symbol_, uint256 totalSupply_) public onlyOwner {

    myERC20Token instanceERCToken = new myERC20Token(name_, symbol_, totalSupply_);
    myERC20TokenList.push(instanceERCToken);
    
    }

    function get_myERC20Token() external view returns (myERC20Token[] memory) {
	return myERC20TokenList;
}

}