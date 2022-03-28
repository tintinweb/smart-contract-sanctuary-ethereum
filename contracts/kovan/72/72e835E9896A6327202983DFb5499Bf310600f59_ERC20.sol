//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract ERC20 {
    string _name;
    string _symbol;
    uint private _totalSupply;
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowToPay;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    address _owner;

    constructor (string memory _initName, string memory _initSymbol) {
        _name = _initName;
        _symbol = _initSymbol;
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "you are not an owner");
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns(uint){
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns(uint) {
        return _balances[owner];
    }

    function transfer(address to, uint amount) public returns (bool){
        require(_balances[msg.sender] >= amount, "transfer: transfer amount exceeds balance");

        _balances[msg.sender] -= amount;
        _balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint amount) public returns (bool) {
        _allowToPay[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public returns (bool) {
        require(_balances[from] >= amount, "transferFrom: transfer amount exceeds balance");
        require(_allowToPay[from][msg.sender] >= amount, "transferFrom: transfer amount exceeds allowed amount");

        _allowToPay[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowToPay[owner][spender];
    }

    function increaseAllowance(address spender, uint addValue) public returns (bool) {
        require(spender != address(0), "0 address is not allowed");

        uint currentAllow = _allowToPay[msg.sender][spender];
        uint newAllow = currentAllow + addValue;

        _allowToPay[msg.sender][spender] = newAllow;

        emit Approval(msg.sender, spender, newAllow);
        return true;
    }

    function decreaseAllowance(address spender, uint subValue) public returns (bool) {
        require(spender != address(0), "0 address is not allowed");
        require(_allowToPay[msg.sender][spender] >= subValue, "subValue exceeds allowed amount");

        _allowToPay[msg.sender][spender] -= subValue;

        emit Approval(msg.sender, spender, _allowToPay[msg.sender][spender]);
        return true;
    }

    function mint(address recipient, uint amount) public onlyOwner returns (bool) {
        _totalSupply += amount;
        _balances[recipient] += amount;

        emit Transfer(address(0), recipient, amount);
        return true;
    }

    function burn(uint amount) public onlyOwner {
        require(_balances[msg.sender] >= amount, "burn amount exceeds balance");

        _totalSupply -= amount;
        _balances[msg.sender] -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }
}