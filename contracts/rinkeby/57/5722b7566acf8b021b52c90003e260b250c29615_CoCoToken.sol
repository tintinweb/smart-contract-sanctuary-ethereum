/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface InterERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
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

abstract contract OwnerHelper {
    using SafeMath for uint;

    // [Try] owner를 private 으로 선언해야한다.
    mapping (address => address) internal _owner;
    mapping (string => uint) internal _ownercnt; 
    mapping(address => uint256) internal _balances;
    // agenda id(투표안건 0번)
    // agenda voter id 투표안건 0번의 투표자 0번
    // agenda voter id's address 
    mapping (string => mapping(address => address)) internal _agenda;
    mapping (string => uint256) internal _voters;

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
    	    // preOwner 삭제 -> 삭제를 하면 키-밸류가 사라지는게 아니라 0으로 초기화됩니다.
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
    require(_balances[newOwner] >= 5);
    require(newOwner != _owner[newOwner]);
    // _newOwner가 이미 3개의 키-값 이 있는지?? -> map 의 키 개수를 계산할 수는 없다
    _owner[newOwner] = newOwner;
    _ownercnt["ownercnt"] = _ownercnt["ownercnt"].add(1); //SafeMath.add로 고쳐보기
    }
}

contract CoCoToken is Context, InterERC20, OwnerHelper {
    using SafeMath for uint256;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 public _decimals;

    constructor() {
        _name = "CoCo Farm Token";
        _symbol = "CoCo";
        _decimals = 6;
        _totalSupply = 100000000 * (10 ** _decimals);
        _balances[msg.sender] = _totalSupply; 
    }


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

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function isOwner(address account) public view returns (bool) {
        require(account == _owner[account]);
        return true;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {_approve(owner, spender, currentAllowance - subtractedValue);}
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {_balances[from] = fromBalance - amount;}
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {_balances[account] = accountBalance - amount;}
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {_approve(owner, spender, currentAllowance - amount);}
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}