//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Token20 {

    uint256 public _totalSupply; // total number of tokens

    mapping(address => uint256) private _balances; // the number of tokens each user has
    mapping(address => mapping(address => uint256)) private _allowances; // information who entrusted their money to whom

    string public name; // name of token
    string public symbol; // symbol of token
    uint8 public decimals; // number of decimals
    address private _owner; // address of an owner
    address private _bridge; // address of a bridge
    bool bridgeConnected; // is bridge connected or not

    modifier requireBridgeOrOwner {
        require(msg.sender == _owner || msg.sender == _bridge, "Not a bridge or an owner");
        _;
    }

    constructor (string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _owner = msg.sender;
    }

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    // getters
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    // transfers token to another user
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_balances[msg.sender] >= _value, "Not enough tokens");
        require(_to != address(0), "Enter correct address");
        
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // uses with function "approve", send tokens from another user to another user
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_allowances[_from][msg.sender] >= _value, "You try to transfer more than allowed");
        require(_balances[_from] >= _value, "Not enough tokens");
        require(_to != address(0), "Enter correct address");

        _allowances[_from][msg.sender] -= _value;
        _balances[_from] -= _value;
        _balances[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    // approves someone to use your tokens
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Enter correct address");

        _allowances[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // also getter
    function allowance(address owner, address _spender) public view returns (uint256) {
        return _allowances[owner][_spender];
    }

    // connects bridge to contract
    function connectBridge (address bridge_) public requireBridgeOrOwner {
        bridgeConnected = true;
        _bridge = bridge_;
    }

    // deletes tokens from system
    function burn(address account, uint256 amount) public requireBridgeOrOwner {
        require(amount <= _balances[account], "Not enough tokens");

        _totalSupply -= amount;
        _balances[account] -= amount;

        emit Transfer(account, address(0), amount);
    }

    // adds token to system
    function mint(address account, uint256 amount) public requireBridgeOrOwner {
        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }
}