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
    uint256 _totalSupply;
    string private _name;
    string public _symbol;
    uint8 public _decimals;

    // set up a balances mapping
    // a mapping is like hash table, or a dictionary
    // or like a two-column spreadsheet
    // index-> value
    mapping(address => uint256) private _balances;

    constructor() {

        // **msg.sender** is the account that digitally signed the tx
        owner = msg.sender;
 
        _totalSupply = 1000000 * 10**uint(_decimals); // multiple by decimals

        _symbol = "KM";
        _name = "KittyMeow";

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
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool){
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool){
        return true;
    }

}