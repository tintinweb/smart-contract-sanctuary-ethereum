/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

interface ERC20Interface { //ERC20 인터페이스
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address spender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Transfer(address indexed spender, address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 oldAmount, uint256 amount);
}

library SafeMath { // 언더플로, 오버플로 제어를 도와주는 라이브러리 SafeMath
// internal option -> 컨트랙트 내부에서만 사용
// pure option -> 함수가 단순 연산의 결과값만 반환, 상태 변수를 읽거나 쓰지 않음

// require가 아닌 assert를 쓰는 이유 : assert는 계약 실행 전에 확인 불가, require는 계약 실행 전에 확인 가능
  	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
  	}

  	function div(uint256 a, uint256 b) internal pure returns (uint256) {
	    uint256 c = a / b;
		return c;
  	}

  	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
  	}

  	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

//관리자용 함수 Ownerhelper
// abstract contract : 컨트랙트 구현기능과 interface 추상화 기능 포함
// 실제 컨트랙트에서 사용하지 않으면 추상으로 표시하여 사용 X
abstract contract Ownerhelper{
    address private _owner; //관리자

    event OwnershipTransferred(address indexed preOwner, address indexed nextOwner); // 관리자가 변경되었을 때 이전 관리자의 주소, 새 관리자의 주소 로그 남기는 이벤트

    modifier onlyOwner{ // 함수 실행 이전에 함수 실행시키는 사람이 관리자인지 확인
        require(msg.sender == _owner, "Ownerhelper : caller is not owner");
        _;
    }

    constructor(){
        _owner = msg.sender;
    }
    
    function owner() public view virtual returns (address){
        return _owner;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != _owner);
        require(newOwner != address(0x0));
        _owner = newOwner;
        emit OwnershipTransferred(_owner,newOwner);
    }
}

contract SimpleToken is ERC20Interface, Ownerhelper {
    using SafeMath for uint256; //uint256에 대해서 SafeMath 라이브러리 사용 (언더플로, 오버플로 방지)
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    uint256 public _totalSupply;
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    bool public _tokenLock;
    mapping (address => bool) public _personalTokenLock;
    
    constructor(string memory getName, string memory getSymbol) {
        _name = getName;
        _symbol = getSymbol;
        _decimals = 18;
        _totalSupply = 100000000e18;
        _balances[msg.sender] = _totalSupply;
        // _personalTokenLock = true;
        _tokenLock = true;
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
    
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint amount) external virtual override returns (bool) {
        uint256 currentAllownace = _allowances[msg.sender][spender];
        require(currentAllownace >= amount, "ERC20: Transfer amount exceeds allowance");
        _approve(msg.sender, spender, currentAllownace, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        emit Transfer(msg.sender, sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance, currentAllowance.sub(amount)); // currentAllowance.sub(amount) => SafeMath를 활용한 안전한 연산
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(isTokenLock(sender,recipient)==true, "TokenLock : invalid token transfer"); // 토큰락 검사, 보내는 사람과 받는 사람중 락이 걸리면 토큰 전송 불가
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance.sub(amount); // SafeMath sub
        _balances[recipient] = _balances[recipient].add(amount);// SafeMath add
    }
    
    //TokenLock : 토큰의 전체 락에 대한 처리
    // tokenPersonalLick : 토큰의 개인 락에 대한 처리

    // isTokenLock : 전체 락, 보내는 사람의 락, 받는 사람의 락을 검사하여 락이 걸려 있는지 확인하는 함수 
    function isTokenLock(address from, address to) public view returns (bool lock){
        lock = true;

        if(_tokenLock == false){
            lock = false;
        }
        if(_personalTokenLock[from] == false && _personalTokenLock[to]== false){
            lock = false;
        }
    }

    // onlyOwner : 예시

    // removeTokenLock, removePersonalTokenLock : 토큰락 해제 함수, 관리자만 락을 해제할 수 있도록 제어해야 함
    // 이렇게 락을 적용하면 모든 락을 해제할 때만 토큰의 이동이 가능
    function removeTokenLock() onlyOwner public{
        require (_tokenLock == true);
        _tokenLock = false;
    }

    // onlyOwner : 예시
    function removePersonalTokenLock (address _who) onlyOwner public{
        require(_personalTokenLock[_who] == true);
        _personalTokenLock[_who] = false;
    }

    function _approve(address owner, address spender, uint256 currentAmount, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(currentAmount == _allowances[owner][spender], "ERC20: invalid currentAmount");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, currentAmount, amount);
    }
}