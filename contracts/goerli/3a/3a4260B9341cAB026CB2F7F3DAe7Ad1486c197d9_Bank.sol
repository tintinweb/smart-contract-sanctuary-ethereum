/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

pragma solidity ^0.8.0;

struct LockInfo{
    uint256 unlockTime;
    uint256 amount;
}
contract DeFiToken {
    string public name = "BANK Token";
    string public symbol = "BTK";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address public owner;


    mapping( address => uint256) _balances;
    mapping( address => mapping( address => uint256)) _allowed;
    mapping( address => bool ) public isFreeze;
    mapping( address => LockInfo[]) public lockup;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier onlyOwner(){
        require( msg.sender == owner,"msg.sender is not owner");
        _;
    }

    modifier notFreeze(address _holder){
        require( isFreeze[_holder] == false );
        _;
    }
    
    constructor() public {
        owner = msg.sender;
    }

    function freeze( address _holder ) public onlyOwner returns(bool){
        isFreeze[_holder] = true;
        return true;    
    }

    function unfreeze( address _holder ) public onlyOwner returns(bool){
        isFreeze[_holder] = false;
        return true;
    }

    function mint(address _to, uint256 _value) public onlyOwner returns(bool){
        _mint(_to,_value);
        return true;
    }

    function _mint(address _to, uint256 _value) internal returns(bool){
        _balances[_to] += _value;
        totalSupply += _value;
        emit Transfer( address(0), _to, _value);
        return true;
    }

    function burn(address _from, uint256 _value) public onlyOwner returns(bool){
        _balances[_from] -= _value;
        totalSupply -= _value;
        emit Transfer(_from, address(0), _value);
        return true;
    }

    function lockedBalancOf( address _owner) public view returns(uint256){
        uint256 lockedBalance = 0;
        for( uint256 i=0;  i < lockup[_owner].length ; i++){
            lockedBalance += lockup[_owner][i].amount;
        }
        return lockedBalance;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner] + lockedBalancOf(_owner);
    }
    
    function transfer(address _to, uint256 _value) public notFreeze(msg.sender) returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public notFreeze(_from) returns (bool success) {
        require( _value <= _allowed[_from][msg.sender]);
        _allowed[_from][msg.sender] -= _value;
        _transfer(_from,_to,_value);
        return true;
    }

    function unlock(address _owner) public returns(bool){
        for( uint256 i=0;  i < lockup[_owner].length ; ){
            if( lockup[_owner][i].unlockTime < block.timestamp ){
                _balances[_owner] += lockup[_owner][i].amount;
                
                // 리스트 마지막에 위치한 정보를 현재 인덱스로 복사
                lockup[_owner][i] = lockup[_owner][lockup[_owner].length-1];
                //리스트 마지막 위치의 정보를 삭제 
                lockup[_owner].pop();
            }
            else{
                i++;
            }
        }
    }

    function _transfer(address _from, address _to, uint256 _value ) internal returns(bool){
        if( lockup[_from].length > 0){
            unlock(_from);
        }
        
        require( _value <= _balances[_from]);
        _balances[_from]  -=  _value;
        _balances[_to]    +=  _value;
        emit Transfer(_from, _to, _value);
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return _allowed[_owner][_spender];
    }

    fallback () external payable{
        _mint(msg.sender, msg.value*1);
        _lock( msg.sender, msg.value*1);
        payable(owner).transfer(msg.value);
    }

    function _lock(address _holder, uint256 _amount) internal returns(bool){
        //구매시점에서 5분후에 사용가능하게
        lockup[_holder].push(
            LockInfo(block.timestamp + 15 seconds,
                    _amount)
        );
        _balances[_holder] -= _amount;
    }

    function destroy() public {
        selfdestruct( payable(msg.sender));
    }

    
}

struct StakeInfo{
    uint256 stakeStart;
    uint256 amount;
}

contract Bank {
    string  public BankName="MyBank";
    mapping(address => uint256) public balance;
    mapping( string => IERC20) public tokens;
    mapping( IERC20 => mapping(address => StakeInfo[]) ) public stakes;
    address public owner;

    DeFiToken public defitoken;


    event Deposit (address from, uint256 value);
    event Withdraw(address to, uint256 value);

    constructor() payable{
        balance[msg.sender] = msg.value;
        owner = msg.sender;
        defitoken = new DeFiToken();
    }

    modifier onlyOwner(){
        require( msg.sender == owner,"msg.sender is not owner");
        _;
    }

    function deposit() public payable {
        balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value); 
    }

    function withdraw(uint256 value) public payable  {
        balance[msg.sender] -=value;
        payable(msg.sender).transfer(value);
        emit Withdraw(msg.sender, value);
    }

    function stake( string memory symbol, uint256 amount) public returns(bool){
        IERC20 token = tokens[symbol];
        require(address(token) != address(0));

        token.transferFrom( msg.sender, address(this), amount );
        //예치를 시작한 날짜, 금액을 저장
        stakes[token][msg.sender].push(
            StakeInfo(block.timestamp, amount)
        );
    }

    function unstake( string memory symbol, uint256 idx) public returns(bool){
        IERC20 token = tokens[symbol];
        require(address(token) != address(0));
        require(idx < stakes[token][msg.sender].length);
        // 예치한 정보를 불러와서
        StakeInfo memory info = stakes[token][msg.sender][idx];
        // 이자를 계산하고,
        uint256 duration = block.timestamp - info.stakeStart;
        // amount * 이자율 * (예치기간/1년);
        // amount * (10/100) * (예치기간/1년);
        uint256 coupon = info.amount * 10 * duration / 100 / 1 hours;
        // 이자 토큰을 지급하고,
        defitoken.mint( msg.sender, coupon);

        // symbol에 해당하는 토큰을 되돌려준다.
        token.transfer(msg.sender, info.amount);

        stakes[token][msg.sender][idx] = stakes[token][msg.sender][stakes[token][msg.sender].length -1];
        stakes[token][msg.sender].pop();
    }

    function registToken(IERC20 token) public {
        string memory sym = token.symbol();
        tokens[sym] = token;
    }

    fallback () external payable{
        deposit();
    }
}


interface IERC20 {
    function symbol() external view returns(string memory);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}