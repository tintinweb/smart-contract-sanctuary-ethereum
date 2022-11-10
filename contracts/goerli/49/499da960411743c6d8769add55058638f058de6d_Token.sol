/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

pragma solidity ^0.8.0;

contract Token {
    string public name = "MyToken";
    string public symbol = "MTk";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) _balance;
    mapping(address => mapping(address => uint256)) _allowed;
            // owner => mapping
                        // spender => amount()

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() public {
        totalSupply = 10000 * 10**decimals;
        _balance[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    /*function findIndexof(address _holder) public view returns(uint256){
        for(uint256 i=0;i<holders.length;i++){
            if(holders[i] == _holder){
                return i;
            }
        }
        revert("holder not exist");
    } */

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balance[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value <= _balance[msg.sender]);
        _balance[msg.sender] -= _value;
        _balance[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= _allowed[_from][msg.sender]);
        require(_value <= _balance[_from]);
        _allowed[_from][msg.sender] -= _value;
        _balance[_from] -= _value;
        _balance[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
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