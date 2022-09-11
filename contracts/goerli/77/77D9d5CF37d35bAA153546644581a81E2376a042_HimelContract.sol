/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {

    string name_ ;
    string symbol_ ;
    uint8 decimal_ ;
    uint256 tSupply;
    mapping (address => uint256) balances;
    address owner;

    constructor(string memory _name, string memory _symbol, uint8 _decimal) {
        name_ = _name;
        symbol_ = _symbol;
        decimal_ = _decimal;
        //balances[msg.sender] = tSupply;
        owner = msg.sender; // deployer
    }
    function name() public view returns (string memory) {
        return name_;
    }
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    function decimals() public view returns (uint8) {
        return decimal_;
    }
    function totalSupply() public view returns (uint256) {
        return tSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
       // balance = balances[_owner];
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) public virtual returns (bool success) {
        require(balances[msg.sender]>= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // transferFrom - spender
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balances[_from]>= _value, "Insufficient balance");
        require(allowed[_from][msg.sender]>= _value, "Not enough allowance available");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from,_to,_value);
        return true;
    }

    // approve - _from will approve spender to spend tokens from his account.
    mapping (address => mapping(address => uint256)) allowed;   // Owner => spender => amount
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        remaining = allowed[_owner][_spender];
        //return allowed[_owner][_spender];
    }

    function icreaseAllowance(address _spender, uint256 _value)public returns (bool) {
        allowed[msg.sender][_spender] += _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    function decreaseAllowance(address _spender, uint256 _value)public returns (bool) {
        require(allowed[msg.sender][_spender]>=_value, "Not enough allowance to decrease");
        allowed[msg.sender][_spender] -= _value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }

    function mint (address _addr, uint256 _value) public {
        require(owner == msg.sender, "Only owner");
        tSupply += _value;
        // 1. To address calling the fn
        //    balances[msg.sender] += _value;
        // 2. To owner of contract
        //      balances[owner] += _value;
        // 3. to a specified address
        balances[_addr] += _value;
    }
    
    function burn (uint256 _amount) public {
        require(owner == msg.sender, "Only owner");
        tSupply -= _amount;
        balances[msg.sender] -= _amount;
    }
    // burn

}

contract HimelContract is ERC20 {

    constructor (uint256 _tsupply) ERC20("HimelContract", "HML",0)  {
        mint(owner, _tsupply);

    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balances[msg.sender]>= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value*90/100;
        balances[owner] += _value*10/100;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
}

contract RoohiContract is ERC20 {

    constructor (uint256 _tsupply) ERC20("RoohiContract", "ROO", 2) {
        mint(owner, _tsupply);
    }


}