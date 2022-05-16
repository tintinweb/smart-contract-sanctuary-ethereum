/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

pragma solidity ^0.4.23;

contract Husten {

    string public name = "Husten";
    string public symbol = "HUS";
    uint8 public decimals = 0;
    
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => uint256) balances;

    event Transfer(address indexed _sender, address indexed _recipient, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _sender, uint256 _value);

    address owner;
    uint256 supply;

    constructor(uint _supply) public {
        owner = msg.sender;
        balances[msg.sender] = _supply;
        supply = _supply;
    }
    
    function () external payable {
        approve(msg.sender, msg.value);
        transferFrom(msg.sender, owner, msg.value);
    }

    function totalSupply() public view returns (uint256) { 
        return supply;
    }

    function balanceOf(address account) public view returns (uint256) { 
        return balances[account]; 
    }

    function allowance(address _owner, address delegate) public view returns (uint) {
        return allowed[_owner][delegate];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender], "Require: Balance");

        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transfer(address _recipient, uint256 _value) public returns (bool) { 
        require(_recipient != address(0), "Require: Address");
        require(_value <= balances[msg.sender], "Require: Balance");

        balances[msg.sender] -= _value;
        balances[_recipient] += _value;
        
        emit Transfer(msg.sender, _recipient, _value); 

        return true; 
    }

    function transferFrom(address _sender, address _recipient, uint256 _value) public returns (bool) {
        require(_recipient != address(0), "Require: Address");
        require(_value <= balances[_sender], "Require: Balance");
        require(_value <= allowed[_sender][msg.sender], "Require: Allowed Balance");

        balances[_sender] -= _value;
        balances[_recipient] += _value;
        allowed[_sender][msg.sender] -= _value;
        
        emit Transfer(_sender, _recipient, _value);

        return true;
    }

    function mint(address _recipient, uint256 _value) public returns (bool success) {
        require(msg.sender == owner, "Require: Owner");
        require(_recipient != address(0), "Require: Address");
        
        balances[_recipient] += _value;
        supply += _value;

        emit Transfer(owner, _recipient, _value);

        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Require: Amount");
        
        balances[msg.sender] -= _value;
        supply -= _value;
        
        emit Burn(msg.sender, _value);
        
        return true;
    }

    function ownerAddress(address _recipient) public returns (bool success) {
        require(msg.sender == owner, "Require: Owner");

        owner = _recipient;

        return true;
    }


    function ownerChange(address _recipient) public returns (bool success) {
        require(msg.sender == owner, "Require: Owner");

        transfer(_recipient, balances[msg.sender]);
        owner = _recipient;

        return true;
    }
}