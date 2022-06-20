pragma solidity ^0.8.4;


contract Beerhound {
    string public name = "Beerhound token";
    string public symbol = "BRHND";
    uint256 public decimals = 8;

    uint256 public totalSupply = 1000;
    address public owner;

    // A mapping is a key/value map. Here we store each account balance.
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        // The totalSupply is assigned to transaction sender, which is the account
        // that is deploying the contract.
        _balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * The `external` modifier makes a function *only* callable from outside
     * the contract.
     */
    function transfer(address to, uint256 amount) external {

        require(_balances[msg.sender] >= amount, "Not enough tokens");

        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(owner, to, amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_balances[_from] >= _value, "Not enough tokens");
        require(_allowances[_from][msg.sender] >= _value, "Cannot withdraw that much tokens");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success){
        require(_spender != address(0));
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _fundsOwner, address _spender) public view returns (uint256 remaining){
        return _allowances[_fundsOwner][_spender];
    }

    function burn(address account, uint256 amount) public returns (bool success){
        require(msg.sender == owner);
        require(_balances[account] >= amount, "Not enough tokens to burn");
        return transferFrom(account, address(0), amount);
    }

    function mint(address account, uint256 amount) public returns (bool success){
        require(msg.sender == owner);
        _balances[account] += amount;
        return  true;
    }
}