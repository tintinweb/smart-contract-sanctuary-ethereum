/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.5.0;

contract Token {

    /*
    string _name;
    string _symbol;
    uint8 _decimals;
    uint256 _totalSupply;
    */
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) _balances;
    //mapping(address => bool) _allowed;
    /*
    mapping(address => address[]) _allowed;
    mapping(address => uint256) _allowed2;
    */
    mapping(address => mapping(address => uint256)) _allowed;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() public {
        name = "WoongSikToken";
        symbol = "WST";
        decimals = 18;
        totalSupply = 1000 * (10 ** 18);

        //_balances[msg.sender] = totalSupply-1;
        //_balances[0x3098c4A30699a61Dfc1a3A2A4e1F3743a315DEf1] = 1;
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply); //etherscan
    }
    
    /*
    function name() public pure returns (string memory) {
        return "MyToken";
    }
    */

    /*
    function name() public view returns (string memory) {
        //return "MyToken";
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        //return "MTN";
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        //return 18; // 1 Eth = 1*10^18 Wei
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        //return 1000 * (10 ** uint256(decimals())); //return 1000 * 1000000000000000000;
        return _totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        //uint256 balance = _balance[_owner];
        //balance = _balance[_owner];
        //return balance;
        return _balance[_owner];
    }
    */
    
    function balanceOf(address _owner) public view returns (uint256) {
        //uint256 balance = _balances[_owner];
        //balance = _balances[_owner];
        //return balance;
        return _balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        /*
        require(_balances[msg.sender] >= _value);
        require(_balances[_to] + _value >= _balances[_to]);

        _balances[_to] += _value;
        _balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        */
        _transfer(msg.sender, _to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //require(_allowed[msg.sender]);
        require(_allowed[_from][msg.sender] >= _value);

        /*
        require(_balances[_from] >= _value);
        require(_balances[_to] + _value >= _balances[_to]);

        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        */
        _transfer(_from, _to, _value);

        _allowed[_from][msg.sender] -= _value;
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns(bool) {
        require(_balances[_from] >= _value);
        require(_balances[_to] + _value >= _balances[_to]);

        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);

        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    /*
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return _allowed[_owner][_spender];
    }
    */
    
    function allowance(address _owner, address _spender) public view returns (uint256){
        return _allowed[_owner][_spender];
    }

    /*
    function destruct() public returns(bool){
        selfdestruct(msg.sender);
    }
    */

    function mint(address _to, uint256 _value) public returns(bool){
        /*
        totalSupply += _value;

        _balances[msg.sender] += _value;
        emit Transfer(address(0), msg.sender, _value); //etherscan

        transfer(_to, _value);
        */
        totalSupply += _value;

        _balances[_to] += _value;
        emit Transfer(address(0), _to, _value); //etherscan

        return true;
    }

    function burn(address _from, uint256 _value) public returns(bool){
        /*
        transfer(_from, msg.sender, _value);

        _balances[msg.sender] -= _value;
        emit Transfer(msg.sender, address(0), _value); //etherscan
        
        totalSupply -= _value;
        */
        require(_balances[_from] >= _value);

        _balances[_from] -= _value;
        emit Transfer(_from, address(0), _value); //etherscan

        totalSupply -= _value;

        return true;
    }
}