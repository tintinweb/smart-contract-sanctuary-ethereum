/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.5.0;

//ERC20 토큰
contract Token {
    
    //상태변수에 public을 이용하면 자동 Get 할 수 있는 함수가 만들어진다.
    string  public name;
    string  public symbol;    
    uint8   public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) _balances;
    // holder > spender value 
    mapping(address => mapping(address => uint256)) _allowed;    //Table Create(2 Key value define) , 이중 매핑

    //Log 생성을 위해 define
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() public {
        name       = "SioToken001";
        symbol     = "STK1";
        decimals   = 18;
        totalSupply= 10000 * (10**18);          //Token 발행
        
        _balances[msg.sender] = totalSupply;    //Token 소유자 명시
        emit Transfer(address(0),msg.sender, totalSupply);  //Token 찍어서 누구한테 보낼 경우
    }
    
    /*
    //Token의 이름을 보여준다.
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;

    }
    
    function decimals() public view returns (uint8) {
        return _decimals;        
    }
    
    //Token 총 발행량
    function totalSupply() public view returns (uint256) {
        //return 1000 * 1000000000000000000;                
        //return 1000 * (10**18);
        //return 1000 * (10**decimals());
        return _totalSupply;
    }
    */

    /*
    function balanceOf(address _owner) public view returns (uint256 balance) {
        balance = _balances[_owner];    //별도로  Return을 하지 않아도 된다.
    }*/

    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    /* T_exa
    function transfer(address payable to, uint256 value) public payable{
       require( msg.sender==owner,"msg.sender != contract owner");
        to.transfer(value);
        emit Transfer(msg.sender, to, value);
        balance -=value; 
    }*/

    //Token 전송하는 기능
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_balances[msg.sender]   >= _value);         //송금하는 사람의 계좌 잔고보다 클 경우
        require(_balances[_to] + _value >= _balances[_to]); //받는 사람의 계좌 금액이 작아질 경우

        _balances[_to]        += _value; //전송할 금액 정의
        _balances[msg.sender] -= _value; //본인 계좌에서 차감하는 금액 정의
        emit Transfer(msg.sender, _to, _value);
        
    }
    
    //Token 전송을 제 3자가 수행하도록 하는 것(Approve 기능을 활용하여 위임을 할 수 있음)
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        /*// Msg.sender 위임을 받았는지 확인 필요
        // 위임 받은 수량이 얼마인지 확인(전송하려는 금액이, 위임받은 금액ㅂ다 적어야 한다.)
        require(_allowed[_from][msg.sender] >= _value);
        require(_balances[_from]        >= _value);         //송금하는 사람의 계좌 잔고보다 클 경우
        require(_balances[_to] + _value >= _balances[_to]); //받는 사람의 계좌 금액이 작아질 경우
        
        _balances[_from] -= _value;
        _balances[_to]   += _value;

        _allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);*/
    
        require(_allowed[_from][msg.sender]>= _value);
        _transfer(_from,_to,_value);
        _allowed[_from][msg.sender] -= _value;        
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal returns(bool){
        require(_balances[_from] >= _value);
        require(_balances[_to] + _value >= _balances[_to]);
        _balances[_from] -= _value;
        _balances[_to]   += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool success) {
        //제 3자에게 위임하는 함수
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return _allowed[_owner][_spender];

    }

    //contract 삭제될 경우 정보가 없어진다.
    function destruct() public returns(bool){
        selfdestruct(msg.sender);
    }

    //Token 추가하는 기능(누군가한테 준다는 개념)
    function mint(address _to, uint256 _value) public returns(bool){
        require(_balances[_to] + _value >= _balances[_to]);
        _balances[_to] += _value;
        totalSupply    += _value;
        emit Transfer(address(0), _to, _value); //새로 발행된거기 때문에 첫번째 주소로 설정한다.
        return true;        
    }

    //Token 삭제하는 기능
    function burn(address _from, uint256 _value) public returns(bool){
        require(_balances[_from]  >= _value);
        _balances[_from]  -= _value;
        totalSupply       -= _value;
        emit Transfer(_from, address(0) ,_value);
        return true;
    }


}