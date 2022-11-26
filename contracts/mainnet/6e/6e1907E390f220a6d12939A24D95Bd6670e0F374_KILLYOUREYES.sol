/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title KILLYOUREYES
/// @author LUCAzz85Hz
/// @notice DON'T WORK IT!
/// @custom:website www.killyoureyes.org
/// @custom:email [email protected]
contract KILLYOUREYES {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address payable _author;
    string private _clue;
    uint256 private _price;
    uint8 private _tax;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value); // IERC20
    event Approval(address indexed _owner, address indexed _spender, uint256 _value); // IERC20

    constructor() {
        _name = "KILLYOUREYES";
        _symbol = "KYE";
        _decimals = 0;
        _totalSupply = 0;
        _author = payable(msg.sender);
        _clue = unicode"𑀉𑀦𑁆𑀫𑀢𑁆𑀢𑀕𑀻𑀢𑀸";
        _price = type(uint32).max; // KYE / Wei
        _tax = 25; // %
    }

    modifier author() {
        require(msg.sender == _author, "DON'T WORK IT!");
        _;
    }

    modifier fee(uint256 _fee) {
        _fee = _fee * _tax / 100;
        _balances[msg.sender] -= _fee;
        _totalSupply -= _fee;
        emit Transfer(msg.sender, address(0), _fee);
        _;
    }

    function name() public view returns (string memory) { // IERC20
        return _name;
    }

    function symbol() public view returns (string memory) { // IERC20
        return _symbol;
    }

    function decimals() public view returns (uint8) { // IERC20
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) { // IERC20
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) { // IERC20
        return _balances[_owner];
    }

    function getAuthor() public view returns (address) {
        return _author;
    }

    function getClue() public view returns (string memory) {
        return _clue;
    }

    function getPrice() public view returns (uint256) {
        return _price;
    }

    function getTax() public view returns (uint8) {
        return _tax;
    }

    function transfer(address _to, uint256 _value) public fee(_value) returns (bool success) { // IERC20
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public fee(_value) returns (bool success) { // IERC20
        _allowances[_from][msg.sender] -= _value;
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) { // IERC20
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) { // IERC20
        return _allowances[_owner][_spender];
    }

    function setDecimals(uint8 _newDecimals) public author returns (bool success) {
        _decimals = _newDecimals;
       return true;
    }

    function setAuthor(address payable _newAuthor) public author returns (bool success) {
        _author = _newAuthor;
       return true;
    }

    function setClue(string memory _newClue) public author returns (bool success) {
        _clue = _newClue;
       return true;
    }

    function setPrice(uint256 _newPrice) public author returns (bool success) {
        _price = _newPrice;
       return true;
    }

    function setTax(uint8 _newTax) public author returns (bool success) {
        _tax = _newTax;
       return true;
    }

    function mint(uint256 _value) public author returns (bool success) {
        _balances[msg.sender] += _value;
        _totalSupply += _value;
        emit Transfer(address(0), msg.sender, _value);
       return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        _balances[msg.sender] -= _value;
        _totalSupply -= _value;
        emit Transfer(msg.sender, address(0), _value);
       return true;
    }

    function buy() public payable {
        _balances[msg.sender] += msg.value * _price;
        _totalSupply += msg.value * _price;
        emit Transfer(address(0), msg.sender, msg.value * _price);
        _author.transfer(msg.value);
    }
}