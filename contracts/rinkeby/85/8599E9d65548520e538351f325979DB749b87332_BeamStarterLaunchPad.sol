/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
abstract contract Context {
	function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }   
	function _msgData() internal view virtual returns (bytes memory) {
		this; 
		return msg.data;
	}
}

abstract contract Ownable is Context {
	address private _owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor () {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}
	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		emit OwnershipTransferred(_owner, address(0));
		_owner = address(0);
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		emit OwnershipTransferred(_owner, newOwner);
		_owner = newOwner;
	}
}

library SafeMath {
	function tryAdd (uint a,  uint b) internal pure returns (bool,  uint) {
		uint c = a + b;
		if (c < a) return (false, 0);
		return (true, c);
	}

	function trySub (uint a,  uint b) internal pure returns (bool,  uint) {
		if (b > a) return (false, 0);
		return (true, a - b);
	}

	function tryMul (uint a,  uint b) internal pure returns (bool,  uint) {
		if (a == 0) return (true, 0);
		uint c = a * b;
		if (c / a != b) return (false, 0);
		return (true, c);
	}

	function tryDiv (uint a,  uint b) internal pure returns (bool,  uint) {
		if (b == 0) return (false, 0);
		return (true, a / b);
	}

	function tryMod (uint a,  uint b) internal pure returns (bool,  uint) {
		if (b == 0) return (false, 0);
		return (true, a % b);
	}

	function add (uint a, uint b) internal pure returns (uint) {
		uint c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	function sub (uint a, uint b) internal pure returns (uint) {
		require(b <= a, "SafeMath: subtraction overflow");
		return a - b;
	}

	function mul (uint a, uint b) internal pure returns (uint) {
		if (a == 0) return 0;
		uint c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}
	function div (uint a, uint b) internal pure returns (uint) {
		require(b > 0, "SafeMath: division by zero");
		return a / b;
	}

	function mod (uint a, uint b) internal pure returns (uint) {
		require(b > 0, "SafeMath: modulo by zero");
		return a % b;
	}

	function sub (uint a, uint b, string memory errorMessage) internal pure returns(uint) {
		require(b <= a, errorMessage);
		return a - b;
	}

	function div (uint a, uint b, string memory errorMessage) internal pure returns(uint) {
		require(b > 0, errorMessage);
		return a / b;
	}

	function mod (uint a, uint b, string memory errorMessage) internal pure returns(uint) {
		require(b > 0, errorMessage);
		return a % b;
	}
}

interface IERC20 {
	function name() external view returns(string memory);
	function symbol() external view returns(string memory);
	function decimals() external view returns(uint8);
	function totalSupply() external view returns(uint);

	function balanceOf(address account) external view returns(uint);
	function transfer(address recipient,    uint amount) external returns(bool);
	function allowance(address owner, address spender) external view returns(uint);
	function approve(address spender,   uint amount) external returns (bool);
	function transferFrom(address sender, address recipient,    uint amount) external returns (bool);
	
	event Transfer(address indexed from, address indexed to,    uint value);
	event Approval(address indexed owner, address indexed spender,  uint value);
}

contract ERC20 is Context, IERC20 {
	using SafeMath for uint;
	mapping (address => uint) private _balances;
	mapping (address => mapping (address => uint)) private _allowances;
	uint private _totalSupply;
	string private _name;
	string private _symbol;
	uint8 private _decimals;
	constructor (string memory name_, string memory symbol_)  {
		_name = name_;
		_symbol = symbol_;
		_decimals = 18;
	}
	function name() public view virtual override returns (string memory) {
		return _name;
	}

	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	function decimals() public view virtual override returns (uint8) {
		return _decimals;
	}

	function totalSupply() public view virtual override returns(uint) {
		return _totalSupply;
	}
	function balanceOf(address account) public view virtual override returns(uint) {
		return _balances[account];
	}

	function transfer(address recipient,    uint amount) public virtual override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view virtual override returns(uint) {
		return _allowances[owner][spender];
	}

	function approve(address spender,   uint amount) public virtual override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient,uint amount) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);
		_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
		return true;
	}

	function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
		return true;
	}

	function _transfer(address sender, address recipient,   uint amount) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(sender, recipient, amount);

		_balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
		_balances[recipient] = _balances[recipient].add(amount);
		emit Transfer(sender, recipient, amount);
	}

	function _mint(address account, uint amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply = _totalSupply.add(amount);
		_balances[account] = _balances[account].add(amount);
		emit Transfer(address(0), account, amount);
	}

	function _burn(address account, uint amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		_balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
		_totalSupply = _totalSupply.sub(amount);
		emit Transfer(account, address(0), amount);
	}

	function _approve(address owner, address spender,   uint amount) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	function _setupDecimals(uint8 decimals_) internal virtual {
		_decimals = decimals_;
	}

	function _beforeTokenTransfer(address from, address to, uint amount) internal virtual { }
}

library Address {
	function isContract(address account) internal view returns (bool) {
		uint size;
		assembly { size := extcodesize(account) }
		return size > 0;
	}

	function sendValue(address payable recipient, uint amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");

		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
	  return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(address target, bytes memory data, uint value) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}

	function functionCallWithValue(address target, bytes memory data, uint value, string memory errorMessage) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");
		(bool success, bytes memory returndata) = target.call{ value: value }(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed");
	}

	function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");

		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed");
	}

	function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}

library SafeERC20 {
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
		_callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove( IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }


    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


contract BeamStarterLaunchPad is Ownable {
	string public NAME;
	using SafeMath for uint;
	using SafeERC20 for ERC20;

	address payable public constant bstr = 0xddD6b394CC2563012a22E2cd21119F9713DfDae6;  //BSTR token
	uint[4] private  tiers = [
		1000 * 1e18,
		2000 * 1e18,
		3000 * 1e18,
		4000 * 1e18
	];


	uint private constant feeRate = 1000; // 10%

	struct IDOPool {
		address tokenAddress;
		address receiveToken;
		address receiveWallet;
		uint startTime;
		uint endTime;
		uint closeTime;
		uint minPurchase;
		uint maxPurchase; 
		uint totalToken; //total sale token for this pool
		uint totalSold; //total number of token sold
		uint price;  //price per token
		uint tier;  //1,2,3,4
	}

	mapping(address => IDOPool) private pools;
	mapping(address => uint) private rewards;

	constructor(){
		 NAME = "BeamStarter: LaunchPad";
	}

	function addPool(
		address _tokenAddress,
		address _receiveToken,
		address _receiveWallet,
		uint _startTime,
		uint _endTime,
		uint _minPurchase,
		uint _maxPurchase, 
		uint _totalToken, //total sale token for this pool
		uint _price,  //price per token
		uint _tier  //1,2,3,4
	) public onlyOwner {
		require(_tokenAddress!=address(0), "Pool: tokenAddress is zero");
		require(_receiveToken!=address(0), "Pool: receiveToken is zero");
		require(_receiveWallet!=address(0), "Pool: receiveWallet is zero");
		require(Address.isContract(_tokenAddress), "Pool: tokenAddress is not ERC20");
		require(Address.isContract(_receiveToken), "Pool: receiveToken is not ERC20");
		require(Address.isContract(_receiveWallet), "Pool: receiveWallet is not ERC20");
		require(_tier>=1 && _tier<=tiers.length, "Pool: tier should be 1 ~ 4");
		uint feePertier = tiers[_tier - 1];
		ERC20(bstr).safeTransferFrom(msg.sender, address(this), feePertier);
		ERC20(_tokenAddress).safeTransferFrom(msg.sender, address(this), _totalToken);
		
		IDOPool memory newPool = IDOPool({
			tokenAddress:	_tokenAddress,
			receiveToken:	_receiveToken,
			receiveWallet:	_receiveWallet,
			startTime:		_startTime,
			endTime:		_endTime,
			closeTime:		0,
			minPurchase:	_minPurchase,
			maxPurchase:	_maxPurchase,
			totalToken:		_totalToken,
			totalSold:		0,
			price:			_price,
			tier:			_tier
		});

		pools[_tokenAddress] = newPool;
		rewards[_tokenAddress] = 0;
	}

	function emergencyWithdraw(address _token) public onlyOwner {
		require(msg.sender!=address(0), "Pools: sender is zero");
		IDOPool memory pool = pools[_token];
		ERC20(_token).safeTransfer(msg.sender, pool.totalToken);
	}

	function rewardOf(address _token) public view onlyOwner  returns(uint) {
		return rewards[_token];
	}

	function climbRewards(address _token) public onlyOwner {
		IDOPool memory pool = pools[_token];
		require(msg.sender!=address(0), "Pools: sender is zero");
		require(rewards[_token]!=0, "Pools: reward is zero");
		ERC20(pool.receiveToken).safeTransfer(msg.sender, rewards[_token]);
	}

	function withdraw(address _token) public {
		IDOPool memory pool = pools[_token];
		require(pool.receiveWallet==msg.sender, "Pools: is not owner");
		uint amount = pool.totalSold.mul(pool.price);
		uint fee = amount.mul(feeRate).div(1e4);
		rewards[_token] += fee;
		ERC20(pool.receiveToken).safeTransfer(pool.receiveWallet, amount - fee);
	}

	function buy(address _token) public payable {
		IDOPool memory pool = pools[_token];
		require(block.timestamp >= pool.startTime && block.timestamp <= pool.endTime, "invalid time");
		uint remainToken = getRemainToken(_token);
		if (remainToken <= pool.minPurchase) {
			pool.closeTime = block.timestamp;
		}
		uint amount = msg.value;
		require(amount <= pool.maxPurchase, "invalid maximum contribute");
		require(amount >= pool.minPurchase, "invalid minimum contribute");
		pool.totalSold += amount;
		ERC20(_token).safeTransfer(msg.sender, amount);
	}

	function getRemainToken(address _token) public view returns(uint) {
		return pools[_token].totalToken.sub(pools[_token].totalSold);
	}

	function getTokenActiveStatus(address _token) public view returns (uint)
	{
		IDOPool memory pool = pools[_token];
		uint nowTime = block.timestamp;
		if(nowTime < pool.startTime){
			return 1;
		}else if(nowTime >= pool.startTime && nowTime <= pool.endTime){
			return 2;
		}else if(nowTime > pool.closeTime){
			return 3;
		}
		return 4;
	}
	function getTokenTotalSupply(address _token) public view returns (uint){
		IDOPool memory pool = pools[_token];
		return pool.totalToken;
	}
	
	function getTokenTotalSold(address _token) public view returns (uint){
		IDOPool memory pool = pools[_token];
		return pool.totalSold;
	}

	function getPoolInfo(address _token) public view returns (IDOPool memory)
	{
		IDOPool memory pool = pools[_token];
		return pool;
	}

	receive() external payable {}

}