/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

pragma solidity ^0.5.0;

contract Token {
    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;

    mapping ( address => uint256) _balances;
    mapping ( address => mapping( address => uint256) ) _allowed;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() public {
        name = "Mytoken100";
        symbol = "MTK100";
        decimals = 18;
        totalSupply = 10000* 10**18;

        _balances[msg.sender] = totalSupply;
        emit Transfer( address(0) ,msg.sender, totalSupply);
    }
    
    
    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
       require(_allowed[_from][msg.sender] >= _value);
        _transfer(_from,_to,_value);
        _allowed[_from][msg.sender] -= _value; 
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns(bool){
        require( _balances[_from] >= _value);
        require( _balances[_to] + _value >= _balances[_to]);
        _balances[_from] -= _value;
        _balances[_to]   += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256){
        return _allowed[_owner][_spender];
    }

    function mint( address _to, uint256 _value) public returns(bool){
    
    }

    function burn( address _from, uint256 _value) public returns (bool){

    }

}