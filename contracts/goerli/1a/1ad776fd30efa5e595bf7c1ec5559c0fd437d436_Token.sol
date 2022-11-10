/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

pragma solidity ^0.8.0;
contract Token {
    string public name = "Mytoken";
    string public symbol = "MTN";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    

    mapping( address => uint256) _balances;
    mapping( address => mapping( address => uint256)) _allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() public {
        mint(msg.sender,1000000 * 10**decimals);
    }

    function mint(address _to, uint256 _value) public returns(bool){
        _balances[_to] += _value;
        totalSupply += _value;
        emit Transfer( address(0), _to, _value);
        return true;
    }
    function burn(address _from, uint256 _value) public returns(bool){
        _balances[_from] -= _value;
        totalSupply -= _value;
        emit Transfer(_from, address(0), _value);
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require( _value <= _allowed[_from][msg.sender]);
        _allowed[_from][msg.sender] -= _value;
        _transfer(_from,_to,_value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value ) internal returns(bool){
        require( _value <= _balances[_from]);
        _balances[_from]  -=  _value;
        _balances[_to]    +=  _value;
        emit Transfer(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return _allowed[_owner][_spender];
    }

    
}