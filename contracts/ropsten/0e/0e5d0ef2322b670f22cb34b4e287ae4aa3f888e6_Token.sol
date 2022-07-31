/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

pragma solidity >=0.7.0 <0.9.0;

contract Token{

string public name;
string public symbol;
uint256 public decimals;
uint256 public totalSupply;

mapping(address => uint256) public balanceOf;
mapping(address => mapping(address => uint256)) public allowance;

event Transfer(address indexed _from , address indexed _to , uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 amount);

constructor(string memory _name, string memory _symbol,uint256 _decimals ,uint256 _totalSupply){
 name = _name;
 symbol = _symbol;
 decimals = _decimals;
 totalSupply = _totalSupply;
 balanceOf[msg.sender] = totalSupply;
}

function transfer(address _to , uint256 _amount) public returns(bool success){
    require(balanceOf[msg.sender] >= _amount);
    _transfer(msg.sender,_to,_amount);
    return true;
}

function _transfer(address _from , address _to , uint256 _amount) internal {
    require(_to != address(0));
    balanceOf[msg.sender] -= _amount;
    balanceOf[_to] += _amount;

    emit Transfer(_from,_to,_amount);
}

function approve(address _spender , uint256 _amount) external returns(bool){
    require(_spender != address(0));
    allowance[msg.sender][_spender] = _amount;
    emit Approval(msg.sender, _spender, _amount);
    return true;
}

function transferFrom(address _from, address _to, uint256 _amount) external returns(bool){
    require(balanceOf[_from] >= _amount);
    require(allowance[_from][msg.sender] >= _amount);

    allowance[_from][msg.sender] -= _amount;
    _transfer(_from, _to ,_amount);
    return true ;

}

}