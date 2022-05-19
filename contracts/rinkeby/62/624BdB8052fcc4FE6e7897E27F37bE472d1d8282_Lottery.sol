// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/*
        █▄░█ █▀▀ ▀█▀   █░░ █▀█ ▀█▀ ▀█▀ █▀▀ █▀█ █▄█
        █░▀█ █▀░ ░█░   █▄▄ █▄█ ░█░ ░█░ ██▄ █▀▄ ░█░

		Lottery on our website:
		https://lottery.com
		Author: chenjiejie
		
*/


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


contract Lottery is Ownable{
	string public Name = "NFT Drop Platform";
	using SafeMath for uint;
	using SafeERC20 for ERC20;

	address private immutable perc;  //PERC token
	address private immutable storeWallet;  //PERC Token Store Wallet
	
	uint public  lotteryStartTime;
	uint public  lotteryEndTime;
	uint private lotteryWinnerRate = 50;
	uint private  totalSupply;
	uint private  totalSold; 
	uint private  totalWined; 

	uint[4] private  percs = [
		100 * 1e18,
		1000 * 1e18,
		10000 * 1e18,
		100000 * 1e18
	];
	uint[4] private  periods = [
		0,
		7776000,
		31104000,
		124416000
	];
	event getTicket(address indexed tokenAddress, address indexed account, uint value);
	event Claim(address indexed tokenAddress, address indexed account, uint value);
	event Lottery(address indexed tokenAddress, address indexed account,  uint value);

	struct StakingToken {
		address account;
		uint startTime;
		uint endTime;
		uint amount;
		uint period;
		uint ticket; 
		uint itemSize;
		uint itemCost;
		uint claimTime;
		uint claimedToken;
	}

	mapping(address => StakingToken) private stakings;
	mapping(address => uint) private ticketBalances;
	mapping(uint => address) private ticketOwners;

	constructor(address _perc, address _storeWallet,  uint _startTime, uint _endTime) {
		perc = _perc;
		storeWallet = _storeWallet;
		lotteryStartTime = _startTime;
		lotteryEndTime = _endTime;
		totalSupply = 10000;
	}

	function setWinnerRate(uint _rate) public onlyOwner{
		lotteryWinnerRate = _rate;
	}
	function setStartTime(uint _start) public onlyOwner{
		lotteryStartTime = _start;
	}

	function setEndTime(uint _end) public onlyOwner{
		lotteryEndTime = _end;
	}

	function getRemainToken(address _account) public view returns(uint) {
		return stakings[_account].amount.sub(stakings[_account].claimedToken);
	}

	function getTotalSupply() public view returns(uint) {
		return totalSupply;
	}
	function getTotalSold() public view returns(uint) {
		return totalSold;
	}
	function getTotalWined() public view returns(uint) {
		return totalWined;
	}
	function getLotteryStartTime() public view returns(uint) {
		return lotteryStartTime;
	}
	function getLotteryEndTime() public view returns(uint) {
		return lotteryEndTime;
	}
	function getTicketOf(address _account) public view returns(uint) {
		return ticketBalances[_account];
	}
	function getStakingInfoOf(address _account) public view returns(StakingToken memory) {
		return stakings[_account];
	}

	function isLotteryActived() public view returns(bool) {
		return block.timestamp >= lotteryStartTime && block.timestamp <= lotteryEndTime;
	}
	
	function isStakingActived(address _account) public view returns(bool) {
		StakingToken memory stoken = stakings[_account];
		uint startTime = stoken.startTime;
		uint endTime = stoken.endTime;
		return block.timestamp >= startTime && block.timestamp <= endTime;
	}

	function getTickets(uint _tokens, uint _period,  uint _itemSize, uint _itemCost) public  {
		uint tokenCount = percs[_tokens.sub(1)];
		uint ticketCount = _tokens.mul(_period);
		uint period = periods[_period.sub(1)];
		address account = msg.sender;
		require(account!=address(0), "Lottery: msg sender is zero");
		ERC20(perc).safeTransferFrom(msg.sender, address(this), tokenCount);
		StakingToken memory newStaking = StakingToken({
			account : account,
			startTime : block.timestamp,
			endTime : block.timestamp.add(period),
			amount : tokenCount,
			period : period,
			ticket : ticketCount,
			itemSize : _itemSize,
			itemCost : _itemCost,
			claimTime : 0,
			claimedToken : 0
		});
		stakings[account] = newStaking;
		for(uint i=1; i<=ticketCount; i++){
			ticketOwners[totalSold.add(i)] = account;
		}
		ticketBalances[account] = ticketCount;
		totalSold = totalSold + ticketCount;
		emit getTicket(perc, account, ticketCount);
	}
	
	function getClaim(uint _amount) public {
		address _account = msg.sender;
		require(_account != address(0), "Claim: mint to the zero address");
		require(!isStakingActived(_account), "Claim: token locked");
		require(getRemainToken(_account) >= _amount, "Claim: not enough token");
		ERC20(perc).safeTransfer(msg.sender, _amount);
		stakings[_account].claimedToken = stakings[_account].claimedToken.add(_amount);
		stakings[_account].claimTime = block.timestamp;
		emit Claim(perc, _account, _amount);
	}
	
}