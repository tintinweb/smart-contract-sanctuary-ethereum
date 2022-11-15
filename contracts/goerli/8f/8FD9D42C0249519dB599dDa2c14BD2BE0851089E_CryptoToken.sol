/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CryptoToken{
    address private owner;
    uint private _totalSupply;

    string private _name;
    string private _symbol;

    mapping(address => uint) private _balanceOf;
    mapping(address => mapping(address => uint)) private _allowances;

    constructor(string memory _tokenName, string memory _tokenSymbol){
        _name = _tokenName;
        _symbol = _tokenSymbol;
        owner = msg.sender;
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not allowed");
        _;
    }

    function name() public view returns (string memory){
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256 balance) {
        return _balanceOf[account];
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_balanceOf[msg.sender] >= _value, "Value not enough to sent");
        require(_to != address(0));

        _balanceOf[msg.sender] -= _value;
        _balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        _allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0) && _to != address(0));
        require(_allowances[_from][msg.sender] >= _value, "You are not allowed to send this value");
        require(_balanceOf[_from] >= _value, "The balance of who you are trying to send is insufficient");

        _balanceOf[_from] -= _value;
        _balanceOf[_to] += _value;

        _allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function mint(address account, uint amount) public onlyOwner{
        require(account != address(0));

        _totalSupply += amount;
        _balanceOf[account] += amount;
        
        emit Transfer(address(0), account, amount);
    }
}