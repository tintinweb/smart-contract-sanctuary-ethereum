/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.5.0;

contract Token {
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() public {
        name = "PSB01";
        symbol = "PSB01";
        decimals = 18;
        totalSupply = 10000 * 10**18;

        _balances[msg.sender] = totalSupply;
    }
  
    function balanceOf(address _owner) public view returns (uint256 balance) {
        balance = _balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_balances[msg.sender] >= _value);
        require(_balances[_to] + _value >= _balances[_to]);
        _balances[_to]          += _value;
        _balances[msg.sender]   -= _value;
        emit Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // MSG.SENDER 위임을 받았는지 확인 필요
        // 위임 받은 수량이 얼마인지 확인(전송하려는 금액이, 위임받은 금액보다 적어야함)
        require(_allowed[_from][msg.sender] >= _value);

        require(_balances[_from] >= _value);
        require(_balances[_to]   >= _balances[_to]);
        
        _balances[_from] -= _value;
        _balances[_to]   += _value;
        
        _allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        //위임
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return _allowed[_owner][_spender];
    }

    function mint(address _to, uint256 _value) public returns(bool) {
        _balances[_to] += _value;
        
        totalSupply    += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }
    
    function burn(address _from, uint256 _value) public returns(bool){
        require(_balances[_from] >= _value);

        _balances[_from] -= _value;
        return true;
    }
}