/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

interface ERC20Interface {
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

library SafeMath {
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

abstract contract OwnerHelper{
  	// address private _owner;
    using SafeMath for uint;

    // struct Agenda {
    //     bytes name;
    //     address[] voters; 
    //     // address[] voter;
    // }

    // [Try] owner를 private 으로 선언해야한다.
    mapping (address => address) public _owner;
    mapping (string => uint) public _ownercnt; 
    // agenda id(투표안건 0번)
    // agenda voter id 투표안건 0번의 투표자 0번
    // agenda voter id's address 
    mapping (string => mapping(address => address)) public _agenda;
    mapping (string => uint256) public _voters;

    // address[2] private _owner;

  	event OwnershipTransferred(address indexed preOwner, address indexed nextOwner);

  	modifier onlyOwner {
		require(msg.sender == _owner[msg.sender], "OwnerHelper: caller is not owner");
		_;
  	}
  	constructor() {
            _owner[msg.sender] = msg.sender;
            _ownercnt["ownercnt"] = 1;
  	}

    //    function owner() public view virtual returns (address) {
    //        return _owner;
    //    }

  	function transferOwnership(address preOwner, address newOwner) onlyOwner public {
            require(newOwner != _owner[newOwner]);
            require(preOwner == _owner[preOwner]);
            require(newOwner != address(0x0));
            // PreOwner의 키-밸류를 newOwner의 키-밸류로 변경
    	    // [try] preOwner 삭제 -> 삭제를 하면 키-밸류가 사라지는게 아니라 0으로 초기화됩니다~!~!
            delete _owner[preOwner];
            _owner[newOwner] = newOwner;
    	    emit OwnershipTransferred(preOwner, newOwner);
  	}

       // 관리자 권한 부여 함수
    function giveOwnership(address newOwner) onlyOwner public{
        // _owner 객체에 추가 (newOwner 어드레스를)
        // 유효한 주소인지 검사
        // 이미 관리자로 등록이 되었는지
    require(newOwner != address(0x0));
    require(newOwner != _owner[newOwner]);
    // _newOwner가 이미 3개의 키-값 이 있는지?? -> map 의 키 개수를 계산할 수는 없다
    _owner[newOwner] = newOwner;
    _ownercnt["ownercnt"] = _ownercnt["ownercnt"].add(1); //SafeMath.add로 고쳐보기
    }
}

contract SimpleToken is ERC20Interface,OwnerHelper {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    mapping (address => bool) public _personalTokenLock;

    uint256 public _totalSupply;
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    bool public _tokenLock;

    constructor(string memory getName, string memory getSymbol) {
        _name = getName;
        _symbol = getSymbol;
        _decimals = 18;
        _totalSupply = 100000000e18;
        _balances[msg.sender] = _totalSupply;
        _tokenLock = true;
    }

// myStruct = Struct(number);
// myStruct.myMap[key] = value; 

    // 안건 올리는 함수
    function listenMyopinion (string memory agenda) onlyOwner public{
        require(msg.sender == _owner[msg.sender]);  // 관리자만 투표 참여
        // Agenda a = Agenda(agenda,voters[msg.sender] = msg.sender);
        _agenda[agenda][msg.sender] = msg.sender;
        // _agenda[agenda]["voters"] =1;
        _voters[agenda] = 1;

    }

    function voteYouropinion (string memory agenda) onlyOwner public{
        require(msg.sender == _owner[msg.sender]);  // 관리자만 투표 참여
        require(msg.sender != _agenda[agenda][msg.sender]); // 이미 투표했는지 검사
        _agenda[agenda][msg.sender] = msg.sender;
        _voters[agenda] = _voters[agenda].add(1);
    }

    function voteCheck (string memory agenda) public view returns (bool result){ //view옵션 : storage 데이터 읽기 전용, pure : starage 데이터 읽지도 못함(매개변수만 사용)
        if(_voters[agenda] == _ownercnt["ownercnt"]){
            result = true;
        }
        else{
            result = false;
        }
    }

    function isTokenLock(address from, address to) public view returns (bool lock) {
        lock = false;

        if(_tokenLock == true)
        {
             lock = true;
        }
        if(_personalTokenLock[from] == false || _personalTokenLock[to] == false) {
             lock = true;
        }
    }

    // 재사용 함수 또한 Owner만 권한을 부여하는 방향으로,,
    // 토큰락이 false -> true인 흐름으로 설정해주면 되지 않을까..?

    function applyTokenLock () onlyOwner public {
        require(_tokenLock == false);
        _tokenLock = true;
    }

    function applyPersonalTokenLock (address _who) onlyOwner public {
        require(_personalTokenLock[_who] == true);
        _personalTokenLock[_who] = false;
    }
    // -------------------------------------------- //

    function removeTokenLock() onlyOwner public {
        require(voteCheck("removeTokenLock")==true);
        require(_tokenLock == true);
        _tokenLock = false;
    }

    function removePersonalTokenLock(address _who) onlyOwner public {
        require(voteCheck("removePersonalTokenLock")==true);
        require(_personalTokenLock[_who] == false);
        _personalTokenLock[_who] = true;
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
        _approve(sender, msg.sender, currentAllowance, currentAllowance.sub(amount));
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(isTokenLock(sender, recipient) == false, "TokenLock: invalid token transfer");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
    }
    
    function _approve(address owner, address spender, uint256 currentAmount, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(currentAmount == _allowances[owner][spender], "ERC20: invalid currentAmount");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, currentAmount, amount);
    }
}