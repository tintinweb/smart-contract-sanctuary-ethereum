/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

pragma solidity ^0.5.0;

contract Token {
    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;

    address payable public  contractManager;
    //contractManager가 mint, burn을 실행할 수 있도록 변경

    mapping ( address => uint256) _balances;
    mapping ( address => mapping( address => uint256) ) _allowed;
    mapping ( address => bool ) public _isFreeze;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() public {
        name = "MTK007";
        symbol = "MTK7";
        decimals = 18;
        totalSupply = 10000* 10**18;

        _balances[msg.sender] = totalSupply;
        emit Transfer( address(0) ,msg.sender, totalSupply);
        contractManager = msg.sender;
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
        require( _isFreeze[_from] == false );
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
        //관리자만 실행할수 있도록
        require( msg.sender == contractManager );
        _mint(_to,_value);
        return true;
    }

    function _mint( address _to, uint256 _value) internal returns(bool){
        require( _balances[_to] + _value >= _balances[_to]);

        _balances[_to] += _value;
        totalSupply += _value;
        emit Transfer( address(0), _to, _value);
        return true;        
    }

    function burn( address _from, uint256 _value) public returns (bool){
        require( msg.sender == contractManager );
        require( _balances[_from] >= _value);

        _balances[_from] -= _value;
        totalSupply -= _value;
        emit Transfer( _from, address(0), _value);
        return true;
    }

    function freeze( address _target ) public returns(bool){
        require( msg.sender == contractManager);
        _isFreeze[_target] = true;
        return true;
    }

    function unFreeze( address _target ) public returns(bool){
        require( msg.sender == contractManager);
        _isFreeze[_target] = false;
        return true;
    }

    function () external payable {
        uint256 eth = msg.value;
        uint256 token = eth * 100;
        _mint(msg.sender, token);

        contractManager.transfer(eth);
    }

}