/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.5.0;

contract Token {
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    uint128 public _totalSupply;

    mapping(address => uint256) _balances;
    // mapping(address => bool) _allowed;
    mapping(address => mapping(address => uint256)) _allowed; // 중복 매핑 구현
    // mapping(address => uint256) _allowed2;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() public {
        _name = "MTK004";
        _symbol = "MTK004";
        _decimals = 18;
        _totalSupply = 10000* 10 **18;

        _balances[msg.sender] = _totalSupply;
        // _balances[0xA4cCCA3A8b2E7865541E86dcf11982031c814Bc0] = 100;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        // return 10000 * 1000000000000000000;
        // return 10000 * (10 ** 18);
        return _totalSupply;
        // return 10000 * (10 ** decimals());
    }
    
    function balanceOf(address _owner) public view returns (uint256) {
        // balance = _balances[_owner];
        return _balances[_owner]; 

    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_balances[msg.sender] >= _value);
        require(_balances[_to] + _value >= _balances[_to]);
        _balances[_to] += _value;
        _balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        
        
    }

    //위임할때 유용(최근 디파이에서 많이 사용), 이게 없으면 10000개 토큰에 모두 수수료를 넣어두어야 한다.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) { 
        //MSG_SENDER가 위임을 받았는지 확인이 필요
        // 위임 받은 수량이 얼마인지 확인(전송하려는 금액이, 위임받은 금액보다 작아야 한다.)
        // if (_allowed[msg.sender])
        require(_allowed[_from][msg.sender] >= _value);
        // require(_allowed[msg.sender]);
        require(_balances[_from] >= _value);
        require(_balances[_to] + _value >= _balances[_to]);
        _balances[_from] -= _value;
        _balances[_to] += _value;

        _allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
        
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        // 위임
        _allowed[msg.sender][_spender] = _value;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return _allowed[_owner][_spender];

    }

    function mint(address _to, uint128 _value) public returns(bool){
        // 토큰 추가 발행
        require(_balances[_to] + _value >= _balances[_to]);
        _balances[_to] += _value;
        _totalSupply += _value;
        emit Transfer( address(0), _to, _value);
        return true;

    }

    function burn(address _from, uint128 _value ) public returns(bool){
        // 토큰 소각
        require( _balances[_from] >= _value);
        _balances[_from] -= _value;
        _totalSupply -= _value;
        emit Transfer( _from, address(0), _value);
        return true;

    }

    
}