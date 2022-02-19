/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface ERC20Interface {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    

    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract SimpleCoin is ERC20Interface{

    address public owner;
    uint256 private _totalSupply;
    string private _name;
    string public _symbol;
    uint8 private _decimals;

    // set up a balances mapping
    // a mapping is like hash table, or a dictionary
    // or like a two-column spreadsheet
    // index-> value
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {

        // **msg.sender** is the account that digitally signed the tx
        owner = msg.sender;
        _decimals = 18;
        _totalSupply = 1000000 * 10**uint(_decimals); // multiple by decimals

        _symbol = "NOT_TOK";  //insert your own symbol here
        _name = "Token McTokenFace"; //give it your own name here

        // assign all of total supply to the owner
        _balances[owner] = _totalSupply;
    }

    function balanceOf(address account) public view override returns(uint256) {
        return _balances[account];
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint256) {
        return _decimals;
    }


    function transfer(address account, uint256 amount) public override returns(bool) {
        address from = msg.sender;
        address to = account;
        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount;
        emit Transfer(from, account, amount);
        return true;
    }

    function totalSupply() public view override returns(uint256) {
        return _totalSupply;
    }

    function allowance(address owner_allowance, address spender) public view virtual override returns (uint256) {
        return _allowances[owner_allowance][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool){
        address approver = msg.sender;
        _allowances[approver][spender] = amount;
        emit Approval(approver, spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool){
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);

        _allowances[sender][recipient] = amount;
        emit Approval(sender, recipient, amount);
        return true;
    }

}