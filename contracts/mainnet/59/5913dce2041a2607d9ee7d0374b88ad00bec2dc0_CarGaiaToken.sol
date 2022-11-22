/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.13;


contract Ownable {
    address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

contract Pausable is Ownable {
  event Pause(address account);
  event Unpause(address account);

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }


  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause(msg.sender);
  }

  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause(msg.sender);
  }

}

contract BlackList is Ownable {

	mapping (address => bool) public blackListed;

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

    function getBlackListStatus(address _maker) external view returns (bool) {
        return blackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function addBlackList (address _evilUser) public onlyOwner {
        blackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        blackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

	modifier isBlackListed(address _user) {
		require(!blackListed[_user]);
		_;
  	}

}

interface IERC20 {
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
	function approve(address spender, uint value) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function transferFrom(address from, address to, uint value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

contract ERC20 is IERC20, Pausable, BlackList{

	string public name;
    string public symbol;
    uint public decimals;
	uint public totalSupply;

    mapping(address => uint) public balances;

	mapping (address => mapping (address => uint)) public allowed;


    function transfer(address _to, uint _value) public isBlackListed(msg.sender) whenNotPaused returns (bool) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
		return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

	function approve(address _spender, uint _value) public returns (bool) {
		allowed[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint) {
		return allowed[_owner][_spender];
	}

	function transferFrom(address _from, address _to, uint _value) public isBlackListed(_from) whenNotPaused returns (bool) {
		allowed[_from][msg.sender] -= _value;
		balances[_from] -= _value;
		balances[_to] += _value;
		emit Transfer(_from, _to, _value);
		return true;
	}


}

contract CarGaiaToken is ERC20 {

	uint public initTime;

	address public sale;
	address public community;
	address public advisor;
	address public ecosystem;
	address public foundation;
	address public team;

	struct CliffVesting{
		uint lockTotal;
		uint unlockTotal;
	}

	mapping(address => CliffVesting) public cliffVesting;

    constructor(
		uint _initialSupply, string memory _name, string memory _symbol, uint _decimals,
		address _sale,address _community,address _advisor,
		address _ecosystem,address _foundation,address _team) {

        totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

		initTime = block.timestamp;

		sale = _sale;
		community = _community;
		advisor = _advisor;
		ecosystem = _ecosystem;
		foundation = _foundation;
		team = _team;

		//Total: 18% + 15% = 33%   Unlock: 15%*100% = 15%
		initBalances(_initialSupply, _sale, 3300, 1500);
		//Total: 6% + 6% = 12%   Unlock: 6%*5% + 6%*5% = 0.6%
		initBalances(_initialSupply, _community, 1200, 60);
		//Total: 5%   Unlock: 0
		initBalances(_initialSupply, _advisor, 500, 0);
		//Total: 20%   Unlock: 20%*2% = 0.4%
		initBalances(_initialSupply, _ecosystem, 2000, 40);
		//Total: 15%   Unlock: 15%*5%  = 0.75%
		initBalances(_initialSupply, _foundation, 1500, 75);
		//Total: 15%   Unlock: 0
		initBalances(_initialSupply, _team, 1500, 0);

    }

	function initBalances(uint _initialSupply, address _owner, uint _tn, uint _uln) private {
	    uint _total = _initialSupply*_tn/10000;
		uint _value = _initialSupply*_uln/10000;
		uint _lock = _total - _value;
		cliffVesting[_owner].lockTotal = _lock;
		if(_value > 0){
			balances[_owner] = _value;
			emit Transfer(address(0x0), _owner, _value);
		}
	}

	function unlock(address _owner) public {
		uint _unlockOf = unlockOf(_owner);
		require(_unlockOf > 0);
		cliffVesting[_owner].unlockTotal += _unlockOf;
	    balances[_owner] += _unlockOf;
	    emit Transfer(address(0x0), _owner, _unlockOf);
	}

    function unlockOf(address _owner) public view returns (uint) {
		uint _times = block.timestamp - initTime;
		uint _lockTotal = cliffVesting[_owner].lockTotal;
		if(_lockTotal <= 0){
			return 0;
		}
		uint _unlockTotal = cliffVesting[_owner].unlockTotal;
		if(_unlockTotal == _lockTotal){
			return 0;
		}
		//1 day = 86400 seconds
		//1 week = 7 days
		//1 years = 365 days
		//1 years = 52 weeks
		uint _unlock;
		if(_owner == sale){
			if(_times < 31536000){
				return 0;
			}
			_times = _times - 31536000;
			//12 months cliff 20%
			_unlock = _lockTotal*20/100;
			//remaining 80% daily vesting for 48 months
			_unlock += vesting(_lockTotal - _unlock, _times, 86400, 1460);
		}else if(_owner == community || _owner == foundation){
			//weekly unlock for 24 months
			_unlock = vesting(_lockTotal, _times, 604800, 104);
		}else if(_owner == advisor || _owner == team){
			//5 years vesting and 12-month cliff
			_unlock = vesting(_lockTotal, _times, 31536000, 5);
		}else{
			//daily vesting for 24 months
			_unlock = vesting(_lockTotal, _times, 86400, 730);
		}
		if(_unlock > _lockTotal){
			return _lockTotal - _unlockTotal;
		}
        return _unlock - _unlockTotal;
    }

	function vesting(uint256 a, uint256 b, uint256 c, uint256 d) internal pure returns (uint256) {
	    return a*(b/c)/d;
	}

}