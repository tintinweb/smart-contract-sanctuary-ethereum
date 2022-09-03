/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface iERC20 {

	function balanceOf(address who) external view returns (uint256 balance);

	function allowance(address owner, address spender) external view returns (uint256 remaining);

	function transfer(address to, uint256 value) external returns (bool success);

	function approve(address spender, uint256 value) external returns (bool success);

	function transferFrom(address from, address to, uint256 value) external returns (bool success);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Context {
	function _msgSender() internal view returns (address) {
		return msg.sender;
	}

	function _msgData() internal view returns (bytes memory) {
		this;
		return msg.data;
	}
}

library SafeMath {
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		require(c / a == b);
		return c;
	}
}

library SafeERC20 {
	function safeTransfer(iERC20 _token, address _to, uint256 _value) internal {
		require(_token.transfer(_to, _value));
	}
	function safeTransferFrom(iERC20 _token, address _from, address _to, uint256 _value) internal {
		require(_token.transferFrom(_from, _to, _value));
	}
}

contract Controllable is Context {
	mapping (address => bool) public controllers;
	event ControllerAdded(address indexed _new);
	event ControllerRemoved(address indexed _old);

	constructor () {
		address msgSender = _msgSender();
		controllers[msgSender] = true;
		emit ControllerAdded(msgSender);
	}

	modifier onlyController() {
		require(controllers[_msgSender()], "Controllable: caller is not a controller");
		_;
	}

	function addController(address _address) external onlyController {
		controllers[_address] = true;
		emit ControllerAdded(_address);
	}

	function removeController(address _address) external onlyController {
		delete controllers[_address];
		emit ControllerRemoved(_address);
	}
}

contract Pausable is Controllable {
	event Pause();
	event Unpause();

	bool public paused = false;

	modifier whenNotPaused() {
		require(!paused);
		_;
	}

	modifier whenPaused() {
		require(paused);
		_;
	}

	function pause() public onlyController whenNotPaused {
		paused = true;
		emit Pause();
	}

	function unpause() public onlyController whenPaused {
		paused = false;
		emit Unpause();
	}
}

contract VIDT_tokenswap is Controllable, Pausable {
	using SafeMath for uint256;
	using SafeERC20 for iERC20;

	mapping (address => bool) public blocklist;

	iERC20 public constant tokenOld = iERC20(0xfeF4185594457050cC9c23980d301908FE057Bb1); 
	iERC20 public constant tokenNew = iERC20(0x3BE7bF1A5F23BD8336787D0289B70602f1940875);
	address public tokenPool = address(0x025c4123148416e26f864d45Fe9C45AeBc6A47c3);
	uint256 public blocked;

	event swapped(uint256 indexed amount);
	
	constructor() {
		controllers[msg.sender] = true;
	}
	
	function switchPool(address _tokenPool) public onlyController {
		tokenPool = _tokenPool;
	}

	function receiveEther() public payable {
		revert();
	}

	function swap() public {
		uint256 _amount = tokenOld.balanceOf(msg.sender);
		require(_amount > 0,"No balance of VIDT Datalink tokens");
		_swap(_amount);
	}

	function _swap(uint256 _amount) internal {
		tokenOld.safeTransferFrom(address(msg.sender), tokenPool, _amount);
		if (blocklist[msg.sender]) {
			blocked.add(_amount);
		} else {
			tokenNew.safeTransferFrom(tokenPool, address(msg.sender), _amount.mul(10));
		}
		emit swapped(_amount);
	}

	function blockAddress(address _address, bool _state) external onlyController returns (bool) {
		blocklist[_address] = _state;
		return true;
	}

	function transferToken(address tokenAddress, uint256 amount) external onlyController {
		iERC20(tokenAddress).safeTransfer(msg.sender,amount);
	}

	function flushToken(address tokenAddress) external onlyController {
		uint256 amount = iERC20(tokenAddress).balanceOf(address(this));
		iERC20(tokenAddress).safeTransfer(msg.sender,amount);
	}
}