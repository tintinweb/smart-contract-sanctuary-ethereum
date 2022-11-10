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
    mapping( address => mapping(address => uint256)) _allowed;
        //owner -> mapping
                //(address => uint256)
                //(spender => amount)

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() public {
        totalSupply = 10000 * 10**decimals;
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply); //새로운 토큰이 발행되었음을 의미
        mint(msg.sender, totalSupply);
    }
    
    function mint(address _to, uint256 _value) public returns (bool) {
        //추가발행
        _balances[_to] += _value;
        totalSupply += _value;
        //이벤트 발생
        emit Transfer(address(0), _to, _value);
        //종료
        return true;
    }

    //소각함수
    function burn(address _from, uint _value) public returns (bool) {
        _balances[_from] -= _value;
        totalSupply -= _value; //totalSupply에서 없어진 것
        emit Transfer(_from, address(0), _value);
        return true;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require( _value <= _balances[msg.sender]);
        _balances[msg.sender]  -=  _value;
        _balances[_to]         +=  _value;

        // 누가, 누구한테, 얼마를 보냈는지
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
         /*
         require( _value <= _balances[_from]);
				 _balances[_from]  -=  _value;
         _balances[_to]    +=  _value;
         */
         //approve 여부 확인
         require(_value <= _allowed[_from][msg.sender]); //승인한 금액보다 보내려는 금액이 적을때
         require(_value <= _balances[_from]); //잔고보다 보내려는 금액이 적을때 가능
        
         //_allowed 업데이트
         _allowed[_from][msg.sender] -= _value;
        
         _balances[_from]  -=  _value;
         _balances[_to]    +=  _value;

         return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowed[msg.sender][_spender] = _value;
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return _allowed[_owner][_spender];
    }

    
}