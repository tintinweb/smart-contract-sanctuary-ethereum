//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

contract ERC20 {
    address owner;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    
    mapping (address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals){
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = 0;
    }
    
    modifier onlyOwner(){
    require(owner == msg.sender, "You are not owner");
    _;
    }
    
    function mint(address _to, uint _value) onlyOwner public {
        totalSupply += _value;
        balances[_to] += _value;
        emit Transfer(address(0), _to, _value);
    }
    
    function burn(uint _value) public {
        require(balances[msg.sender] >= _value, "not enough tokens");
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        emit Transfer(msg.sender, address(0), _value);
    }

    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint _value) public {
        require(balances[msg.sender] >= _value, "not enough tokens");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint _value) public {
        require(allowed[_from][msg.sender] >= _value, "no permission to spend");
        require(balances[_from] >= _value, "not enough tokens");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
    }
    
    function approve(address _spender, uint _value) public {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    function allowance(address _owner, address _spender) public view returns(uint) {
        return allowed[_owner][_spender];
    }
}