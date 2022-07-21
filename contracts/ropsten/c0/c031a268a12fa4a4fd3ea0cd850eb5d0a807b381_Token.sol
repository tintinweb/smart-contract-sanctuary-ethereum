/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.5.0;

contract Token {
    // string _name;
    // string _symbol;
    // uint8 _decimals;
    // uint256 _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping( address => uint256 ) _balances;
    // mapping( address => bool ) _allowed;
    // mapping( address => address[] ) _allowed;
        //   holder              spender    value
    mapping( address => mapping( address => uint256 ) ) _allowed;
        //   spender    value
    // mapping( address => uint256 ) _allowed2;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() public {
        // _name = "MyToken";
        // _symbol = "MTK";
        // _decimals = 18;
        // _totalSupply = 10000 * (10 ** 10);
        name = "MyToken2";
        symbol = "MTK2";
        decimals = 18;
        totalSupply = 10000 * 10**uint256(decimals);//10000 * 10**18;
        // 1000000000000000000 = 10 ** 18
        // 10000 * (10 ** 18)
        // 10000 * (10 ** uint256(decimals()))

        _balances[msg.sender] = totalSupply;
        // _balances[0x5f235EDb2f944477Eb4AB7b55E730291dDBAe085] = 100;

        emit Transfer( address(0), msg.sender, totalSupply );
    }
    
    // function name() public view returns (string memory) {
    //     return _name;
    // }
    
    // function symbol() public view returns (string memory) {
    //     return _symbol;
    // }
    
    // function decimals() public view returns (uint8) {
    //     return _decimals;
    // }
    
    // function totalSupply() public view returns (uint256) {
    //     return _totalSupply;
    // }
    
    // function balanceOf(address _owner) public view returns (uint256 balance) {
    function balanceOf(address _owner) public view returns (uint256) {
        // balance = _balances[_owner];
        return _balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // require( _balances[msg.sender] >= _value );
        // require( _balances[_to] + _value >= _balances[_to] );
        // _balances[_to] += _value;
        // _balances[msg.sender] -= _value;
        // emit Transfer( msg.sender, _to, _value );
        _transfer (msg.sender, _to, _value);
    }

    // '찰스' 호출
    // msg.sender = 호출 주체 = 찰스
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // MSG_SENDER 위임을 받았는지 확인이 필요.
        // require( _allowed[msg.sender] );
        // 위임 받은 수량이 얼마인지 확인 (전송하려는 금액이, 위임받은 금액보다 적어야한다.)
            //            엘리스 찰스
        require( _allowed[_from][msg.sender] >= _value);
        _allowed[_from][msg.sender] -= _value;

        // require( _balances[_from] >= _value );
        // require( _balances[_to] + _value >= _balances[_to] );
        // _balances[_from] -= _value;
        // _balances[_to] += _value;
        // emit Transfer( _from, _to, _value );
        _transfer (_from, _to, _value);
    }
    
    function _transfer (address _from, address _to, uint256 _value) internal returns(bool) {
        require( _balances[_from] >= _value );
        require( _balances[_to] + _value >= _balances[_to] );
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer( _from, _to, _value );

        return true;
    }

    // '엘리스' 호출
    // msg.sender = 호출 주체 = 엘리스
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // 위임
            //   엘리스       찰스
        _allowed[msg.sender][_spender] = _value;
        emit Approval (msg.sender, _spender, _value);
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return _allowed[_owner][_spender];
    }

    function destuct() public returns(bool) {
        selfdestruct(msg.sender);
    }

    /* 실습 : 추가발행 */
    function mnit ( address _to, uint256 _value ) public returns(bool) {
        require( _balances[_to] + _value >= _balances[_to] );

        _balances[_to] += _value;
        totalSupply += _value;
        emit Transfer ( address(0), _to, _value );
        return true;
    }
    function burn (address _from, uint256 _value) public returns(bool) {
        require( _balances[_from] >= _value );

        _balances[_from] -= _value;
        totalSupply -= _value;
        emit Transfer ( _from, address(0), _value );
        return true;
    }
}