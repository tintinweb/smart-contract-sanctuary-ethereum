/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

// SPDX-License-Identifier: None

pragma solidity >=0.7.0 <0.9.0;

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

contract OurToken is ERC20Interface {

    uint256 _totalSupply;
    string _name;
    string _symbol;
    uint8 public decimals;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // this is run when the contract is deployed on chain
    constructor() {
        _name = "Shiba Ginu5";
        _symbol = "SHIB5";
        decimals = 18;
        // set the total supply to 1000000 tokens
        _totalSupply = 1000000 * 10**decimals;

        // give the total supply to the contract deployer
        _balances[msg.sender] = _totalSupply;
    }

    // returns the total supply of the token (should be 1000000)
    function totalSupply() public view override returns (uint256) {
    return _totalSupply;
    }

    // this returns the token balance for a provided address
    function balanceOf(address add) public view override returns (uint256) {
        return _balances[add];
    }

    function allowance(address owner, address spender) public override view returns (uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = msg.sender;

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function transfer(address toAddress, uint256 amount) public override returns (bool) {
        address fromAddress = msg.sender;

        _balances[fromAddress] = _balances[fromAddress] - amount;
        _balances[toAddress] = _balances[toAddress] + amount;

        emit Transfer(fromAddress, toAddress, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool){
        _balances[recipient] = _balances[recipient] - amount;
        emit Transfer(sender, recipient, amount);

        _allowances[sender][recipient] = amount;
        emit Approval(sender, recipient, amount);
        return true;
    }

    // returns the _name variable
    function name() public view returns (string memory){
        return _name;
    }

    // returns the _name variable
    function symbol() public view returns (string memory){
        return _symbol;
    }

}