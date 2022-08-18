/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

/* Bitcoin Classic 
Creator: 0xdf35485444B0BcB78D7c75fF5F41a2f7e00AA218 
Owner: 0xe136aA13F88256Dc5D1E8Febf8bd3183137941d1*/

pragma solidity 0.8.13;

contract BitcoinClassic {

    address public admin;

    string private _name = "Bitcoin Classic";
    string private _symbol = "BXC";
    uint256 private _totalSupply = 600148 * 10 ** 18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        admin = msg.sender;
        _balances[msg.sender] = _totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(_balances[msg.sender] >= value);
        _balances[msg.sender] -= value;
        _balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(_balances[from] >= value && _allowances[from][msg.sender] >= value);
        _allowances[from][msg.sender] -= value;
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns(bool) {
        require(spender != msg.sender);
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns(uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address owner) public view returns(uint256) {
        return _balances[owner];
    }

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public pure returns(uint8) {
        return 18;
    }

}