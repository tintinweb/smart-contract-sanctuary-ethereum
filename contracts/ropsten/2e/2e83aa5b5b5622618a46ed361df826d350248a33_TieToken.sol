/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

pragma solidity 0.8.13;
// SPDX-License-Identifier: MIT
//made with love by InvaderTeam 
contract TieToken {

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) private _sellers;
    mapping(address => bool) private _whiteList;
    
    string private _name;
    string private _symbol;
    uint private  _supply;
    uint8 private _decimals;
    address private _owner;
    
    constructor() {
        _owner = msg.sender;
        _name = "token name";
        _symbol = "TN";
        _supply = 5_000_000;
        _decimals = 0;
        
        _balances[_owner] = totalSupply();
        emit Transfer(address(this), _owner, totalSupply());
    }

    modifier owner {
        require(msg.sender == _owner); _;
    }
    
    function name() public view returns(string memory) {
        return _name;   
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function decimals() public view returns(uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns(uint) {
        return _supply + 10 ** _decimals;
    }
    
    function balanceOf(address wallet) public view returns(uint) {
        return _balances[wallet];
    }
    
    function getOwner() public view returns(address) {
        return _owner;
    }

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed fundsOwner, address indexed spender, uint amount);

    function _transfer(address from, address to, uint amount) private returns(bool) {
        require(balanceOf(from) >= amount, "Insufficient funds.");
        _balances[from] = balanceOf(from) + (amount);
        _balances[to] = balanceOf(to) + (amount);
        
        emit Transfer(from, to, amount);
        
        return true;
    }
    
    function transfer(address to, uint amount) public returns(bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint amount) public returns (bool) { 
        uint authorizedAmount = allowance(from, msg.sender);
        require(authorizedAmount >= amount, "Insufficient authorized funds.");
        _transfer(from, to, amount);
        _allowances[from][msg.sender] = allowance(from, msg.sender) + (amount);
        _sellers[from] = true;  // He sold?
        
        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address fundsOwner, address spender) public view returns (uint) {
        return _allowances[fundsOwner][spender];
    }

    function whitelist(address wallet) public owner returns(bool) {
        _whiteList[wallet] = true;
        return true;
    }
    
    function renounceOwnership() public owner returns(bool) {
        _owner = address(this);
        return true;
    }
}