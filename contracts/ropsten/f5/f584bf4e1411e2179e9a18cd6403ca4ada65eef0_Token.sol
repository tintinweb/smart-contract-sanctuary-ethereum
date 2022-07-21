/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.5.17;

contract Token {

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupplay;

    mapping (address => uint256) _balances;
    //      holder             spender    value
    mapping(address => mapping(address => uint256)) _allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() public {
        name = "My Token";
        symbol = "MTK";
        decimals = 18;
        totalSupplay = 10000 * 10 ** 18;

        _balances[msg.sender] = totalSupplay;
        emit Transfer(address(0), msg.sender, totalSupplay);
    }
    
    function balanceOf2(address _owner) public view returns (uint256 balance) {//returns에 변수 명 선언 시 함수 내  return  불필요
        balance = _balances[_owner];
    }

    function balanceOf(address _owner) public view returns (uint256) {//returns에 변수 명 선언 시 함수 내  return  불필요
         return _balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_balances[msg.sender] >= _value);
        require(_balances[_to] + _value >= _balances[_to]);
        //_to.transfer(_value);
        _balances[_to] = _balances[_to] + _value;
        _balances[msg.sender] = _balances[msg.sender] - _value;
        emit Transfer(msg.sender, _to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //MSG.SENDER 위임을 받았는지 확인 필요
        //위임받은 수량이 얼마인지 획인(전송하려는 금액이 위임받은 금액보다 적어야한다.)
        require(_allowed[_from][msg.sender] >= _value);

        // _transfer function으로 분리
        // require(_balances[msg.sender] >= _value);
        // require(_balances[_to] + value >= _balances[_to]);
        // //_to.transfer(_value);
        // _balances[_to] = _balances[_to] + _value;
        // _balances[msg.sender] = _balances[msg.sender] - _value;
        // emit Transfer(msg.sender, _to, _value);

        _allowed[_from][msg.sender] -= _value;
        _transfer(_from,_to,_value);
    }

    function _transfer(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_balances[_from] >= _value);
        require(_balances[_to] + _value >= _balances[_to]);
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from,_to,_value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender,_spender,_value);
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return _allowed[_owner][_spender];
    }

    function mint(address _to, uint256 _value) public returns(bool){
        require(_balances[_to] + _value >= _balances[_to]);

        _balances[_to] += _value;
        totalSupplay += _value;
        emit Transfer(address(0),_to,_value);
    }
    
    function burn(address _from, uint256 _value) public returns(bool){
        require(_balances[_from] + _value >= _balances[_from]);

        _balances[_from] -= _value;
        totalSupplay -= _value;
        emit Transfer(_from,address(0),_value);
    }
}