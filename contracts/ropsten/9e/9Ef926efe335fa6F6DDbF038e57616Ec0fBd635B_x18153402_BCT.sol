/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: None
pragma solidity >=0.7.0 <0.9.0;
//noddy token standard
interface ERC20Interface {
function balanceOf(address account) external view returns (uint256);
function transfer(address recipient, uint256 amount) external returns (bool);
function totalSupply() external view returns (uint256);
event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
      function approve(address spender, uint256 amount) external returns (bool);
      function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
contract x18153402_BCT is ERC20Interface {

    uint256 _totalSupply;
    string _name;
    string _symbol;
    uint8 public decimals;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    // this is run when the contract is deployed on chain
    constructor() {
        _name = "x18153402_BCT";
        _symbol = "STDx18153402";
        decimals = 0;
        _totalSupply = 500000;
        _balances[msg.sender] = _totalSupply;

    }

function totalSupply() public view override returns (uint256) {
return _totalSupply;
}
    // this returns the token balance for a provided address
    function balanceOf(address add) public view override returns (uint256) {
        return _balances[add];
    }
    function allowance(address owner, address spender) external view returns (uint256){
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

//reducing amount from recipient
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