/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract ERC20Template {

    constructor (string memory _name, string memory _symbol) {
        name_ = _name;
        symbol_ = _symbol;
        decimal_ = 0;
     //  tSupply = 1000;
        balances[msg.sender] = tSupply; // deploy
        admin = msg.sender;
    }
    address admin;
    string name_;
    string symbol_;
    uint8 decimal_;
    uint256 tSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    mapping (address => uint256) balances;

    function name() public view returns (string memory){
        return name_;
    }
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    function decimals() public view returns (uint8) {
        return decimal_;
    }
    function totalSupply() public view returns (uint256){
        return tSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];

    }
    function transfer(address _to, uint256 _value) public returns (bool success){
        require( balances[msg.sender]>= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require( balances[_from]>= _value, "Insufficient balance");
        require(allowed[_from][msg.sender]>= _value, "Not enough allowance");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from,_to, _value);
        return true;

    }
    mapping (address => mapping(address => uint256)) allowed;
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];

    }
    // increase / decrease of allowance
    function increaseAllowance(address _spender, uint256 _value) public returns(bool){
        allowed[msg.sender][_spender] += _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function decreaseAllowance(address _spender, uint256 _value) public returns(bool){
        require(allowed[msg.sender][_spender]>=_value, "Not enough allowance to decrease");
        allowed[msg.sender][_spender] -= _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    // mint  & burn
    function mint(address _addr, uint256 _value) public returns(bool){
        require(msg.sender == admin, "Only admin");
        tSupply += _value;
        // Mint to msg.sender
        // balances[msg.sender] += _value;
        // // Mint to admin
        // balances[admin] += _value;
        
        // Mint to an address.
        balances[_addr] += _value;

        emit Transfer(address(0),_addr,_value);
        return true;

    }

    function burn (address _user, uint256 _value) public returns(bool){
        require(msg.sender == admin, "Only admin");
        require( balances[_user]>= _value, "Insufficient balance to burn");
        require(allowance(_user,admin)>= _value, "Not enough allowance to burn");
        tSupply -= _value;
        balances[_user] -= _value;
        allowed[_user][admin] -= _value;
        return true;
    }


}

contract Movement is ERC20Template {

    constructor (uint256 _value) ERC20Template("MovementToken","MMT") {
        mint(msg.sender,_value);
    }
}